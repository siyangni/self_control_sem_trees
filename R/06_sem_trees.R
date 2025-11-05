# ==============================================================================
# SemTREE Analysis for Self-Control Growth Trajectories
# Identifying Subgroups Based on Parenting and Child Characteristics
# ==============================================================================
#
# This script performs:
# 1. SemTREE - Decision tree to identify subgroups with different growth patterns
# 2. SemFOREST - Random forest of SEM trees for variable importance
#
# IMPORTANT NOTE ON ESTIMATION:
# - The LGBM model uses WLSMV estimator (for categorical indicators)
# - SemTREE "score-based" method requires ML estimator
# - Solution: Use "fair" method (likelihood-based, works with WLSMV)
# - Alternative: Refit LGBM with ML estimator for continuous factor scores
#
# Covariates include 47 MCS variables:
# - Parenting practices across childhood (ages 3, 5, 7, 11)
# - Parental monitoring (ages 14, 17)
# - Baseline child characteristics (cognitive ability, temperament, birth weight)
# - Family characteristics (SES, structure, home environment)
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

# Define covariates from MCS dataset
# Parenting practices and child characteristics
covariate_candidates <- c(
  # Parenting at Age 3
  "ignore3", "smack3", "shout3", "bedroom3", "treats3", "telloff3", "bribe3",
  
  # Parenting at Age 5
  "ignore5", "smack5", "shout5", "bedroom5", "treats5", "telloff5", "bribe5", "reason5",
  
  # Parenting at Age 7
  "ignore7", "smack7", "shout7", "bedroom7", "treats7", "telloff7", "bribe7", "reason7",
  
  # Parenting at Age 11
  "bedroom11", "treats11", "reason11",
  
  # Monitoring/Activities at Age 14
  "pwhere14", "pwho14", "pwhat14", "cmwhere14", "cmwho14", "cmwhat14",
  
  # Monitoring/Activities at Age 17
  "pwhere17", "ptback17", "cmwhere17", "cmtback17",
  
  # Baseline child and family characteristics
  "scoga",      # Child general cognitive ability
  "lbw",        # Low birth weight
  "inftemp",    # Infant temperament
  "hfae",       # Home Family Environment
  "bmarried",   # Parents married at birth
  "brace",      # Child race/ethnicity
  "sex",        # Child sex
  "bpedu",      # Parental education at birth
  "incomef"     # Family income
)

# Check which covariates are available
available_covariates <- covariate_candidates[covariate_candidates %in% names(merged_waves_recoded)]
cat(sprintf("\n=== Covariate Summary ===\n"))
cat(sprintf("Available covariates: %d of %d requested\n", 
            length(available_covariates), length(covariate_candidates)))

if (length(available_covariates) > 0) {
  # Categorize available covariates
  parenting_age3 <- available_covariates[grepl("3$", available_covariates)]
  parenting_age5 <- available_covariates[grepl("5$", available_covariates)]
  parenting_age7 <- available_covariates[grepl("7$", available_covariates)]
  parenting_age11 <- available_covariates[grepl("11$", available_covariates)]
  parenting_age14 <- available_covariates[grepl("14$", available_covariates)]
  parenting_age17 <- available_covariates[grepl("17$", available_covariates)]
  baseline_vars <- available_covariates[available_covariates %in% c("scoga", "lbw", "inftemp", "hfae", "bmarried", "brace", "sex", "bpedu", "incomef")]
  
  cat("\nAvailable by category:\n")
  if (length(parenting_age3) > 0) cat(sprintf("  - Age 3 parenting: %d variables\n", length(parenting_age3)))
  if (length(parenting_age5) > 0) cat(sprintf("  - Age 5 parenting: %d variables\n", length(parenting_age5)))
  if (length(parenting_age7) > 0) cat(sprintf("  - Age 7 parenting: %d variables\n", length(parenting_age7)))
  if (length(parenting_age11) > 0) cat(sprintf("  - Age 11 parenting: %d variables\n", length(parenting_age11)))
  if (length(parenting_age14) > 0) cat(sprintf("  - Age 14 monitoring: %d variables\n", length(parenting_age14)))
  if (length(parenting_age17) > 0) cat(sprintf("  - Age 17 monitoring: %d variables\n", length(parenting_age17)))
  if (length(baseline_vars) > 0) cat(sprintf("  - Baseline characteristics: %d variables\n", length(baseline_vars)))
  
  cat("\nFull list:\n")
  cat("  ", paste(available_covariates, collapse = ", "), "\n")
  
  # Report missing covariates
  missing_covariates <- covariate_candidates[!covariate_candidates %in% names(merged_waves_recoded)]
  if (length(missing_covariates) > 0) {
    cat("\nMissing covariates (not in dataset):\n")
    cat("  ", paste(missing_covariates, collapse = ", "), "\n")
  }
} else {
  cat("  WARNING: No requested covariates found in dataset.\n")
  cat("  Cannot proceed with SemTREE analysis.\n")
}

