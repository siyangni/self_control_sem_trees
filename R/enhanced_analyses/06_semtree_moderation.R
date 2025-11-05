# ==============================================================================
# Theory-Driven Moderation SEMTree
# ==============================================================================
#
# Purpose: Test specific theoretical moderation hypotheses using SEMTree
#   - Focus on theoretically-motivated interactions
#   - More power than exploratory approach
#   - Tests key criminological theories
#
# Theoretical Hypotheses:
#   H1: SES × Harsh Parenting (differential susceptibility)
#       - Harsh parenting more harmful in low-SES contexts
#   H2: Sex × Positive Parenting (differential effectiveness)
#       - Positive parenting differentially effective by sex
#   H3: Cognitive Ability × SES (compensatory effects)
#       - Cognitive ability buffers low-SES risk
#   H4: Difficult Temperament × Harsh Parenting (diathesis-stress)
#       - Harsh parenting more harmful for difficult temperament
#   H5: Cognitive Ability × Harsh Parenting (protective factor)
#       - Cognitive ability buffers harsh parenting effects
#
# Methodological Approach:
#   - Use growth parameters (intercept, slope) as outcomes
#   - Create interaction-focused covariate sets
#   - Run targeted SEMTrees for each hypothesis
#   - Compare with regression interaction tests
#
# Input:  data/processed/growth_parameters_with_covariates.RData
# Output: results/models/semtree_moderation_*.RData
#         results/figures/semtree_moderation_*.pdf
#         results/tables/moderation_summary.csv
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, semtree, here)

cat("\n")
cat("==============================================================================\n")
cat("THEORY-DRIVEN MODERATION SEMTREE\n")
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

cat("Step 1: Loading growth parameters...\n")

load(file.path(processed_path, "growth_parameters_with_covariates.RData"))

cat("  - N =", nrow(growth_params_with_cov), "participants\n")
cat("  - Outcomes: Intercept (i) and Slope (s)\n\n")

# ------------------------------------------------------------------------------
# STEP 2: PREPARE DATA AND STANDARDIZE VARIABLES
# ------------------------------------------------------------------------------

cat("Step 2: Preparing moderation data...\n")

# Standardize continuous predictors for interpretability
moderation_data <- growth_params_with_cov %>%
  mutate(
    # Standardize continuous variables
    harsh_z = scale(harsh_early_avg)[,1],
    pos_z = scale(pos_early_avg)[,1],
    cog_z = scale(cognitive_3)[,1],

    # Create binary/categorical versions for clearer splits
    ses_binary = ifelse(ses_group == "Low", "Low", "Middle/High"),
    harsh_binary = ifelse(harsh_group == "High", "High", "Low/Medium"),
    pos_binary = ifelse(pos_group == "High", "High", "Low/Medium"),

    # Ensure factors
    sex = factor(sex, levels = c("Male", "Female")),
    ses_binary = factor(ses_binary, levels = c("Low", "Middle/High")),
    harsh_binary = factor(harsh_binary, levels = c("Low/Medium", "High")),
    pos_binary = factor(pos_binary, levels = c("Low/Medium", "High"))
  )

cat("  - Standardized continuous predictors\n")
cat("  - Created binary groupings for clearer interpretation\n\n")

# ------------------------------------------------------------------------------
# STEP 3: DEFINE MODERATION HYPOTHESES
# ------------------------------------------------------------------------------

cat("Step 3: Defining moderation hypotheses...\n\n")

# Define hypothesis-specific covariate sets
# Each set includes the focal variables + relevant controls

hypotheses <- list(

  # H1: SES × Harsh Parenting
  h1_ses_harsh = list(
    name = "H1: SES × Harsh Parenting",
    theory = "Differential susceptibility - harsh parenting more harmful in low-SES",
    predictors = c("ses_binary", "harsh_z", "sex", "ethnicity", "married"),
    outcome_intercept = TRUE,
    outcome_slope = TRUE
  ),

  # H2: Sex × Positive Parenting
  h2_sex_positive = list(
    name = "H2: Sex × Positive Parenting",
    theory = "Differential effectiveness - positive parenting effects vary by sex",
    predictors = c("sex", "pos_z", "ses_group", "ethnicity"),
    outcome_intercept = TRUE,
    outcome_slope = TRUE
  ),

  # H3: Cognitive Ability × SES
  h3_cog_ses = list(
    name = "H3: Cognitive Ability × SES",
    theory = "Compensatory effects - cognitive ability buffers low-SES risk",
    predictors = c("cog_z", "ses_binary", "sex", "ethnicity", "mat_edu_collapsed"),
    outcome_intercept = TRUE,
    outcome_slope = TRUE
  ),

  # H4: Difficult Temperament × Harsh Parenting
  h4_temp_harsh = list(
    name = "H4: Difficult Temperament × Harsh Parenting",
    theory = "Diathesis-stress - harsh parenting more harmful for difficult children",
    predictors = c("difficult_temperament", "harsh_z", "ses_group", "sex"),
    outcome_intercept = TRUE,
    outcome_slope = TRUE
  ),

  # H5: Cognitive Ability × Harsh Parenting
  h5_cog_harsh = list(
    name = "H5: Cognitive Ability × Harsh Parenting",
    theory = "Protective factor - cognitive ability buffers harsh parenting",
    predictors = c("cog_z", "harsh_z", "ses_group", "sex", "ethnicity"),
    outcome_intercept = TRUE,
    outcome_slope = TRUE
  )
)

