#!/bin/bash

# Get variables from config
config=/PATH/TO/config
source $config

# Stop on error
set -eu

# Identify right file
# Exmaple - $outdir/template/modelarray_outputs/mifs_${metric}_${subtest}${suffix}
metric='fdc' #  log_fc, fd, or fdc
subtest='TOWRE' # swe or pde
suffix='_eff' # in case there's additional text, otherwise leave as an empty string

# Create output textfile
out_file=$outdir/template/modelarray_outputs/${metric}_${subtest}${suffix}_tract_fixels.txt
touch $out_file

# Threshold fixel data at given p-val FDR
p_fdr=0.05
$mrtrix mrthreshold $outdir/template/modelarray_outputs/mifs_${metric}_${subtest}${suffix}/result_gam_${subtest}_DM.p.value.fdr.mif $outdir/template/modelarray_outputs/mifs_${metric}_${subtest}${suffix}/sig_fixels.mif -abs ${p_fdr} -comparison lt -force

# Loop over tract masks
for track in $outdir/template/tractseg/tck_fixels/*bin*;
	# Calculate proportion of tract occupied by significant fixels
	do proportion=$($mrtrix mrstats $outdir/template/modelarray_outputs/mifs_${metric}_${subtest}${suffix}/sig_fixels.mif -mask $track -output mean); 
	# Get number of significant fixels per tract
	count_tract=$($mrtrix mrstats $outdir/template/modelarray_outputs/mifs_${metric}_${subtest}${suffix}/sig_fixels.mif -mask $track -output count);
	# Get number of total fixles per tract
	num_fixels=$(echo "$proportion * $count_tract" | bc);
	# Get max effect size achieved in tract
	max_eff_tract=$($mrtrix mrstats $outdir/template/modelarray_outputs/mifs_${metric}_${subtest}${suffix}/result_gam_${subtest}_DM.delta.adj.rsq.mif -mask $track -output max);
	# Add information to text file
	echo $(basename $track) >> $out_file;
	printf "%.0f\n" $num_fixels >> $out_file;
	echo $proportion >> $out_file;
	echo $max_eff_tract >> $out_file;
done
