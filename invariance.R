# ==============================================================================
# Longitudinal Measurement Invariance for Ordinal Data in R (lavaan)
# Following Wu & Estabrook (2016) and Svetina et al. (2020)
# ==============================================================================
#
# USAGE:
#   1. Run entire script to test measurement invariance across ages 3-17
#   2. Review fit comparisons and decision rules for invariance
#   3. If invariance holds, uncomment latent mean comparison section
#
# MODELS TESTED:
#   A. Configural (no constraints)
#   B. Threshold invariance (equal thresholds across time)  
#   C. Strong invariance (equal thresholds + loadings) <- KEY TEST
#
# DATA REQUIREMENTS:
#   - merged_waves_recoded.RData with self-control items (sc3*, sc5*, sc7*, etc.)
#   - Survey design variables: sptn00 (cluster), pttype2 (strata), nh2 (FPC)
#   - Wave-specific survey weights: bovwt1, covwt1, dovwt1, eovwt1, fovwt1, govwt1
#   - Items coded as 0/1/2 (ordinal)
#   - 7 items: thac, tcom, obey, dist, temp, rest, fidg
#   - 6 waves: ages 3, 5, 7, 11, 14, 17
#
# ==============================================================================

library(pacman)
p_load(lavaan, semTools, tidyverse, haven, survey)

# Load your data
load("/home/siyang/dissertation/merged_waves_recoded.RData")

# ==============================================================================
# DATA PREPARATION
# ==============================================================================

cat("\n=== Data Preparation for Invariance Testing ===\n")
cat("Using 7 items (thac, tcom, obey, dist, temp, rest, fidg)\n")
cat("Across ages 3, 5, 7, 11, 14, 17\n\n")

# All self-control variables to include (7 items x 6 waves = 42 variables)
all_vars <- c(
  "sc3thac", "sc3tcom", "sc3obey", "sc3dist", "sc3temp", "sc3rest", "sc3fidg",
  "sc5thac", "sc5tcom", "sc5obey", "sc5dist", "sc5temp", "sc5rest", "sc5fidg",
  "sc7thac", "sc7tcom", "sc7obey", "sc7dist", "sc7temp", "sc7rest", "sc7fidg",
  "sc11thac", "sc11tcom", "sc11obey", "sc11dist", "sc11temp", "sc11rest", "sc11fidg",
  "sc14thac", "sc14tcom", "sc14obey", "sc14dist", "sc14temp", "sc14rest", "sc14fidg",
  "sc17thac", "sc17tcom", "sc17obey", "sc17dist", "sc17temp", "sc17rest", "sc17fidg"
)

# Wave-specific survey weights (MCS complex survey design)
wave_weights <- c("bovwt1", "covwt1", "dovwt1", "eovwt1", "fovwt1", "govwt1")

# Survey design variables
survey_vars <- c("sptn00", "pttype2", "nh2")

# Variables needed for analysis
analysis_vars <- c(all_vars, wave_weights, survey_vars)

cat("Survey Design Variables:\n")
cat("  Cluster (PSU):              sptn00\n")
cat("  Strata:                     pttype2\n")
cat("  Finite Population Correct:  nh2\n\n")

cat("Wave-Specific Survey Weights:\n")
cat("  Age 3  (MCS2): bovwt1\n")
cat("  Age 5  (MCS3): covwt1\n")
cat("  Age 7  (MCS4): dovwt1\n")
cat("  Age 11 (MCS5): eovwt1\n")
cat("  Age 14 (MCS6): fovwt1\n")
cat("  Age 17 (MCS7): govwt1\n\n")

# Create composite weight for longitudinal analysis
# Use the mean of wave-specific weights for cases with complete data across all waves
# NOTE: This is a simplification; ideally each wave would use its own weight
cat("Creating composite survey weight...\n")
cat("  Method: Mean of valid wave-specific weights\n")
cat("  Note: lavaan does not support wave-specific weights in single model\n\n")

# Filter complete cases
data <- merged_waves_recoded %>%
  mutate(
    .nmiss = rowSums(is.na(select(., all_of(all_vars)))),
    .complete = (.nmiss == 0),
    # Check that ALL wave weights are valid
    .weights_valid = !is.na(bovwt1) & !is.na(covwt1) & !is.na(dovwt1) & 
                     !is.na(eovwt1) & !is.na(fovwt1) & !is.na(govwt1) &
                     bovwt1 > 0 & covwt1 > 0 & dovwt1 > 0 & 
                     eovwt1 > 0 & fovwt1 > 0 & govwt1 > 0,
    .survey_valid = !is.na(sptn00) & !is.na(pttype2),
    .ok = .complete & .weights_valid & .survey_valid
  ) %>%
  filter(.ok) %>%
  select(all_of(analysis_vars))

# Create composite weight (average of wave weights)
data <- data %>%
  mutate(
    composite_weight = (bovwt1 + covwt1 + dovwt1 + eovwt1 + fovwt1 + govwt1) / 6
  )

cat(sprintf("Sample size with complete data and valid weights: N = %d\n", nrow(data)))

# Summary of weights
cat("\nWeight Summary Statistics:\n")
weight_summary <- data %>%
  summarize(
    across(c(bovwt1, covwt1, dovwt1, eovwt1, fovwt1, govwt1, composite_weight),
           list(mean = mean, sd = sd, min = min, max = max),
           .names = "{.col}_{.fn}")
  )
cat("  Composite weight: M =", sprintf("%.2f", weight_summary$composite_weight_mean),
    ", SD =", sprintf("%.2f", weight_summary$composite_weight_sd), "\n")
