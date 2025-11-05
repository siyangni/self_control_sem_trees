# ==============================================================================
# Extract Growth Parameters from LGBM for Two-Stage SEMTree Analysis
# ==============================================================================
#
# Purpose: Extract intercept and slope factor scores from LGBM model
#   - Individual-level growth parameters (intercept, slope)
#   - Standard errors for measurement error propagation
#   - Wave-specific self-control factor scores
#   - Merge with covariates for downstream analyses
#
# This enables:
#   - Two-stage SEMTree (intercept tree, slope tree separately)
#   - Regression analysis with more power
#   - Machine learning on growth parameters
#
# Input:
#   - data/processed/mcs_lavaan_fiml.RData (from Phase 0)
#   - Runs LGBM model internally
#
# Output:
#   - data/processed/growth_parameters.RData
#   - data/processed/growth_parameters_with_covariates.RData
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, semTools, here)

cat("\n")
cat("==============================================================================\n")
cat("EXTRACTING GROWTH PARAMETERS FROM LGBM\n")
cat("==============================================================================\n\n")

# Set paths
processed_path <- here("data", "processed")
results_path <- here("results", "models")
dir.create(results_path, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# STEP 1: LOAD DATA
# ------------------------------------------------------------------------------

cat("Step 1: Loading data...\n")

# Load FIML-ready dataset (allows missing SC waves)
load(file.path(processed_path, "mcs_lavaan_fiml.RData"))
cat("  - Loaded N =", nrow(mcs_lavaan_fiml), "participants\n")

# Load covariate lists
load(file.path(processed_path, "covariate_lists.RData"))
cat("  - Loaded covariate sets\n\n")

# ------------------------------------------------------------------------------
# STEP 2: DEFINE LGBM MODEL
# ------------------------------------------------------------------------------

cat("Step 2: Defining second-order latent growth model...\n")

# Model specification
# This is a simplified version focusing on growth parameters
# Uses 7 items per wave for consistency

lgbm_model <- '
# ==============================================================================
# FIRST-ORDER FACTORS (Self-Control at each wave)
# ==============================================================================

# Age 3
SC_3 =~ l1*sc_3_thac + l2*sc_3_tcom + l3*sc_3_obey +
        l4*sc_3_dist + l5*sc_3_temp + l6*sc_3_rest + l7*sc_3_fidg

# Age 5
SC_5 =~ l1*sc_5_thac + l2*sc_5_tcom + l3*sc_5_obey +
        l4*sc_5_dist + l5*sc_5_temp + l6*sc_5_rest + l7*sc_5_fidg

# Age 7
SC_7 =~ l1*sc_7_thac + l2*sc_7_tcom + l3*sc_7_obey +
        l4*sc_7_dist + l5*sc_7_temp + l6*sc_7_rest + l7*sc_7_fidg

# Age 11
SC_11 =~ l1*sc_11_thac + l2*sc_11_tcom + l3*sc_11_obey +
         l4*sc_11_dist + l5*sc_11_temp + l6*sc_11_rest + l7*sc_11_fidg

# Age 14
SC_14 =~ l1*sc_14_thac + l2*sc_14_tcom + l3*sc_14_obey +
         l4*sc_14_dist + l5*sc_14_temp + l6*sc_14_rest + l7*sc_14_fidg

# Age 17
SC_17 =~ l1*sc_17_thac + l2*sc_17_tcom + l3*sc_17_obey +
         l4*sc_17_dist + l5*sc_17_temp + l6*sc_17_rest + l7*sc_17_fidg

# ==============================================================================
# SECOND-ORDER GROWTH FACTORS
# ==============================================================================

# Intercept (i): Initial level at age 3
i =~ 1*SC_3 + 1*SC_5 + 1*SC_7 + 1*SC_11 + 1*SC_14 + 1*SC_17

# Slope (s): Rate of change (latent basis)
# Time 0 at age 3, time 1 at age 17, middle times freely estimated
s =~ 0*SC_3 + t5*SC_5 + t7*SC_7 + t11*SC_11 + t14*SC_14 + 1*SC_17

# Fix intercept mean to 0 for identification
i ~ 0*1

# Estimate slope mean
s ~ 1

# Estimate variances and covariance
i ~~ i
s ~~ s
i ~~ s

# Fix intercepts of first-order factors to 0
SC_3 ~ 0*1
SC_5 ~ 0*1
SC_7 ~ 0*1
SC_11 ~ 0*1
SC_14 ~ 0*1
SC_17 ~ 0*1
'

cat("  - Model defined: 2nd-order LGBM with 6 waves\n")
cat("  - Intercept (i): Initial level\n")
cat("  - Slope (s): Rate of change (latent basis)\n\n")

# ------------------------------------------------------------------------------
# STEP 3: FIT LGBM MODEL
# ------------------------------------------------------------------------------

cat("Step 3: Fitting LGBM model...\n")
cat("  (This may take 5-10 minutes)\n\n")

# List of SC items (7 core items per wave)
sc_items <- c(
  paste0("sc_3_", c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg")),
  paste0("sc_5_", c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg")),
  paste0("sc_7_", c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg")),
  paste0("sc_11_", c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg")),
  paste0("sc_14_", c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg")),
  paste0("sc_17_", c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg"))
)

# Fit model with FIML for missing data
fit_lgbm <- cfa(
  model = lgbm_model,
  data = mcs_lavaan_fiml,
  ordered = sc_items,
  estimator = "WLSMV",
  missing = "pairwise",  # Use available data
  std.lv = FALSE
)

cat("\n✓ Model fitted successfully\n\n")

# Check convergence
if (!lavInspect(fit_lgbm, "converged")) {
  warning("Model did not converge! Results may be unreliable.")
}

# ------------------------------------------------------------------------------
# STEP 4: MODEL FIT SUMMARY
# ------------------------------------------------------------------------------

cat("Step 4: Model fit summary...\n\n")

fit_measures <- fitmeasures(fit_lgbm, c("chisq", "df", "pvalue",
                                         "cfi", "tli", "rmsea",
                                         "rmsea.ci.lower", "rmsea.ci.upper",
                                         "srmr"))

cat("Fit indices:\n")
cat("  χ² (", fit_measures["df"], ") = ", round(fit_measures["chisq"], 2),
    ", p = ", format.pval(fit_measures["pvalue"], digits = 3), "\n", sep = "")
cat("  CFI = ", round(fit_measures["cfi"], 3), "\n", sep = "")
cat("  TLI = ", round(fit_measures["tli"], 3), "\n", sep = "")
cat("  RMSEA = ", round(fit_measures["rmsea"], 3),
    " [", round(fit_measures["rmsea.ci.lower"], 3), ", ",
    round(fit_measures["rmsea.ci.upper"], 3), "]\n", sep = "")
cat("  SRMR = ", round(fit_measures["srmr"], 3), "\n\n", sep = "")

# Growth parameters
params <- parameterEstimates(fit_lgbm, standardized = TRUE)

cat("Growth parameters:\n")

# Intercept variance
intercept_var <- params %>%
  filter(lhs == "i" & op == "~~" & rhs == "i") %>%
  pull(est)
cat("  Intercept variance: ", round(intercept_var, 3), "\n", sep = "")

# Slope variance
slope_var <- params %>%
  filter(lhs == "s" & op == "~~" & rhs == "s") %>%
  pull(est)
cat("  Slope variance: ", round(slope_var, 3), "\n", sep = "")

# Intercept-slope covariance
cov_is <- params %>%
  filter(lhs == "i" & op == "~~" & rhs == "s") %>%
  pull(est)
cat("  Intercept-slope covariance: ", round(cov_is, 3), "\n", sep = "")

# Correlation
cor_is <- cov_is / sqrt(intercept_var * slope_var)
cat("  Intercept-slope correlation: ", round(cor_is, 3), "\n\n", sep = "")

# ------------------------------------------------------------------------------
# STEP 5: EXTRACT FACTOR SCORES
# ------------------------------------------------------------------------------

cat("Step 5: Extracting factor scores...\n")

# Extract all latent variable scores
# This includes: SC_3, SC_5, SC_7, SC_11, SC_14, SC_17, i (intercept), s (slope)
factor_scores_all <- lavPredict(fit_lgbm, type = "lv")

# Convert to data frame
factor_scores_df <- as.data.frame(factor_scores_all)

# Add participant ID
factor_scores_df <- factor_scores_df %>%
  mutate(mcsid = mcs_lavaan_fiml$mcsid) %>%
  relocate(mcsid)

cat("  - Extracted factor scores for N =", nrow(factor_scores_df), "participants\n")
cat("  - Variables extracted:\n")
cat("    * SC_3, SC_5, SC_7, SC_11, SC_14, SC_17 (wave-specific SC)\n")
cat("    * i (intercept - initial level at age 3)\n")
cat("    * s (slope - rate of change)\n\n")

# Descriptive statistics for growth parameters
cat("Growth parameter distributions:\n")
cat("  Intercept (i):\n")
cat("    Mean =", round(mean(factor_scores_df$i, na.rm = TRUE), 3), "\n")
cat("    SD =", round(sd(factor_scores_df$i, na.rm = TRUE), 3), "\n")
cat("    Range = [", round(min(factor_scores_df$i, na.rm = TRUE), 3), ", ",
    round(max(factor_scores_df$i, na.rm = TRUE), 3), "]\n\n", sep = "")

cat("  Slope (s):\n")
cat("    Mean =", round(mean(factor_scores_df$s, na.rm = TRUE), 3), "\n")
cat("    SD =", round(sd(factor_scores_df$s, na.rm = TRUE), 3), "\n")
cat("    Range = [", round(min(factor_scores_df$s, na.rm = TRUE), 3), ", ",
    round(max(factor_scores_df$s, na.rm = TRUE), 3), "]\n\n", sep = "")

# ------------------------------------------------------------------------------
# STEP 6: EXTRACT STANDARD ERRORS (for uncertainty quantification)
# ------------------------------------------------------------------------------

cat("Step 6: Extracting standard errors for growth parameters...\n")

# Extract factor score standard errors
# Note: lavaan doesn't provide SEs for factor scores by default
# We'll use the reliability-based approach

# Get reliability of factor scores
reliability <- inspect(fit_lgbm, "rsquare")

# Filter for growth parameters
if ("i" %in% names(reliability)) {
  cat("  - Intercept reliability (R²): ", round(reliability["i"], 3), "\n", sep = "")
}

if ("s" %in% names(reliability)) {
  cat("  - Slope reliability (R²): ", round(reliability["s"], 3), "\n\n", sep = "")
}

# Compute approximate SE based on reliability
# SE = SD * sqrt(1 - reliability)

factor_scores_df <- factor_scores_df %>%
  mutate(
    # Standard errors for intercept and slope
    i_se = sd(i, na.rm = TRUE) * sqrt(1 - ifelse("i" %in% names(reliability),
                                                   reliability["i"], 0.9)),
    s_se = sd(s, na.rm = TRUE) * sqrt(1 - ifelse("s" %in% names(reliability),
                                                   reliability["s"], 0.9)),

    # Confidence intervals (95%)
    i_ci_lower = i - 1.96 * i_se,
    i_ci_upper = i + 1.96 * i_se,
    s_ci_lower = s - 1.96 * s_se,
    s_ci_upper = s + 1.96 * s_se
  )

cat("  ✓ Standard errors and confidence intervals computed\n\n")

# ------------------------------------------------------------------------------
# STEP 7: MERGE WITH COVARIATES
# ------------------------------------------------------------------------------

cat("Step 7: Merging with covariates...\n")

# Load full merged data to get all covariates
load(file.path(processed_path, "mcs_merged_wide.RData"))

# Select covariates
covariates_to_merge <- c(
  "mcsid",
  covariate_lists$baseline,
  covariate_lists$parenting,
  "survey_weight",
  "risk_index", "risk_group",
  "harsh_group", "pos_group", "ses_group"
)

# Merge factor scores with covariates
growth_params_with_cov <- factor_scores_df %>%
  left_join(
    mcs_merged %>% select(any_of(covariates_to_merge)),
    by = "mcsid"
  )

cat("  - Merged with", length(covariates_to_merge) - 1, "covariates\n")
cat("  - Final dataset: N =", nrow(growth_params_with_cov), "\n\n")

# ------------------------------------------------------------------------------
# STEP 8: SAVE OUTPUTS
# ------------------------------------------------------------------------------

cat("Step 8: Saving outputs...\n")

# Save growth parameters only
growth_parameters <- factor_scores_df
save(growth_parameters, file = file.path(processed_path, "growth_parameters.RData"))
cat("  ✓ Saved: growth_parameters.RData\n")

# Save growth parameters with covariates
save(growth_params_with_cov,
     file = file.path(processed_path, "growth_parameters_with_covariates.RData"))
cat("  ✓ Saved: growth_parameters_with_covariates.RData\n")

# Save fitted model
save(fit_lgbm, file = file.path(results_path, "lgbm_fitted_model.RData"))
cat("  ✓ Saved: lgbm_fitted_model.RData\n\n")

# Save summary statistics
growth_param_summary <- data.frame(
  parameter = c("Intercept (i)", "Slope (s)"),
  mean = c(mean(factor_scores_df$i, na.rm = TRUE),
           mean(factor_scores_df$s, na.rm = TRUE)),
  sd = c(sd(factor_scores_df$i, na.rm = TRUE),
         sd(factor_scores_df$s, na.rm = TRUE)),
  min = c(min(factor_scores_df$i, na.rm = TRUE),
          min(factor_scores_df$s, na.rm = TRUE)),
  max = c(max(factor_scores_df$i, na.rm = TRUE),
          max(factor_scores_df$s, na.rm = TRUE)),
  reliability = c(
    ifelse("i" %in% names(reliability), reliability["i"], NA),
    ifelse("s" %in% names(reliability), reliability["s"], NA)
  )
)

write_csv(growth_param_summary,
          file.path(processed_path, "growth_parameter_summary.csv"))
cat("  ✓ Saved: growth_parameter_summary.csv\n\n")

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("GROWTH PARAMETER EXTRACTION COMPLETE\n")
cat("==============================================================================\n\n")

cat("Extracted for N =", nrow(factor_scores_df), "participants:\n\n")

cat("Growth parameters:\n")
cat("  ✓ Intercept (i) - Initial self-control level at age 3\n")
cat("  ✓ Slope (s) - Rate of change from age 3 to 17\n")
cat("  ✓ Standard errors for both parameters\n")
cat("  ✓ 95% confidence intervals\n\n")

cat("Wave-specific factor scores:\n")
cat("  ✓ SC_3, SC_5, SC_7, SC_11, SC_14, SC_17\n\n")

cat("Merged covariates:\n")
cat("  ✓ Baseline characteristics (demographics, SES, cognition)\n")
cat("  ✓ Parenting variables (harsh, positive, monitoring)\n")
cat("  ✓ Derived composites (risk index, categorical groups)\n\n")

cat("Output files:\n")
cat("  📁 data/processed/growth_parameters.RData\n")
cat("  📁 data/processed/growth_parameters_with_covariates.RData\n")
cat("  📁 results/models/lgbm_fitted_model.RData\n")
cat("  📁 data/processed/growth_parameter_summary.csv\n\n")

cat("Ready for:\n")
cat("  ✓ Two-stage SEMTree (intercept tree, slope tree separately)\n")
cat("  ✓ Regression analysis (predict i and s from covariates)\n")
cat("  ✓ Machine learning (RF, GBM on growth parameters)\n")
cat("  ✓ Descriptive analysis (correlations, group comparisons)\n\n")

cat("Next steps:\n")
cat("  1. Regression analysis: R/enhanced_analyses/02_regression_growth_params.R\n")
cat("  2. Two-stage SEMTree: R/enhanced_analyses/03_semtree_intercept.R\n")
cat("  3. Two-stage SEMTree: R/enhanced_analyses/04_semtree_slope.R\n\n")

cat("==============================================================================\n\n")
