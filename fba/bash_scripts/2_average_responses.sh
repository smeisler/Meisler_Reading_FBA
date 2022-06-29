#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --mem=8GB
#SBATCH --cpus-per-task=8
#SBATCH -J fba_2

########## Average FRFs across sites ##########
# Get variables from config
config=/PATH/TO/config
source $config

# Stop on error
set -eu

echo "AVERAGING TISSUE RESPONSES"
pushd $outdir

declare -a sites=("SI" "CUNY" "CBIC" "RU")
for site in ${sites[@]}; do
# Check is site is applicable to subject, and if so, append subject's FRF file to array to average
# WM Response
frfs_site=()
for sub in sub*; do if [ -d $base/$sub/ses-HBNsite$site/ ]; then frfs_site+=("$outdir/$sub/fodf/response_wm.txt"); fi; done;
$mrtrix responsemean ${frfs_site[@]} $outdir/${site}_average_response_wm.txt -force
# GM Response
frfs_site=()
for sub in sub*; do if [ -d $base/$sub/ses-HBNsite$site/ ]; then frfs_site+=("$outdir/$sub/fodf/response_gm.txt"); fi; done;
$mrtrix responsemean ${frfs_site[@]} $outdir/${site}_average_response_gm.txt -force
# CSF Response
frfs_site=()
for sub in sub*; do if [ -d $base/$sub/ses-HBNsite$site/ ]; then frfs_site+=("$outdir/$sub/fodf/response_csf.txt"); fi; done;
$mrtrix responsemean ${frfs_site[@]} $outdir/${site}_average_response_csf.txt -force

done
popd

echo "DONE, PLEASE PROCEED TO STEP 3"
