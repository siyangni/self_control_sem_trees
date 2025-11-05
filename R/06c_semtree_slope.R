# ==============================================================================
# SEMTree Analysis: Slope (Rate of Change in Self-Control)
# ==============================================================================
#
# Purpose: Two-stage SEMTree to identify covariates predicting CHANGE
#          in self-control over time (slope from LGBM)
#
# Research Question:
#   What characteristics predict individual differences in the RATE OF CHANGE
#   in self-control from ages 3 to 17?
#
# Strategy:
#   - Outcome: Slope factor score (continuous)
#   - Predictors: Time-varying parenting + baseline covariates
#   - Estimator: ML (continuous outcome)
#   - Method: Two-stage approach (factor scores from 06a)
#
# Key Hypothesis:
#   Parenting practices may not predict INITIAL levels (intercept) but may
#   predict CHANGE (slope). This is a critical developmental question!
#
# Input:
#   - data/processed/mcs_twostage_dataset.RData (from 06a)
#
# Output:
#   - results/semtrees/slope_tree.RData
#   - results/plots/semtrees/slope_tree.pdf
#   - results/reports/slope_tree_summary.md
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, semtree, here)

cat("\n")
cat("==============================================================================\n")
cat("SEMTREE ANALYSIS: SLOPE (RATE OF CHANGE)\n")
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
# STEP 2: Define Simple Regression Model (Outcome = Slope)
# ------------------------------------------------------------------------------

cat("\nStep 2: Defining regression model for slope...\n")

# Simple regression: slope predicted by nothing (null model)
# SEMTree will test which covariates split the sample
slope_model <- '
  # Regression model
  slope ~ 1
'

cat("  ✓ Model: Slope regressed on constant\n")
cat("  ✓ SEMTree will test: Which covariates predict slope?\n")

# Fit null model to check
fit_null <- sem(slope_model, data = twostage_data, estimator = "ML")
cat("\nNull Model Summary:\n")
cat("  Mean slope:", round(coef(fit_null)["slope~1"], 3), "\n")
cat("  Variance:", round(lavInspect(fit_null, "est")$theta["slope", "slope"], 3), "\n")

# Check slope distribution
cat("\nSlope Distribution:\n")
cat("  Negative (declining SC):", sum(twostage_data$slope < 0, na.rm = TRUE),
    paste0("(", round(100 * sum(twostage_data$slope < 0, na.rm = TRUE) /
                     sum(!is.na(twostage_data$slope)), 1), "%)"), "\n")
cat("  Positive (increasing SC):", sum(twostage_data$slope > 0, na.rm = TRUE),
    paste0("(", round(100 * sum(twostage_data$slope > 0, na.rm = TRUE) /
                     sum(!is.na(twostage_data$slope)), 1), "%)"), "\n")

# ------------------------------------------------------------------------------
# STEP 3: Select Covariates (Predictors for CHANGE)
# ------------------------------------------------------------------------------

cat("\nStep 3: Selecting covariates as potential splitting variables...\n")

# For SLOPE: Include time-varying parenting (hypothesized to affect CHANGE)
# Plus baseline characteristics that may moderate developmental trajectories
slope_covariates <- c(
  # Demographics (moderators of change)
  "sex",                    # Gender differences in development?
  "ethnicity_white",        # Ethnic differences in trajectories?

  # Socioeconomic (may affect resources for development)
  "ses_disadvantage",       # Does poverty affect trajectory?

  # Child characteristics (stability vs. change)
  "cognitive_ability",      # Do smarter kids change more/less?

  # TIME-VARYING PARENTING (key predictors of CHANGE!)
  "harsh_early",            # Early harsh parenting (ages 3-7)
  "pos_early",              # Early positive parenting (ages 5-7)
  "mon_avg"                 # Adolescent monitoring (ages 14-17)
)

# Check availability
available_covs <- slope_covariates[slope_covariates %in% names(twostage_data)]
cat("  ✓ Available covariates:", length(available_covs), "/", length(slope_covariates), "\n")
cat("  ✓ Covariates:", paste(available_covs, collapse = ", "), "\n")

# Prepare covariate data frame
covariate_data <- twostage_data %>%
  select(all_of(c("mcsid", available_covs))) %>%
  # Convert factors to numeric for semtree
  mutate(across(where(is.factor), ~as.numeric(as.character(.))))

# Check for complete cases
complete_data <- twostage_data %>%
  filter(complete.cases(select(., all_of(c("slope", available_covs)))))

