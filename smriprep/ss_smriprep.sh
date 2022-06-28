#!/bin/bash
#SBATCH --time=3-00:00:00
#SBATCH --mem=20GB
#SBATCH --cpus-per-task=8
#SBATCH -J smriprep

set -eu # Stop on errors

##### CHANGE THESE VARIABLES AS NEEDED ######
IMG="" # path to smriprep container
module add openmind/singularity/3.9.5 # add singularity to path
scratch="" # path to working directory
#############################################

# Import arguments from job submission script
args=($@)
subjs=(${args[@]:1})
bids_dir=$1

# index slurm array to grab subject
subject=${subjs[${SLURM_ARRAY_TASK_ID}]}

# assign output directory
output_dir=${bids_dir}/derivatives

# remove FS IsRunning files
rm -f $output_dir/freesurfer/$subject/scripts/*Running*

# create single-subject bids directory in scratch space (speeds up smriprep initialization)
# This is fine for HPCs, but will add a lot of temporary storage usage, so be careful if you are using this on a space-limited drive!
if [ ! -d $scratch/${subject}_db/$subject ]; then mkdir -p ${scratch}/${subject}_db/$subject/anat
cp $bids_dir/dataset_description.json $scratch/${subject}_db/dataset_description.json 
cp $bids_dir/$subject/ses*/anat/* $scratch/${subject}_db/$subject/anat
fi;

# Define the command
cmd="singularity run -B ${scratch},${bids_dir} $IMG --participant_label ${subject:4} -w $scratch --fs-license-file ${bids_dir}/code/smriprep/license.txt $scratch/${subject}_db/ ${output_dir} participant"

# Run the command
echo "Submitted job for: ${subject}"
echo "$'Command :\n'${cmd}"
${cmd}
