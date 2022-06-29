#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --mem=20GB
#SBATCH --cpus-per-task=16
#SBATCH -J fba_8b

########## Segment tracts on FOD template and make masks out of them ##########

# Get variables from config
config=/PATH/TO/config
source $config

# Stop on error
set -eu

echo 'GENERATING PEAKS FROM TEMPLATE FODS'
$mrtrix sh2peaks $outdir/template/wmfod_template.mif $outdir/template/peaks.nii.gz -force -mask $outdir/template/template_mask.mif

echo 'RUNNING TRACTSEG ON TEMPLATE FODS'
# Make output directory
ts_out=$outdir/template/tractseg
mkdir -p $ts_out
# Run tractseg pipelines
$tractseg TractSeg -i $outdir/template/peaks.nii.gz -o $ts_out
$tractseg TractSeg -i $outdir/template/peaks.nii.gz -o $ts_out --output_type endings_segmentation
$tractseg TractSeg -i $outdir/template/peaks.nii.gz -o $ts_out --output_type TOM 
$tractseg Tracking -i $outdir/template/peaks.nii.gz -o $ts_out --tracking_format tck --nr_fibers 10000

echo 'GENERATING FIXELS FROM TRACT TCKS'
mkdir -p $ts_out/tck_fixels
for tck in $ts_out/TOM_trackings/*.tck
	do tract=$(basename "$tck" .tck)
	$mrtrix tck2fixel $tck $outdir/template/fixel_mask $ts_out/tck_fixels $tract.mif
done

echo 'BINARIZING TRACT FIXEL MASKS'
for tract in $ts_out/tck_fixels/*.mif
	do $mrtrix mrthreshold $tract ${tract//.mif}_bin.mif -abs 1 -force
done

echo "DONE. IF 8a IS ALSO DONE, PROCEED TO STEP 9"
