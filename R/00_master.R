# =============================================================================
# Master Analysis Script
# =============================================================================
# Project: Self-Control Development Trajectory Heterogeneity
# Purpose: Run complete analysis pipeline
# Author: [Your Name]
# Date: November 2025
# Last Modified: November 2025
#
# Description:
#   This master script runs all analyses in the correct sequence.
#   It can be run all at once or step-by-step for debugging.
#
# Dependencies:
#   - R >= 4.2.0
#   - All packages in renv.lock
#   - MCS data in data/raw/
#
# Usage:
#   source("R/00_master.R")
#
# Runtime:
#   - Complete pipeline: ~5 hours
#   - With saved intermediate data: ~30 minutes
# =============================================================================

# SETUP -----------------------------------------------------------------------

cat("\n")
cat("=============================================================================\n")
cat("SELF-CONTROL DEVELOPMENT STUDY - MASTER ANALYSIS PIPELINE\n")
cat("=============================================================================\n\n")

# Record start time
start_time <- Sys.time()
cat("Pipeline started:", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n\n")

# Set project root (using here package)
if (!require("here", quietly = TRUE)) {
  install.packages("here")
}
library(here)
setwd(here::here())

cat("Project directory:", here::here(), "\n\n")

# Check R version
cat("R version:", R.version.string, "\n")
if (getRversion() < "4.2.0") {
  warning("R version >= 4.2.0 recommended. Current version: ", R.version.string)
}

# PACKAGE MANAGEMENT ----------------------------------------------------------

cat("\n--- Checking Package Dependencies ---\n\n")

# Required packages
required_packages <- c(
  "tidyverse",   # Data wrangling
  "haven",       # Read Stata files
  "here",        # Project paths
  "lavaan",      # SEM
  "semTools",    # SEM utilities
  "semtree",     # SEM trees
  "survey",      # Survey analysis
  "psych",       # Psychometrics
  "OpenMx"       # Alternative SEM
)

# Check if using renv
if (file.exists("renv.lock")) {
  cat("Using renv for package management\n")
  if (!require("renv", quietly = TRUE)) {
    install.packages("renv")
    library(renv)
  }

  # Check if packages need restoring
  if (!all(required_packages %in% installed.packages()[,"Package"])) {
    cat("Restoring packages from renv.lock...\n")
    renv::restore()
  }
} else {
  cat("Installing/loading packages individually\n")

  # Install missing packages
  new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    cat("Installing:", paste(new_packages, collapse = ", "), "\n")
    install.packages(new_packages)
  }
}

# Load all packages
cat("\nLoading packages...\n")
for (pkg in required_packages) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  cat("  ✓", pkg, "\n")
}

# DATA CHECKS -----------------------------------------------------------------

cat("\n--- Checking Data Availability ---\n\n")

# Check if raw data exists
raw_data_exists <- length(list.files("data/raw/", pattern = "\\.dta$")) > 0

if (!raw_data_exists) {
  cat("⚠ WARNING: No raw MCS data files found in data/raw/\n")
  cat("Please download MCS data from UK Data Service and place in data/raw/\n")
  cat("See data/README.md for instructions\n\n")
  stop("Cannot proceed without raw data.")
}

cat("✓ Raw data files found:", length(list.files("data/raw/", pattern = "\\.dta$")), "files\n")

# Check if processed data exists
processed_data_exists <- file.exists("data/processed/merged_waves_recoded.RData")

if (processed_data_exists) {
  cat("✓ Processed data available (merged_waves_recoded.RData)\n")
  cat("  Analyses can skip data preparation if desired\n")
} else {
  cat("ℹ Processed data not yet created\n")
  cat("  Will be created by script 01\n")
}

# ANALYSIS PIPELINE -----------------------------------------------------------

cat("\n")
cat("=============================================================================\n")
cat("ANALYSIS PIPELINE\n")
cat("=============================================================================\n\n")

# Option to skip scripts
SKIP_IF_EXISTS <- TRUE  # Set to FALSE to force re-run all analyses

# Helper function to run script with error handling
run_script <- function(script_name, description) {
  cat("\n")
  cat("-----------------------------------------------------------------------------\n")
  cat("STEP:", description, "\n")
  cat("Script:", script_name, "\n")
  cat("-----------------------------------------------------------------------------\n\n")

  script_path <- here("R", script_name)

  if (!file.exists(script_path)) {
    cat("⚠ WARNING: Script not found:", script_path, "\n")
    cat("Skipping...\n")
    return(FALSE)
  }

  script_start <- Sys.time()

  tryCatch({
    source(script_path, echo = FALSE)
    script_end <- Sys.time()
    runtime <- difftime(script_end, script_start, units = "mins")

    cat("\n✓ Completed successfully in", round(runtime, 2), "minutes\n")
    return(TRUE)

  }, error = function(e) {
    cat("\n✗ ERROR occurred:\n")
    cat(e$message, "\n\n")
    cat("Pipeline stopped at:", description, "\n")
    cat("Fix the error and re-run from this step\n")
    return(FALSE)
  })
}

# Step 1: Measurement Models
success_01 <- run_script(
  "01_measurement.R",
  "Step 1 - Measurement Models (CFA, Reliability)"
)

