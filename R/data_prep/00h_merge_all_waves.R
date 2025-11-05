# ==============================================================================
# Merge All MCS Waves into Wide Format Dataset
# ==============================================================================
#
# Purpose: Merge waves 1-7 by MCSID into single wide-format dataset
#   - One row per cohort member
#   - Columns for all time points
#   - Baseline covariates from Wave 1
#   - Self-control from Waves 2-7
#   - Parenting from Waves 2-4 (harsh/positive) and 6-7 (monitoring)
#
# Input:  data/processed/wave*.RData (from scripts 00a-00g)
# Output: data/processed/mcs_merged_wide.RData
#
# ==============================================================================

library(pacman)
p_load(tidyverse, here)

cat("\n")
cat("==============================================================================\n")
cat("MERGING ALL MCS WAVES\n")
cat("==============================================================================\n\n")

# Set paths
processed_path <- here("data", "processed")

# ------------------------------------------------------------------------------
# LOAD ALL WAVE FILES
# ------------------------------------------------------------------------------

cat("Loading wave-specific datasets...\n")

load(file.path(processed_path, "wave1_baseline.RData"))
cat("  ✓ Wave 1 (baseline): N =", nrow(wave1_baseline), "\n")

load(file.path(processed_path, "wave2_age3.RData"))
cat("  ✓ Wave 2 (age 3): N =", nrow(wave2_age3), "\n")

load(file.path(processed_path, "wave3_age5.RData"))
cat("  ✓ Wave 3 (age 5): N =", nrow(wave3_age5), "\n")

load(file.path(processed_path, "wave4_age7.RData"))
cat("  ✓ Wave 4 (age 7): N =", nrow(wave4_age7), "\n")

load(file.path(processed_path, "wave5_age11.RData"))
cat("  ✓ Wave 5 (age 11): N =", nrow(wave5_age11), "\n")

load(file.path(processed_path, "wave6_age14.RData"))
cat("  ✓ Wave 6 (age 14): N =", nrow(wave6_age14), "\n")

load(file.path(processed_path, "wave7_age17.RData"))
cat("  ✓ Wave 7 (age 17): N =", nrow(wave7_age17), "\n")

# ------------------------------------------------------------------------------
# MERGE WAVES SEQUENTIALLY
# ------------------------------------------------------------------------------

cat("\nMerging waves by MCSID...\n")

# Start with baseline (Wave 1) - most inclusive
mcs_merged <- wave1_baseline

cat("  Step 1: Starting with Wave 1 baseline (N =", nrow(mcs_merged), ")\n")

# Add Wave 2 (Age 3)
mcs_merged <- mcs_merged %>%
  full_join(wave2_age3, by = "mcsid", suffix = c("", "_w2"))

cat("  Step 2: Merged Wave 2 (age 3) - now N =", nrow(mcs_merged), "\n")

# Add Wave 3 (Age 5)
mcs_merged <- mcs_merged %>%
  full_join(wave3_age5, by = "mcsid", suffix = c("", "_w3"))

cat("  Step 3: Merged Wave 3 (age 5) - now N =", nrow(mcs_merged), "\n")

# Add Wave 4 (Age 7)
mcs_merged <- mcs_merged %>%
  full_join(wave4_age7, by = "mcsid", suffix = c("", "_w4"))

cat("  Step 4: Merged Wave 4 (age 7) - now N =", nrow(mcs_merged), "\n")

# Add Wave 5 (Age 11)
mcs_merged <- mcs_merged %>%
  full_join(wave5_age11, by = "mcsid", suffix = c("", "_w5"))

cat("  Step 5: Merged Wave 5 (age 11) - now N =", nrow(mcs_merged), "\n")

# Add Wave 6 (Age 14)
mcs_merged <- mcs_merged %>%
  full_join(wave6_age14, by = "mcsid", suffix = c("", "_w6"))

cat("  Step 6: Merged Wave 6 (age 14) - now N =", nrow(mcs_merged), "\n")

# Add Wave 7 (Age 17)
mcs_merged <- mcs_merged %>%
  full_join(wave7_age17, by = "mcsid", suffix = c("", "_w7"))

cat("  Step 7: Merged Wave 7 (age 17) - final N =", nrow(mcs_merged), "\n")

# ------------------------------------------------------------------------------
# RESOLVE DUPLICATE COLUMNS FROM MERGES
# ------------------------------------------------------------------------------

cat("\nResolving duplicate survey design variables...\n")

# Survey design variables may be duplicated across waves
# Keep the most complete version (usually from latest wave)

