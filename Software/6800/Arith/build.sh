#!/bin/bash

set -e

../../../Kernal/asl -cpu 6800 -L -olist arith.lst arith.asm
../../../Kernal/p2bin arith.p
../a.out arith.bin ../current.bin
