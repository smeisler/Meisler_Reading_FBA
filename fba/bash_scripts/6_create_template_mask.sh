#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --mem=16GB
#SBATCH --cpus-per-task=8
#SBATCH -J fba_6

########## Make study-specific analysis mask in template space ##########

# Get variables from config
config=/PATH/TO/config
source $config

# Stop on error
set -eu

echo "CALCULATING INTERSECTION OF ALL SUBJECT MASKS TO GENERATE SINGLE TEMPLATE MASK"
$mrtrix mrmath $outdir/sub*/template/mask_template.mif min $outdir/template/template_mask.mif -datatype bit -force
$mrtrix mrconvert $outdir/template/template_mask.mif $outdir/template/template_mask.nii.gz -force

echo "GENERATING TEMPLATE FIXEL MASK"
$mrtrix fod2fixel -mask $outdir/template/template_mask.mif -fmls_peak_value 0.06 -force $outdir/template/wmfod_template.mif $outdir/template/fixel_mask

echo "DONE, PLEASE PROCEED TO STEP 7"
