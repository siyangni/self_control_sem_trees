# ==============================================================================
# Regression Analysis of Growth Parameters
# ==============================================================================
#
# Purpose: Use regression to identify predictors of initial level and change
#   - More power than SEMTree for detecting small effects
#   - Provides effect sizes (standardized coefficients)
#   - Tests specific hypotheses about parenting effects
#   - Identifies which covariates matter most
#
# Advantages over SEMTree:
#   - Linear models have more power for small effects
#   - Can test interactions explicitly
#   - Standard statistical inference (p-values, CIs)
#   - Easy to interpret effect sizes
#
# Input:  data/processed/growth_parameters_with_covariates.RData
# Output: results/tables/regression_*.csv
#         results/figures/regression_*.pdf
#
# ==============================================================================

library(pacman)
p_load(tidyverse, here, broom, car, effects, ggplot2, patchwork)

cat("\n")
cat("==============================================================================\n")
cat("REGRESSION ANALYSIS OF GROWTH PARAMETERS\n")
cat("==============================================================================\n\n")

# Set paths
processed_path <- here("data", "processed")
tables_path <- here("results", "tables")
figures_path <- here("results", "figures")

dir.create(tables_path, showWarnings = FALSE, recursive = TRUE)
dir.create(figures_path, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# STEP 1: LOAD DATA
# ------------------------------------------------------------------------------

cat("Step 1: Loading growth parameters with covariates...\n")

load(file.path(processed_path, "growth_parameters_with_covariates.RData"))
load(file.path(processed_path, "covariate_lists.RData"))

cat("  - N =", nrow(growth_params_with_cov), "participants\n")
cat("  - Growth parameters: intercept (i), slope (s)\n")
cat("  - Covariates:", length(covariate_lists$all_full), "variables\n\n")

# ------------------------------------------------------------------------------
# STEP 2: DATA PREPARATION
# ------------------------------------------------------------------------------

cat("Step 2: Preparing data for regression...\n")

# Create analysis dataset with complete cases on key covariates
regression_data <- growth_params_with_cov %>%
  # Convert factors to ensure proper handling
  mutate(
    sex = factor(sex),
    ethnicity = factor(ethnicity),
    mat_edu_collapsed = factor(mat_edu_collapsed, levels = c("Low", "Medium", "High")),
    ses_group = factor(ses_group, levels = c("Low", "Middle", "High")),
    harsh_group = factor(harsh_group, levels = c("Low", "Medium", "High")),
    pos_group = factor(pos_group, levels = c("Low", "Medium", "High"))
  ) %>%
  # Standardize continuous predictors for interpretability
  mutate(
    across(c(cognitive_3, harsh_early_avg, pos_early_avg, mon_adolescent_avg,
             birth_weight, difficult_temperament),
           ~scale(.), .names = "{.col}_z")
  )

# Count complete cases
n_complete_minimal <- regression_data %>%
  select(i, s, sex, ses_group, cognitive_3_z, harsh_early_avg_z) %>%
  na.omit() %>%
  nrow()

cat("  - Complete cases (minimal model): N =", n_complete_minimal, "\n\n")

# ------------------------------------------------------------------------------
# STEP 3: MODEL 1 - INTERCEPT (Initial Self-Control)
# ------------------------------------------------------------------------------

cat("Step 3: Predicting Intercept (initial level at age 3)...\n\n")

# Model 1a: Baseline characteristics only
cat("  Model 1a: Baseline characteristics\n")

model_1a_intercept <- lm(
  i ~ sex + ethnicity + ses_group + mat_edu_collapsed +
      cognitive_3_z + low_birth_weight + premature + difficult_temperament_z,
  data = regression_data,
  weights = survey_weight
)

summary_1a_i <- summary(model_1a_intercept)
cat("    R² =", round(summary_1a_i$r.squared, 3),
    ", Adj. R² =", round(summary_1a_i$adj.r.squared, 3), "\n")
cat("    F(", summary_1a_i$fstatistic[2], ",", summary_1a_i$fstatistic[3], ") =",
    round(summary_1a_i$fstatistic[1], 2),
    ", p =", format.pval(pf(summary_1a_i$fstatistic[1],
                            summary_1a_i$fstatistic[2],
                            summary_1a_i$fstatistic[3],
                            lower.tail = FALSE), digits = 3), "\n\n")

# Model 1b: Add parenting
cat("  Model 1b: Add early parenting (ages 3-7)\n")

model_1b_intercept <- lm(
  i ~ sex + ethnicity + ses_group + mat_edu_collapsed +
      cognitive_3_z + low_birth_weight + premature + difficult_temperament_z +
      harsh_early_avg_z + pos_early_avg_z,
  data = regression_data,
  weights = survey_weight
)

summary_1b_i <- summary(model_1b_intercept)
cat("    R² =", round(summary_1b_i$r.squared, 3),
    ", Adj. R² =", round(summary_1b_i$adj.r.squared, 3), "\n")
cat("    ΔR² from Model 1a:", round(summary_1b_i$r.squared - summary_1a_i$r.squared, 4), "\n")

# Test incremental R²
anova_1a_1b <- anova(model_1a_intercept, model_1b_intercept)
cat("    F-test for ΔR²: F(", anova_1a_1b$Df[2], ",", anova_1a_1b$Res.Df[2], ") =",
    round(anova_1a_1b$F[2], 2), ", p =",
    format.pval(anova_1a_1b$`Pr(>F)`[2], digits = 3), "\n\n")

# ------------------------------------------------------------------------------
# STEP 4: MODEL 2 - SLOPE (Rate of Change)
# ------------------------------------------------------------------------------

cat("Step 4: Predicting Slope (rate of change)...\n\n")

# Model 2a: Baseline characteristics
cat("  Model 2a: Baseline characteristics\n")

model_2a_slope <- lm(
  s ~ sex + ethnicity + ses_group + mat_edu_collapsed +
      cognitive_3_z + low_birth_weight + premature + difficult_temperament_z,
  data = regression_data,
  weights = survey_weight
)

summary_2a_s <- summary(model_2a_slope)
cat("    R² =", round(summary_2a_s$r.squared, 3),
    ", Adj. R² =", round(summary_2a_s$adj.r.squared, 3), "\n\n")

# Model 2b: Add parenting
cat("  Model 2b: Add parenting across development\n")

model_2b_slope <- lm(
  s ~ sex + ethnicity + ses_group + mat_edu_collapsed +
      cognitive_3_z + low_birth_weight + premature + difficult_temperament_z +
      harsh_early_avg_z + pos_early_avg_z + mon_adolescent_avg_z,
  data = regression_data,
  weights = survey_weight
)

summary_2b_s <- summary(model_2b_slope)
cat("    R² =", round(summary_2b_s$r.squared, 3),
    ", Adj. R² =", round(summary_2b_s$adj.r.squared, 3), "\n")
cat("    ΔR² from Model 2a:", round(summary_2b_s$r.squared - summary_2a_s$r.squared, 4), "\n")

# Test incremental R²
anova_2a_2b <- anova(model_2a_slope, model_2b_slope)
cat("    F-test for ΔR²: F(", anova_2a_2b$Df[2], ",", anova_2a_2b$Res.Df[2], ") =",
    round(anova_2a_2b$F[2], 2), ", p =",
    format.pval(anova_2a_2b$`Pr(>F)`[2], digits = 3), "\n\n")

# ------------------------------------------------------------------------------
# STEP 5: INTERACTION MODELS
# ------------------------------------------------------------------------------

cat("Step 5: Testing key interactions...\n\n")

# Interaction 1: SES × Harsh Parenting predicting slope
cat("  Interaction 1: SES × Harsh Parenting → Slope\n")
cat("  Hypothesis: Harsh parenting more detrimental in low SES contexts\n")

model_int1 <- lm(
  s ~ ses_group * harsh_early_avg_z + sex + cognitive_3_z,
  data = regression_data,
  weights = survey_weight
)

cat("    Interaction term:\n")
int1_coef <- tidy(model_int1) %>%
  filter(grepl(":", term))
print(int1_coef %>% select(term, estimate, std.error, statistic, p.value))
cat("\n")

# Interaction 2: Sex × Parenting predicting slope
cat("  Interaction 2: Sex × Positive Parenting → Slope\n")
cat("  Hypothesis: Boys and girls respond differently to positive parenting\n")

model_int2 <- lm(
  s ~ sex * pos_early_avg_z + ses_group + cognitive_3_z,
  data = regression_data,
  weights = survey_weight
)

cat("    Interaction term:\n")
int2_coef <- tidy(model_int2) %>%
  filter(grepl(":", term))
print(int2_coef %>% select(term, estimate, std.error, statistic, p.value))
cat("\n")

# ------------------------------------------------------------------------------
# STEP 6: EXTRACT AND SAVE RESULTS
# ------------------------------------------------------------------------------

cat("Step 6: Saving regression results...\n")

# Function to create clean coefficient table
create_coef_table <- function(model, model_name) {
  tidy(model, conf.int = TRUE) %>%
    mutate(
      model = model_name,
      sig = case_when(
        p.value < 0.001 ~ "***",
        p.value < 0.01 ~ "**",
        p.value < 0.05 ~ "*",
        TRUE ~ ""
      )
    ) %>%
    select(model, term, estimate, std.error, statistic, p.value, conf.low, conf.high, sig)
}

# Combine all results
all_results <- bind_rows(
  create_coef_table(model_1a_intercept, "Intercept: Baseline"),
  create_coef_table(model_1b_intercept, "Intercept: + Parenting"),
  create_coef_table(model_2a_slope, "Slope: Baseline"),
  create_coef_table(model_2b_slope, "Slope: + Parenting"),
  create_coef_table(model_int1, "Slope: SES × Harsh"),
  create_coef_table(model_int2, "Slope: Sex × Positive")
)

write_csv(all_results, file.path(tables_path, "regression_all_models.csv"))
cat("  ✓ Saved: regression_all_models.csv\n")

# Model comparison table
model_comparison <- data.frame(
  Model = c("Intercept: Baseline", "Intercept: + Parenting",
            "Slope: Baseline", "Slope: + Parenting"),
  R_squared = c(summary_1a_i$r.squared, summary_1b_i$r.squared,
                summary_2a_s$r.squared, summary_2b_s$r.squared),
  Adj_R_squared = c(summary_1a_i$adj.r.squared, summary_1b_i$adj.r.squared,
                    summary_2a_s$adj.r.squared, summary_2b_s$adj.r.squared),
  F_statistic = c(summary_1a_i$fstatistic[1], summary_1b_i$fstatistic[1],
                  summary_2a_s$fstatistic[1], summary_2b_s$fstatistic[1]),
  N = c(nobs(model_1a_intercept), nobs(model_1b_intercept),
        nobs(model_2a_slope), nobs(model_2b_slope))
)

write_csv(model_comparison, file.path(tables_path, "regression_model_comparison.csv"))
cat("  ✓ Saved: regression_model_comparison.csv\n\n")

# ------------------------------------------------------------------------------
# STEP 7: CREATE VISUALIZATIONS
# ------------------------------------------------------------------------------

cat("Step 7: Creating visualizations...\n")

# Plot 1: Coefficient plot for intercept model
cat("  Creating coefficient plot for intercept model...\n")

coef_plot_intercept <- model_1b_intercept %>%
  tidy(conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = case_when(
      term == "sexFemale" ~ "Sex: Female",
      term == "ses_groupMiddle" ~ "SES: Middle (vs Low)",
      term == "ses_groupHigh" ~ "SES: High (vs Low)",
      term == "cognitive_3_z" ~ "Cognitive Ability (z)",
      term == "harsh_early_avg_z" ~ "Harsh Parenting (z)",
      term == "pos_early_avg_z" ~ "Positive Parenting (z)",
      term == "low_birth_weightTRUE" ~ "Low Birth Weight",
      term == "prematureTRUE" ~ "Premature Birth",
      term == "difficult_temperament_z" ~ "Difficult Temperament (z)",
      TRUE ~ term
    ),
    sig = p.value < 0.05
  ) %>%
  ggplot(aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high),
                 height = 0.2, color = "gray40") +
  geom_point(aes(color = sig), size = 3) +
  scale_color_manual(values = c("gray60", "firebrick"),
                     labels = c("ns", "p < .05")) +
  labs(
    title = "Predictors of Initial Self-Control (Intercept)",
    subtitle = "Regression coefficients with 95% CIs",
    x = "Standardized Coefficient",
    y = NULL,
    color = "Significance"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(figures_path, "regression_intercept_coefs.pdf"),
       coef_plot_intercept, width = 10, height = 6)

