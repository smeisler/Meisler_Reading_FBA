## 1) Preprocess DWI and T1 (qsiprep and smriprep)
- Download the `qsiprep` and `smriprep` folders to your BIDS code folder. In them, add your FreeSurfer license as `license.txt` (case-sensitive).
- In the `submit_job_array.sh` scripts, udpate the variable `bids` in the beginning of the scripts to direct to your BIDS directory. Additionally, in the last line of the scripts, you can update the parameter after `%` to limit how many jobs can be active at a time. We set this to 100 as a default, but you can alter this or delete it to not set a limit.
- In the `ss_XXXX.sh` scripts, change the SBATCH headers to match your desired parameters (e.g. memory usage, time-to-wall, etc). Then update the variable `IMG` to the path of the corresponding singularity images. Set the variable `scratch` to where you want intermediate files to be stored during the workflows. Review the command at the bottom of the script to make sure you understand how QSIPrep and sMRIprep are being run and change any parameters you would like.
- In terminal, navigate to the `qsiprep` or `smriprep` folder, and run `./submit_job_array.sh` to begin the workflow.