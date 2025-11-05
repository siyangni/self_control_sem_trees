# ==============================================================================
# Latent Growth Mixture Models (GMM) - Extension of LGBM
# ==============================================================================
#
# This script extends the second-order latent growth basis model to identify
# latent classes (subpopulations) with different growth trajectories.
#
# APPROACH:
# 1. Extract factor scores from LGBM model (6 time points: ages 3-17)
# 2. Fit TRUE growth mixture models using lcmm with quadratic growth
# 3. Use gridsearch for robust convergence (100 random starts per model)
# 4. Fit 1-class (baseline), then PARALLELIZE 2-, 3-, and 4-class GMMs
# 5. Compare models using AIC, BIC, entropy, and likelihood ratio tests
# 6. Select optimal number of classes based on BIC
# 7. Describe class characteristics and visualize trajectories
#
# PARALLELIZATION:
# - Uses mclapply to fit 2-, 3-, and 4-class models simultaneously
# - Reduces computation time by ~3x compared to sequential fitting
# - Automatically detects available cores (uses all but one)
#
# MODEL SPECIFICATION:
# - Fixed effects: quadratic growth (poly(age_centered, 2))
# - Mixture: class-specific quadratic trajectories
# - Random effects: individual-specific quadratic deviations
# - idiag = TRUE for diagonal random-effects covariance (stability)
# - nwg = TRUE for class-specific residual variance
#
# PACKAGES USED:
# - lcmm: True growth mixture modeling
# - lavaan: For extracting factor scores from LGBM
# - tidyverse: Data manipulation and visualization
#
# ==============================================================================

library(pacman)
p_load(tidyverse, lavaan, lcmm, ggplot2, parallel)

# Set up parallel processing
n_cores <- max(1, detectCores() - 1)  # Use all but one core
cat(sprintf("\nParallel processing enabled with %d cores\n", n_cores))

# ==============================================================================
# STEP 1: LOAD LGBM RESULTS AND PREPARE DATA
# ==============================================================================

cat("\n==============================================================================\n")
cat("LATENT GROWTH MIXTURE MODEL ANALYSIS\n")
cat("==============================================================================\n\n")

cat("=== Loading LGBM Results ===\n")
load("/home/siyang/dissertation/lgbm_results.RData")

cat(sprintf("Loaded data: N = %d observations\n", nrow(lgbm_data)))
cat("Loaded model: fit_lgbm_survey\n")
cat(sprintf("Loaded pre-computed factor scores: %d individuals\n", nrow(factor_scores_df)))

# ==============================================================================
# STEP 2: PREPARE FACTOR SCORES FOR GROWTH MIXTURE MODELING
# ==============================================================================

cat("\n=== Preparing Factor Scores for GMM ===\n")

# Factor scores already loaded from lgbm_results.RData (pre-computed in lgbm.R)
# This avoids the slow lavPredict() call which can take several minutes

cat("Factor scores for 6 time points:\n")
cat("  SC_3 (age 3), SC_5 (age 5), SC_7 (age 7)\n")
cat("  SC_11 (age 11), SC_14 (age 14), SC_17 (age 17)\n")

# Create long format for lcmm
factor_scores_long <- factor_scores_df %>%
  pivot_longer(
    cols = starts_with("SC_"),
    names_to = "wave",
    values_to = "self_control"
  ) %>%
  mutate(
    age = case_when(
      wave == "SC_3" ~ 3,
      wave == "SC_5" ~ 5,
      wave == "SC_7" ~ 7,
      wave == "SC_11" ~ 11,
      wave == "SC_14" ~ 14,
      wave == "SC_17" ~ 17
    ),
    age_centered = age - 3  # Center at age 3
  )

cat(sprintf("\nPrepared long format data: %d observations\n", nrow(factor_scores_long)))

# Add survey weights
factor_scores_long <- factor_scores_long %>%
  left_join(lgbm_data %>% select(mcsid, govwt1), by = c("id" = "mcsid"))

