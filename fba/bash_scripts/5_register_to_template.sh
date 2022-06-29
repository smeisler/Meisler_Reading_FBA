#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --mem=12GB
#SBATCH --cpus-per-task=8
#SBATCH -J fba_5

########## Register subjects to FOD template ##########

# Get variables from config
config=/PATH/TO/config
source $config

# Stop on error
set -eu

# Get subject name from job array
args=($@)
subjs=(${args[@]:0})
sub=${subjs[${SLURM_ARRAY_TASK_ID}]}
mkdir -p $outdir/$sub/template

echo "REGISTERING SUBJECT FOD TO TEMPLATE FOD"
$mrtrix mrregister $outdir/$sub/fodf/wmfod_norm.mif -mask1 $outdir/$sub/mask.mif $outdir/template/wmfod_template.mif -nl_warp $outdir/$sub/template/subject2template_warp.mif $outdir/$sub/template/template2subject_warp.mif -force

echo "APPLYING TRANSFORM TO SUBJECT MASK"
$mrtrix mrtransform $outdir/$sub/mask.mif -warp $outdir/$sub/template/subject2template_warp.mif -interp nearest -datatype bit $outdir/$sub/template/mask_template.mif -template $outdir/template/wmfod_template.mif -force

echo "WARP FODS TO TEMPLATE"
$mrtrix mrtransform $outdir/$sub/fodf/wmfod_norm.mif -warp $outdir/$sub/template/subject2template_warp.mif -template $outdir/template/wmfod_template.mif -reorient_fod no $outdir/$sub/template/fod_in_template_space_NOT_REORIENTED.mif -

echo "CREATING TEMPLATE MASK NIFTI OUTPUT FOR QC"
$mrtrix mrconvert $outdir/$sub/template/mask_template.mif $outdir/$sub/template/mask_template.nii.gz -force

echo "DONE, MAKE SURE ALL SUBJECTS ARE FINISHED AND VISUALLY QC THE BRAIN MASKS BEFORE PROCEEDING TO STEP 6"
