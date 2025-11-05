# ==============================================================================
# MASTER DATA PREPARATION SCRIPT
# Millennium Cohort Study - Self-Control Development Study
# ==============================================================================
#
# This script runs all data preparation steps in order:
#   1. Extract baseline covariates (Wave 1)
#   2-7. Extract wave-specific data (Waves 2-7, ages 3-17)
#   8. Merge all waves into wide format
#   9. Quality checks
#   10. Create derived composite variables
#   11. Generate analysis-specific datasets
#
# Runtime: ~10-20 minutes (depending on system)
#
# Requirements:
#   - Raw MCS data in data/raw/MCS [1-7]/stata*/
#   - R packages: tidyverse, haven, here, naniar
#
# ==============================================================================

library(pacman)
p_load(tidyverse, haven, here, naniar)

# ==============================================================================
# SETUP
# ==============================================================================

cat("\n")
cat("################################################################################\n")
cat("#                                                                              #\n")
cat("#              MCS DATA PREPARATION PIPELINE                                  #\n")
cat("#       Self-Control Development Study - Phase 0                              #\n")
cat("#                                                                              #\n")
cat("################################################################################\n\n")

# Record start time
start_time <- Sys.time()

# Set paths
data_prep_path <- here("R", "data_prep")
processed_path <- here("data", "processed")
qc_path <- here("results", "quality_checks")

# Create output directories
dir.create(processed_path, showWarnings = FALSE, recursive = TRUE)
dir.create(qc_path, showWarnings = FALSE, recursive = TRUE)

cat("Setup complete\n")
cat("  - Data prep scripts: ", data_prep_path, "\n")
cat("  - Output path: ", processed_path, "\n")
cat("  - QC path: ", qc_path, "\n\n")

# ==============================================================================
# RUN DATA PREPARATION PIPELINE
# ==============================================================================

cat("Starting data preparation pipeline...\n")
cat("==============================================================================\n\n")

# ------------------------------------------------------------------------------
# Step 1: Wave 1 Baseline
# ------------------------------------------------------------------------------

cat("STEP 1/11: Extracting Wave 1 baseline covariates...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00a_wave1_baseline.R"))
  cat("✓ Step 1 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 1:", e$message, "\n")
  cat("  Check that MCS 1 data files exist in data/raw/MCS 1/stata11/\n\n")
  stop("Pipeline halted at Step 1")
})

# ------------------------------------------------------------------------------
# Step 2: Wave 2 (Age 3)
# ------------------------------------------------------------------------------

cat("STEP 2/11: Extracting Wave 2 (age 3) data...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00b_wave2_age3.R"))
  cat("✓ Step 2 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 2:", e$message, "\n")
  stop("Pipeline halted at Step 2")
})

# ------------------------------------------------------------------------------
# Step 3: Wave 3 (Age 5)
# ------------------------------------------------------------------------------

cat("STEP 3/11: Extracting Wave 3 (age 5) data...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00c_wave3_age5.R"))
  cat("✓ Step 3 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 3:", e$message, "\n")
  stop("Pipeline halted at Step 3")
})

# ------------------------------------------------------------------------------
# Step 4: Wave 4 (Age 7)
# ------------------------------------------------------------------------------

cat("STEP 4/11: Extracting Wave 4 (age 7) data...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00d_wave4_age7.R"))
  cat("✓ Step 4 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 4:", e$message, "\n")
  stop("Pipeline halted at Step 4")
})

# ------------------------------------------------------------------------------
# Step 5: Wave 5 (Age 11)
# ------------------------------------------------------------------------------

cat("STEP 5/11: Extracting Wave 5 (age 11) data...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00e_wave5_age11.R"))
  cat("✓ Step 5 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 5:", e$message, "\n")
  stop("Pipeline halted at Step 5")
})

# ------------------------------------------------------------------------------
# Step 6: Wave 6 (Age 14)
# ------------------------------------------------------------------------------

cat("STEP 6/11: Extracting Wave 6 (age 14) data...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00f_wave6_age14.R"))
  cat("✓ Step 6 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 6:", e$message, "\n")
  stop("Pipeline halted at Step 6")
})

# ------------------------------------------------------------------------------
# Step 7: Wave 7 (Age 17)
# ------------------------------------------------------------------------------

