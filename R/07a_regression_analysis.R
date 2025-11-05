# ==============================================================================
# Traditional Regression Analysis of Growth Parameters
# ==============================================================================
#
# Purpose: Complement SEMTree with traditional regression to detect small
#          uniform effects across the population
#
# Rationale:
#   - SEMTree finds SUBGROUPS (interactions)
#   - Regression finds MAIN EFFECTS (uniform associations)
#   - Small uniform effects may not split but still be important!
#
# Strategy:
#   1. Regress intercept on baseline covariates
#   2. Regress slope on baseline + time-varying covariates
#   3. Test interactions (SES × Parenting, Sex × Parenting)
#   4. Calculate effect sizes (β, R², f²)
#   5. Compare with SEMTree findings
#
# Input:  data/processed/mcs_twostage_dataset.RData
# Output: results/regression/intercept_slope_regression.RData
#
# ==============================================================================

library(pacman)
p_load(tidyverse, here, broom, ggplot2, car)  # car for VIF

cat("\n")
cat("==============================================================================\n")
cat("TRADITIONAL REGRESSION ANALYSIS\n")
cat("==============================================================================\n\n")

processed_path <- here("data", "processed")
results_path <- here("results")

dir.create(file.path(results_path, "regression"), showWarnings = FALSE)
dir.create(file.path(results_path, "plots", "regression"),
          showWarnings = FALSE, recursive = TRUE)

# Load data
load(file.path(processed_path, "mcs_twostage_dataset.RData"))

# ------------------------------------------------------------------------------
# MODEL 1: Intercept Regression (Initial Self-Control)
# ------------------------------------------------------------------------------

cat("===== MODEL 1: INTERCEPT (INITIAL SELF-CONTROL) =====\n\n")

# Predictors: Baseline characteristics only
intercept_formula <- as.formula(
  "intercept ~ sex + ethnicity_white + ses_disadvantage +
   cognitive_ability + low_birth_weight + premature + harsh_early"
)

# Fit model
m1 <- lm(intercept_formula, data = twostage_data)

cat("Summary:\n")
summary(m1)

# Standardized coefficients
m1_std <- lm(scale(intercept) ~ scale(sex) + scale(ethnicity_white) +
            scale(ses_disadvantage) + scale(cognitive_ability) +
            scale(low_birth_weight) + scale(premature) + scale(harsh_early),
            data = twostage_data)

# Effect sizes
m1_results <- tidy(m1) %>%
  mutate(
    std_beta = coef(m1_std)[-1],  # Exclude intercept
    r_squared = summary(m1)$r.squared,
    adj_r_squared = summary(m1)$adj.r.squared
  )

cat("\nStandardized Coefficients:\n")
print(m1_results %>% select(term, estimate, std_beta, p.value), row.names = FALSE)

cat("\nModel Fit:\n")
cat("  R² =", round(summary(m1)$r.squared, 4), "\n")
cat("  Adj. R² =", round(summary(m1)$adj.r.squared, 4), "\n")
cat("  F =", round(summary(m1)$fstatistic[1], 2), "\n")

# VIF (multicollinearity check)
vif_vals <- vif(m1)
cat("\nVariance Inflation Factors (VIF):\n")
print(vif_vals)
if (any(vif_vals > 5)) {
  cat("  WARNING: VIF > 5 detected (multicollinearity concern)\n")
}

# ------------------------------------------------------------------------------
# MODEL 2: Slope Regression (Rate of Change)
# ------------------------------------------------------------------------------

cat("\n\n===== MODEL 2: SLOPE (RATE OF CHANGE) =====\n\n")

# Predictors: Baseline + time-varying parenting
slope_formula <- as.formula(
  "slope ~ sex + ethnicity_white + ses_disadvantage + cognitive_ability +
   harsh_early + pos_early + mon_avg"
)

# Fit model
m2 <- lm(slope_formula, data = twostage_data)

cat("Summary:\n")
summary(m2)

