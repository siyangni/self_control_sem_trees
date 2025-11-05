# ==============================================================================
# Two-Stage SEMTree: Intercept (Initial Self-Control Level)
# ==============================================================================
#
# Purpose: Use SEMTree to identify subgroups with different initial SC levels
#   - TWO-STAGE APPROACH: Extract intercept, then split on it
#   - Much simpler than splitting full LGBM (only 1 outcome vs 42 indicators)
#   - More power to detect subgroups
#   - Clearer interpretation (who starts high vs low?)
#
# Methodological Innovation:
#   Stage 1: Extract intercept factor scores from LGBM (done in script 01)
#   Stage 2: Use SEMTree to split on intercept based on covariates
#
# Advantages:
#   - Simpler model = more power
#   - Can use ML estimator (intercept is continuous)
#   - Faster computation
#   - Easier to interpret
#
# Input:  data/processed/growth_parameters_with_covariates.RData
# Output: results/models/semtree_intercept_*.RData
#         results/figures/semtree_intercept_*.pdf
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, semtree, here)

cat("\n")
cat("==============================================================================\n")
cat("TWO-STAGE SEMTREE: INTERCEPT (INITIAL LEVEL)\n")
cat("==============================================================================\n\n")

# Set paths
processed_path <- here("data", "processed")
results_path <- here("results", "models")
figures_path <- here("results", "figures")

