# ==============================================================================
# Time-Specific SEMTree Analyses (Cross-Sectional at Each Age)
# ==============================================================================
#
# Purpose: Run separate SEMTree analyses for each wave to identify age-specific
#          predictors of self-control
#
# Research Question:
#   Do different covariates predict self-control at different developmental stages?
#
# Strategy:
#   - Run 6 separate trees (ages 3, 5, 7, 11, 14, 17)
#   - Use age-appropriate covariates (concurrent and lagged predictors)
#   - Compare patterns across ages
#
# Input:  data/processed/mcs_twostage_dataset.RData
# Output: results/semtrees/timespecific_trees.RData
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, semtree, here)

cat("\n")
cat("==============================================================================\n")
cat("TIME-SPECIFIC SEMTREE ANALYSES\n")
cat("==============================================================================\n\n")

processed_path <- here("data", "processed")
results_path <- here("results")

# Load data
load(file.path(processed_path, "mcs_twostage_dataset.RData"))

# Ages to analyze
ages <- c(3, 5, 7, 11, 14, 17)
all_trees <- list()
all_tests <- list()

# ------------------------------------------------------------------------------
# Run SEMTree for Each Age
# ------------------------------------------------------------------------------

for (age in ages) {
  cat("===== AGE", age, "=====\n")

  # Define outcome
  outcome_var <- paste0("SC_", age)

  # Define model
  model <- paste0(outcome_var, " ~ 1")

  # Select age-appropriate covariates
  if (age <= 7) {
    # Early childhood: baseline + early parenting
    covs <- c("sex", "ses_disadvantage", "cognitive_ability", "harsh_early")
  } else if (age == 11) {
    # Middle childhood: baseline + early parenting + consistency
    covs <- c("sex", "ses_disadvantage", "cognitive_ability",
              "harsh_early", "pos_early")
  } else {
    # Adolescence: all covariates
    covs <- c("sex", "ses_disadvantage", "cognitive_ability",
              "harsh_early", "pos_early", "mon_avg")
  }

  # Filter available
  covs <- covs[covs %in% names(twostage_data)]

  # Complete cases
  complete_data <- twostage_data %>%
    filter(complete.cases(select(., all_of(c(outcome_var, covs)))))

  cat("  N =", nrow(complete_data), "\n")
  cat("  Covariates:", paste(covs, collapse = ", "), "\n")

  # Fit null model
  fit <- sem(model, data = complete_data, estimator = "ML")

  # Run SEMTree
  ctrl <- semtree_control(method = "fair", alpha = 0.10, min.N = 100,
                         bonferroni = TRUE, verbose = FALSE)

  tree <- tryCatch({
    semtree(model = fit, data = complete_data, control = ctrl,
           predictors = complete_data[, covs, drop = FALSE])
  }, error = function(e) NULL)

  if (!is.null(tree) && length(tree$rule) > 0) {
    cat("  ✓ SPLITS FOUND:", tree$rule[1], "\n")
  } else {
    cat("  ✗ No splits\n")
  }

  all_trees[[paste0("age_", age)]] <- tree

  # Individual covariate tests
  tests <- data.frame()
  for (cov in covs) {
    median_val <- median(complete_data[[cov]], na.rm = TRUE)
    complete_data$split <- ifelse(complete_data[[cov]] <= median_val, 0, 1)

    fit_split <- sem(model, data = complete_data, estimator = "ML", group = "split")
    lr <- anova(fit, fit_split)

    mean_low <- mean(complete_data[[outcome_var]][complete_data$split == 0], na.rm = TRUE)
    mean_high <- mean(complete_data[[outcome_var]][complete_data$split == 1], na.rm = TRUE)
    d <- (mean_high - mean_low) / sd(complete_data[[outcome_var]], na.rm = TRUE)

    tests <- rbind(tests, data.frame(
      age = age,
      covariate = cov,
      p_value = lr$`Pr(>Chisq)`[2],
      effect_size = d
    ))
  }

  all_tests[[paste0("age_", age)]] <- tests %>% arrange(p_value)
  cat("\n")
}

# Combine all tests
combined_tests <- bind_rows(all_tests)

# ------------------------------------------------------------------------------
# Visualize Cross-Age Patterns
# ------------------------------------------------------------------------------

cat("Creating visualizations...\n")

dir.create(file.path(results_path, "plots", "semtrees"),
          showWarnings = FALSE, recursive = TRUE)

# Heatmap of effects across ages
pdf(file.path(results_path, "plots", "semtrees", "timespecific_heatmap.pdf"),
    width = 10, height = 6)

combined_tests %>%
  ggplot(aes(x = factor(age), y = covariate, fill = effect_size)) +
  geom_tile(color = "white") +
  geom_text(aes(label = ifelse(p_value < 0.05, "*", "")),
           size = 6, color = "white") +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                      midpoint = 0, limits = c(-0.5, 0.5)) +
  theme_minimal() +
  labs(title = "Covariate Effects Across Ages",
       subtitle = "* = p < .05",
       x = "Age", y = "Covariate",
       fill = "Effect Size\n(Cohen's d)")

dev.off()

cat("  ✓ Saved heatmap\n")

# Save results
save(all_trees, combined_tests,
     file = file.path(results_path, "semtrees", "timespecific_trees.RData"))

cat("\n==============================================================================\n")
cat("TIME-SPECIFIC ANALYSIS COMPLETE!\n")
cat("- Analyzed", length(ages), "ages:", paste(ages, collapse = ", "), "\n")
cat("- Saved: results/semtrees/timespecific_trees.RData\n")
cat("- Plot: results/plots/semtrees/timespecific_heatmap.pdf\n")
cat("==============================================================================\n\n")