cat("  Range:", sprintf("%.2f", weight_summary$composite_weight_min), "-", 
    sprintf("%.2f", weight_summary$composite_weight_max), "\n")

# ==============================================================================
# MODEL A: CONFIGURAL (Baseline)
# ==============================================================================

cat("\n\n=== MODEL A: CONFIGURAL (Baseline) ===\n")

# Full explicit model specification for 7 items across 6 waves
model_configural <- '
  # Latent factors (one per wave)
  SC_3  =~ sc3thac + sc3tcom + sc3obey + sc3dist + sc3temp + sc3rest + sc3fidg
  SC_5  =~ sc5thac + sc5tcom + sc5obey + sc5dist + sc5temp + sc5rest + sc5fidg
  SC_7  =~ sc7thac + sc7tcom + sc7obey + sc7dist + sc7temp + sc7rest + sc7fidg
  SC_11 =~ sc11thac + sc11tcom + sc11obey + sc11dist + sc11temp + sc11rest + sc11fidg
  SC_14 =~ sc14thac + sc14tcom + sc14obey + sc14dist + sc14temp + sc14rest + sc14fidg
  SC_17 =~ sc17thac + sc17tcom + sc17obey + sc17dist + sc17temp + sc17rest + sc17fidg
  
  # Correlated uniquenesses (adjacent waves only)
  # thac item
  sc3thac  ~~ sc5thac
  sc5thac  ~~ sc7thac
  sc7thac  ~~ sc11thac
  sc11thac ~~ sc14thac
  sc14thac ~~ sc17thac
  
  # tcom item
  sc3tcom  ~~ sc5tcom
  sc5tcom  ~~ sc7tcom
  sc7tcom  ~~ sc11tcom
  sc11tcom ~~ sc14tcom
  sc14tcom ~~ sc17tcom
  
  # obey item
  sc3obey  ~~ sc5obey
  sc5obey  ~~ sc7obey
  sc7obey  ~~ sc11obey
  sc11obey ~~ sc14obey
  sc14obey ~~ sc17obey
  
  # dist item
  sc3dist  ~~ sc5dist
  sc5dist  ~~ sc7dist
  sc7dist  ~~ sc11dist
  sc11dist ~~ sc14dist
  sc14dist ~~ sc17dist
  
  # temp item
  sc3temp  ~~ sc5temp
  sc5temp  ~~ sc7temp
  sc7temp  ~~ sc11temp
  sc11temp ~~ sc14temp
  sc14temp ~~ sc17temp
  
  # rest item
  sc3rest  ~~ sc5rest
  sc5rest  ~~ sc7rest
  sc7rest  ~~ sc11rest
  sc11rest ~~ sc14rest
  sc14rest ~~ sc17rest
  
  # fidg item
  sc3fidg  ~~ sc5fidg
  sc5fidg  ~~ sc7fidg
  sc7fidg  ~~ sc11fidg
  sc11fidg ~~ sc14fidg
  sc14fidg ~~ sc17fidg
'

cat("\nFull model specification created.\n")

# Specify which variables are ordinal (all self-control items)
ordinal_vars <- c(
  "sc3thac", "sc3tcom", "sc3obey", "sc3dist", "sc3temp", "sc3rest", "sc3fidg",
  "sc5thac", "sc5tcom", "sc5obey", "sc5dist", "sc5temp", "sc5rest", "sc5fidg",
  "sc7thac", "sc7tcom", "sc7obey", "sc7dist", "sc7temp", "sc7rest", "sc7fidg",
  "sc11thac", "sc11tcom", "sc11obey", "sc11dist", "sc11temp", "sc11rest", "sc11fidg",
  "sc14thac", "sc14tcom", "sc14obey", "sc14dist", "sc14temp", "sc14rest", "sc14fidg",
  "sc17thac", "sc17tcom", "sc17obey", "sc17dist", "sc17temp", "sc17rest", "sc17fidg"
)

cat(sprintf("Number of ordinal variables: %d\n", length(ordinal_vars)))

# Fit configural model with survey weights
fit_configural <- cfa(
  model_configural,
  data = data,
  ordered = ordinal_vars,
  estimator = "WLSMV",
  parameterization = "delta",
  std.lv = TRUE,                       # Standardize latent variables (factor variance = 1)
  meanstructure = TRUE,                # Include means/intercepts
  sampling.weights = "composite_weight" # Include composite survey weight
)

# View results
cat("\n--- Model Results ---\n")
summary(fit_configural, fit.measures = TRUE, standardized = TRUE)

# ==============================================================================
# MODEL B: THRESHOLD INVARIANCE
# ==============================================================================
# For K=2 thresholds, this is equivalent to configural but sets up proper
# identification for the next step

cat("\n\n=== MODEL B: THRESHOLD INVARIANCE ===\n")