cat("\n  Sample size checks:\n")
cat("    Total:", nrow(twostage_data), "\n")
cat("    Complete cases (slope + covariates):", nrow(complete_data), "\n")
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
# STEP 5: Test Parenting Variables Specifically
# ------------------------------------------------------------------------------

cat("\nStep 5: Testing parenting effects (key hypothesis!)...\n\n")

# Focus on parenting variables
parenting_vars <- c("harsh_early", "pos_early", "mon_avg")
parenting_vars <- parenting_vars[parenting_vars %in% available_covs]

parenting_tests <- data.frame(
  covariate = character(),
  chi_sq = numeric(),
  df = numeric(),
  p_value = numeric(),
  effect_size = numeric(),
  mean_low = numeric(),
  mean_high = numeric(),
  stringsAsFactors = FALSE
)

for (cov in parenting_vars) {
  cat("Testing", cov, "...\n")

  # Create binary split at median
  median_val <- median(complete_data[[cov]], na.rm = TRUE)
  complete_data$split_var <- ifelse(complete_data[[cov]] <= median_val, 0, 1)

  # Fit models
  fit_constrained <- sem(slope_model, data = complete_data, estimator = "ML")

  # Multi-group model
  fit_split <- sem(slope_model, data = complete_data, estimator = "ML",
                   group = "split_var")

  # Likelihood ratio test
  lr_test <- anova(fit_constrained, fit_split)

  # Effect size (mean difference)
  mean_low <- mean(complete_data$slope[complete_data$split_var == 0], na.rm = TRUE)
  mean_high <- mean(complete_data$slope[complete_data$split_var == 1], na.rm = TRUE)
  sd_pooled <- sd(complete_data$slope, na.rm = TRUE)
  cohens_d <- (mean_high - mean_low) / sd_pooled

  parenting_tests <- rbind(parenting_tests, data.frame(
    covariate = cov,
    chi_sq = lr_test$`Chisq diff`[2],
    df = lr_test$`Df diff`[2],
    p_value = lr_test$`Pr(>Chisq)`[2],
    effect_size = cohens_d,
    mean_low = mean_low,
    mean_high = mean_high
  ))

  cat("  χ²(", lr_test$`Df diff`[2], ") =", round(lr_test$`Chisq diff`[2], 3),
      ", p =", round(lr_test$`Pr(>Chisq)`[2], 4),
      ", d =", round(cohens_d, 3), "\n")
  cat("  Low", cov, "slope:", round(mean_low, 3), "\n")
  cat("  High", cov, "slope:", round(mean_high, 3), "\n\n")
}

# ------------------------------------------------------------------------------
# STEP 6: Test All Covariates
# ------------------------------------------------------------------------------

cat("Step 6: Testing all covariates individually...\n\n")

all_tests <- data.frame(
  covariate = character(),
  chi_sq = numeric(),
  df = numeric(),
  p_value = numeric(),
  effect_size = numeric(),
  stringsAsFactors = FALSE
)

for (cov in available_covs) {
  # Skip if already tested
  if (cov %in% parenting_tests$covariate) {
    all_tests <- rbind(all_tests, parenting_tests %>%
                      filter(covariate == cov) %>%
                      select(covariate, chi_sq, df, p_value, effect_size))
    next
  }

  # Create binary split at median
  median_val <- median(complete_data[[cov]], na.rm = TRUE)
  complete_data$split_var <- ifelse(complete_data[[cov]] <= median_val, 0, 1)

  # Fit models
  fit_constrained <- sem(slope_model, data = complete_data, estimator = "ML")
  fit_split <- sem(slope_model, data = complete_data, estimator = "ML",
                   group = "split_var")

  # Likelihood ratio test
  lr_test <- anova(fit_constrained, fit_split)

  # Effect size
  mean_low <- mean(complete_data$slope[complete_data$split_var == 0], na.rm = TRUE)
  mean_high <- mean(complete_data$slope[complete_data$split_var == 1], na.rm = TRUE)
  sd_pooled <- sd(complete_data$slope, na.rm = TRUE)
  cohens_d <- (mean_high - mean_low) / sd_pooled

  all_tests <- rbind(all_tests, data.frame(
    covariate = cov,
    chi_sq = lr_test$`Chisq diff`[2],
    df = lr_test$`Df diff`[2],
    p_value = lr_test$`Pr(>Chisq)`[2],
    effect_size = cohens_d
  ))
}

