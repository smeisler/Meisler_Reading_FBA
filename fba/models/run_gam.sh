#!/bin/bash
#SBATCH --time=7-00:00:00
#SBATCH --mem=50GB
#SBATCH --cpus-per-task=32
#SBATCH -J ModelArray

#module add openmind/singularity/3.9.5
config=/PATH/TO/config
source $config

set -eu # Stop on errors
# Get model from list of models
args=($@)
models=(${args[@]:0})
model=${models[${SLURM_ARRAY_TASK_ID}]}
IMG=/PATH/TO/modelarray_0.1.2.img
# Run Model
echo $model

singularity exec -B $base,$model --cleanenv ${IMG} Rscript $model "$outdir"
