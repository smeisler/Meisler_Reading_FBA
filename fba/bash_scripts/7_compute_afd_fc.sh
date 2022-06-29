#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --mem=12GB
#SBATCH --cpus-per-task=4
#SBATCH -J fba_7

########## Compute Fiber Density (FD), Cross-Section (FC) and their product (FDC) ##########

# Get variables from config
config=/PATH/TO/config
source $config

# Stop on error
set -eu

# Get subject name from job array
args=($@)
subjs=(${args[@]:0})
sub=${subjs[${SLURM_ARRAY_TASK_ID}]}

# Make output directories
mkdir -p $outdir/template/fixel_stats/log_fc
mkdir -p $outdir/template/fixel_stats/fdc
mkdir -p $outdir/template/fixel_stats/fd

# Remove previous outputs if they exist
rm -rf $outdir/$sub/template/fixel_in_template_space_NOT_REORIENTED/
rm -rf $outdir/$sub/template/fixel_in_template_space/

if [ ! -d $outdir/$sub/template/fixel_in_template_space_NOT_REORIENTED ]; then echo "SEGMENTING FODS AND CALCULATING FD";
$mrtrix fod2fixel -mask $outdir/template/template_mask.mif $outdir/$sub/template/fod_in_template_space_NOT_REORIENTED.mif $outdir/$sub/template/fixel_in_template_space_NOT_REORIENTED -afd fd.mif
fi

echo "REORIENTING FIXELS"
$mrtrix fixelreorient $outdir/$sub/template/fixel_in_template_space_NOT_REORIENTED $outdir/$sub/template/subject2template_warp.mif $outdir/$sub/template/fixel_in_template_space -force

echo "ASSIGNING SUBJECT FIXELS TO TEMPLATE FIXELS"
$mrtrix fixelcorrespondence $outdir/$sub/template/fixel_in_template_space/fd.mif $outdir/template/fixel_mask $outdir/template/fixel_stats/fd ${sub}_fd.mif -force

echo "COMPUTING FC AND LOG FC"
$mrtrix warp2metric $outdir/$sub/template/subject2template_warp.mif -fc $outdir/template/fixel_mask $outdir/template/fixel_stats/fc ${sub}_fc.mif -force

cp $outdir/template/fixel_stats/fc/index.mif $outdir/template/fixel_stats/fc/directions.mif $outdir/template/fixel_stats/log_fc
$mrtrix mrcalc $outdir/template/fixel_stats/fc/${sub}_fc.mif -log $outdir/template/fixel_stats/log_fc/${sub}_log_fc.mif -force

echo "COMPUTING FDC"
cp $outdir/template/fixel_stats/fc/index.mif $outdir/template/fixel_stats/fdc
cp $outdir/template/fixel_stats/fc/directions.mif $outdir/template/fixel_stats/fdc
$mrtrix mrcalc $outdir/template/fixel_stats/fd/${sub}_fd.mif $outdir/template/fixel_stats/fc/${sub}_fc.mif -mult $outdir/template/fixel_stats/fdc/${sub}_fdc.mif -force

echo "DONE, MAKE SURE ALL SUBJECTS ARE FINISHED BEFORE PROCEEDING TO STEP 8 (a and b can be run concurrently)"