# Strata and PSU should be constant across waves - use first non-missing
if ("strata.x" %in% names(mcs_merged)) {
  mcs_merged <- mcs_merged %>%
    mutate(
      strata = coalesce(strata, strata.x, strata.y),
      psu = coalesce(psu, psu.x, psu.y)
    ) %>%
    select(-matches("strata\\."), -matches("psu\\."))
}

cat("  ✓ Survey design variables unified\n")

# ------------------------------------------------------------------------------
# CREATE UNIFIED WEIGHT VARIABLE
# ------------------------------------------------------------------------------

cat("\nCreating unified survey weight variables...\n")

mcs_merged <- mcs_merged %>%
  mutate(
    # Longitudinal weight (most restrictive - present in all waves)
    # Use Wave 7 weight as it conditions on participation in all prior waves
    wt_longitudinal = weight_17,

    # Wave-specific weights for cross-sectional analyses
    wt_age3 = weight_3,
    wt_age5 = weight_5,
    wt_age7 = weight_7,
    wt_age11 = weight_11,
    wt_age14 = weight_14,
    wt_age17 = weight_17,

    # Default weight for analyses (longitudinal)
    survey_weight = wt_longitudinal
  )

cat("  ✓ Survey weights created\n")
cat("    - Longitudinal weight: N =", sum(!is.na(mcs_merged$wt_longitudinal)), "\n")
cat("    - Age 3 weight: N =", sum(!is.na(mcs_merged$wt_age3)), "\n")
cat("    - Age 17 weight: N =", sum(!is.na(mcs_merged$wt_age17)), "\n")

# ------------------------------------------------------------------------------
# CREATE PARTICIPATION FLAGS
# ------------------------------------------------------------------------------

cat("\nCreating wave participation indicators...\n")

mcs_merged <- mcs_merged %>%
  mutate(
    # Participation flags (already created in wave scripts, but ensure they exist)
    participated_w1 = !is.na(wave1_participant),
    participated_w2 = !is.na(sc_3_total),
    participated_w3 = !is.na(sc_5_total),
    participated_w4 = !is.na(sc_7_total),
    participated_w5 = !is.na(sc_11_total),
    participated_w6 = !is.na(sc_14_total),
    participated_w7 = !is.na(sc_17_total),

    # Total waves participated
    n_waves_participated = rowSums(select(., starts_with("participated_w")), na.rm = TRUE),

    # Participated in all SC waves (ages 3-17)
    participated_all_sc = (participated_w2 & participated_w3 & participated_w4 &
                           participated_w5 & participated_w6 & participated_w7),

    # Participated in at least 3 waves
    participated_min3 = (n_waves_participated >= 3)
  )

cat("  ✓ Participation flags created\n")
cat("    - Participated all 7 waves: N =", sum(mcs_merged$participated_all_sc, na.rm = TRUE),
    " (", round(100 * mean(mcs_merged$participated_all_sc, na.rm = TRUE), 1), "%)\n", sep = "")
cat("    - Participated ≥3 waves: N =", sum(mcs_merged$participated_min3, na.rm = TRUE),
    " (", round(100 * mean(mcs_merged$participated_min3, na.rm = TRUE), 1), "%)\n", sep = "")

# ------------------------------------------------------------------------------
# VARIABLE ORDERING & CLEANUP
# ------------------------------------------------------------------------------

cat("\nOrganizing variables...\n")

# Create sensible variable order
mcs_merged <- mcs_merged %>%
  select(
    # ID and survey design
    mcsid, strata, psu,

    # Participation flags
    starts_with("participated_"), n_waves_participated,

    # Survey weights
    starts_with("wt_"), survey_weight,

    # Baseline demographics
    sex, ethnicity, birth_order,
    birth_weight, gestational_age, low_birth_weight, premature,

    # Baseline SES
    maternal_education, mat_edu_level, mat_edu_collapsed,
    maternal_age, income_quintile, income_tertile,
    married, housing, household_size,

    # Baseline child characteristics
    cognitive_3, difficult_temperament, difficult_temp_flag,

    # Self-control items (all waves)
    starts_with("sc_3_"), starts_with("sc_5_"), starts_with("sc_7_"),
    starts_with("sc_11_"), starts_with("sc_14_"), starts_with("sc_17_"),

    # Parenting variables
    starts_with("harsh_3_"), starts_with("harsh_5_"), starts_with("harsh_7_"),
    starts_with("harsh_11_"),
    starts_with("pos_5_"), starts_with("pos_7_"), starts_with("pos_11_"),

    # Monitoring
    starts_with("mon_14_"), starts_with("mon_17_"),

    # Everything else
    everything()
  )

# Remove temporary wave participant flags
mcs_merged <- mcs_merged %>%
  select(-matches("wave[0-9]_participant"))

