# =============================================================================
# Utility Functions
# =============================================================================
# Project: Self-Control Development Study
# Purpose: Helper functions used across multiple analysis scripts
# Author: [Your Name]
# Date: November 2025
# =============================================================================

# ENVIRONMENT SETUP -----------------------------------------------------------

#' Load Required Packages
#'
#' @description Loads all packages needed for the project with suppressed messages
#' @return Invisible NULL
#' @export
load_packages <- function() {
  packages <- c(
    "tidyverse", "haven", "here", "lavaan", "semTools",
    "semtree", "survey", "psych", "OpenMx"
  )

  suppressPackageStartupMessages({
    for (pkg in packages) {
      library(pkg, character.only = TRUE)
    }
  })

  invisible(NULL)
}


# DATA MANAGEMENT -------------------------------------------------------------

#' Safe Load RData File
#'
#' @description Loads an RData file and returns the object(s) it contains
#' @param file Character. Path to .RData file
#' @return List of objects loaded from the file
#' @export
safe_load <- function(file) {
  if (!file.exists(file)) {
    stop("File not found: ", file)
  }

  env <- new.env()
  loaded_objects <- load(file, envir = env)

  if (length(loaded_objects) == 1) {
    return(env[[loaded_objects]])
  } else {
    return(as.list(env))
  }
}

#' Check for Missing Data Patterns
#'
#' @description Summarize missing data across variables
#' @param data Data frame
#' @param vars Character vector of variable names to check
#' @return Data frame with missingness summary
#' @export
check_missing <- function(data, vars = NULL) {
  if (is.null(vars)) {
    vars <- names(data)
  }

  data %>%
    select(all_of(vars)) %>%
    summarise(across(everything(),
                     list(
                       n_miss = ~sum(is.na(.)),
                       pct_miss = ~mean(is.na(.)) * 100
                     ))) %>%
    pivot_longer(everything(),
                 names_to = c("variable", ".value"),
                 names_pattern = "(.+)_(.+)") %>%
    arrange(desc(pct_miss))
}


# MODEL UTILITIES -------------------------------------------------------------

#' Extract Model Fit Indices
#'
#' @description Extract key fit indices from lavaan model
#' @param model Fitted lavaan model object
#' @param indices Character vector of fit index names
#' @return Named vector of fit indices
#' @export
extract_fit <- function(model,
                        indices = c("chisq", "df", "pvalue", "cfi", "tli",
                                    "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
                                    "srmr")) {
  if (!inherits(model, "lavaan")) {
    stop("Model must be a lavaan object")
  }

  fitMeasures(model, fit.measures = indices)
}

#' Interpret Model Fit
#'
#' @description Categorize model fit as Excellent/Good/Acceptable/Marginal/Poor
#' @param cfi Comparative Fit Index
#' @param tli Tucker-Lewis Index
#' @param rmsea Root Mean Square Error of Approximation
#' @return Character string indicating fit quality
#' @export
interpret_fit <- function(cfi, tli, rmsea) {
  if (cfi >= 0.95 && tli >= 0.95 && rmsea <= 0.06) {
    return("Excellent")
  } else if (cfi >= 0.90 && tli >= 0.90 && rmsea <= 0.08) {
    return("Good")
  } else if (cfi >= 0.85 && tli >= 0.85 && rmsea <= 0.10) {
    return("Acceptable")
  } else if (cfi >= 0.80 && tli >= 0.80) {
    return("Marginal")
  } else {
    return("Poor")
  }
}

#' Compare Nested Models
#'
#' @description Compare fit of nested models using ΔCFI and ΔRMSEA
#' @param model1 More constrained model (nested)
#' @param model2 Less constrained model (baseline)
#' @return List with fit comparison results
#' @export
compare_nested <- function(model1, model2) {
  fit1 <- extract_fit(model1, c("cfi", "rmsea", "chisq", "df"))
  fit2 <- extract_fit(model2, c("cfi", "rmsea", "chisq", "df"))

  delta_cfi <- fit1["cfi"] - fit2["cfi"]
  delta_rmsea <- fit1["rmsea"] - fit2["rmsea"]
  delta_chisq <- fit1["chisq"] - fit2["chisq"]
  delta_df <- fit1["df"] - fit2["df"]

  # Chen (2007) guidelines for invariance testing
  invariance_supported <- (delta_cfi >= -0.010) && (delta_rmsea <= 0.015)

  list(
    delta_cfi = delta_cfi,
    delta_rmsea = delta_rmsea,
    delta_chisq = delta_chisq,
    delta_df = delta_df,
    invariance_supported = invariance_supported
  )
}


# RELIABILITY FUNCTIONS -------------------------------------------------------

#' Calculate Ordinal Alpha
#'
#' @description Compute coefficient alpha from polychoric correlation matrix
#' @param data Data frame with items
#' @param items Character vector of item names
#' @return Numeric. Ordinal alpha coefficient
#' @export
ordinal_alpha <- function(data, items) {
  # Compute polychoric correlation matrix
  poly_result <- psych::polychoric(data[, items])
  C <- poly_result$rho
  k <- ncol(C)

  # Calculate ordinal alpha
  rbar <- (sum(C) - k) / (k * (k - 1))
  alpha <- (k * rbar) / (1 + (k - 1) * rbar)

  return(alpha)
}

