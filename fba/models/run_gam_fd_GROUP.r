# Load libraries
library(ModelArray)
library(testthat)
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

args = commandArgs(trailingOnly=TRUE)
fba_dir = args[1] # path to FBA derivatives directory
metric = 'fd' # metric to analyze (e.g., log_fc, fc, or fdc)

# Define analysis and file paths
metric = c(metric) 
h5_path <- paste(fba_dir, "template/modelarray_inputs/fixels_",metric,'_group.h5',sep="")
csv_path <- paste(fba_dir, "template/modelarray_inputs/cohort_",metric,'_group.csv',sep="")
modelarray <- ModelArray(h5_path, scalar_types = metric)
phenotypes <- read.csv(csv_path)

# demean and center continuous covariates
AGE_demean = scale(phenotypes$AGE)
phenotypes$AGE_DM <- AGE_demean
logICV_demean = scale(phenotypes$logICV)
phenotypes$logICV_DM <- logICV_demean
TOWRE_demean = scale(phenotypes$TOWRE)
phenotypes$TOWRE_DM <- TOWRE_demean
N_CORR_demean = scale(phenotypes$N_CORR)
phenotypes$N_CORR_DM <- N_CORR_demean

# make sure categorical variables are factors
phenotypes$GROUP_F <- factor(phenotypes$GROUP)
phenotypes$SEX_F <- factor(phenotypes$SEX)
phenotypes$SITE_F <- factor(phenotypes$SITE)

# define and run the GAM
formula <- fd ~ s(AGE_DM, k=4) + SEX_F + SITE_F + N_CORR_DM + GROUP_F
mygam <- ModelArray.gam(formula, data = modelarray, phenotypes = phenotypes, scalar = metric, element.subset = NULL,
                          correct.p.value.smoothTerms = c("fdr"),
                          correct.p.value.parametricTerms = c("fdr"),
                          changed.rsq.term.index = c(5),
                          full.outputs = TRUE, 
                        n_cores = 16, pbar = TRUE, verbose = TRUE)

# write GAM results:
h5_output_path <- gsub("_inputs","_outputs",h5_path)
#h5_output_path <- gsub(".h5","_GROUP.h5",h5_output_path)
writeResults(h5_output_path, df.output = mygam,  
             analysis_name="result_gam", 
             overwrite=TRUE)
