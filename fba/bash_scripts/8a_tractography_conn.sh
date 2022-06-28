#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --mem=64GB
#SBATCH --cpus-per-task=16
#SBATCH -J fba_8a

########## Run tractography on FOD template and smooth fixel-metrics based on fixel connectivity ##########

# Get variables from config
config=/om4/group/gablab/data/hbn_bids/code/fba/config
source $config

# Stop on error
set -eu

echo "GENERATING TRACTOGRAM"
$mrtrix tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 $outdir/template/wmfod_template.mif -seed_image $outdir/template/template_mask.mif -mask $outdir/template/template_mask.mif -select 20000000 -cutoff 0.06 $outdir/template/tracks_20_million.tck

echo "FILTERING TRACTOGRAM WITH SIFT"
$mrtrix tcksift $outdir/template/tracks_20_million.tck $outdir/template/wmfod_template.mif $outdir/template/tracks_2_million_sift.tck -term_number 2000000

echo "GENERATING FIXEL-FIXEL CONNECTIVITY"
$mrtrix fixelconnectivity $outdir/template/fixel_mask/ $outdir/template/tracks_2_million_sift.tck $outdir/template/matrix/

echo "SMOOTHING FIXEL DATA"
$mrtrix fixelfilter $outdir/template/fixel_stats/fd smooth $outdir/template/fixel_stats/fd_smooth -matrix $outdir/template/matrix/
$mrtrix fixelfilter $outdir/template/fixel_stats/log_fc smooth $outdir/template/fixel_stats/log_fc_smooth -matrix $outdir/template/matrix/
$mrtrix fixelfilter $outdir/template/fixel_stats/fdc smooth $outdir/template/fixel_stats/fdc_smooth -matrix $outdir/template/matrix/

echo "DONE. IF 8b IS ALSO DONE, PROCEED TO STEP 9"
