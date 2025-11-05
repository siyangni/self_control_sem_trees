# ==============================================================================
# Comprehensive Visualization Suite
# ==============================================================================
#
# Purpose: Create publication-ready visualizations of key findings
#
# Visualizations:
#   1. Individual trajectories (spaghetti plots)
#   2. Mean trajectories by covariate levels
#   3. Growth parameter distributions
#   4. Covariate correlation heatmap
#   5. Effect size dashboard
#   6. Method comparison summary
#
# Input:  All results from previous analyses
# Output: High-quality PDFs in results/plots/publication/
#
# ==============================================================================

library(pacman)
p_load(tidyverse, here, ggplot2, patchwork, corrplot, RColorBrewer)

cat("\n")
cat("==============================================================================\n")
cat("COMPREHENSIVE VISUALIZATION SUITE\n")
cat("==============================================================================\n\n")

processed_path <- here("data", "processed")
results_path <- here("results")

dir.create(file.path(results_path, "plots", "publication"),
          showWarnings = FALSE, recursive = TRUE)

# Load data
load(file.path(processed_path, "mcs_twostage_dataset.RData"))
load(file.path(processed_path, "mcs_factor_scores.RData"))

# ------------------------------------------------------------------------------
# FIGURE 1: Individual Trajectories (Spaghetti Plot)
# ------------------------------------------------------------------------------

cat("Creating Figure 1: Individual trajectories...\n")

# Sample subset for visualization (too many lines otherwise)
set.seed(123)
sample_ids <- sample(twostage_data$mcsid, size = min(200, nrow(twostage_data)))

traj_data <- twostage_data %>%
  filter(mcsid %in% sample_ids) %>%
  select(mcsid, starts_with("SC_")) %>%
  pivot_longer(cols = starts_with("SC_"),
              names_to = "age",
              values_to = "sc") %>%
  mutate(age = as.numeric(str_extract(age, "\\d+")))

pdf(file.path(results_path, "plots", "publication", "fig1_trajectories.pdf"),
    width = 10, height = 6)

ggplot(traj_data, aes(x = age, y = sc, group = mcsid)) +
  geom_line(alpha = 0.2, color = "steelblue") +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
              color = "red", size = 1.5) +
  stat_summary(aes(group = 1), fun.data = mean_se, geom = "ribbon",
              alpha = 0.2, fill = "red") +
  theme_minimal() +
  labs(
    title = "Individual Self-Control Trajectories (Ages 3-17)",
    subtitle = paste("Sample of", length(sample_ids), "individuals; Red line = population mean"),
    x = "Age (years)",
    y = "Self-Control (Factor Score)",
    caption = "MCS Study"
  ) +
  scale_x_continuous(breaks = c(3, 5, 7, 11, 14, 17))

dev.off()

# ------------------------------------------------------------------------------
# FIGURE 2: Trajectories by Key Covariates
# ------------------------------------------------------------------------------

cat("Creating Figure 2: Trajectories by covariates...\n")

# Prepare data by parenting groups
traj_by_harsh <- twostage_data %>%
  mutate(harsh_group = ifelse(harsh_early <= median(harsh_early, na.rm = TRUE),
                              "Low Harsh Parenting", "High Harsh Parenting")) %>%
  select(mcsid, harsh_group, starts_with("SC_")) %>%
  pivot_longer(cols = starts_with("SC_"),
              names_to = "age", values_to = "sc") %>%
  mutate(age = as.numeric(str_extract(age, "\\d+")))

pdf(file.path(results_path, "plots", "publication", "fig2_trajectories_by_parenting.pdf"),
    width = 10, height = 6)

ggplot(traj_by_harsh, aes(x = age, y = sc, color = harsh_group, fill = harsh_group)) +
  stat_summary(fun = mean, geom = "line", size = 1.2) +
  stat_summary(fun.data = mean_se, geom = "ribbon", alpha = 0.2, color = NA) +
  theme_minimal() +
  labs(
    title = "Self-Control Trajectories by Harsh Parenting Exposure",
    subtitle = "Mean trajectories with 95% CI",
    x = "Age (years)",
    y = "Self-Control (Factor Score)",
    color = "Parenting Group",
    fill = "Parenting Group"
  ) +
  scale_x_continuous(breaks = c(3, 5, 7, 11, 14, 17)) +
  scale_color_manual(values = c("Low Harsh Parenting" = "forestgreen",
                                "High Harsh Parenting" = "coral")) +
  scale_fill_manual(values = c("Low Harsh Parenting" = "forestgreen",
                               "High Harsh Parenting" = "coral"))

