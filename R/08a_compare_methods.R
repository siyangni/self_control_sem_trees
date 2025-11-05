# ==============================================================================
# Method Comparison: SEMTree vs. Regression vs. Machine Learning
# ==============================================================================
#
# Purpose: Synthesize and compare results across three complementary approaches
#
# Methods:
#   1. SEMTree - Finds subgroups (interactions/heterogeneity)
#   2. Regression - Finds main effects (uniform associations)
#   3. Machine Learning - Variable importance + prediction
#
# Research Questions:
#   - Do methods agree on important predictors?
#   - Does SEMTree find subgroups where regression finds main effects?
#   - What is the relative predictive accuracy?
#
# Input:
#   - results/semtrees/*.RData
#   - results/regression/*.RData
#   - results/machine_learning/*.RData
#
# Output:
#   - results/method_comparison/comparison_summary.RData
#   - results/reports/method_comparison_report.md
#
# ==============================================================================

library(pacman)
p_load(tidyverse, here, ggplot2, gridExtra)

cat("\n")
cat("==============================================================================\n")
cat("METHOD COMPARISON: SEMTREE VS REGRESSION VS MACHINE LEARNING\n")
cat("==============================================================================\n\n")

results_path <- here("results")

dir.create(file.path(results_path, "method_comparison"), showWarnings = FALSE)

# ------------------------------------------------------------------------------
# Load Results from All Methods
# ------------------------------------------------------------------------------

cat("Loading results...\n")

# SEMTree results
load(file.path(results_path, "semtrees", "intercept_tree.RData"))
semtree_intercept_tests <- individual_tests
rm(individual_tests, trees, complete_data)

load(file.path(results_path, "semtrees", "slope_tree.RData"))
semtree_slope_tests <- all_tests
rm(all_tests, trees, parenting_tests, complete_data)

# Regression results
load(file.path(results_path, "regression", "intercept_slope_regression.RData"))
regression_intercept <- m1_results %>%
  filter(term != "(Intercept)") %>%
  select(covariate = term, std_beta, p_value)

regression_slope <- m2_results %>%
  filter(term != "(Intercept)") %>%
  select(covariate = term, std_beta, p_value)

# ML results
load(file.path(results_path, "machine_learning", "ml_results.RData"))

cat("  ✓ Loaded SEMTree results\n")
cat("  ✓ Loaded regression results\n")
cat("  ✓ Loaded ML results\n\n")

# ------------------------------------------------------------------------------
# INTERCEPT: Cross-Method Comparison
# ------------------------------------------------------------------------------

cat("===== INTERCEPT COMPARISON =====\n\n")

# Standardize variable names
semtree_intercept_tests <- semtree_intercept_tests %>%
  rename(semtree_d = effect_size, semtree_p = p_value)

rf_imp_i <- rf_imp_i %>%
  mutate(rf_importance = importance / max(importance)) %>%  # Normalize
  select(variable, rf_importance)

regression_intercept <- regression_intercept %>%
  mutate(covariate = str_remove_all(covariate, "scale\\(|\\)")) %>%
  rename(reg_beta = std_beta, reg_p = p_value)

# Merge all results
intercept_comparison <- semtree_intercept_tests %>%
  full_join(regression_intercept, by = "covariate") %>%
  full_join(rf_imp_i, by = c("covariate" = "variable"))

# Calculate ranks
intercept_comparison <- intercept_comparison %>%
  mutate(
    semtree_rank = rank(-abs(semtree_d), na.last = "keep"),
    reg_rank = rank(-abs(reg_beta), na.last = "keep"),
    ml_rank = rank(-rf_importance, na.last = "keep")
  ) %>%
  arrange(ml_rank)

cat("Cross-Method Rankings (Intercept):\n")
print(intercept_comparison %>%
       select(covariate, semtree_rank, reg_rank, ml_rank,
              semtree_d, reg_beta, rf_importance),
     row.names = FALSE)

