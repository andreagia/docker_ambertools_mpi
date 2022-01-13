#!/bin/bash
#
# amber_run.sh - This script is meant to run on Grid or Container
#

[ -z "$AMBERMPI" ] && RUN=$AMBERHOME/bin/sander || RUN="mpirun -np 8 sander.MPI"

tar xvfz in.tgz

#AMBER_COMMAND
$RUN -O -i sander0.in -o sander0.out -p prmtop -c prmcrd -r sander0.crd -ref  prmcrd
$AMBERHOME/bin/ambpdb -p prmtop -c sander0.crd > amber_final0.pdb
#perl gettensor.pl sander0.out
$RUN -O -i sander1.in -o sander1.out -p prmtop -c sander0.crd -r sander1.crd -ref  sander0.crd

tar cvfz pro.tgz ./* --exclude in.tgz --exclude run_amber.sh --exclude gettensor.pl