dev.off()

# ------------------------------------------------------------------------------
# FIGURE 3: Growth Parameter Distributions
# ------------------------------------------------------------------------------

cat("Creating Figure 3: Growth parameter distributions...\n")

pdf(file.path(results_path, "plots", "publication", "fig3_growth_parameters.pdf"),
    width = 12, height = 5)

p1 <- ggplot(twostage_data, aes(x = intercept)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white", alpha = 0.8) +
  geom_vline(xintercept = mean(twostage_data$intercept, na.rm = TRUE),
            linetype = "dashed", color = "red", size = 1) +
  theme_minimal() +
  labs(
    title = "Intercept Distribution",
    subtitle = paste("Mean =", round(mean(twostage_data$intercept, na.rm = TRUE), 2)),
    x = "Intercept (Initial Self-Control)",
    y = "Count"
  )

p2 <- ggplot(twostage_data, aes(x = slope)) +
  geom_histogram(bins = 30, fill = "coral", color = "white", alpha = 0.8) +
  geom_vline(xintercept = mean(twostage_data$slope, na.rm = TRUE),
            linetype = "dashed", color = "red", size = 1) +
  theme_minimal() +
  labs(
    title = "Slope Distribution",
    subtitle = paste("Mean =", round(mean(twostage_data$slope, na.rm = TRUE), 3)),
    x = "Slope (Rate of Change)",
    y = "Count"
  )

p3 <- ggplot(twostage_data, aes(x = intercept, y = slope)) +
  geom_point(alpha = 0.3, color = "steelblue") +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  theme_minimal() +
  labs(
    title = "Intercept-Slope Relationship",
    subtitle = paste("r =", round(cor(twostage_data$intercept,
                                     twostage_data$slope, use = "complete.obs"), 3)),
    x = "Intercept",
    y = "Slope"
  )

p1 + p2 + p3

dev.off()

# ------------------------------------------------------------------------------
# FIGURE 4: Covariate Correlation Heatmap
# ------------------------------------------------------------------------------

cat("Creating Figure 4: Covariate correlations...\n")

# Select numeric covariates
cor_vars <- c("intercept", "slope", "sex", "ses_disadvantage",
             "cognitive_ability", "harsh_early", "pos_early", "mon_avg")
cor_vars <- cor_vars[cor_vars %in% names(twostage_data)]

cor_matrix <- cor(twostage_data[, cor_vars], use = "pairwise.complete.obs")

pdf(file.path(results_path, "plots", "publication", "fig4_correlations.pdf"),
    width = 10, height = 10)

corrplot(cor_matrix, method = "color", type = "upper",
        tl.col = "black", tl.srt = 45,
        col = colorRampPalette(c("blue", "white", "red"))(200),
        addCoef.col = "black", number.cex = 0.7,
        title = "Covariate Correlation Matrix",
        mar = c(0, 0, 2, 0))

dev.off()

# ------------------------------------------------------------------------------
# FIGURE 5: Effect Size Dashboard (All Methods)
# ------------------------------------------------------------------------------

cat("Creating Figure 5: Effect size dashboard...\n")

# Load comparison results
if (file.exists(file.path(results_path, "method_comparison", "comparison_summary.RData"))) {
  load(file.path(results_path, "method_comparison", "comparison_summary.RData"))

  pdf(file.path(results_path, "plots", "publication", "fig5_effect_size_dashboard.pdf"),
      width = 14, height = 8)

  # Intercept panel
  p_int <- intercept_comparison %>%
    select(covariate, semtree_d, reg_beta, rf_importance) %>%
    pivot_longer(cols = -covariate, names_to = "method", values_to = "effect") %>%
    mutate(
      method = recode(method,
                     "semtree_d" = "SEMTree",
                     "reg_beta" = "Regression",
                     "rf_importance" = "ML"),
      effect_abs = abs(effect)
    ) %>%
    ggplot(aes(x = reorder(covariate, effect_abs), y = effect, fill = method)) +
    geom_col(position = "dodge") +
    coord_flip() +
    theme_minimal() +
    labs(title = "Intercept: Effect Sizes", x = "", y = "Effect Size", fill = "Method") +
    scale_fill_manual(values = c("SEMTree" = "purple", "Regression" = "steelblue",
                                 "ML" = "forestgreen"))

  # Slope panel
  p_slope <- slope_comparison %>%
    select(covariate, semtree_d, reg_beta, rf_importance) %>%
    pivot_longer(cols = -covariate, names_to = "method", values_to = "effect") %>%
    mutate(
      method = recode(method,
                     "semtree_d" = "SEMTree",
                     "reg_beta" = "Regression",
                     "rf_importance" = "ML"),
      effect_abs = abs(effect)
    ) %>%
    ggplot(aes(x = reorder(covariate, effect_abs), y = effect, fill = method)) +
    geom_col(position = "dodge") +
    coord_flip() +
    theme_minimal() +
    labs(title = "Slope: Effect Sizes", x = "", y = "Effect Size", fill = "Method") +
    scale_fill_manual(values = c("SEMTree" = "purple", "Regression" = "coral",
                                 "ML" = "forestgreen"))

  p_int + p_slope + plot_layout(guides = "collect")

  dev.off()
}

# ------------------------------------------------------------------------------
# FIGURE 6: Summary Figure (For presentations)
# ------------------------------------------------------------------------------

cat("Creating Figure 6: Summary figure...\n")

pdf(file.path(results_path, "plots", "publication", "fig6_summary.pdf"),
    width = 16, height = 10)

# 4-panel summary
p1 <- ggplot(traj_by_harsh, aes(x = age, y = sc, color = harsh_group)) +
  stat_summary(fun = mean, geom = "line", size = 1.2) +
  theme_minimal() +
  labs(title = "A. Trajectories by Parenting", x = "Age", y = "Self-Control") +
  scale_color_manual(values = c("forestgreen", "coral"), name = "") +
  theme(legend.position = "bottom")

p2 <- ggplot(twostage_data, aes(x = intercept, y = slope)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", color = "red") +
  theme_minimal() +
  labs(title = "B. Intercept-Slope Correlation", x = "Intercept", y = "Slope")

# Load regression results for panel 3
if (file.exists(file.path(results_path, "regression", "intercept_slope_regression.RData"))) {
  load(file.path(results_path, "regression", "intercept_slope_regression.RData"))

  p3 <- m1_results %>%
    filter(term != "(Intercept)") %>%
    mutate(sig = ifelse(p.value < 0.05, "Sig", "NS")) %>%
    ggplot(aes(x = reorder(term, abs(std_beta)), y = std_beta, fill = sig)) +
    geom_col() +
    coord_flip() +
    theme_minimal() +
    labs(title = "C. Intercept Predictors (Regression)", x = "", y = "β") +
    scale_fill_manual(values = c("Sig" = "steelblue", "NS" = "gray70"), name = "")

  p4 <- m2_results %>%
    filter(term != "(Intercept)") %>%
    mutate(sig = ifelse(p.value < 0.05, "Sig", "NS")) %>%
    ggplot(aes(x = reorder(term, abs(std_beta)), y = std_beta, fill = sig)) +
    geom_col() +
    coord_flip() +
    theme_minimal() +
    labs(title = "D. Slope Predictors (Regression)", x = "", y = "β") +
    scale_fill_manual(values = c("Sig" = "coral", "NS" = "gray70"), name = "")

  (p1 + p2) / (p3 + p4)
}

dev.off()

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("VISUALIZATION SUITE COMPLETE!\n")
cat("==============================================================================\n\n")

cat("Generated Figures:\n")
cat("  1. fig1_trajectories.pdf - Individual spaghetti plots\n")
cat("  2. fig2_trajectories_by_parenting.pdf - Mean trajectories by parenting\n")
cat("  3. fig3_growth_parameters.pdf - Intercept/slope distributions\n")
cat("  4. fig4_correlations.pdf - Covariate correlation heatmap\n")
cat("  5. fig5_effect_size_dashboard.pdf - Cross-method effect sizes\n")
cat("  6. fig6_summary.pdf - 4-panel summary figure\n\n")

cat("All figures saved to: results/plots/publication/\n\n")

cat("==============================================================================\n\n")
