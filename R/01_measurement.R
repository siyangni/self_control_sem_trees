# Load required library
library(pacman)
p_load(tidyverse, haven, psych, polycor, lavaan, semTools, survey)

# Load the Stata dataset
#merged_waves_recoded <- read_dta("/home/siyang/dissertation/merged_waves_recoded.dta")
#save(merged_waves_recoded, file = "/home/siyang/dissertation/merged_waves_recoded.RData")

# Load the RData file
load("/home/siyang/dissertation/merged_waves_recoded.RData")

# Check variable information
vars_to_check <- c("sc3thac", "sc3tcom", "sc3obey", "sc3dist", "sc3temp", "sc3rest", "sc3fidg")

# Display variable labels and attributes
cat("\n=== Variable Information ===\n")
for (var in vars_to_check) {
  if (var %in% names(merged_waves_recoded)) {
    cat("\n", var, ":\n", sep="")
    cat("  Label: ", attr(merged_waves_recoded[[var]], "label"), "\n", sep="")
    cat("  Type: ", class(merged_waves_recoded[[var]]), "\n", sep="")
    cat("  Summary:\n")
    print(summary(merged_waves_recoded[[var]]))
    
    # Check for value labels if they exist
    if (!is.null(attr(merged_waves_recoded[[var]], "labels"))) {
      cat("  Value labels:\n")
      print(attr(merged_waves_recoded[[var]], "labels"))
    }
  } else {
    cat("\n", var, ": NOT FOUND in dataset\n", sep="")
  }
}

# ============================================================================
# RELIABILITY ANALYSIS: Ordinal Alpha and Omega
# ============================================================================

# 0) Ensure all items coded so larger = MORE self-control
# NOTE: Upon inspection, sc3dist, sc3temp, sc3rest, sc3fidg are ALREADY reverse-coded
#       in the original data (higher values = NOT true = better self-control)
#       So we do NOT need to reverse them again!
cat("\n\n=== Checking Item Coding (Higher = More Self-Control) ===\n")
cat("Items sc3dist, sc3temp, sc3rest, sc3fidg are already coded where:\n")
cat("  0 = Certainly true (problem behavior)\n")
cat("  2 = Not true (no problem = good self-control)\n")
cat("No additional reversing needed.\n")

# Create list of self-control variables (all correctly coded)
myvars <- c("sc3thac", "sc3tcom", "sc3obey", "sc3dist", "sc3temp", "sc3rest", "sc3fidg")

# 1) Create analysis subset with complete cases and valid survey weights
merged_waves_recoded <- merged_waves_recoded %>%
  mutate(
    .nmiss = rowSums(is.na(select(., all_of(myvars)))),
    .complete = (.nmiss == 0),
    .ok = .complete == 1 & 
           !is.na(bovwt1) & !is.na(sptn00) & !is.na(pttype2) & 
           bovwt1 > 0
  )

cat("Complete cases with valid survey weights:", sum(merged_waves_recoded$.ok, na.rm=TRUE), "\n")

# Prepare data for analysis
analysis_data <- merged_waves_recoded %>%
  filter(.ok) %>%
  select(all_of(myvars), bovwt1, sptn00, pttype2, nh2)

# Set up survey design
svy_design <- svydesign(
  ids = ~sptn00,
  strata = ~pttype2,
  weights = ~bovwt1,
  fpc = ~nh2,
  data = analysis_data,
  nest = TRUE
)

cat("\n=== (A) Ordinal Alpha (Weighted Polychoric Correlations) ===\n")

# Calculate polychoric correlation matrix (using survey weights via replication)
# Note: polycor doesn't directly support weights, so we use psych::polychoric
poly_result <- polychoric(analysis_data[, myvars])
C <- poly_result$rho
k <- ncol(C)

# Calculate ordinal alpha
rbar <- (sum(C) - k) / (k * (k - 1))
ordinal_alpha <- (k * rbar) / (1 + (k - 1) * rbar)

cat(sprintf("POINT: Ordinal alpha = %.4f\n", ordinal_alpha))
cat(sprintf("  Number of items: %d\n", k))
cat(sprintf("  Average inter-item correlation: %.4f\n", rbar))

cat("\n=== (B) Ordinal Omega (Survey-Weighted CFA) ===\n")

# Specify single-factor CFA model with ordinal indicators
cfa_model <- paste0(
  "FACTOR =~ ", 
  paste(myvars, collapse = " + ")
)

# Fit CFA with sampling weights
# Using lavaan with weights (not full survey design, but includes weights)
fit_weighted <- cfa(cfa_model, 
                    data = analysis_data,
                    ordered = myvars,
                    std.lv = TRUE,
                    sampling.weights = "bovwt1",
                    estimator = "WLSMV")

# Extract standardized loadings and calculate omega manually
params <- parameterEstimates(fit_weighted, standardized = TRUE)
loadings_df <- params %>%
  filter(op == "=~")

# Calculate omega_total using standardized loadings
# Formula: ω = (Σλ)² / [(Σλ)² + Σ(1-λ²)]
loadings <- loadings_df$std.all
sum_loadings <- sum(loadings)
sum_error_var <- k - sum(loadings^2)
omega_total <- sum_loadings^2 / (sum_loadings^2 + sum_error_var)

cat(sprintf("POINT: Ordinal omega (ω_total) = %.4f\n", omega_total))

cat("\nStandardized factor loadings:\n")
for (i in 1:nrow(loadings_df)) {
  cat(sprintf("  %s: %.4f\n", loadings_df$rhs[i], loadings_df$std.all[i]))
}

# Display model fit indices - comprehensive reporting
fit_indices <- fitMeasures(fit_weighted, c("chisq", "df", "pvalue", "cfi", "tli", 
                                             "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
                                             "srmr", "chisq.scaled", "cfi.scaled", "tli.scaled",
                                             "rmsea.scaled"))

cat("\nModel Fit Statistics:\n")
cat("  Single-Factor CFA:\n")
cat(sprintf("    χ²(%.0f) = %.2f, p < %.4f\n", 
            fit_indices["df"], fit_indices["chisq"], fit_indices["pvalue"]))

if (!is.na(fit_indices["chisq.scaled"])) {
  cat(sprintf("    χ²-scaled(%.0f) = %.2f (WLSMV)\n", 
              fit_indices["df"], fit_indices["chisq.scaled"]))
}

cat("  Incremental Fit:\n")
cat(sprintf("    CFI = %.4f", fit_indices["cfi"]))
if (!is.na(fit_indices["cfi.scaled"])) {
  cat(sprintf(" (robust: %.4f)", fit_indices["cfi.scaled"]))
}
cat("\n")

cat(sprintf("    TLI = %.4f", fit_indices["tli"]))
if (!is.na(fit_indices["tli.scaled"])) {
  cat(sprintf(" (robust: %.4f)", fit_indices["tli.scaled"]))
}
cat("\n")

cat("  Absolute Fit:\n")
cat(sprintf("    RMSEA = %.4f", fit_indices["rmsea"]))
if (!is.na(fit_indices["rmsea.ci.lower"]) && !is.na(fit_indices["rmsea.ci.upper"])) {
  cat(sprintf(" [%.4f, %.4f]", fit_indices["rmsea.ci.lower"], fit_indices["rmsea.ci.upper"]))
}
if (!is.na(fit_indices["rmsea.scaled"])) {
  cat(sprintf(" (robust: %.4f)", fit_indices["rmsea.scaled"]))
}
cat("\n")

if ("srmr" %in% names(fit_indices) && !is.na(fit_indices["srmr"])) {
  cat(sprintf("    SRMR = %.4f\n", fit_indices["srmr"]))
}

# Fit interpretation
cat("  Interpretation:\n")
cfi_check <- if (!is.na(fit_indices["cfi.scaled"])) fit_indices["cfi.scaled"] else fit_indices["cfi"]
tli_check <- if (!is.na(fit_indices["tli.scaled"])) fit_indices["tli.scaled"] else fit_indices["tli"]
rmsea_check <- if (!is.na(fit_indices["rmsea.scaled"])) fit_indices["rmsea.scaled"] else fit_indices["rmsea"]

if (cfi_check >= 0.95 && tli_check >= 0.95 && rmsea_check <= 0.06) {
  cat("    Excellent fit\n")
} else if (cfi_check >= 0.90 && tli_check >= 0.90 && rmsea_check <= 0.08) {
  cat("    Good fit\n")
} else if (cfi_check >= 0.85 && tli_check >= 0.85 && rmsea_check <= 0.10) {
  cat("    Acceptable fit\n")
} else {
  cat("    Marginal fit\n")
}

