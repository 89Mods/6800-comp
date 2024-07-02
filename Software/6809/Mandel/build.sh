#!/bin/bash

set -e

../../../Kernal/asl -cpu 6809 -L -olist mandel.lst mandel.asm
../../../Kernal/p2bin mandel.p
../../6800/a.out mandel.bin ../current.bin
