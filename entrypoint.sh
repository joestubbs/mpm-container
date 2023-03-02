#!/bin/bash

# Configure MPI libraries
source /opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/bin/mpivars.sh


# Debug statements -----
#echo "first arg: $1" 
#echo "second arg: $2"
#echo "target output directory: $2output" 


# Ensure the output directory exists
mkdir -p /TapisOutput/results

# Create symlink from the Tapis output directory to the results directory
ln -s /TapisOutput/results $2results

# Run mpm, piping stdout to the Tapis output moutpint
./mpm "$@" > /TapisOutput/stdout 

