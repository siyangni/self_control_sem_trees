# ==============================================================================
# SEMTree Analysis: Intercept (Initial Self-Control)
# ==============================================================================
#
# Purpose: Two-stage SEMTree to identify covariates predicting INITIAL
#          self-control levels (intercept from LGBM)
#
# Research Question:
#   What baseline characteristics predict individual differences in
#   self-control at age 3?
#
# Strategy:
#   - Outcome: Intercept factor score (continuous)
#   - Predictors: Baseline covariates only (SES, cognition, sex, etc.)
#   - Estimator: ML (continuous outcome - more power than WLSMV)
#   - Method: Two-stage approach (factor scores from 06a)
#
# Benefits vs. Full LGBM SEMTree:
#   1. Simpler model = more power
#   2. Faster computation
#   3. Clear interpretation (what predicts START point?)
#   4. Can use ML estimator (continuous outcome)
#
# Input:
#   - data/processed/mcs_twostage_dataset.RData (from 06a)
#
# Output:
#   - results/semtrees/intercept_tree.RData
#   - results/plots/semtrees/intercept_tree.pdf
#   - results/reports/intercept_tree_summary.md
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, semtree, here)

cat("\n")
cat("==============================================================================\n")
cat("SEMTREE ANALYSIS: INTERCEPT (INITIAL SELF-CONTROL)\n")
cat("==============================================================================\n\n")

processed_path <- here("data", "processed")
results_path <- here("results")

# Create output directories
dir.create(file.path(results_path, "semtrees"), showWarnings = FALSE)
dir.create(file.path(results_path, "plots", "semtrees"),
           showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(results_path, "reports"), showWarnings = FALSE)

# ------------------------------------------------------------------------------
# STEP 1: Load Two-Stage Dataset
# ------------------------------------------------------------------------------

cat("Step 1: Loading two-stage dataset...\n")

if (!file.exists(file.path(processed_path, "mcs_twostage_dataset.RData"))) {
  stop("ERROR: Two-stage dataset not found. Please run R/06a_semtree_factor_scores.R first.")
}

load(file.path(processed_path, "mcs_twostage_dataset.RData"))
cat("  ✓ Loaded", nrow(twostage_data), "participants\n")

# ------------------------------------------------------------------------------
# STEP 2: Define Simple Regression Model (Outcome = Intercept)
# ------------------------------------------------------------------------------

cat("\nStep 2: Defining regression model for intercept...\n")

# Simple regression: intercept predicted by nothing (null model)
# SEMTree will test which covariates split the sample
intercept_model <- '
  # Regression model
  intercept ~ 1
'

cat("  ✓ Model: Intercept regressed on constant\n")
cat("  ✓ SEMTree will test: Which covariates predict intercept?\n")

# Fit null model to check
fit_null <- sem(intercept_model, data = twostage_data, estimator = "ML")
cat("\nNull Model Summary:\n")
cat("  Mean intercept:", round(coef(fit_null)["intercept~1"], 3), "\n")
cat("  Variance:", round(lavInspect(fit_null, "est")$theta["intercept", "intercept"], 3), "\n")

# ------------------------------------------------------------------------------
# STEP 3: Select Baseline Covariates (Predictors)
# ------------------------------------------------------------------------------

cat("\nStep 3: Selecting baseline covariates as potential splitting variables...\n")

# Only baseline covariates (no time-varying parenting)
# These are measured BEFORE or AT age 3
baseline_covariates <- c(
  # Demographics
  "sex",                    # Male/Female
  "ethnicity_white",        # White vs. non-white

  # Socioeconomic
  "ses_disadvantage",       # Low SES indicator

  # Child characteristics
  "cognitive_ability",      # BAS score at age 3
  "low_birth_weight",       # <2500g
  "premature",              # <37 weeks

  # Early parenting (ages 3-7 average)
  "harsh_early"             # Harsh discipline composite
)