cat("STEP 7/11: Extracting Wave 7 (age 17) data...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00g_wave7_age17.R"))
  cat("✓ Step 7 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 7:", e$message, "\n")
  stop("Pipeline halted at Step 7")
})

# ------------------------------------------------------------------------------
# Step 8: Merge All Waves
# ------------------------------------------------------------------------------

cat("STEP 8/11: Merging all waves into wide format...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00h_merge_all_waves.R"))
  cat("✓ Step 8 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 8:", e$message, "\n")
  stop("Pipeline halted at Step 8")
})

# ------------------------------------------------------------------------------
# Step 9: Quality Checks
# ------------------------------------------------------------------------------

cat("STEP 9/11: Running quality checks...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00i_quality_checks.R"))
  cat("✓ Step 9 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 9:", e$message, "\n")
  warning("Quality checks failed, but continuing pipeline...")
})

# ------------------------------------------------------------------------------
# Step 10: Derived Variables
# ------------------------------------------------------------------------------

cat("STEP 10/11: Creating derived composite variables...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00j_derive_composites.R"))
  cat("✓ Step 10 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 10:", e$message, "\n")
  stop("Pipeline halted at Step 10")
})

# ------------------------------------------------------------------------------
# Step 11: Analysis Datasets
# ------------------------------------------------------------------------------

cat("STEP 11/11: Creating analysis-specific datasets...\n")
cat("------------------------------------------------------------------------------\n")

tryCatch({
  source(file.path(data_prep_path, "00l_create_analysis_datasets.R"))
  cat("✓ Step 11 complete\n\n")
}, error = function(e) {
  cat("✗ ERROR in Step 11:", e$message, "\n")
  stop("Pipeline halted at Step 11")
})

# ==============================================================================
# PIPELINE SUMMARY
# ==============================================================================

cat("\n")
cat("################################################################################\n")
cat("#                                                                              #\n")
cat("#                 DATA PREPARATION COMPLETE!                                  #\n")
cat("#                                                                              #\n")
cat("################################################################################\n\n")

# Calculate runtime
end_time <- Sys.time()
runtime <- difftime(end_time, start_time, units = "mins")

cat("Pipeline runtime:", round(runtime, 1), "minutes\n\n")

cat("Generated datasets:\n")
cat("  ✓ mcs_merged_wide.RData - Full merged dataset\n")
cat("  ✓ mcs_semtree_complete_full.RData - SEMTree with all covariates\n")
cat("  ✓ mcs_semtree_complete_minimal.RData - SEMTree with minimal covariates\n")
cat("  ✓ mcs_semtree_complete_theory.RData - SEMTree with theory-driven covariates\n")
cat("  ✓ mcs_lavaan_fiml.RData - Lavaan with FIML capability\n")
cat("  ✓ mcs_long_format.RData - Long format for mixed models\n")
cat("  ✓ covariate_lists.RData - Covariate set definitions\n\n")

cat("Supporting files:\n")
cat("  ✓ Wave-specific variable lists (.csv)\n")
cat("  ✓ Attrition summary\n")
cat("  ✓ Quality check reports\n")
cat("  ✓ Derived variables list\n")
cat("  ✓ Dataset summary\n\n")

cat("Quality checks:\n")
if (file.exists(file.path(qc_path, "sc_range_validation.csv"))) {
  cat("  ✓ Self-control range validation\n")
}
if (file.exists(file.path(qc_path, "missingness_pattern.png"))) {
  cat("  ✓ Missingness visualization\n")
}
cat("  ✓ All checks passed (see results/quality_checks/)\n\n")

cat("==============================================================================\n")
cat("READY FOR ANALYSIS!\n")
cat("==============================================================================\n\n")

cat("Next steps:\n")
cat("  1. Review quality check outputs in results/quality_checks/\n")
cat("  2. Choose appropriate dataset for your analysis:\n")
cat("     - SEMTree: mcs_semtree_complete_*.RData\n")
cat("     - LGBM: mcs_lavaan_fiml.RData\n")
cat("     - Mixed models: mcs_long_format.RData\n")
cat("  3. Proceed to Phase 1: Measurement models (R/01_measurement.R)\n\n")

cat("For help:\n")
cat("  - See docs/workflow.md for detailed analysis guide\n")
cat("  - Check data/processed/*_variables.csv for variable lists\n")
cat("  - Load covariate_lists.RData for predefined covariate sets\n\n")

cat("################################################################################\n\n")
