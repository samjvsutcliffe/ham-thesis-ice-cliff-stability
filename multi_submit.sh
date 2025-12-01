#!/bin/bash
set -e
#export OMP_PROC_BIND=spread,close
#export BLIS_NUM_THREADS=1
export REFINE=1
read -p "Do you want to clear previous data? (y/n)" yn
case $yn in
    [yY] ) echo "Removing data";rm -r output-*; rm -r data-cliff-stability; break;;
    [nN] ) break;;
esac
for h in 400
do
    for f in 0.95 0.9 0.8 0.7
    do
        export HEIGHT=$h
        export FLOATATION=$f
        sbcl --dynamic-space-size 16000  --disable-debugger --load "ice.lisp" --quit
       # sbatch batch_cliff_stab.sh
    done
done
