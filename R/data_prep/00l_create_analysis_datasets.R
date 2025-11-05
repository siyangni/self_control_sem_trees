# ==============================================================================
# Create Analysis-Specific Datasets
# ==============================================================================
#
# Purpose: Generate optimized datasets for different analysis types
#   - Complete case for SEMTree (all covariates present)
#   - FIML-ready for lavaan (minimal missing on covariates)
#   - Long format for mixed models
#   - Covariate lists for easy reference
#
# ==============================================================================

library(pacman)
p_load(tidyverse, here)

cat("\n")
cat("==============================================================================\n")
cat("CREATING ANALYSIS-SPECIFIC DATASETS\n")
cat("==============================================================================\n\n")

processed_path <- here("data", "processed")

# Load merged data with derived variables
load(file.path(processed_path, "mcs_merged_wide.RData"))

cat("Starting with N =", nrow(mcs_merged), "participants\n\n")

# ------------------------------------------------------------------------------
# DEFINE COVARIATE SETS
# ------------------------------------------------------------------------------

cat("Defining covariate sets for analyses...\n")

# Baseline covariates (time-invariant)
baseline_covariates <- c(
  "sex", "ethnicity",
  "birth_weight", "low_birth_weight", "premature",
  "maternal_education", "mat_edu_collapsed",
  "income_quintile", "income_tertile", "ses_group",
  "married", "housing",
  "cognitive_3", "difficult_temperament"
)

# Parenting covariates (time-varying, but using averages)
parenting_covariates <- c(
  "harsh_early_avg", "pos_early_avg", "mon_adolescent_avg",
  "harsh_group", "pos_group"
)

# All covariates for complete case
all_covariates_full <- c(baseline_covariates, parenting_covariates)

# Minimal/essential covariates (fewer variables = more complete cases)
minimal_covariates <- c(
  "sex", "ethnicity", "ses_group", "mat_edu_collapsed",
  "cognitive_3", "harsh_early_avg", "pos_early_avg"
)

# Theory-driven covariates for focused SEMTree
theory_covariates <- c(
  "sex", "ses_group", "cognitive_3",
  "harsh_early_avg", "pos_early_avg",
  "low_birth_weight", "premature", "married"
)

# Save covariate lists
covariate_lists <- list(
  baseline = baseline_covariates,
  parenting = parenting_covariates,
  all_full = all_covariates_full,
  minimal = minimal_covariates,
  theory = theory_covariates
)

save(covariate_lists, file = file.path(processed_path, "covariate_lists.RData"))
cat("  ✓ Covariate lists defined and saved\n")

# ------------------------------------------------------------------------------
# DATASET 1: Complete Case for SEMTree (Full Covariates)
# ------------------------------------------------------------------------------

cat("\nDataset 1: Complete case with full covariates (for SEMTree)...\n")

# Identify SC variable names
sc_total_vars <- c("sc_3_total", "sc_5_total", "sc_7_total",
                   "sc_11_total", "sc_14_total", "sc_17_total")

# Complete case: all SC + all covariates + valid weight
mcs_semtree_complete_full <- mcs_merged %>%
  filter(
    # All SC waves present
    complete.cases(select(., all_of(sc_total_vars))),
    # All covariates present
    complete.cases(select(., all_of(all_covariates_full))),
    # Valid survey weight
    !is.na(survey_weight) & survey_weight > 0
  )

cat("  - Complete cases (all covariates): N =", nrow(mcs_semtree_complete_full),
    " (", round(100 * nrow(mcs_semtree_complete_full) / nrow(mcs_merged), 1), "% of total)\n", sep = "")

save(mcs_semtree_complete_full,
     file = file.path(processed_path, "mcs_semtree_complete_full.RData"))
cat("  ✓ Saved: mcs_semtree_complete_full.RData\n")

# ------------------------------------------------------------------------------
# DATASET 2: Complete Case for SEMTree (Minimal Covariates)
# ------------------------------------------------------------------------------

cat("\nDataset 2: Complete case with minimal covariates (for SEMTree)...\n")

mcs_semtree_complete_minimal <- mcs_merged %>%
  filter(
    complete.cases(select(., all_of(sc_total_vars))),
    complete.cases(select(., all_of(minimal_covariates))),
    !is.na(survey_weight) & survey_weight > 0
  )

