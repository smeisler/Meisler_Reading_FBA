#!/bin/bash

# RUN PROCESSING STEPS THAT RUN ON PARTICIPANTS INDIVIDUALLY IN PARALLEL

# Get variables from config
config=/om4/group/gablab/data/hbn_bids/code/fba/config
source $config

subjs=$@
# Get subject names
pushd $qsiprep_dir
subjs=($(ls sub*/ -d))
subjs=("${subjs[@]///}")
popd

# take the length of the array
# this will be useful for indexing later
len=$(expr ${#subjs[@]} - 1) # len - 1
echo Spawning ${#subjs[@]} sub-jobs.

if [ "$1" = "1" ]; then
	script=1_individual_responses.sh
	echo "Running Step 1: Computing Individual Fiber Repsonses"
elif [ "$1" = "3" ]; then
	echo "Running Step 3: Computing FODs"
	script=3_compute_fods.sh
elif [ "$1" = "5" ]; then
	echo "Running Step 5: Registering to Template"
	script=5_register_to_template.sh
elif [ "$1" = "7" ]; then
	echo "Running Step 7: Computing AFD and FC"
	script=7_compute_afd_fc.sh
elif [ "$1" = "9" ]; then
	echo "Running Step 9: Computing Global and Tract Average Stats"
	script=9_global_tract_stats.sh
elif [ "$1" = "S1" ]; then
	echo "Running Step S1: Warping DTI and NODDI Metrics"
	script=S1_warp_dti_noddi.sh
else
	echo "Please enter either '1', '3', '5', '7', '9', or 'S1'. For other steps, just run 'sbatch SCRIPTNAME' "
	exit
fi

sbatch --array=0-$len%100 $base/code/fba/bash_scripts/$script ${subjs[@]}
