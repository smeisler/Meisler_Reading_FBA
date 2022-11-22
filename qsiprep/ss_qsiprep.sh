#!/bin/bash
#SBATCH --time=3-00:00:00
#SBATCH --mem=20GB
#SBATCH --cpus-per-task=8
#SBATCH -J qsiprep
set -eu # Stop on errors

##### CHANGE THESE VARIABLES AS NEEDED ######
IMG='' # put path to qsiprep docker image here
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

# create single-subject bids directory in scratch space (speeds up qsiprep initialization)
mkdir -p ${scratch}/${subject}_db/derivatives/qsiprep
ln -sf $bids_dir/dataset_description.json $scratch/${subject}_db/dataset_description.json 
ln -sf $bids_dir/$subject $scratch/${subject}_db/$subject
ln -sf $bids_dir/derivatives/qsiprep/$subject/ $scratch/${subject}_db/derivatives/qsiprep/


# define the command
cmd="singularity run -B ${scratch},${bids_dir},${output_dir} $IMG --participant_label ${subject:4} -w $scratch --recon-only --recon-input $scratch/${subject}_db/derivatives/qsiprep/ --recon-spec ${bids_dir}/code/qsiprep/dki_noddi_recon.json --fs-license-file ${bids_dir}/code/qsiprep/license.txt --skip-bids-validation $scratch/${subject}_db/ ${output_dir} participant"

# run the command
echo "Submitted job for: ${subject}"
echo $'Command :\n'${cmd}
${cmd}
