#!/bin/bash
#SBATCH --time=4-00:00:00
#SBATCH --mem=50GB
#SBATCH --cpus-per-task=24
#SBATCH -J ModelArray
#SBATCH -p gablab

config=/PATH/TO/config
source $config

set -eu # Stop on errors
# Get model from list of models
args=($@)
models=(${args[@]:0})
model=${models[${SLURM_ARRAY_TASK_ID}]}

# Run Model
echo $model
$Rscript $model "$outdir"
