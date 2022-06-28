#!/bin/bash
#SBATCH --time=3-00:00:00
#SBATCH --mem=20GB
#SBATCH --cpus-per-task=8
#SBATCH -J qsiprep
set -eu # Stop on errors

##### CHANGE THESE VARIABLES AS NEEDED ######
IMG='' # put path to qsiprep docker image here
module add openmind/singularity/3.9.5 # add singularity to path
scratch='' # assign working directory
#############################################

# Import arguments from job submission script
args=($@)
subjs=(${args[@]:1})
bids_dir=$1

# index slurm array to grab subject
subject=${subjs[${SLURM_ARRAY_TASK_ID}]}

# assign output directory
output_dir=${bids_dir}/derivatives
mkdir -p ${output_dir}

# create single-subject bids directory in scratch space (speeds up smriprep initialization)
# This is fine for HPCs, but will add a lot of temporary storage usage, so be careful if you are using this on a space-limited drive!
mkdir -p ${scratch}/${subject}_db
ln -sf $bids_dir/dataset_description.json $scratch/${subject}_db/dataset_description.json 
ln -sf $bids_dir/$subject $scratch/${subject}_db/$subject

# define the command
cmd="singularity run -B ${scratch},${bids_dir},${output_dir} $IMG --participant_label ${subject:4} -w $scratch --recon-only --recon-input ${output_dir}/derivatives/qsiprep --recon-spec ${bids_dir}/code/qsiprep/dki_noddi_recon.json --fs-license-file ${bids_dir}/code/qsiprep/license.txt --skip-bids-validation $scratch/${subject}_db/ ${output_dir} participant"

# run the command
echo "Submitted job for: ${subject}"
echo $'Command :\n'${cmd}
${cmd}
