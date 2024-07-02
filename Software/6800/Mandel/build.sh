#!/bin/bash

set -e

../../../Kernal/asl -cpu 6800 -L -olist mandel.lst mandel.asm
../../../Kernal/p2bin mandel.p
../a.out mandel.bin ../current.bin
