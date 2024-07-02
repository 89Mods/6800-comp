#!/bin/bash

set -e

../../../Kernal/asl -cpu 6809 -L -olist menu.lst menu.asm
../../../Kernal/p2bin menu.p
./a.out menu.bin ../current.bin ../../6800/current.bin "Memory Monitor" ../MemoryMon/mon.bin "Mandelbrot" ../Mandel/mandel.bin "Arith Test" ../Arith/arith.bin "Keyboard Test" ../Develop_KB/develop.bin
