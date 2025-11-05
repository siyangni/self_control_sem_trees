# ==============================================================================
# SemTREE Analysis - RELAXED PARAMETERS VERSION
# ==============================================================================
#
# This version uses more permissive splitting criteria to increase the 
# likelihood of detecting subgroups:
# - Higher alpha (0.10 instead of 0.05)
# - Lower min.N (50 instead of 100)
# - Focused set of key covariates
#
# Use this if the standard version finds no splits
#
# ==============================================================================

library(pacman)
p_load(tidyverse, semtree, semforest)

# Load LGBM model results
cat("\n=== Loading LGBM Model Results ===\n")
load("/home/siyang/dissertation/lgbm_results.RData")
cat("Loaded: lgbm_data, fit_lgbm_survey, factor_scores_df\n")

# Reload original data to get covariates
load("/home/siyang/dissertation/merged_waves_recoded.RData")
cat("Loaded: merged_waves_recoded (full dataset with covariates)\n")

# ==============================================================================
# FOCUSED COVARIATE SELECTION
# ==============================================================================

cat("\n=== Covariate Selection Strategy ===\n")
cat("Using focused set of theoretically important predictors\n\n")

# Strategy 1: Baseline characteristics only
baseline_covs <- c(
  "scoga",      # Cognitive ability
  "lbw",        # Low birth weight
  "inftemp",    # Infant temperament
  "hfae",       # Home environment
  "bmarried",   # Married at birth
  "brace",      # Race/ethnicity
  "sex",        # Child sex
  "bpedu",      # Parental education
  "incomef"     # Family income
)

# Strategy 2: Early parenting practices (ages 3-7)
early_parenting_covs <- c(
  "smack3", "shout3", "reason5", "reason7",
  "telloff3", "telloff5", "telloff7"
)

# Strategy 3: Combined key predictors
combined_covs <- c(baseline_covs, early_parenting_covs)

# Check availability
available_baseline <- baseline_covs[baseline_covs %in% names(merged_waves_recoded)]
available_early <- early_parenting_covs[early_parenting_covs %in% names(merged_waves_recoded)]
available_combined <- combined_covs[combined_covs %in% names(merged_waves_recoded)]

cat("Available covariates by strategy:\n")
cat(sprintf("  Baseline only: %d/%d\n", length(available_baseline), length(baseline_covs)))
cat(sprintf("  Early parenting: %d/%d\n", length(available_early), length(early_parenting_covs)))
cat(sprintf("  Combined: %d/%d\n", length(available_combined), length(combined_covs)))

# Choose strategy (prefer combined if enough available)
if (length(available_combined) >= 5) {
  cat("\nUsing COMBINED strategy (baseline + early parenting)\n")
  available_covariates <- available_combined
} else if (length(available_baseline) >= 3) {
  cat("\nUsing BASELINE strategy (child/family characteristics)\n")
  available_covariates <- available_baseline
} else {
  cat("\nWARNING: Insufficient covariates available\n")
  available_covariates <- character(0)
}

cat("Selected covariates:", paste(available_covariates, collapse = ", "), "\n")

# ==============================================================================
# PREPARE DATA
# ==============================================================================

if (length(available_covariates) > 0) {
  lgbm_data_with_cov <- lgbm_data %>%
    left_join(
      merged_waves_recoded %>% 
        select(mcsid, all_of(available_covariates)),
      by = "mcsid"
    )
  
  # Convert categorical variables to factors
  for (var in available_covariates) {
    if (!is.numeric(lgbm_data_with_cov[[var]])) {
      lgbm_data_with_cov[[var]] <- as.factor(lgbm_data_with_cov[[var]])
    }
  }
  
  # Remove cases with missing covariates
  n_before <- nrow(lgbm_data_with_cov)
  lgbm_data_with_cov <- lgbm_data_with_cov %>%
    filter(if_all(all_of(available_covariates), ~ !is.na(.)))
  n_after <- nrow(lgbm_data_with_cov)
  
  cat(sprintf("\nCases with complete covariate data: %d (%.1f%% of original)\n", 
              n_after, 100 * n_after / n_before))
  
} else {
  cat("\nERROR: No suitable covariates found. Cannot proceed.\n")
  lgbm_data_with_cov <- NULL
}

# ==============================================================================
# FIT SEMTREE WITH RELAXED PARAMETERS
# ==============================================================================

