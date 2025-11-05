# ==============================================================================
# Create Derived Composite Variables
# ==============================================================================

library(pacman)
p_load(tidyverse, here)

cat("\n=== CREATING DERIVED COMPOSITE VARIABLES ===\n\n")

processed_path <- here("data", "processed")

# Load merged data
load(file.path(processed_path, "mcs_merged_wide.RData"))

cat("Starting N =", nrow(mcs_merged), "\n\n")

# ------------------------------------------------------------------------------
# TIME-AVERAGED PARENTING COMPOSITES
# ------------------------------------------------------------------------------

cat("Creating time-averaged parenting composites...\n")

mcs_merged <- mcs_merged %>%
  rowwise() %>%
  mutate(
    # Early harsh discipline (ages 3-7 average)
    harsh_early_avg = mean(c(harsh_3_composite, harsh_5_composite, harsh_7_composite),
                           na.rm = TRUE),

    # Early positive parenting (ages 5-7 average)
    pos_early_avg = mean(c(pos_5_composite, pos_7_composite), na.rm = TRUE),

    # Adolescent monitoring (ages 14-17 average)
    mon_adolescent_avg = mean(c(mon_14_avg, mon_17_avg), na.rm = TRUE)
  ) %>%
  ungroup()

cat("  ✓ harsh_early_avg, pos_early_avg, mon_adolescent_avg\n")

# ------------------------------------------------------------------------------
# PARENTING STABILITY (WITHIN-PERSON SD)
# ------------------------------------------------------------------------------

cat("\nCreating parenting stability measures...\n")

mcs_merged <- mcs_merged %>%
  rowwise() %>%
  mutate(
    # SD across early harsh parenting waves
    harsh_stability_sd = sd(c(harsh_3_composite, harsh_5_composite, harsh_7_composite),
                            na.rm = TRUE),

    # Binary: consistent (low SD) vs inconsistent (high SD)
    harsh_consistent = ifelse(!is.na(harsh_stability_sd),
                              harsh_stability_sd < median(harsh_stability_sd, na.rm = TRUE),
                              NA)
  ) %>%
  ungroup()

cat("  ✓ harsh_stability_sd, harsh_consistent\n")

# ------------------------------------------------------------------------------
# CATEGORICAL GROUPINGS
# ------------------------------------------------------------------------------

cat("\nCreating categorical groupings...\n")

mcs_merged <- mcs_merged %>%
  mutate(
    # Harsh parenting groups (tertiles)
    harsh_group = case_when(
      harsh_early_avg <= quantile(harsh_early_avg, 1/3, na.rm = TRUE) ~ "Low",
      harsh_early_avg <= quantile(harsh_early_avg, 2/3, na.rm = TRUE) ~ "Medium",
      harsh_early_avg > quantile(harsh_early_avg, 2/3, na.rm = TRUE) ~ "High",
      TRUE ~ NA_character_
    ),
    harsh_group = factor(harsh_group, levels = c("Low", "Medium", "High")),

    # Positive parenting groups
    pos_group = case_when(
      pos_early_avg <= quantile(pos_early_avg, 1/3, na.rm = TRUE) ~ "Low",
      pos_early_avg <= quantile(pos_early_avg, 2/3, na.rm = TRUE) ~ "Medium",
      pos_early_avg > quantile(pos_early_avg, 2/3, na.rm = TRUE) ~ "High",
      TRUE ~ NA_character_
    ),
    pos_group = factor(pos_group, levels = c("Low", "Medium", "High")),

    # SES groups (from income quintiles)
    ses_group = case_when(
      income_quintile %in% 1:2 ~ "Low",
      income_quintile == 3 ~ "Middle",
      income_quintile %in% 4:5 ~ "High",
      TRUE ~ NA_character_
    ),
    ses_group = factor(ses_group, levels = c("Low", "Middle", "High"))
  )

cat("  ✓ harsh_group, pos_group, ses_group\n")

# ------------------------------------------------------------------------------
# CUMULATIVE RISK INDEX
# ------------------------------------------------------------------------------

cat("\nCreating cumulative risk index...\n")

mcs_merged <- mcs_merged %>%
  mutate(
    # Individual risk indicators
    risk_low_birth_weight = ifelse(!is.na(low_birth_weight), low_birth_weight, 0),
    risk_premature = ifelse(!is.na(premature), premature, 0),
    risk_low_ses = ifelse(!is.na(ses_group), ses_group == "Low", 0),
    risk_single_parent = ifelse(!is.na(married), !married, 0),
    risk_harsh_parenting = ifelse(!is.na(harsh_group), harsh_group == "High", 0),
    risk_difficult_temp = ifelse(!is.na(difficult_temp_flag), difficult_temp_flag, 0),

    # Cumulative risk (sum of indicators, 0-6)
    risk_index = risk_low_birth_weight + risk_premature + risk_low_ses +
                 risk_single_parent + risk_harsh_parenting + risk_difficult_temp,

    # Risk groups
    risk_group = case_when(
      risk_index == 0 ~ "No risk",
      risk_index %in% 1:2 ~ "Low risk",
      risk_index %in% 3:4 ~ "Medium risk",
      risk_index >= 5 ~ "High risk",
      TRUE ~ NA_character_
    ),
    risk_group = factor(risk_group, levels = c("No risk", "Low risk", "Medium risk", "High risk"))
  )