# Standardized coefficients
m2_std <- lm(scale(slope) ~ scale(sex) + scale(ethnicity_white) +
            scale(ses_disadvantage) + scale(cognitive_ability) +
            scale(harsh_early) + scale(pos_early) + scale(mon_avg),
            data = twostage_data)

m2_results <- tidy(m2) %>%
  mutate(
    std_beta = coef(m2_std)[-1],
    r_squared = summary(m2)$r.squared,
    adj_r_squared = summary(m2)$adj.r.squared
  )

cat("\nStandardized Coefficients:\n")
print(m2_results %>% select(term, estimate, std_beta, p.value), row.names = FALSE)

cat("\nModel Fit:\n")
cat("  R² =", round(summary(m2)$r.squared, 4), "\n")
cat("  Adj. R² =", round(summary(m2)$adj.r.squared, 4), "\n")

# ------------------------------------------------------------------------------
# MODEL 3: Interaction Models
# ------------------------------------------------------------------------------

cat("\n\n===== MODEL 3: INTERACTION MODELS =====\n\n")

# SES × Harsh Parenting interaction
m3a <- lm(intercept ~ ses_disadvantage * harsh_early + sex + cognitive_ability,
         data = twostage_data)

cat("SES × Harsh Parenting (Intercept):\n")
cat("  Interaction β =", round(coef(m3a)["ses_disadvantage:harsh_early"], 4), "\n")
cat("  p =", format.pval(summary(m3a)$coef["ses_disadvantage:harsh_early", "Pr(>|t|)"],
                        digits = 3), "\n\n")

# Sex × Harsh Parenting interaction
m3b <- lm(slope ~ sex * harsh_early + ses_disadvantage + cognitive_ability,
         data = twostage_data)

cat("Sex × Harsh Parenting (Slope):\n")
cat("  Interaction β =", round(coef(m3b)["sex:harsh_early"], 4), "\n")
cat("  p =", format.pval(summary(m3b)$coef["sex:harsh_early", "Pr(>|t|)"],
                        digits = 3), "\n\n")

# ------------------------------------------------------------------------------
# Visualizations
# ------------------------------------------------------------------------------

cat("Creating visualizations...\n")

# Plot 1: Coefficient plot for intercept model
pdf(file.path(results_path, "plots", "regression", "intercept_coefficients.pdf"),
    width = 10, height = 6)

m1_results %>%
  filter(term != "(Intercept)") %>%
  mutate(sig = ifelse(p.value < 0.05, "p < .05", "ns"),
         term = str_remove(term, "scale\\(|\\)")) %>%
  ggplot(aes(x = reorder(term, std_beta), y = std_beta, fill = sig)) +
  geom_col() +
  geom_errorbar(aes(ymin = std_beta - 1.96 * std.error / sd(twostage_data$intercept, na.rm = TRUE),
                   ymax = std_beta + 1.96 * std.error / sd(twostage_data$intercept, na.rm = TRUE)),
               width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Predictors of Initial Self-Control (Intercept)",
    subtitle = paste0("R² = ", round(summary(m1)$r.squared, 3)),
    x = "Predictor",
    y = "Standardized Coefficient (β)",
    fill = "Significance"
  ) +
  scale_fill_manual(values = c("p < .05" = "steelblue", "ns" = "gray70"))

dev.off()

# Plot 2: Coefficient plot for slope model
pdf(file.path(results_path, "plots", "regression", "slope_coefficients.pdf"),
    width = 10, height = 6)

m2_results %>%
  filter(term != "(Intercept)") %>%
  mutate(sig = ifelse(p.value < 0.05, "p < .05", "ns"),
         term = str_remove(term, "scale\\(|\\)")) %>%
  ggplot(aes(x = reorder(term, std_beta), y = std_beta, fill = sig)) +
  geom_col() +
  geom_errorbar(aes(ymin = std_beta - 1.96 * std.error / sd(twostage_data$slope, na.rm = TRUE),
                   ymax = std_beta + 1.96 * std.error / sd(twostage_data$slope, na.rm = TRUE)),
               width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Predictors of Self-Control Change (Slope)",
    subtitle = paste0("R² = ", round(summary(m2)$r.squared, 3)),
    x = "Predictor",
    y = "Standardized Coefficient (β)",
    fill = "Significance"
  ) +
  scale_fill_manual(values = c("p < .05" = "coral", "ns" = "gray70"))

