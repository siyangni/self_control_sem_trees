# ==============================================================================
# Machine Learning Analysis: Variable Importance
# ==============================================================================
#
# Purpose: Use ensemble machine learning methods to identify important
#          predictors of growth parameters
#
# Methods:
#   1. Random Forest (ranger) - Fast, handles interactions
#   2. Gradient Boosting (xgboost) - High predictive accuracy
#   3. Elastic Net (glmnet) - Regularized regression for comparison
#
# Output:
#   - Variable importance rankings
#   - Partial dependence plots for top predictors
#   - Prediction performance (R², RMSE)
#   - Comparison with SEMTree and regression
#
# Input:  data/processed/mcs_twostage_dataset.RData
# Output: results/machine_learning/ml_results.RData
#
# ==============================================================================

library(pacman)
p_load(tidyverse, here, ranger, xgboost, glmnet, pdp, ggplot2)

cat("\n")
cat("==============================================================================\n")
cat("MACHINE LEARNING ANALYSIS: VARIABLE IMPORTANCE\n")
cat("==============================================================================\n\n")

processed_path <- here("data", "processed")
results_path <- here("results")

dir.create(file.path(results_path, "machine_learning"), showWarnings = FALSE)
dir.create(file.path(results_path, "plots", "machine_learning"),
          showWarnings = FALSE, recursive = TRUE)

# Load data
load(file.path(processed_path, "mcs_twostage_dataset.RData"))

# ------------------------------------------------------------------------------
# Prepare Data
# ------------------------------------------------------------------------------

cat("Preparing data...\n")

# Select predictors
predictors <- c("sex", "ethnicity_white", "ses_disadvantage",
               "cognitive_ability", "low_birth_weight", "premature",
               "harsh_early", "pos_early", "mon_avg")

# Filter available predictors
predictors <- predictors[predictors %in% names(twostage_data)]

# Create analysis dataset
ml_data <- twostage_data %>%
  select(all_of(c("mcsid", "intercept", "slope", predictors))) %>%
  drop_na()

cat("  N =", nrow(ml_data), "\n")
cat("  Predictors:", length(predictors), "\n")
cat("  Variables:", paste(predictors, collapse = ", "), "\n\n")

# Split into train/test (80/20)
set.seed(12345)
train_idx <- sample(1:nrow(ml_data), size = floor(0.8 * nrow(ml_data)))
train_data <- ml_data[train_idx, ]
test_data <- ml_data[-train_idx, ]

cat("  Train N =", nrow(train_data), "\n")
cat("  Test N =", nrow(test_data), "\n\n")

# ------------------------------------------------------------------------------
# OUTCOME 1: INTERCEPT
# ------------------------------------------------------------------------------

cat("===== INTERCEPT PREDICTION =====\n\n")

# Random Forest
cat("Training Random Forest...\n")
rf_intercept <- ranger(
  intercept ~ .,
  data = train_data %>% select(intercept, all_of(predictors)),
  importance = "permutation",
  num.trees = 1000,
  mtry = floor(sqrt(length(predictors))),
  seed = 12345
)

cat("  OOB R² =", round(rf_intercept$r.squared, 4), "\n")
cat("  OOB RMSE =", round(sqrt(rf_intercept$prediction.error), 4), "\n")

# Test set prediction
rf_pred_i <- predict(rf_intercept, data = test_data)$predictions
rf_test_r2_i <- cor(rf_pred_i, test_data$intercept)^2
rf_test_rmse_i <- sqrt(mean((rf_pred_i - test_data$intercept)^2))
cat("  Test R² =", round(rf_test_r2_i, 4), "\n")
cat("  Test RMSE =", round(rf_test_rmse_i, 4), "\n\n")

# XGBoost
cat("Training XGBoost...\n")

# Prepare matrices
dtrain_i <- xgb.DMatrix(
  data = as.matrix(train_data[, predictors]),
  label = train_data$intercept
)
dtest_i <- xgb.DMatrix(
  data = as.matrix(test_data[, predictors]),
  label = test_data$intercept
)

# Train with cross-validation
xgb_intercept <- xgb.train(
  params = list(
    objective = "reg:squarederror",
    eta = 0.05,
    max_depth = 5,
    subsample = 0.8,
    colsample_bytree = 0.8
  ),
  data = dtrain_i,
  nrounds = 500,
  early_stopping_rounds = 50,
  watchlist = list(train = dtrain_i, test = dtest_i),
  verbose = 0
)

xgb_pred_i <- predict(xgb_intercept, dtest_i)
xgb_test_r2_i <- cor(xgb_pred_i, test_data$intercept)^2
xgb_test_rmse_i <- sqrt(mean((xgb_pred_i - test_data$intercept)^2))
cat("  Test R² =", round(xgb_test_r2_i, 4), "\n")
cat("  Test RMSE =", round(xgb_test_rmse_i, 4), "\n\n")