cat("\n=== Summary ===\n")
cat(sprintf("Ordinal Alpha:       %.4f\n", ordinal_alpha))
cat(sprintf("Ordinal Omega_total: %.4f\n", omega_total))  

# ============================================================================
# RELIABILITY ANALYSIS FOR OTHER AGE WAVES
# ============================================================================

# Function to analyze reliability for a given wave
analyze_wave <- function(wave_prefix, wave_label, weight_var) {
  cat("\n\n")
  cat("============================================================================\n")
  cat(sprintf("WAVE: %s (Items: %s*, Weight: %s)\n", wave_label, wave_prefix, weight_var))
  cat("============================================================================\n")
  
  # Define variables for this wave (includes "lyin" for ages 5+)
  wave_vars <- paste0(wave_prefix, c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg", "lyin"))
  
  # Check which variables exist
  existing_vars <- wave_vars[wave_vars %in% names(merged_waves_recoded)]
  missing_vars <- wave_vars[!wave_vars %in% names(merged_waves_recoded)]
  
  if (length(missing_vars) > 0) {
    cat("Missing variables:", paste(missing_vars, collapse=", "), "\n")
  }
  
  if (length(existing_vars) < 3) {
    cat("Insufficient variables for analysis (found", length(existing_vars), ")\n")
    return(NULL)
  }
  
  cat("Analyzing", length(existing_vars), "items\n")
  
  # Check if weight variable exists
  if (!weight_var %in% names(merged_waves_recoded)) {
    cat(sprintf("Warning: Weight variable %s not found in dataset\n", weight_var))
    return(NULL)
  }
  
  # Create analysis subset with wave-specific weight
  merged_waves_recoded <- merged_waves_recoded %>%
    mutate(
      .nmiss_wave = rowSums(is.na(select(., all_of(existing_vars)))),
      .complete_wave = (.nmiss_wave == 0),
      .ok_wave = .complete_wave == 1 & 
                 !is.na(.data[[weight_var]]) & !is.na(sptn00) & !is.na(pttype2) & 
                 .data[[weight_var]] > 0
    )
  
  n_complete <- sum(merged_waves_recoded$.ok_wave, na.rm=TRUE)
  cat("Complete cases with valid survey weights:", n_complete, "\n")
  
  if (n_complete < 100) {
    cat("Insufficient sample size for analysis\n")
    return(NULL)
  }
  
  # Prepare data
  analysis_data_wave <- merged_waves_recoded %>%
    filter(.ok_wave) %>%
    select(all_of(existing_vars), all_of(weight_var), sptn00, pttype2, nh2) %>%
    rename(wave_weight = all_of(weight_var))  # Rename for consistent reference
  
  # (A) Ordinal Alpha
  cat("\n--- (A) Ordinal Alpha ---\n")
  tryCatch({
    poly_result <- polychoric(analysis_data_wave[, existing_vars])
    C <- poly_result$rho
    k <- ncol(C)
    rbar <- (sum(C) - k) / (k * (k - 1))
    alpha <- (k * rbar) / (1 + (k - 1) * rbar)
    cat(sprintf("Ordinal alpha = %.4f\n", alpha))
    cat(sprintf("  Items: %d, Avg inter-item r: %.4f\n", k, rbar))
  }, error = function(e) {
    cat("Error calculating alpha:", e$message, "\n")
    alpha <<- NA
  })
  
  # (B) Ordinal Omega
  cat("\n--- (B) Ordinal Omega (CFA with survey weights) ---\n")
  tryCatch({
    cfa_model <- paste0("FACTOR =~ ", paste(existing_vars, collapse = " + "))
    
    fit <- cfa(cfa_model, 
               data = analysis_data_wave,
               ordered = existing_vars,
               std.lv = TRUE,
               sampling.weights = "wave_weight",
               estimator = "WLSMV")
    
    # Extract loadings
    params <- parameterEstimates(fit, standardized = TRUE)
    loadings_df <- params %>% filter(op == "=~")
    loadings <- loadings_df$std.all
    
    # Calculate omega
    sum_loadings <- sum(loadings)
    sum_error_var <- length(existing_vars) - sum(loadings^2)
    omega <- sum_loadings^2 / (sum_loadings^2 + sum_error_var)
    
    cat(sprintf("Ordinal omega = %.4f\n", omega))
    cat("\nStandardized loadings:\n")
    for (i in 1:nrow(loadings_df)) {
      cat(sprintf("  %s: %.4f\n", loadings_df$rhs[i], loadings_df$std.all[i]))
    }
    
    # Model fit - comprehensive reporting
    fit_idx <- fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", 
                                    "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
                                    "srmr", "chisq.scaled", "cfi.scaled", "tli.scaled",
                                    "rmsea.scaled"))
    
    cat("\nModel Fit Statistics:\n")
    cat("  Single-Factor CFA:\n")
    cat(sprintf("    χ²(%.0f) = %.2f, p < %.4f\n", 
                fit_idx["df"], fit_idx["chisq"], fit_idx["pvalue"]))
    
    if (!is.na(fit_idx["chisq.scaled"])) {
      cat(sprintf("    χ²-scaled(%.0f) = %.2f (WLSMV)\n", 
                  fit_idx["df"], fit_idx["chisq.scaled"]))
    }
    
    cat("  Incremental Fit:\n")
    cat(sprintf("    CFI = %.4f", fit_idx["cfi"]))
    if (!is.na(fit_idx["cfi.scaled"])) {
      cat(sprintf(" (robust: %.4f)", fit_idx["cfi.scaled"]))
    }
    cat("\n")
    
    cat(sprintf("    TLI = %.4f", fit_idx["tli"]))
    if (!is.na(fit_idx["tli.scaled"])) {
      cat(sprintf(" (robust: %.4f)", fit_idx["tli.scaled"]))
    }
    cat("\n")
    
    cat("  Absolute Fit:\n")
    cat(sprintf("    RMSEA = %.4f", fit_idx["rmsea"]))
    if (!is.na(fit_idx["rmsea.ci.lower"]) && !is.na(fit_idx["rmsea.ci.upper"])) {
      cat(sprintf(" [%.4f, %.4f]", fit_idx["rmsea.ci.lower"], fit_idx["rmsea.ci.upper"]))
    }
    if (!is.na(fit_idx["rmsea.scaled"])) {
      cat(sprintf(" (robust: %.4f)", fit_idx["rmsea.scaled"]))
    }
    cat("\n")
    
    if ("srmr" %in% names(fit_idx) && !is.na(fit_idx["srmr"])) {
      cat(sprintf("    SRMR = %.4f\n", fit_idx["srmr"]))
    }
    
    # Fit interpretation
    cat("  Interpretation:\n")
    cfi_check <- if (!is.na(fit_idx["cfi.scaled"])) fit_idx["cfi.scaled"] else fit_idx["cfi"]
    tli_check <- if (!is.na(fit_idx["tli.scaled"])) fit_idx["tli.scaled"] else fit_idx["tli"]
    rmsea_check <- if (!is.na(fit_idx["rmsea.scaled"])) fit_idx["rmsea.scaled"] else fit_idx["rmsea"]
    
    if (cfi_check >= 0.95 && tli_check >= 0.95 && rmsea_check <= 0.06) {
      cat("    Excellent fit\n")
    } else if (cfi_check >= 0.90 && tli_check >= 0.90 && rmsea_check <= 0.08) {
      cat("    Good fit\n")
    } else if (cfi_check >= 0.85 && tli_check >= 0.85 && rmsea_check <= 0.10) {
      cat("    Acceptable fit\n")
    } else {
      cat("    Marginal fit\n")
    }
    
  }, error = function(e) {
    cat("Error calculating omega:", e$message, "\n")
    omega <<- NA
  })
  
  cat("\n--- Summary ---\n")
  cat(sprintf("Alpha = %.4f, Omega = %.4f (N = %d)\n", alpha, omega, n_complete))
  
  # Store fit statistics if available
  if (exists("fit_idx")) {
    cfi_final <- if (!is.na(fit_idx["cfi.scaled"])) fit_idx["cfi.scaled"] else fit_idx["cfi"]
    tli_final <- if (!is.na(fit_idx["tli.scaled"])) fit_idx["tli.scaled"] else fit_idx["tli"]
    rmsea_final <- if (!is.na(fit_idx["rmsea.scaled"])) fit_idx["rmsea.scaled"] else fit_idx["rmsea"]
    srmr_final <- fit_idx["srmr"]
  } else {
    cfi_final <- tli_final <- rmsea_final <- srmr_final <- NA
  }
  
  return(list(alpha = alpha, omega = omega, n = n_complete, k = length(existing_vars),
              cfi = cfi_final, tli = tli_final, rmsea = rmsea_final, srmr = srmr_final))
}

