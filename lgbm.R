# ==============================================================================
# Second-Order Latent Growth Basis Model (LGBM) in R
# Matching MPlus Model: Second-order LGBM with categorical indicators
# ==============================================================================
#
# This script:
# 1. Subsets variables from merged_waves_recoded.RData
# 2. Builds a second-order latent growth basis model matching the MPlus specification
#
# MODEL STRUCTURE:
# - First-order factors: SC_3, SC_5, SC_7, SC_11, SC_14, SC_17
# - Each factor measured by 7 categorical indicators (thac, tcom, obey, dist, temp, rest, fidg)
# - Second-order growth: Intercept (i) and Slope (s) over first-order factors
# - Measurement invariance: Equal loadings and thresholds across time
# - Adjacent correlated uniquenesses
# - Complex survey design
#
# ==============================================================================

library(pacman)
p_load(tidyverse, haven, lavaan)

# ==============================================================================
# STEP 1: LOAD DATA AND SUBSET VARIABLES
# ==============================================================================

cat("\n=== Loading Data ===\n")
load("/home/siyang/dissertation/merged_waves_recoded.RData")

# Define all variables needed for the model
cat("\n=== Subsetting Variables ===\n")

# Self-control items across 6 waves (7 items x 6 waves = 42 variables)
sc_vars <- c(
  # Age 3 (Wave 2)
  "sc3thac", "sc3tcom", "sc3obey", "sc3dist", "sc3temp", "sc3rest", "sc3fidg",
  # Age 5 (Wave 3)
  "sc5thac", "sc5tcom", "sc5obey", "sc5dist", "sc5temp", "sc5rest", "sc5fidg",
  # Age 7 (Wave 4)
  "sc7thac", "sc7tcom", "sc7obey", "sc7dist", "sc7temp", "sc7rest", "sc7fidg",
  # Age 11 (Wave 5)
  "sc11thac", "sc11tcom", "sc11obey", "sc11dist", "sc11temp", "sc11rest", "sc11fidg",
  # Age 14 (Wave 6)
  "sc14thac", "sc14tcom", "sc14obey", "sc14dist", "sc14temp", "sc14rest", "sc14fidg",
  # Age 17 (Wave 7)
  "sc17thac", "sc17tcom", "sc17obey", "sc17dist", "sc17temp", "sc17rest", "sc17fidg"
)

# Survey design variables
design_vars <- c(
  "mcsid",      # ID variable
  "pttype2",    # Stratification
  "sptn00",     # Cluster
  "govwt1"      # Weight (using Wave 7 weight as in MPlus)
)

# All variables for analysis
all_analysis_vars <- c(design_vars, sc_vars)

# Check which variables exist in the dataset
cat("\nChecking variable availability:\n")
missing_vars <- all_analysis_vars[!all_analysis_vars %in% names(merged_waves_recoded)]
if (length(missing_vars) > 0) {
  cat("  WARNING: Missing variables:", paste(missing_vars, collapse = ", "), "\n")
} else {
  cat("  All variables found in dataset\n")
}

# Subset the data
lgbm_data <- merged_waves_recoded %>%
  select(all_of(all_analysis_vars[all_analysis_vars %in% names(merged_waves_recoded)]))

cat(sprintf("\nSubset complete: %d observations, %d variables\n", 
            nrow(lgbm_data), ncol(lgbm_data)))

# ==============================================================================
# STEP 2: DATA PREPARATION
# ==============================================================================

cat("\n=== Data Preparation ===\n")

# Filter for valid cases (matching MPlus SUBPOPULATION filter)
lgbm_data <- lgbm_data %>%
  mutate(
    # Count missing self-control items
    .nmiss = rowSums(is.na(select(., all_of(sc_vars)))),
    # Complete case indicator
    .complete = (.nmiss == 0),
    # Valid survey design variables
    .survey_valid = !is.na(sptn00) & !is.na(pttype2) & !is.na(govwt1) & govwt1 > 0,
    # Overall valid case
    .ok = .complete & .survey_valid
  ) %>%
  filter(.ok) %>%
  select(-starts_with("."))

cat(sprintf("Valid cases with complete data and govwt1 > 0: N = %d\n", nrow(lgbm_data)))