# Merge covariates with LGBM data
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
  cat("\nWARNING: No suitable covariates found. Skipping SemTREE analysis.\n")
  lgbm_data_with_cov <- NULL
}

# ==============================================================================
# FIT SEMTREE
# ==============================================================================

if (!is.null(lgbm_data_with_cov) && nrow(lgbm_data_with_cov) > 100) {
  
  cat("\n=== Fitting SemTREE ===\n")
  cat("This may take several minutes depending on data size...\n\n")
  
  # Prepare data for semtree
  semtree_data <- lgbm_data_with_cov
  
  # Create semtree control object with appropriate settings
  # Use "fair" method (works with WLSMV estimator) instead of "score" (needs ML)
  ctrl <- semtree_control(
    method = "fair",           # Fair split selection (compatible with WLSMV)
    min.N = 100,               # Minimum sample size per node
    max.depth = 5,             # Maximum tree depth
    alpha = 0.05,              # Significance level for splits
    alpha.invariance = 0.05,   # Alpha for invariance tests
    verbose = TRUE
  )
  
  # Fit the semtree
  cat("\nBuilding decision tree to identify subgroups...\n")
  
  tryCatch({
    tree <- semtree(
      model = fit_lgbm_survey,
      data = semtree_data,
      control = ctrl,
      predictors = available_covariates
    )
    
    cat("\n✓ SemTREE fitted successfully\n")
    
    # Display tree structure
    cat("\n--- Tree Structure ---\n")
    print(tree)
    
    # Check if any splits were found
    # A tree with splits has multiple nodes; no splits = single root node
    tree_str <- capture.output(print(tree))
    has_splits <- any(grepl("\\|-\\[2\\]", tree_str))  # Check for node 2 (first split)
    
    if (!has_splits) {
      cat("\n⚠ WARNING: No significant splits found!\n")
      cat("This means no covariates significantly differentiate growth trajectories.\n")
      cat("Possible reasons:\n")
      cat("  - Covariates are not predictive of growth patterns\n")
      cat("  - Sample size too small for detecting differences\n")
      cat("  - Alpha threshold too stringent\n")
      cat("  - Model complexity limits split detection\n\n")
      cat("Consider:\n")
      cat("  - Increasing alpha (e.g., 0.10 instead of 0.05)\n")
      cat("  - Reducing min.N per node\n")
      cat("  - Using different covariates\n")
      cat("  - Checking for data quality issues\n\n")
    }
    
    # Plot the tree
    cat("\nGenerating tree visualization...\n")
    pdf("/home/siyang/dissertation/semtree_plot.pdf", width = 12, height = 8)
    tryCatch({
      plot(tree, main = "SemTREE: Self-Control Growth Trajectories")
    }, error = function(e) {
      plot.new()
      text(0.5, 0.5, "No splits found - single node tree", cex = 1.5)
    })
    dev.off()
    cat("Saved: semtree_plot.pdf\n")
    
    # Get node information
    cat("\n--- Terminal Nodes (Subgroups) ---\n")
    # Simple approach: check tree structure
    if (!is.null(tree) && class(tree)[1] == "semtree") {
      # For semtree objects, check if there are splits
      if (has_splits) {
        cat("Tree has multiple nodes (splits found)\n")
      } else {
        cat("Tree has only 1 terminal node (no splits found)\n")
        cat(sprintf("  Root node: N = %d (entire sample)\n", nrow(semtree_data)))
      }
    }
    
    # Save tree object
    save(tree, file = "/home/siyang/dissertation/semtree_results.RData")
    cat("\nSaved: semtree_results.RData\n")
    
  }, error = function(e) {
    cat("\nERROR fitting semtree:", e$message, "\n")
    cat("This may occur if:\n")
    cat("  - Sample size is too small\n")
    cat("  - No significant splits found\n")
    cat("  - Covariates are not informative\n")
  })
  
  # ==============================================================================
  # FIT SEMFOREST (Random Forest of SEM Trees)
  # ==============================================================================
  
  # Only fit forest if the single tree found splits
  if (exists("has_splits") && has_splits) {
    cat("\n=== Fitting SemFOREST ===\n")
    cat("Growing a forest of trees for robust subgroup identification...\n")
    cat("This will take longer than a single tree...\n\n")
    
    # Create forest control object
    forest_ctrl <- semforest_control(
      num.trees = 100,           # Number of trees in forest
      control = ctrl             # Use same tree controls
    )
    
    tryCatch({
      forest <- semforest(
        model = fit_lgbm_survey,
        data = semtree_data,
        control = forest_ctrl,
        predictors = available_covariates
      )
      
      cat("\n✓ SemFOREST fitted successfully\n")
      
      # Variable importance (with error handling)
      cat("\n--- Variable Importance ---\n")
      varimp_result <- tryCatch({
        varimp <- varimp(forest)
        print(varimp)
        
        # Plot variable importance
        cat("\nGenerating variable importance plot...\n")
        pdf("/home/siyang/dissertation/semforest_varimp.pdf", width = 10, height = 6)
        plot(varimp, main = "Variable Importance for Growth Trajectory Differences")
        dev.off()
        cat("Saved: semforest_varimp.pdf\n")
        
        # Save forest object with variable importance
        save(forest, varimp, 
             file = "/home/siyang/dissertation/semforest_results.RData")
        cat("Saved: semforest_results.RData\n")
        
        TRUE
      }, error = function(e) {
        cat("\n⚠ WARNING: Could not compute variable importance\n")
        cat("Error:", e$message, "\n")
        cat("This likely means no trees in the forest had any splits.\n")
        cat("Saving forest object without variable importance.\n")
        
        # Save forest object without variable importance
        save(forest, file = "/home/siyang/dissertation/semforest_results.RData")
        cat("Saved: semforest_results.RData (no variable importance)\n")
        
        FALSE
      })
      
    }, error = function(e) {
      cat("\nERROR fitting semforest:", e$message, "\n")
      cat("Forest analysis requires substantial computational resources.\n")
    })
  } else {
    cat("\n=== Skipping SemFOREST ===\n")
    cat("No splits found in single tree, so forest analysis would not be informative.\n")
    cat("A forest of 100 trees would take ~1-2 hours and likely find nothing.\n\n")
    cat("RECOMMENDATION: Try one of these alternatives instead:\n")
    cat("  1. Run sem_trees_relaxed.R (more permissive parameters)\n")
    cat("  2. Use fewer covariates (focus on theory-driven predictors)\n")
    cat("  3. Increase alpha to 0.10 or 0.15\n")
    cat("  4. Reduce min.N to 50 or 75\n")
    cat("  5. Use factor scores with traditional methods (regression, ANOVA)\n")
  }
  
} else {
  if (is.null(lgbm_data_with_cov)) {
    cat("\nSkipping SemTREE: No covariates available\n")
  } else {
    cat(sprintf("\nSkipping SemTREE: Insufficient sample size (N = %d, need > 100)\n", 
                nrow(lgbm_data_with_cov)))
  }
}