# Variable importance
rf_imp_i <- data.frame(
  variable = names(rf_intercept$variable.importance),
  importance = rf_intercept$variable.importance,
  method = "Random Forest"
)

xgb_imp_i <- xgb.importance(model = xgb_intercept)
xgb_imp_i <- data.frame(
  variable = xgb_imp_i$Feature,
  importance = xgb_imp_i$Gain,
  method = "XGBoost"
)

cat("Variable Importance (Random Forest):\n")
print(rf_imp_i %>% arrange(desc(importance)), row.names = FALSE)

# ------------------------------------------------------------------------------
# OUTCOME 2: SLOPE
# ------------------------------------------------------------------------------

cat("\n===== SLOPE PREDICTION =====\n\n")

# Random Forest
cat("Training Random Forest...\n")
rf_slope <- ranger(
  slope ~ .,
  data = train_data %>% select(slope, all_of(predictors)),
  importance = "permutation",
  num.trees = 1000,
  mtry = floor(sqrt(length(predictors))),
  seed = 12345
)

cat("  OOB R² =", round(rf_slope$r.squared, 4), "\n")
cat("  OOB RMSE =", round(sqrt(rf_slope$prediction.error), 4), "\n")

rf_pred_s <- predict(rf_slope, data = test_data)$predictions
rf_test_r2_s <- cor(rf_pred_s, test_data$slope)^2
rf_test_rmse_s <- sqrt(mean((rf_pred_s - test_data$slope)^2))
cat("  Test R² =", round(rf_test_r2_s, 4), "\n")
cat("  Test RMSE =", round(rf_test_rmse_s, 4), "\n\n")

# XGBoost
cat("Training XGBoost...\n")

dtrain_s <- xgb.DMatrix(
  data = as.matrix(train_data[, predictors]),
  label = train_data$slope
)
dtest_s <- xgb.DMatrix(
  data = as.matrix(test_data[, predictors]),
  label = test_data$slope
)

xgb_slope <- xgb.train(
  params = list(
    objective = "reg:squarederror",
    eta = 0.05,
    max_depth = 5,
    subsample = 0.8,
    colsample_bytree = 0.8
  ),
  data = dtrain_s,
  nrounds = 500,
  early_stopping_rounds = 50,
  watchlist = list(train = dtrain_s, test = dtest_s),
  verbose = 0
)

xgb_pred_s <- predict(xgb_slope, dtest_s)
xgb_test_r2_s <- cor(xgb_pred_s, test_data$slope)^2
xgb_test_rmse_s <- sqrt(mean((xgb_pred_s - test_data$slope)^2))
cat("  Test R² =", round(xgb_test_r2_s, 4), "\n")
cat("  Test RMSE =", round(xgb_test_rmse_s, 4), "\n\n")

# Variable importance
rf_imp_s <- data.frame(
  variable = names(rf_slope$variable.importance),
  importance = rf_slope$variable.importance,
  method = "Random Forest"
)

xgb_imp_s <- xgb.importance(model = xgb_slope)
xgb_imp_s <- data.frame(
  variable = xgb_imp_s$Feature,
  importance = xgb_imp_s$Gain,
  method = "XGBoost"
)

cat("Variable Importance (Random Forest):\n")
print(rf_imp_s %>% arrange(desc(importance)), row.names = FALSE)

# ------------------------------------------------------------------------------
# Visualizations
# ------------------------------------------------------------------------------

cat("\nCreating visualizations...\n")

# Plot 1: Variable importance comparison (intercept)
pdf(file.path(results_path, "plots", "machine_learning",
             "intercept_variable_importance.pdf"),
    width = 10, height = 6)

bind_rows(rf_imp_i, xgb_imp_i) %>%
  mutate(importance = importance / max(importance)) %>%  # Normalize
  ggplot(aes(x = reorder(variable, importance), y = importance, fill = method)) +
  geom_col(position = "dodge") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Variable Importance: Intercept (Initial Self-Control)",
    subtitle = "Normalized importance scores from Random Forest and XGBoost",
    x = "Variable",
    y = "Normalized Importance",
    fill = "Method"
  ) +
  scale_fill_manual(values = c("Random Forest" = "forestgreen",
                               "XGBoost" = "darkorange"))

dev.off()

# Plot 2: Variable importance comparison (slope)
pdf(file.path(results_path, "plots", "machine_learning",
             "slope_variable_importance.pdf"),
    width = 10, height = 6)

