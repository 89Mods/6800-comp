#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <string>
#include <chrono>
namespace sc = std::chrono;

#include "gpu.h"

GPU::GPU() {
	cursor_blink_state = 0;
	last_blink = curr_time_millis();
	reset();
	for(int i = 0; i < 32768; i++) {
		character_buffer[i] = rand();
		color_buffer[i] = rand();
	}
	std::string line;
	std::ifstream charsfile("characters.txt");
	std::ifstream gfxfile("graphics.txt");
	if(!charsfile.is_open() || !gfxfile.is_open()) {
		printf("Unable to open files containing SCN2670 character ROM dumps\r\n");
		exit(1);
	}
	for(int i = 0; i < 128; i++) {
		if(!getline(charsfile, line)) {
			printf("Error parsing characters.txt: hit EOF too early");
			exit(1);
		}
		if(line[0] != '~') {
			printf("Error parsing characters.txt: format error in graphics separator");
			exit(1);
		}
		for(int j = 0; j < 16; j++) {
			if(!getline(charsfile, line)) {
				printf("Error parsing characters.txt: hit EOF too early");
				exit(1);
			}
			for(int k = 0; k < 10; k++) {
				ascii_chars[i + 128][j][k] = line[k] == '#' ? 1 : 0;
			}
		}
	}
	for(int i = 0; i < 128; i++) for(int j = 0; j < 16; j++) for(int k = 0; k < 10; k++) ascii_chars[i][j][k] = 1;
	for(int i = 0; i < 256; i++) {
		if(!getline(gfxfile, line)) {
			printf("Error parsing graphics.txt: hit EOF too early");
			exit(1);
		}
		if(line[0] != '~') {
			printf("Error parsing graphics.txt: format error in graphics separator");
			exit(1);
		}
		for(int j = 0; j < 16; j++) {
			if(!getline(gfxfile, line)) {
				printf("Error parsing graphics.txt: hit EOF too early");
				exit(1);
			}
			for(int k = 0; k < 10; k++) {
				graphics_chars[i][j][k] = line[k] == '#' ? 1 : 0;
			}
		}
	}
	
	charsfile.close();
	gfxfile.close();
}

void GPU::reset() {
	curr_ir = 0;
	busy = 0;
	initializing = 1;
	pixbuff = NULL;
	display_on = 0;
	is_blanking = 0;
	step_counter = 0;
}

long int GPU::curr_time_millis() {
	return sc::duration_cast<sc::milliseconds>(sc::system_clock::now().time_since_epoch()).count();
}

void GPU::step() {
	long int curr_t = curr_time_millis();
	if(curr_t - last_blink >= (cursor_blink_rate ? 1066 : 533)) {
		last_blink = curr_t;
		cursor_blink_state = !cursor_blink_state;
	}
	step_counter++;
	if((step_counter & 7) == 0) is_blanking = !is_blanking;
	if(cooldown_cycles == 0) return;
	cooldown_cycles--;
	if(cooldown_cycles > 0) return;
	character_buffer[write_targ] = char_latch;
	color_buffer[write_targ] = color_latch;
	busy = 0;
}

void GPU::allocate_pixbuff() {
	if(pixbuff) free(pixbuff);
	pixbuff = (uint8_t*)malloc((rows * 16 * columns * 10 + 10) * sizeof(uint8_t));
	if(!pixbuff) {
		printf("Could not allocate pixel buffer");
		exit(1);
	}
}

