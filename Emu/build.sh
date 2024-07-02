#!/bin/bash

set -e

CFLAGS=$(pkg-config gtkmm-4.0 --cflags)
LDFLAGS=$(pkg-config gtkmm-4.0 --libs)
g++ -o emu.o -c ${CFLAGS} emu.cpp
g++ -o 6800.o -c ${CFLAGS} 6800.cpp
g++ -o spiflash.o -c ${CFLAGS} spiflash.cpp
g++ -o IOBoard.o -c ${CFLAGS} IOBoard.cpp
g++ -o cdp1855.o -c ${CFLAGS} cdp1855.cpp
g++ -o gpu.o -c ${CFLAGS} gpu.cpp
g++ -o computer.o -c ${CFLAGS} computer.cpp
g++ -o emu ${LDFLAGS} emu.o 6800.o spiflash.o IOBoard.o cdp1855.o gpu.o computer.o
