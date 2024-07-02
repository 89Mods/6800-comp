#!/bin/bash

set -e

../asl -cpu 6809 -olist kernal.lst kernal.asm
../p2bin kernal.p
