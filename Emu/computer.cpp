#include <cstdint>
#include <fstream>

#include "spiflash.h"
#include "cdp1855.h"
#include "6800.h"
#include "IOBoard.h"
#include "gpu.h"
#include "computer.h"

Computer::Computer() : cpu(*this), ioBoard(*this) {
	reset();
}

void Computer::reset() {
	cdp1855.reset();
	std::ifstream input("../Kernal/6800/kernal.bin", std::ios::binary | std::ios::in);
	input.seekg(0, std::ios::end);
	std::streamsize size = input.tellg();
	input.seekg(0, std::ios::beg);
	input.read((char*)ROM, size > 32768 ? 32768 : size);
	int read = input.tellg();
	input.close();
	printf("%d bytes read for ROM\r\n", read);
	if(read < 32768) for(int i = read; i < 32768; i++) ROM[i] = 0xFF;
	ioBoard.reset();
	cpu.reset();
	gpu.reset();
	ps2_wp = 0;
	ps2_rp = 0;
	ps2_cooldown = 201;
	last_nmi = 0;
}

uint8_t Computer::memory_read(uint16_t address) {
	if(address < 256 || (address >= 512 && address < 32768)) return RAM[address];
	if(address >= 32768) return ROM[address - 32768];
	if(address >= 256 && address < 512) {
		uint8_t dnum = (address >> 5) & 7;
		if(dnum == 0 && (address & 4) != 0) {
			return cdp1855.read(address & 3);
		}else if(dnum == 3) {
			return 0xFF; //Do not emulate the UART
		}else if(dnum == 2) {
			return ioBoard.read(address);
		}else if(dnum == 1) {
			return gpu.read(address);
		}
		printf("IO Read from unknown address %02x\r\n", address & 0xFF);
		exit(1);
	}
	return 0;
}

void Computer::memory_write(uint16_t address, uint8_t value) {
	if(address < 256 || (address >= 512 && address < 32768)) {
		RAM[address] = value;
	}else if(address >= 256 && address < 512) {
		uint8_t dnum = (address >> 5) & 7;
		if(dnum == 0 && (address & 4) != 0) {
			cdp1855.write(address & 3, value);
			return;
		}else if(dnum == 3) {
			//Do not emulate the UART.
			return;
		}else if(dnum == 2) {
			ioBoard.write(address, value);
			return;
		}else if(dnum == 1) {
			gpu.write(address, value);
			return;
		}
		printf("IO Write to unknown address %02x, value %02X\r\n", address & 0xFF, value);
		cpu.print_regs();
		exit(1);
	}
}

void Computer::cycles(int count) {
	for(int i = 0; i < count; i++) {
		cdp1855.step();
		gpu.step();
		cpu.step();
		ioBoard.step();
		if(ioBoard.pending_interrupt()) {
			if(!last_nmi) cpu.interrupt(0);
			last_nmi = 1;
		}else last_nmi = 0;
		ps2_cooldown--;
		if(ps2_cooldown == 0) {
			ps2_cooldown = 201;
			if(ps2_wp == ps2_rp) continue;
			uint8_t val = pendingPS2[ps2_rp];
			ps2_rp++;
			ioBoard.set_ps2_val(val);
		}
	}
}

uint8_t* Computer::gpu_render(uint16_t* width, uint16_t* height) {
	return gpu.render(width, height);
}

void Computer::ps2_int(uint8_t val) {
	if(ps2_wp + 1 == ps2_rp) return;
	pendingPS2[ps2_wp] = val;
	ps2_wp++;
}