# Convert to ordered factors (lavaan requirement for categorical variables)
cat("\nConverting self-control items to ordered factors...\n")
for (var in sc_vars) {
  if (var %in% names(lgbm_data)) {
    lgbm_data[[var]] <- ordered(lgbm_data[[var]])
  }
}

# Summary statistics
cat("\nSurvey weight summary (govwt1):\n")
cat(sprintf("  Mean: %.2f\n", mean(lgbm_data$govwt1)))
cat(sprintf("  SD: %.2f\n", sd(lgbm_data$govwt1)))
cat(sprintf("  Range: %.2f - %.2f\n", min(lgbm_data$govwt1), max(lgbm_data$govwt1)))

# ==============================================================================
# STEP 3: DEFINE SECOND-ORDER LGBM MODEL
# ==============================================================================

cat("\n=== Defining Second-Order LGBM Model ===\n")

# Model specification matching MPlus exactly
lgbm_model <- '
# ==============================================================================
# FIRST-ORDER FACTORS (measurement model at each wave)
# ==============================================================================

# Age 3
SC_3 =~ l1*sc3thac + l2*sc3tcom + l3*sc3obey + l4*sc3dist + l5*sc3temp + l6*sc3rest + l7*sc3fidg

# Age 5
SC_5 =~ l1*sc5thac + l2*sc5tcom + l3*sc5obey + l4*sc5dist + l5*sc5temp + l6*sc5rest + l7*sc5fidg

# Age 7
SC_7 =~ l1*sc7thac + l2*sc7tcom + l3*sc7obey + l4*sc7dist + l5*sc7temp + l6*sc7rest + l7*sc7fidg

# Age 11
SC_11 =~ l1*sc11thac + l2*sc11tcom + l3*sc11obey + l4*sc11dist + l5*sc11temp + l6*sc11rest + l7*sc11fidg

# Age 14
SC_14 =~ l1*sc14thac + l2*sc14tcom + l3*sc14obey + l4*sc14dist + l5*sc14temp + l6*sc14rest + l7*sc14fidg

# Age 17
SC_17 =~ l1*sc17thac + l2*sc17tcom + l3*sc17obey + l4*sc17dist + l5*sc17temp + l6*sc17rest + l7*sc17fidg

# Note: Equal loadings (l1-l7) across all waves (strong factorial invariance)
# Note: First loading (l1) will be fixed to 1 by lavaan for identification

# ==============================================================================
# EQUAL THRESHOLDS ACROSS WAVES (threshold invariance)
# ==============================================================================

# Thresholds for thac (2 thresholds for 3-category items)
sc3thac | t_thac1*t1 + t_thac2*t2
sc5thac | t_thac1*t1 + t_thac2*t2
sc7thac | t_thac1*t1 + t_thac2*t2
sc11thac | t_thac1*t1 + t_thac2*t2
sc14thac | t_thac1*t1 + t_thac2*t2
sc17thac | t_thac1*t1 + t_thac2*t2

# Thresholds for tcom
sc3tcom | t_tcom1*t1 + t_tcom2*t2
sc5tcom | t_tcom1*t1 + t_tcom2*t2
sc7tcom | t_tcom1*t1 + t_tcom2*t2
sc11tcom | t_tcom1*t1 + t_tcom2*t2
sc14tcom | t_tcom1*t1 + t_tcom2*t2
sc17tcom | t_tcom1*t1 + t_tcom2*t2

# Thresholds for obey
sc3obey | t_obey1*t1 + t_obey2*t2
sc5obey | t_obey1*t1 + t_obey2*t2
sc7obey | t_obey1*t1 + t_obey2*t2
sc11obey | t_obey1*t1 + t_obey2*t2
sc14obey | t_obey1*t1 + t_obey2*t2
sc17obey | t_obey1*t1 + t_obey2*t2

# Thresholds for dist
sc3dist | t_dist1*t1 + t_dist2*t2
sc5dist | t_dist1*t1 + t_dist2*t2
sc7dist | t_dist1*t1 + t_dist2*t2
sc11dist | t_dist1*t1 + t_dist2*t2
sc14dist | t_dist1*t1 + t_dist2*t2
sc17dist | t_dist1*t1 + t_dist2*t2