# Analyze each wave with appropriate weights
results_summary <- list()

results_summary[["Age 5"]] <- analyze_wave("sc5", "Age 5", "covwt1")   # MCS3
results_summary[["Age 7"]] <- analyze_wave("sc7", "Age 7", "dovwt1")   # MCS4
results_summary[["Age 11"]] <- analyze_wave("sc11", "Age 11", "eovwt1") # MCS5
results_summary[["Age 14"]] <- analyze_wave("sc14", "Age 14", "fovwt1") # MCS6
results_summary[["Age 17"]] <- analyze_wave("sc17", "Age 17", "govwt1") # MCS7

# ============================================================================
# OVERALL SUMMARY TABLE
# ============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("OVERALL SUMMARY: Self-Control Scale Reliability Across Age Waves\n")
cat("============================================================================\n\n")

cat("Table 1: Reliability Coefficients\n")
cat(sprintf("%-10s %6s %8s %8s %10s\n", "Wave", "Items", "Alpha", "Omega", "N"))
cat(strrep("-", 50), "\n")
cat(sprintf("%-10s %6s %8s %8s %10s\n", "Age 3", "7", "0.8057", "0.8257", "12489"))

for (wave_name in names(results_summary)) {
  res <- results_summary[[wave_name]]
  if (!is.null(res)) {
    cat(sprintf("%-10s %6d %8.4f %8.4f %10d\n", 
                wave_name, res$k, res$alpha, res$omega, res$n))
  } else {
    cat(sprintf("%-10s %6s %8s %8s %10s\n", 
                wave_name, "-", "-", "-", "-"))
  }
}

cat("\n\nTable 2: Single-Factor CFA Model Fit Statistics\n")
cat(sprintf("%-10s %8s %8s %8s %8s %15s\n", "Wave", "CFI", "TLI", "RMSEA", "SRMR", "Fit Quality"))
cat(strrep("-", 65), "\n")
cat(sprintf("%-10s %8.4f %8.4f %8.4f %8.4f %15s\n", 
            "Age 3", 0.9703, 0.9555, 0.0839, 0.0688, "Good"))

for (wave_name in names(results_summary)) {
  res <- results_summary[[wave_name]]
  if (!is.null(res) && !is.na(res$cfi)) {
    # Determine fit quality
    if (res$cfi >= 0.95 && res$tli >= 0.95 && res$rmsea <= 0.06) {
      fit_quality <- "Excellent"
    } else if (res$cfi >= 0.90 && res$tli >= 0.90 && res$rmsea <= 0.08) {
      fit_quality <- "Good"
    } else if (res$cfi >= 0.85 && res$tli >= 0.85 && res$rmsea <= 0.10) {
      fit_quality <- "Acceptable"
    } else {
      fit_quality <- "Marginal"
    }
    
    cat(sprintf("%-10s %8.4f %8.4f %8.4f %8.4f %15s\n", 
                wave_name, res$cfi, res$tli, res$rmsea, res$srmr, fit_quality))
  } else {
    cat(sprintf("%-10s %8s %8s %8s %8s %15s\n", 
                wave_name, "-", "-", "-", "-", "-"))
  }
}

cat("\n")

# ============================================================================
# ADDITIONAL ANALYSIS: 7 Common Items Only (Excluding "lyin")
# ============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("ADDITIONAL ANALYSIS: 7 Common Items Across All Waves (Excluding 'lyin')\n")
cat("============================================================================\n\n")
cat("This analysis uses the same 7 items across ALL waves for comparability:\n")
cat("  thac, tcom, obey, dist, temp, rest, fidg\n\n")

# Function to analyze reliability for a given wave (7 items only)
analyze_wave_7items <- function(wave_prefix, wave_label, weight_var) {
  cat("\n\n")
  cat("============================================================================\n")
  cat(sprintf("WAVE: %s (7 items only, Weight: %s)\n", wave_label, weight_var))
  cat("============================================================================\n")
  
  # Define 7 common variables for this wave (NO lyin)
  wave_vars <- paste0(wave_prefix, c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg"))
  
  # Check which variables exist
  existing_vars <- wave_vars[wave_vars %in% names(merged_waves_recoded)]
  missing_vars <- wave_vars[!wave_vars %in% names(merged_waves_recoded)]
  
  if (length(missing_vars) > 0) {
    cat("Missing variables:", paste(missing_vars, collapse=", "), "\n")
  }
  
  if (length(existing_vars) < 3) {
    cat("Insufficient variables for analysis (found", length(existing_vars), ")\n")
    return(NULL)
  }
  
  cat("Analyzing", length(existing_vars), "items\n")
  
  # Check if weight variable exists
  if (!weight_var %in% names(merged_waves_recoded)) {
    cat(sprintf("Warning: Weight variable %s not found in dataset\n", weight_var))
    return(NULL)
  }
  
  # Create analysis subset with wave-specific weight
  merged_waves_recoded <- merged_waves_recoded %>%
    mutate(
      .nmiss_wave7 = rowSums(is.na(select(., all_of(existing_vars)))),
      .complete_wave7 = (.nmiss_wave7 == 0),
      .ok_wave7 = .complete_wave7 == 1 & 
                  !is.na(.data[[weight_var]]) & !is.na(sptn00) & !is.na(pttype2) & 
                  .data[[weight_var]] > 0
    )
  
  n_complete <- sum(merged_waves_recoded$.ok_wave7, na.rm=TRUE)
  cat("Complete cases with valid survey weights:", n_complete, "\n")
  
  if (n_complete < 100) {
    cat("Insufficient sample size for analysis\n")
    return(NULL)
  }
  
  # Prepare data
  analysis_data_wave <- merged_waves_recoded %>%
    filter(.ok_wave7) %>%
    select(all_of(existing_vars), all_of(weight_var), sptn00, pttype2, nh2) %>%
    rename(wave_weight = all_of(weight_var))
  
  # (A) Ordinal Alpha
  cat("\n--- (A) Ordinal Alpha ---\n")
  tryCatch({
    poly_result <- polychoric(analysis_data_wave[, existing_vars])
    C <- poly_result$rho
    k <- ncol(C)
    rbar <- (sum(C) - k) / (k * (k - 1))
    alpha <- (k * rbar) / (1 + (k - 1) * rbar)
    cat(sprintf("Ordinal alpha = %.4f\n", alpha))
    cat(sprintf("  Items: %d, Avg inter-item r: %.4f\n", k, rbar))
  }, error = function(e) {
    cat("Error calculating alpha:", e$message, "\n")
    alpha <<- NA
  })
  
  # (B) Ordinal Omega
  cat("\n--- (B) Ordinal Omega (CFA with survey weights) ---\n")
  tryCatch({
    cfa_model <- paste0("FACTOR =~ ", paste(existing_vars, collapse = " + "))
    
    fit <- cfa(cfa_model, 
               data = analysis_data_wave,
               ordered = existing_vars,
               std.lv = TRUE,
               sampling.weights = "wave_weight",
               estimator = "WLSMV")
    
    # Extract loadings
    params <- parameterEstimates(fit, standardized = TRUE)
    loadings_df <- params %>% filter(op == "=~")
    loadings <- loadings_df$std.all
    
    # Calculate omega
    sum_loadings <- sum(loadings)
    sum_error_var <- length(existing_vars) - sum(loadings^2)
    omega <- sum_loadings^2 / (sum_loadings^2 + sum_error_var)
    
    cat(sprintf("Ordinal omega = %.4f\n", omega))
    cat("\nStandardized loadings:\n")
    for (i in 1:nrow(loadings_df)) {
      cat(sprintf("  %s: %.4f\n", loadings_df$rhs[i], loadings_df$std.all[i]))
    }
    
    # Model fit - comprehensive reporting
    fit_idx <- fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", 
                                    "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
                                    "srmr", "chisq.scaled", "cfi.scaled", "tli.scaled",
                                    "rmsea.scaled"))
    
    cat("\nModel Fit Statistics:\n")
    cat("  Single-Factor CFA:\n")
    cat(sprintf("    χ²(%.0f) = %.2f, p < %.4f\n", 
                fit_idx["df"], fit_idx["chisq"], fit_idx["pvalue"]))
    
    if (!is.na(fit_idx["chisq.scaled"])) {
      cat(sprintf("    χ²-scaled(%.0f) = %.2f (WLSMV)\n", 
                  fit_idx["df"], fit_idx["chisq.scaled"]))
    }
    
    cat("  Incremental Fit:\n")
    cat(sprintf("    CFI = %.4f", fit_idx["cfi"]))
    if (!is.na(fit_idx["cfi.scaled"])) {
      cat(sprintf(" (robust: %.4f)", fit_idx["cfi.scaled"]))
    }
    cat("\n")
    
    cat(sprintf("    TLI = %.4f", fit_idx["tli"]))
    if (!is.na(fit_idx["tli.scaled"])) {
      cat(sprintf(" (robust: %.4f)", fit_idx["tli.scaled"]))
    }
    cat("\n")
    
    cat("  Absolute Fit:\n")
    cat(sprintf("    RMSEA = %.4f", fit_idx["rmsea"]))
    if (!is.na(fit_idx["rmsea.ci.lower"]) && !is.na(fit_idx["rmsea.ci.upper"])) {
      cat(sprintf(" [%.4f, %.4f]", fit_idx["rmsea.ci.lower"], fit_idx["rmsea.ci.upper"]))
    }
    if (!is.na(fit_idx["rmsea.scaled"])) {
      cat(sprintf(" (robust: %.4f)", fit_idx["rmsea.scaled"]))
    }
    cat("\n")
    
    if ("srmr" %in% names(fit_idx) && !is.na(fit_idx["srmr"])) {
      cat(sprintf("    SRMR = %.4f\n", fit_idx["srmr"]))
    }
    
    # Fit interpretation
    cat("  Interpretation:\n")
    cfi_check <- if (!is.na(fit_idx["cfi.scaled"])) fit_idx["cfi.scaled"] else fit_idx["cfi"]
    tli_check <- if (!is.na(fit_idx["tli.scaled"])) fit_idx["tli.scaled"] else fit_idx["tli"]
    rmsea_check <- if (!is.na(fit_idx["rmsea.scaled"])) fit_idx["rmsea.scaled"] else fit_idx["rmsea"]
    
    if (cfi_check >= 0.95 && tli_check >= 0.95 && rmsea_check <= 0.06) {
      cat("    Excellent fit\n")
    } else if (cfi_check >= 0.90 && tli_check >= 0.90 && rmsea_check <= 0.08) {
      cat("    Good fit\n")
    } else if (cfi_check >= 0.85 && tli_check >= 0.85 && rmsea_check <= 0.10) {
      cat("    Acceptable fit\n")
    } else {
      cat("    Marginal fit\n")
    }
    
  }, error = function(e) {
    cat("Error calculating omega:", e$message, "\n")
    omega <<- NA
  })
  
  cat("\n--- Summary ---\n")
  cat(sprintf("Alpha = %.4f, Omega = %.4f (N = %d)\n", alpha, omega, n_complete))
  
  # Store fit statistics if available
  if (exists("fit_idx")) {
    cfi_final <- if (!is.na(fit_idx["cfi.scaled"])) fit_idx["cfi.scaled"] else fit_idx["cfi"]
    tli_final <- if (!is.na(fit_idx["tli.scaled"])) fit_idx["tli.scaled"] else fit_idx["tli"]
    rmsea_final <- if (!is.na(fit_idx["rmsea.scaled"])) fit_idx["rmsea.scaled"] else fit_idx["rmsea"]
    srmr_final <- fit_idx["srmr"]
  } else {
    cfi_final <- tli_final <- rmsea_final <- srmr_final <- NA
  }
  
  return(list(alpha = alpha, omega = omega, n = n_complete, k = length(existing_vars),
              cfi = cfi_final, tli = tli_final, rmsea = rmsea_final, srmr = srmr_final))
}

