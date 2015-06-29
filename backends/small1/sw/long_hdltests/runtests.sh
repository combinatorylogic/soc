#!/bin/bash
set -e

for f in *.c
do
    make $f.hex
    out="_out"
    cp $f$out/*.v ../../hw/custom/
    (cd ../../hw/soc/logipi/verilated/; make exe)
    make $f.tst
done
