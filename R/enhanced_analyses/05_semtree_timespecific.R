# ==============================================================================
# Time-Specific SEMTree: Cross-Sectional SC at Each Wave
# ==============================================================================
#
# Purpose: Use SEMTree to identify subgroups at specific time points
#   - Cross-sectional approach (not growth models)
#   - Analyze SC at ages 3, 5, 7, 11, 14, 17 separately
#   - Can include participants with missing waves (more power)
#   - Reveals age-specific moderator effects
#
# Methodological Advantages:
#   - No need to fit complex growth model first
#   - Larger N (don't require all 6 waves)
#   - Simpler interpretation (who has high/low SC at age X?)
#   - May reveal developmental stage-specific effects
#
# Research Questions:
#   - Do different covariates matter at different ages?
#   - Are there critical periods where certain factors are more important?
#   - Do subgroups emerge at certain developmental stages?
#
# Input:  data/processed/growth_parameters_with_covariates.RData
# Output: results/models/semtree_age*.RData
#         results/figures/semtree_age*.pdf
#         results/tables/timespecific_summary.csv
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, semtree, here)

cat("\n")
cat("==============================================================================\n")
cat("TIME-SPECIFIC SEMTREE: CROSS-SECTIONAL ANALYSIS AT EACH WAVE\n")
cat("==============================================================================\n\n")

# Set paths
processed_path <- here("data", "processed")
results_path <- here("results", "models")
figures_path <- here("results", "figures")
tables_path <- here("results", "tables")

