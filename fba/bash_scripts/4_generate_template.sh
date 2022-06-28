#!/bin/bash
#SBATCH --time=48:00:00
#SBATCH --mem=100GB
#SBATCH --cpus-per-task=32
#SBATCH -J fba_4

########## Generate study-specific FOD template ##########

# Get variables from config
config=/om4/group/gablab/data/hbn_bids/code/fba/config
source $config

# Stop on error
set -eu

# Make directories for template subject inputs
mkdir -p $outdir/template/template_input/fod_input
mkdir -p $outdir/template/template_input/mask_input

# Load the template subject list generated using by the Jupyter notebooks.
# If creating manually, make a text fileput one subject per line in /PATH/TO/CODE/fba/subs_template.txt
subs_template_list=$base/code/fba/subs_template.txt 

echo "COPYING TEMPLATE SUBJECTS' FOD AND MASK DATA TO TEMPLATE DIRECTORY"
# symlink template subject data to template directory
while read -r line; do
sub="$line"
ln -srf $outdir/$sub/fodf/wmfod_norm.mif $outdir/template/template_input/fod_input/${sub}_wmfod_norm.mif
ln -srf $outdir/$sub/mask.mif $outdir/template/template_input/mask_input/${sub}_mask.mif
done < "$subs_template_list"

echo "GENERATING POPULATION TEMPLATE"
$mrtrix population_template $outdir/template/template_input/fod_input -mask_dir $outdir/template/template_input/mask_input $outdir/template/wmfod_template.mif -voxel_size 1.25 -scratch $scratch -linear_no_pause

echo "PRODUCING NIFTI OUTPUT OF TEMPLATE"
$mrtrix mrconvert $outdir/template/wmfod_template.mif $outdir/template/wmfod_template.nii.gz

echo "DONE, PLEASE PROCEED TO STEP 5"
