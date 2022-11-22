#!/bin/bash
subjs=($@) # You can run 'submit_job_array.sh sub-xx sub-xy' to only run specific subjects
base='' # PUT YOUR BIDS DIRECTORY HERE

# Get subject names from the directory
if [[ $# -eq 0 ]]; then
    pushd $base
    subjs=($(ls sub-* -d))
    popd
fi

# take the length of the array
# this will be useful for indexing later
len=$(expr ${#subjs[@]} - 1) # len - 1

echo Spawning ${#subjs[@]} sub-jobs.

sbatch --array=0-$len%100 $base/code/smriprep/ss_smriprep.sh $base ${subjs[@]}
