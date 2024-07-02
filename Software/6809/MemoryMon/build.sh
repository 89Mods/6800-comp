#!/bin/bash

set -e

../../../Kernal/asl -cpu 6809 -L -olist mon.lst mon.asm
../../../Kernal/p2bin mon.p
../../6800/a.out mon.bin ../current.bin
