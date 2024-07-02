#!/bin/bash

set -e

../../../Kernal/asl -cpu 6809 -L -olist develop.lst develop.asm
../../../Kernal/p2bin develop.p
../../6800/a.out develop.bin ../current.bin