# Check availability
available_covs <- baseline_covariates[baseline_covariates %in% names(twostage_data)]
cat("  ✓ Available covariates:", length(available_covs), "/", length(baseline_covariates), "\n")
cat("  ✓ Covariates:", paste(available_covs, collapse = ", "), "\n")

# Prepare covariate data frame
covariate_data <- twostage_data %>%
  select(all_of(c("mcsid", available_covs))) %>%
  # Convert factors to numeric for semtree
  mutate(across(where(is.factor), ~as.numeric(as.character(.))))

# Check for complete cases
complete_data <- twostage_data %>%
  filter(complete.cases(select(., all_of(c("intercept", available_covs)))))

cat("\n  Sample size checks:\n")
cat("    Total:", nrow(twostage_data), "\n")
cat("    Complete cases (intercept + covariates):", nrow(complete_data), "\n")
cat("    % retained:", round(100 * nrow(complete_data) / nrow(twostage_data), 1), "%\n")

# ------------------------------------------------------------------------------
# STEP 4: Run SEMTree with Progressive Alpha Levels
# ------------------------------------------------------------------------------

cat("\nStep 4: Running SEMTree with multiple alpha levels...\n\n")

# Test multiple significance thresholds
alpha_levels <- c(0.05, 0.10, 0.15, 0.20)
trees <- list()

for (alpha in alpha_levels) {
  cat("Testing alpha =", alpha, "...\n")

  # Set control parameters
  ctrl <- semtree_control(
    method = "fair",
    alpha = alpha,
    min.N = 100,            # Minimum node size
    max.depth = 5,          # Maximum tree depth
    min.bucket = 50,        # Minimum terminal node size
    bonferroni = TRUE,      # Bonferroni correction
    exclude.heywood = TRUE, # Exclude inadmissible solutions
    use.all = FALSE,        # Fair splits only
    verbose = FALSE
  )

  # Run SEMTree
  tree <- tryCatch({
    semtree(
      model = fit_null,
      data = complete_data,
      control = ctrl,
      predictors = covariate_data[match(complete_data$mcsid, covariate_data$mcsid), ]
    )
  }, error = function(e) {
    cat("  ERROR:", e$message, "\n")
    return(NULL)
  })

  if (!is.null(tree)) {
    trees[[paste0("alpha_", alpha)]] <- tree

    # Check if splits found
    if (length(tree$rule) > 0) {
      cat("  ✓ SPLITS FOUND!\n")
      cat("    First split:", tree$rule[1], "\n")
      cat("    Number of terminal nodes:", length(tree$leafs), "\n")
    } else {
      cat("  ✗ No splits found\n")
    }
  }

  cat("\n")
}

# ------------------------------------------------------------------------------
# STEP 5: Test Specific Covariates Individually
# ------------------------------------------------------------------------------

cat("\nStep 5: Testing individual covariate effects (sensitivity analysis)...\n\n")

# If no splits found, test each covariate individually
individual_tests <- data.frame(
  covariate = character(),
  chi_sq = numeric(),
  df = numeric(),
  p_value = numeric(),
  effect_size = numeric(),
  stringsAsFactors = FALSE
)

for (cov in available_covs) {
  cat("Testing", cov, "...\n")

  # Create binary split at median
  median_val <- median(complete_data[[cov]], na.rm = TRUE)
  complete_data$split_var <- ifelse(complete_data[[cov]] <= median_val, 0, 1)

  # Fit models
  fit_constrained <- sem(intercept_model, data = complete_data, estimator = "ML")

  # Multi-group model
  fit_split <- sem(intercept_model, data = complete_data, estimator = "ML",
                   group = "split_var")

  # Likelihood ratio test
  lr_test <- anova(fit_constrained, fit_split)

  # Effect size (mean difference)
  mean_low <- mean(complete_data$intercept[complete_data$split_var == 0], na.rm = TRUE)
  mean_high <- mean(complete_data$intercept[complete_data$split_var == 1], na.rm = TRUE)
  sd_pooled <- sd(complete_data$intercept, na.rm = TRUE)
  cohens_d <- (mean_high - mean_low) / sd_pooled

  individual_tests <- rbind(individual_tests, data.frame(
    covariate = cov,
    chi_sq = lr_test$`Chisq diff`[2],
    df = lr_test$`Df diff`[2],
    p_value = lr_test$`Pr(>Chisq)`[2],
    effect_size = cohens_d
  ))

  cat("  χ²(", lr_test$`Df diff`[2], ") =", round(lr_test$`Chisq diff`[2], 3),
      ", p =", round(lr_test$`Pr(>Chisq)`[2], 4),
      ", d =", round(cohens_d, 3), "\n")
}

