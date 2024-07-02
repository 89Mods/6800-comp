#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>

#include "spiflash.h"

Spiflash::Spiflash() {
	std::ifstream input("../Software/6800/current.bin", std::ios::binary | std::ios::in);
	input.seekg(0, std::ios::end);
	std::streamsize size = input.tellg();
	input.seekg(0, std::ios::beg);
	input.read((char*)ROM, size > 4*1024*1024 ? 4*1024*1024 : size);
	int read = input.tellg();
	input.close();
	printf("%d bytes read for spiflash\r\n", read);
	if(read < 4*1024*1024) for(int i = read; i < 4*1024*1024; i++) ROM[i] = 0xFF;
	reset();
}

void Spiflash::reset() {
	step_counter = 0;
	curr_sdo = 0;
	prev_clk = 0;
	data_in = 0;
	data_out = 0;
	cmd = 0;
	address_step = 0;
}

uint8_t Spiflash::update(uint8_t sck, uint8_t di) {
	if(sck == prev_clk) return curr_sdo;
	prev_clk = sck;
	if(!sck) return curr_sdo;
	data_in = data_in << 1;
	data_in |= di & 1;
	curr_sdo = (data_out >> 7) & 1;
	data_out <<= 1;
	step_counter++;
	if(step_counter == 8) {
		step_counter = 0;
		if(cmd == 0) {
			cmd = data_in;
			if(cmd == 0x90 || cmd == 0x03) {
				address = 0;
				address_step = 3;
			}else cmd = 0;
		}else if(address_step) {
			address <<= 8;
			address |= data_in;
			address_step--;
		}
		if(address_step == 0) {
			if(cmd == 0x90) {
				data_out = (address & 1) != 0 ? 0x15 : 0xEF;
				address++;
			}else if(cmd == 0x03) {
				data_out = ROM[address];
				address++;
			}
		}
	}
	return curr_sdo;
}