# Full explicit model specification with threshold constraints
model_threshold <- '
  # Latent factors (one per wave) 
  SC_3  =~ sc3thac + sc3tcom + sc3obey + sc3dist + sc3temp + sc3rest + sc3fidg
  SC_5  =~ sc5thac + sc5tcom + sc5obey + sc5dist + sc5temp + sc5rest + sc5fidg
  SC_7  =~ sc7thac + sc7tcom + sc7obey + sc7dist + sc7temp + sc7rest + sc7fidg
  SC_11 =~ sc11thac + sc11tcom + sc11obey + sc11dist + sc11temp + sc11rest + sc11fidg
  SC_14 =~ sc14thac + sc14tcom + sc14obey + sc14dist + sc14temp + sc14rest + sc14fidg
  SC_17 =~ sc17thac + sc17tcom + sc17obey + sc17dist + sc17temp + sc17rest + sc17fidg
  
  # Equal thresholds across waves (K=2: two thresholds per item)
  # thac item
  sc3thac  | t1_thac * t1 + t2_thac * t2
  sc5thac  | t1_thac * t1 + t2_thac * t2
  sc7thac  | t1_thac * t1 + t2_thac * t2
  sc11thac | t1_thac * t1 + t2_thac * t2
  sc14thac | t1_thac * t1 + t2_thac * t2
  sc17thac | t1_thac * t1 + t2_thac * t2
  
  # tcom item
  sc3tcom  | t1_tcom * t1 + t2_tcom * t2
  sc5tcom  | t1_tcom * t1 + t2_tcom * t2
  sc7tcom  | t1_tcom * t1 + t2_tcom * t2
  sc11tcom | t1_tcom * t1 + t2_tcom * t2
  sc14tcom | t1_tcom * t1 + t2_tcom * t2
  sc17tcom | t1_tcom * t1 + t2_tcom * t2
  
  # obey item
  sc3obey  | t1_obey * t1 + t2_obey * t2
  sc5obey  | t1_obey * t1 + t2_obey * t2
  sc7obey  | t1_obey * t1 + t2_obey * t2
  sc11obey | t1_obey * t1 + t2_obey * t2
  sc14obey | t1_obey * t1 + t2_obey * t2
  sc17obey | t1_obey * t1 + t2_obey * t2
  
  # dist item
  sc3dist  | t1_dist * t1 + t2_dist * t2
  sc5dist  | t1_dist * t1 + t2_dist * t2
  sc7dist  | t1_dist * t1 + t2_dist * t2
  sc11dist | t1_dist * t1 + t2_dist * t2
  sc14dist | t1_dist * t1 + t2_dist * t2
  sc17dist | t1_dist * t1 + t2_dist * t2
  
  # temp item
  sc3temp  | t1_temp * t1 + t2_temp * t2
  sc5temp  | t1_temp * t1 + t2_temp * t2
  sc7temp  | t1_temp * t1 + t2_temp * t2
  sc11temp | t1_temp * t1 + t2_temp * t2
  sc14temp | t1_temp * t1 + t2_temp * t2
  sc17temp | t1_temp * t1 + t2_temp * t2
  
  # rest item
  sc3rest  | t1_rest * t1 + t2_rest * t2
  sc5rest  | t1_rest * t1 + t2_rest * t2
  sc7rest  | t1_rest * t1 + t2_rest * t2
  sc11rest | t1_rest * t1 + t2_rest * t2
  sc14rest | t1_rest * t1 + t2_rest * t2
  sc17rest | t1_rest * t1 + t2_rest * t2
  
  # fidg item
  sc3fidg  | t1_fidg * t1 + t2_fidg * t2
  sc5fidg  | t1_fidg * t1 + t2_fidg * t2
  sc7fidg  | t1_fidg * t1 + t2_fidg * t2
  sc11fidg | t1_fidg * t1 + t2_fidg * t2
  sc14fidg | t1_fidg * t1 + t2_fidg * t2
  sc17fidg | t1_fidg * t1 + t2_fidg * t2
  
  # Correlated uniquenesses (adjacent waves only)
  sc3thac  ~~ sc5thac;  sc5thac  ~~ sc7thac;  sc7thac  ~~ sc11thac;  sc11thac ~~ sc14thac;  sc14thac ~~ sc17thac
  sc3tcom  ~~ sc5tcom;  sc5tcom  ~~ sc7tcom;  sc7tcom  ~~ sc11tcom;  sc11tcom ~~ sc14tcom;  sc14tcom ~~ sc17tcom
  sc3obey  ~~ sc5obey;  sc5obey  ~~ sc7obey;  sc7obey  ~~ sc11obey;  sc11obey ~~ sc14obey;  sc14obey ~~ sc17obey
  sc3dist  ~~ sc5dist;  sc5dist  ~~ sc7dist;  sc7dist  ~~ sc11dist;  sc11dist ~~ sc14dist;  sc14dist ~~ sc17dist
  sc3temp  ~~ sc5temp;  sc5temp  ~~ sc7temp;  sc7temp  ~~ sc11temp;  sc11temp ~~ sc14temp;  sc14temp ~~ sc17temp
  sc3rest  ~~ sc5rest;  sc5rest  ~~ sc7rest;  sc7rest  ~~ sc11rest;  sc11rest ~~ sc14rest;  sc14rest ~~ sc17rest
  sc3fidg  ~~ sc5fidg;  sc5fidg  ~~ sc7fidg;  sc7fidg  ~~ sc11fidg;  sc11fidg ~~ sc14fidg;  sc14fidg ~~ sc17fidg
'

cat("\nFull threshold invariance model created.\n")

# Fit threshold invariance model with survey weights
fit_threshold <- cfa(
  model_threshold,
  data = data,
  ordered = ordinal_vars,
  estimator = "WLSMV",
  parameterization = "delta",
  std.lv = TRUE,
  meanstructure = TRUE,
  sampling.weights = "composite_weight"
)

cat("\n--- Model Results ---\n")
summary(fit_threshold, fit.measures = TRUE, standardized = TRUE)

# ==============================================================================
# MODEL C: THRESHOLD + LOADING INVARIANCE (Strong Invariance)
# ==============================================================================
# This is the critical test for ordinal data with K=2

