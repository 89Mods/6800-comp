#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include "spiflash.h"
#include "IOBoard.h"
#include "cdp1855.h"
#include "6800.h"
#include "gpu.h"
#include "computer.h"

MC6800::MC6800(Computer& c) : comp(c) {
	//reset();
}

void MC6800::reset() {
	A = B = 0;
	SP = X = 0;
	SR = 128+64;
	PC = (comp.memory_read(0xFFFE) << 8) | comp.memory_read(0xFFFF);
	printf("Initial pc: %04x\r\n", PC);
	trace_on = 0;
}

#define FLAG_C 1
#define FLAG_V 2
#define FLAG_Z 4
#define FLAG_N 8
#define FLAG_I 16
#define FLAG_AC 32

void MC6800::set_conditions_for8(int8_t val) {
	SR &= ~(FLAG_Z | FLAG_N | FLAG_V);
	if(val == 0) SR |= FLAG_Z;
	if(val < 0) SR |= FLAG_N;
}

void MC6800::set_conditions_for16(int16_t val) {
	SR &= ~(FLAG_Z | FLAG_N | FLAG_V);
	if(val == 0) SR |= FLAG_Z;
	if(val < 0) SR |= FLAG_N;
}

void MC6800::branch() {
	int8_t disp = (int8_t)comp.memory_read(PC);
	PC += disp;
	PC++;
}

uint8_t MC6800::add(uint8_t a, uint8_t b, uint8_t carry_in) {
	uint16_t res = a + b + carry_in;
	int8_t val = (int8_t)res;
	SR &= ~(FLAG_Z | FLAG_N | FLAG_V | FLAG_C);
	set_conditions_for8(val);
	if(res > 255) SR |= FLAG_C;
	if((a >> 7) == (b >> 7) && ((res >> 7) & 1) != (b >> 7)) SR |= FLAG_V;
	return (uint8_t)res;
}

uint8_t MC6800::subtract(uint8_t a, uint8_t b, uint8_t borrow_in) {
	uint16_t res = a - b - borrow_in;
	int8_t val = (int8_t)res;
	SR &= ~(FLAG_Z | FLAG_N | FLAG_V | FLAG_C);
	set_conditions_for8(val);
	if(res > 255) SR |= FLAG_C;
	b = ~b;
	if((a >> 7) == (b >> 7) && ((res >> 7) & 1) != (b >> 7)) SR |= FLAG_V;
	return (uint8_t)res;
}

