#!/bin/bash

set -e

../../Kernal/asl -cpu 6800 -L -olist develop.lst develop.asm
../../Kernal/p2bin develop.p
../a.out develop.bin ../current.bin