cat("  - Complete cases (minimal covariates): N =", nrow(mcs_semtree_complete_minimal),
    " (", round(100 * nrow(mcs_semtree_complete_minimal) / nrow(mcs_merged), 1), "% of total)\n", sep = "")

save(mcs_semtree_complete_minimal,
     file = file.path(processed_path, "mcs_semtree_complete_minimal.RData"))
cat("  ✓ Saved: mcs_semtree_complete_minimal.RData\n")

# ------------------------------------------------------------------------------
# DATASET 3: Complete Case for SEMTree (Theory-Driven Covariates)
# ------------------------------------------------------------------------------

cat("\nDataset 3: Complete case with theory-driven covariates (for SEMTree)...\n")

mcs_semtree_complete_theory <- mcs_merged %>%
  filter(
    complete.cases(select(., all_of(sc_total_vars))),
    complete.cases(select(., all_of(theory_covariates))),
    !is.na(survey_weight) & survey_weight > 0
  )

cat("  - Complete cases (theory covariates): N =", nrow(mcs_semtree_complete_theory),
    " (", round(100 * nrow(mcs_semtree_complete_theory) / nrow(mcs_merged), 1), "% of total)\n", sep = "")

save(mcs_semtree_complete_theory,
     file = file.path(processed_path, "mcs_semtree_complete_theory.RData"))
cat("  ✓ Saved: mcs_semtree_complete_theory.RData\n")

# ------------------------------------------------------------------------------
# DATASET 4: FIML-Ready for Lavaan (allow missing SC)
# ------------------------------------------------------------------------------

cat("\nDataset 4: FIML-ready for lavaan (≥3 waves SC, complete covariates)...\n")

mcs_lavaan_fiml <- mcs_merged %>%
  mutate(
    n_sc_waves = rowSums(!is.na(select(., all_of(sc_total_vars))))
  ) %>%
  filter(
    # At least 3 waves of SC data
    n_sc_waves >= 3,
    # Complete baseline covariates (allow missing on parenting)
    complete.cases(select(., all_of(baseline_covariates))),
    # Valid survey weight
    !is.na(survey_weight) & survey_weight > 0
  )

cat("  - FIML-ready cases (≥3 SC waves): N =", nrow(mcs_lavaan_fiml),
    " (", round(100 * nrow(mcs_lavaan_fiml) / nrow(mcs_merged), 1), "% of total)\n", sep = "")

save(mcs_lavaan_fiml, file = file.path(processed_path, "mcs_lavaan_fiml.RData"))
cat("  ✓ Saved: mcs_lavaan_fiml.RData\n")

# ------------------------------------------------------------------------------
# DATASET 5: Long Format for Mixed Models
# ------------------------------------------------------------------------------

cat("\nDataset 5: Long format for mixed models / trajectory analysis...\n")

# SC items in long format
sc_items_long <- mcs_merged %>%
  select(mcsid, starts_with("sc_") & (contains("thac") | contains("tcom") |
                                      contains("obey") | contains("dist") |
                                      contains("temp") | contains("rest") |
                                      contains("fidg"))) %>%
  pivot_longer(
    cols = starts_with("sc_"),
    names_to = c("age", "item"),
    names_pattern = "sc_(\\d+)_(.*)",
    values_to = "value"
  ) %>%
  pivot_wider(
    names_from = item,
    values_from = value
  )

# Add time variables
sc_items_long <- sc_items_long %>%
  mutate(
    age = as.numeric(age),
    time = (age - 3) / 14,  # Scale 0-1 from age 3 to 17
    time_sq = time^2,
    time_age3 = age - 3,     # Years since age 3
    wave = case_when(
      age == 3 ~ 2,
      age == 5 ~ 3,
      age == 7 ~ 4,
      age == 11 ~ 5,
      age == 14 ~ 6,
      age == 17 ~ 7
    )
  )

# Add covariates (time-invariant, repeat for each row)
mcs_long <- sc_items_long %>%
  left_join(
    mcs_merged %>%
      select(mcsid, all_of(baseline_covariates), all_of(parenting_covariates),
             survey_weight, wt_age3, wt_age5, wt_age7, wt_age11, wt_age14, wt_age17),
    by = "mcsid"
  ) %>%
  # Add wave-specific weights
  mutate(
    wave_weight = case_when(
      wave == 2 ~ wt_age3,
      wave == 3 ~ wt_age5,
      wave == 4 ~ wt_age7,
      wave == 5 ~ wt_age11,
      wave == 6 ~ wt_age14,
      wave == 7 ~ wt_age17
    )
  ) %>%
  # Remove temporary weight columns
  select(-starts_with("wt_age"))

