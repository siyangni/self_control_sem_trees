# ==============================================================================
# Extract Factor Scores for Two-Stage SEMTree Analysis
# ==============================================================================
#
# Purpose: Extract factor scores with standard errors for use in two-stage
#          SEMTree analyses (Strategy A from improved workflow)
#
# Approach:
#   1. Extract wave-specific self-control factor scores (ages 3-17)
#   2. Extract growth parameters (intercept, slope) from LGBM
#   3. Save with standard errors for measurement error propagation
#   4. Merge with covariates to create analysis-ready dataset
#
# Input:
#   - data/processed/mcs_semtree_complete_minimal.RData (from Phase 0)
#   - Fitted lavaan models (from scripts 01-04)
#
# Output:
#   - data/processed/mcs_factor_scores.RData
#   - data/processed/mcs_growth_parameters.RData
#   - data/processed/mcs_twostage_dataset.RData (factor scores + covariates)
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, here, semTools)

cat("\n")
cat("==============================================================================\n")
cat("EXTRACTING FACTOR SCORES FOR TWO-STAGE SEMTREE ANALYSIS\n")
cat("==============================================================================\n\n")

processed_path <- here("data", "processed")
results_path <- here("results")

# ------------------------------------------------------------------------------
# STEP 1: Load Data and Fitted Models
# ------------------------------------------------------------------------------

cat("Step 1: Loading data and fitted models...\n")

# Load complete case data from Phase 0
load(file.path(processed_path, "mcs_semtree_complete_minimal.RData"))
cat("  ✓ Loaded", nrow(mcs_semtree_complete_minimal), "participants\n")

# Load fitted LGBM model (from script 04)
if (file.exists(file.path(results_path, "models", "lgbm_final.RData"))) {
  load(file.path(results_path, "models", "lgbm_final.RData"))
  cat("  ✓ Loaded LGBM model\n")
} else {
  stop("ERROR: LGBM model not found. Please run R/04_lgbm.R first.")
}

# ------------------------------------------------------------------------------
# STEP 2: Extract Wave-Specific Factor Scores
# ------------------------------------------------------------------------------

cat("\nStep 2: Extracting wave-specific self-control factor scores...\n")

# Define wave-specific CFA models
cfa_age3 <- '
  SC_3 =~ sc_3_thac + sc_3_tcom + sc_3_obey + sc_3_dist +
          sc_3_temp + sc_3_rest + sc_3_fidg
'

cfa_age5 <- '
  SC_5 =~ sc_5_thac + sc_5_tcom + sc_5_obey + sc_5_dist +
          sc_5_temp + sc_5_rest + sc_5_fidg + sc_5_lyin
'

cfa_age7 <- '
  SC_7 =~ sc_7_thac + sc_7_tcom + sc_7_obey + sc_7_dist +
          sc_7_temp + sc_7_rest + sc_7_fidg + sc_7_lyin
'

cfa_age11 <- '
  SC_11 =~ sc_11_thac + sc_11_tcom + sc_11_obey + sc_11_dist +
           sc_11_temp + sc_11_rest + sc_11_fidg + sc_11_lyin
'

cfa_age14 <- '
  SC_14 =~ sc_14_thac + sc_14_tcom + sc_14_obey + sc_14_dist +
           sc_14_temp + sc_14_rest + sc_14_fidg + sc_14_lyin
'

cfa_age17 <- '
  SC_17 =~ sc_17_thac + sc_17_tcom + sc_17_obey + sc_17_dist +
           sc_17_temp + sc_17_rest + sc_17_fidg + sc_17_lyin
'

# Fit wave-specific CFA models
fit_age3 <- cfa(cfa_age3, data = mcs_semtree_complete_minimal,
                ordered = TRUE, estimator = "WLSMV")
fit_age5 <- cfa(cfa_age5, data = mcs_semtree_complete_minimal,
                ordered = TRUE, estimator = "WLSMV")
fit_age7 <- cfa(cfa_age7, data = mcs_semtree_complete_minimal,
                ordered = TRUE, estimator = "WLSMV")
fit_age11 <- cfa(cfa_age11, data = mcs_semtree_complete_minimal,
                 ordered = TRUE, estimator = "WLSMV")
fit_age14 <- cfa(cfa_age14, data = mcs_semtree_complete_minimal,
                 ordered = TRUE, estimator = "WLSMV")
fit_age17 <- cfa(cfa_age17, data = mcs_semtree_complete_minimal,
                 ordered = TRUE, estimator = "WLSMV")

