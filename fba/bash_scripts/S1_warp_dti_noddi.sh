#!/bin/bash
#SBATCH --time=4:00:00
#SBATCH --mem=8GB
#SBATCH --cpus-per-task=8
#SBATCH -J fba_12

########## Warp DTI, DKI, and NODDI metrics to template space fixels, and smooth them across fiber populations ##########

# Stop on error
set -eu

# Get variables from config
config=/om4/group/gablab/data/hbn_bids/code/fba/config
source $config

# Get subject name from job array
args=($@)
subjs=(${args[@]:0})
sub=${subjs[${SLURM_ARRAY_TASK_ID}]}

# Make Output and Temporary Directories
mkdir -p $outdir/$sub/template/warped_dti_noddi
mkdir -p $scratch/$sub/temp_dti_noddi/

echo 'WARPING DTI AND NODDI METRICS'
declare -a metrics=("fa_DKI" "md_DKI" "kfa_DKI" "mk_DKI" "ICVF_NODDI" "OD_NODDI")
for metric in ${metrics[@]}; do
	# Reorient scalar map to FSL
	$fsl fslreorient2std $qsirecon_dir/$sub/ses*/dwi/*desc-preproc_desc-${metric}.nii.gz $scratch/$sub/temp_dti_noddi/${metric}_reorient.nii.gz
	# Warp map to template space
	$mrtrix mrtransform $scratch/$sub/temp_dti_noddi/${metric}_reorient.nii.gz $outdir/$sub/template/warped_dti_noddi/${metric}_template.nii.gz \
	-template $outdir/template/wmfod_template.mif -warp $outdir/$sub/template/subject2template_warp.mif -force
	# Map voxel data to fixels
	mkdir -p /$outdir/template/fixel_stats/$metric/
	$mrtrix voxel2fixel $outdir/$sub/template/warped_dti_noddi/${metric}_template.nii.gz $outdir/template/fixel_mask/ $outdir/template/fixel_stats/$metric/ ${sub}_${metric}.mif -force
	# Smooth data across fiber populations
	mkdir -p /$outdir/template/fixel_stats/${metric}_smooth/
	echo "SMOOTHING FIXEL DATA"
	$mrtrix fixelfilter $outdir/template/fixel_stats/$metric smooth $outdir/template/fixel_stats/${metric}_smooth -matrix $outdir/template/matrix/

done
echo "DONE."