# ==============================================================================
# SUMMARY OF SEMTREE ANALYSIS
# ==============================================================================

cat("\n")
cat("==============================================================================\n")
cat("SEMTREE ANALYSIS SUMMARY\n")
cat("==============================================================================\n\n")

cat("SemTREE identifies subgroups in your data that show different patterns\n")
cat("in the latent growth model parameters (intercept, slope, variance).\n\n")

cat("Key outputs:\n")
cat("  1. semtree_results.RData - Decision tree object\n")
cat("  2. semtree_plot.pdf - Visual representation of splits\n")
cat("  3. semforest_results.RData - Random forest object\n")
cat("  4. semforest_varimp.pdf - Variable importance rankings\n\n")

cat("Interpretation:\n")
cat("  - Each terminal node represents a distinct subgroup\n")
cat("  - Split points show which covariates differentiate groups\n")
cat("  - Variable importance indicates predictive strength\n")
cat("  - Compare parameter estimates across terminal nodes\n\n")

cat("Next steps:\n")
cat("  1. Examine terminal nodes for substantive interpretation\n")
cat("  2. Test stability with different control parameters\n")
cat("  3. Validate findings with alternative methods\n")
cat("  4. Report effect sizes for key splits\n\n")

cat("==============================================================================\n")
cat("COMPLETE ANALYSIS FINISHED\n")
cat("==============================================================================\n")