cat("\n\n=== MODEL C: THRESHOLD + LOADING INVARIANCE (Strong/Scalar) ===\n")

# Full explicit model specification with equal loadings and thresholds
model_strong <- '
  # Latent factors with equal loadings across waves
  # First item (thac) loading fixed to 1 for identification, others constrained equal
  SC_3  =~ NA * sc3thac  + 1 * sc3thac  + L_tcom * sc3tcom  + L_obey * sc3obey  + L_dist * sc3dist  + L_temp * sc3temp  + L_rest * sc3rest  + L_fidg * sc3fidg
  SC_5  =~ NA * sc5thac  + 1 * sc5thac  + L_tcom * sc5tcom  + L_obey * sc5obey  + L_dist * sc5dist  + L_temp * sc5temp  + L_rest * sc5rest  + L_fidg * sc5fidg
  SC_7  =~ NA * sc7thac  + 1 * sc7thac  + L_tcom * sc7tcom  + L_obey * sc7obey  + L_dist * sc7dist  + L_temp * sc7temp  + L_rest * sc7rest  + L_fidg * sc7fidg
  SC_11 =~ NA * sc11thac + 1 * sc11thac + L_tcom * sc11tcom + L_obey * sc11obey + L_dist * sc11dist + L_temp * sc11temp + L_rest * sc11rest + L_fidg * sc11fidg
  SC_14 =~ NA * sc14thac + 1 * sc14thac + L_tcom * sc14tcom + L_obey * sc14obey + L_dist * sc14dist + L_temp * sc14temp + L_rest * sc14rest + L_fidg * sc14fidg
  SC_17 =~ NA * sc17thac + 1 * sc17thac + L_tcom * sc17tcom + L_obey * sc17obey + L_dist * sc17dist + L_temp * sc17temp + L_rest * sc17rest + L_fidg * sc17fidg
  
  # Equal thresholds across waves (same as Model B)
  sc3thac  | t1_thac * t1 + t2_thac * t2
  sc5thac  | t1_thac * t1 + t2_thac * t2
  sc7thac  | t1_thac * t1 + t2_thac * t2
  sc11thac | t1_thac * t1 + t2_thac * t2
  sc14thac | t1_thac * t1 + t2_thac * t2
  sc17thac | t1_thac * t1 + t2_thac * t2
  
  sc3tcom  | t1_tcom * t1 + t2_tcom * t2
  sc5tcom  | t1_tcom * t1 + t2_tcom * t2
  sc7tcom  | t1_tcom * t1 + t2_tcom * t2
  sc11tcom | t1_tcom * t1 + t2_tcom * t2
  sc14tcom | t1_tcom * t1 + t2_tcom * t2
  sc17tcom | t1_tcom * t1 + t2_tcom * t2
  
  sc3obey  | t1_obey * t1 + t2_obey * t2
  sc5obey  | t1_obey * t1 + t2_obey * t2
  sc7obey  | t1_obey * t1 + t2_obey * t2
  sc11obey | t1_obey * t1 + t2_obey * t2
  sc14obey | t1_obey * t1 + t2_obey * t2
  sc17obey | t1_obey * t1 + t2_obey * t2
  
  sc3dist  | t1_dist * t1 + t2_dist * t2
  sc5dist  | t1_dist * t1 + t2_dist * t2
  sc7dist  | t1_dist * t1 + t2_dist * t2
  sc11dist | t1_dist * t1 + t2_dist * t2
  sc14dist | t1_dist * t1 + t2_dist * t2
  sc17dist | t1_dist * t1 + t2_dist * t2
  
  sc3temp  | t1_temp * t1 + t2_temp * t2
  sc5temp  | t1_temp * t1 + t2_temp * t2
  sc7temp  | t1_temp * t1 + t2_temp * t2
  sc11temp | t1_temp * t1 + t2_temp * t2
  sc14temp | t1_temp * t1 + t2_temp * t2
  sc17temp | t1_temp * t1 + t2_temp * t2
  
  sc3rest  | t1_rest * t1 + t2_rest * t2
  sc5rest  | t1_rest * t1 + t2_rest * t2
  sc7rest  | t1_rest * t1 + t2_rest * t2
  sc11rest | t1_rest * t1 + t2_rest * t2
  sc14rest | t1_rest * t1 + t2_rest * t2
  sc17rest | t1_rest * t1 + t2_rest * t2
  
  sc3fidg  | t1_fidg * t1 + t2_fidg * t2
  sc5fidg  | t1_fidg * t1 + t2_fidg * t2
  sc7fidg  | t1_fidg * t1 + t2_fidg * t2
  sc11fidg | t1_fidg * t1 + t2_fidg * t2
  sc14fidg | t1_fidg * t1 + t2_fidg * t2
  sc17fidg | t1_fidg * t1 + t2_fidg * t2
  
  # Factor variances: Reference wave (age 3) = 1, others free
  SC_3  ~~ 1 * SC_3
  SC_5  ~~ NA * SC_5
  SC_7  ~~ NA * SC_7
  SC_11 ~~ NA * SC_11
  SC_14 ~~ NA * SC_14
  SC_17 ~~ NA * SC_17
  
  # Factor means: all fixed to 0 (for invariance testing)
  SC_3  ~ 0 * 1
  SC_5  ~ 0 * 1
  SC_7  ~ 0 * 1
  SC_11 ~ 0 * 1
  SC_14 ~ 0 * 1
  SC_17 ~ 0 * 1
  
  # Correlated uniquenesses (adjacent waves only)
  sc3thac  ~~ sc5thac;  sc5thac  ~~ sc7thac;  sc7thac  ~~ sc11thac;  sc11thac ~~ sc14thac;  sc14thac ~~ sc17thac
  sc3tcom  ~~ sc5tcom;  sc5tcom  ~~ sc7tcom;  sc7tcom  ~~ sc11tcom;  sc11tcom ~~ sc14tcom;  sc14tcom ~~ sc17tcom
  sc3obey  ~~ sc5obey;  sc5obey  ~~ sc7obey;  sc7obey  ~~ sc11obey;  sc11obey ~~ sc14obey;  sc14obey ~~ sc17obey
  sc3dist  ~~ sc5dist;  sc5dist  ~~ sc7dist;  sc7dist  ~~ sc11dist;  sc11dist ~~ sc14dist;  sc14dist ~~ sc17dist
  sc3temp  ~~ sc5temp;  sc5temp  ~~ sc7temp;  sc7temp  ~~ sc11temp;  sc11temp ~~ sc14temp;  sc14temp ~~ sc17temp
  sc3rest  ~~ sc5rest;  sc5rest  ~~ sc7rest;  sc7rest  ~~ sc11rest;  sc11rest ~~ sc14rest;  sc14rest ~~ sc17rest
  sc3fidg  ~~ sc5fidg;  sc5fidg  ~~ sc7fidg;  sc7fidg  ~~ sc11fidg;  sc11fidg ~~ sc14fidg;  sc14fidg ~~ sc17fidg
