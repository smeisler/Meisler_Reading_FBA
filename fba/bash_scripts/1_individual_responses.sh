#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --mem=12GB
#SBATCH --cpus-per-task=8
#SBATCH -J fba_1

########## Reorient subject data and fit their fiber response functions (FRFs) ##########

# Get variables from config
config=/PATH/TO/config
source $config

#Stop on error
set -eu

# Get subject name from job array
args=($@)
subjs=(${args[@]:0})
sub=${subjs[${SLURM_ARRAY_TASK_ID}]}
echo "Running script 1 on $sub"

# Make output and scratch directories
mkdir -p $scratch/$sub
mkdir -p $outdir/$sub/fodf

# Define where to find qsiprep outputs
qsiprep_sub=$qsiprep_dir/$sub
#################################################

# Begin Running
echo "REORIENTING FILES TO FSL STANDARD"
$fsl fslreorient2std ${qsiprep_sub}/anat/${sub}_desc-preproc_T1w.nii.gz $outdir/$sub/T1w.nii.gz
$fsl fslreorient2std ${qsiprep_sub}/ses*/dwi/*-preproc_dwi.nii.gz $scratch/$sub/dwi_orig.nii.gz
$fsl fslreorient2std ${qsiprep_sub}/ses*/dwi/*_mask.nii.gz $scratch/$sub/mask_orig.nii.gz

echo "CORRECTING GRADIENTS"
$mrtrix dwigradcheck $scratch/$sub/dwi_orig.nii.gz \
	-mask $scratch/$sub/mask_orig.nii.gz -grad ${qsiprep_sub}/ses*/dwi/*.b \
	-export_grad_mrtrix $scratch/$sub/grad.b -scratch $scratch -force

echo "UPSAMPLING DWI AND MASK"
$mrtrix mrconvert $scratch/$sub/dwi_orig.nii.gz $scratch/$sub/dwi_orig.mif -grad $scratch/$sub/grad.b -force
$mrtrix mrgrid $scratch/$sub/dwi_orig.mif regrid -vox 1.25 $scratch/$sub/dwi.mif -force
$mrtrix mrgrid $scratch/$sub/mask_orig.nii.gz regrid -template $scratch/$sub/dwi.mif $outdir/$sub/mask.mif -interp nearest -force
$mrtrix mrconvert $outdir/$sub/mask.mif $outdir/$sub/mask.nii.gz -force

echo "EXTRACTING FODF SHELLs"
$mrtrix dwiextract -shells 0,$fodf_shells $scratch/$sub/dwi.mif $outdir/$sub/fodf/dwi_fodf.mif -force

echo 'ESTIMATING RESPONSE FUNCTION OF WM, GM, CSF (USING dhollander ALGORITHM)'
$mrtrix dwi2response dhollander $outdir/$sub/fodf/dwi_fodf.mif $outdir/$sub/fodf/response_wm.txt $outdir/$sub/fodf/response_gm.txt $outdir/$sub/fodf/response_csf.txt \
-mask $outdir/$sub/mask.mif -scratch $scratch -force

echo "DONE, MAKE SURE ALL SUBJECTS ARE FINISHED BEFORE PROCEEDING TO STEP 2"