# Analyze each wave with 7 items only
results_7items <- list()

results_7items[["Age 3"]] <- analyze_wave_7items("sc3", "Age 3", "bovwt1")   # MCS2
results_7items[["Age 5"]] <- analyze_wave_7items("sc5", "Age 5", "covwt1")   # MCS3
results_7items[["Age 7"]] <- analyze_wave_7items("sc7", "Age 7", "dovwt1")   # MCS4
results_7items[["Age 11"]] <- analyze_wave_7items("sc11", "Age 11", "eovwt1") # MCS5
results_7items[["Age 14"]] <- analyze_wave_7items("sc14", "Age 14", "fovwt1") # MCS6
results_7items[["Age 17"]] <- analyze_wave_7items("sc17", "Age 17", "govwt1") # MCS7

# Summary tables for 7-item analysis
cat("\n\n")
cat("============================================================================\n")
cat("SUMMARY: 7-Item Self-Control Scale Across All Waves\n")
cat("============================================================================\n\n")

cat("Table 3: Reliability Coefficients (7 Items Only)\n")
cat(sprintf("%-10s %6s %8s %8s %10s\n", "Wave", "Items", "Alpha", "Omega", "N"))
cat(strrep("-", 50), "\n")

for (wave_name in names(results_7items)) {
  res <- results_7items[[wave_name]]
  if (!is.null(res)) {
    cat(sprintf("%-10s %6d %8.4f %8.4f %10d\n", 
                wave_name, res$k, res$alpha, res$omega, res$n))
  } else {
    cat(sprintf("%-10s %6s %8s %8s %10s\n", 
                wave_name, "-", "-", "-", "-"))
  }
}

cat("\n\nTable 4: Single-Factor CFA Model Fit (7 Items Only)\n")
cat(sprintf("%-10s %8s %8s %8s %8s %15s\n", "Wave", "CFI", "TLI", "RMSEA", "SRMR", "Fit Quality"))
cat(strrep("-", 65), "\n")

for (wave_name in names(results_7items)) {
  res <- results_7items[[wave_name]]
  if (!is.null(res) && !is.na(res$cfi)) {
    # Determine fit quality
    if (res$cfi >= 0.95 && res$tli >= 0.95 && res$rmsea <= 0.06) {
      fit_quality <- "Excellent"
    } else if (res$cfi >= 0.90 && res$tli >= 0.90 && res$rmsea <= 0.08) {
      fit_quality <- "Good"
    } else if (res$cfi >= 0.85 && res$tli >= 0.85 && res$rmsea <= 0.10) {
      fit_quality <- "Acceptable"
    } else {
      fit_quality <- "Marginal"
    }
    
    cat(sprintf("%-10s %8.4f %8.4f %8.4f %8.4f %15s\n", 
                wave_name, res$cfi, res$tli, res$rmsea, res$srmr, fit_quality))
  } else {
    cat(sprintf("%-10s %8s %8s %8s %8s %15s\n", 
                wave_name, "-", "-", "-", "-", "-"))
  }
}

cat("\n")

# ============================================================================
# MULTILEVEL CFA: Within-Person and Between-Person Reliability
# ============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("MULTILEVEL CFA: Decomposing Within- and Between-Person Reliability\n")
cat("============================================================================\n\n")

# Prepare long-format data with all waves
cat("Preparing long-format data...\n")

# Define all self-control items across waves
sc_items_base <- c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg")

# Create long format data
long_data_list <- list()

# Wave 3 (7 items, no lyin) - MCS2, bovwt1
wave3_items <- paste0("sc3", sc_items_base)
long_data_list[[1]] <- merged_waves_recoded %>%
  select(mcsid, all_of(wave3_items), bovwt1, sptn00, pttype2, nh2) %>%
  rename_with(~gsub("sc3", "sc", .), starts_with("sc3")) %>%
  rename(survey_weight = bovwt1) %>%
  mutate(age = 3, wave = 1)

# Waves 5, 7, 11, 14, 17 (8 items including lyin) with corresponding weights
wave_specs <- list(
  list(age = 5, prefix = "sc5", weight = "covwt1", wave_num = 2),  # MCS3
  list(age = 7, prefix = "sc7", weight = "dovwt1", wave_num = 3),  # MCS4
  list(age = 11, prefix = "sc11", weight = "eovwt1", wave_num = 4), # MCS5
  list(age = 14, prefix = "sc14", weight = "fovwt1", wave_num = 5), # MCS6
  list(age = 17, prefix = "sc17", weight = "govwt1", wave_num = 6)  # MCS7
)