# Thresholds for temp
sc3temp | t_temp1*t1 + t_temp2*t2
sc5temp | t_temp1*t1 + t_temp2*t2
sc7temp | t_temp1*t1 + t_temp2*t2
sc11temp | t_temp1*t1 + t_temp2*t2
sc14temp | t_temp1*t1 + t_temp2*t2
sc17temp | t_temp1*t1 + t_temp2*t2

# Thresholds for rest
sc3rest | t_rest1*t1 + t_rest2*t2
sc5rest | t_rest1*t1 + t_rest2*t2
sc7rest | t_rest1*t1 + t_rest2*t2
sc11rest | t_rest1*t1 + t_rest2*t2
sc14rest | t_rest1*t1 + t_rest2*t2
sc17rest | t_rest1*t1 + t_rest2*t2

# Thresholds for fidg
sc3fidg | t_fidg1*t1 + t_fidg2*t2
sc5fidg | t_fidg1*t1 + t_fidg2*t2
sc7fidg | t_fidg1*t1 + t_fidg2*t2
sc11fidg | t_fidg1*t1 + t_fidg2*t2
sc14fidg | t_fidg1*t1 + t_fidg2*t2
sc17fidg | t_fidg1*t1 + t_fidg2*t2

# ==============================================================================
# ADJACENT CORRELATED UNIQUENESSES (autoregressive residuals)
# ==============================================================================

# thac
sc3thac ~~ sc5thac
sc5thac ~~ sc7thac
sc7thac ~~ sc11thac
sc11thac ~~ sc14thac
sc14thac ~~ sc17thac

# tcom
sc3tcom ~~ sc5tcom
sc5tcom ~~ sc7tcom
sc7tcom ~~ sc11tcom
sc11tcom ~~ sc14tcom
sc14tcom ~~ sc17tcom

# obey
sc3obey ~~ sc5obey
sc5obey ~~ sc7obey
sc7obey ~~ sc11obey
sc11obey ~~ sc14obey
sc14obey ~~ sc17obey

# dist
sc3dist ~~ sc5dist
sc5dist ~~ sc7dist
sc7dist ~~ sc11dist
sc11dist ~~ sc14dist
sc14dist ~~ sc17dist

# temp
sc3temp ~~ sc5temp
sc5temp ~~ sc7temp
sc7temp ~~ sc11temp
sc11temp ~~ sc14temp
sc14temp ~~ sc17temp

# rest
sc3rest ~~ sc5rest
sc5rest ~~ sc7rest
sc7rest ~~ sc11rest
sc11rest ~~ sc14rest
sc14rest ~~ sc17rest

# fidg
sc3fidg ~~ sc5fidg
sc5fidg ~~ sc7fidg
sc7fidg ~~ sc11fidg
sc11fidg ~~ sc14fidg
sc14fidg ~~ sc17fidg

# ==============================================================================
# SCALE FACTORS (matching MPlus parameterization)
# ==============================================================================

# Fix scale factors at reference wave (age 3) to 1
sc3thac ~*~ sf1*sc3thac
sc3tcom ~*~ sf1*sc3tcom
sc3obey ~*~ sf1*sc3obey
sc3dist ~*~ sf1*sc3dist
sc3temp ~*~ sf1*sc3temp
sc3rest ~*~ sf1*sc3rest
sc3fidg ~*~ sf1*sc3fidg

# Free scale factors at other waves
sc5thac ~*~ sf5*sc5thac
sc5tcom ~*~ sf5*sc5tcom
sc5obey ~*~ sf5*sc5obey
sc5dist ~*~ sf5*sc5dist
sc5temp ~*~ sf5*sc5temp
sc5rest ~*~ sf5*sc5rest
sc5fidg ~*~ sf5*sc5fidg

sc7thac ~*~ sf7*sc7thac
sc7tcom ~*~ sf7*sc7tcom
sc7obey ~*~ sf7*sc7obey
sc7dist ~*~ sf7*sc7dist
sc7temp ~*~ sf7*sc7temp
sc7rest ~*~ sf7*sc7rest
sc7fidg ~*~ sf7*sc7fidg