# Convert id to numeric for lcmm (required by hlme)
# Create a numeric ID mapping
id_mapping <- data.frame(
  original_id = unique(factor_scores_long$id),
  numeric_id = 1:length(unique(factor_scores_long$id))
)

factor_scores_long <- factor_scores_long %>%
  left_join(id_mapping, by = c("id" = "original_id")) %>%
  rename(id_original = id, id = numeric_id)

cat(sprintf("Converted IDs to numeric format (required by lcmm)\n"))

# ==============================================================================
# STEP 3: FIT TRUE GROWTH MIXTURE MODELS USING LCMM
# ==============================================================================

cat("\n=== Fitting Growth Mixture Models ===\n\n")
cat("Using lcmm package for true growth mixture modeling\n")
cat("Model specification: Quadratic growth with class-specific trajectories\n\n")

# Ensure factor_scores_long has proper structure
cat("Data structure:\n")
cat(sprintf("  N individuals: %d\n", length(unique(factor_scores_long$id))))
cat(sprintf("  N observations: %d\n", nrow(factor_scores_long)))
cat(sprintf("  Time points: %s\n\n", 
            paste(sort(unique(factor_scores_long$age)), collapse = ", ")))

# ==============================================================================
# STEP 3A: FIT 1-CLASS MODEL (BASELINE)
# ==============================================================================

cat("=== Step 1: Fitting 1-class model (baseline) ===\n")
cat("This provides stable starting values for mixture models\n\n")

gmm_1class <- hlme(
  fixed   = self_control ~ poly(age_centered, 2, raw = TRUE),
  random  = ~ poly(age_centered, 2, raw = TRUE),
  subject = 'id',
  data    = factor_scores_long,
  idiag   = TRUE,   # diagonal random-effects covariance (helps stability)
  nwg     = FALSE,  # no class-specific variance (only 1 class)
  verbose = FALSE
)

cat(sprintf("1-class model converged (code: %d)\n", gmm_1class$conv))
cat(sprintf("  Log-likelihood: %.2f\n", gmm_1class$loglik))
cat(sprintf("  BIC: %.2f\n", gmm_1class$BIC))
cat(sprintf("  Number of parameters: %d\n\n", length(gmm_1class$best)))

# ==============================================================================
# STEP 3B: FIT 2-4 CLASS MODELS IN PARALLEL WITH GRIDSEARCH
# ==============================================================================

cat("=== Step 2: Fitting 2-4 class models in parallel ===\n")
cat(sprintf("Using %d cores for parallel processing\n", n_cores))
cat("Each model uses 100 random starts with gridsearch\n")
cat("This will take several minutes...\n\n")

# Function to fit a GMM for a given number of classes
fit_gmm_class <- function(nclass, baseline_model, data_long) {
  # Note: cat() doesn't work well in mclapply, output goes to dev/null
  start_time <- Sys.time()
  
  model <- tryCatch({
    gridsearch(
      m = hlme(
        fixed   = self_control ~ poly(age_centered, 2, raw = TRUE),
        mixture = ~ poly(age_centered, 2, raw = TRUE),
        random  = ~ poly(age_centered, 2, raw = TRUE),
        subject = 'id',
        ng      = nclass,
        data    = data_long,
        idiag   = TRUE,
        nwg     = TRUE,
        B       = baseline_model$best
      ),
      rep     = 100,
      maxiter = 30,
      minit   = baseline_model
    )
  }, error = function(e) {
    return(list(error = paste("Error in", nclass, "-class model:", e$message)))
  })
  
  end_time <- Sys.time()
  elapsed <- round(difftime(end_time, start_time, units = "mins"), 2)
  
  # Add timing and class info to model object
  if (!is.null(model) && !("error" %in% names(model))) {
    model$nclass <- nclass
    model$elapsed_time <- elapsed
  }
  
  return(model)
}

# Fit 2-4 class models in parallel
cat("Fitting models in parallel...\n\n")
parallel_start <- Sys.time()

