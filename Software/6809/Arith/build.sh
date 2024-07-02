#!/bin/bash

set -e

../../../Kernal/asl -cpu 6809 -L -olist arith.lst arith.asm
../../../Kernal/p2bin arith.p
../../6800/a.out arith.bin ../current.bin
