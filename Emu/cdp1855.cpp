#include <cstdint>
#include <cstdio>

#include "cdp1855.h"

CDP1855::CDP1855() {
	reset();
}

void CDP1855::reset() {
	x = y = z = 0;
	control = 0;
	x_seq = y_seq = z_seq = 0;
	cooldown = op = 0;
	broken = 1;
	overflow = 0;
}

void CDP1855::write(uint8_t addr, uint8_t val) {
	addr &= 3;
	if(addr == 0) {
		x &= x_seq ? 0xFF00 : 0x00FF;
		x |= x_seq ? val : (uint16_t)val << 8;
		x_seq = !x_seq;
	}else if(addr == 1) {
		z &= z_seq ? 0xFF00 : 0x00FF;
		z |= z_seq ? val : (uint16_t)val << 8;
		z_seq = !z_seq;
	}else if(addr == 2) {
		y &= y_seq ? 0xFF00 : 0x00FF;
		y |= y_seq ? val : (uint16_t)val << 8;
		y_seq = !y_seq;
	}else if(addr == 3) {
		if((val & 64) != 0) x_seq = y_seq = z_seq = 0;
		if((val & 4) != 0) z = 0;
		if((val & 8) != 0) y = 0;
		op = val & 3;
		if(op == 3) printf("CDP1855: Invalid op 0x3\r\n");
		uint8_t no = (val >> 4) & 3;
		cooldown = (val & 128) == 0 ? 3 : (no == 3 ? 6 : (no == 2 ? 12 : 24));
		if((val & 128) != 0 && no != 2) {
			broken = 1;
			printf("CDP1855: invalid MDU number config\r\n");
		}else broken = 0;
	}
}

uint8_t CDP1855::read(uint8_t addr) {
	addr &= 3;
	if(addr == 0) {
		x_seq = !x_seq;
		if(x_seq) return x >> 8;
		else return x & 0xFF;
	}else if(addr == 1) {
		z_seq = !z_seq;
		if(z_seq) return z >> 8;
		else return z & 0xFF;
	}else if(addr == 2) {
		y_seq = !y_seq;
		if(y_seq) return y >> 8;
		else return y & 0xFF;
	}else if(addr == 3) {
		return overflow & 1;
	}
	return 0;
}

void CDP1855::step() {
	if(op == 0 || op == 3) return;
	if(cooldown == 0) return;
	cooldown--;
	if(cooldown != 0) return;
	if(broken) {
		x = z = y = 0;
		return;
	}
	if(op == 1) {
		//Mul
		uint32_t res = (uint32_t)x * (uint32_t)z;
		y = res >> 16;
		z = res & 0xFFFF;
		return;
	}
	//Div
	uint32_t divident = (uint32_t)y << 16;
	divident |= z;
	uint32_t res = divident / (uint32_t)x;
	overflow = res > 0xFFFF;
	z = res & 0xFFFF;
	y = divident % (uint32_t)x;
}
