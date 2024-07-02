#!/bin/bash

set -e

../../../Kernal/asl -cpu 6800 -L -olist pong.lst pong.asm
../../../Kernal/p2bin pong.p
../a.out pong.bin ../current.bin