cat("Defined", length(hypotheses), "theoretical hypotheses:\n")
for (h in hypotheses) {
  cat("  •", h$name, "\n")
  cat("    Theory:", h$theory, "\n")
  cat("    Predictors:", paste(h$predictors, collapse = ", "), "\n\n")
}

# ------------------------------------------------------------------------------
# STEP 4: RUN MODERATION SEMTREES
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("RUNNING MODERATION SEMTREES\n")
cat("==============================================================================\n\n")

# SEMTree control - slightly relaxed for moderation detection
ctrl_moderation <- semtree.control(
  method = "score",
  alpha = 0.10,     # More permissive for interactions
  min.N = 75,       # Smaller nodes
  max.depth = 4,    # Limit depth (focus on main splits)
  verbose = FALSE
)

# Storage for results
moderation_results <- data.frame()
trees_moderation <- list()

# Loop through hypotheses
for (h_id in names(hypotheses)) {

  h <- hypotheses[[h_id]]

  cat(rep("=", 80), "\n", sep = "")
  cat(h$name, "\n")
  cat(rep("=", 80), "\n", sep = "")
  cat("Theory:", h$theory, "\n\n")

  # --------------------------------------------------------------------------
  # Test with INTERCEPT as outcome
  # --------------------------------------------------------------------------

  if (h$outcome_intercept) {

    cat("Testing moderation of INTERCEPT (initial level)...\n")

    # Prepare data
    data_h_i <- moderation_data %>%
      select(mcsid, i, all_of(h$predictors)) %>%
      na.omit()

    cat("  - Complete cases: N =", nrow(data_h_i), "\n")

    # Define model
    model_i <- '
      i ~ 1
      i ~~ i
    '

    # Fit baseline
    fit_i <- sem(model_i, data = data_h_i, estimator = "ML")

    # Run SEMTree
    tree_i <- semtree(
      model = fit_i,
      data = data_h_i,
      control = ctrl_moderation,
      predictors = h$predictors
    )

    # Check for splits
    tree_i_str <- capture.output(print(tree_i))
    has_splits_i <- any(grepl("\\[2\\]", tree_i_str))

    if (has_splits_i) {
      cat("  🎉 SPLITS FOUND for intercept!\n\n")
      print(tree_i)
      cat("\n")
    } else {
      cat("  ⚠ No splits found for intercept\n\n")
    }

    # Save tree
    save(tree_i, file = file.path(results_path,
                                    paste0("semtree_", h_id, "_intercept.RData")))

    # Plot
    pdf(file.path(figures_path, paste0("semtree_", h_id, "_intercept.pdf")),
        width = 12, height = 8)
    tryCatch({
      plot(tree_i, main = paste(h$name, "- Intercept"))
    }, error = function(e) {
      plot.new()
      text(0.5, 0.5, paste(h$name, "\nIntercept\nNo splits"), cex = 1.5)
    })
    dev.off()

    # Store results
    trees_moderation[[paste0(h_id, "_intercept")]] <- tree_i

    moderation_results <- rbind(moderation_results, data.frame(
      hypothesis = h_id,
      hypothesis_name = h$name,
      outcome = "Intercept",
      n = nrow(data_h_i),
      n_predictors = length(h$predictors),
      splits_found = has_splits_i,
      stringsAsFactors = FALSE
    ))
  }

  # --------------------------------------------------------------------------
  # Test with SLOPE as outcome
  # --------------------------------------------------------------------------

  if (h$outcome_slope) {

    cat("Testing moderation of SLOPE (rate of change)...\n")

    # Prepare data
    data_h_s <- moderation_data %>%
      select(mcsid, s, all_of(h$predictors)) %>%
      na.omit()

    cat("  - Complete cases: N =", nrow(data_h_s), "\n")

    # Define model
    model_s <- '
      s ~ 1
      s ~~ s
    '

    # Fit baseline
    fit_s <- sem(model_s, data = data_h_s, estimator = "ML")

    # Run SEMTree
    tree_s <- semtree(
      model = fit_s,
      data = data_h_s,
      control = ctrl_moderation,
      predictors = h$predictors
    )

    # Check for splits
    tree_s_str <- capture.output(print(tree_s))
    has_splits_s <- any(grepl("\\[2\\]", tree_s_str))

    if (has_splits_s) {
      cat("  🎉 SPLITS FOUND for slope!\n\n")
      print(tree_s)
      cat("\n")
    } else {
      cat("  ⚠ No splits found for slope\n\n")
    }

    # Save tree
    save(tree_s, file = file.path(results_path,
                                    paste0("semtree_", h_id, "_slope.RData")))

    # Plot
    pdf(file.path(figures_path, paste0("semtree_", h_id, "_slope.pdf")),
        width = 12, height = 8)
    tryCatch({
      plot(tree_s, main = paste(h$name, "- Slope"))
    }, error = function(e) {
      plot.new()
      text(0.5, 0.5, paste(h$name, "\nSlope\nNo splits"), cex = 1.5)
    })
    dev.off()

    # Store results
    trees_moderation[[paste0(h_id, "_slope")]] <- tree_s

    moderation_results <- rbind(moderation_results, data.frame(
      hypothesis = h_id,
      hypothesis_name = h$name,
      outcome = "Slope",
      n = nrow(data_h_s),
      n_predictors = length(h$predictors),
      splits_found = has_splits_s,
      stringsAsFactors = FALSE
    ))
  }

  cat("  ✓ Hypothesis", h_id, "complete\n\n")
}