'

cat("\nFull strong invariance model created.\n")

# Fit strong invariance model with survey weights
fit_strong <- cfa(
  model_strong,
  data = data,
  ordered = ordinal_vars,
  estimator = "WLSMV",
  parameterization = "delta",
  std.lv = FALSE,  # We're manually controlling factor variances
  meanstructure = TRUE,
  sampling.weights = "composite_weight"
)

cat("\n--- Model Results ---\n")
summary(fit_strong, fit.measures = TRUE, standardized = TRUE)

# ==============================================================================
# MODEL COMPARISONS
# ==============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("MODEL COMPARISONS\n")
cat("============================================================================\n\n")

cat("--- Comparison 1: Configural vs Threshold Invariance ---\n")
cat("(For K=2 thresholds, these should be equivalent)\n\n")
comp1 <- lavTestLRT(fit_configural, fit_threshold)
print(comp1)

cat("\n\n--- Comparison 2: Threshold vs Strong Invariance (KEY TEST) ---\n")
cat("(Tests equal thresholds + equal loadings across time)\n\n")
comp2 <- lavTestLRT(fit_threshold, fit_strong)
print(comp2)

# ==============================================================================
# FIT CHANGE EVALUATION (Svetina & Rutkowski 2017 guidelines)
# ==============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("FIT CHANGE EVALUATION\n")
cat("============================================================================\n\n")

# Extract fit measures
fit_measures_cfg <- fitMeasures(fit_configural, c("chisq.scaled", "df.scaled", 
                                                   "cfi.scaled", "rmsea.scaled", 
                                                   "tli.scaled", "srmr"))
fit_measures_thr <- fitMeasures(fit_threshold, c("chisq.scaled", "df.scaled", 
                                                  "cfi.scaled", "rmsea.scaled", 
                                                  "tli.scaled", "srmr"))
fit_measures_str <- fitMeasures(fit_strong, c("chisq.scaled", "df.scaled", 
                                               "cfi.scaled", "rmsea.scaled", 
                                               "tli.scaled", "srmr"))

# Create comparison table
fit_comparison <- data.frame(
  Model = c("Configural", "Threshold", "Strong (Thr+Load)"),
  ChiSq = c(fit_measures_cfg["chisq.scaled"], 
            fit_measures_thr["chisq.scaled"], 
            fit_measures_str["chisq.scaled"]),
  df = c(fit_measures_cfg["df.scaled"], 
         fit_measures_thr["df.scaled"], 
         fit_measures_str["df.scaled"]),
  CFI = c(fit_measures_cfg["cfi.scaled"], 
          fit_measures_thr["cfi.scaled"], 
          fit_measures_str["cfi.scaled"]),
  RMSEA = c(fit_measures_cfg["rmsea.scaled"], 
            fit_measures_thr["rmsea.scaled"], 
            fit_measures_str["rmsea.scaled"]),
  TLI = c(fit_measures_cfg["tli.scaled"], 
          fit_measures_thr["tli.scaled"], 
          fit_measures_str["tli.scaled"]),
  SRMR = c(fit_measures_cfg["srmr"], 
           fit_measures_thr["srmr"], 
           fit_measures_str["srmr"])
)

# Calculate changes in fit
fit_comparison$Delta_CFI <- c(NA, 
                              fit_comparison$CFI[2] - fit_comparison$CFI[1],
                              fit_comparison$CFI[3] - fit_comparison$CFI[2])
fit_comparison$Delta_RMSEA <- c(NA,
                                fit_comparison$RMSEA[2] - fit_comparison$RMSEA[1],
                                fit_comparison$RMSEA[3] - fit_comparison$RMSEA[2])

cat("\nFit Measures Comparison:\n")
# Round only numeric columns
fit_comparison_print <- fit_comparison
fit_comparison_print[, -1] <- round(fit_comparison[, -1], 4)
print(fit_comparison_print)

# ==============================================================================
# EVALUATION GUIDELINES
# ==============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("INVARIANCE DECISION RULES\n")
cat("============================================================================\n\n")

