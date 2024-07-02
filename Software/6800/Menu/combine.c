#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

void main(int argc, char **argv) {
	if(argc < 2) {
		printf("Missing input filename\r\n");
		exit(1);
	}
	if(argc < 3) {
		printf("Missing output filename\r\n");
		exit(1);
	}
	if((argc - 3) % 2 != 0) {
		printf("Invalid list of inputs. Must be [program name] [file path] [program name] [file path] etc.\r\n");
		exit(1);
	}
	FILE *infil;
	infil = fopen(argv[1], "rb");
	fseek(infil, 0L, SEEK_END);
	uint32_t sz = ftell(infil);
	rewind(infil);
	if(sz > 16384) {
		printf("Input file too big (16K max)\r\n");
		fclose(infil);
		exit(1);
	}
	uint32_t total_written = 0;
	FILE *outfil;
	outfil = fopen(argv[2], "wb");
	total_written += fwrite("CHIRP!",1,7,outfil);
	uint8_t buffer[64];
	buffer[0] = sz & 0xFF;
	buffer[1] = (sz >> 8) & 0xFF;
	total_written += fwrite(buffer,1,2,outfil);
	while(1) {
		uint32_t read = fread(buffer,1,64,infil);
		if(read == 0) break;
		total_written += fwrite(buffer,1,read,outfil);
		if(read != 64) break;
	}
	fclose(infil);
	for(int i = 0; i < (argc - 3) / 2; i++) {
		char* name = argv[i*2+3];
		if(strlen(name) > 32) {
			printf("Name \"%s\" is too long (32 chars max)\r\n", name);
			continue;
		}
		char* fpath = argv[i*2+4];
		infil = fopen(fpath, "rb");
		fseek(infil, 0L, SEEK_END);
		uint32_t sz = ftell(infil);
		rewind(infil);
		if(sz > 16384) {
			printf("Input file %s too big (16K max)\r\n", fpath);
			fclose(infil);
			continue;
		}
		buffer[0] = 1;
		total_written += fwrite(buffer,1,1,outfil);
		total_written += fwrite(name,1,strlen(name)+1,outfil);
		buffer[0] = sz & 0xFF;
		buffer[1] = (sz >> 8) & 0xFF;
		total_written += fwrite(buffer,1,2,outfil);
		while(1) {
			uint32_t read = fread(buffer,1,64,infil);
			if(read == 0) break;
			total_written += fwrite(buffer,1,read,outfil);
			if(read != 64) break;
		}
	}
	buffer[0] = 0;
	total_written += fwrite(buffer,1,1,outfil);
	
	for(uint32_t i = total_written; i < 4*1024*1024; i++) {
		buffer[0] = 0xFF;
		fwrite(buffer,1,1,outfil);
	}
	
	fclose(outfil);
}