if (!success_01) {
  stop("Pipeline failed at Step 1. Fix errors and re-run.")
}

# Step 2: Measurement Invariance
success_02 <- run_script(
  "02_invariance.R",
  "Step 2 - Measurement Invariance Testing"
)

if (!success_02) {
  stop("Pipeline failed at Step 2. Fix errors and re-run.")
}

# Step 3: Merge Factor Scores
success_03 <- run_script(
  "03_merge_factor_scores.R",
  "Step 3 - Merge Self-Control & Parenting Factor Scores"
)

if (!success_03) {
  stop("Pipeline failed at Step 3. Fix errors and re-run.")
}

# Step 4: Latent Basis Growth Model
cat("\nℹ Note: LGBM estimation may take 20-30 minutes\n")
success_04 <- run_script(
  "04_lgbm.R",
  "Step 4 - Latent Basis Growth Model (LGBM)"
)

if (!success_04) {
  stop("Pipeline failed at Step 4. Fix errors and re-run.")
}

# Step 5: Growth Mixture Model (OPTIONAL - LONG RUNTIME)
cat("\n")
cat("-----------------------------------------------------------------------------\n")
cat("OPTIONAL: Growth Mixture Models (GMM)\n")
cat("-----------------------------------------------------------------------------\n\n")
cat("⚠ GMM analysis can take 2+ hours\n")
cat("Skip this step? (y/n): ")

skip_gmm <- readline()

if (tolower(trimws(skip_gmm)) != "y") {
  success_05 <- run_script(
    "05_gmm_lgbm.R",
    "Step 5 - Growth Mixture Models (OPTIONAL)"
  )
} else {
  cat("Skipping GMM analysis\n")
  success_05 <- TRUE
}

# Step 6: SEM Trees (Standard)
success_06 <- run_script(
  "06_sem_trees.R",
  "Step 6 - SEM Trees (Standard Parameters)"
)

if (!success_06) {
  warning("SEM tree analysis (standard) encountered issues. Check results.")
}

# Step 7: SEM Trees (Relaxed)
success_07 <- run_script(
  "07_sem_trees_relaxed.R",
  "Step 7 - SEM Trees (Relaxed Parameters - Sensitivity Analysis)"
)

if (!success_07) {
  warning("SEM tree analysis (relaxed) encountered issues. Check results.")
}

# PIPELINE COMPLETION ---------------------------------------------------------

cat("\n")
cat("=============================================================================\n")
cat("PIPELINE COMPLETED\n")
cat("=============================================================================\n\n")

end_time <- Sys.time()
total_runtime <- difftime(end_time, start_time, units = "hours")

cat("Started:", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("Finished:", format(end_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("Total runtime:", round(total_runtime, 2), "hours\n\n")

# Summary of outputs
cat("--- Output Files ---\n\n")

cat("Data:\n")
cat("  - data/processed/merged_waves_recoded.RData\n")
cat("  - data/processed/merged_sc_pa_fscores.RData\n\n")

cat("Models:\n")
model_files <- list.files("results/models/", pattern = "\\.RData$")
cat(paste0("  - results/models/", model_files), sep = "\n")

cat("\nFigures:\n")
figure_files <- list.files("results/figures/", pattern = "\\.(pdf|png)$")
cat(paste0("  - results/figures/", figure_files), sep = "\n")

cat("\nReports:\n")
report_files <- list.files("results/reports/", pattern = "\\.md$")
cat(paste0("  - results/reports/", report_files), sep = "\n")

# Session info for reproducibility
cat("\n--- Session Info ---\n\n")
cat("Saving session info to results/sessionInfo.txt\n")

sink("results/sessionInfo.txt")
cat("Analysis completed:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
sessionInfo()
sink()

cat("\n✓ Session info saved\n")

# Next steps
cat("\n")
cat("=============================================================================\n")
cat("NEXT STEPS\n")
cat("=============================================================================\n\n")

cat("1. Review results:\n")
cat("   - Read results/reports/*.md files\n")
cat("   - Examine figures in results/figures/\n\n")

cat("2. Key findings:\n")
cat("   - Measurement models: Check results/tables/reliability_summary.csv\n")
cat("   - Growth trajectories: See results/figures/growth_trajectory.pdf\n")
cat("   - Subgroup detection: Read results/reports/SEMTREE_FINAL_SUMMARY.md\n\n")

cat("3. Additional analyses:\n")
cat("   - Regression models (predict growth parameters)\n")
cat("   - Theory-driven group comparisons\n")
cat("   - Machine learning approaches\n\n")

cat("4. Documentation:\n")
cat("   - Update docs/methods.md with any modifications\n")
cat("   - Document decisions in analysis notes\n\n")

cat("5. Manuscript preparation:\n")
cat("   - Extract key results for reporting\n")
cat("   - Create publication-ready figures\n")
cat("   - Write up findings\n\n")

cat("=============================================================================\n")
cat("Thank you for using the Self-Control Development analysis pipeline!\n")
cat("For questions or issues, open an issue on GitHub\n")
cat("=============================================================================\n\n")

# =============================================================================
# END OF MASTER SCRIPT
# =============================================================================