# Sort by p-value
individual_tests <- individual_tests %>%
  arrange(p_value) %>%
  mutate(p_adj = p.adjust(p_value, method = "holm"))

cat("\nRanked Covariates (by p-value):\n")
print(individual_tests, row.names = FALSE)

# ------------------------------------------------------------------------------
# STEP 6: Visualize Results
# ------------------------------------------------------------------------------

cat("\nStep 6: Creating visualizations...\n")

# Plot 1: Best tree (if any splits found)
best_tree <- NULL
for (alpha in alpha_levels) {
  tree_name <- paste0("alpha_", alpha)
  if (!is.null(trees[[tree_name]]) && length(trees[[tree_name]]$rule) > 0) {
    best_tree <- trees[[tree_name]]
    cat("  Best tree found at alpha =", alpha, "\n")
    break
  }
}

if (!is.null(best_tree)) {
  pdf(file.path(results_path, "plots", "semtrees", "intercept_tree.pdf"),
      width = 12, height = 8)
  plot(best_tree, main = "SEMTree: Intercept (Initial Self-Control)")
  dev.off()
  cat("  ✓ Saved tree plot\n")
} else {
  cat("  ✗ No tree to plot (no splits found at any alpha level)\n")
}

# Plot 2: Individual covariate effects
pdf(file.path(results_path, "plots", "semtrees", "intercept_covariate_effects.pdf"),
    width = 10, height = 6)

individual_tests %>%
  mutate(sig = ifelse(p_adj < 0.05, "p < .05", "ns")) %>%
  ggplot(aes(x = reorder(covariate, -effect_size), y = effect_size, fill = sig)) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dotted", color = "gray50") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Covariate Effects on Intercept (Initial Self-Control)",
    subtitle = "Cohen's d for median split comparison",
    x = "Covariate",
    y = "Effect Size (Cohen's d)",
    fill = "Significance",
    caption = "Dashed line = 0; Dotted lines = small effect (|d| = 0.2)"
  ) +
  scale_fill_manual(values = c("p < .05" = "steelblue", "ns" = "gray70"))

dev.off()

cat("  ✓ Saved covariate effects plot\n")

# ------------------------------------------------------------------------------
# STEP 7: Save Results
# ------------------------------------------------------------------------------

cat("\nStep 7: Saving results...\n")

# Save all trees
save(trees, individual_tests, complete_data,
     file = file.path(results_path, "semtrees", "intercept_tree.RData"))
cat("  ✓ Saved to results/semtrees/intercept_tree.RData\n")

# ------------------------------------------------------------------------------
# STEP 8: Generate Summary Report
# ------------------------------------------------------------------------------

cat("\nStep 8: Generating summary report...\n")

report <- c(
  "# SEMTree Analysis: Intercept (Initial Self-Control)",
  "",
  paste("**Date:**", Sys.Date()),
  paste("**Sample Size:**", nrow(complete_data)),
  "",
  "## Research Question",
  "",
  "What baseline characteristics predict individual differences in self-control at age 3 (intercept)?",
  "",
  "## Method",
  "",
  "- **Approach:** Two-stage SEMTree",
  "- **Outcome:** Intercept factor score (continuous)",
  paste("- **Predictors:**", length(available_covs), "baseline covariates"),
  "- **Estimator:** ML (continuous outcome)",
  "- **Alpha levels tested:** 0.05, 0.10, 0.15, 0.20",
  "",
  "## Results",
  "",
  "### SEMTree Results",
  ""
)