# Use mclapply on Unix/Linux/Mac, lapply on Windows
if (.Platform$OS.type == "unix") {
  cat("Using parallel processing (Unix/Linux/Mac)\n")
  gmm_models_list <- mclapply(
    X = 2:4,
    FUN = function(k) fit_gmm_class(k, gmm_1class, factor_scores_long),
    mc.cores = min(n_cores, 3)  # Use up to 3 cores for 3 models
  )
} else {
  cat("Using sequential processing (Windows - mclapply not supported)\n")
  cat("Consider using Linux/Mac or WSL for parallel processing\n\n")
  gmm_models_list <- lapply(
    X = 2:4,
    FUN = function(k) fit_gmm_class(k, gmm_1class, factor_scores_long)
  )
}

parallel_end <- Sys.time()
total_time <- round(difftime(parallel_end, parallel_start, units = "mins"), 2)

# Extract models
gmm_2class <- gmm_models_list[[1]]
gmm_3class <- gmm_models_list[[2]]
gmm_4class <- gmm_models_list[[3]]

# Check for errors and report results
cat("\n=== Model Fitting Results ===\n\n")

for (i in 1:3) {
  model <- gmm_models_list[[i]]
  nclass <- i + 1
  
  if (!is.null(model) && "error" %in% names(model)) {
    cat(sprintf("%d-class model: ERROR - %s\n", nclass, model$error))
  } else if (!is.null(model)) {
    cat(sprintf("%d-class model: SUCCESS\n", nclass))
    cat(sprintf("  Convergence code: %d\n", model$conv))
    cat(sprintf("  Log-likelihood: %.2f\n", model$loglik))
    cat(sprintf("  BIC: %.2f\n", model$BIC))
    cat(sprintf("  Time: %.2f minutes\n\n", model$elapsed_time))
  } else {
    cat(sprintf("%d-class model: FAILED (NULL result)\n\n", nclass))
  }
}

if (.Platform$OS.type == "unix") {
  cat(sprintf("Total parallel execution time: %.2f minutes\n", total_time))
  cat("Note: Sequential fitting would have taken ~3x longer.\n\n")
} else {
  cat(sprintf("Total execution time: %.2f minutes (sequential)\n\n", total_time))
}

# ==============================================================================
# STEP 4: EXTRACT FIT STATISTICS
# ==============================================================================

cat("\n=== Extracting Fit Statistics ===\n\n")

# Function to extract fit statistics from lcmm models
extract_fit_stats <- function(model, nclass) {
  if (is.null(model)) {
    return(data.frame(
      n_classes = nclass,
      converged = FALSE,
      conv_code = NA,
      logLik = NA,
      AIC = NA,
      BIC = NA,
      n_params = NA
    ))
  }
  
  # Check convergence (codes 1, 2, 3 indicate convergence)
  converged <- model$conv %in% c(1, 2, 3)
  
  # Extract fit indices from lcmm
  loglik <- model$loglik
  aic <- model$AIC
  bic <- model$BIC
  n_params <- length(model$best)
  
  data.frame(
    n_classes = nclass,
    converged = converged,
    conv_code = model$conv,
    logLik = loglik,
    AIC = aic,
    BIC = bic,
    n_params = n_params
  )
}

# Extract fit statistics for all models
fit_comparison <- bind_rows(
  extract_fit_stats(gmm_1class, 1),
  extract_fit_stats(gmm_2class, 2),
  extract_fit_stats(gmm_3class, 3),
  extract_fit_stats(gmm_4class, 4)
)

# Calculate relative fit indices
# Note: For lcmm, BIC is calculated so that HIGHER values are better
fit_comparison <- fit_comparison %>%
  mutate(
    delta_AIC = AIC - min(AIC, na.rm = TRUE),
    delta_BIC = BIC - max(BIC, na.rm = TRUE)  # distance from best (highest)
  )

cat("Fit Statistics Summary:\n")
cat("Note: For lcmm BIC, HIGHER is better\n\n")
print(fit_comparison %>% 
        select(n_classes, converged, conv_code, logLik, AIC, BIC, n_params), 
      row.names = FALSE)