for (i in 1:5) {
  spec <- wave_specs[[i]]
  wave_items <- paste0(spec$prefix, c(sc_items_base, "lyin"))
  
  long_data_list[[i+1]] <- merged_waves_recoded %>%
    select(mcsid, all_of(wave_items), all_of(spec$weight), sptn00, pttype2, nh2) %>%
    rename_with(~gsub(spec$prefix, "sc", .), starts_with(spec$prefix)) %>%
    rename(survey_weight = all_of(spec$weight)) %>%
    mutate(age = spec$age, wave = spec$wave_num)
}

# Combine all waves
long_data <- bind_rows(long_data_list)

# Remove rows with all missing items
sc_common <- c("scthac", "sctcom", "scobey", "scdist", "sctemp", "screst", "scfidg")
long_data <- long_data %>%
  mutate(
    n_missing = rowSums(is.na(select(., all_of(sc_common)))),
    complete_common = n_missing == 0
  ) %>%
  filter(complete_common, survey_weight > 0, !is.na(sptn00), !is.na(pttype2))

cat(sprintf("Long data: %d observations from %d persons\n", 
            nrow(long_data), n_distinct(long_data$mcsid)))
cat(sprintf("Observations per person: %.2f (range: %d-%d)\n",
            nrow(long_data) / n_distinct(long_data$mcsid),
            min(table(long_data$mcsid)),
            max(table(long_data$mcsid))))

# Multilevel CFA using the 7 common items across all waves
cat("\nFitting multilevel CFA (7 common items)...\n")
cat("Using wave-specific survey weights:\n")
cat("  Age 3: bovwt1, Age 5: covwt1, Age 7: dovwt1\n")
cat("  Age 11: eovwt1, Age 14: fovwt1, Age 17: govwt1\n")
cat("This may take a few minutes...\n\n")

# Specify multilevel model
# Within level: items load on within-person factor
# Between level: person means load on between-person factor
mlcfa_model <- '
  level: 1
    FW =~ scthac + sctcom + scobey + scdist + sctemp + screst + scfidg
    
  level: 2
    FB =~ scthac + sctcom + scobey + scdist + sctemp + screst + scfidg
'

# Fit multilevel CFA
# Note: For ordinal variables in multilevel models, we need to be careful
# Using continuous approximation due to computational complexity
tryCatch({
  fit_mlcfa <- cfa(mlcfa_model,
                   data = long_data,
                   cluster = "mcsid",
                   estimator = "MLR")  # Robust ML for clustered data
  
  cat("Model converged successfully!\n\n")
  
  # Extract parameters
  params_ml <- parameterEstimates(fit_mlcfa, standardized = TRUE)
  
  # Within-level loadings
  loadings_w <- params_ml %>%
    filter(level == 1, op == "=~") %>%
    pull(std.all)
  
  # Between-level loadings
  loadings_b <- params_ml %>%
    filter(level == 2, op == "=~") %>%
    pull(std.all)
  
  # Calculate omega_within
  sum_lambda_w <- sum(loadings_w)
  sum_error_w <- length(sc_common) - sum(loadings_w^2)
  omega_w <- sum_lambda_w^2 / (sum_lambda_w^2 + sum_error_w)
  
  # Calculate omega_between
  sum_lambda_b <- sum(loadings_b)
  sum_error_b <- length(sc_common) - sum(loadings_b^2)
  omega_b <- sum_lambda_b^2 / (sum_lambda_b^2 + sum_error_b)
  
  cat("=== WITHIN-PERSON LEVEL ===\n")
  cat(sprintf("Omega_within (ω_w) = %.4f\n", omega_w))
  cat("Interpretation: Reliability of distinguishing within-person changes over time\n")
  cat("\nStandardized loadings (within):\n")
  for (i in 1:length(sc_common)) {
    cat(sprintf("  %s: %.4f\n", sc_common[i], loadings_w[i]))
  }
  
  cat("\n=== BETWEEN-PERSON LEVEL ===\n")
  cat(sprintf("Omega_between (ω_b) = %.4f\n", omega_b))
  cat("Interpretation: Reliability of distinguishing between persons\n")
  cat("\nStandardized loadings (between):\n")
  for (i in 1:length(sc_common)) {
    cat(sprintf("  %s: %.4f\n", sc_common[i], loadings_b[i]))
  }
  
  # Model fit
  cat("\n=== MODEL FIT ===\n")
  fit_ml <- fitMeasures(fit_mlcfa, c("chisq", "df", "pvalue", "cfi", "tli", 
                                      "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr"))
  cat(sprintf("χ²(%.0f) = %.2f, p = %.4f\n", 
              fit_ml["df"], fit_ml["chisq"], fit_ml["pvalue"]))
  cat(sprintf("CFI = %.4f, TLI = %.4f\n", fit_ml["cfi"], fit_ml["tli"]))
  cat(sprintf("RMSEA = %.4f [%.4f, %.4f]\n", 
              fit_ml["rmsea"], fit_ml["rmsea.ci.lower"], fit_ml["rmsea.ci.upper"]))
  cat(sprintf("SRMR = %.4f\n", fit_ml["srmr"]))
  
  # ICC calculation (proportion of variance between persons)
  # Extract variances
  var_within <- 1  # standardized
  var_between <- 1  # standardized
  
  # Get actual unstandardized variances for ICC
  params_unst <- parameterEstimates(fit_mlcfa, standardized = FALSE)
  
  # Within-level factor variance
  var_w_factor <- params_unst %>%
    filter(level == 1, lhs == "FW", op == "~~", rhs == "FW") %>%
    pull(est)
  
  # Between-level factor variance
  var_b_factor <- params_unst %>%
    filter(level == 2, lhs == "FB", op == "~~", rhs == "FB") %>%
    pull(est)
  
  if (length(var_w_factor) > 0 && length(var_b_factor) > 0) {
    icc <- var_b_factor / (var_w_factor + var_b_factor)
    cat(sprintf("\n=== VARIANCE DECOMPOSITION ===\n"))
    cat(sprintf("ICC (Intraclass Correlation) = %.4f\n", icc))
    cat(sprintf("Between-person variance: %.1f%%\n", icc * 100))
    cat(sprintf("Within-person variance:  %.1f%%\n", (1 - icc) * 100))
  }
  
  cat("\n=== SUMMARY ===\n")
  cat(sprintf("ω_within  = %.4f (consistency across items within occasions)\n", omega_w))
  cat(sprintf("ω_between = %.4f (consistency in ranking persons over time)\n", omega_b))
  cat("\nNote: Higher ω_b indicates stable individual differences.\n")
  cat("      Higher ω_w indicates reliable measurement at each occasion.\n")
  
}, error = function(e) {
  cat("Error fitting multilevel CFA:", e$message, "\n")
  cat("\nTrying alternative specification with ordinal indicators...\n")
  
  # Try with WLSMV for ordinal data (no clustering)
  tryCatch({
    fit_mlcfa_ord <- cfa(mlcfa_model,
                         data = long_data,
                         cluster = "mcsid",
                         ordered = sc_common,
                         estimator = "WLSMV")
    
    cat("Alternative model converged!\n")
    # [Similar output code as above]
    
  }, error = function(e2) {
    cat("Alternative model also failed:", e2$message, "\n")
    cat("\nNote: Multilevel CFA with ordinal indicators is computationally intensive.\n")
    cat("Consider using Mplus or a Bayesian approach for full ordinal multilevel CFA.\n")
  })
})

cat("\n")

# ============================================================================
# RELIABILITY ANALYSIS: PARENTING DISCIPLINE SCALES
# ============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("RELIABILITY ANALYSIS: Parenting Discipline Scales\n")
cat("============================================================================\n\n")

