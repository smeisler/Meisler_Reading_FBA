#!/bin/bash

# To run GAM models in array, run `bash /PATH/TO/submit_gams.sh`

# Get current directory
filepath=`realpath $0`
cwd=`dirname $filepath`
# Get list of models in directory
models=($(ls $cwd/run_gam*.r))
# Get number of models
len=$(expr ${#models[@]} - 1) # len - 1
echo Spawning ${#models[@]} sub-jobs.
# Spawn job array
sbatch --array=0-$len $cwd/run_gam.sh ${models[@]}