# Plot 2: Coefficient plot for slope model
cat("  Creating coefficient plot for slope model...\n")

coef_plot_slope <- model_2b_slope %>%
  tidy(conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = case_when(
      term == "sexFemale" ~ "Sex: Female",
      term == "ses_groupMiddle" ~ "SES: Middle (vs Low)",
      term == "ses_groupHigh" ~ "SES: High (vs Low)",
      term == "cognitive_3_z" ~ "Cognitive Ability (z)",
      term == "harsh_early_avg_z" ~ "Harsh Parenting (z)",
      term == "pos_early_avg_z" ~ "Positive Parenting (z)",
      term == "mon_adolescent_avg_z" ~ "Adolescent Monitoring (z)",
      term == "low_birth_weightTRUE" ~ "Low Birth Weight",
      term == "prematureTRUE" ~ "Premature Birth",
      term == "difficult_temperament_z" ~ "Difficult Temperament (z)",
      TRUE ~ term
    ),
    sig = p.value < 0.05
  ) %>%
  ggplot(aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high),
                 height = 0.2, color = "gray40") +
  geom_point(aes(color = sig), size = 3) +
  scale_color_manual(values = c("gray60", "steelblue"),
                     labels = c("ns", "p < .05")) +
  labs(
    title = "Predictors of Self-Control Change (Slope)",
    subtitle = "Regression coefficients with 95% CIs",
    x = "Standardized Coefficient",
    y = NULL,
    color = "Significance"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(figures_path, "regression_slope_coefs.pdf"),
       coef_plot_slope, width = 10, height = 6)