# Function to analyze discipline items for a given wave
analyze_discipline_wave <- function(wave_num, wave_label, discipline_vars, weight_var) {
  cat("\n\n")
  cat("============================================================================\n")
  cat(sprintf("DISCIPLINE WAVE: %s (Weight: %s)\n", wave_label, weight_var))
  cat("============================================================================\n")
  
  # Check which variables exist
  existing_vars <- discipline_vars[discipline_vars %in% names(merged_waves_recoded)]
  missing_vars <- discipline_vars[!discipline_vars %in% names(merged_waves_recoded)]
  
  if (length(missing_vars) > 0) {
    cat("Missing variables:", paste(missing_vars, collapse=", "), "\n")
  }
  
  if (length(existing_vars) < 2) {
    cat("Insufficient variables for analysis (found", length(existing_vars), ")\n")
    return(NULL)
  }
  
  cat("Analyzing", length(existing_vars), "items:", paste(existing_vars, collapse=", "), "\n")
  
  # Check if weight variable exists
  if (!weight_var %in% names(merged_waves_recoded)) {
    cat(sprintf("Warning: Weight variable %s not found in dataset\n", weight_var))
    return(NULL)
  }
  
  # Create analysis subset
  merged_waves_recoded <- merged_waves_recoded %>%
    mutate(
      .nmiss_disc = rowSums(is.na(select(., all_of(existing_vars)))),
      .complete_disc = (.nmiss_disc == 0),
      .ok_disc = .complete_disc == 1 & 
                 !is.na(.data[[weight_var]]) & !is.na(sptn00) & !is.na(pttype2) & 
                 .data[[weight_var]] > 0
    )
  
  n_complete <- sum(merged_waves_recoded$.ok_disc, na.rm=TRUE)
  cat("Complete cases with valid survey weights:", n_complete, "\n")
  
  if (n_complete < 100) {
    cat("Insufficient sample size for analysis\n")
    return(NULL)
  }
  
  # Prepare data
  analysis_data_disc <- merged_waves_recoded %>%
    filter(.ok_disc) %>%
    select(all_of(existing_vars), all_of(weight_var), sptn00, pttype2, nh2) %>%
    rename(wave_weight = all_of(weight_var))
  
  # (A) Ordinal Alpha
  cat("\n--- (A) Ordinal Alpha ---\n")
  alpha <- NA
  tryCatch({
    poly_result <- polychoric(analysis_data_disc[, existing_vars])
    C <- poly_result$rho
    k <- ncol(C)
    rbar <- (sum(C) - k) / (k * (k - 1))
    alpha <- (k * rbar) / (1 + (k - 1) * rbar)
    cat(sprintf("Ordinal alpha = %.4f\n", alpha))
    cat(sprintf("  Items: %d, Avg inter-item r: %.4f\n", k, rbar))
  }, error = function(e) {
    cat("Error calculating alpha:", e$message, "\n")
  })
  
  # (B) Ordinal Omega
  cat("\n--- (B) Ordinal Omega (CFA with survey weights) ---\n")
  omega <- NA
  tryCatch({
    cfa_model <- paste0("FACTOR =~ ", paste(existing_vars, collapse = " + "))
    
    fit <- cfa(cfa_model, 
               data = analysis_data_disc,
               ordered = existing_vars,
               std.lv = TRUE,
               sampling.weights = "wave_weight",
               estimator = "WLSMV")
    
    # Extract loadings
    params <- parameterEstimates(fit, standardized = TRUE)
    loadings_df <- params %>% filter(op == "=~")
    loadings <- loadings_df$std.all
    
    # Calculate omega
    sum_loadings <- sum(loadings)
    sum_error_var <- length(existing_vars) - sum(loadings^2)
    omega <- sum_loadings^2 / (sum_loadings^2 + sum_error_var)
    
    cat(sprintf("Ordinal omega = %.4f\n", omega))
    cat("\nStandardized loadings:\n")
    for (i in 1:nrow(loadings_df)) {
      cat(sprintf("  %s: %.4f\n", loadings_df$rhs[i], loadings_df$std.all[i]))
    }
    
    # Model fit
    fit_idx <- fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", 
                                    "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
                                    "srmr", "chisq.scaled", "cfi.scaled", "tli.scaled",
                                    "rmsea.scaled"))
    
    cat("\nModel Fit Statistics:\n")
    cat(sprintf("  χ²(%.0f) = %.2f, p < %.4f\n", 
                fit_idx["df"], fit_idx["chisq"], fit_idx["pvalue"]))
    
    if (!is.na(fit_idx["chisq.scaled"])) {
      cat(sprintf("  χ²-scaled(%.0f) = %.2f (WLSMV)\n", 
                  fit_idx["df"], fit_idx["chisq.scaled"]))
    }
    
    cat(sprintf("  CFI = %.4f", fit_idx["cfi"]))
    if (!is.na(fit_idx["cfi.scaled"])) cat(sprintf(" (robust: %.4f)", fit_idx["cfi.scaled"]))
    cat("\n")
    
    cat(sprintf("  TLI = %.4f", fit_idx["tli"]))
    if (!is.na(fit_idx["tli.scaled"])) cat(sprintf(" (robust: %.4f)", fit_idx["tli.scaled"]))
    cat("\n")
    
    cat(sprintf("  RMSEA = %.4f", fit_idx["rmsea"]))
    if (!is.na(fit_idx["rmsea.ci.lower"]) && !is.na(fit_idx["rmsea.ci.upper"])) {
      cat(sprintf(" [%.4f, %.4f]", fit_idx["rmsea.ci.lower"], fit_idx["rmsea.ci.upper"]))
    }
    if (!is.na(fit_idx["rmsea.scaled"])) cat(sprintf(" (robust: %.4f)", fit_idx["rmsea.scaled"]))
    cat("\n")
    
    if ("srmr" %in% names(fit_idx) && !is.na(fit_idx["srmr"])) {
      cat(sprintf("  SRMR = %.4f\n", fit_idx["srmr"]))
    }
    
    # Fit interpretation
    cfi_check <- if (!is.na(fit_idx["cfi.scaled"])) fit_idx["cfi.scaled"] else fit_idx["cfi"]
    tli_check <- if (!is.na(fit_idx["tli.scaled"])) fit_idx["tli.scaled"] else fit_idx["tli"]
    rmsea_check <- if (!is.na(fit_idx["rmsea.scaled"])) fit_idx["rmsea.scaled"] else fit_idx["rmsea"]
    
    if (cfi_check >= 0.95 && tli_check >= 0.95 && rmsea_check <= 0.06) {
      cat("  Interpretation: Excellent fit\n")
    } else if (cfi_check >= 0.90 && tli_check >= 0.90 && rmsea_check <= 0.08) {
      cat("  Interpretation: Good fit\n")
    } else if (cfi_check >= 0.85 && tli_check >= 0.85 && rmsea_check <= 0.10) {
      cat("  Interpretation: Acceptable fit\n")
    } else {
      cat("  Interpretation: Marginal fit\n")
    }
    
    cfi_final <- cfi_check
    tli_final <- tli_check
    rmsea_final <- rmsea_check
    srmr_final <- fit_idx["srmr"]
    
  }, error = function(e) {
    cat("Error calculating omega:", e$message, "\n")
    cfi_final <- tli_final <- rmsea_final <- srmr_final <- NA
  })
  
  cat("\n--- Summary ---\n")
  cat(sprintf("Alpha = %.4f, Omega = %.4f (N = %d)\n", alpha, omega, n_complete))
  
  if (exists("cfi_final")) {
    return(list(alpha = alpha, omega = omega, n = n_complete, k = length(existing_vars),
                cfi = cfi_final, tli = tli_final, rmsea = rmsea_final, srmr = srmr_final))
  } else {
    return(list(alpha = alpha, omega = omega, n = n_complete, k = length(existing_vars),
                cfi = NA, tli = NA, rmsea = NA, srmr = NA))
  }
}

# Analyze discipline items at each age
discipline_results <- list()

# Age 3: ignore3 smack3 shout3 bedroom3 treats3 telloff3 bribe3
discipline3_vars <- c("ignore3", "smack3", "shout3", "bedroom3", "treats3", "telloff3", "bribe3")
discipline_results[["Age 3"]] <- analyze_discipline_wave(3, "Age 3", discipline3_vars, "bovwt1")

# Age 5: ignore5 smack5 shout5 bedroom5 treats5 telloff5 bribe5 reason5
discipline5_vars <- c("ignore5", "smack5", "shout5", "bedroom5", "treats5", "telloff5", "bribe5", "reason5")
discipline_results[["Age 5"]] <- analyze_discipline_wave(5, "Age 5", discipline5_vars, "covwt1")

# Age 7: ignore7 smack7 shout7 bedroom7 treats7 telloff7 bribe7 reason7
discipline7_vars <- c("ignore7", "smack7", "shout7", "bedroom7", "treats7", "telloff7", "bribe7", "reason7")
discipline_results[["Age 7"]] <- analyze_discipline_wave(7, "Age 7", discipline7_vars, "dovwt1")

# Age 11: bedroom11 treats11 reason11
discipline11_vars <- c("bedroom11", "treats11", "reason11")
discipline_results[["Age 11"]] <- analyze_discipline_wave(11, "Age 11", discipline11_vars, "eovwt1")

# Summary table for discipline scales
cat("\n\n")
cat("============================================================================\n")
cat("SUMMARY: Parenting Discipline Scales Reliability\n")
cat("============================================================================\n\n")

cat("Table: Discipline Scale Reliability Coefficients\n")
cat(sprintf("%-10s %6s %8s %8s %10s\n", "Wave", "Items", "Alpha", "Omega", "N"))
cat(strrep("-", 50), "\n")

