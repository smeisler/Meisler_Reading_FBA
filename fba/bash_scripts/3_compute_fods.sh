#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --mem=16GB
#SBATCH --cpus-per-task=8
#SBATCH -J fba_3

########## Compute fiber orientation distribution functions (FODs) ##########

# Get variables from config
config=/om4/group/gablab/data/hbn_bids/code/fba/config
source $config

# Stop on error
set -eu

# Get subject name from job array
args=($@)
subjs=(${args[@]:0})
sub=${subjs[${SLURM_ARRAY_TASK_ID}]}
echo $sub

# Define subject FOD output directory
fod_out=$outdir/$sub/fodf

declare -a sites=("SI" "CUNY" "CBIC" "RU")
# Make sure we get the right site FRFs
for site_test in ${sites[@]};
do if [ -d $base/$sub/ses-HBNsite${site_test} ];
then site=$site_test; fi;
done

# Estimate the FODs

if [ $single_multi = "single" ]; then
	# USE SINGLE SHELL 3TISSUE ALGORITHM FOR SINGLE SHELL
	echo 'Estimate FODs with Single Shell 3 Tissue Algorithm'
	$mrtrix3t ss3t_csd_beta1 $fod_out/dwi_fodf.mif \
	$outdir/${site}_average_response_wm.txt $fod_out/wmfod.mif \
	$outdir/${site}_average_response_gm.txt $fod_out/gm.mif \
	$outdir/${site}_average_response_csf.txt $fod_out/csf.mif \
	-mask $outdir/$sub/mask.mif -force -scratch $scratch
else
	# USE MULTISHELL MULTI TISSUE ALGORITHM FOR MULTISHELL
	echo 'Estimate FODs with Multi Shell Multi Tissue Algorithm'
	$mrtrix dwi2fod msmt_csd $fod_out/dwi_fodf.mif \
	$outdir/${site}_average_response_wm.txt $fod_out/wmfod.mif \
	$outdir/${site}_average_response_gm.txt $fod_out/gm.mif \
	$outdir/${site}_average_response_csf.txt $fod_out/csf.mif \
	-mask $outdir/$sub/mask.mif -force -scratch $scratch
fi

echo 'Normalizing FODs'
$mrtrix mtnormalise $fod_out/wmfod.mif $fod_out/wmfod_norm.mif \
$fod_out/gm.mif $fod_out/gm_norm.mif \
$fod_out/csf.mif $fod_out/csf_norm.mif \
-mask $outdir/$sub/mask.mif -force

echo 'Obtaining FOD Peaks'
$mrtrix sh2peaks $fod_out/wmfod_norm.mif $fod_out/peaks.nii.gz -mask $outdir/$sub/mask.mif -force

echo "DONE, MAKE SURE ALL SUBJECTS ARE FINISHED AND TEMPLATE SUBJECTS ARE DETERMINED BEFORE PROCEEDING TO STEP 4."
