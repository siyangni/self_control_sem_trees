# ============================================================================
# Example Analysis Using crimeTrajec Package
# ============================================================================
# This script demonstrates a complete trajectory modeling workflow
# using the crimeTrajec package

# Load required packages
library(crimeTrajec)

# ============================================================================
# 1. LOAD AND EXPLORE DATA
# ============================================================================

# Load the example crime dataset
data(crime_data)

# Basic exploration
cat("Dataset dimensions:\n")
print(dim(crime_data))

cat("\nFirst few rows:\n")
print(head(crime_data))

cat("\nSummary statistics:\n")
print(summary(crime_data))

# Check the number of unique individuals and time points
cat("\nNumber of individuals:", length(unique(crime_data$id)), "\n")
cat("Number of time points:", length(unique(crime_data$time)), "\n")

# Visualize some raw trajectories
par(mfrow = c(1, 1), mar = c(4, 4, 3, 1))
plot(range(crime_data$age), range(crime_data$offenses),
     type = "n", xlab = "Age", ylab = "Number of Offenses",
     main = "Sample of Individual Offense Trajectories")

# Plot first 30 individuals
for(i in 1:min(30, length(unique(crime_data$id)))) {
  ind_data <- crime_data[crime_data$id == i, ]
  lines(ind_data$age, ind_data$offenses,
        col = rgb(0, 0, 0, 0.4), lwd = 0.8)
}

# ============================================================================
# 2. MODEL SELECTION: DETERMINE NUMBER OF GROUPS
# ============================================================================

cat("\n\n============================================\n")
cat("PHASE 1: MODEL SELECTION\n")
cat("============================================\n\n")

# Compare models with 1-5 groups using BIC
selection_bic <- selectNumGroups(
  data = crime_data,
  id = "id",
  time = "time",
  outcome = "offenses",
  max_groups = 5,
  criteria = "BIC",
  dist = "zip",
  degree = 3,
  verbose = TRUE
)

# View results
print(selection_bic)

# Plot BIC curve
plot(selection_bic, criterion = "BIC",
     main = "Model Selection: BIC Comparison")

# Optional: More rigorous model selection with cross-validation
# (Commented out because it's computationally intensive)
# selection_cv <- selectNumGroups(
#   data = crime_data,
#   id = "id",
#   time = "time",
#   outcome = "offenses",
#   max_groups = 4,
#   criteria = c("BIC", "CVE"),
#   cv_folds = 5,
#   parallel = TRUE,
#   verbose = TRUE
# )
# print(selection_cv)
# plot(selection_cv, criterion = "all")

# ============================================================================
# 3. FIT FINAL MODEL
# ============================================================================

cat("\n\n============================================\n")
cat("PHASE 2: FITTING FINAL MODEL\n")
cat("============================================\n\n")

# Based on BIC, fit a 3-group model
model_3groups <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "time",
  outcome = "offenses",
  dist = "zip",
  groups = 3,
  degree = 3,
  zero_inflated = TRUE,
  verbose = TRUE
)

# View comprehensive results
print(model_3groups)
cat("\n")
summary(model_3groups)

# ============================================================================
# 4. VISUALIZE TRAJECTORIES
# ============================================================================

cat("\n\n============================================\n")
cat("PHASE 3: VISUALIZATION\n")
cat("============================================\n\n")

# Basic trajectory plot
par(mfrow = c(1, 1), mar = c(4, 4, 3, 1))
plot(model_3groups,
     main = "Estimated Trajectory Groups",
     xlab = "Age",
     ylab = "Expected Number of Offenses",
     include_ci = TRUE)

# Plot with individual data overlay
plot(model_3groups,
     main = "Trajectories with Individual Data",
     xlab = "Age",
     ylab = "Number of Offenses",
     include_ci = TRUE,
     include_data = TRUE,
     n_sample = 50)

# ============================================================================
# 5. EXAMINE GROUP ASSIGNMENTS
# ============================================================================

cat("\n\n============================================\n")
cat("PHASE 4: GROUP ASSIGNMENTS\n")
cat("============================================\n\n")

# Get group assignments
group_assignments <- model_3groups$group_assignments
cat("Group membership distribution:\n")
print(table(group_assignments))
cat("\n")

# Posterior probabilities
cat("Summary of posterior probabilities:\n")
cat("Mean maximum posterior probability:",
    mean(apply(model_3groups$posterior, 1, max)), "\n")
cat("Minimum maximum posterior probability:",
    min(apply(model_3groups$posterior, 1, max)), "\n")
cat("\n")

# Individuals with uncertain group membership
uncertain_threshold <- 0.70
uncertain_ids <- which(apply(model_3groups$posterior, 1, max) < uncertain_threshold)
cat("Number of individuals with uncertain membership (max P <", uncertain_threshold, "):",
    length(uncertain_ids), "\n")

if (length(uncertain_ids) > 0) {
  cat("\nFirst few uncertain individuals:\n")
  print(head(model_3groups$posterior[uncertain_ids, ]))
}

# ============================================================================
# 6. PREDICTIONS
# ============================================================================

cat("\n\n============================================\n")
cat("PHASE 5: PREDICTIONS\n")
cat("============================================\n\n")

# Posterior probabilities for all individuals
post_probs <- predict(model_3groups, type = "posterior")
cat("Posterior probabilities (first 5 individuals):\n")
print(head(post_probs, 5))
cat("\n")