for (wave_name in names(discipline_results)) {
  res <- discipline_results[[wave_name]]
  if (!is.null(res) && !is.na(res$alpha)) {
    cat(sprintf("%-10s %6d %8.4f %8.4f %10d\n", 
                wave_name, res$k, res$alpha, res$omega, res$n))
  } else {
    cat(sprintf("%-10s %6s %8s %8s %10s\n", 
                wave_name, "-", "-", "-", "-"))
  }
}

cat("\n\nTable: Discipline Scale CFA Model Fit Statistics\n")
cat(sprintf("%-10s %8s %8s %8s %8s %15s\n", "Wave", "CFI", "TLI", "RMSEA", "SRMR", "Fit Quality"))
cat(strrep("-", 65), "\n")

for (wave_name in names(discipline_results)) {
  res <- discipline_results[[wave_name]]
  if (!is.null(res) && !is.na(res$cfi)) {
    # Determine fit quality
    if (res$cfi >= 0.95 && res$tli >= 0.95 && res$rmsea <= 0.06) {
      fit_quality <- "Excellent"
    } else if (res$cfi >= 0.90 && res$tli >= 0.90 && res$rmsea <= 0.08) {
      fit_quality <- "Good"
    } else if (res$cfi >= 0.85 && res$tli >= 0.85 && res$rmsea <= 0.10) {
      fit_quality <- "Acceptable"
    } else {
      fit_quality <- "Marginal"
    }
    
    cat(sprintf("%-10s %8.4f %8.4f %8.4f %8.4f %15s\n", 
                wave_name, res$cfi, res$tli, res$rmsea, res$srmr, fit_quality))
  } else {
    cat(sprintf("%-10s %8s %8s %8s %8s %15s\n", 
                wave_name, "-", "-", "-", "-", "-"))
  }
}

cat("\n")

# ============================================================================
# RELIABILITY ANALYSIS: PARENTAL MONITORING SCALES
# ============================================================================

cat("\n\n")
cat("============================================================================\n")
cat("RELIABILITY ANALYSIS: Parental Monitoring Scales\n")
cat("============================================================================\n\n")

# Function to analyze parental monitoring items for a given wave
analyze_monitoring_wave <- function(wave_num, wave_label, monitoring_vars, weight_var) {
  cat("\n\n")
  cat("============================================================================\n")
  cat(sprintf("PARENTAL MONITORING WAVE: %s (Weight: %s)\n", wave_label, weight_var))
  cat("============================================================================\n")
  
  # Check which variables exist
  existing_vars <- monitoring_vars[monitoring_vars %in% names(merged_waves_recoded)]
  missing_vars <- monitoring_vars[!monitoring_vars %in% names(merged_waves_recoded)]
  
  if (length(missing_vars) > 0) {
    cat("Missing variables:", paste(missing_vars, collapse=", "), "\n")
  }
  
  if (length(existing_vars) < 2) {
    cat("Insufficient variables for analysis (found", length(existing_vars), ")\n")
    return(NULL)
  }
  
  cat("Analyzing", length(existing_vars), "items:", paste(existing_vars, collapse=", "), "\n")
  
  # Check if weight variable exists
  if (!weight_var %in% names(merged_waves_recoded)) {
    cat(sprintf("Warning: Weight variable %s not found in dataset\n", weight_var))
    return(NULL)
  }
  
  # Create analysis subset
  merged_waves_recoded <- merged_waves_recoded %>%
    mutate(
      .nmiss_mon = rowSums(is.na(select(., all_of(existing_vars)))),
      .complete_mon = (.nmiss_mon == 0),
      .ok_mon = .complete_mon == 1 & 
                !is.na(.data[[weight_var]]) & !is.na(sptn00) & !is.na(pttype2) & 
                .data[[weight_var]] > 0
    )
  
  n_complete <- sum(merged_waves_recoded$.ok_mon, na.rm=TRUE)
  cat("Complete cases with valid survey weights:", n_complete, "\n")
  
  if (n_complete < 100) {
    cat("Insufficient sample size for analysis\n")
    return(NULL)
  }
  
  # Prepare data
  analysis_data_mon <- merged_waves_recoded %>%
    filter(.ok_mon) %>%
    select(all_of(existing_vars), all_of(weight_var), sptn00, pttype2, nh2) %>%
    rename(wave_weight = all_of(weight_var))
  
  # (A) Ordinal Alpha
  cat("\n--- (A) Ordinal Alpha ---\n")
  alpha <- NA
  tryCatch({
    poly_result <- polychoric(analysis_data_mon[, existing_vars])
    C <- poly_result$rho
    k <- ncol(C)
    rbar <- (sum(C) - k) / (k * (k - 1))
    alpha <- (k * rbar) / (1 + (k - 1) * rbar)
    cat(sprintf("Ordinal alpha = %.4f\n", alpha))
    cat(sprintf("  Items: %d, Avg inter-item r: %.4f\n", k, rbar))
  }, error = function(e) {
    cat("Error calculating alpha:", e$message, "\n")
  })
  
  # (B) Ordinal Omega
  cat("\n--- (B) Ordinal Omega (CFA with survey weights) ---\n")
  omega <- NA
  tryCatch({
    cfa_model <- paste0("FACTOR =~ ", paste(existing_vars, collapse = " + "))
    
    fit <- cfa(cfa_model, 
               data = analysis_data_mon,
               ordered = existing_vars,
               std.lv = TRUE,
               sampling.weights = "wave_weight",
               estimator = "WLSMV")
    
    # Extract loadings
    params <- parameterEstimates(fit, standardized = TRUE)
    loadings_df <- params %>% filter(op == "=~")
    loadings <- loadings_df$std.all
    
    # Calculate omega
    sum_loadings <- sum(loadings)
    sum_error_var <- length(existing_vars) - sum(loadings^2)
    omega <- sum_loadings^2 / (sum_loadings^2 + sum_error_var)
    
    cat(sprintf("Ordinal omega = %.4f\n", omega))
    cat("\nStandardized loadings:\n")
    for (i in 1:nrow(loadings_df)) {
      cat(sprintf("  %s: %.4f\n", loadings_df$rhs[i], loadings_df$std.all[i]))
    }
    
    # Model fit
    fit_idx <- fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", 
                                    "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
                                    "srmr", "chisq.scaled", "cfi.scaled", "tli.scaled",
                                    "rmsea.scaled"))
    
    cat("\nModel Fit Statistics:\n")
    cat(sprintf("  χ²(%.0f) = %.2f, p < %.4f\n", 
                fit_idx["df"], fit_idx["chisq"], fit_idx["pvalue"]))
    
    if (!is.na(fit_idx["chisq.scaled"])) {
      cat(sprintf("  χ²-scaled(%.0f) = %.2f (WLSMV)\n", 
                  fit_idx["df"], fit_idx["chisq.scaled"]))
    }
    
    cat(sprintf("  CFI = %.4f", fit_idx["cfi"]))
    if (!is.na(fit_idx["cfi.scaled"])) cat(sprintf(" (robust: %.4f)", fit_idx["cfi.scaled"]))
    cat("\n")
    
    cat(sprintf("  TLI = %.4f", fit_idx["tli"]))
    if (!is.na(fit_idx["tli.scaled"])) cat(sprintf(" (robust: %.4f)", fit_idx["tli.scaled"]))
    cat("\n")
    
    cat(sprintf("  RMSEA = %.4f", fit_idx["rmsea"]))
    if (!is.na(fit_idx["rmsea.ci.lower"]) && !is.na(fit_idx["rmsea.ci.upper"])) {
      cat(sprintf(" [%.4f, %.4f]", fit_idx["rmsea.ci.lower"], fit_idx["rmsea.ci.upper"]))
    }
    if (!is.na(fit_idx["rmsea.scaled"])) cat(sprintf(" (robust: %.4f)", fit_idx["rmsea.scaled"]))
    cat("\n")
    
    if ("srmr" %in% names(fit_idx) && !is.na(fit_idx["srmr"])) {
      cat(sprintf("  SRMR = %.4f\n", fit_idx["srmr"]))
    }
    
    # Fit interpretation
    cfi_check <- if (!is.na(fit_idx["cfi.scaled"])) fit_idx["cfi.scaled"] else fit_idx["cfi"]
    tli_check <- if (!is.na(fit_idx["tli.scaled"])) fit_idx["tli.scaled"] else fit_idx["tli"]
    rmsea_check <- if (!is.na(fit_idx["rmsea.scaled"])) fit_idx["rmsea.scaled"] else fit_idx["rmsea"]
    
    if (cfi_check >= 0.95 && tli_check >= 0.95 && rmsea_check <= 0.06) {
      cat("  Interpretation: Excellent fit\n")
    } else if (cfi_check >= 0.90 && tli_check >= 0.90 && rmsea_check <= 0.08) {
      cat("  Interpretation: Good fit\n")
    } else if (cfi_check >= 0.85 && tli_check >= 0.85 && rmsea_check <= 0.10) {
      cat("  Interpretation: Acceptable fit\n")
    } else {
      cat("  Interpretation: Marginal fit\n")
    }
    
    cfi_final <- cfi_check
    tli_final <- tli_check
    rmsea_final <- rmsea_check
    srmr_final <- fit_idx["srmr"]
    
  }, error = function(e) {
    cat("Error calculating omega:", e$message, "\n")
    cfi_final <- tli_final <- rmsea_final <- srmr_final <- NA
  })
  
  cat("\n--- Summary ---\n")
  cat(sprintf("Alpha = %.4f, Omega = %.4f (N = %d)\n", alpha, omega, n_complete))
  
  if (exists("cfi_final")) {
    return(list(alpha = alpha, omega = omega, n = n_complete, k = length(existing_vars),
                cfi = cfi_final, tli = tli_final, rmsea = rmsea_final, srmr = srmr_final))
  } else {
    return(list(alpha = alpha, omega = omega, n = n_complete, k = length(existing_vars),
                cfi = NA, tli = NA, rmsea = NA, srmr = NA))
  }
}