cat("\n\nRelative Fit:\n")
cat("  delta_AIC: distance from best (lower is better)\n")
cat("  delta_BIC: distance from best (closer to 0 is better)\n\n")
print(fit_comparison %>% 
        select(n_classes, delta_AIC, delta_BIC), 
      row.names = FALSE)

# ==============================================================================
# STEP 5: CALCULATE ENTROPY FOR CLASSIFICATION QUALITY
# ==============================================================================

cat("\n=== Classification Quality (Entropy) ===\n\n")

# Function to calculate entropy from lcmm models
calculate_entropy <- function(model) {
  if (is.null(model) || model$ng == 1) {
    return(NA)
  }
  
  # Get posterior probabilities from lcmm
  # pprob contains: [id columns], class, prob_class1, prob_class2, ...
  posterior <- as.matrix(model$pprob[, paste0("prob", 1:model$ng)])
  
  # Calculate entropy
  # E = 1 - (sum of -p*log(p) across all individuals and classes) / (N * log(K))
  log_post <- log(posterior + 1e-10)  # Add small constant to avoid log(0)
  entropy_terms <- -posterior * log_post
  sum_entropy <- sum(entropy_terms)
  n <- nrow(posterior)
  k <- model$ng
  
  entropy <- 1 - (sum_entropy / (n * log(k)))
  
  return(entropy)
}

# Calculate entropy for each model
entropy_results <- data.frame(
  n_classes = 1:4,
  entropy = c(
    calculate_entropy(gmm_1class),
    calculate_entropy(gmm_2class),
    calculate_entropy(gmm_3class),
    calculate_entropy(gmm_4class)
  )
)

cat("Entropy (higher is better, > 0.80 is good):\n\n")
print(entropy_results, row.names = FALSE)

# ==============================================================================
# STEP 6: CALCULATE AVERAGE POSTERIOR PROBABILITIES
# ==============================================================================

cat("\n=== Average Posterior Probabilities ===\n\n")

calculate_avg_pp <- function(model) {
  if (is.null(model) || model$ng == 1) {
    return(NULL)
  }
  
  # Get class membership and posterior probabilities from lcmm
  pprob_data <- model$pprob
  class_membership <- pprob_data$class
  posterior <- as.matrix(pprob_data[, paste0("prob", 1:model$ng)])
  
  # Calculate average posterior probability for each class
  avg_pp <- sapply(1:model$ng, function(k) {
    mean(posterior[class_membership == k, k])
  })
  
  # Class sizes
  class_sizes <- table(class_membership)
  class_props <- prop.table(class_sizes)
  
  data.frame(
    class = 1:model$ng,
    n = as.numeric(class_sizes),
    proportion = as.numeric(class_props),
    avg_posterior_prob = avg_pp
  )
}

# Display for each model
for (i in 2:4) {
  model <- switch(i,
                  `2` = gmm_2class,
                  `3` = gmm_3class,
                  `4` = gmm_4class)
  
  if (!is.null(model)) {
    cat(sprintf("\n%d-Class Model:\n", i))
    avg_pp <- calculate_avg_pp(model)
    print(avg_pp, row.names = FALSE, digits = 3)
  }
}

# ==============================================================================
# STEP 7: LIKELIHOOD RATIO TESTS
# ==============================================================================

cat("\n\n=== Likelihood Ratio Tests ===\n\n")

# Function to perform LR test for lcmm models
perform_lrt <- function(model_h0, model_h1) {
  if (is.null(model_h0) || is.null(model_h1)) {
    return(list(p_value = NA, lr_stat = NA, df = NA, decision = "NA"))
  }
  
  # Observed LR statistic
  lr_observed <- 2 * (model_h1$loglik - model_h0$loglik)
  
  # Degrees of freedom (difference in number of parameters)
  df <- length(model_h1$best) - length(model_h0$best)
  
  # P-value using chi-square distribution
  # For mixture models, this is approximate (boundary issue)
  p_value <- pchisq(lr_observed, df = df, lower.tail = FALSE)
  
  cat(sprintf("  LR statistic: %.2f\n", lr_observed))
  cat(sprintf("  df: %d\n", df))
  cat(sprintf("  p-value: %.4f\n", p_value))
  
  decision <- ifelse(p_value < 0.05, 
                     "Significant (prefer more classes)", 
                     "Not significant (prefer fewer classes)")
  
  return(list(
    lr_stat = lr_observed,
    df = df,
    p_value = p_value,
    decision = decision
  ))
}

