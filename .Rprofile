# =============================================================================
# R Profile for Self-Control Development Study
# =============================================================================
# This file is automatically sourced when R starts in this project directory
# Last Updated: November 2025
# =============================================================================

# Welcome message
if (interactive()) {
  cat("\n")
  cat("=====================================================================\n")
  cat("  Self-Control Development Trajectory Heterogeneity Study\n")
  cat("  Project initialized\n")
  cat("=====================================================================\n\n")
}

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Set working directory to project root using here
if (requireNamespace("here", quietly = TRUE)) {
  setwd(here::here())
  if (interactive()) {
    cat("Working directory set to:", here::here(), "\n\n")
  }
} else {
  if (interactive()) {
    cat("Tip: Install 'here' package for better path management\n")
    cat("  install.packages('here')\n\n")
  }
}

# Load renv if available (for package management)
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
  if (interactive()) {
    cat("renv activated for reproducible package management\n\n")
  }
}

# Set global options
options(
  # Display
  width = 120,
  max.print = 1000,

  # Warnings and errors
  warn = 1,  # Print warnings as they occur
  error = NULL,  # Use default error handler

  # Strings
  stringsAsFactors = FALSE,  # Modern R default

  # Memory
  expressions = 5e5,  # Increase max expression limit for complex models

  # Reproducibility
  digits = 7
)

# Set scipen for better number display
options(scipen = 10)

# Helper functions for interactive sessions
if (interactive()) {

  # Quick load packages
  qload <- function() {
    suppressPackageStartupMessages({
      library(tidyverse)
      library(haven)
      library(here)
      library(lavaan)
    })
    cat("Core packages loaded: tidyverse, haven, here, lavaan\n")
  }

  # List analysis scripts
  list_scripts <- function() {
    scripts <- list.files(here::here("R"), pattern = "^\\d{2}_.*\\.R$")
    cat("Analysis scripts:\n")
    cat(paste0("  ", scripts), sep = "\n")
  }

  # Run analysis script
  run <- function(step) {
    script_name <- sprintf("%02d", step)
    script_file <- list.files(here::here("R"),
                              pattern = paste0("^", script_name, "_.*\\.R$"),
                              full.names = TRUE)

    if (length(script_file) == 0) {
      cat("Script", step, "not found\n")
      return(invisible(NULL))
    }

    cat("Running:", basename(script_file), "\n\n")
    source(script_file)
  }

  # Display project info
  project_info <- function() {
    cat("\n=== Project Information ===\n\n")
    cat("Project:", "Self-Control Development Study\n")
    cat("Directory:", here::here(), "\n")
    cat("R version:", R.version.string, "\n")

    if (requireNamespace("renv", quietly = TRUE)) {
      cat("renv status:", ifelse(renv::status()$synchronized,
                                  "synchronized", "needs update"), "\n")
    }

    cat("\nData:\n")
    cat("  Raw:", ifelse(dir.exists(here::here("data/raw")),
                         "available", "not found"), "\n")
    cat("  Processed:", ifelse(file.exists(here::here("data/processed/merged_waves_recoded.RData")),
                               "available", "not created"), "\n")

    cat("\nResults:\n")
    cat("  Models:", length(list.files(here::here("results/models"))), "files\n")
    cat("  Figures:", length(list.files(here::here("results/figures"))), "files\n")
    cat("  Reports:", length(list.files(here::here("results/reports"))), "files\n")

    cat("\n=== Quick Commands ===\n\n")
    cat("  qload()           - Load core packages\n")
    cat("  list_scripts()    - List analysis scripts\n")
    cat("  run(1)            - Run script 01\n")
    cat("  project_info()    - Show this info\n\n")
  }

  # Show quick commands on startup
  cat("=== Quick Commands ===\n")
  cat("  qload()           - Load core packages\n")
  cat("  list_scripts()    - List analysis scripts\n")
  cat("  run(1)            - Run script 01\n")
  cat("  project_info()    - Show project info\n")
  cat("  source('R/00_master.R') - Run full pipeline\n\n")
}

# Set random seed for reproducibility (can be overridden in scripts)
set.seed(20251105)

# Ensure critical directories exist
dirs <- c("data/raw", "data/processed",
          "results/figures", "results/tables", "results/models", "results/reports",
          "R/utils", "docs", "manuscript")

for (dir in dirs) {
  if (!dir.exists(here::here(dir))) {
    dir.create(here::here(dir), recursive = TRUE, showWarnings = FALSE)
  }
}

# Clean up
rm(dirs)

# =============================================================================
# End of .Rprofile
# =============================================================================