#' Calculate Ordinal Omega
#'
#' @description Compute coefficient omega from CFA model
#' @param model Fitted lavaan CFA model
#' @return Numeric. Ordinal omega coefficient
#' @export
ordinal_omega <- function(model) {
  # Use semTools::reliability
  rel <- semTools::reliability(model)

  # Extract omega
  if ("omega" %in% names(rel)) {
    return(rel["omega"])
  } else if ("omega.total" %in% names(rel)) {
    return(rel["omega.total"])
  } else {
    warning("Omega not found in reliability output")
    return(NA)
  }
}


# VISUALIZATION HELPERS -------------------------------------------------------

#' Create Standardized Theme for Plots
#'
#' @description Apply consistent theme across all project visualizations
#' @return ggplot2 theme object
#' @export
theme_project <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11, color = "gray40"),
      axis.title = element_text(face = "bold"),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )
}

#' Save Plot with Consistent Settings
#'
#' @description Save plot with project-standard settings
#' @param plot ggplot object
#' @param filename Character. Output filename
#' @param width Numeric. Width in inches (default 8)
#' @param height Numeric. Height in inches (default 6)
#' @param path Character. Output directory (default "results/figures/")
#' @export
save_plot <- function(plot, filename, width = 8, height = 6,
                      path = here::here("results/figures/")) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  full_path <- file.path(path, filename)

  ggsave(
    filename = full_path,
    plot = plot,
    width = width,
    height = height,
    dpi = 300,
    units = "in"
  )

  message("Plot saved to: ", full_path)
}


# SEM TREE HELPERS ------------------------------------------------------------

#' Check if SEM Tree Has Splits
#'
#' @description Determine if a semtree object contains any splits
#' @param tree semtree object
#' @return Logical. TRUE if splits exist
#' @export
has_splits <- function(tree) {
  if (!inherits(tree, "semtree")) {
    stop("Object must be a semtree")
  }

  # Capture tree structure as text
  tree_str <- capture.output(print(tree))

  # Check for node 2 (first split would create node 2)
  any(grepl("\\|-\\[2\\]", tree_str))
}

#' Extract Terminal Nodes from SEM Tree
#'
#' @description Get all terminal nodes and their sample sizes
#' @param tree semtree object
#' @return Data frame with terminal node information
#' @export
get_terminal_nodes <- function(tree) {
  if (!inherits(tree, "semtree")) {
    stop("Object must be a semtree")
  }

  # This is a simplified version - may need adjustment based on semtree structure
  tree_str <- capture.output(print(tree))
  terminal_lines <- grep("TERMINAL", tree_str, value = TRUE)

  # Parse node IDs and N
  # Format: "|-[ID] TERMINAL [N=XXX]"
  node_info <- lapply(terminal_lines, function(line) {
    node_id <- as.integer(gsub(".*\\[([0-9]+)\\].*", "\\1", line))
    n <- as.integer(gsub(".*N=([0-9]+).*", "\\1", line))
    data.frame(node_id = node_id, n = n)
  })

  do.call(rbind, node_info)
}


# TABLE FORMATTING ------------------------------------------------------------

#' Format p-values for Publication
#'
#' @description Format p-values with appropriate precision
#' @param p Numeric vector of p-values
#' @return Character vector of formatted p-values
#' @export
format_pvalue <- function(p) {
  case_when(
    p < 0.001 ~ "< .001",
    p < 0.01 ~ sprintf("= %.3f", p),
    TRUE ~ sprintf("= %.2f", p)
  )
}

#' Create APA-style Regression Table
#'
#' @description Format regression results in APA style
#' @param model lm or lavaan model object
#' @return Data frame with formatted results
#' @export
apa_table <- function(model) {
  # Get parameter estimates
  if (inherits(model, "lavaan")) {
    params <- parameterEstimates(model, standardized = TRUE)
  } else if (inherits(model, "lm")) {
    params <- broom::tidy(model, conf.int = TRUE)
  } else {
    stop("Model type not supported")
  }

  # Format for APA
  params %>%
    mutate(
      estimate = sprintf("%.2f", estimate),
      se = sprintf("%.2f", se),
      ci = sprintf("[%.2f, %.2f]", ci.lower, ci.upper),
      p = format_pvalue(pvalue)
    ) %>%
    select(term, estimate, se, ci, p)
}


# SESSION INFO ----------------------------------------------------------------

#' Save Session Information
#'
#' @description Save sessionInfo() to a file for reproducibility
#' @param filename Character. Output filename (default "sessionInfo.txt")
#' @param path Character. Output directory
#' @export
save_session_info <- function(filename = "sessionInfo.txt",
                               path = here::here("results/")) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  full_path <- file.path(path, filename)

  sink(full_path)
  cat("Session Info for Self-Control Development Study\n")
  cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
  print(sessionInfo())
  sink()

  message("Session info saved to: ", full_path)
}


# VALIDATION ------------------------------------------------------------------

#' Validate Dataset Structure
#'
#' @description Check if dataset has expected variables
#' @param data Data frame
#' @param required_vars Character vector of required variable names
#' @return Logical. TRUE if all required variables present
#' @export
validate_dataset <- function(data, required_vars) {
  missing_vars <- setdiff(required_vars, names(data))

  if (length(missing_vars) > 0) {
    stop("Missing required variables: ", paste(missing_vars, collapse = ", "))
  }

  message("✓ All required variables present")
  return(TRUE)
}


# =============================================================================
# END OF UTILITY FUNCTIONS
# =============================================================================