//C,Z,S,O,Ac,I
void MC6800::step() {
	uint8_t opcode = comp.memory_read(PC);
	if(trace_on) {
		printf("%02x @ %04x\r\n", opcode, PC);
	}
	PC++;
	if(opcode == 0x00) {
		//if(trace_on) exit(0);
		trace_on = !trace_on;
	}else if(opcode == 0x01) {
		//NOP
	}else if(opcode == 0x0F) {
		//SEI
		SR |= FLAG_I;
	}else if(opcode == 0x0E) {
		//CLI
		SR &= ~FLAG_I;
	}else if(opcode == 0x8E) {
		//LDS #data16
		SP = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC += 2;
		printf("New SP: %04x\r\n", SP);
		SR &= ~(FLAG_Z | FLAG_N | FLAG_V);
		if(SP == 0) SR |= FLAG_Z;
		if((SP & 32768) != 0) SR |= FLAG_N;
	}else if(opcode == 0xAD || opcode == 0xBD) {
		uint16_t targ;
		if(opcode == 0xAD) {
			//JSR d8,X
			targ = X + comp.memory_read(PC);
			PC++;
		}else {
			//JSR a16
			targ = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		comp.memory_write(SP, PC & 0xFF);
		comp.memory_write(SP - 1, PC >> 8);
		SP -= 2;
		PC = targ;
	}else if(opcode == 0x86 || opcode == 0xC6) {
		//LDA A/B #
		uint8_t val = comp.memory_read(PC);
		PC++;
		set_conditions_for8(val);
		if(opcode == 0x86) A = val;
		else B = val;
	}else if(opcode == 0xB7 || opcode == 0xF7) {
		//STA A/B a16
		uint16_t addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC += 2;
		comp.memory_write(addr, opcode == 0xB7 ? A : B);
		set_conditions_for8(opcode == 0xB7 ? A : B);
	}else if(opcode == 0x39) {
		//RTS
		PC = (comp.memory_read(SP + 1) << 8) | comp.memory_read(SP + 2);
		SP += 2;
	}else if(opcode == 0x36 || opcode == 0x37) {
		//PSH A/B
		comp.memory_write(SP, opcode == 0x36 ? A : B);
		SP--;
	}else if(opcode == 0x4A || opcode == 0x5A) {
		//DEC A/B
		uint8_t val = opcode == 0x4A ? A : B;
		set_conditions_for8(val - 1);
		if(val == 128) SR |= FLAG_V;
		if(opcode == 0x4A) A = val - 1;
		else B = val - 1;
	}else if(opcode == 0x26) {
		//BNE
		if((SR & FLAG_Z) == 0) branch();
		else PC++;
	}else if(opcode == 0x32 || opcode == 0x33) {
		//PUL A/B
		SP++;
		uint8_t val = comp.memory_read(SP);
		if(opcode == 0x32) A = val;
		else B = val;
	}else if(opcode == 0x4F || opcode == 0x5F) {
		//CLR A/B
		if(opcode == 0x4F) A = 0;
		else B = 0;
		SR &= ~(FLAG_C | FLAG_N | FLAG_V);
		SR |= FLAG_Z;
	}else if(opcode == 0x97 || opcode == 0xD7) {
		//STA A/B a8
		uint8_t addr = comp.memory_read(PC);
		PC++;
		uint8_t val = opcode == 0x97 ? A : B;
		comp.memory_write(addr, val);
		set_conditions_for8(val);
	}else if(opcode == 0x7E) {
		//JMP a16
		PC = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
	}else if(opcode == 0x6E) {
		//JMP d8,X
		uint8_t d = comp.memory_read(PC);
		PC = X + d;
	}else if(opcode == 0xB6 || opcode == 0xF6) {
		//LDA A/B a16
		uint16_t addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC++; PC++;
		uint8_t val = comp.memory_read(addr);
		set_conditions_for8(val);
		if(opcode == 0xB6) A = val;
		else B = val;
	}else if(opcode == 0x31) {
		//INS
		SP++;
	}else if(opcode == 0x94 || opcode == 0xD4) {
		//AND A/B a8
		uint8_t addr = comp.memory_read(PC);
		PC++;
		uint8_t val = comp.memory_read(addr);
		val = val & (opcode == 0x94 ? A : B);
		set_conditions_for8(val);
		if(opcode == 0x94) A = val;
		else B = val;
	}else if(opcode == 0x27) {
		//BEQ
		if((SR & FLAG_Z) != 0) branch();
		else PC++;
	}else if(opcode == 0x84 || opcode == 0xC4) {
		//AND A/B #
		uint8_t val = comp.memory_read(PC);
		PC++;
		val = val & (opcode == 0x84 ? A : B);
		set_conditions_for8(val);
		if(opcode == 0x84) A = val;
		else B = val;
	}else if(opcode == 0xCE) {
		//LDX #
		uint16_t val = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC++; PC++;
		X = val;
		set_conditions_for16(X);
	}else if(opcode == 0xA1 || opcode == 0xE1) {
		//CMP A/B d8,X
		uint8_t val = comp.memory_read(PC);
		PC++;
		val = comp.memory_read(X + val);
		subtract(opcode == 0xA1 ? A : B, val, 0);
	}else if(opcode == 0x11) {
		//CBA
		subtract(A, B, 0);
	}else if(opcode == 0x8B || opcode == 0xCB) {
		//ADD A/B #
		uint8_t val = comp.memory_read(PC);
		PC++;
		val = add(opcode == 0x8B ? A : B, val, 0);
		if(opcode == 0x8B) A = val;
		else B = val;
	}else if(opcode == 0x96 || opcode == 0xD6) {
		//LDA A/B a8
		uint8_t val = comp.memory_read(PC);
		PC++;
		val = comp.memory_read(val);
		set_conditions_for8(val);
		if(opcode == 0x96) A = val;
		else B = val;
	}else if(opcode == 0x89 || opcode == 0xC9) {
		//ADC A/B #
		uint8_t val = comp.memory_read(PC);
		PC++;
		val = add(opcode == 0x89 ? A : B, val, (SR & FLAG_C) != 0);
		if(opcode == 0x89) A = val;
		else B = val;
	}else if(opcode == 0x81 || opcode == 0xC1) {
		//CMP A/B #
		uint8_t val = comp.memory_read(PC);
		PC++;
		subtract(opcode == 0x81 ? A : B, val, 0);
	}else if(opcode == 0x0C) {
		//CLC
		SR &= ~FLAG_C;
	}else if(opcode == 0x46 || opcode == 0x56) {
		//ROR A/B
		uint8_t val = opcode == 0x46 ? A : B;
		uint8_t new_c = val & 1;
		val >>= 1;
		if((SR & FLAG_C) != 0) val |= 128;
		SR &= ~FLAG_C;
		set_conditions_for8(val);
		if(new_c) SR |= FLAG_C;
		if(opcode == 0x46) A = val;
		else B = val;
		if(((SR & FLAG_C) != 0 || (SR & FLAG_N) != 0) && !((SR & FLAG_C) != 0 && (SR & FLAG_N) != 0)) SR |= FLAG_V;
	}else if(opcode == 0x66 || opcode == 0x76) {
		uint16_t addr;
		if(opcode == 0x66) {
			//ROR d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//ROR a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		uint8_t val = comp.memory_read(addr);
		uint8_t new_c = val & 1;
		val >>= 1;
		if((SR & FLAG_C) != 0) val |= 128;
		SR &= ~FLAG_C;
		set_conditions_for8(val);
		if(new_c) SR |= FLAG_C;
		comp.memory_write(addr, val);
		if(((SR & FLAG_C) != 0 || (SR & FLAG_N) != 0) && !((SR & FLAG_C) != 0 && (SR & FLAG_N) != 0)) SR |= FLAG_V;
	}else if(opcode == 0x4C || opcode == 0x5C) {
		//INC A/B
		uint8_t val = opcode == 0x4C ? A : B;
		set_conditions_for8(val + 1);
		if(val == 127) SR |= FLAG_V;
		if(opcode == 0x4C) A = val + 1;
		else B = val + 1;
	}else if(opcode == 0x6C || opcode == 0x7C) {
		uint16_t addr;
		if(opcode == 0x6C) {
			//INC d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//INC a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		uint8_t val = comp.memory_read(addr);
		set_conditions_for8(val + 1);
		if(val == 127) SR |= FLAG_V;
		comp.memory_write(addr, val + 1);
	}else if(opcode == 0x6A || opcode == 0x7A) {
		uint16_t addr;
		if(opcode == 0x6A) {
			//DEC d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//DEC a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		uint8_t val = comp.memory_read(addr);
		set_conditions_for8(val - 1);
		if(val == 128) SR |= FLAG_V;
		comp.memory_write(addr, val - 1);
	}else if(opcode == 0x9B || opcode == 0xDB) {
		//ADD A/B a8
		uint8_t addr = comp.memory_read(PC);
		PC++;
		uint8_t val = comp.memory_read(addr);
		val = add(opcode == 0x9B ? A : B, val, 0);
		if(opcode == 0x9B) A = val;
		else B = val;
	}else if(opcode == 0xA7 || opcode == 0xE7) {
		//STA A/B d8,X
		uint16_t addr = comp.memory_read(PC) + X;
		PC++;
		uint8_t val = opcode == 0xA7 ? A : B;
		comp.memory_write(addr, val);
		set_conditions_for8(val);
	}else if(opcode == 0x8A || opcode == 0xCA) {
		//ORA A/B #
		uint16_t val = comp.memory_read(PC);
		PC++;
		val |= opcode == 0x8A ? A : B;
		set_conditions_for8(val);
		if(opcode == 0x8A) A = val;
		else B = val;
	}else if(opcode == 0x2B) {
		//BMI
		if((SR & FLAG_N) != 0) branch();
		else PC++;
	}else if(opcode == 0x2A) {
		//BPL
		if((SR & FLAG_N) == 0) branch();
		else PC++;
	}else if(opcode == 0xA6 || opcode == 0xE6) {
		//LDA A/B d8,X
		uint16_t addr = comp.memory_read(PC) + X;
		PC++;
		uint8_t val = comp.memory_read(addr);
		set_conditions_for8(val);
		if(opcode == 0xA6) A = val;
		else B = val;
	}else if(opcode == 0x09) {
		//DEX
		X--;
		SR &= ~FLAG_Z;
		if(X == 0) SR |= FLAG_Z;
	}else if(opcode == 0x44 || opcode == 0x54) {
		//LSR A/B
		uint8_t val = opcode == 0x44 ? A : B;
		uint8_t new_c = val & 1;
		val >>= 1;
		SR &= ~FLAG_C;
		set_conditions_for8(val);
		if(new_c) SR |= FLAG_C + FLAG_V;
		if(opcode == 0x44) A = val;
		else B = val;
	}else if(opcode == 0x64 || opcode == 0x74) {
		uint16_t addr;
		if(opcode == 0x64) {
			//LSR d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//LSR a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		uint8_t val = comp.memory_read(addr);
		uint8_t new_c = val & 1;
		val >>= 1;
		SR &= ~FLAG_C;
		set_conditions_for8(val);
		if(new_c) SR |= FLAG_C + FLAG_V;
		comp.memory_write(addr, val);
	}else if(opcode == 0x91 || opcode == 0xD1) {
		//CMP A/B a8
		uint8_t addr = comp.memory_read(PC);
		PC++;
		subtract(opcode == 0x91 ? A : B, comp.memory_read(addr), 0);
	}else if(opcode == 0xB1 || opcode == 0xF1) {
		//CMP A/B a16
		uint16_t addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC += 2;
		subtract(opcode == 0xB1 ? A : B, comp.memory_read(addr), 0);
	}else if(opcode == 0x6F || opcode == 0x7F) {
		uint16_t addr;
		if(opcode == 0x6F) {
			//CLR d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//CLR a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		SR &= ~(FLAG_C | FLAG_N | FLAG_V);
		SR |= FLAG_Z;
		comp.memory_write(addr, 0);
	}else if(opcode == 0xEE || opcode == 0xFE) {
		uint16_t addr;
		if(opcode == 0xEE) {
			//LDX d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//LDX a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		X = (comp.memory_read(addr) << 8) | comp.memory_read(addr + 1);
		set_conditions_for16(X);
	}else if(opcode == 0xAE || opcode == 0xBE) {
		uint16_t addr;
		if(opcode == 0xAE) {
			//LDS d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//LDS a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		SP = (comp.memory_read(addr) << 8) | comp.memory_read(addr + 1);
		set_conditions_for16(SP);
		printf("New SP: %04x\r\n", SP);
	}else if(opcode == 0xDE) {
		//LDX a8
		uint16_t addr = comp.memory_read(PC);
		PC++;
		X = (comp.memory_read(addr) << 8) | comp.memory_read((addr + 1)&255);
		set_conditions_for16(X);
	}else if(opcode == 0x9E) {
		//LDS a8
		uint16_t addr = comp.memory_read(PC);
		PC++;
		SP = (comp.memory_read(addr) << 8) | comp.memory_read((addr + 1)&255);
		set_conditions_for16(SP);
		printf("New SP: %04x\r\n", SP);
	}else if(opcode == 0x3B) {
		//RTI
		SR = 0xC0 | comp.memory_read(SP + 1);
		B = comp.memory_read(SP + 2);
		A = comp.memory_read(SP + 3);
		X = (comp.memory_read(SP + 4) << 8) | comp.memory_read(SP + 5);
		PC = (comp.memory_read(SP + 6) << 8) | comp.memory_read(SP + 7);
		SP += 7;
	}else if(opcode == 0x10) {
		//SBA
		A = subtract(A, B, 0);
	}else if(opcode == 0x0D) {
		//SEC
		SR |= FLAG_C;
	}else if(opcode == 0x0B) {
		//SEV
		SR |= FLAG_V;
	}else if(opcode == 0x0A) {
		//CLV
		SR &= ~FLAG_V;
	}else if(opcode == 0x30) {
		//TSX
		X = SP + 1;
	}else if(opcode == 0x35) {
		//TXD
		SP = X - 1;
	}else if(opcode == 0x4D || opcode == 0x5D) {
		//TST A/B
		SR &= ~FLAG_C;
		set_conditions_for8(opcode = 0x4D ? A : B);
	}else if(opcode == 0x6D || opcode == 0x7D) {
		uint16_t addr;
		if(opcode == 0x6D) {
			//TST d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//TST a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		SR &= ~FLAG_C;
		set_conditions_for8(comp.memory_read(addr));
	}else if(opcode == 0x16) {
		//TAB
		B = A;
		set_conditions_for8(B);
	}else if(opcode == 0x06) {
		//TAP
		SR = A | 0xC0;
	}else if(opcode == 0x17) {
		//TBA
		A = B;
		set_conditions_for8(A);
	}else if(opcode == 0x07) {
		//TPA
		A = SR;
	}else if(opcode == 0x3F) {
		//SWI
		comp.memory_write(SP, PC & 0xFF);
		comp.memory_write(SP - 1, PC >> 8);
		comp.memory_write(SP - 2, X & 0xFF);
		comp.memory_write(SP - 3, X >> 8);
		comp.memory_write(SP - 4, A);
		comp.memory_write(SP - 5, B);
		comp.memory_write(SP - 6, SR);
		SP -= 7;
		PC = (comp.memory_read(0xFFFA) << 8) | comp.memory_read(0xFFFB);
	}else if(opcode == 0x24) {
		//BCC
		if((SR & FLAG_C) == 0) branch();
		else PC++;
	}else if(opcode == 0x25) {
		//BCS
		if((SR & FLAG_C) != 0) branch();
		else PC++;
	}else if(opcode == 0x2C) {
		//BGE
		if(((SR & FLAG_N) != 0) != ((SR & FLAG_V) != 0)) PC++;
		else branch();
	}else if(opcode == 0x2E) {
		//BGT
		if((((SR & FLAG_N) != 0) != ((SR & FLAG_V) != 0)) || (SR & FLAG_Z) != 0) PC++;
		else branch();
	}else if(opcode == 0x22) {
		//BHI
		if(((SR & FLAG_C) != 0) || ((SR & FLAG_N) != 0)) PC++;
		else branch();
	}else if(opcode == 0x2F) {
		//BLE
		if((((SR & FLAG_N) != 0) != ((SR & FLAG_V) != 0)) || (SR & FLAG_Z) != 0) branch();
		else PC++;
	}else if(opcode == 0x23) {
		//BLS
		if(((SR & FLAG_C) != 0) || ((SR & FLAG_N) != 0)) branch();
		else PC++;
	}else if(opcode == 0x2D) {
		//BLT
		if(((SR & FLAG_N) != 0) != ((SR & FLAG_V) != 0)) branch();
		else PC++;
	}else if(opcode == 0x20) {
		//BRA
		branch();
	}else if(opcode == 0x8D) {
		//BSR
		PC++;
		comp.memory_write(SP, PC & 0xFF);
		comp.memory_write(SP - 1, PC >> 8);
		SP -= 2;
		PC--;
		branch();
	}else if(opcode == 0x28) {
		//BVC
		if((SR & FLAG_V) == 0) branch();
		else PC++;
	}else if(opcode == 0x29) {
		//BVS
		if((SR & FLAG_C) != 0) branch();
		else PC++;
	}else if(opcode == 0x43 || opcode == 0x53) {
		//COM A/B
		uint8_t val = opcode == 0x43 ? A : B;
		val = ~val;
		set_conditions_for8(val);
		SR |= FLAG_C;
		if(opcode == 0x43) A = val;
		else B = val;
	}else if(opcode == 0x63 || opcode == 0x73) {
		uint16_t addr;
		if(opcode == 0x63) {
			//COM d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//COM a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		uint8_t val = comp.memory_read(addr);
		val = ~val;
		set_conditions_for8(val);
		SR |= FLAG_C;
		comp.memory_write(addr, val);
	}else if(opcode == 0x9C || opcode == 0xAC || opcode == 0x8C || opcode == 0xBC) {
		uint16_t addr;
		if(opcode == 0x9C) {
			//CPX a8
			addr = comp.memory_read(PC);
			PC++;
		}else if(opcode == 0xAC) {
			//CPX d8,X
			addr = comp.memory_read(PC) + X;
			PC++;
		}else if(opcode == 0xBC || opcode == 0x8C) {
			//CPX a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		uint16_t val;
		if(opcode == 0x8C) {
			//CPX #
			val = addr;
		}else {
			val = (comp.memory_read(addr) << 8) | comp.memory_read(opcode == 0x9C ? ((addr + 1) & 255) : (addr + 1));
		}
		uint8_t prev_c = (SR & FLAG_C) != 0;
		uint16_t res;
		res = subtract(X & 255, val & 255, 0);
		res |= (uint16_t)subtract(X >> 8, val >> 8, (SR & FLAG_C) != 0) << 8;
		SR &= ~FLAG_C;
		SR &= ~FLAG_Z;
		if(res == 0) SR |= FLAG_Z;
		if(prev_c) SR |= FLAG_C;
	}else if(opcode == 0x34) {
		//DES
		SP--;
	}else if(opcode == 0x08) {
		//INX
		X++;
		SR &= ~FLAG_Z;
		if(X == 0) SR |= FLAG_Z;
	}else if(opcode == 0x40 || opcode == 0x50) {
		//NEG A/B
		uint8_t res = subtract(0, opcode == 0x40 ? A : B, 0);
		if(opcode == 0x40) A = res;
		else B = res;
	}else if(opcode == 0x60 || opcode == 0x70) {
		uint16_t addr;
		if(opcode == 0x60) {
			//NEG d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//NEG a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		uint8_t res = subtract(0, comp.memory_read(addr), 0);
		comp.memory_write(addr, res);
	}else if(opcode == 0x49 || opcode == 0x59) {
		//ROL A/B
		uint8_t val = opcode == 0x49 ? A : B;
		uint8_t new_c = (val & 128) != 0;
		val <<= 1;
		if((SR & FLAG_C) != 0) val |= 1;
		SR &= ~FLAG_C;
		set_conditions_for8(val);
		if(new_c) SR |= FLAG_C;
		if(opcode == 0x49) A = val;
		else B = val;
		if(((SR & FLAG_C) != 0 || (SR & FLAG_N) != 0) && !((SR & FLAG_C) != 0 && (SR & FLAG_N) != 0)) SR |= FLAG_V;
	}else if(opcode == 0x69 || opcode == 0x79) {
		uint16_t addr;
		if(opcode == 0x69) {
			//ROR d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//ROR a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		uint8_t val = comp.memory_read(addr);
		uint8_t new_c = (val & 128) != 0;
		val <<= 1;
		if((SR & FLAG_C) != 0) val |= 1;
		SR &= ~FLAG_C;
		set_conditions_for8(val);
		if(new_c) SR |= FLAG_C;
		comp.memory_write(addr, val);
		if(((SR & FLAG_C) != 0 || (SR & FLAG_N) != 0) && !((SR & FLAG_C) != 0 && (SR & FLAG_N) != 0)) SR |= FLAG_V;
	}else if(opcode == 0xDF) {
		//STX a8
		uint16_t addr = comp.memory_read(PC);
		PC++;
		comp.memory_write(addr, X >> 8);
		comp.memory_write((addr + 1) & 255, X & 255);
		set_conditions_for16(X);
	}else if(opcode == 0xEF || opcode == 0xFF) {
		uint16_t addr;
		if(opcode == 0xEF) {
			//STX d8,X
			uint8_t val = comp.memory_read(PC);
			PC++;
			addr = val + X;
		}else {
			//STX a16
			addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
			PC += 2;
		}
		comp.memory_write(addr, X >> 8);
		comp.memory_write(addr + 1, X & 255);
		set_conditions_for16(X);
	}else if(opcode == 0x1B) {
		//ABA
		A = add(A, B, 0);
	}else if(opcode == 0x85 || opcode == 0xC5) {
		//BIT A/B #
		uint8_t val = comp.memory_read(PC);
		PC++;
		val &= opcode == 0x85 ? A : B;
		set_conditions_for8(val);
	}else if(opcode == 0x95 || opcode == 0xD5) {
		//BIT A/B a8
		uint8_t addr = comp.memory_read(PC);
		uint8_t val = comp.memory_read(addr);
		PC++;
		val &= opcode == 0x95 ? A : B;
		set_conditions_for8(val);
	}else if(opcode == 0xB5 || opcode == 0xF5) {
		//BIT A/B a16
		uint16_t addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC += 2;
		uint8_t val = comp.memory_read(addr);
		val &= opcode == 0xB5 ? A : B;
		set_conditions_for8(val);
	}else if(opcode == 0xA5 || opcode == 0xE5) {
		//BIT A/B d8,X
		uint16_t addr = comp.memory_read(PC) + X;
		uint8_t val = comp.memory_read(addr);
		PC++;
		val &= opcode == 0xA5 ? A : B;
		set_conditions_for8(val);
	}else if(opcode == 0x99 || opcode == 0xD9) {
		//ADC A/B a8
		uint8_t addr = comp.memory_read(PC);
		PC++;
		uint8_t val = add(opcode == 0x99 ? A : B, comp.memory_read(addr), (SR & FLAG_C) != 0);
		if(opcode == 0x99) A = val;
		else B = val;
	}else if(opcode == 0xB9 || opcode == 0xF9) {
		//ADC A/B a16
		uint16_t addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC += 2;
		uint8_t val = add(opcode == 0xB9 ? A : B, comp.memory_read(addr), (SR & FLAG_C) != 0);
		if(opcode == 0xB9) A = val;
		else B = val;
	}else if(opcode == 0xA9 || opcode == 0xE9) {
		//ADC A/B d8,X
		uint16_t addr = comp.memory_read(PC) + X;
		PC++;
		uint8_t val = add(opcode == 0xA9 ? A : B, comp.memory_read(addr), (SR & FLAG_C) != 0);
		if(opcode == 0xA9) A = val;
		else B = val;
	}else if(opcode == 0x80 || opcode == 0xC0) {
		//SUB A/B d8
		uint8_t val = comp.memory_read(PC);
		PC++;
		val = subtract(opcode == 0x80 ? A : B, val, 0);
		if(opcode == 0x80) A = val;
		else B = val;
	}else if(opcode == 0xBA || opcode == 0xFA) {
		//ORA A/B a16
		uint16_t addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC++; PC++;
		uint8_t val = comp.memory_read(addr);
		val |= opcode == 0xBA ? A : B;
		set_conditions_for8(val);
		if(opcode == 0xBA) A = val;
		else B = val;
	}else if(opcode == 0xB2 || opcode == 0xF2) {
		//SBC A/B a16
		uint16_t addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC += 2;
		uint8_t val = comp.memory_read(addr);
		val = subtract(opcode == 0xB2 ? A : B, val, (SR & FLAG_C) != 0);
		if(opcode == 0xB2) A = val;
		else B = val;
	}else if(opcode == 0xA0 || opcode == 0xE0) {
		//SUB A/B d8,X
		uint16_t addr = comp.memory_read(PC) + X;
		PC++;
		uint8_t val = comp.memory_read(addr);
		val = subtract(opcode == 0xA0 ? A : B, val, 0);
		if(opcode == 0xA0) A = val;
		else B = val;
	}else if(opcode == 0xA2 || opcode == 0xE2) {
		//SBC A/B d8,X
		uint16_t addr = comp.memory_read(PC) + X;
		PC++;
		uint8_t val = comp.memory_read(addr);
		val = subtract(opcode == 0xA2 ? A : B, val, (SR & FLAG_C) != 0);
		if(opcode == 0xA2) A = val;
		else B = val;
	}else if(opcode == 0xAB || opcode == 0xEB) {
		//ADD A/B d8,X
		uint16_t addr = comp.memory_read(PC) + X;
		PC++;
		uint8_t val = comp.memory_read(addr);
		val = add(opcode == 0xAB ? A : B, val, 0);
		if(opcode == 0xAB) A = val;
		else B = val;
	}else if(opcode == 0xB0 || opcode == 0xF0) {
		//SUB A/B a16
		uint16_t addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC += 2;
		uint8_t val = comp.memory_read(addr);
		val = subtract(opcode == 0xB0 ? A : B, val, 0);
		if(opcode == 0xB0) A = val;
		else B = val;
	}else if(opcode == 0x98 || opcode == 0xD8) {
		//EOR A/B a8
		uint16_t addr = comp.memory_read(PC);
		PC++;
		uint8_t val = comp.memory_read(addr);
		val = (opcode == 0x98 ? A : B) ^ val;
		set_conditions_for8(val);
		if(opcode == 0x98) A = val;
		else B = val;
	}else if(opcode == 0xBB || opcode == 0xFB) {
		//ADD A/B a16
		uint16_t addr = (comp.memory_read(PC) << 8) | comp.memory_read(PC + 1);
		PC += 2;
		uint8_t val = comp.memory_read(addr);
		val = add(opcode == 0xBB ? A : B, val, 0);
		if(opcode == 0xBB) A = val;
		else B = val;
	}else if(opcode == 0x92 || opcode == 0xD2) {
		//SBC A/B a8
		uint16_t addr = comp.memory_read(PC);
		PC++;
		uint8_t val = comp.memory_read(addr);
		val = subtract(opcode == 0x92 ? A : B, val, (SR & FLAG_C) != 0);
		if(opcode == 0x92) A = val;
		else B = val;
	}
	
	else {
		printf("Unknown opcode: %02x\r\n", opcode);
		print_regs();
		exit(1);
	}
	if(trace_on) print_regs();
}

void MC6800::interrupt(uint8_t which) {
	if(!which && (SR & FLAG_I) != 0) return;
	comp.memory_write(SP, PC & 0xFF);
	comp.memory_write(SP - 1, PC >> 8);
	comp.memory_write(SP - 2, X & 0xFF);
	comp.memory_write(SP - 3, X >> 8);
	comp.memory_write(SP - 4, A);
	comp.memory_write(SP - 5, B);
	comp.memory_write(SP - 6, SR);
	SP -= 7;
	if(which) PC = (comp.memory_read(0xFFFC) << 8) | comp.memory_read(0xFFFD);
	else PC = (comp.memory_read(0xFFF8) << 8) | comp.memory_read(0xFFF9);
}

void MC6800::print_regs() {
	printf("A: %02x B: %02x X: %04x PC: %04x\r\n", A, B, X, PC);
}