# Sort by p-value
all_tests <- all_tests %>%
  arrange(p_value) %>%
  mutate(
    p_adj = p.adjust(p_value, method = "holm"),
    is_parenting = covariate %in% parenting_vars
  )

cat("\nRanked Covariates (by p-value):\n")
print(all_tests, row.names = FALSE)

# ------------------------------------------------------------------------------
# STEP 7: Visualize Results
# ------------------------------------------------------------------------------

cat("\nStep 7: Creating visualizations...\n")

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
  pdf(file.path(results_path, "plots", "semtrees", "slope_tree.pdf"),
      width = 12, height = 8)
  plot(best_tree, main = "SEMTree: Slope (Rate of Change)")
  dev.off()
  cat("  ✓ Saved tree plot\n")
} else {
  cat("  ✗ No tree to plot (no splits found at any alpha level)\n")
}

# Plot 2: Parenting effects specifically
pdf(file.path(results_path, "plots", "semtrees", "slope_parenting_effects.pdf"),
    width = 10, height = 6)

if (nrow(parenting_tests) > 0) {
  parenting_tests %>%
    mutate(sig = ifelse(p_value < 0.05, "p < .05", "ns")) %>%
    ggplot(aes(x = reorder(covariate, -effect_size), y = effect_size, fill = sig)) +
    geom_col() +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_hline(yintercept = c(-0.2, 0.2), linetype = "dotted", color = "gray50") +
    coord_flip() +
    theme_minimal() +
    labs(
      title = "Parenting Effects on Slope (Rate of Change)",
      subtitle = "Does parenting predict self-control development?",
      x = "Parenting Variable",
      y = "Effect Size (Cohen's d)",
      fill = "Significance",
      caption = "Dashed line = 0; Dotted lines = small effect (|d| = 0.2)"
    ) +
    scale_fill_manual(values = c("p < .05" = "darkgreen", "ns" = "gray70"))
} else {
  plot.new()
  text(0.5, 0.5, "No parenting variables available", cex = 1.5)
}

dev.off()

# Plot 3: All covariate effects
pdf(file.path(results_path, "plots", "semtrees", "slope_all_effects.pdf"),
    width = 10, height = 8)

all_tests %>%
  mutate(sig = ifelse(p_adj < 0.05, "p < .05", "ns")) %>%
  ggplot(aes(x = reorder(covariate, -effect_size), y = effect_size,
             fill = sig, alpha = is_parenting)) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dotted", color = "gray50") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "All Covariate Effects on Slope (Rate of Change)",
    subtitle = "What predicts self-control development from ages 3-17?",
    x = "Covariate",
    y = "Effect Size (Cohen's d)",
    fill = "Significance",
    caption = "Darker bars = parenting variables; Dotted lines = small effect (|d| = 0.2)"
  ) +
  scale_fill_manual(values = c("p < .05" = "steelblue", "ns" = "gray70")) +
  scale_alpha_manual(values = c("TRUE" = 1.0, "FALSE" = 0.5), guide = "none")

dev.off()

cat("  ✓ Saved 3 visualization PDFs\n")

# ------------------------------------------------------------------------------
# STEP 8: Save Results
# ------------------------------------------------------------------------------

cat("\nStep 8: Saving results...\n")

# Save all trees and tests
save(trees, all_tests, parenting_tests, complete_data,
     file = file.path(results_path, "semtrees", "slope_tree.RData"))
cat("  ✓ Saved to results/semtrees/slope_tree.RData\n")

# ------------------------------------------------------------------------------
# STEP 9: Generate Summary Report
# ------------------------------------------------------------------------------

cat("\nStep 9: Generating summary report...\n")

report <- c(
  "# SEMTree Analysis: Slope (Rate of Change)",
  "",
  paste("**Date:**", Sys.Date()),
  paste("**Sample Size:**", nrow(complete_data)),
  "",
  "## Research Question",
  "",
  "What characteristics predict individual differences in the rate of change in self-control from ages 3 to 17?",
  "",
  "**Key Hypothesis:** Parenting practices may predict CHANGE in self-control even if they don't predict initial levels.",
  "",
  "## Method",
  "",
  "- **Approach:** Two-stage SEMTree",
  "- **Outcome:** Slope factor score (continuous)",
  paste("- **Predictors:**", length(available_covs), "covariates (including time-varying parenting)"),
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
           "### Parenting Effects (Key Predictors)",
           "")