cat("  ✓ Saved coefficient plots\n\n")

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------

cat("==============================================================================\n")
cat("REGRESSION ANALYSIS COMPLETE\n")
cat("==============================================================================\n\n")

cat("Models fitted:\n")
cat("  ✓ Intercept models (baseline, + parenting)\n")
cat("  ✓ Slope models (baseline, + parenting)\n")
cat("  ✓ Interaction models (SES × harsh, sex × positive)\n\n")

cat("Key findings:\n\n")

cat("INTERCEPT (Initial Level at Age 3):\n")
cat("  - Baseline model R² =", round(summary_1a_i$r.squared, 3), "\n")
cat("  - With parenting R² =", round(summary_1b_i$r.squared, 3), "\n")
cat("  - Parenting adds ΔR² =", round(summary_1b_i$r.squared - summary_1a_i$r.squared, 4),
    "(", ifelse(anova_1a_1b$`Pr(>F)`[2] < 0.05, "significant", "ns"), ")\n\n")

cat("SLOPE (Rate of Change):\n")
cat("  - Baseline model R² =", round(summary_2a_s$r.squared, 3), "\n")
cat("  - With parenting R² =", round(summary_2b_s$r.squared, 3), "\n")
cat("  - Parenting adds ΔR² =", round(summary_2b_s$r.squared - summary_2a_s$r.squared, 4),
    "(", ifelse(anova_2a_2b$`Pr(>F)`[2] < 0.05, "significant", "ns"), ")\n\n")

cat("Output files:\n")
cat("  📊 results/tables/regression_all_models.csv\n")
cat("  📊 results/tables/regression_model_comparison.csv\n")
cat("  📈 results/figures/regression_intercept_coefs.pdf\n")
cat("  📈 results/figures/regression_slope_coefs.pdf\n\n")

cat("Interpretation:\n")
cat("  - Compare R² values: How much variance explained?\n")
cat("  - Check coefficients: Which predictors matter?\n")
cat("  - Compare with SEMTree: Regression finds what SEMTree missed?\n")
cat("  - Effect sizes: Even if significant, are effects meaningful?\n\n")

cat("Next steps:\n")
cat("  1. Compare these results with SEMTree findings\n")
cat("  2. If regression finds effects SEMTree missed → SEMTree lacks power\n")
cat("  3. If neither finds effects → True null or unmeasured moderators\n")
cat("  4. Try two-stage SEMTree with these factor scores\n\n")

cat("==============================================================================\n\n")