# Group assignments
predicted_groups <- predict(model_3groups, type = "class")
cat("Predicted group assignments:\n")
print(table(predicted_groups))
cat("\n")

# Predicted trajectories
pred_trajectories <- predict(model_3groups, type = "trajectory")
cat("Predicted trajectory values (first 10 rows):\n")
print(head(pred_trajectories, 10))

# ============================================================================
# 7. MODEL WITH COVARIATES
# ============================================================================

cat("\n\n============================================\n")
cat("PHASE 6: COVARIATE EFFECTS\n")
cat("============================================\n\n")

# Fit model with covariates predicting group membership
model_with_cov <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "time",
  outcome = "offenses",
  dist = "zip",
  groups = 3,
  degree = 3,
  group_cov = ~sex + ses,
  verbose = TRUE
)

# View results
print(model_with_cov)
summary(model_with_cov)

# Compare BIC with and without covariates
cat("\n\nModel comparison:\n")
cat("Model without covariates - BIC:", model_3groups$BIC, "\n")
cat("Model with covariates - BIC:", model_with_cov$BIC, "\n")
cat("Difference:", model_3groups$BIC - model_with_cov$BIC, "\n")
if (model_with_cov$BIC < model_3groups$BIC) {
  cat("=> Covariates improve model fit\n")
} else {
  cat("=> Covariates do not substantially improve fit\n")
}

# ============================================================================
# 8. ALTERNATIVE SPECIFICATIONS
# ============================================================================

cat("\n\n============================================\n")
cat("PHASE 7: SENSITIVITY ANALYSES\n")
cat("============================================\n\n")

# Try different polynomial degrees
cat("Testing different polynomial degrees...\n\n")

model_linear <- fitTrajectory(
  data = crime_data, id = "id", time = "time", outcome = "offenses",
  groups = 3, degree = 1, dist = "zip", verbose = FALSE
)

model_quadratic <- fitTrajectory(
  data = crime_data, id = "id", time = "time", outcome = "offenses",
  groups = 3, degree = 2, dist = "zip", verbose = FALSE
)

cat("Comparison of polynomial degrees:\n")
cat("Linear (degree=1)   - BIC:", model_linear$BIC, "\n")
cat("Quadratic (degree=2) - BIC:", model_quadratic$BIC, "\n")
cat("Cubic (degree=3)     - BIC:", model_3groups$BIC, "\n")
cat("\n")

best_degree <- which.min(c(model_linear$BIC, model_quadratic$BIC, model_3groups$BIC))
cat("Best model by BIC: degree =", best_degree, "\n")

# ============================================================================
# 9. EXPORT RESULTS
# ============================================================================

cat("\n\n============================================\n")
cat("PHASE 8: EXPORTING RESULTS\n")
cat("============================================\n\n")

# Create a results summary
results_summary <- data.frame(
  Group = 1:3,
  Proportion = model_3groups$group_probs,
  N = as.vector(table(model_3groups$group_assignments))
)

cat("Group summary:\n")
print(results_summary)

# Save results (uncomment to save)
# save(model_3groups, file = "trajectory_model_results.RData")
# write.csv(results_summary, file = "group_summary.csv", row.names = FALSE)

# Save trajectory coefficients
coef_df <- as.data.frame(model_3groups$coefficients)
colnames(coef_df) <- paste0("beta_", 0:(ncol(coef_df)-1))
coef_df$Group <- 1:nrow(coef_df)
cat("\nTrajectory coefficients:\n")
print(coef_df)

# write.csv(coef_df, file = "trajectory_coefficients.csv", row.names = FALSE)

# Save individual posterior probabilities and assignments
individual_results <- data.frame(
  id = unique(crime_data$id),
  group_assignment = model_3groups$group_assignments,
  max_posterior_prob = apply(model_3groups$posterior, 1, max),
  model_3groups$posterior
)
colnames(individual_results)[4:6] <- paste0("P_Group", 1:3)

cat("\nIndividual classifications (first 10):\n")
print(head(individual_results, 10))

# write.csv(individual_results, file = "individual_classifications.csv", row.names = FALSE)

# ============================================================================
# ANALYSIS COMPLETE
# ============================================================================

cat("\n\n============================================\n")
cat("ANALYSIS COMPLETE\n")
cat("============================================\n\n")

cat("Summary of findings:\n")
cat("- Optimal number of groups:", selection_bic$best_model$BIC, "\n")
cat("- Model BIC:", model_3groups$BIC, "\n")
cat("- Model converged:", model_3groups$converged, "\n")
cat("- Mean classification certainty:",
    round(mean(apply(model_3groups$posterior, 1, max)), 3), "\n")
cat("\nGroup descriptions:\n")
cat("  Group 1 (", round(model_3groups$group_probs[1]*100, 1), "%): ",
    "Low-rate desistors\n", sep="")
cat("  Group 2 (", round(model_3groups$group_probs[2]*100, 1), "%): ",
    "Adolescence-peaked offenders\n", sep="")
cat("  Group 3 (", round(model_3groups$group_probs[3]*100, 1), "%): ",
    "Chronic high-rate offenders\n", sep="")

cat("\n\nFor more information, see:\n")
cat("  ?fitTrajectory\n")
cat("  ?selectNumGroups\n")
cat("  vignette('crimeTrajec-vignette')\n\n")