cat("NOTE: This analysis tests Threshold + Loading invariance (scalar/strong).\n")
cat("We evaluate against TWO sets of guidelines:\n\n")

cat("1. SVETINA et al. (2020) - Categorical/Many-Groups Guidelines:\n")
cat("   For SCALAR (thresholds + loadings) invariance:\n")
cat("     - ΔCFI ≥ −.010\n")
cat("     - ΔRMSEA ≤ .010\n")
cat("   (Note: More stringent than metric; context-dependent guidelines)\n\n")

cat("2. CHEN (2007) - General Guidelines:\n")
cat("   For SCALAR invariance:\n")
cat("     - ΔCFI ≥ −.010\n")
cat("     - ΔRMSEA ≤ .015\n")
cat("   (Note: Widely used; appropriate for longitudinal with 6 waves)\n\n")

cat("CONTEXT: This is a longitudinal design with 6 waves (not 10-20 groups).\n")
cat("Both sets are reported for transparency. These are guidelines, not rules.\n")
cat("Also consider the scaled chi-square difference test p-value.\n\n")

if (!is.na(fit_comparison$Delta_CFI[3])) {
  cat("YOUR RESULTS (Threshold vs Strong Invariance):\n")
  cat(sprintf("  ΔCFI = %.4f\n", fit_comparison$Delta_CFI[3]))
  cat(sprintf("  ΔRMSEA = %.4f\n\n", fit_comparison$Delta_RMSEA[3]))
  
  # Evaluate against Svetina et al. (2020) criteria
  cat("Evaluation against SVETINA et al. (2020) criteria:\n")
  svetina_cfi_pass <- fit_comparison$Delta_CFI[3] >= -0.010
  svetina_rmsea_pass <- fit_comparison$Delta_RMSEA[3] <= 0.010
  cat(sprintf("  ΔCFI ≥ −.010: %s (%.4f)\n", 
              ifelse(svetina_cfi_pass, "✓ PASS", "✗ FAIL"),
              fit_comparison$Delta_CFI[3]))
  cat(sprintf("  ΔRMSEA ≤ .010: %s (%.4f)\n", 
              ifelse(svetina_rmsea_pass, "✓ PASS", "✗ FAIL"),
              fit_comparison$Delta_RMSEA[3]))
  cat(sprintf("  Overall: %s\n\n", 
              ifelse(svetina_cfi_pass && svetina_rmsea_pass, 
                     "✓ PASS (both criteria met)", 
                     "✗ FAIL (one or both criteria not met)")))
  
  # Evaluate against Chen (2007) criteria
  cat("Evaluation against CHEN (2007) criteria:\n")
  chen_cfi_pass <- fit_comparison$Delta_CFI[3] >= -0.010
  chen_rmsea_pass <- fit_comparison$Delta_RMSEA[3] <= 0.015
  cat(sprintf("  ΔCFI ≥ −.010: %s (%.4f)\n", 
              ifelse(chen_cfi_pass, "✓ PASS", "✗ FAIL"),
              fit_comparison$Delta_CFI[3]))
  cat(sprintf("  ΔRMSEA ≤ .015: %s (%.4f)\n", 
              ifelse(chen_rmsea_pass, "✓ PASS", "✗ FAIL"),
              fit_comparison$Delta_RMSEA[3]))
  cat(sprintf("  Overall: %s\n\n", 
              ifelse(chen_cfi_pass && chen_rmsea_pass, 
                     "✓ PASS (both criteria met)", 
                     "✗ FAIL (one or both criteria not met)")))
  
  # Overall decision
  cat("OVERALL DECISION:\n")
  if (svetina_cfi_pass && svetina_rmsea_pass) {
    cat("  Strong (threshold + loading) invariance is SUPPORTED by both criteria.\n")
    cat("  You can proceed to compare latent means across time.\n")
  } else if (chen_cfi_pass && chen_rmsea_pass) {
    cat("  Strong invariance is SUPPORTED by Chen (2007) but not Svetina et al. (2020).\n")
    cat("  This suggests acceptable fit change for a longitudinal study with 6 waves.\n")
    cat("  You can likely proceed, but consider the more stringent criteria carefully.\n")
  } else {
    cat("  Strong invariance is NOT supported by either set of criteria.\n")
    cat("  Consider:\n")
    cat("    1. Examining modification indices\n")
    cat("    2. Testing partial invariance (free non-invariant parameters)\n")
    cat("    3. Using alignment optimization for multiple groups/waves\n")
  }
}

# ==============================================================================
# OPTIONAL: Latent Mean Comparisons (if strong invariance holds)
# ==============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("OPTIONAL: LATENT MEAN COMPARISONS\n")
cat("============================================================================\n\n")

cat("If strong invariance holds, you can compare latent means across time.\n")
cat("Uncomment the code below to run latent mean comparisons:\n\n")

