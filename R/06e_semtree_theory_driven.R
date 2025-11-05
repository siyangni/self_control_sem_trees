# ==============================================================================
# Theory-Driven Moderation Trees
# ==============================================================================
#
# Purpose: Test specific theoretical hypotheses using constrained SEMTrees
#
# Hypotheses:
#   1. SES × Parenting: Does harsh parenting matter more in low-SES contexts?
#   2. Sex × Parenting: Do boys and girls respond differently to parenting?
#   3. Cognition × Parenting: Do high-ability children show different sensitivity?
#
# Strategy:
#   - Force first split on moderator (SES, sex, cognition)
#   - Test parenting effects within each group
#   - Compare effect sizes across groups
#
# Input:  data/processed/mcs_twostage_dataset.RData
# Output: results/semtrees/theory_driven_trees.RData
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, here)

cat("\n")
cat("==============================================================================\n")
cat("THEORY-DRIVEN MODERATION ANALYSES\n")
cat("==============================================================================\n\n")

processed_path <- here("data", "processed")
results_path <- here("results")

load(file.path(processed_path, "mcs_twostage_dataset.RData"))

# Outcomes to test
outcomes <- c("intercept", "slope")

moderation_results <- list()

# ------------------------------------------------------------------------------
# HYPOTHESIS 1: SES × Parenting Interaction
# ------------------------------------------------------------------------------

cat("===== HYPOTHESIS 1: SES × PARENTING =====\n")

for (outcome in outcomes) {
  cat("\nOutcome:", outcome, "\n")

  # Create SES groups
  twostage_data$ses_group <- ifelse(twostage_data$ses_disadvantage == 1,
                                   "Low SES", "High SES")

  # Test harsh parenting effect in each SES group
  for (ses in c("Low SES", "High SES")) {
    data_subset <- twostage_data %>% filter(ses_group == ses,
                                           !is.na(harsh_early))

    if (nrow(data_subset) < 50) next

    # Median split on harsh parenting
    median_harsh <- median(data_subset$harsh_early, na.rm = TRUE)
    data_subset$harsh_group <- ifelse(data_subset$harsh_early <= median_harsh,
                                     "Low Harsh", "High Harsh")

    # Compare groups
    low_mean <- mean(data_subset[[outcome]][data_subset$harsh_group == "Low Harsh"],
                    na.rm = TRUE)
    high_mean <- mean(data_subset[[outcome]][data_subset$harsh_group == "High Harsh"],
                     na.rm = TRUE)
    pooled_sd <- sd(data_subset[[outcome]], na.rm = TRUE)
    d <- (high_mean - low_mean) / pooled_sd

    # t-test
    t_result <- t.test(data_subset[[outcome]] ~ data_subset$harsh_group)

    cat("  ", ses, ": d =", round(d, 3), ", p =",
        format.pval(t_result$p.value, digits = 3), "\n")

    moderation_results[[paste0("SES_harsh_", outcome, "_", ses)]] <- list(
      moderator = "SES",
      predictor = "harsh_early",
      outcome = outcome,
      group = ses,
      effect_size = d,
      p_value = t_result$p.value
    )
  }
}

# ------------------------------------------------------------------------------
# HYPOTHESIS 2: Sex × Parenting Interaction
# ------------------------------------------------------------------------------

cat("\n===== HYPOTHESIS 2: SEX × PARENTING =====\n")

for (outcome in outcomes) {
  cat("\nOutcome:", outcome, "\n")

  # Test parenting in boys vs. girls
  for (sex_val in c(0, 1)) {  # Assuming 0 = female, 1 = male
    sex_label <- ifelse(sex_val == 1, "Males", "Females")
    data_subset <- twostage_data %>%
      filter(sex == sex_val, !is.na(harsh_early))

    if (nrow(data_subset) < 50) next

    median_harsh <- median(data_subset$harsh_early, na.rm = TRUE)
    data_subset$harsh_group <- ifelse(data_subset$harsh_early <= median_harsh,
                                     "Low Harsh", "High Harsh")

    low_mean <- mean(data_subset[[outcome]][data_subset$harsh_group == "Low Harsh"],
                    na.rm = TRUE)
    high_mean <- mean(data_subset[[outcome]][data_subset$harsh_group == "High Harsh"],
                     na.rm = TRUE)
    d <- (high_mean - low_mean) / sd(data_subset[[outcome]], na.rm = TRUE)

    t_result <- t.test(data_subset[[outcome]] ~ data_subset$harsh_group)

    cat("  ", sex_label, ": d =", round(d, 3), ", p =",
        format.pval(t_result$p.value, digits = 3), "\n")

    moderation_results[[paste0("Sex_harsh_", outcome, "_", sex_label)]] <- list(
      moderator = "Sex",
      predictor = "harsh_early",
      outcome = outcome,
      group = sex_label,
      effect_size = d,
      p_value = t_result$p.value
    )
  }
}

