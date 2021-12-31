#!/bin/bash
#SBATCH --time=3-00:00:00
#SBATCH --mem=20GB
#SBATCH --cpus-per-task=8
#SBATCH -J smriprep
set -eu

##### CHANGE THESE VARIABLES AS NEEDED ######
IMG='' # Put singularity image here
ses='ses-HBNsiteCBIC'
module add openmind/singularity/3.6.3 # Add singularity to path
#############################################

# Import arguments from job submission script
args=($@)
subjs=(${args[@]:1})
bids_dir=$1

# index slurm array to grab subject
subject=${subjs[${SLURM_ARRAY_TASK_ID}]}

# assign working directory
scratch=/om/scratch/Mon/$(whoami)/smriprep
# assign output directory
output_dir=${bids_dir}/derivatives

# create single-subject bids directory in scratch space (speeds up smriprep initialization)
# This is fine for HPCs, but will add a lot of temporary storage usage, so be careful if you are using this on a space-limited drive!
mkdir -p ${scratch}/${subject}_db/$subject/$ses/anat
cp $bids_dir/dataset_description.json $scratch/${subject}_db/dataset_description.json 
cp $bids_dir/$subject/$ses/anat/* $scratch/${subject}_db/$subject/$ses/anat

# Define the command
cmd="singularity run -B ${scratch},${bids_dir} $IMG --participant_label ${subject:4} -w $scratch --fs-license-file ${bids_dir}/code/smriprep/license.txt $scratch/${subject}_db/ ${output_dir} participant"

# Run the command
echo Submitted job for: ${subject}
echo $'Command :\n'${cmd}
${cmd}
