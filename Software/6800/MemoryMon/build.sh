#!/bin/bash

set -e

../../../Kernal/asl -cpu 6800 -L -olist mon.lst mon.asm
../../../Kernal/p2bin mon.p
../a.out mon.bin ../current.bin