sc11thac ~*~ sf11*sc11thac
sc11tcom ~*~ sf11*sc11tcom
sc11obey ~*~ sf11*sc11obey
sc11dist ~*~ sf11*sc11dist
sc11temp ~*~ sf11*sc11temp
sc11rest ~*~ sf11*sc11rest
sc11fidg ~*~ sf11*sc11fidg

sc14thac ~*~ sf14*sc14thac
sc14tcom ~*~ sf14*sc14tcom
sc14obey ~*~ sf14*sc14obey
sc14dist ~*~ sf14*sc14dist
sc14temp ~*~ sf14*sc14temp
sc14rest ~*~ sf14*sc14rest
sc14fidg ~*~ sf14*sc14fidg

sc17thac ~*~ sf17*sc17thac
sc17tcom ~*~ sf17*sc17tcom
sc17obey ~*~ sf17*sc17obey
sc17dist ~*~ sf17*sc17dist
sc17temp ~*~ sf17*sc17temp
sc17rest ~*~ sf17*sc17rest
sc17fidg ~*~ sf17*sc17fidg

# Constrain scale factor to 1 at reference wave
sf1 == 1

# ==============================================================================
# SECOND-ORDER LATENT GROWTH MODEL
# ==============================================================================

# Define intercept (i) and slope (s) factors
# Time centered at age 3 with non-linear slope (basis coefficients estimated)

# Intercept: equal loadings on all time points (fixed to 1)
i =~ 1*SC_3 + 1*SC_5 + 1*SC_7 + 1*SC_11 + 1*SC_14 + 1*SC_17

# Slope: time 0 at age 3, time 1 at age 17, middle times freely estimated
s =~ 0*SC_3 + t5*SC_5 + t7*SC_7 + t11*SC_11 + t14*SC_14 + 1*SC_17

# Fix intercept mean to 0 for identification (MPlus: [i@0])
i ~ 0*1

# Estimate slope mean
s ~ 1

# Estimate variances and covariance
i ~~ i
s ~~ s
i ~~ s

# Fix intercepts of first-order factors to 0 (MPlus: [SC_3-SC_17@0])
SC_3 ~ 0*1
SC_5 ~ 0*1
SC_7 ~ 0*1
SC_11 ~ 0*1
SC_14 ~ 0*1
SC_17 ~ 0*1
'

cat("Model specification complete\n")
cat("  - First-order factors: 6 (SC_3, SC_5, SC_7, SC_11, SC_14, SC_17)\n")
cat("  - Items per factor: 7 (thac, tcom, obey, dist, temp, rest, fidg)\n")
cat("  - Total indicators: 42\n")
cat("  - Measurement invariance: Equal loadings and thresholds\n")
cat("  - Correlated uniquenesses: Adjacent time points only\n")
cat("  - Second-order: Intercept (i) and non-linear Slope (s)\n")

# ==============================================================================
# STEP 4: FIT MODEL WITH COMPLEX SURVEY DESIGN
# ==============================================================================

cat("\n=== Fitting Model ===\n")
cat("Estimator: WLSMV (diagonally weighted least squares)\n")
cat("Survey design: Complex (strata, cluster, weights)\n\n")

# Fit model using lavaan with survey weights
# NOTE: lavaan does not currently support categorical + clustering simultaneously
# We use sampling weights here, which adjusts for differential selection probabilities
# This is consistent with the MPlus WEIGHT specification
cat("Fitting model with survey weights...\n")
cat("NOTE: Using sampling weights (categorical + clustering not supported in lavaan)\n\n")

fit_lgbm_survey <- lavaan::cfa(
  model = lgbm_model,
  data = lgbm_data,
  ordered = sc_vars,
  estimator = "WLSMV",
  parameterization = "delta",  # Matches MPlus PARAMETERIZATION = DELTA
  std.lv = FALSE,               # Don't standardize latent variables (we control this manually)
  effect.coding = FALSE,        # Use marker variable method (first loading = 1)
  # Survey design (weights only - clustering not supported with categorical)
  sampling.weights = "govwt1",  # Survey weights (matches MPlus WEIGHT = govwt1)
  verbose = TRUE
)

cat("\nModel fitting complete\n")
cat("Survey design specifications:\n")
cat(sprintf("  - Weight variable: govwt1 (applied)\n"))
cat(sprintf("  - Clustering (sptn00): %d PSUs [not applied - lavaan limitation]\n", 
            length(unique(lgbm_data$sptn00))))
