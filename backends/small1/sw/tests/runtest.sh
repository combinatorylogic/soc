#!/bin/bash
set -e

for f in $*
do
    make $f.tst
done
