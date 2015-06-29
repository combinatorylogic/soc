#!/bin/bash
set -e

for f in *.c
do
    make $f.tst
done