if (!is.null(lgbm_data_with_cov) && nrow(lgbm_data_with_cov) > 50) {
  
  cat("\n=== Fitting SemTREE with RELAXED Parameters ===\n")
  cat("Settings:\n")
  cat("  - Method: fair (WLSMV compatible)\n")
  cat("  - Alpha: 0.10 (more permissive)\n")
  cat("  - Min N: 50 (smaller nodes allowed)\n")
  cat("  - Max depth: 6 (deeper tree)\n\n")
  
  semtree_data <- lgbm_data_with_cov
  
  # Relaxed control parameters
  ctrl_relaxed <- semtree_control(
    method = "fair",           # WLSMV compatible
    min.N = 50,               # Reduced from 100
    max.depth = 6,            # Increased from 5
    alpha = 0.10,             # Increased from 0.05
    alpha.invariance = 0.10,
    verbose = TRUE
  )
  
  cat("Building decision tree...\n")
  
  tryCatch({
    tree_relaxed <- semtree(
      model = fit_lgbm_survey,
      data = semtree_data,
      control = ctrl_relaxed,
      predictors = available_covariates
    )
    
    cat("\n✓ SemTREE fitted successfully\n")
    
    # Display tree structure
    cat("\n--- Tree Structure ---\n")
    print(tree_relaxed)
    
    # Check if splits were found - proper detection
    tree_str <- capture.output(print(tree_relaxed))
    has_splits <- any(grepl("\\|-\\[2\\]", tree_str))  # Check for node 2 (first split)
    
    if (has_splits) {
      cat("\n✓ SUCCESS: Splits found!\n")
      cat("The relaxed parameters successfully identified subgroups.\n\n")
    } else {
      cat("\n⚠ Still no splits found even with relaxed parameters.\n")
      cat("This strongly suggests covariates do not differentiate trajectories.\n\n")
    }
    
    # Plot the tree
    cat("Generating tree visualization...\n")
    pdf("/home/siyang/dissertation/semtree_relaxed_plot.pdf", width = 14, height = 10)
    tryCatch({
      plot(tree_relaxed, main = "SemTREE (Relaxed): Self-Control Growth Trajectories")
    }, error = function(e) {
      plot.new()
      text(0.5, 0.5, "No splits found", cex = 1.5)
    })
    dev.off()
    cat("Saved: semtree_relaxed_plot.pdf\n")
    
    # Save results
    save(tree_relaxed, ctrl_relaxed, available_covariates,
         file = "/home/siyang/dissertation/semtree_relaxed_results.RData")
    cat("Saved: semtree_relaxed_results.RData\n")
    
    # If splits found, fit forest
    if (has_splits) {
      cat("\n=== Fitting SemFOREST (Relaxed) ===\n")
      cat("Splits detected - proceeding with forest analysis...\n\n")
      
      forest_ctrl_relaxed <- semforest_control(
        num.trees = 50,            # Fewer trees for faster computation
        control = ctrl_relaxed
      )
      
      tryCatch({
        forest_relaxed <- semforest(
          model = fit_lgbm_survey,
          data = semtree_data,
          control = forest_ctrl_relaxed,
          predictors = available_covariates
        )
        
        cat("\n✓ SemFOREST fitted successfully\n")
        
        # Variable importance (with error handling)
        cat("\n--- Variable Importance ---\n")
        varimp_result <- tryCatch({
          varimp_relaxed <- varimp(forest_relaxed)
          print(varimp_relaxed)
          
          # Plot variable importance
          pdf("/home/siyang/dissertation/semforest_relaxed_varimp.pdf", width = 10, height = 6)
          plot(varimp_relaxed, main = "Variable Importance (Relaxed Parameters)")
          dev.off()
          cat("Saved: semforest_relaxed_varimp.pdf\n")
          
          # Save forest with variable importance
          save(forest_relaxed, varimp_relaxed,
               file = "/home/siyang/dissertation/semforest_relaxed_results.RData")
          cat("Saved: semforest_relaxed_results.RData\n")
          
          TRUE
        }, error = function(e) {
          cat("\n⚠ WARNING: Could not compute variable importance\n")
          cat("Error:", e$message, "\n")
          cat("This likely means no trees in the forest had any splits.\n")
          cat("Saving forest object without variable importance.\n")
          
          # Save forest without variable importance
          save(forest_relaxed, 
               file = "/home/siyang/dissertation/semforest_relaxed_results.RData")
          cat("Saved: semforest_relaxed_results.RData (no variable importance)\n")
          
          FALSE
        })
        
      }, error = function(e) {
        cat("\nERROR fitting semforest:", e$message, "\n")
      })
    } else {
      cat("\n=== Skipping SemFOREST (Relaxed) ===\n")
      cat("No splits found even with relaxed parameters.\n")
      cat("A forest of 50 trees would take ~1 hour and likely find nothing.\n\n")
      cat("⚠ IMPORTANT: Even with more permissive criteria, no subgroups detected.\n\n")
      cat("This strongly suggests that the examined covariates do not\n")
      cat("differentiate self-control growth trajectories in your sample.\n\n")
      cat("RECOMMENDATIONS:\n")
      cat("  1. Consider alternative analytic approaches:\n")
      cat("     • Regression with factor scores as outcomes\n")
      cat("     • Theory-driven group comparisons (e.g., high vs low SES)\n")
      cat("     • Examine GMM results for data-driven classes\n")
      cat("  2. This null finding is scientifically meaningful and reportable\n")
      cat("  3. May indicate universal developmental processes\n")
      cat("  4. Could point to unmeasured moderators\n")
    }
    
  }, error = function(e) {
    cat("\nERROR fitting semtree:", e$message, "\n")
  })
  
} else {
  if (is.null(lgbm_data_with_cov)) {
    cat("\nSkipping: No covariates available\n")
  } else {
    cat(sprintf("\nSkipping: Insufficient sample (N=%d, need >50)\n", 
                nrow(lgbm_data_with_cov)))
  }
}

# ==============================================================================
# SUMMARY
# ==============================================================================

cat("\n")
cat("==============================================================================\n")
cat("RELAXED PARAMETER ANALYSIS COMPLETE\n")
cat("==============================================================================\n\n")

cat("This analysis used more permissive criteria:\n")
cat("  ✓ Lower significance threshold (α = 0.10)\n")
cat("  ✓ Smaller minimum node size (N = 50)\n")
cat("  ✓ Focused covariate set\n\n")

cat("If splits were found:\n")
cat("  → Examine semtree_relaxed_plot.pdf for tree structure\n")
cat("  → Check semforest_relaxed_varimp.pdf for variable importance\n")
cat("  → Load semtree_relaxed_results.RData for detailed analysis\n\n")

cat("If still no splits:\n")
cat("  → Covariates likely do not predict trajectory differences\n")
cat("  → Consider alternative analytic strategies:\n")
cat("     • Regression with factor scores as outcomes\n")
cat("     • Theory-driven subgroup comparisons\n")
cat("     • Qualitative categorization of covariates\n\n")

cat("==============================================================================\n")