# Perform LR comparisons
cat("1-class vs 2-class:\n")
lrt_2v1 <- perform_lrt(gmm_1class, gmm_2class)
cat(sprintf("  Decision: %s\n\n", lrt_2v1$decision))

cat("2-class vs 3-class:\n")
lrt_3v2 <- perform_lrt(gmm_2class, gmm_3class)
cat(sprintf("  Decision: %s\n\n", lrt_3v2$decision))

cat("3-class vs 4-class:\n")
lrt_4v3 <- perform_lrt(gmm_3class, gmm_4class)
cat(sprintf("  Decision: %s\n\n", lrt_4v3$decision))

cat("Note: These p-values are approximate for mixture models.\n")
cat("BIC is generally preferred for model selection in GMMs.\n")

# ==============================================================================
# STEP 8: MODEL SELECTION SUMMARY
# ==============================================================================

cat("\n")
cat("==============================================================================\n")
cat("MODEL SELECTION SUMMARY\n")
cat("==============================================================================\n\n")

# Determine best model by each criterion
# Note: For lcmm BIC, HIGHER is better
best_aic <- fit_comparison$n_classes[which.min(fit_comparison$AIC)]
best_bic <- fit_comparison$n_classes[which.max(fit_comparison$BIC)]

# Entropy-based recommendation (> 0.80)
good_entropy <- entropy_results %>%
  filter(entropy > 0.80 | is.na(entropy))

cat("Model Selection by Information Criteria:\n")
cat(sprintf("  Best by AIC:   %d-class model (AIC = %.2f)\n", 
            best_aic, fit_comparison$AIC[fit_comparison$n_classes == best_aic]))
cat(sprintf("  Best by BIC:   %d-class model (BIC = %.2f)\n\n", 
            best_bic, fit_comparison$BIC[fit_comparison$n_classes == best_bic]))

cat("Classification Quality (Entropy > 0.80):\n")
if (nrow(good_entropy) > 0) {
  for (i in 1:nrow(good_entropy)) {
    if (!is.na(good_entropy$entropy[i]) && good_entropy$n_classes[i] > 1) {
      cat(sprintf("  %d-class model: Entropy = %.3f ✓\n", 
                  good_entropy$n_classes[i], good_entropy$entropy[i]))
    }
  }
} else {
  cat("  No models meet entropy > 0.80 criterion\n")
}

cat("\nLikelihood Ratio Tests:\n")
cat(sprintf("  2 vs 1 classes: p = %.4f (%s)\n", 
            lrt_2v1$p_value, 
            ifelse(lrt_2v1$p_value < 0.05, "prefer 2", "prefer 1")))
cat(sprintf("  3 vs 2 classes: p = %.4f (%s)\n", 
            lrt_3v2$p_value,
            ifelse(lrt_3v2$p_value < 0.05, "prefer 3", "prefer 2")))
cat(sprintf("  4 vs 3 classes: p = %.4f (%s)\n", 
            lrt_4v3$p_value,
            ifelse(lrt_4v3$p_value < 0.05, "prefer 4", "prefer 3")))

# Overall recommendation
cat("\n--- RECOMMENDED MODEL ---\n")
cat("Based on the principle of parsimony and considering all criteria,\n")
cat("BIC is generally preferred for mixture models.\n")
cat(sprintf("\nRECOMMENDED: %d-class model\n", best_bic))