# Correlation between methods
cat("\nMethod Correlations (Intercept):\n")
cat("  SEMTree vs Regression:",
    round(cor(intercept_comparison$semtree_d,
             intercept_comparison$reg_beta,
             use = "complete.obs"), 3), "\n")
cat("  SEMTree vs ML:",
    round(cor(abs(intercept_comparison$semtree_d),
             intercept_comparison$rf_importance,
             use = "complete.obs"), 3), "\n")
cat("  Regression vs ML:",
    round(cor(abs(intercept_comparison$reg_beta),
             intercept_comparison$rf_importance,
             use = "complete.obs"), 3), "\n\n")

# ------------------------------------------------------------------------------
# SLOPE: Cross-Method Comparison
# ------------------------------------------------------------------------------

cat("===== SLOPE COMPARISON =====\n\n")

semtree_slope_tests <- semtree_slope_tests %>%
  rename(semtree_d = effect_size, semtree_p = p_value) %>%
  filter(!is_parenting | is.na(is_parenting)) %>%  # Remove duplicate parenting vars
  select(covariate, semtree_d, semtree_p)

rf_imp_s <- rf_imp_s %>%
  mutate(rf_importance = importance / max(importance)) %>%
  select(variable, rf_importance)

regression_slope <- regression_slope %>%
  mutate(covariate = str_remove_all(covariate, "scale\\(|\\)")) %>%
  rename(reg_beta = std_beta, reg_p = p_value)

# Merge
slope_comparison <- semtree_slope_tests %>%
  full_join(regression_slope, by = "covariate") %>%
  full_join(rf_imp_s, by = c("covariate" = "variable"))

slope_comparison <- slope_comparison %>%
  mutate(
    semtree_rank = rank(-abs(semtree_d), na.last = "keep"),
    reg_rank = rank(-abs(reg_beta), na.last = "keep"),
    ml_rank = rank(-rf_importance, na.last = "keep")
  ) %>%
  arrange(ml_rank)

cat("Cross-Method Rankings (Slope):\n")
print(slope_comparison %>%
       select(covariate, semtree_rank, reg_rank, ml_rank,
              semtree_d, reg_beta, rf_importance),
     row.names = FALSE)

cat("\nMethod Correlations (Slope):\n")
cat("  SEMTree vs Regression:",
    round(cor(slope_comparison$semtree_d,
             slope_comparison$reg_beta,
             use = "complete.obs"), 3), "\n")
cat("  SEMTree vs ML:",
    round(cor(abs(slope_comparison$semtree_d),
             slope_comparison$rf_importance,
             use = "complete.obs"), 3), "\n")
cat("  Regression vs ML:",
    round(cor(abs(slope_comparison$reg_beta),
             slope_comparison$rf_importance,
             use = "complete.obs"), 3), "\n\n")

# ------------------------------------------------------------------------------
# Visualizations
# ------------------------------------------------------------------------------

cat("Creating visualizations...\n")

dir.create(file.path(results_path, "plots", "method_comparison"),
          showWarnings = FALSE, recursive = TRUE)

# Plot 1: Intercept - method comparison
pdf(file.path(results_path, "plots", "method_comparison",
             "intercept_method_comparison.pdf"),
    width = 12, height = 8)

intercept_comparison %>%
  select(covariate, semtree_d, reg_beta, rf_importance) %>%
  pivot_longer(cols = -covariate, names_to = "method", values_to = "effect") %>%
  mutate(
    method = recode(method,
                   "semtree_d" = "SEMTree (d)",
                   "reg_beta" = "Regression (β)",
                   "rf_importance" = "ML (Importance)"),
    effect_scaled = case_when(
      method == "ML (Importance)" ~ effect,  # Already 0-1
      TRUE ~ effect / max(abs(effect), na.rm = TRUE)  # Scale to -1 to 1
    )
  ) %>%
  ggplot(aes(x = reorder(covariate, effect_scaled), y = effect_scaled, fill = method)) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Intercept: Method Comparison",
    subtitle = "Do all methods agree on important predictors?",
    x = "Covariate",
    y = "Scaled Effect Size",
    fill = "Method"
  ) +
  scale_fill_manual(values = c("SEMTree (d)" = "purple",
                               "Regression (β)" = "steelblue",
                               "ML (Importance)" = "forestgreen"))