# ------------------------------------------------------------------------------
# HYPOTHESIS 3: Cognition × Parenting Interaction
# ------------------------------------------------------------------------------

cat("\n===== HYPOTHESIS 3: COGNITIVE ABILITY × PARENTING =====\n")

for (outcome in outcomes) {
  cat("\nOutcome:", outcome, "\n")

  # Create cognition groups (median split)
  median_cog <- median(twostage_data$cognitive_ability, na.rm = TRUE)
  twostage_data$cog_group <- ifelse(twostage_data$cognitive_ability <= median_cog,
                                   "Low Ability", "High Ability")

  # Test parenting in each cognition group
  for (cog in c("Low Ability", "High Ability")) {
    data_subset <- twostage_data %>%
      filter(cog_group == cog, !is.na(harsh_early))

    if (nrow(data_subset) < 50) next

    median_harsh <- median(data_subset$harsh_early, na.rm = TRUE)
    data_subset$harsh_group <- ifelse(data_subset$harsh_early <= median_harsh,
                                     "Low Harsh", "High Harsh")

    low_mean <- mean(data_subset[[outcome]][data_subset$harsh_group == "Low Harsh"],
                    na.rm = TRUE)
    high_mean <- mean(data_subset[[outcome]][data_subset$harsh_group == "High Harsh"],
                     na.rm = TRUE)
    d <- (high_mean - low_mean) / sd(data_subset[[outcome]], na.rm = TRUE)

    t_result <- t.test(data_subset[[outcome]] ~ data_subset$harsh_group)

    cat("  ", cog, ": d =", round(d, 3), ", p =",
        format.pval(t_result$p.value, digits = 3), "\n")

    moderation_results[[paste0("Cog_harsh_", outcome, "_", cog)]] <- list(
      moderator = "Cognition",
      predictor = "harsh_early",
      outcome = outcome,
      group = cog,
      effect_size = d,
      p_value = t_result$p.value
    )
  }
}

# ------------------------------------------------------------------------------
# Visualize Moderation Effects
# ------------------------------------------------------------------------------

cat("\nCreating visualizations...\n")

dir.create(file.path(results_path, "plots", "semtrees"),
          showWarnings = FALSE, recursive = TRUE)

# Convert to data frame
mod_df <- bind_rows(lapply(names(moderation_results), function(name) {
  res <- moderation_results[[name]]
  data.frame(
    name = name,
    moderator = res$moderator,
    predictor = res$predictor,
    outcome = res$outcome,
    group = res$group,
    effect_size = res$effect_size,
    p_value = res$p_value,
    stringsAsFactors = FALSE
  )
}))

# Plot
pdf(file.path(results_path, "plots", "semtrees", "theory_driven_moderation.pdf"),
    width = 12, height = 8)

mod_df %>%
  mutate(sig = ifelse(p_value < 0.05, "p < .05", "ns"),
         label = paste0(moderator, "\n", group)) %>%
  ggplot(aes(x = label, y = effect_size, fill = sig)) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dotted", color = "gray50") +
  facet_wrap(~outcome, ncol = 2) +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Theory-Driven Moderation Effects",
    subtitle = "Effect of harsh parenting on intercept/slope within moderator groups",
    x = "Moderator Group",
    y = "Effect Size (Cohen's d)",
    fill = "Significance"
  ) +
  scale_fill_manual(values = c("p < .05" = "darkgreen", "ns" = "gray70"))

dev.off()

cat("  ✓ Saved plot\n")

# Save results
save(moderation_results, mod_df,
     file = file.path(results_path, "semtrees", "theory_driven_trees.RData"))

cat("\n==============================================================================\n")
cat("THEORY-DRIVEN MODERATION ANALYSIS COMPLETE!\n")
cat("- Tested 3 hypotheses: SES × Parenting, Sex × Parenting, Cognition × Parenting\n")
cat("- Saved: results/semtrees/theory_driven_trees.RData\n")
cat("- Plot: results/plots/semtrees/theory_driven_moderation.pdf\n")
cat("==============================================================================\n\n")
