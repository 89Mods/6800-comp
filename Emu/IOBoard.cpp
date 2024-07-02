#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include "spiflash.h"
#include "IOBoard.h"
#include "cdp1855.h"
#include "6800.h"
#include "gpu.h"
#include "computer.h"

/*
 * "IOBoard" is a 82C55 interacting with a PS/2 keyboard interface implemented in 74-series logic
 * It also generates interrupts when a code is received from the keyboard
 * Secondly, there is a spiflash RAM, also connected to the 82C55 and a 7-segment BCD display which is not emulated here
 */

IOBoard::IOBoard(Computer& c) : comp(c) {
	reset();
}

void IOBoard::reset() {
	ctrl_word = 0b10011011;
	porta_setting = portb_setting = portc_setting = 0;
	porta_out = 0xFF;
	portb_in = 0;
	portc_in = 0;
	curr_sdi = 1;
	interrupt_latch = 0;
}

void IOBoard::step() {
	if(((ctrl_word >> 4) & 1) != 0) porta_out = 0xFF;
	else porta_out = porta_setting;
	if(((ctrl_word >> 3) & 1) != 0) bcd_val = 0xF;
	else bcd_val = portc_setting >> 4;
	led_state = (porta_out >> 4) & 1;
	
	curr_sdi = 1;
	if(((porta_out >> 3) & 1) != 0) flash.reset();
	else curr_sdi = flash.update((porta_out >> 2) & 1, (porta_out >> 1) & 1);
	portc_in &= 0xFE;
	portc_in |= curr_sdi;
	
	uint8_t shifter_reset = porta_out & 1;
	if(!shifter_reset) interrupt_latch = 0;
}

void IOBoard::write(uint8_t addr, uint8_t val) {
	addr &= 3;
	if(addr == 0) {
		//PORTA
		porta_setting = val;
	}else if(addr == 1) {
		//PORTB
		portb_setting = val;
	}else if(addr == 2) {
		//PORC
		portc_setting = val;
	}else if(addr == 3) {
		//Control
		if((val >> 7) != 0) {
			if(val != 0x83) printf("WARN: IO Board control word not 0x83, which will cause issues\r\n");
			ctrl_word = val;
		}else {
			uint8_t bit = (val >> 1) & 7;
			portc_setting &= ~(1 << bit);
			if((val & 1) != 0) portc_setting |= 1 << bit;
		}
	}
}

uint8_t IOBoard::read(uint8_t addr) {
	addr &= 3;
	if(addr == 0) {
		//PORTA
		if(((ctrl_word >> 4) & 1) != 0) return 0xFF;
		else return porta_setting;
	}else if(addr == 1) {
		//PORTB
		if(((ctrl_word >> 1) & 1) != 0) return portb_in;
		else return portb_setting;
	}else if(addr == 2) {
		//PORTC
		uint8_t res = 0;
		if(((ctrl_word >> 3) & 1) != 0) res |= 0xF0;
		else res |= portc_setting & 0xF0;
		if(((ctrl_word >> 0) & 1) != 0) res |= portc_in & 0x0F;
		else res |= portc_setting & 0x0F;
		return res;
	}
	return 0xFF;
}

uint8_t IOBoard::pending_interrupt() {
	return interrupt_latch;
}

unsigned char reverse(unsigned char b) {
   b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
   b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
   b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
   return b;
}

void IOBoard::set_ps2_val(uint8_t val) {
	interrupt_latch = 1;
	portb_in = reverse(val);
	portc_in &= 0b11110001;
	portc_in |= 4;
	uint8_t parity = 0;
	for(uint8_t i = 0; i < 8; i++) {
		parity = parity ^ ((val >> i) & 1);
	}
	if(!parity) portc_in |= 2;
}