void GPU::write(uint8_t addr, uint8_t val) {
	addr &= 31;
	if((addr & 16) != 0) {
		addr &= 7;
		if(addr == 0) {
			//Init register
			//Most of this is ignored by the emulation. It trusts the code knows what its doing when it comes to real HW.
			if(curr_ir == 0 && (val & 3) != 0) printf("ERROR: SCN2674 being initialized into a mode other than Independent (not supported by emulator)\r\n");
			if(curr_ir == 1) printf("SCN2674: equalizing constant is %02x\r\n", val & 127);
			if(curr_ir == 4) {
				rows = (val & 127) + 1;
				blink_rate = val >> 7;
				allocate_pixbuff();
			}
			if(curr_ir == 5) {
				columns = val + 1;
				allocate_pixbuff();
			}
			if(curr_ir == 6) {
				cursor_start_line = val >> 4;
				cursor_end_line = val & 15;
				printf("SCN2674: Cursor from line %d to %d\r\n", cursor_start_line, cursor_end_line);
			}
			if(curr_ir == 7) {
				cursor_blinking = (val >> 5) & 1;
				cursor_blink_rate = (val >> 4) & 1;
				ul_position = val & 15;
			}
			if(curr_ir == 8) {
				display_start_addr = val;
			}
			if(curr_ir == 9) {
				display_start_addr |= (val & 15) << 8;
				display_end_addr = (val >> 4) * 1024 + 1023;
				printf("SCN2674: display buffer address range is %04x - %04x\r\n", display_start_addr, display_end_addr);
			}
			if(curr_ir == 10) {
				pointer_addr &= 0xFF00;
				pointer_addr |= val;
			}
			if(curr_ir == 11) {
				pointer_addr &= 0x00FF;
				pointer_addr |= (val & 0b00111111) << 8;
			}
			if(curr_ir == 14) {
				initializing = 0;
				printf("SCN2674: initialized\r\n");
			}
			if(curr_ir < 14) curr_ir++;
		}else if(addr == 1 && !busy) {
			//CMD
			if(val == 0) reset();
			if((val & 0xF0) == 0x10) curr_ir = val & 15;
			if((val & 0xE9) == 0x28) {
				//Display off
				display_on = 0;
			}
			if((val & 0xE9) == 0x29) {
				//Display on
				display_on = 1;
			}
			if((val & 0xF1) == 0x30) {
				//Cursor off
				cursor_enabled = 0;
			}
			if((val & 0xF1) == 0x31) {
				//Cursor on
				cursor_enabled = 1;
			}
			if((val & 0xE3) == 0x22) {
				//printf("SCN2674: GFX OFF (as it should be)\r\n");
			}
			if((val & 0xE3) == 0x23) {
				printf("SCN2674: GFX ON (unsupported) %02x\r\n", val);
			}
			//Done with Instantaneous commands
			//Interrupts not emulated because not used on real hardware
			if(val == 0b10100010) {
				//Write at pointer address
				write_targ = pointer_addr;
				cooldown_cycles = 8;
				busy = 1;
			}
			if(val == 0b10101001) {
				//Increment cursor address
				cursor_addr = (cursor_addr + 1) & 0x3FFF;
			}
			if(val == 0b10101010) {
				//Write at cursor address
				write_targ = cursor_addr;
				cooldown_cycles = 8;
				//printf("SCN2674: Write at cursor address\r\n");
				busy = 1;
			}
			if(val == 0b10101011) {
				//Write at cursor address and increment address
				write_targ = cursor_addr;
				cooldown_cycles = 8;
				cursor_addr = (cursor_addr + 1) & 0x3FFF;
				//printf("SCN2674: Write at cursor address and increment address\r\n");
				busy = 1;
			}
			//Done with delayed commands, these are all the real hardware supports
		}else if(addr == 2) {
			start_1 &= 0xFF00;
			start_1 |= val;
		}else if(addr == 3) {
			start_1 &= 0x00FF;
			start_1 |= val << 8;
		}else if(addr == 4) {
			cursor_addr &= 0xFF00;
			cursor_addr |= val;
		}else if(addr == 5) {
			cursor_addr &= 0x00FF;
			cursor_addr |= (val & 0b00111111) << 8;
		}else if(addr == 6) {
			start_2 &= 0xFF00;
			start_2 |= val;
		}else if(addr == 7) {
			start_2 &= 0x00FF;
			start_2 |= val << 8;
		}
	}else {
		if((addr & 8) != 0) color_latch = val;
		else char_latch = val;
	}
}

uint8_t GPU::read(uint8_t addr) {
	addr &= 31;
	if((addr & 16) != 0) {
		addr &= 7;
		if(addr == 0 || addr == 1) {
			//Status
			uint8_t val = (!busy) << 1;
			if(is_blanking) val |= 16;
			if(addr == 1) val |= ((!busy) || initializing) << 5;
			return val;
		}else if(addr == 2) {
			return start_1 & 0xFF;
		}else if(addr == 3) {
			return start_1 >> 8;
		}else if(addr == 4) {
			return cursor_addr & 0xFF;
		}else if(addr == 5) {
			return (cursor_addr >> 8) & 0b00111111;
		}else if(addr == 6) {
			return start_2 & 0xFF;
		}else if(addr == 7) {
			return (start_2 >> 8) & 0b00111111;
		}
	}
	return 0xFF;
}

uint8_t* GPU::render(uint16_t* width, uint16_t* height) {
	if(!pixbuff) return NULL;
	*width = columns * 10;
	*height = rows * 16;
	for(uint32_t i = 0; i < *width * *height; i++) pixbuff[i] = 0;
	if(!display_on) {
		return pixbuff;
	}
	for(uint32_t i = 0; i < rows; i++) {
		for(uint32_t j = 0; j < columns; j++) {
			uint16_t addr = ((i * columns + j) % (display_end_addr - display_start_addr)) + display_start_addr;
			addr |= cursor_addr & 0xC000;
			uint8_t has_cursor = ((addr+1) & 0x3FFF) == (cursor_addr & 0x3FFF) && cursor_enabled;
			if(cursor_blinking && !cursor_blink_state) has_cursor = 0;
			uint8_t character = character_buffer[addr];
			uint8_t is_gfx = (color_buffer[addr] & 1) != 0;
			uint8_t has_underline = (color_buffer[addr+1] & 2) != 0;
			uint8_t color = (color_buffer[addr+1] >> 2) & 0b111111;
			
			uint32_t start_pos = j * 10 + i * 16 * *width;
			for(int k = 0; k < 16; k++) {
				for(int l = 0; l < 10; l++) {
					uint8_t pixel = 0;
					if(is_gfx) {
						pixel = graphics_chars[character][k][l];
					}else {
						pixel = ascii_chars[character][k][l];
					}
					pixel |= has_underline && k == 15;
					if(has_cursor && k >= cursor_start_line && k <= cursor_end_line) pixel = !pixel;
					
					pixbuff[start_pos + l + k * *width] = pixel ? color & 0b111 : color >> 3;
				}
			}
		}
	}
	return pixbuff;
}