dev.off()

# Plot 2: Slope - method comparison
pdf(file.path(results_path, "plots", "method_comparison",
             "slope_method_comparison.pdf"),
    width = 12, height = 8)

slope_comparison %>%
  select(covariate, semtree_d, reg_beta, rf_importance) %>%
  pivot_longer(cols = -covariate, names_to = "method", values_to = "effect") %>%
  mutate(
    method = recode(method,
                   "semtree_d" = "SEMTree (d)",
                   "reg_beta" = "Regression (β)",
                   "rf_importance" = "ML (Importance)"),
    effect_scaled = case_when(
      method == "ML (Importance)" ~ effect,
      TRUE ~ effect / max(abs(effect), na.rm = TRUE)
    )
  ) %>%
  ggplot(aes(x = reorder(covariate, effect_scaled), y = effect_scaled, fill = method)) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Slope: Method Comparison",
    subtitle = "Do all methods agree on important predictors?",
    x = "Covariate",
    y = "Scaled Effect Size",
    fill = "Method"
  ) +
  scale_fill_manual(values = c("SEMTree (d)" = "purple",
                               "Regression (β)" = "coral",
                               "ML (Importance)" = "forestgreen"))

dev.off()

# Plot 3: Prediction performance comparison
pdf(file.path(results_path, "plots", "method_comparison",
             "prediction_performance_comparison.pdf"),
    width = 10, height = 6)

pred_performance <- data.frame(
  Method = c("Regression", "Random Forest", "XGBoost", "Regression", "Random Forest", "XGBoost"),
  Outcome = rep(c("Intercept", "Slope"), each = 3),
  R2 = c(
    summary(m1)$r.squared,  # Regression intercept (training)
    rf_test_r2_i,           # RF intercept (test)
    xgb_test_r2_i,          # XGB intercept (test)
    summary(m2)$r.squared,  # Regression slope (training)
    rf_test_r2_s,           # RF slope (test)
    xgb_test_r2_s           # XGB slope (test)
  )
)

ggplot(pred_performance, aes(x = Method, y = R2, fill = Outcome)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = round(R2, 3)), position = position_dodge(0.9),
           vjust = -0.5, size = 3) +
  theme_minimal() +
  labs(
    title = "Prediction Performance Comparison",
    subtitle = "Which method best predicts growth parameters?",
    x = "Method",
    y = "R²",
    fill = "Outcome"
  ) +
  scale_fill_manual(values = c("Intercept" = "steelblue", "Slope" = "coral")) +
  ylim(0, max(pred_performance$R2) * 1.2)

dev.off()

cat("  ✓ Saved 3 plots\n")

# ------------------------------------------------------------------------------
# Generate Comparison Report
# ------------------------------------------------------------------------------

cat("\nGenerating comparison report...\n")

report <- c(
  "# Method Comparison Report",
  "",
  paste("**Date:**", Sys.Date()),
  "",
  "## Overview",
  "",
  "This report compares three complementary approaches for identifying predictors of self-control development:",
  "",
  "1. **SEMTree** - Identifies subgroups (interactions/heterogeneity)",
  "2. **Regression** - Identifies main effects (uniform associations)",
  "3. **Machine Learning** - Variable importance + prediction",
  "",
  "## Key Questions",
  "",
  "- Do methods agree on important predictors?",
  "- Does SEMTree find subgroups where regression finds main effects?",
  "- What is the relative predictive accuracy?",
  "",
  "## Intercept (Initial Self-Control)",
  "",
  "### Top 3 Predictors by Method:",
  ""
)

for (i in 1:3) {
  report <- c(report,
             paste0(i, ". ", intercept_comparison$covariate[i]),
             paste0("   - SEMTree: rank ", intercept_comparison$semtree_rank[i],
                   " (d = ", round(intercept_comparison$semtree_d[i], 3), ")"),
             paste0("   - Regression: rank ", intercept_comparison$reg_rank[i],
                   " (β = ", round(intercept_comparison$reg_beta[i], 3), ")"),
             paste0("   - ML: rank ", intercept_comparison$ml_rank[i],
                   " (importance = ", round(intercept_comparison$rf_importance[i], 3), ")"),
             "")
}