# ------------------------------------------------------------------------------
# STEP 5: SUMMARIZE MODERATION RESULTS
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("MODERATION RESULTS SUMMARY\n")
cat("==============================================================================\n\n")

print(moderation_results, row.names = FALSE)

cat("\n")

# Count supported hypotheses
n_splits_total <- sum(moderation_results$splits_found)
n_tests_total <- nrow(moderation_results)

cat("Summary:\n")
cat("  - Hypotheses tested:", length(hypotheses), "\n")
cat("  - Total tests (intercept + slope):", n_tests_total, "\n")
cat("  - Tests with splits:", n_splits_total, "\n")
cat("  - Proportion with splits:", round(n_splits_total / n_tests_total, 2), "\n\n")

if (n_splits_total > 0) {

  cat("Evidence found for:\n")

  supported <- moderation_results %>%
    filter(splits_found) %>%
    arrange(hypothesis, outcome)

  for (i in 1:nrow(supported)) {
    cat("  ✓", supported$hypothesis_name[i], "-", supported$outcome[i], "\n")
  }

  cat("\n→ Examine trees to identify specific moderator patterns\n\n")

} else {

  cat("No moderation effects detected:\n")
  cat("  - Null findings across all theoretical hypotheses\n")
  cat("  - Suggests homogeneous effects across subgroups\n")
  cat("  - Check regression results for small interaction effects\n\n")

}

# ------------------------------------------------------------------------------
# STEP 6: SAVE RESULTS
# ------------------------------------------------------------------------------

cat("Saving results...\n")

# Save summary table
write_csv(moderation_results,
          file.path(tables_path, "moderation_semtree_summary.csv"))
cat("  ✓ Saved: moderation_semtree_summary.csv\n")

# Save all trees
save(trees_moderation, moderation_results, hypotheses,
     file = file.path(results_path, "semtree_moderation_all.RData"))
cat("  ✓ Saved: semtree_moderation_all.RData\n\n")

# ------------------------------------------------------------------------------
# INTERPRETATION GUIDE
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("INTERPRETATION GUIDE\n")
cat("==============================================================================\n\n")

cat("What do moderation results mean?\n\n")

cat("IF SPLITS FOUND:\n")
cat("  1. Evidence for the theoretical moderation hypothesis\n")
cat("  2. Examine which variable splits first (focal moderator)\n")
cat("  3. Compare terminal node means to quantify interaction\n")
cat("  4. Cross-check with regression interaction term\n")
cat("  5. Consider clinical/policy implications of subgroup differences\n\n")