cat("  ✓ Fitted wave-specific CFA models\n")

# Extract factor scores with standard errors
fs_age3 <- lavPredict(fit_age3, type = "lv", se = "standard",
                      method = "EBM")  # Empirical Bayes Modal
fs_age5 <- lavPredict(fit_age5, type = "lv", se = "standard", method = "EBM")
fs_age7 <- lavPredict(fit_age7, type = "lv", se = "standard", method = "EBM")
fs_age11 <- lavPredict(fit_age11, type = "lv", se = "standard", method = "EBM")
fs_age14 <- lavPredict(fit_age14, type = "lv", se = "standard", method = "EBM")
fs_age17 <- lavPredict(fit_age17, type = "lv", se = "standard", method = "EBM")

# Combine factor scores into data frame
factor_scores <- data.frame(
  mcsid = mcs_semtree_complete_minimal$mcsid,

  # Factor scores
  SC_3 = as.numeric(fs_age3[, 1]),
  SC_5 = as.numeric(fs_age5[, 1]),
  SC_7 = as.numeric(fs_age7[, 1]),
  SC_11 = as.numeric(fs_age11[, 1]),
  SC_14 = as.numeric(fs_age14[, 1]),
  SC_17 = as.numeric(fs_age17[, 1]),

  # Standard errors
  SC_3_se = attr(fs_age3, "se")[, 1],
  SC_5_se = attr(fs_age5, "se")[, 1],
  SC_7_se = attr(fs_age7, "se")[, 1],
  SC_11_se = attr(fs_age11, "se")[, 1],
  SC_14_se = attr(fs_age14, "se")[, 1],
  SC_17_se = attr(fs_age17, "se")[, 1]
)

cat("  ✓ Extracted factor scores for", nrow(factor_scores), "participants\n")
cat("  ✓ Mean reliability (1 - se²/var):",
    round(mean(1 - factor_scores$SC_3_se^2 / var(factor_scores$SC_3)), 3), "\n")

# Save factor scores
save(factor_scores, file = file.path(processed_path, "mcs_factor_scores.RData"))
cat("  ✓ Saved to data/processed/mcs_factor_scores.RData\n")

# ------------------------------------------------------------------------------
# STEP 3: Extract Growth Parameters from LGBM
# ------------------------------------------------------------------------------

cat("\nStep 3: Extracting growth parameters (intercept, slope) from LGBM...\n")

# Extract growth parameter estimates with standard errors
growth_params <- lavPredict(lgbm_final, type = "lv", se = "standard",
                           method = "EBM")

# Create data frame
growth_parameters <- data.frame(
  mcsid = mcs_semtree_complete_minimal$mcsid,

  # Growth parameters (if LGBM has eta_I and eta_S)
  intercept = as.numeric(growth_params[, "eta_I"]),
  slope = as.numeric(growth_params[, "eta_S"]),

  # Standard errors
  intercept_se = attr(growth_params, "se")[, "eta_I"],
  slope_se = attr(growth_params, "se")[, "eta_S"]
)

cat("  ✓ Extracted growth parameters for", nrow(growth_parameters), "participants\n")
cat("\nGrowth Parameter Summary:\n")
cat("  Intercept: M =", round(mean(growth_parameters$intercept), 3),
    ", SD =", round(sd(growth_parameters$intercept), 3), "\n")
cat("  Slope:     M =", round(mean(growth_parameters$slope), 3),
    ", SD =", round(sd(growth_parameters$slope), 3), "\n")

# Correlations
cat("  Correlation (I-S):", round(cor(growth_parameters$intercept,
                                      growth_parameters$slope), 3), "\n")

# Save growth parameters
save(growth_parameters,
     file = file.path(processed_path, "mcs_growth_parameters.RData"))
cat("  ✓ Saved to data/processed/mcs_growth_parameters.RData\n")

# ------------------------------------------------------------------------------
# STEP 4: Create Two-Stage Analysis Dataset
# ------------------------------------------------------------------------------

cat("\nStep 4: Creating two-stage analysis dataset...\n")

# Merge factor scores, growth parameters, and covariates
twostage_data <- mcs_semtree_complete_minimal %>%
  left_join(factor_scores, by = "mcsid") %>%
  left_join(growth_parameters, by = "mcsid")

cat("  ✓ Merged data: N =", nrow(twostage_data), "\n")
cat("  ✓ Variables:", ncol(twostage_data), "\n")