cat("  ✓ Variables organized\n")
cat("  - Total variables:", ncol(mcs_merged), "\n")

# ------------------------------------------------------------------------------
# SUMMARY STATISTICS
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("MERGE SUMMARY\n")
cat("==============================================================================\n\n")

cat("Sample sizes:\n")
cat("  Total unique participants: N =", nrow(mcs_merged), "\n\n")

cat("Attrition pattern:\n")
attrition <- data.frame(
  wave = c("1 (9mo)", "2 (3yr)", "3 (5yr)", "4 (7yr)", "5 (11yr)", "6 (14yr)", "7 (17yr)"),
  n = c(
    sum(mcs_merged$participated_w1, na.rm = TRUE),
    sum(mcs_merged$participated_w2, na.rm = TRUE),
    sum(mcs_merged$participated_w3, na.rm = TRUE),
    sum(mcs_merged$participated_w4, na.rm = TRUE),
    sum(mcs_merged$participated_w5, na.rm = TRUE),
    sum(mcs_merged$participated_w6, na.rm = TRUE),
    sum(mcs_merged$participated_w7, na.rm = TRUE)
  )
)
attrition$pct_wave1 <- round(100 * attrition$n / attrition$n[1], 1)
attrition$attrition <- 100 - attrition$pct_wave1

print(attrition)

cat("\nSelf-control data availability:\n")
cat("  Age 3: N =", sum(!is.na(mcs_merged$sc_3_total)), "\n")
cat("  Age 5: N =", sum(!is.na(mcs_merged$sc_5_total)), "\n")
cat("  Age 7: N =", sum(!is.na(mcs_merged$sc_7_total)), "\n")
cat("  Age 11: N =", sum(!is.na(mcs_merged$sc_11_total)), "\n")
cat("  Age 14: N =", sum(!is.na(mcs_merged$sc_14_total)), "\n")
cat("  Age 17: N =", sum(!is.na(mcs_merged$sc_17_total)), "\n")

cat("\nBaseline covariate availability:\n")
cat("  Sex: N =", sum(!is.na(mcs_merged$sex)),
    " (", round(100 * mean(!is.na(mcs_merged$sex)), 1), "%)\n", sep = "")
cat("  Ethnicity: N =", sum(!is.na(mcs_merged$ethnicity)),
    " (", round(100 * mean(!is.na(mcs_merged$ethnicity)), 1), "%)\n", sep = "")
cat("  Maternal education: N =", sum(!is.na(mcs_merged$maternal_education)),
    " (", round(100 * mean(!is.na(mcs_merged$maternal_education)), 1), "%)\n", sep = "")
cat("  Income quintile: N =", sum(!is.na(mcs_merged$income_quintile)),
    " (", round(100 * mean(!is.na(mcs_merged$income_quintile)), 1), "%)\n", sep = "")
cat("  Cognitive ability (age 3): N =", sum(!is.na(mcs_merged$cognitive_3)),
    " (", round(100 * mean(!is.na(mcs_merged$cognitive_3)), 1), "%)\n", sep = "")

# ------------------------------------------------------------------------------
# SAVE MERGED DATASET
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("SAVING MERGED DATASET\n")
cat("==============================================================================\n\n")

# Save main merged file
save(mcs_merged, file = file.path(processed_path, "mcs_merged_wide.RData"))
cat("✓ Saved: data/processed/mcs_merged_wide.RData\n")
cat("  - N =", nrow(mcs_merged), "participants\n")
cat("  - Variables:", ncol(mcs_merged), "\n")

# Save variable list
var_list <- data.frame(
  variable = names(mcs_merged),
  type = sapply(mcs_merged, class),
  n_valid = sapply(mcs_merged, function(x) sum(!is.na(x))),
  n_missing = sapply(mcs_merged, function(x) sum(is.na(x))),
  pct_missing = round(100 * sapply(mcs_merged, function(x) mean(is.na(x))), 1)
)

write_csv(var_list, file.path(processed_path, "mcs_merged_wide_variables.csv"))
cat("✓ Saved: data/processed/mcs_merged_wide_variables.csv\n")

# Save attrition summary
write_csv(attrition, file.path(processed_path, "attrition_summary.csv"))
cat("✓ Saved: data/processed/attrition_summary.csv\n")

cat("\n")
cat("==============================================================================\n")
cat("MERGE COMPLETE!\n")
cat("==============================================================================\n")
cat("\nReady for:\n")
cat("  - Quality checks (00i_quality_checks.R)\n")
cat("  - Derived variables (00j_derive_composites.R)\n")
cat("  - Analysis-specific datasets (00l_create_analysis_datasets.R)\n\n")