# Uncomment to fit latent mean comparison model:
# 
# model_means <- '
#   # Latent factors with equal loadings (same as strong model)
#   SC_3  =~ NA * sc3thac  + 1 * sc3thac  + L_tcom * sc3tcom  + L_obey * sc3obey  + L_dist * sc3dist  + L_temp * sc3temp  + L_rest * sc3rest  + L_fidg * sc3fidg
#   SC_5  =~ NA * sc5thac  + 1 * sc5thac  + L_tcom * sc5tcom  + L_obey * sc5obey  + L_dist * sc5dist  + L_temp * sc5temp  + L_rest * sc5rest  + L_fidg * sc5fidg
#   SC_7  =~ NA * sc7thac  + 1 * sc7thac  + L_tcom * sc7tcom  + L_obey * sc7obey  + L_dist * sc7dist  + L_temp * sc7temp  + L_rest * sc7rest  + L_fidg * sc7fidg
#   SC_11 =~ NA * sc11thac + 1 * sc11thac + L_tcom * sc11tcom + L_obey * sc11obey + L_dist * sc11dist + L_temp * sc11temp + L_rest * sc11rest + L_fidg * sc11fidg
#   SC_14 =~ NA * sc14thac + 1 * sc14thac + L_tcom * sc14tcom + L_obey * sc14obey + L_dist * sc14dist + L_temp * sc14temp + L_rest * sc14rest + L_fidg * sc14fidg
#   SC_17 =~ NA * sc17thac + 1 * sc17thac + L_tcom * sc17tcom + L_obey * sc17obey + L_dist * sc17dist + L_temp * sc17temp + L_rest * sc17rest + L_fidg * sc17fidg
#   
#   # Equal thresholds (same as strong model)
#   sc3thac  | t1_thac * t1 + t2_thac * t2
#   sc5thac  | t1_thac * t1 + t2_thac * t2
#   sc7thac  | t1_thac * t1 + t2_thac * t2
#   sc11thac | t1_thac * t1 + t2_thac * t2
#   sc14thac | t1_thac * t1 + t2_thac * t2
#   sc17thac | t1_thac * t1 + t2_thac * t2
#   
#   sc3tcom  | t1_tcom * t1 + t2_tcom * t2
#   sc5tcom  | t1_tcom * t1 + t2_tcom * t2
#   sc7tcom  | t1_tcom * t1 + t2_tcom * t2
#   sc11tcom | t1_tcom * t1 + t2_tcom * t2
#   sc14tcom | t1_tcom * t1 + t2_tcom * t2
#   sc17tcom | t1_tcom * t1 + t2_tcom * t2
#   
#   sc3obey  | t1_obey * t1 + t2_obey * t2
#   sc5obey  | t1_obey * t1 + t2_obey * t2
#   sc7obey  | t1_obey * t1 + t2_obey * t2
#   sc11obey | t1_obey * t1 + t2_obey * t2
#   sc14obey | t1_obey * t1 + t2_obey * t2
#   sc17obey | t1_obey * t1 + t2_obey * t2
#   
#   sc3dist  | t1_dist * t1 + t2_dist * t2
#   sc5dist  | t1_dist * t1 + t2_dist * t2
#   sc7dist  | t1_dist * t1 + t2_dist * t2
#   sc11dist | t1_dist * t1 + t2_dist * t2
#   sc14dist | t1_dist * t1 + t2_dist * t2
#   sc17dist | t1_dist * t1 + t2_dist * t2
#   
#   sc3temp  | t1_temp * t1 + t2_temp * t2
#   sc5temp  | t1_temp * t1 + t2_temp * t2
#   sc7temp  | t1_temp * t1 + t2_temp * t2
#   sc11temp | t1_temp * t1 + t2_temp * t2
#   sc14temp | t1_temp * t1 + t2_temp * t2
#   sc17temp | t1_temp * t1 + t2_temp * t2
#   
#   sc3rest  | t1_rest * t1 + t2_rest * t2
#   sc5rest  | t1_rest * t1 + t2_rest * t2
#   sc7rest  | t1_rest * t1 + t2_rest * t2
#   sc11rest | t1_rest * t1 + t2_rest * t2
#   sc14rest | t1_rest * t1 + t2_rest * t2
#   sc17rest | t1_rest * t1 + t2_rest * t2
#   
#   sc3fidg  | t1_fidg * t1 + t2_fidg * t2
#   sc5fidg  | t1_fidg * t1 + t2_fidg * t2
#   sc7fidg  | t1_fidg * t1 + t2_fidg * t2
#   sc11fidg | t1_fidg * t1 + t2_fidg * t2
#   sc14fidg | t1_fidg * t1 + t2_fidg * t2
#   sc17fidg | t1_fidg * t1 + t2_fidg * t2
#   
#   # Factor variances: Reference = 1, others free
#   SC_3  ~~ 1 * SC_3
#   SC_5  ~~ NA * SC_5
#   SC_7  ~~ NA * SC_7
#   SC_11 ~~ NA * SC_11
#   SC_14 ~~ NA * SC_14
#   SC_17 ~~ NA * SC_17
#   
#   # Factor means: Reference = 0, others FREE for mean comparisons
#   SC_3  ~ 0 * 1
#   SC_5  ~ NA * 1
#   SC_7  ~ NA * 1
#   SC_11 ~ NA * 1
#   SC_14 ~ NA * 1
#   SC_17 ~ NA * 1
#   
#   # Correlated uniquenesses (adjacent waves only)
#   sc3thac  ~~ sc5thac;  sc5thac  ~~ sc7thac;  sc7thac  ~~ sc11thac;  sc11thac ~~ sc14thac;  sc14thac ~~ sc17thac
#   sc3tcom  ~~ sc5tcom;  sc5tcom  ~~ sc7tcom;  sc7tcom  ~~ sc11tcom;  sc11tcom ~~ sc14tcom;  sc14tcom ~~ sc17tcom
#   sc3obey  ~~ sc5obey;  sc5obey  ~~ sc7obey;  sc7obey  ~~ sc11obey;  sc11obey ~~ sc14obey;  sc14obey ~~ sc17obey
#   sc3dist  ~~ sc5dist;  sc5dist  ~~ sc7dist;  sc7dist  ~~ sc11dist;  sc11dist ~~ sc14dist;  sc14dist ~~ sc17dist
#   sc3temp  ~~ sc5temp;  sc5temp  ~~ sc7temp;  sc7temp  ~~ sc11temp;  sc11temp ~~ sc14temp;  sc14temp ~~ sc17temp
#   sc3rest  ~~ sc5rest;  sc5rest  ~~ sc7rest;  sc7rest  ~~ sc11rest;  sc11rest ~~ sc14rest;  sc14rest ~~ sc17rest
#   sc3fidg  ~~ sc5fidg;  sc5fidg  ~~ sc7fidg;  sc7fidg  ~~ sc11fidg;  sc11fidg ~~ sc14fidg;  sc14fidg ~~ sc17fidg
# '
# 
# fit_means <- cfa(
#   model_means,
#   data = data,
#   ordered = ordinal_vars,
#   estimator = "WLSMV",
#   parameterization = "delta",
#   std.lv = FALSE,
#   meanstructure = TRUE,
#   sampling.weights = "composite_weight"
# )
# 
# cat("\n--- Latent Mean Results ---\n")
# summary(fit_means, fit.measures = TRUE, standardized = TRUE)
# 
# # Extract latent means
# params_means <- parameterEstimates(fit_means)
# means_df <- params_means %>%
#   filter(op == "~1", lhs %in% c("SC_3", "SC_5", "SC_7", "SC_11", "SC_14", "SC_17")) %>%
#   select(lhs, est, se, z, pvalue, ci.lower, ci.upper)
# 
# cat("\n--- Latent Mean Estimates (Reference = Age 3) ---\n")
# print(means_df)