dev.off()

# Plot 3: Compare intercept vs. slope predictors
pdf(file.path(results_path, "plots", "regression", "intercept_vs_slope.pdf"),
    width = 10, height = 8)

# Combine results
common_predictors <- c("sex", "ethnicity_white", "ses_disadvantage",
                      "cognitive_ability", "harsh_early")

comparison <- data.frame(
  predictor = common_predictors,
  intercept_beta = sapply(common_predictors, function(p) {
    idx <- which(m1_results$term == p)
    if (length(idx) > 0) m1_results$std_beta[idx] else NA
  }),
  slope_beta = sapply(common_predictors, function(p) {
    idx <- which(m2_results$term == p)
    if (length(idx) > 0) m2_results$std_beta[idx] else NA
  })
) %>%
  pivot_longer(cols = c(intercept_beta, slope_beta),
              names_to = "outcome", values_to = "std_beta") %>%
  mutate(outcome = str_remove(outcome, "_beta"))

comparison %>%
  ggplot(aes(x = predictor, y = std_beta, fill = outcome)) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Comparison: Intercept vs. Slope Predictors",
    subtitle = "Do different factors predict initial levels vs. change?",
    x = "Predictor",
    y = "Standardized Coefficient (β)",
    fill = "Outcome"
  ) +
  scale_fill_manual(values = c("intercept" = "steelblue", "slope" = "coral"))

dev.off()

cat("  ✓ Saved 3 plots\n")

# ------------------------------------------------------------------------------
# Save Results
# ------------------------------------------------------------------------------

save(m1, m2, m3a, m3b, m1_results, m2_results,
     file = file.path(results_path, "regression", "intercept_slope_regression.RData"))

# ------------------------------------------------------------------------------
# Summary Report
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("REGRESSION ANALYSIS COMPLETE!\n")
cat("==============================================================================\n\n")

cat("Key Findings:\n\n")

cat("INTERCEPT (Initial Self-Control):\n")
cat("  R² =", round(summary(m1)$r.squared, 3), "\n")
sig_predictors_i <- m1_results %>% filter(p.value < 0.05, term != "(Intercept)")
if (nrow(sig_predictors_i) > 0) {
  cat("  Significant predictors:", nrow(sig_predictors_i), "\n")
  for (i in 1:nrow(sig_predictors_i)) {
    cat("    -", sig_predictors_i$term[i], ": β =",
        round(sig_predictors_i$std_beta[i], 3), "\n")
  }
} else {
  cat("  No significant predictors at p < .05\n")
}

cat("\nSLOPE (Rate of Change):\n")
cat("  R² =", round(summary(m2)$r.squared, 3), "\n")
sig_predictors_s <- m2_results %>% filter(p.value < 0.05, term != "(Intercept)")
if (nrow(sig_predictors_s) > 0) {
  cat("  Significant predictors:", nrow(sig_predictors_s), "\n")
  for (i in 1:nrow(sig_predictors_s)) {
    cat("    -", sig_predictors_s$term[i], ": β =",
        round(sig_predictors_s$std_beta[i], 3), "\n")
  }
} else {
  cat("  No significant predictors at p < .05\n")
}

cat("\nOutput Files:\n")
cat("  - results/regression/intercept_slope_regression.RData\n")
cat("  - results/plots/regression/intercept_coefficients.pdf\n")
cat("  - results/plots/regression/slope_coefficients.pdf\n")
cat("  - results/plots/regression/intercept_vs_slope.pdf\n\n")

cat("Compare with SEMTree results:\n")
cat("  - Regression finds MAIN EFFECTS (uniform associations)\n")
cat("  - SEMTree finds SUBGROUPS (interactions/heterogeneity)\n")
cat("  - Both provide complementary insights!\n\n")

cat("==============================================================================\n\n")
