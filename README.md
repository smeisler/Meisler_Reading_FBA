# Meisler_Reading_FBA

To cite:
Steven Lee MeislerJohn Gabrieli (2022) Fiber-specific structural properties relate to reading skills in children and adolescents eLife 11:e82088.
[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.18914.svg)](https://doi.org/10.7554/eLife.82088)

Code used in the Meisler and Gabrieli 2022 paper on fixel based analyses relating to reading abilities. Please clone these folders to your BIDS code directory (you can delete the LICENSE and README files from there afterwards). For model and tract segmentation outputs that can be viewed with MRview, please visit https://osf.io/3ady4/.

For this study, we began with already preprocessed T1w and DWI data from the HBN-POD2 release (Richie-Halford et al., 2022; *Scientific Data* (https://www.nature.com/articles/s41597-022-01695-7)). These data are hosted on AWS as `s3://fcp-indi/data/Projects/HBN/BIDS_curated/derivatives/qsiprep/`.

This repository includes the code used to further preprocess the neuroimaging data (QSIPrep and sMRIPrep), prepare for fixel-based analyses (FBA, primarily using MRtrix3), run the FBA (ModelArray), and run the statistics/make figures. Much of the processing code is agnostic to the data set. That is, it can be run on **any BIDS** compliant dataset with T1w and diffusion data. Other parts of code, such as quality control, statistics, and phenotypic comparisons, are tailored to work with a Healthy Brain Network (HBN) phenotypic query, but can be adapted to work with another dataset.

**A NOTE ON RUNNING FBA SCRIPTS**: Due to the large size of the cohort, individual subject jobs (odd-numbered bash scripts) are parallelized for efficiency. To submit odd numbered jobs, navigate terminal to the `fba/bash_scripts` code folder, and run `./submit_job_array X` where "X" is the number of the bash script (e.g. 1,3,5,7,9). Even number scripts can be submitted by running `sbatch Y` where "Y" is the _full name_ of the scripts (e.g. "2_average_responses.sh"). The steps mostly mirror those described in MRtrix's FBA tutorial (https://mrtrix.readthedocs.io/en/latest/fixel_based_analysis/st_fibre_density_cross-section.html) and are also described in our paper.

If using this code, please also cite relevant papers to the software and methods employed here. See our paper or the software-specific documentation (bottom of this README) for these references.

## Requirements
### In general
- BIDS-compliant dataset with _at least_ T1w and DWI images
- Environment (Anaconda recommened) with ConFixel (https://github.com/PennLINC/ConFixel) and ModelArray (https://github.com/PennLINC/ModelArray) installed
  - You can also use a Singularity/Docker container
- Singularity / Docker with the following Docker images:
  - QSIPrep 0.15.3 (`singularity build qsiprep.simg docker://pennbbl/qsiprep:0.15.3`)
  - TractSeg 2.3 (`singularity build tractseg.simg docker://wasserth/tractseg_container:master`)
  - MrTrix 3.0.3 (`singularity build mrtrix.simg docker://mrtrix3/mrtrix3:3.0.3`)
  - Mrtrix3tissue 5.2.9 (`singularity build mrtrix3t.simg docker://kaitj/mrtrix3tissue:v5.2.9`)
  - FSL 6.0.4 (`singularity build fsl.simg docker://brainlife/fsl:6.0.4-patched`)
  - sMRIPrep 0.8.1 (`singularity build smriprep.simg docker://nipreps/smriprep:0.8.1`)
  - ModelArray 0.1.2 (`singularity build modelarray.simg docker://pennlinc/modelarray_confixel:0.1.2`)
  - Singularity 3.9.5 was used in this study. The images above were used in this study, but **more recent stable versions of these software may introduce improvements that should be used in future research.**
- SLURM job scheduler, used for parallelizing jobs. If you uses SGE/PBS to schedule jobs, the scripts can be adapted using tips from this webpage: https://www.msi.umn.edu/slurm/pbs-conversion
- Python environment with Jupyter capabilities and the following dependencies: numpy, scipy, scikit-learn, pandas, os, glob, matplotlib, json, filecmp, nilearn, fslpy, pingouin, statsmodels, seaborn, and statannotations (https://github.com/trevismd/statannotations)
- FreeSurfer license (https://surfer.nmr.mgh.harvard.edu/fswiki/License) - **ADD THIS FILE as "license.txt" in the "qsiprep" and "smriprep" folders**
### Additional requirements if downloading HBN data
- Data Usage Agreement (if working with Healthy Brain Network data), used to access neuroimaging and phenotypic data
- Amazon Web Services (AWS) Command Line version 2 (or any version with s3 capabilities), used to download neuroimaging data (https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

## 0) Download and prepare HBN data (if using HBN)
- Obtain a Data Usage Agreement: http://fcon_1000.projects.nitrc.org/indi/cmi_healthy_brain_network/Pheno_Access.html#DUA, https://data.healthybrainnetwork.org/login/request-account/
- Using the AWS command line, `aws s3 cp` or `aws s3 sync` the HBN-POD2 repository (`s3://fcp-indi/data/Projects/HBN/BIDS_curated/derivatives/qsiprep/`) to your `BIDSROOT/derivatives/qsiprep` folder.
- Using the HBN Loris portal (https://data.healthybrainnetwork.org/main.php) make a phenotypic query with _at least_ the following fields: "Basic_Demos", "TOWRE", "EHQ", "WISC", "Barratt", and "Clinician Diagnoses"

## 1) Run DWI reconstruction and FreeSurfer (qsiprep and smriprep)
We ran NODDI and DKI/DTI reconstruction on these files with QSIPrep, and also used smriprep to run FreeSurfer - needed for intracranial volume estimation.
- Download the `qsiprep` and `smriprep` folders to your BIDS code folder. In them, add your FreeSurfer license as `license.txt` (case-sensitive).
- In the `submit_job_array.sh` scripts, udpate the variable `bids` in the beginning of the scripts to direct to your BIDS directory. Additionally, in the last line of the scripts, you can update the parameter after `%` to limit how many jobs can be active at a time. We set this to 100 as a default, but you can alter this or delete it to not set a limit.
- In the `ss_XXXX.sh` scripts, change the SBATCH headers to match your desired parameters (e.g. memory usage, walltime, etc). Then update the variable `IMG` to the path of the corresponding singularity images. Set the variable `scratch` to where you want intermediate files to be stored during the workflows. Review the command at the bottom of the script to make sure you understand how QSIPrep and sMRIprep are being run and change any parameters you would like.
- In terminal, navigate to the `qsiprep` or `smriprep` folder, and run `./submit_job_array.sh` to begin the workflow.

## 2) Run automated QC and first-level manual QC. Determine which subjects define population template
- Before beginning, save your HBN phenotypic data as `HBN_query.csv` and place it in your BIDS code directory.
- Run through Jupyter notebook 1. Read the comments in the notebook for notes and directions.

## 3) Begin Fixel Based Analysis Pipeline (up until manual QC is required again)
- Update fields in `fba/config` file to match your needs. These paths and softwares are used in FBA analyses.
- **UPDATE THE VARIABLE `config` IN EACH SBATCH SCRIPT TO THE PATH OF YOUR CONFIG FILE**
- Read the note above about running FBA jobs scripts, and then run bash scripts 1-5.

## 4) Second-level manual QC
- Run Jupyter notebook 2.
- Remove any poor quality subjects from the FBA derivatives directories

## 5) Finish FBA preparations
- Run bash scripts 6-9. 8a and 8b can be run concurrently.
- bash script S1 warps the voxel scalar maps from DTI, DKI, and NODDI, which is used in the secondary analyses.
- While the scripts are running, you can make the necessary files for running the ModelArray analyses and analyze phenotypic data in Jupyter noteboooks 3 and 4.

## 6) Run ModelArray analyses
- Using ConFixel, convert .mif to .h5 files (`bash convert_mif_to_h5.mif`)
- Run the models in the `fba/models` folder with `submit_gams.sh`
- Convert the ModelArray outputs back to mif form with `python convert_h5_to_mif.py /PATH/TO/BIDS/ROOT`
- Explore the results in MRtrix's MRView

## Questions? Feel free to either open an issue in this repository or email Steven Meisler (smeisler@g.harvard.edu) with any problems, suggestions, or feedback!

## Extra documentation
- Healthy Brain Network Data Portal (http://fcon_1000.projects.nitrc.org/indi/cmi_healthy_brain_network/index.html)
- TractSeg Website (https://github.com/MIC-DKFZ/TractSeg)
- QSIPrep Website (https://qsiprep.readthedocs.io/en/latest/)
- sMRIPrep Website (https://www.nipreps.org/smriprep/)
- MRtrix3 Website (https://mrtrix.readthedocs.io/en/latest/)
- MRtrix3Tissue Website (https://3tissue.github.io/)
- ModelArray GitHub (https://github.com/PennLINC/ModelArray)

## License

MIT License

Copyright (c) 2022 Steven Meisler

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