# Quality checks
cat("\nQuality Checks:\n")
cat("  Complete cases (all factor scores):",
    sum(complete.cases(twostage_data[, c("SC_3", "SC_5", "SC_7",
                                          "SC_11", "SC_14", "SC_17")])), "\n")
cat("  Complete cases (growth parameters):",
    sum(complete.cases(twostage_data[, c("intercept", "slope")])), "\n")

# Save combined dataset
save(twostage_data,
     file = file.path(processed_path, "mcs_twostage_dataset.RData"))
cat("  ✓ Saved to data/processed/mcs_twostage_dataset.RData\n")

# ------------------------------------------------------------------------------
# STEP 5: Create Summary Visualizations
# ------------------------------------------------------------------------------

cat("\nStep 5: Creating summary visualizations...\n")

# Create plots directory
dir.create(file.path(results_path, "plots", "factor_scores"),
           showWarnings = FALSE, recursive = TRUE)

library(ggplot2)

# Plot 1: Factor score distributions
pdf(file.path(results_path, "plots", "factor_scores",
              "factor_score_distributions.pdf"),
    width = 12, height = 8)

factor_scores_long <- factor_scores %>%
  select(mcsid, starts_with("SC_")) %>%
  select(-ends_with("_se")) %>%
  pivot_longer(cols = starts_with("SC_"),
               names_to = "age",
               values_to = "factor_score") %>%
  mutate(age = as.numeric(str_extract(age, "\\d+")))

ggplot(factor_scores_long, aes(x = factor_score, fill = factor(age))) +
  geom_density(alpha = 0.5) +
  facet_wrap(~age, ncol = 3) +
  theme_minimal() +
  labs(title = "Self-Control Factor Score Distributions by Age",
       x = "Factor Score",
       y = "Density",
       fill = "Age") +
  theme(legend.position = "none")

dev.off()

# Plot 2: Growth parameters
pdf(file.path(results_path, "plots", "factor_scores",
              "growth_parameters.pdf"),
    width = 10, height = 5)

par(mfrow = c(1, 2))

hist(growth_parameters$intercept, breaks = 30,
     main = "Intercept Distribution",
     xlab = "Intercept (Initial Self-Control at Age 3)",
     col = "steelblue", border = "white")

hist(growth_parameters$slope, breaks = 30,
     main = "Slope Distribution",
     xlab = "Slope (Rate of Change)",
     col = "coral", border = "white")

dev.off()

# Plot 3: Intercept-Slope scatterplot
pdf(file.path(results_path, "plots", "factor_scores",
              "intercept_slope_scatter.pdf"),
    width = 8, height = 8)

ggplot(growth_parameters, aes(x = intercept, y = slope)) +
  geom_point(alpha = 0.3, color = "steelblue") +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  theme_minimal() +
  labs(title = "Relationship Between Intercept and Slope",
       x = "Intercept (Initial Self-Control)",
       y = "Slope (Rate of Change)",
       caption = paste0("r = ",
                       round(cor(growth_parameters$intercept,
                                growth_parameters$slope), 3)))

dev.off()

cat("  ✓ Saved 3 visualization PDFs\n")

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("FACTOR SCORE EXTRACTION COMPLETE!\n")
cat("==============================================================================\n\n")

cat("Created Datasets:\n")
cat("  1. mcs_factor_scores.RData (N =", nrow(factor_scores), ")\n")
cat("     - Wave-specific factor scores (SC_3 through SC_17)\n")
cat("     - Standard errors for each wave\n\n")

cat("  2. mcs_growth_parameters.RData (N =", nrow(growth_parameters), ")\n")
cat("     - Intercept (initial self-control)\n")
cat("     - Slope (rate of change)\n")
cat("     - Standard errors for both\n\n")

cat("  3. mcs_twostage_dataset.RData (N =", nrow(twostage_data), ")\n")
cat("     - Combined: factor scores + growth params + covariates\n")
cat("     - Ready for two-stage SEMTree analysis\n\n")

cat("Visualizations:\n")
cat("  - results/plots/factor_scores/factor_score_distributions.pdf\n")
cat("  - results/plots/factor_scores/growth_parameters.pdf\n")
cat("  - results/plots/factor_scores/intercept_slope_scatter.pdf\n\n")

cat("Next Steps:\n")
cat("  - Run 06b_semtree_intercept.R (Intercept tree)\n")
cat("  - Run 06c_semtree_slope.R (Slope tree)\n")
cat("  - Run 06d_semtree_timespecific.R (Time-specific trees)\n\n")

cat("==============================================================================\n\n")