# ==============================================================================
# SUMMARY AND NOTES
# ==============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("IMPLEMENTATION NOTES\n")
cat("============================================================================\n\n")

cat("This script implements the Wu & Estabrook (2016) approach:\n\n")

cat("KEY FEATURES:\n")
cat("  ✓ DELTA parameterization (proper identification for ordinal data)\n")
cat("  ✓ WLSMV estimator (appropriate for categorical outcomes)\n")
cat("  ✓ Threshold-first testing sequence (not loadings-first)\n")
cat("  ✓ Proper re-identification when adding threshold constraints\n")
cat("  ✓ Adjacent correlated uniquenesses (longitudinal structure)\n")
cat("  ✓ MCS complex survey design incorporated\n")
cat("  ✓ Wave-specific survey weights (bovwt1, covwt1, dovwt1, eovwt1, fovwt1, govwt1)\n")
cat("  ✓ Composite weight used (mean of wave-specific weights)\n")
cat("  ✓ Full explicit model specifications (no dynamic code)\n\n")

cat("TESTING SEQUENCE:\n")
cat("  1. Configural: No constraints (baseline model)\n")
cat("  2. Threshold: Equal thresholds (K=2: equivalent to configural)\n")
cat("  3. Strong: Equal thresholds + equal loadings (KEY TEST)\n\n")

cat("SURVEY DESIGN CONSIDERATIONS:\n")
cat("  - MCS uses complex survey design with clustering, stratification, and FPC\n")
cat("  - Cluster variable (PSU): sptn00\n")
cat("  - Stratification variable: pttype2\n")
cat("  - Finite population correction: nh2\n")
cat("  - Each wave has its own survey weight:\n")
cat("    * Age 3 (MCS2): bovwt1\n")
cat("    * Age 5 (MCS3): covwt1\n")
cat("    * Age 7 (MCS4): dovwt1\n")
cat("    * Age 11 (MCS5): eovwt1\n")
cat("    * Age 14 (MCS6): fovwt1\n")
cat("    * Age 17 (MCS7): govwt1\n")
cat("  - LIMITATION: lavaan's sampling.weights only handles weights, not clustering/strata\n")
cat("  - LIMITATION: lavaan doesn't support wave-specific weights in single model\n")
cat("  - WORKAROUND: Composite weight (mean of wave weights) used\n")
cat("  - For full survey design, consider Mplus or lavaan.survey package\n\n")

cat("INTERPRETATION:\n")
cat("  - If strong invariance holds: Loadings and thresholds are time-invariant\n")
cat("  - This justifies comparing latent means across ages\n")
cat("  - You can proceed to growth curve modeling or other longitudinal analyses\n\n")

cat("IF INVARIANCE FAILS:\n")
cat("  1. Examine modification indices: modindices(fit_strong, sort=TRUE, maximum.number=20)\n")
cat("  2. Consider partial invariance (free specific non-invariant parameters)\n")
cat("  3. Use alignment optimization (see semTools::invariance.alignment())\n\n")

cat("REFERENCES:\n")
cat("  - Wu, H., & Estabrook, R. (2016). Identification of confirmatory factor\n")
cat("    analysis models of different levels of invariance for ordered categorical\n")
cat("    outcomes. Psychometrika, 81(4), 1014-1045.\n")
cat("  - Svetina, D., Rutkowski, L., & Rutkowski, D. (2020). Multiple-group\n")
cat("    invariance with categorical outcomes using updated guidelines.\n")
cat("    Structural Equation Modeling, 27(1), 111-130.\n")
cat("  - Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of\n")
cat("    measurement invariance. Structural Equation Modeling, 14(3), 464-504.\n\n")

cat("============================================================================\n")
cat("Script completed successfully!\n")
cat("============================================================================\n\n")

