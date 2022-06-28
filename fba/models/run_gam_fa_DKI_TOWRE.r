# Load libraries
library(ModelArray)
library(testthat)
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

args = commandArgs(trailingOnly=TRUE)
fba_dir = args[1] # path to FBA derivatives directory
metric = 'fa_DKI' # metric to analyze (log_fc, fc, or fdc)

# Define analysis and file paths
metric = c(metric) 
#h5_path <- paste(fba_dir, "template/modelarray_inputs/fixels_",metric,'.h5',sep="")
#csv_path <- paste(fba_dir, "template/modelarray_inputs/cohort_",metric,'.csv',sep="")
h5_path <- paste('/om2/scratch/Fri/smeisler/fba/modelarray_inputs/fixels_',metric,'.h5',sep="")
csv_path <- paste('/om2/scratch/Fri/smeisler/fba/modelarray_inputs/cohort_',metric,'.csv',sep="")
modelarray <- ModelArray(h5_path, scalar_types = metric)
phenotypes <- read.csv(csv_path)

# demean and center continuous covariates
AGE_demean = scale(phenotypes$AGE)
phenotypes$AGE_DM <- AGE_demean
logICV_demean = scale(phenotypes$logICV)
phenotypes$logICV_DM <- logICV_demean
TOWRE_demean = scale(phenotypes$TOWRE)
phenotypes$TOWRE_DM <- TOWRE_demean
MOTION_demean = scale(phenotypes$MOTION)
phenotypes$MOTION_DM <- MOTION_demean
N_CORR_demean = scale(phenotypes$N_CORR)
phenotypes$N_CORR_DM <- N_CORR_demean
gFD_demean = scale(phenotypes$gFD)
phenotypes$gFD_DM <- gFD_demean

# make sure categorical variables are factors
phenotypes$GROUP_F <- factor(phenotypes$GROUP)
phenotypes$SEX_F <- factor(phenotypes$SEX)
phenotypes$HAND_F <- factor(phenotypes$HAND)
phenotypes$SITE_F <- factor(phenotypes$SITE)

# define and run the GAM
formula <- fa_DKI ~ s(AGE_DM, k=4, fx=TRUE) + SEX_F + SITE_F + logICV_DM + N_CORR_DM + TOWRE_DM
mygam <- ModelArray.gam(formula, data = modelarray, phenotypes = phenotypes, scalar = metric, element.subset = NULL,
                          correct.p.value.smoothTerms = c("fdr"),
                          correct.p.value.parametricTerms = c("fdr"),
                          changed.rsq.term.index = c(6),
                          full.outputs = TRUE, 
                        n_cores = 32, pbar = TRUE, verbose = TRUE)

# write GAM results:
h5_output_path <- gsub("_inputs","_outputs",h5_path)
h5_output_path <- gsub(".h5","_TOWRE.h5",h5_output_path)
writeResults(h5_output_path, df.output = mygam,  
             analysis_name="result_gam", 
             overwrite=TRUE)