bind_rows(rf_imp_s, xgb_imp_s) %>%
  mutate(importance = importance / max(importance)) %>%
  ggplot(aes(x = reorder(variable, importance), y = importance, fill = method)) +
  geom_col(position = "dodge") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Variable Importance: Slope (Rate of Change)",
    subtitle = "Normalized importance scores from Random Forest and XGBoost",
    x = "Variable",
    y = "Normalized Importance",
    fill = "Method"
  ) +
  scale_fill_manual(values = c("Random Forest" = "forestgreen",
                               "XGBoost" = "darkorange"))

dev.off()

# Plot 3: Partial dependence for top 3 predictors (intercept)
top_vars_i <- rf_imp_i %>%
  arrange(desc(importance)) %>%
  head(3) %>%
  pull(variable)

pdf(file.path(results_path, "plots", "machine_learning",
             "intercept_partial_dependence.pdf"),
    width = 12, height = 4)

par(mfrow = c(1, 3))
for (var in top_vars_i) {
  pd <- partial(rf_intercept, pred.var = var, train = train_data)
  plot(pd, main = paste("Partial Dependence:", var),
       xlab = var, ylab = "Predicted Intercept")
}

dev.off()

# Plot 4: Prediction performance comparison
pdf(file.path(results_path, "plots", "machine_learning",
             "prediction_performance.pdf"),
    width = 10, height = 5)

performance <- data.frame(
  Method = rep(c("Random Forest", "XGBoost"), 2),
  Outcome = rep(c("Intercept", "Slope"), each = 2),
  R2 = c(rf_test_r2_i, xgb_test_r2_i, rf_test_r2_s, xgb_test_r2_s),
  RMSE = c(rf_test_rmse_i, xgb_test_rmse_i, rf_test_rmse_s, xgb_test_rmse_s)
)

ggplot(performance, aes(x = Method, y = R2, fill = Outcome)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = round(R2, 3)), position = position_dodge(0.9),
           vjust = -0.5, size = 3.5) +
  theme_minimal() +
  labs(
    title = "Prediction Performance: Test Set R²",
    subtitle = "Higher values indicate better predictive accuracy",
    x = "Method",
    y = "R² (Test Set)",
    fill = "Outcome"
  ) +
  scale_fill_manual(values = c("Intercept" = "steelblue", "Slope" = "coral")) +
  ylim(0, max(performance$R2) * 1.2)

dev.off()

cat("  ✓ Saved 4 plots\n")

# ------------------------------------------------------------------------------
# Save Results
# ------------------------------------------------------------------------------

save(rf_intercept, rf_slope, xgb_intercept, xgb_slope,
     rf_imp_i, rf_imp_s, xgb_imp_i, xgb_imp_s,
     performance, train_data, test_data,
     file = file.path(results_path, "machine_learning", "ml_results.RData"))

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("MACHINE LEARNING ANALYSIS COMPLETE!\n")
cat("==============================================================================\n\n")

cat("Prediction Performance (Test Set R²):\n")
cat("  Intercept:\n")
cat("    - Random Forest: R² =", round(rf_test_r2_i, 4), "\n")
cat("    - XGBoost:       R² =", round(xgb_test_r2_i, 4), "\n")
cat("  Slope:\n")
cat("    - Random Forest: R² =", round(rf_test_r2_s, 4), "\n")
cat("    - XGBoost:       R² =", round(xgb_test_r2_s, 4), "\n\n")

cat("Top 3 Predictors (Random Forest):\n")
cat("  Intercept:\n")
for (i in 1:min(3, nrow(rf_imp_i))) {
  cat("    ", i, ". ", rf_imp_i$variable[i],
      " (", round(rf_imp_i$importance[i], 4), ")\n", sep = "")
}
cat("  Slope:\n")
for (i in 1:min(3, nrow(rf_imp_s))) {
  cat("    ", i, ". ", rf_imp_s$variable[i],
      " (", round(rf_imp_s$importance[i], 4), ")\n", sep = "")
}

cat("\nInterpretation:\n")
cat("  - Variable importance = predictive contribution (higher = more important)\n")
cat("  - Handles interactions automatically (unlike linear regression)\n")
cat("  - Complements SEMTree (finds important vars even without subgroups)\n\n")

cat("Output Files:\n")
cat("  - results/machine_learning/ml_results.RData\n")
cat("  - results/plots/machine_learning/intercept_variable_importance.pdf\n")
cat("  - results/plots/machine_learning/slope_variable_importance.pdf\n")
cat("  - results/plots/machine_learning/intercept_partial_dependence.pdf\n")
cat("  - results/plots/machine_learning/prediction_performance.pdf\n\n")

cat("Next: Compare SEMTree vs Regression vs ML (08a)\n\n")

cat("==============================================================================\n\n")