cat(sprintf("  - Stratification (pttype2): %d strata [not applied - lavaan limitation]\n", 
            length(unique(lgbm_data$pttype2))))
cat(sprintf("  - N = %d\n", nrow(lgbm_data)))
cat("\nFor full survey design (clustering + weights), consider:\n")
cat("  - MPlus (as you have done)\n")
cat("  - Multilevel SEM approaches\n")
cat("  - Resampling methods\n")

# ==============================================================================
# STEP 5: EXTRACT AND DISPLAY RESULTS
# ==============================================================================

cat("\n")
cat("==============================================================================\n")
cat("MODEL FIT INDICES\n")
cat("==============================================================================\n\n")

fit_measures <- lavaan::fitmeasures(fit_lgbm_survey, 
                                     c("chisq", "df", "pvalue", "cfi", "tli", 
                                       "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
                                       "srmr"))
print(fit_measures)

cat("\n")
cat("==============================================================================\n")
cat("PARAMETER ESTIMATES (Survey-Adjusted)\n")
cat("==============================================================================\n\n")

# Get parameter estimates
params <- lavaan::parameterEstimates(fit_lgbm_survey, standardized = TRUE)

# Display key parameter groups
cat("\n--- SECOND-ORDER GROWTH PARAMETERS ---\n\n")
cat("Growth Factor Means:\n")
print(params %>% filter(op == "~1" & lhs %in% c("i", "s")) %>%
        select(lhs, est, se, z, pvalue, ci.lower, ci.upper))

cat("\nGrowth Factor Variances and Covariance:\n")
print(params %>% filter(op == "~~" & lhs %in% c("i", "s") & rhs %in% c("i", "s")) %>%
        select(lhs, op, rhs, est, se, z, pvalue, ci.lower, ci.upper))

cat("\n--- BASIS COEFFICIENTS (Non-linear Slope) ---\n")
cat("Time loadings on Slope factor (0 = age 3, 1 = age 17):\n")
basis_params <- params %>% 
  filter(op == "=~" & lhs == "s") %>%
  select(lhs, op, rhs, est, se, z, pvalue, ci.lower, ci.upper)
print(basis_params)

cat("\n--- FACTOR LOADINGS (First-Order) ---\n")
cat("Constrained to be equal across time:\n")
loading_params <- params %>% 
  filter(op == "=~" & lhs %in% c("SC_3", "SC_5", "SC_7", "SC_11", "SC_14", "SC_17")) %>%
  filter(row_number() <= 7)  # Show only one wave (they're all equal)
print(loading_params %>% select(lhs, op, rhs, est, se, z, pvalue))

cat("\n--- SCALE FACTORS ---\n")
scale_params <- params %>% 
  filter(grepl("sf", label) & !is.na(label) & label != "") %>%
  distinct(label, .keep_all = TRUE) %>%
  select(label, est, se, z, pvalue)
print(scale_params)

cat("\n")
cat("==============================================================================\n")
cat("MODEL SUMMARY\n")
cat("==============================================================================\n\n")

summary(fit_lgbm_survey, 
        fit.measures = TRUE, 
        standardized = TRUE,
        rsquare = TRUE)

# ==============================================================================
# EXTRACT AND SAVE FACTOR SCORES
# ==============================================================================

cat("\n=== Extracting Factor Scores ===\n")

# Extract factor scores for GMM analysis
factor_scores <- lavPredict(fit_lgbm_survey, type = "lv")
factor_scores_df <- as.data.frame(factor_scores) %>%
  mutate(id = lgbm_data$mcsid) %>%
  relocate(id) %>%
  select(id, SC_3, SC_5, SC_7, SC_11, SC_14, SC_17)

cat(sprintf("Extracted factor scores for %d individuals\n", nrow(factor_scores_df)))

# ==============================================================================
# SAVE RESULTS
# ==============================================================================

cat("\n=== Saving Results ===\n")

# Save the fitted model objects and factor scores
save(lgbm_data, fit_lgbm_survey, factor_scores_df,
     file = "/home/siyang/dissertation/lgbm_results.RData")
cat("Saved: lgbm_results.RData (includes factor scores)\n")