dir.create(results_path, showWarnings = FALSE, recursive = TRUE)
dir.create(figures_path, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# STEP 1: LOAD DATA
# ------------------------------------------------------------------------------

cat("Step 1: Loading growth parameters...\n")

load(file.path(processed_path, "growth_parameters_with_covariates.RData"))
load(file.path(processed_path, "covariate_lists.RData"))

cat("  - N =", nrow(growth_params_with_cov), "participants\n")
cat("  - Outcome: Intercept (i) - initial self-control at age 3\n\n")

# ------------------------------------------------------------------------------
# STEP 2: PREPARE DATA FOR SEMTREE
# ------------------------------------------------------------------------------

cat("Step 2: Preparing data for SEMTree...\n")

# Define covariates to test (use theory-driven set for focused analysis)
covariates_to_test <- covariate_lists$theory

cat("  - Testing", length(covariates_to_test), "covariates\n")
cat("  - Covariates:", paste(covariates_to_test, collapse = ", "), "\n\n")

# Create complete case dataset
semtree_data_intercept <- growth_params_with_cov %>%
  select(mcsid, i, all_of(covariates_to_test)) %>%
  na.omit()

cat("  - Complete cases: N =", nrow(semtree_data_intercept), "\n\n")

# ------------------------------------------------------------------------------
# STEP 3: DEFINE SIMPLE MODEL FOR INTERCEPT
# ------------------------------------------------------------------------------

cat("Step 3: Defining model for intercept...\n")

# Simple model: just the intercept as outcome
# This is a "manifest variable" model - no latent variables
# Just modeling the mean and variance of intercept

intercept_model <- '
  # Mean of intercept (to be split on)
  i ~ 1

  # Variance of intercept
  i ~~ i
'

cat("  - Model: Intercept mean and variance\n")
cat("  - This is the simplest possible SEM (univariate)\n\n")

# Fit baseline model to whole sample
cat("  - Fitting baseline model to full sample...\n")

fit_baseline <- sem(intercept_model,
                    data = semtree_data_intercept,
                    estimator = "ML")  # Can use ML since intercept is continuous

cat("  ✓ Baseline model fitted\n")
cat("    Mean intercept:", round(coef(fit_baseline)["i~1"], 3), "\n")
cat("    Variance:", round(coef(fit_baseline)["i~~i"], 3), "\n\n")

# ------------------------------------------------------------------------------
# STEP 4: RUN SEMTREE (STANDARD PARAMETERS)
# ------------------------------------------------------------------------------

cat("Step 4: Running SEMTree with standard parameters...\n")
cat("  (This may take a few minutes)\n\n")

# SEMTree control - standard parameters
ctrl_standard <- semtree.control(
  method = "score",      # Can use score test (model is ML)
  alpha = 0.05,
  min.N = 100,
  max.depth = 5,
  verbose = TRUE
)

# Run SEMTree
cat("  - Building tree...\n")

tree_standard <- semtree(
  model = fit_baseline,
  data = semtree_data_intercept,
  control = ctrl_standard,
  predictors = covariates_to_test
)

cat("\n  ✓ SEMTree complete\n\n")

# Check for splits
tree_str <- capture.output(print(tree_standard))
has_splits_standard <- any(grepl("\\[2\\]", tree_str))

if (has_splits_standard) {
  cat("  🎉 SUCCESS: Splits found!\n\n")
  print(tree_standard)
} else {
  cat("  ⚠ No splits found with standard parameters\n")
  cat("  - No covariates significantly differentiate initial SC level\n\n")
}

# Save tree
save(tree_standard, file = file.path(results_path, "semtree_intercept_standard.RData"))
cat("  ✓ Saved: semtree_intercept_standard.RData\n\n")

# Plot tree
cat("  - Creating tree visualization...\n")

pdf(file.path(figures_path, "semtree_intercept_standard.pdf"), width = 12, height = 8)
tryCatch({
  plot(tree_standard, main = "SEMTree: Initial Self-Control Level (Intercept)")
}, error = function(e) {
  plot.new()
  text(0.5, 0.5, "No splits found\nSingle terminal node", cex = 2)
})
dev.off()

cat("  ✓ Saved: semtree_intercept_standard.pdf\n\n")

# ------------------------------------------------------------------------------
# STEP 5: RUN SEMTREE (RELAXED PARAMETERS)
# ------------------------------------------------------------------------------

cat("Step 5: Running SEMTree with relaxed parameters...\n")
cat("  (Sensitivity analysis)\n\n")

# SEMTree control - relaxed parameters
ctrl_relaxed <- semtree.control(
  method = "score",
  alpha = 0.10,          # More permissive
  min.N = 50,            # Smaller nodes
  max.depth = 6,
  verbose = TRUE
)

# Run SEMTree
cat("  - Building tree with relaxed parameters...\n")

tree_relaxed <- semtree(
  model = fit_baseline,
  data = semtree_data_intercept,
  control = ctrl_relaxed,
  predictors = covariates_to_test
)

cat("\n  ✓ SEMTree complete\n\n")

# Check for splits
tree_str_relaxed <- capture.output(print(tree_relaxed))
has_splits_relaxed <- any(grepl("\\[2\\]", tree_str_relaxed))

if (has_splits_relaxed) {
  cat("  🎉 SUCCESS: Splits found with relaxed parameters!\n\n")
  print(tree_relaxed)
} else {
  cat("  ⚠ No splits found even with relaxed parameters\n")
  cat("  - Robust null finding\n\n")
}

# Save tree
save(tree_relaxed, file = file.path(results_path, "semtree_intercept_relaxed.RData"))
cat("  ✓ Saved: semtree_intercept_relaxed.RData\n\n")

# Plot tree
pdf(file.path(figures_path, "semtree_intercept_relaxed.pdf"), width = 12, height = 8)
tryCatch({
  plot(tree_relaxed, main = "SEMTree: Initial SC (Relaxed Parameters)")
}, error = function(e) {
  plot.new()
  text(0.5, 0.5, "No splits found\nSingle terminal node", cex = 2)
})
dev.off()

cat("  ✓ Saved: semtree_intercept_relaxed.pdf\n\n")

# ------------------------------------------------------------------------------
# STEP 6: RUN FOREST (if splits found)
# ------------------------------------------------------------------------------

if (has_splits_standard || has_splits_relaxed) {
  cat("Step 6: Running SEMForest for variable importance...\n")
  cat("  (This will take longer - growing 100 trees)\n\n")

  # Use whichever tree found splits
  tree_for_forest <- ifelse(has_splits_standard, tree_standard, tree_relaxed)
  ctrl_for_forest <- ifelse(has_splits_standard, ctrl_standard, ctrl_relaxed)

  forest_ctrl <- semforest.control(
    num.trees = 100,
    control = ctrl_for_forest
  )

  forest_intercept <- semforest(
    model = fit_baseline,
    data = semtree_data_intercept,
    control = forest_ctrl,
    predictors = covariates_to_test
  )

  cat("\n  ✓ Forest complete\n\n")

  # Variable importance
  cat("  - Computing variable importance...\n")

  tryCatch({
    varimp_intercept <- varimp(forest_intercept)

    cat("\n  Variable Importance:\n")
    print(varimp_intercept)

    # Plot variable importance
    pdf(file.path(figures_path, "semforest_intercept_varimp.pdf"), width = 10, height = 6)
    plot(varimp_intercept, main = "Variable Importance: Initial SC Level")
    dev.off()

    # Save forest
    save(forest_intercept, varimp_intercept,
         file = file.path(results_path, "semforest_intercept.RData"))

    cat("\n  ✓ Saved forest and variable importance\n\n")

  }, error = function(e) {
    cat("\n  ⚠ Could not compute variable importance\n")
    cat("  Error:", e$message, "\n\n")

    save(forest_intercept, file = file.path(results_path, "semforest_intercept.RData"))
  })

} else {
  cat("Step 6: Skipping forest (no splits found in single tree)\n\n")
}

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("TWO-STAGE SEMTREE: INTERCEPT ANALYSIS COMPLETE\n")
cat("==============================================================================\n\n")

cat("Sample: N =", nrow(semtree_data_intercept), "with complete data\n")
cat("Outcome: Intercept (initial self-control at age 3)\n")
cat("Covariates tested:", length(covariates_to_test), "\n\n")

cat("Results:\n")
cat("  Standard parameters (α=.05, min.N=100):\n")
if (has_splits_standard) {
  cat("    ✓ SPLITS FOUND\n")
} else {
  cat("    ✗ No splits\n")
}

cat("  Relaxed parameters (α=.10, min.N=50):\n")
if (has_splits_relaxed) {
  cat("    ✓ SPLITS FOUND\n")
} else {
  cat("    ✗ No splits\n")
}
cat("\n")

if (has_splits_standard || has_splits_relaxed) {
  cat("Interpretation:\n")
  cat("  - Covariates DO differentiate initial SC levels\n")
  cat("  - Examine tree for which variables split\n")
  cat("  - Check variable importance from forest\n")
  cat("  - Compare terminal node means (subgroup differences)\n\n")
} else {
  cat("Interpretation:\n")
  cat("  - NO covariates significantly differentiate initial SC\n")
  cat("  - Null finding is consistent with:\n")
  cat("    • Homogeneous initial levels across subgroups\n")
  cat("    • Effects too small for SEMTree to detect\n")
  cat("    • Check regression results for small effects\n\n")
}

cat("Output files:\n")
cat("  📁 results/models/semtree_intercept_standard.RData\n")
cat("  📁 results/models/semtree_intercept_relaxed.RData\n")
if (exists("forest_intercept")) {
  cat("  📁 results/models/semforest_intercept.RData\n")
  cat("  📈 results/figures/semforest_intercept_varimp.pdf\n")
}
cat("  📈 results/figures/semtree_intercept_standard.pdf\n")
cat("  📈 results/figures/semtree_intercept_relaxed.pdf\n\n")

cat("Next steps:\n")
cat("  1. Run slope tree: R/enhanced_analyses/04_semtree_slope.R\n")
cat("  2. Compare intercept vs slope findings\n")
cat("  3. Compare with regression results\n")
cat("  4. Compare with full LGBM SEMTree\n\n")

cat("==============================================================================\n\n")
