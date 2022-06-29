#!/bin/bash
config=/PATH/TO/config
source $config

fn_py="$base/code/fba/ConFixel/confixel/fixels.py" # path to fixels.py from ConFixel
relative_root="$outdir/template" # Where fba template files are

#Get list of metrics, loop through metrics
declare -a metrics=("fd" "fdc" "log_fc" "fa_DKI" "kfa_DKI" "md_DKI" "mk_DKI" "ICVF_NODDI" "ISOVF_NODDI" "OD_NODDI")

for metric in ${metrics[@]}; do
	# Define metric input files
	index_file="fixel_stats/${metric}_smooth/index.mif"
	directions_file="fixel_stats/${metric}_smooth/directions.mif"
	cohort_file="modelarray_inputs/cohort_${metric}.csv"
	output_hdf5="modelarray_inputs/fixels_${metric}.h5"

	cmd="python $fn_py"
	cmd+=" --index-file ${index_file}"
	cmd+=" --directions-file ${directions_file}"
	cmd+=" --cohort-file ${cohort_file}"
	cmd+=" --output-hdf5 ${output_hdf5}"
	cmd+=" --relative-root ${relative_root}"
	$cmd

	cohort_file="modelarray_inputs/cohort_${metric}_group.csv"
	output_hdf5="modelarray_inputs/fixels_${metric}_group.h5"

	cmd="python $fn_py"
	cmd+=" --index-file ${index_file}"
	cmd+=" --directions-file ${directions_file}"
	cmd+=" --cohort-file ${cohort_file}"
	cmd+=" --output-hdf5 ${output_hdf5}"
	cmd+=" --relative-root ${relative_root}"

	echo $cmd
	$cmd
	echo ""
done