dir.create(results_path, showWarnings = FALSE, recursive = TRUE)
dir.create(figures_path, showWarnings = FALSE, recursive = TRUE)
dir.create(tables_path, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# STEP 1: LOAD DATA
# ------------------------------------------------------------------------------

cat("Step 1: Loading data...\n")

load(file.path(processed_path, "growth_parameters_with_covariates.RData"))
load(file.path(processed_path, "covariate_lists.RData"))

cat("  - Full sample: N =", nrow(growth_params_with_cov), "participants\n")
cat("  - Will analyze each wave separately\n\n")

# Define covariates to test (use theory-driven set)
covariates_to_test <- covariate_lists$theory

cat("  - Testing", length(covariates_to_test), "covariates at each age\n")
cat("  - Covariates:", paste(covariates_to_test, collapse = ", "), "\n\n")

# ------------------------------------------------------------------------------
# STEP 2: DEFINE WAVES TO ANALYZE
# ------------------------------------------------------------------------------

cat("Step 2: Setting up wave-specific analyses...\n")

# Define waves with their SC factor scores from LGBM
# These are already extracted and available in growth_params_with_cov
waves_to_analyze <- data.frame(
  age = c(3, 5, 7, 11, 14, 17),
  sc_var = c("SC_3", "SC_5", "SC_7", "SC_11", "SC_14", "SC_17"),
  label = c("Age 3 (Early Childhood)", "Age 5 (Preschool)",
            "Age 7 (Middle Childhood)", "Age 11 (Pre-Adolescence)",
            "Age 14 (Early Adolescence)", "Age 17 (Late Adolescence)")
)

cat("  - Will analyze", nrow(waves_to_analyze), "time points:\n")
for (i in 1:nrow(waves_to_analyze)) {
  cat("    •", waves_to_analyze$label[i], "\n")
}
cat("\n")

# ------------------------------------------------------------------------------
# STEP 3: RUN SEMTREE FOR EACH WAVE
# ------------------------------------------------------------------------------

cat("Step 3: Running SEMTree for each wave...\n")
cat("  (This may take 10-15 minutes total)\n\n")

# Initialize results storage
results_summary <- data.frame()
trees_list <- list()

# SEMTree control parameters
ctrl_standard <- semtree.control(
  method = "score",
  alpha = 0.05,
  min.N = 100,
  max.depth = 5,
  verbose = FALSE  # Set to FALSE for cleaner output
)

# Loop through each wave
for (i in 1:nrow(waves_to_analyze)) {

  age <- waves_to_analyze$age[i]
  sc_var <- waves_to_analyze$sc_var[i]
  label <- waves_to_analyze$label[i]

  cat(rep("=", 80), "\n", sep = "")
  cat("WAVE", i, ":", label, "\n")
  cat(rep("=", 80), "\n", sep = "")

  # ------------------------------------------------------------------------------
  # Prepare data for this wave
  # ------------------------------------------------------------------------------

  cat("\n  Preparing data...\n")

  # Select SC at this age + covariates, remove missing
  semtree_data_wave <- growth_params_with_cov %>%
    select(mcsid, all_of(sc_var), all_of(covariates_to_test)) %>%
    na.omit()

  # Rename SC variable to generic name for model
  names(semtree_data_wave)[names(semtree_data_wave) == sc_var] <- "sc"

  n_wave <- nrow(semtree_data_wave)

  cat("    - Complete cases: N =", n_wave, "\n")
  cat("    - SC variable:", sc_var, "(factor score from LGBM)\n\n")

  # ------------------------------------------------------------------------------
  # Define and fit baseline model
  # ------------------------------------------------------------------------------

  cat("  Fitting baseline model...\n")

  # Simple univariate model
  model_wave <- '
    # Mean of SC at this age
    sc ~ 1

    # Variance of SC
    sc ~~ sc
  '

  # Fit baseline model
  fit_baseline <- sem(model_wave,
                      data = semtree_data_wave,
                      estimator = "ML")

  mean_sc <- coef(fit_baseline)["sc~1"]
  var_sc <- coef(fit_baseline)["sc~~sc"]

  cat("    ✓ Baseline model fitted\n")
  cat("    - Mean SC:", round(mean_sc, 3), "\n")
  cat("    - Variance:", round(var_sc, 3), "\n\n")

  # ------------------------------------------------------------------------------
  # Run SEMTree
  # ------------------------------------------------------------------------------

  cat("  Running SEMTree...\n")

  tree_wave <- semtree(
    model = fit_baseline,
    data = semtree_data_wave,
    control = ctrl_standard,
    predictors = covariates_to_test
  )

  cat("    ✓ SEMTree complete\n")

  # Check for splits
  tree_str <- capture.output(print(tree_wave))
  has_splits <- any(grepl("\\[2\\]", tree_str))

  if (has_splits) {
    cat("    🎉 SPLITS FOUND at age", age, "\n\n")

    # Print tree structure
    print(tree_wave)
    cat("\n")

    # Count terminal nodes
    n_nodes <- sum(grepl("N=", tree_str))
    cat("    - Number of terminal nodes:", n_nodes, "\n\n")

  } else {
    cat("    ⚠ No splits found at age", age, "\n\n")
  }

  # ------------------------------------------------------------------------------
  # Save tree
  # ------------------------------------------------------------------------------

  filename_base <- paste0("semtree_age", age)

  save(tree_wave,
       file = file.path(results_path, paste0(filename_base, ".RData")))
  cat("    ✓ Saved:", paste0(filename_base, ".RData"), "\n")

  # ------------------------------------------------------------------------------
  # Plot tree
  # ------------------------------------------------------------------------------

  pdf(file.path(figures_path, paste0(filename_base, ".pdf")),
      width = 12, height = 8)
  tryCatch({
    plot(tree_wave, main = paste("SEMTree:", label))
  }, error = function(e) {
    plot.new()
    text(0.5, 0.5, paste("Age", age, "\nNo splits found\nSingle terminal node"),
         cex = 2)
  })
  dev.off()

  cat("    ✓ Saved:", paste0(filename_base, ".pdf"), "\n\n")

  # ------------------------------------------------------------------------------
  # Store results
  # ------------------------------------------------------------------------------

  trees_list[[paste0("age_", age)]] <- tree_wave

  results_summary <- rbind(results_summary, data.frame(
    age = age,
    label = label,
    sc_variable = sc_var,
    n = n_wave,
    mean_sc = mean_sc,
    sd_sc = sqrt(var_sc),
    splits_found = has_splits,
    n_nodes = ifelse(has_splits, sum(grepl("N=", tree_str)), 1)
  ))

  cat("  ✓ Wave", i, "complete\n\n")
}

# ------------------------------------------------------------------------------
# STEP 4: SUMMARIZE RESULTS ACROSS WAVES
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("TIME-SPECIFIC SEMTREE: RESULTS SUMMARY\n")
cat("==============================================================================\n\n")

cat("Results by developmental stage:\n\n")

print(results_summary, row.names = FALSE)

cat("\n")

# Count how many waves found splits
n_splits <- sum(results_summary$splits_found)

cat("Summary:\n")
cat("  - Waves analyzed:", nrow(results_summary), "\n")
cat("  - Waves with splits:", n_splits, "\n")
cat("  - Waves with no splits:", nrow(results_summary) - n_splits, "\n\n")

if (n_splits > 0) {
  cat("Splits found at:\n")
  for (i in which(results_summary$splits_found)) {
    cat("  •", results_summary$label[i],
        "(", results_summary$n_nodes[i], "terminal nodes)\n")
  }
  cat("\n")
}

# ------------------------------------------------------------------------------
# STEP 5: SAVE SUMMARY TABLE
# ------------------------------------------------------------------------------

cat("Saving summary table...\n")

write_csv(results_summary,
          file.path(tables_path, "timespecific_semtree_summary.csv"))
cat("  ✓ Saved: timespecific_semtree_summary.csv\n\n")

# Save all trees in one file
save(trees_list, results_summary,
     file = file.path(results_path, "semtree_timespecific_all.RData"))
cat("  ✓ Saved: semtree_timespecific_all.RData\n\n")

# ------------------------------------------------------------------------------
# STEP 6: DEVELOPMENTAL PATTERNS
# ------------------------------------------------------------------------------

cat("Developmental patterns:\n\n")

# Check if splits emerge at certain ages
if (n_splits > 0) {

  cat("Age-specific findings:\n")

  for (i in which(results_summary$splits_found)) {
    age <- results_summary$age[i]
    label <- results_summary$label[i]

    cat("  • Age", age, "(", label, "):\n")
    cat("    - Subgroups detected\n")
    cat("    - Examine tree for splitting variables\n")
    cat("    - Compare with adjacent ages\n\n")
  }

  # Are splits more common in certain developmental periods?
  if (any(results_summary$splits_found[results_summary$age <= 7])) {
    cat("  → Early childhood (ages 3-7): Subgroups detected\n")
  }

  if (any(results_summary$splits_found[results_summary$age >= 11])) {
    cat("  → Adolescence (ages 11-17): Subgroups detected\n")
  }

} else {

  cat("  - NO splits found at any developmental stage\n")
  cat("  - Consistent with homogeneous effects across ages\n")
  cat("  - Null finding robust across childhood and adolescence\n\n")

}

# ------------------------------------------------------------------------------
# INTERPRETATION GUIDE
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("INTERPRETATION GUIDE\n")
cat("==============================================================================\n\n")

cat("What do these results mean?\n\n")

cat("IF SPLITS FOUND:\n")
cat("  1. Different subgroups exist at that specific age\n")
cat("  2. Examine which covariates split at each age\n")
cat("  3. Compare splitting patterns across ages:\n")
cat("     - Same variables split across ages → stable moderators\n")
cat("     - Different variables split → age-specific effects\n")
cat("  4. Look for critical periods (ages where effects emerge/disappear)\n\n")

cat("IF NO SPLITS FOUND:\n")
cat("  1. Consistent with homogeneous SC levels across subgroups\n")
cat("  2. Null finding robust across developmental stages\n")
cat("  3. Check regression results for small linear effects\n")
cat("  4. Consider that covariates may affect CHANGE (slope) not LEVEL\n\n")

cat("Comparing with growth parameter results:\n")
cat("  - Intercept tree = Who starts high/low at age 3?\n")
cat("  - Slope tree = Who changes faster/slower?\n")
cat("  - Time-specific = Who is high/low at each specific age?\n")
cat("  - These are complementary, not redundant!\n\n")

# ------------------------------------------------------------------------------
# OUTPUT SUMMARY
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("OUTPUT FILES\n")
cat("==============================================================================\n\n")

cat("Individual wave results:\n")
for (i in 1:nrow(waves_to_analyze)) {
  age <- waves_to_analyze$age[i]
  cat("  📁 results/models/semtree_age", age, ".RData\n", sep = "")
  cat("  📈 results/figures/semtree_age", age, ".pdf\n", sep = "")
}

cat("\nSummary files:\n")
cat("  📁 results/models/semtree_timespecific_all.RData\n")
cat("  📊 results/tables/timespecific_semtree_summary.csv\n\n")

# ------------------------------------------------------------------------------
# NEXT STEPS
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("NEXT STEPS\n")
cat("==============================================================================\n\n")

cat("Analysis:\n")
cat("  1. Compare time-specific with growth parameter results\n")
cat("  2. If splits found: examine which covariates split at each age\n")
cat("  3. Look for age-specific vs stable moderator effects\n")
cat("  4. Cross-validate patterns with regression results\n\n")

cat("Visualization:\n")
cat("  1. Create comparison plot of splits across ages\n")
cat("  2. Visualize mean SC trajectories by terminal nodes\n")
cat("  3. Compare effect sizes across developmental stages\n\n")

cat("Further analyses:\n")
cat("  1. Theory-driven moderation: R/enhanced_analyses/06_semtree_moderation.R\n")
cat("  2. Synthesis and comparison: R/enhanced_analyses/07_compare_results.R\n\n")

cat("==============================================================================\n")
cat("TIME-SPECIFIC SEMTREE COMPLETE!\n")
cat("==============================================================================\n\n")
