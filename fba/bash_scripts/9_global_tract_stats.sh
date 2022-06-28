#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=2
#SBATCH -J fba_9

########## Calculate globally-averaged and tract-averaged fixel-stats ##########

# Get variables from config
config=/om4/group/gablab/data/hbn_bids/code/fba/config
source $config

# Stop on error
set -eu

# Get subject name from job array
args=($@)
subjs=(${args[@]:0})
sub=${subjs[${SLURM_ARRAY_TASK_ID}]}

# Make Output Directories
mkdir -p $outdir/template/fixel_stats/gfd
mkdir -p $outdir/template/fixel_stats/gfc
mkdir -p $outdir/template/fixel_stats/gfdc
mkdir -p $outdir/template/fixel_stats/glog_fc
mkdir -p $outdir/template/tractstats/fd/$sub
mkdir -p $outdir/template/tractstats/fc/$sub
mkdir -p $outdir/template/tractstats/fdc/$sub
mkdir -p $outdir/template/tractstats/log_fc/$sub

echo 'CALCULATING AND SAVING OUT GLOBAL FIXEL AVERAGES'
$mrtrix mrstats $outdir/template/fixel_stats/fd/${sub}_fd.mif -output mean > $outdir/template/fixel_stats/gfd/${sub}_gfd.txt
$mrtrix mrstats $outdir/template/fixel_stats/fc/${sub}_fc.mif -output mean > $outdir/template/fixel_stats/gfc/${sub}_gfc.txt
$mrtrix mrstats $outdir/template/fixel_stats/fdc/${sub}_fdc.mif -output mean > $outdir/template/fixel_stats/gfdc/${sub}_gfdc.txt
$mrtrix mrstats $outdir/template/fixel_stats/log_fc/${sub}_log_fc.mif -output mean > $outdir/template/fixel_stats/glog_fc/${sub}_glog_fc.txt

echo 'CALCULATING TRACT AVERAGED FIXEL METRICS'
pushd $outdir/template/tractseg/TOM_trackings/
for track in *tck
	do track_name=${track//.tck}
	$mrtrix mrstats $outdir/template/fixel_stats/fd/${sub}_fd.mif \
		-mask $outdir/template/tractseg/tck_fixels/${track_name}_bin.mif -output mean > $outdir/template/tractstats/fd/$sub/${track_name}.txt
	$mrtrix mrstats $outdir/template/fixel_stats/fc/${sub}_fc.mif \
		-mask $outdir/template/tractseg/tck_fixels/${track_name}_bin.mif -output mean > $outdir/template/tractstats/fc/$sub/${track_name}.txt
	$mrtrix mrstats $outdir/template/fixel_stats/fdc/${sub}_fdc.mif \
		-mask $outdir/template/tractseg/tck_fixels/${track_name}_bin.mif -output mean > $outdir/template/tractstats/fdc/$sub/${track_name}.txt
	$mrtrix mrstats $outdir/template/fixel_stats/log_fc/${sub}_log_fc.mif \
		-mask $outdir/template/tractseg/tck_fixels/${track_name}_bin.mif -output mean > $outdir/template/tractstats/log_fc/$sub/${track_name}.txt
done
popd

echo "DONE. PLEASE MAKE SURE ALL SUBJECTS ARE FINISHED AND DESIGN MATRICES/CONTRASTS ARE MADE BEFORE PROCEEDING TO STEP 10"
