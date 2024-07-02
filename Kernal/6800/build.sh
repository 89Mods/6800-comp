#!/bin/bash

set -e

../asl -cpu 6800 -L -olist kernal.lst kernal.asm
../p2bin kernal.p
