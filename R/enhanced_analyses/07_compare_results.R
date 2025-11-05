# ==============================================================================
# Compare and Synthesize SEMTree Results Across All Approaches
# ==============================================================================
#
# Purpose: Synthesize findings from multiple SEMTree approaches
#   - Two-stage (intercept, slope)
#   - Time-specific (cross-sectional at each age)
#   - Theory-driven moderation
#   - Regression results
#
# Creates:
#   - Comparison tables
#   - Visualization of results across methods
#   - Summary of convergent/divergent findings
#   - Manuscript-ready figures and tables
#
# Input:  All results from scripts 02-06
# Output: results/synthesis/*
#
# ==============================================================================

library(pacman)
p_load(tidyverse, here, ggplot2, patchwork, knitr)

cat("\n")
cat("==============================================================================\n")
cat("COMPREHENSIVE RESULTS COMPARISON\n")
cat("==============================================================================\n\n")

# Set paths
results_path <- here("results", "models")
figures_path <- here("results", "figures")
tables_path <- here("results", "tables")
synthesis_path <- here("results", "synthesis")

dir.create(synthesis_path, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# STEP 1: LOAD ALL RESULTS
# ------------------------------------------------------------------------------

cat("Step 1: Loading all analysis results...\n")

# Regression results
if (file.exists(file.path(tables_path, "regression_summary.csv"))) {
  regression_results <- read_csv(file.path(tables_path, "regression_summary.csv"),
                                 show_col_types = FALSE)
  cat("  ✓ Regression results loaded\n")
} else {
  cat("  ⚠ Regression results not found\n")
  regression_results <- NULL
}

# Two-stage SEMTree results
cat("  - Loading two-stage SEMTree results...\n")

# Intercept tree
if (file.exists(file.path(results_path, "semtree_intercept_standard.RData"))) {
  load(file.path(results_path, "semtree_intercept_standard.RData"))
  tree_intercept <- tree_standard
  rm(tree_standard)
  cat("    ✓ Intercept tree\n")
} else {
  tree_intercept <- NULL
  cat("    ⚠ Intercept tree not found\n")
}

# Slope tree
if (file.exists(file.path(results_path, "semtree_slope_standard.RData"))) {
  load(file.path(results_path, "semtree_slope_standard.RData"))
  tree_slope <- tree_standard
  rm(tree_standard)
  cat("    ✓ Slope tree\n")
} else {
  tree_slope <- NULL
  cat("    ⚠ Slope tree not found\n")
}

# Time-specific results
if (file.exists(file.path(tables_path, "timespecific_semtree_summary.csv"))) {
  timespecific_results <- read_csv(file.path(tables_path, "timespecific_semtree_summary.csv"),
                                   show_col_types = FALSE)
  cat("  ✓ Time-specific SEMTree results\n")
} else {
  timespecific_results <- NULL
  cat("  ⚠ Time-specific results not found\n")
}

# Moderation results
if (file.exists(file.path(tables_path, "moderation_semtree_summary.csv"))) {
  moderation_results <- read_csv(file.path(tables_path, "moderation_semtree_summary.csv"),
                                 show_col_types = FALSE)
  cat("  ✓ Theory-driven moderation results\n")
} else {
  moderation_results <- NULL
  cat("  ⚠ Moderation results not found\n")
}

cat("\n")

# ------------------------------------------------------------------------------
# STEP 2: CREATE COMPREHENSIVE SUMMARY TABLE
# ------------------------------------------------------------------------------

cat("Step 2: Creating comprehensive summary table...\n")

summary_table <- data.frame(
  approach = character(),
  description = character(),
  n_analyses = integer(),
  n_splits_found = integer(),
  proportion_splits = numeric(),
  stringsAsFactors = FALSE
)

# Two-stage approach
if (!is.null(tree_intercept) || !is.null(tree_slope)) {

  n_two_stage <- 0
  n_splits_two_stage <- 0

  if (!is.null(tree_intercept)) {
    n_two_stage <- n_two_stage + 1
    tree_str <- capture.output(print(tree_intercept))
    if (any(grepl("\\[2\\]", tree_str))) n_splits_two_stage <- n_splits_two_stage + 1
  }

  if (!is.null(tree_slope)) {
    n_two_stage <- n_two_stage + 1
    tree_str <- capture.output(print(tree_slope))
    if (any(grepl("\\[2\\]", tree_str))) n_splits_two_stage <- n_splits_two_stage + 1
  }

  summary_table <- rbind(summary_table, data.frame(
    approach = "Two-stage (Growth Parameters)",
    description = "SEMTree on extracted intercept and slope",
    n_analyses = n_two_stage,
    n_splits_found = n_splits_two_stage,
    proportion_splits = n_splits_two_stage / n_two_stage
  ))
}

# Time-specific approach
if (!is.null(timespecific_results)) {
  summary_table <- rbind(summary_table, data.frame(
    approach = "Time-specific (Cross-sectional)",
    description = "SEMTree at each wave (ages 3-17)",
    n_analyses = nrow(timespecific_results),
    n_splits_found = sum(timespecific_results$splits_found),
    proportion_splits = mean(timespecific_results$splits_found)
  ))
}

# Moderation approach
if (!is.null(moderation_results)) {
  summary_table <- rbind(summary_table, data.frame(
    approach = "Theory-driven Moderation",
    description = "Hypothesis-focused interaction tests",
    n_analyses = nrow(moderation_results),
    n_splits_found = sum(moderation_results$splits_found),
    proportion_splits = mean(moderation_results$splits_found)
  ))
}

# Regression approach (count significant effects)
if (!is.null(regression_results)) {
  n_sig <- sum(regression_results$p_value < 0.05, na.rm = TRUE)
  summary_table <- rbind(summary_table, data.frame(
    approach = "Regression (Linear Models)",
    description = "OLS regression with growth parameters",
    n_analyses = nrow(regression_results),
    n_splits_found = n_sig,
    proportion_splits = n_sig / nrow(regression_results)
  ))
}

print(summary_table)
cat("\n")

write_csv(summary_table, file.path(synthesis_path, "methods_comparison_summary.csv"))
cat("  ✓ Saved: methods_comparison_summary.csv\n\n")

# ------------------------------------------------------------------------------
# STEP 3: VISUALIZE RESULTS ACROSS METHODS
# ------------------------------------------------------------------------------

cat("Step 3: Creating comparison visualizations...\n")

# Plot 1: Proportion of splits/significant effects by method
if (nrow(summary_table) > 0) {

  p1 <- ggplot(summary_table, aes(x = reorder(approach, proportion_splits),
                                   y = proportion_splits)) +
    geom_col(fill = "steelblue", alpha = 0.8) +
    geom_text(aes(label = paste0(n_splits_found, "/", n_analyses)),
              hjust = -0.1, size = 3.5) +
    coord_flip() +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    labs(
      title = "Detection Rate Across SEMTree Approaches",
      subtitle = "Proportion of analyses finding subgroups/effects",
      x = NULL,
      y = "Proportion with Splits/Significant Effects"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      panel.grid.major.y = element_blank()
    )

  ggsave(file.path(synthesis_path, "fig_methods_comparison.pdf"),
         p1, width = 10, height = 6)
  ggsave(file.path(synthesis_path, "fig_methods_comparison.png"),
         p1, width = 10, height = 6, dpi = 300)

  cat("  ✓ Saved: fig_methods_comparison.pdf/png\n")
}

# Plot 2: Time-specific results across developmental stages
if (!is.null(timespecific_results)) {

  p2 <- ggplot(timespecific_results, aes(x = age, y = mean_sc)) +
    geom_line(size = 1, color = "darkblue") +
    geom_point(aes(color = splits_found), size = 4) +
    scale_color_manual(
      values = c("TRUE" = "green3", "FALSE" = "red3"),
      labels = c("TRUE" = "Splits found", "FALSE" = "No splits"),
      name = NULL
    ) +
    labs(
      title = "Self-Control Trajectories and SEMTree Results by Age",
      subtitle = "Green = subgroups detected, Red = no subgroups",
      x = "Age (years)",
      y = "Mean Self-Control (Factor Score)"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      legend.position = "top"
    )

  ggsave(file.path(synthesis_path, "fig_timespecific_trajectory.pdf"),
         p2, width = 10, height = 6)
  ggsave(file.path(synthesis_path, "fig_timespecific_trajectory.png"),
         p2, width = 10, height = 6, dpi = 300)

  cat("  ✓ Saved: fig_timespecific_trajectory.pdf/png\n")
}

# Plot 3: Moderation hypothesis results
if (!is.null(moderation_results)) {

  moderation_results$hypothesis_short <- substr(moderation_results$hypothesis, 1, 10)

  p3 <- ggplot(moderation_results,
               aes(x = hypothesis_short, y = outcome, fill = splits_found)) +
    geom_tile(color = "white", size = 1) +
    scale_fill_manual(
      values = c("TRUE" = "green3", "FALSE" = "grey80"),
      labels = c("TRUE" = "Supported", "FALSE" = "Not supported"),
      name = "Moderation Effect"
    ) +
    labs(
      title = "Theory-Driven Moderation Hypothesis Results",
      subtitle = "Green = evidence for interaction, Grey = null finding",
      x = "Hypothesis",
      y = "Outcome"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "top"
    )

  ggsave(file.path(synthesis_path, "fig_moderation_heatmap.pdf"),
         p3, width = 10, height = 6)
  ggsave(file.path(synthesis_path, "fig_moderation_heatmap.png"),
         p3, width = 10, height = 6, dpi = 300)

  cat("  ✓ Saved: fig_moderation_heatmap.pdf/png\n")
}

cat("\n")

# ------------------------------------------------------------------------------
# STEP 4: IDENTIFY CONVERGENT FINDINGS
# ------------------------------------------------------------------------------

cat("Step 4: Identifying convergent findings...\n")

cat("\nCross-method convergence:\n")

# Check if any method found subgroups
any_splits_semtree <- (
  (!is.null(tree_intercept) && any(grepl("\\[2\\]", capture.output(print(tree_intercept))))) ||
  (!is.null(tree_slope) && any(grepl("\\[2\\]", capture.output(print(tree_slope))))) ||
  (!is.null(timespecific_results) && any(timespecific_results$splits_found)) ||
  (!is.null(moderation_results) && any(moderation_results$splits_found))
)

any_sig_regression <- (!is.null(regression_results) &&
                       any(regression_results$p_value < 0.05, na.rm = TRUE))

if (any_splits_semtree && any_sig_regression) {
  cat("  ✓ CONVERGENT: Both SEMTree and regression find effects\n")
  cat("    → Strong evidence for covariate effects on SC growth\n")
  cat("    → Examine which specific covariates are consistent\n\n")

} else if (!any_splits_semtree && !any_sig_regression) {
  cat("  ✓ CONVERGENT: Both SEMTree and regression find null effects\n")
  cat("    → Robust null finding across methods\n")
  cat("    → Strong evidence for homogeneous SC development\n")
  cat("    → Consider universal (not targeted) interventions\n\n")

} else if (any_splits_semtree && !any_sig_regression) {
  cat("  ⚠ DIVERGENT: SEMTree finds subgroups but regression does not\n")
  cat("    → Non-linear or complex interaction effects\n")
  cat("    → SEMTree may detect patterns regression misses\n")
  cat("    → Examine tree splits to understand subgroup structure\n\n")

} else if (!any_splits_semtree && any_sig_regression) {
  cat("  ⚠ DIVERGENT: Regression finds effects but SEMTree does not\n")
  cat("    → Small linear effects below SEMTree detection threshold\n")
  cat("    → Effects are homogeneous (not moderated)\n")
  cat("    → Regression more sensitive to small effect sizes\n\n")
}

# ------------------------------------------------------------------------------
# STEP 5: SYNTHESIS NARRATIVE
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("SYNTHESIS OF FINDINGS\n")
cat("==============================================================================\n\n")

cat("Overview:\n")
cat("  - Multiple complementary analytic approaches applied\n")
cat("  - Total analyses conducted:",
    sum(summary_table$n_analyses, na.rm = TRUE), "\n")
cat("  - Analyses finding effects/subgroups:",
    sum(summary_table$n_splits_found, na.rm = TRUE), "\n\n")

# Determine overall conclusion
overall_detection_rate <- sum(summary_table$n_splits_found, na.rm = TRUE) /
                          sum(summary_table$n_analyses, na.rm = TRUE)

cat("Overall pattern:\n")

if (overall_detection_rate > 0.25) {
  cat("  → SUBSTANTIAL HETEROGENEITY DETECTED (>25% detection rate)\n")
  cat("    • Self-control development varies across subgroups\n")
  cat("    • Targeted interventions theoretically justified\n")
  cat("    • Identify which covariates/interactions are most important\n\n")

} else if (overall_detection_rate > 0.10) {
  cat("  → MODEST HETEROGENEITY DETECTED (10-25% detection rate)\n")
  cat("    • Some evidence for subgroup differences\n")
  cat("    • Mixed support for heterogeneous effects\n")
  cat("    • Consider method-specific findings carefully\n\n")

} else {
  cat("  → MINIMAL HETEROGENEITY DETECTED (<10% detection rate)\n")
  cat("    • Robust null finding across methods\n")
  cat("    • Self-control development relatively homogeneous\n")
  cat("    • Universal prevention approaches supported\n")
  cat("    • Small main effects may exist (check regression)\n\n")
}

# Method-specific insights
cat("Method-specific insights:\n\n")

if (!is.null(tree_intercept) || !is.null(tree_slope)) {
  intercept_splits <- !is.null(tree_intercept) &&
    any(grepl("\\[2\\]", capture.output(print(tree_intercept))))
  slope_splits <- !is.null(tree_slope) &&
    any(grepl("\\[2\\]", capture.output(print(tree_slope))))

  cat("Two-stage SEMTree (growth parameters):\n")
  if (intercept_splits && slope_splits) {
    cat("  • Subgroups differ in BOTH initial level AND rate of change\n")
    cat("  • Complex developmental heterogeneity\n")
  } else if (intercept_splits) {
    cat("  • Subgroups differ in initial level but not change rate\n")
    cat("  • Early differences persist but don't widen/narrow\n")
  } else if (slope_splits) {
    cat("  • Subgroups have similar starting points but diverge over time\n")
    cat("  • Developmental differences emerge during childhood/adolescence\n")
  } else {
    cat("  • No subgroup differences in growth parameters\n")
    cat("  • Homogeneous intercepts and slopes\n")
  }
  cat("\n")
}

if (!is.null(timespecific_results)) {
  ages_with_splits <- timespecific_results$age[timespecific_results$splits_found]

  cat("Time-specific SEMTree (cross-sectional):\n")
  if (length(ages_with_splits) > 0) {
    cat("  • Subgroups detected at ages:", paste(ages_with_splits, collapse = ", "), "\n")
    if (any(ages_with_splits <= 7)) {
      cat("  • Early childhood effects (critical period?)\n")
    }
    if (any(ages_with_splits >= 11)) {
      cat("  • Adolescent effects (stage-specific mechanisms?)\n")
    }
  } else {
    cat("  • No subgroups at any developmental stage\n")
    cat("  • Consistent homogeneity across ages 3-17\n")
  }
  cat("\n")
}

if (!is.null(moderation_results)) {
  supported_hyp <- moderation_results %>%
    filter(splits_found) %>%
    pull(hypothesis_name) %>%
    unique()

  cat("Theory-driven moderation:\n")
  if (length(supported_hyp) > 0) {
    cat("  • Evidence for theoretical interactions:\n")
    for (hyp in supported_hyp) {
      cat("    -", hyp, "\n")
    }
  } else {
    cat("  • No support for theoretical moderation hypotheses\n")
    cat("  • Main effects dominate over interactions\n")
  }
  cat("\n")
}

# ------------------------------------------------------------------------------
# STEP 6: RECOMMENDATIONS
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("RECOMMENDATIONS\n")
cat("==============================================================================\n\n")

if (overall_detection_rate > 0.25) {

  cat("RESEARCH IMPLICATIONS:\n")
  cat("  1. Document specific subgroup characteristics from terminal nodes\n")
  cat("  2. Quantify effect sizes for each subgroup\n")
  cat("  3. Replicate findings in independent samples\n")
  cat("  4. Investigate mechanisms driving subgroup differences\n\n")

  cat("POLICY/INTERVENTION IMPLICATIONS:\n")
  cat("  1. Consider targeted interventions for high-risk subgroups\n")
  cat("  2. Tailor parenting programs based on family characteristics\n")
  cat("  3. Screen for subgroup membership in prevention programs\n")
  cat("  4. Allocate resources based on risk profiles\n\n")

} else {

  cat("RESEARCH IMPLICATIONS:\n")
  cat("  1. Robust null finding has theoretical value\n")
  cat("  2. Self-control development more universal than expected\n")
  cat("  3. Focus on main effects rather than interactions\n")
  cat("  4. Consider alternative explanations (e.g., measurement, power)\n\n")

  cat("POLICY/INTERVENTION IMPLICATIONS:\n")
  cat("  1. Universal prevention approaches supported\n")
  cat("  2. Interventions likely to benefit all children\n")
  cat("  3. No need for complex risk stratification\n")
  cat("  4. Simpler, broader programs may be more efficient\n\n")

}

# ------------------------------------------------------------------------------
# STEP 7: MANUSCRIPT-READY SUMMARY TABLE
# ------------------------------------------------------------------------------

cat("Step 7: Creating manuscript-ready tables...\n")

# Format table for publication
manuscript_table <- summary_table %>%
  mutate(
    `Method` = approach,
    `Description` = description,
    `N Tests` = n_analyses,
    `N Significant` = n_splits_found,
    `Detection Rate` = sprintf("%.1f%%", proportion_splits * 100)
  ) %>%
  select(`Method`, `Description`, `N Tests`, `N Significant`, `Detection Rate`)

write_csv(manuscript_table, file.path(synthesis_path, "table_methods_comparison_formatted.csv"))

cat("  ✓ Saved: table_methods_comparison_formatted.csv\n\n")

# Print formatted table
cat("Manuscript Table:\n\n")
print(kable(manuscript_table, format = "simple"))

cat("\n")

# ------------------------------------------------------------------------------
# OUTPUT SUMMARY
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("SYNTHESIS COMPLETE\n")
cat("==============================================================================\n\n")

cat("Output files created in results/synthesis/:\n")
cat("  📊 methods_comparison_summary.csv\n")
cat("  📊 table_methods_comparison_formatted.csv (manuscript-ready)\n")
cat("  📈 fig_methods_comparison.pdf/png\n")
if (!is.null(timespecific_results)) {
  cat("  📈 fig_timespecific_trajectory.pdf/png\n")
}
if (!is.null(moderation_results)) {
  cat("  📈 fig_moderation_heatmap.pdf/png\n")
}

cat("\n")

cat("Next steps:\n")
cat("  1. Review all figures and tables\n")
cat("  2. Draft methods and results sections for manuscript\n")
cat("  3. Consider additional sensitivity analyses if needed\n")
cat("  4. Prepare supplementary materials\n\n")

cat("==============================================================================\n\n")