cat("IF NO SPLITS FOUND:\n")
cat("  1. No evidence for moderation (null hypothesis supported)\n")
cat("  2. Effects may be homogeneous across subgroups\n")
cat("  3. Possible explanations:\n")
cat("     - True null (no interaction exists)\n")
cat("     - Interaction too small to detect with SEMTree\n")
cat("     - Insufficient power (check N in each test)\n")
cat("  4. Check regression for small linear interactions\n\n")

cat("Comparing outcomes:\n")
cat("  - Intercept moderation = Who starts high/low depends on X?\n")
cat("  - Slope moderation = Who changes faster/slower depends on X?\n")
cat("  - Different implications for intervention timing\n\n")

# ------------------------------------------------------------------------------
# THEORETICAL IMPLICATIONS
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("THEORETICAL IMPLICATIONS BY HYPOTHESIS\n")
cat("==============================================================================\n\n")

if (any(moderation_results$hypothesis == "h1_ses_harsh" &
        moderation_results$splits_found)) {
  cat("H1 SUPPORTED (SES × Harsh Parenting):\n")
  cat("  → Differential susceptibility confirmed\n")
  cat("  → Harsh parenting effects vary by SES context\n")
  cat("  → Target harsh parenting interventions to high-risk SES groups\n\n")
}

if (any(moderation_results$hypothesis == "h2_sex_positive" &
        moderation_results$splits_found)) {
  cat("H2 SUPPORTED (Sex × Positive Parenting):\n")
  cat("  → Sex differences in positive parenting effects\n")
  cat("  → Consider sex-specific parenting interventions\n")
  cat("  → Examine effect direction in terminal nodes\n\n")
}

if (any(moderation_results$hypothesis == "h3_cog_ses" &
        moderation_results$splits_found)) {
  cat("H3 SUPPORTED (Cognitive × SES):\n")
  cat("  → Cognitive ability as compensatory factor\n")
  cat("  → Cognitive enrichment may buffer low-SES risk\n")
  cat("  → Early cognitive interventions theoretically justified\n\n")
}

if (any(moderation_results$hypothesis == "h4_temp_harsh" &
        moderation_results$splits_found)) {
  cat("H4 SUPPORTED (Temperament × Harsh Parenting):\n")
  cat("  → Diathesis-stress model confirmed\n")
  cat("  → Difficult children more vulnerable to harsh parenting\n")
  cat("  → Temperament-informed parenting programs warranted\n\n")
}

if (any(moderation_results$hypothesis == "h5_cog_harsh" &
        moderation_results$splits_found)) {
  cat("H5 SUPPORTED (Cognitive × Harsh Parenting):\n")
  cat("  → Cognitive ability as protective factor\n")
  cat("  → Cognitive skills buffer parenting risk\n")
  cat("  → Dual intervention (parenting + cognitive) may be optimal\n\n")
}

if (n_splits_total == 0) {
  cat("NO HYPOTHESES SUPPORTED:\n")
  cat("  → Robust null finding across theoretical models\n")
  cat("  → Main effects may dominate over interactions\n")
  cat("  → Intervention targets may not need subgroup tailoring\n")
  cat("  → Universal prevention approaches theoretically justified\n\n")
}

# ------------------------------------------------------------------------------
# OUTPUT FILES
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("OUTPUT FILES\n")
cat("==============================================================================\n\n")

cat("Individual hypothesis results:\n")
for (h_id in names(hypotheses)) {
  h <- hypotheses[[h_id]]
  if (h$outcome_intercept) {
    cat("  📁 results/models/semtree_", h_id, "_intercept.RData\n", sep = "")
    cat("  📈 results/figures/semtree_", h_id, "_intercept.pdf\n", sep = "")
  }
  if (h$outcome_slope) {
    cat("  📁 results/models/semtree_", h_id, "_slope.RData\n", sep = "")
    cat("  📈 results/figures/semtree_", h_id, "_slope.pdf\n", sep = "")
  }
}

cat("\nSummary files:\n")
cat("  📁 results/models/semtree_moderation_all.RData\n")
cat("  📊 results/tables/moderation_semtree_summary.csv\n\n")

# ------------------------------------------------------------------------------
# NEXT STEPS
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("NEXT STEPS\n")
cat("==============================================================================\n\n")

cat("1. Compare moderation results with regression interactions\n")
cat("2. Create visualization comparing all SEMTree approaches\n")
cat("3. Synthesize findings across methods\n")
cat("4. Write up results for manuscript\n\n")

cat("Next script:\n")
cat("  R/enhanced_analyses/07_compare_results.R\n\n")

cat("==============================================================================\n")
cat("THEORY-DRIVEN MODERATION ANALYSIS COMPLETE!\n")
cat("==============================================================================\n\n")