# Check if BIC and entropy agree
selected_model_entropy <- entropy_results$entropy[entropy_results$n_classes == best_bic]
if (!is.na(selected_model_entropy) && best_bic > 1) {
  if (selected_model_entropy > 0.80) {
    cat(sprintf("This model also has good classification quality (Entropy = %.3f)\n", 
                selected_model_entropy))
  } else {
    cat(sprintf("NOTE: Classification quality is moderate (Entropy = %.3f)\n", 
                selected_model_entropy))
    cat("Consider theoretical interpretability when making final decision.\n")
  }
}

# ==============================================================================
# STEP 9: DETAILED RESULTS FOR SELECTED MODEL
# ==============================================================================

cat("\n")
cat("==============================================================================\n")
cat(sprintf("DETAILED RESULTS: %d-CLASS MODEL\n", best_bic))
cat("==============================================================================\n\n")

selected_model <- switch(best_bic,
                         `1` = gmm_1class,
                         `2` = gmm_2class,
                         `3` = gmm_3class,
                         `4` = gmm_4class)

if (!is.null(selected_model)) {
  cat("Model Summary:\n")
  print(summary(selected_model))
  
  if (best_bic > 1) {
    cat("\n\n--- CLASS CHARACTERISTICS ---\n\n")
    
    # Get class membership from lcmm
    pprob_data <- selected_model$pprob
    
    # Class sizes and proportions
    class_summary <- pprob_data %>%
      group_by(class) %>%
      summarise(
        n = n(),
        proportion = n() / nrow(pprob_data),
        .groups = "drop"
      )
    
    cat("Class Sizes:\n")
    print(class_summary, row.names = FALSE, digits = 3)
    
    # Merge class membership with observed data for trajectory plotting
    factor_scores_classified_long <- factor_scores_long %>%
      left_join(pprob_data %>% 
                  rename(numeric_id = !! sym(names(pprob_data)[1])) %>%
                  select(numeric_id, class),
                by = c("id" = "numeric_id"))
    
    # Calculate observed mean trajectories by class
    class_trajectories <- factor_scores_classified_long %>%
      group_by(class, age) %>%
      summarise(
        mean_sc = mean(self_control, na.rm = TRUE),
        sd_sc = sd(self_control, na.rm = TRUE),
        se_sc = sd(self_control, na.rm = TRUE) / sqrt(n()),
        n = n(),
        .groups = "drop"
      )
    
    cat("\n\nObserved Mean Self-Control by Class and Age:\n\n")
    traj_wide <- class_trajectories %>% 
      select(class, age, mean_sc) %>%
      pivot_wider(names_from = age, values_from = mean_sc,
                  names_prefix = "age_") %>%
      arrange(class)
    print(traj_wide, row.names = FALSE, digits = 3)
    
    # Get predicted class-specific trajectories using predictY
    cat("\n\nPredicted Class-Specific Trajectories:\n")
    cat("(Model-estimated mean trajectories for each class)\n\n")
    
    # Create prediction data across age range
    pred_ages <- seq(0, 14, by = 2)  # age_centered from 0 to 14
    
    for (k in 1:best_bic) {
      pred_data <- data.frame(
        age_centered = pred_ages,
        age = pred_ages + 3
      )
      
      # Predict for this class
      pred_result <- predictY(selected_model, 
                               newdata = pred_data,
                               var.time = "age_centered",
                               draws = FALSE)
      
      cat(sprintf("Class %d:\n", k))
      pred_summary <- data.frame(
        age = pred_data$age,
        pred_mean = pred_result$pred[, k]
      )
      print(pred_summary, row.names = FALSE, digits = 3)
      cat("\n")
    }
  }
}

# ==============================================================================
# STEP 10: VISUALIZATION OF GROWTH TRAJECTORIES
# ==============================================================================

cat("\n=== Creating Trajectory Plots ===\n\n")