cat("  - Long format: N =", n_distinct(mcs_long$mcsid), "individuals,",
    nrow(mcs_long), "observations\n")

save(mcs_long, file = file.path(processed_path, "mcs_long_format.RData"))
cat("  ✓ Saved: mcs_long_format.RData\n")

# ------------------------------------------------------------------------------
# SUMMARY OF DATASETS
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("DATASET SUMMARY\n")
cat("==============================================================================\n\n")

dataset_summary <- data.frame(
  dataset = c(
    "mcs_merged_wide",
    "mcs_semtree_complete_full",
    "mcs_semtree_complete_minimal",
    "mcs_semtree_complete_theory",
    "mcs_lavaan_fiml",
    "mcs_long_format"
  ),
  n_participants = c(
    nrow(mcs_merged),
    nrow(mcs_semtree_complete_full),
    nrow(mcs_semtree_complete_minimal),
    nrow(mcs_semtree_complete_theory),
    nrow(mcs_lavaan_fiml),
    n_distinct(mcs_long$mcsid)
  ),
  n_observations = c(
    nrow(mcs_merged),
    nrow(mcs_semtree_complete_full),
    nrow(mcs_semtree_complete_minimal),
    nrow(mcs_semtree_complete_theory),
    nrow(mcs_lavaan_fiml),
    nrow(mcs_long)
  ),
  purpose = c(
    "Full merged dataset (wide)",
    "SEMTree with all covariates",
    "SEMTree with minimal covariates (more cases)",
    "SEMTree with theory-driven covariates",
    "Lavaan LGBM with FIML (≥3 waves)",
    "Mixed models & trajectory analysis"
  ),
  n_covariates = c(
    length(all_covariates_full),
    length(all_covariates_full),
    length(minimal_covariates),
    length(theory_covariates),
    length(baseline_covariates),
    length(c(baseline_covariates, parenting_covariates))
  )
)

print(dataset_summary)

write_csv(dataset_summary, file.path(processed_path, "dataset_summary.csv"))
cat("\n✓ Saved: dataset_summary.csv\n")

# ------------------------------------------------------------------------------
# USAGE GUIDE
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("USAGE GUIDE\n")
cat("==============================================================================\n\n")

cat("Dataset selection by analysis type:\n\n")

cat("1. SEMTree Analysis:\n")
cat("   - High power (max cases): mcs_semtree_complete_minimal.RData (N =",
    nrow(mcs_semtree_complete_minimal), ")\n")
cat("   - Theory-driven: mcs_semtree_complete_theory.RData (N =",
    nrow(mcs_semtree_complete_theory), ")\n")
cat("   - Full covariates: mcs_semtree_complete_full.RData (N =",
    nrow(mcs_semtree_complete_full), ")\n\n")

cat("2. Latent Growth Models (lavaan):\n")
cat("   - Use: mcs_lavaan_fiml.RData (N =", nrow(mcs_lavaan_fiml), ")\n")
cat("   - Allows FIML for missing SC waves (≥3 waves required)\n\n")

cat("3. Mixed Models / Trajectory Analysis:\n")
cat("   - Use: mcs_long_format.RData\n")
cat("   - N =", n_distinct(mcs_long$mcsid), "participants,",
    nrow(mcs_long), "observations\n\n")

cat("4. Descriptive / Exploratory:\n")
cat("   - Use: mcs_merged_wide.RData (N =", nrow(mcs_merged), ")\n")
cat("   - Full sample with maximum flexibility\n\n")

cat("Covariate lists available in: covariate_lists.RData\n")
cat("  - covariate_lists$baseline\n")
cat("  - covariate_lists$parenting\n")
cat("  - covariate_lists$all_full\n")
cat("  - covariate_lists$minimal\n")
cat("  - covariate_lists$theory\n\n")

cat("==============================================================================\n")
cat("ANALYSIS DATASETS COMPLETE!\n")
cat("==============================================================================\n\n")

cat("Ready for:\n")
cat("  ✓ SEMTree analyses (multiple sample size options)\n")
cat("  ✓ Latent growth models with FIML\n")
cat("  ✓ Mixed models in long format\n")
cat("  ✓ Regression, machine learning, etc.\n\n")