# Add tree results
for (alpha in alpha_levels) {
  tree_name <- paste0("alpha_", alpha)
  if (!is.null(trees[[tree_name]])) {
    n_splits <- length(trees[[tree_name]]$rule)
    if (n_splits > 0) {
      report <- c(report,
                 paste("**Alpha =", alpha, ":** ✓ SPLITS FOUND"),
                 paste("  - Number of splits:", n_splits),
                 paste("  - First split:", trees[[tree_name]]$rule[1]),
                 "")
    } else {
      report <- c(report,
                 paste("**Alpha =", alpha, ":** No splits found"),
                 "")
    }
  }
}

report <- c(report,
           "### Individual Covariate Tests",
           "",
           "Ranking of covariates by effect size:",
           "")

# Add table
for (i in 1:nrow(individual_tests)) {
  report <- c(report,
             paste0(i, ". **", individual_tests$covariate[i], "**"),
             paste0("   - Effect size (d): ", round(individual_tests$effect_size[i], 3)),
             paste0("   - p-value: ", format.pval(individual_tests$p_value[i], digits = 3)),
             paste0("   - Adjusted p: ", format.pval(individual_tests$p_adj[i], digits = 3)),
             "")
}

report <- c(report,
           "## Interpretation",
           "",
           ifelse(is.null(best_tree),
                 "**No significant subgroups found.** This suggests that initial self-control levels (intercept) are relatively homogeneous across the tested baseline covariates, or effects are too small to detect with current sample size and method.",
                 "**Significant subgroups identified!** See tree plot for details."),
           "",
           "## Next Steps",
           "",
           "- Examine slope tree (06c) - different predictors may matter for CHANGE",
           "- Compare with regression analysis (07a) - may detect small uniform effects",
           "- Consider time-specific trees (06d) - age-specific patterns",
           "",
           "## Files Generated",
           "",
           "- `results/semtrees/intercept_tree.RData` - All results",
           "- `results/plots/semtrees/intercept_tree.pdf` - Tree plot (if splits found)",
           "- `results/plots/semtrees/intercept_covariate_effects.pdf` - Effect sizes",
           "- `results/reports/intercept_tree_summary.md` - This report",
           ""
)

writeLines(report, file.path(results_path, "reports", "intercept_tree_summary.md"))
cat("  ✓ Saved to results/reports/intercept_tree_summary.md\n")

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("INTERCEPT SEMTREE ANALYSIS COMPLETE!\n")
cat("==============================================================================\n\n")

cat("Key Findings:\n")
if (!is.null(best_tree)) {
  cat("  ✓ SPLITS FOUND at alpha =", alpha, "\n")
  cat("    - Significant subgroups exist!\n")
} else {
  cat("  ✗ No splits found at any alpha level\n")
  cat("    - Intercept appears homogeneous across covariates\n")
}

cat("\nTop 3 Covariates by Effect Size:\n")
for (i in 1:min(3, nrow(individual_tests))) {
  cat("  ", i, ". ", individual_tests$covariate[i],
      " (d = ", round(individual_tests$effect_size[i], 3),
      ", p = ", format.pval(individual_tests$p_value[i], digits = 2), ")\n", sep = "")
}

cat("\nOutput Files:\n")
cat("  - results/semtrees/intercept_tree.RData\n")
cat("  - results/plots/semtrees/intercept_tree.pdf\n")
cat("  - results/plots/semtrees/intercept_covariate_effects.pdf\n")
cat("  - results/reports/intercept_tree_summary.md\n\n")

cat("Next: Run 06c_semtree_slope.R to analyze CHANGE predictors\n\n")

cat("==============================================================================\n\n")