# Function to create trajectory plot for lcmm models
plot_trajectories <- function(model, nclass, factor_scores_long_input) {
  if (is.null(model) || nclass == 1) {
    return(NULL)
  }
  
  # Get class membership from lcmm
  pprob_data <- model$pprob
  
  # Merge with factor scores (numeric id matching)
  plot_data <- factor_scores_long_input %>%
    left_join(pprob_data %>% 
                rename(numeric_id = !! sym(names(pprob_data)[1])) %>%
                select(numeric_id, class),
              by = c("id" = "numeric_id"))
  
  # Calculate mean trajectories by class
  mean_traj <- plot_data %>%
    group_by(class, age) %>%
    summarise(
      mean_sc = mean(self_control, na.rm = TRUE),
      se = sd(self_control, na.rm = TRUE) / sqrt(n()),
      n = n(),
      .groups = "drop"
    )
  
  # Create plot
  p <- ggplot(mean_traj, aes(x = age, y = mean_sc, color = factor(class), 
                              group = class)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 3) +
    geom_ribbon(aes(ymin = mean_sc - 1.96*se, ymax = mean_sc + 1.96*se,
                    fill = factor(class)), alpha = 0.2, color = NA) +
    labs(
      title = sprintf("%d-Class Growth Mixture Model", nclass),
      subtitle = "Observed Mean Self-Control Trajectories by Latent Class",
      x = "Age (years)",
      y = "Self-Control Factor Score",
      color = "Class",
      fill = "Class"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "right"
    ) +
    scale_x_continuous(breaks = c(3, 5, 7, 11, 14, 17))
  
  return(p)
}

# Create plots for all models
plots_list <- list()

for (i in 2:4) {
  model <- switch(i,
                  `2` = gmm_2class,
                  `3` = gmm_3class,
                  `4` = gmm_4class)
  
  if (!is.null(model)) {
    plots_list[[i]] <- plot_trajectories(model, i, factor_scores_long)
    
    # Save plot
    ggsave(
      filename = sprintf("/home/siyang/dissertation/gmm_%dclass_trajectories.png", i),
      plot = plots_list[[i]],
      width = 10,
      height = 6,
      dpi = 300
    )
    cat(sprintf("Saved: gmm_%dclass_trajectories.png\n", i))
  }
}

# Create comparison plot
if (best_bic > 1 && !is.null(selected_model)) {
  cat(sprintf("\nDisplaying selected model (%d-class) plot:\n", best_bic))
  print(plots_list[[best_bic]])
}

# ==============================================================================
# STEP 11: SAVE RESULTS
# ==============================================================================

cat("\n=== Saving Results ===\n\n")

# Save all model objects
save(
  gmm_1class, gmm_2class, gmm_3class, gmm_4class,
  fit_comparison, entropy_results,
  factor_scores_df, factor_scores_long, id_mapping,
  file = "/home/siyang/dissertation/gmm_results.RData"
)
cat("Saved: gmm_results.RData (includes id_mapping for original IDs)\n")

# Save fit comparison table
write.csv(
  fit_comparison,
  file = "/home/siyang/dissertation/gmm_fit_comparison.csv",
  row.names = FALSE
)
cat("Saved: gmm_fit_comparison.csv\n")

# Save entropy results
write.csv(
  entropy_results,
  file = "/home/siyang/dissertation/gmm_entropy.csv",
  row.names = FALSE
)
cat("Saved: gmm_entropy.csv\n")

