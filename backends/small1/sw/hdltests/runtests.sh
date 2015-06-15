#!/bin/bash


for f in *.c
do
    make $f.hex
    out="_out"
    cp $f$out/*.v ../../hw/custom/
    (cd ../../hw/soc/logipi/verilated/; make clean; make exe)
    make $f.tst
done