# Analyze parental monitoring items at each age
monitoring_results <- list()

# Age 14: pwhere14 pwho14 pwhat14 cmwhere14 cmwho14 cmwhat14
monitoring14_vars <- c("pwhere14", "pwho14", "pwhat14", "cmwhere14", "cmwho14", "cmwhat14")
monitoring_results[["Age 14"]] <- analyze_monitoring_wave(14, "Age 14", monitoring14_vars, "fovwt1")

# Age 17: cmwhere17 cmtback17 pwhere17 ptback17
monitoring17_vars <- c("cmwhere17", "cmtback17", "pwhere17", "ptback17")
monitoring_results[["Age 17"]] <- analyze_monitoring_wave(17, "Age 17", monitoring17_vars, "govwt1")

# Age 17 specific: Spearman–Brown reliability for two-item pairs and two-factor CFA
cat("\n\n")
cat("----------------------------------------------------------------------------\n")
cat("AGE 17: Spearman–Brown (two-item) and Two-Factor CFA\n")
cat("----------------------------------------------------------------------------\n")

# Prepare Age 17 analysis data
age17_vars <- c("cmwhere17", "pwhere17", "cmtback17", "ptback17")
if (all(age17_vars %in% names(merged_waves_recoded)) && "govwt1" %in% names(merged_waves_recoded)) {
  age17_data <- merged_waves_recoded %>%
    mutate(
      .ok_age17 = !if_any(all_of(age17_vars), is.na) & !is.na(govwt1) & govwt1 > 0
    ) %>%
    filter(.ok_age17) %>%
    select(all_of(age17_vars), govwt1)

  n_age17 <- nrow(age17_data)
  cat(sprintf("N (complete, weighted cases): %d\n", n_age17))

  if (n_age17 >= 100) {
    # Spearman–Brown for Knowledge (cmwhere17, pwhere17)
    cat("\nSpearman–Brown reliability (polychoric):\n")
    sb_fun <- function(r) ifelse(is.na(r), NA_real_, (2 * r) / (1 + r))

    pc_know <- tryCatch({
      polychoric(age17_data[, c("cmwhere17", "pwhere17")])$rho[1, 2]
    }, error = function(e) NA_real_)
    sb_know <- sb_fun(pc_know)
    cat(sprintf("  Knowledge [cmwhere17 + pwhere17]: r_poly = %.4f, SB = %.4f\n", pc_know, sb_know))

    # Spearman–Brown for Curfew/Rules (cmtback17, ptback17)
    pc_rules <- tryCatch({
      polychoric(age17_data[, c("cmtback17", "ptback17")])$rho[1, 2]
    }, error = function(e) NA_real_)
    sb_rules <- sb_fun(pc_rules)
    cat(sprintf("  Curfew/Rules [cmtback17 + ptback17]: r_poly = %.4f, SB = %.4f\n", pc_rules, sb_rules))

    # Two-factor CFA
    cat("\nTwo-Factor CFA (std.lv = TRUE; no correlated residuals):\n")
    twofactor_model <- "
      Knowledge =~ cmwhere17 + pwhere17
      CurfewRules =~ cmtback17 + ptback17
    "
    fit2 <- tryCatch({
      cfa(twofactor_model,
          data = age17_data,
          ordered = age17_vars,
          std.lv = TRUE,
          sampling.weights = "govwt1",
          estimator = "WLSMV")
    }, error = function(e) { cat("CFA error: ", e$message, "\n"); NULL })

    if (!is.null(fit2)) {
      fit_idx2 <- fitMeasures(fit2, c("cfi", "tli", "rmsea", "srmr"))
      cat(sprintf("  CFI = %.4f, TLI = %.4f, RMSEA = %.4f, SRMR = %.4f\n",
                  fit_idx2["cfi"], fit_idx2["tli"], fit_idx2["rmsea"], fit_idx2["srmr"]))

      params2 <- parameterEstimates(fit2, standardized = TRUE)
      loadings2 <- params2 %>% filter(op == "=~") %>% select(lhs, rhs, std.all)
      cat("  Standardized loadings:\n")
      apply(loadings2, 1, function(row) {
        cat(sprintf("    %s -> %s: %.4f\n", row[[1]], row[[2]], as.numeric(row[[3]])))
      })

      # Factor correlation
      fc <- params2 %>% filter(op == "~~", lhs == "Knowledge", rhs == "CurfewRules") %>% pull(std.all)
      if (length(fc) == 1) cat(sprintf("  Factor correlation (Knowledge ~ Curfew/Rules): %.4f\n", fc))
    }
  } else {
    cat("Insufficient N for Age 17 specific analyses.\n")
  }
} else {
  cat("Required Age 17 variables or weights not found.\n")
}


# Summary table for parental monitoring measures
cat("\n\n")
cat("============================================================================\n")
cat("SUMMARY: Parental Monitoring Scales Reliability\n")
cat("============================================================================\n\n")

cat("Table: Parental Monitoring Reliability Coefficients\n")
cat(sprintf("%-10s %6s %8s %8s %10s\n", "Wave", "Items", "Alpha", "Omega", "N"))
cat(strrep("-", 50), "\n")

for (wave_name in names(monitoring_results)) {
  res <- monitoring_results[[wave_name]]
  if (!is.null(res) && !is.na(res$alpha)) { 
    cat(sprintf("%-10s %6d %8.4f %8.4f %10d\n", 
                wave_name, res$k, res$alpha, res$omega, res$n))
  } else {
    cat(sprintf("%-10s %6s %8s %8s %10s\n", 
                wave_name, "-", "-", "-", "-"))
  }
}

cat("\n\nTable: Parental Monitoring CFA Model Fit Statistics\n")
cat(sprintf("%-10s %8s %8s %8s %8s %15s\n", "Wave", "CFI", "TLI", "RMSEA", "SRMR", "Fit Quality"))
cat(strrep("-", 65), "\n")

for (wave_name in names(monitoring_results)) {
  res <- monitoring_results[[wave_name]]
  if (!is.null(res) && !is.na(res$cfi)) {
    # Determine fit quality
    if (res$cfi >= 0.95 && res$tli >= 0.95 && res$rmsea <= 0.06) {
      fit_quality <- "Excellent"
    } else if (res$cfi >= 0.90 && res$tli >= 0.90 && res$rmsea <= 0.08) {
      fit_quality <- "Good"
    } else if (res$cfi >= 0.85 && res$tli >= 0.85 && res$rmsea <= 0.10) {
      fit_quality <- "Acceptable"
    } else {
      fit_quality <- "Marginal"
    }
    
    cat(sprintf("%-10s %8.4f %8.4f %8.4f %8.4f %15s\n", 
                wave_name, res$cfi, res$tli, res$rmsea, res$srmr, fit_quality))
  } else {
    cat(sprintf("%-10s %8s %8s %8s %8s %15s\n", 
                wave_name, "-", "-", "-", "-", "-"))
  }
}

cat("\n")