# Save class membership for selected model
if (best_bic > 1 && !is.null(selected_model)) {
  # Get class membership and posterior probabilities from lcmm
  pprob_full <- selected_model$pprob
  
  # Map numeric IDs back to original IDs
  pprob_with_original_ids <- pprob_full %>%
    rename(numeric_id = !! sym(names(pprob_full)[1])) %>%
    left_join(id_mapping, by = "numeric_id") %>%
    select(-numeric_id) %>%
    rename(id = original_id)
  
  # Merge with original mcsid
  class_membership_full <- lgbm_data %>%
    select(mcsid) %>%
    left_join(pprob_with_original_ids, by = c("mcsid" = "id"))
  
  write.csv(
    class_membership_full,
    file = sprintf("/home/siyang/dissertation/gmm_%dclass_membership.csv", best_bic),
    row.names = FALSE
  )
  cat(sprintf("Saved: gmm_%dclass_membership.csv\n", best_bic))
  
  # Save class characteristics (observed trajectories)
  class_trajectories_save <- factor_scores_long %>%
    left_join(pprob_full %>% 
                rename(numeric_id = !! sym(names(pprob_full)[1])) %>%
                select(numeric_id, class),
              by = c("id" = "numeric_id")) %>%
    group_by(class, age) %>%
    summarise(
      mean_sc = mean(self_control, na.rm = TRUE),
      sd_sc = sd(self_control, na.rm = TRUE),
      se_sc = sd(self_control, na.rm = TRUE) / sqrt(n()),
      n = n(),
      .groups = "drop"
    )
  
  write.csv(
    class_trajectories_save,
    file = sprintf("/home/siyang/dissertation/gmm_%dclass_characteristics.csv", best_bic),
    row.names = FALSE
  )
  cat(sprintf("Saved: gmm_%dclass_characteristics.csv\n", best_bic))
}

# Create summary report
summary_report <- list(
  n_observations = nrow(lgbm_data),
  n_timepoints = length(unique(factor_scores_long$age)),
  models_fitted = "1-class, 2-class, 3-class, 4-class",
  model_specification = "Quadratic growth with class-specific trajectories",
  recommended_model = sprintf("%d-class", best_bic),
  recommendation_basis = "BIC (Bayesian Information Criterion)",
  fit_statistics = fit_comparison,
  entropy = entropy_results,
  lrt_results = data.frame(
    comparison = c("2 vs 1", "3 vs 2", "4 vs 3"),
    lr_statistic = c(lrt_2v1$lr_stat, lrt_3v2$lr_stat, lrt_4v3$lr_stat),
    df = c(lrt_2v1$df, lrt_3v2$df, lrt_4v3$df),
    p_value = c(lrt_2v1$p_value, lrt_3v2$p_value, lrt_4v3$p_value)
  )
)

saveRDS(
  summary_report,
  file = "/home/siyang/dissertation/gmm_summary_report.rds"
)
cat("Saved: gmm_summary_report.rds\n")

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

cat("\n")
cat("==============================================================================\n")
cat("GMM ANALYSIS COMPLETE\n")
cat("==============================================================================\n\n")

cat("Summary:\n")
cat(sprintf("  - Models fitted: 1, 2, 3, and 4-class GMMs\n"))
cat(sprintf("  - Recommended model: %d-class (based on BIC)\n", best_bic))
cat(sprintf("  - Sample size: N = %d\n", nrow(lgbm_data)))
cat("\nFiles created:\n")
cat("  - gmm_results.RData (all model objects)\n")
cat("  - gmm_fit_comparison.csv\n")
cat("  - gmm_entropy.csv\n")
cat("  - gmm_*class_trajectories.png (plots)\n")
cat("  - gmm_*class_membership.csv\n")
cat("  - gmm_*class_characteristics.csv\n")
cat("  - gmm_summary_report.rds\n")

cat("\n=== Key Features ===\n\n")
cat("1. True growth mixture modeling with lcmm (not LPA)\n")
cat("2. Quadratic growth with class-specific trajectories\n")
cat("3. Robust convergence via gridsearch (100 random starts/model)\n")
if (.Platform$OS.type == "unix") {
  cat(sprintf("4. Parallel processing (%d cores) - 3x faster than sequential\n", n_cores))
} else {
  cat("4. Sequential processing (use Linux/Mac/WSL for parallelization)\n")
}

cat("\n=== Next Steps ===\n\n")
cat("1. Review the trajectory plots to assess interpretability\n")
cat("2. Examine class characteristics to name/describe classes\n")
cat("3. Consider theoretical meaningfulness alongside statistical fit\n")
cat("4. Use class membership for downstream analyses (predictors/outcomes)\n")
cat("5. If needed, refit with more bootstrap samples for BLRT\n")
cat("6. Consider validation in holdout sample or cross-validation\n")

cat("\n=== END ===\n\n")