if (nrow(parenting_tests) > 0) {
  for (i in 1:nrow(parenting_tests)) {
    report <- c(report,
               paste0("**", parenting_tests$covariate[i], ":**"),
               paste0("  - Effect size (d): ", round(parenting_tests$effect_size[i], 3)),
               paste0("  - p-value: ", format.pval(parenting_tests$p_value[i], digits = 3)),
               paste0("  - Low parenting → slope = ", round(parenting_tests$mean_low[i], 3)),
               paste0("  - High parenting → slope = ", round(parenting_tests$mean_high[i], 3)),
               "")
  }
} else {
  report <- c(report, "No parenting variables available in dataset.", "")
}

report <- c(report,
           "### All Covariate Rankings",
           "",
           "Top 5 covariates by effect size:",
           "")

for (i in 1:min(5, nrow(all_tests))) {
  report <- c(report,
             paste0(i, ". **", all_tests$covariate[i], "**"),
             paste0("   - Effect size (d): ", round(all_tests$effect_size[i], 3)),
             paste0("   - p-value: ", format.pval(all_tests$p_value[i], digits = 3)),
             paste0("   - Adjusted p: ", format.pval(all_tests$p_adj[i], digits = 3)),
             "")
}

report <- c(report,
           "## Interpretation",
           "",
           ifelse(is.null(best_tree),
                 "**No significant subgroups found.** This suggests that developmental trajectories are relatively homogeneous, or effects are too small to detect. However, individual covariate tests may reveal small uniform effects.",
                 "**Significant subgroups identified!** See tree plot for details."),
           "",
           "### Clinical/Theoretical Implications",
           "",
           "- Compare intercept vs. slope trees: Different predictors of START vs. CHANGE?",
           "- Parenting effects: Do they matter more for development than initial levels?",
           "- Consider regression analysis for small uniform effects",
           "",
           "## Next Steps",
           "",
           "- Compare intercept vs. slope predictors (different processes?)",
           "- Run regression analysis (07a) to detect small uniform effects",
           "- Try time-specific trees (06d) for age-specific patterns",
           "",
           "## Files Generated",
           "",
           "- `results/semtrees/slope_tree.RData` - All results",
           "- `results/plots/semtrees/slope_tree.pdf` - Tree plot (if splits found)",
           "- `results/plots/semtrees/slope_parenting_effects.pdf` - Parenting effects",
           "- `results/plots/semtrees/slope_all_effects.pdf` - All covariates",
           "- `results/reports/slope_tree_summary.md` - This report",
           ""
)

writeLines(report, file.path(results_path, "reports", "slope_tree_summary.md"))
cat("  ✓ Saved to results/reports/slope_tree_summary.md\n")

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("SLOPE SEMTREE ANALYSIS COMPLETE!\n")
cat("==============================================================================\n\n")

cat("Key Findings:\n")
if (!is.null(best_tree)) {
  cat("  ✓ SPLITS FOUND!\n")
  cat("    - Significant subgroups exist for developmental trajectories\n")
} else {
  cat("  ✗ No splits found at any alpha level\n")
  cat("    - Developmental trajectories appear homogeneous\n")
}

cat("\nParenting Effects:\n")
if (nrow(parenting_tests) > 0) {
  for (i in 1:nrow(parenting_tests)) {
    sig_marker <- ifelse(parenting_tests$p_value[i] < 0.05, "***", "   ")
    cat("  ", sig_marker, " ", parenting_tests$covariate[i],
        ": d = ", round(parenting_tests$effect_size[i], 3),
        ", p = ", format.pval(parenting_tests$p_value[i], digits = 2), "\n", sep = "")
  }
} else {
  cat("  (No parenting variables available)\n")
}

cat("\nTop 3 Covariates Overall:\n")
for (i in 1:min(3, nrow(all_tests))) {
  cat("  ", i, ". ", all_tests$covariate[i],
      " (d = ", round(all_tests$effect_size[i], 3),
      ", p = ", format.pval(all_tests$p_value[i], digits = 2), ")\n", sep = "")
}

cat("\nOutput Files:\n")
cat("  - results/semtrees/slope_tree.RData\n")
cat("  - results/plots/semtrees/slope_tree.pdf\n")
cat("  - results/plots/semtrees/slope_parenting_effects.pdf\n")
cat("  - results/plots/semtrees/slope_all_effects.pdf\n")
cat("  - results/reports/slope_tree_summary.md\n\n")

cat("Next: Compare intercept vs. slope results!\n")
cat("      - Different predictors of initial levels vs. change?\n")
cat("      - Run 06d_semtree_timespecific.R for age-specific analysis\n\n")

cat("==============================================================================\n\n")