cat("  ✓ risk_index (0-6), risk_group\n")

# ------------------------------------------------------------------------------
# SELF-CONTROL TRAJECTORY SUMMARIES
# ------------------------------------------------------------------------------

cat("\nCreating SC trajectory summaries...\n")

mcs_merged <- mcs_merged %>%
  rowwise() %>%
  mutate(
    # Mean across all waves
    sc_mean_all = mean(c(sc_3_total, sc_5_total, sc_7_total, sc_11_total,
                         sc_14_total, sc_17_total), na.rm = TRUE),

    # SD across waves (volatility)
    sc_volatility = sd(c(sc_3_total, sc_5_total, sc_7_total, sc_11_total,
                         sc_14_total, sc_17_total), na.rm = TRUE),

    # Simple linear change (age 17 - age 3, per year)
    sc_change_simple = ifelse(!is.na(sc_17_total) & !is.na(sc_3_total),
                              (sc_17_total - sc_3_total) / 14, NA),

    # Peak SC
    sc_peak = max(c(sc_3_total, sc_5_total, sc_7_total, sc_11_total,
                    sc_14_total, sc_17_total), na.rm = TRUE),

    # Minimum SC
    sc_minimum = min(c(sc_3_total, sc_5_total, sc_7_total, sc_11_total,
                       sc_14_total, sc_17_total), na.rm = TRUE),

    # Range
    sc_range = sc_peak - sc_minimum
  ) %>%
  ungroup() %>%
  mutate(
    # Replace Inf/-Inf with NA
    across(c(sc_peak, sc_minimum, sc_range), ~ifelse(is.infinite(.), NA, .))
  )

cat("  ✓ sc_mean_all, sc_volatility, sc_change_simple, sc_peak, sc_minimum, sc_range\n")

# ------------------------------------------------------------------------------
# SUMMARY STATISTICS
# ------------------------------------------------------------------------------

cat("\n")
cat("==============================================================================\n")
cat("DERIVED VARIABLE SUMMARY\n")
cat("==============================================================================\n\n")

cat("Time-averaged parenting:\n")
cat("  harsh_early_avg: M =", round(mean(mcs_merged$harsh_early_avg, na.rm = TRUE), 2),
    ", SD =", round(sd(mcs_merged$harsh_early_avg, na.rm = TRUE), 2), "\n")
cat("  pos_early_avg: M =", round(mean(mcs_merged$pos_early_avg, na.rm = TRUE), 2),
    ", SD =", round(sd(mcs_merged$pos_early_avg, na.rm = TRUE), 2), "\n")

cat("\nGroupings:\n")
cat("  harsh_group:\n")
print(table(mcs_merged$harsh_group, useNA = "ifany"))
cat("  ses_group:\n")
print(table(mcs_merged$ses_group, useNA = "ifany"))
cat("  risk_group:\n")
print(table(mcs_merged$risk_group, useNA = "ifany"))

cat("\nSC trajectory summaries:\n")
cat("  sc_mean_all: M =", round(mean(mcs_merged$sc_mean_all, na.rm = TRUE), 2),
    ", SD =", round(sd(mcs_merged$sc_mean_all, na.rm = TRUE), 2), "\n")
cat("  sc_change_simple: M =", round(mean(mcs_merged$sc_change_simple, na.rm = TRUE), 3),
    ", SD =", round(sd(mcs_merged$sc_change_simple, na.rm = TRUE), 3), "\n")

# ------------------------------------------------------------------------------
# SAVE ENHANCED DATASET
# ------------------------------------------------------------------------------

cat("\nSaving enhanced dataset with derived variables...\n")

save(mcs_merged, file = file.path(processed_path, "mcs_merged_wide.RData"))
cat("  ✓ Updated: data/processed/mcs_merged_wide.RData\n")
cat("  - Now includes", ncol(mcs_merged), "variables\n")

# Save list of derived variables
derived_vars <- data.frame(
  variable = c("harsh_early_avg", "pos_early_avg", "mon_adolescent_avg",
               "harsh_stability_sd", "harsh_consistent",
               "harsh_group", "pos_group", "ses_group",
               "risk_index", "risk_group",
               "sc_mean_all", "sc_volatility", "sc_change_simple",
               "sc_peak", "sc_minimum", "sc_range"),
  description = c(
    "Mean harsh discipline ages 3-7",
    "Mean positive parenting ages 5-7",
    "Mean parental monitoring ages 14-17",
    "SD of harsh discipline across ages 3-7",
    "Binary: consistent harsh parenting",
    "Harsh parenting tertile groups",
    "Positive parenting tertile groups",
    "SES tertile groups from income",
    "Cumulative risk index (0-6)",
    "Risk groups (none, low, medium, high)",
    "Mean self-control across all waves",
    "SD of self-control across waves",
    "Simple linear change (age 17 - age 3 / 14)",
    "Peak self-control across waves",
    "Minimum self-control across waves",
    "Range of self-control"
  )
)

write_csv(derived_vars, file.path(processed_path, "derived_variables_list.csv"))
cat("  ✓ Saved: data/processed/derived_variables_list.csv\n")

cat("\n=== DERIVED VARIABLES COMPLETE ===\n\n")