report <- c(report,
           "## Slope (Rate of Change)",
           "",
           "### Top 3 Predictors by Method:",
           "")

for (i in 1:3) {
  report <- c(report,
             paste0(i, ". ", slope_comparison$covariate[i]),
             paste0("   - SEMTree: rank ", slope_comparison$semtree_rank[i],
                   " (d = ", round(slope_comparison$semtree_d[i], 3), ")"),
             paste0("   - Regression: rank ", slope_comparison$reg_rank[i],
                   " (β = ", round(slope_comparison$reg_beta[i], 3), ")"),
             paste0("   - ML: rank ", slope_comparison$ml_rank[i],
                   " (importance = ", round(slope_comparison$rf_importance[i], 3), ")"),
             "")
}

report <- c(report,
           "## Convergence Across Methods",
           "",
           "### Intercept:",
           paste0("- SEMTree vs Regression: r = ",
                 round(cor(intercept_comparison$semtree_d,
                          intercept_comparison$reg_beta,
                          use = "complete.obs"), 3)),
           paste0("- SEMTree vs ML: r = ",
                 round(cor(abs(intercept_comparison$semtree_d),
                          intercept_comparison$rf_importance,
                          use = "complete.obs"), 3)),
           paste0("- Regression vs ML: r = ",
                 round(cor(abs(intercept_comparison$reg_beta),
                          intercept_comparison$rf_importance,
                          use = "complete.obs"), 3)),
           "",
           "### Slope:",
           paste0("- SEMTree vs Regression: r = ",
                 round(cor(slope_comparison$semtree_d,
                          slope_comparison$reg_beta,
                          use = "complete.obs"), 3)),
           paste0("- SEMTree vs ML: r = ",
                 round(cor(abs(slope_comparison$semtree_d),
                          slope_comparison$rf_importance,
                          use = "complete.obs"), 3)),
           paste0("- Regression vs ML: r = ",
                 round(cor(abs(slope_comparison$reg_beta),
                          slope_comparison$rf_importance,
                          use = "complete.obs"), 3)),
           "",
           "## Interpretation",
           "",
           "**High convergence (r > 0.7):** Methods agree on important predictors",
           "**Moderate convergence (0.4 < r < 0.7):** Some agreement, but different aspects",
           "**Low convergence (r < 0.4):** Methods capture different phenomena",
           "",
           "## Conclusions",
           "",
           "- SEMTree: Tests for subgroups/interactions",
           "- Regression: Tests for main effects",
           "- ML: Maximizes prediction",
           "",
           "Together, these methods provide complementary insights into",
           "the predictors of self-control development.",
           ""
)

writeLines(report, file.path(results_path, "reports", "method_comparison_report.md"))
cat("  ✓ Saved report\n")

# Save results
save(intercept_comparison, slope_comparison, pred_performance,
     file = file.path(results_path, "method_comparison", "comparison_summary.RData"))

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("METHOD COMPARISON COMPLETE!\n")
cat("==============================================================================\n\n")

cat("Key Findings:\n")
cat("  - Compared SEMTree, Regression, and ML across", length(unique(c(intercept_comparison$covariate, slope_comparison$covariate))), "predictors\n")
cat("  - Generated convergence metrics for each outcome\n")
cat("  - Identified complementary insights from each method\n\n")

cat("Output Files:\n")
cat("  - results/method_comparison/comparison_summary.RData\n")
cat("  - results/reports/method_comparison_report.md\n")
cat("  - results/plots/method_comparison/intercept_method_comparison.pdf\n")
cat("  - results/plots/method_comparison/slope_method_comparison.pdf\n")
cat("  - results/plots/method_comparison/prediction_performance_comparison.pdf\n\n")

cat("==============================================================================\n\n")
