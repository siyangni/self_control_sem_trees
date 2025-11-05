# ==============================================================================
# Extract Baseline Covariates from MCS Wave 1 (9 months)
# ==============================================================================
#
# Purpose: Extract time-invariant baseline characteristics from MCS1
#   - Demographics (sex, ethnicity, birth outcomes)
#   - Socioeconomic status (maternal education, income, housing)
#   - Family structure (marital status, household composition)
#
# Input:  data/raw/MCS 1/stata11/*.dta
# Output: data/processed/wave1_baseline.RData
#
# ==============================================================================

library(pacman)
p_load(tidyverse, haven, here)

cat("\n=== WAVE 1 (9 MONTHS): BASELINE COVARIATES ===\n\n")

# Set paths
raw_path <- here("data", "raw", "MCS 1", "stata11")
out_path <- here("data", "processed")

# ------------------------------------------------------------------------------
# LOAD DATA FILES
# ------------------------------------------------------------------------------

cat("Loading Wave 1 data files...\n")

# Parent interview (main variables)
parent <- read_dta(file.path(raw_path, "mcs1_parent_interview.dta"))
cat("  - Parent interview: N =", nrow(parent), "\n")

# Derived variables (SES, weights)
derived <- read_dta(file.path(raw_path, "mcs1_derived_variables.dta"))
cat("  - Derived variables: N =", nrow(derived), "\n")

# Household grid (child sex, birth order)
hhgrid <- read_dta(file.path(raw_path, "mcs1_hhgrid.dta"))
cat("  - Household grid: N =", nrow(hhgrid), "\n")

# Geographic data (for contextual variables if needed)
geo <- read_dta(file.path(raw_path, "mcs1_geographically_linked_data.dta"))
cat("  - Geographic data: N =", nrow(geo), "\n")

# ------------------------------------------------------------------------------
# EXTRACT VARIABLES
# ------------------------------------------------------------------------------

cat("\nExtracting baseline variables...\n")

# --- Child Demographics ---
child_demo <- hhgrid %>%
  filter(!is.na(MCSID) & AHCNUM00 == 1) %>%  # First cohort member only
  select(
    mcsid = MCSID,
    sex = AHCSEX00,           # 1=Male, 2=Female
    birth_order = AHCNUM00    # Birth order in household
  ) %>%
  mutate(
    sex = factor(sex, levels = 1:2, labels = c("Male", "Female")),
    birth_order = as.integer(birth_order)
  )

cat("  - Child demographics extracted: sex, birth_order\n")

# --- Birth Outcomes ---
birth <- parent %>%
  select(
    mcsid = MCSID,
    birth_weight = APWGHT00,      # Birth weight in grams
    gestational_age = APGEST00,   # Gestational age in weeks
    ethnicity_raw = ADC06E00      # Child ethnicity (detailed)
  ) %>%
  mutate(
    # Recode negative missing codes to NA
    across(where(is.numeric), ~ifelse(. < 0, NA_real_, .)),

    # Derived indicators
    low_birth_weight = ifelse(!is.na(birth_weight), birth_weight < 2500, NA),
    very_low_birth_weight = ifelse(!is.na(birth_weight), birth_weight < 1500, NA),
    premature = ifelse(!is.na(gestational_age), gestational_age < 37, NA),
    very_premature = ifelse(!is.na(gestational_age), gestational_age < 32, NA),

    # Collapsed ethnicity (match existing script)
    ethnicity = case_when(
      ethnicity_raw %in% 1 ~ "White",
      ethnicity_raw %in% 2 ~ "Mixed",
      ethnicity_raw %in% 3 ~ "Indian",
      ethnicity_raw %in% 4 ~ "Pakistani/Bangladeshi",
      ethnicity_raw %in% 5 ~ "Black/Black British",
      ethnicity_raw %in% 6 ~ "Other",
      TRUE ~ NA_character_
    ),
    ethnicity = factor(ethnicity, levels = c("White", "Mixed", "Indian",
                                              "Pakistani/Bangladeshi",
                                              "Black/Black British", "Other"))
  )

cat("  - Birth outcomes extracted: birth_weight, gestational_age, ethnicity, LBW/premature flags\n")

# --- Socioeconomic Status ---
ses <- derived %>%
  select(
    mcsid = MCSID,
    maternal_education = AMDQNI00,  # Maternal NVQ level
    maternal_age = AMDAGE00,         # Mother's age at birth
    income_oecd = AOECDUK0,          # OECD equivalized income quintile
    marital_status = APFCIN00        # Family status
  ) %>%
  mutate(
    # Recode negatives to NA
    across(where(is.numeric), ~ifelse(. < 0, NA_real_, .)),

    # Maternal education groups
    mat_edu_level = case_when(
      maternal_education == 1 ~ "None",
      maternal_education == 2 ~ "NVQ1",
      maternal_education == 3 ~ "NVQ2",
      maternal_education == 4 ~ "NVQ3",
      maternal_education == 5 ~ "NVQ4",
      maternal_education == 6 ~ "NVQ5",
      TRUE ~ NA_character_
    ),
    mat_edu_level = factor(mat_edu_level,
                           levels = c("None", "NVQ1", "NVQ2", "NVQ3", "NVQ4", "NVQ5")),

    # Collapsed education
    mat_edu_collapsed = case_when(
      maternal_education %in% 1:2 ~ "Low",
      maternal_education == 3 ~ "Medium",
      maternal_education %in% 4:6 ~ "High",
      TRUE ~ NA_character_
    ),
    mat_edu_collapsed = factor(mat_edu_collapsed, levels = c("Low", "Medium", "High")),

    # Income quintile (already in quintiles)
    income_quintile = as.integer(income_oecd),

    # Income tertiles
    income_tertile = case_when(
      income_quintile %in% 1:2 ~ "Low",
      income_quintile == 3 ~ "Medium",
      income_quintile %in% 4:5 ~ "High",
      TRUE ~ NA_character_
    ),
    income_tertile = factor(income_tertile, levels = c("Low", "Medium", "High")),

    # Marital status
    married = case_when(
      marital_status == 1 ~ TRUE,   # Married/cohabiting
      marital_status == 2 ~ FALSE,  # Single parent
      TRUE ~ NA
    )
  )

cat("  - SES extracted: maternal education, income quintile/tertile, marital status\n")

# --- Housing and Family Context ---
family <- parent %>%
  select(
    mcsid = MCSID,
    housing_tenure = AHTEN00,     # Housing tenure
    household_size = AHSIZE00,    # Number in household
    infant_temperament = APSDST00 # Infant difficult temperament scale
  ) %>%
  mutate(
    # Recode negatives to NA
    across(where(is.numeric), ~ifelse(. < 0, NA_real_, .)),

    # Housing tenure
    housing = case_when(
      housing_tenure == 1 ~ "Own/Mortgage",
      housing_tenure == 2 ~ "Rent social",
      housing_tenure == 3 ~ "Rent private",
      housing_tenure %in% 4:5 ~ "Other",
      TRUE ~ NA_character_
    ),
    housing = factor(housing, levels = c("Own/Mortgage", "Rent social",
                                         "Rent private", "Other")),

    # Difficult temperament (higher = more difficult)
    difficult_temperament = infant_temperament,

    # High temperament flag (top quartile)
    difficult_temp_flag = ifelse(!is.na(difficult_temperament),
                                  difficult_temperament > quantile(difficult_temperament, 0.75, na.rm = TRUE),
                                  NA)
  )

cat("  - Family context extracted: housing tenure, household size, infant temperament\n")

# --- Survey Design Variables ---
survey <- derived %>%
  select(
    mcsid = MCSID,
    strata = PTTYPE2,      # Stratification variable
    psu = SPTN00           # Primary sampling unit (cluster)
  )

cat("  - Survey design variables extracted: strata, PSU\n")

# ------------------------------------------------------------------------------
# MERGE ALL BASELINE VARIABLES
# ------------------------------------------------------------------------------

cat("\nMerging baseline components...\n")

wave1_baseline <- child_demo %>%
  left_join(birth, by = "mcsid") %>%
  left_join(ses, by = "mcsid") %>%
  left_join(family, by = "mcsid") %>%
  left_join(survey, by = "mcsid") %>%
  # Add wave identifier
  mutate(wave1_participant = TRUE)

cat("  - Merged N =", nrow(wave1_baseline), "\n")
cat("  - Variables:", ncol(wave1_baseline), "\n")

# ------------------------------------------------------------------------------
# QUALITY CHECKS
# ------------------------------------------------------------------------------

cat("\nQuality checks...\n")

# Check for duplicates
n_duplicates <- sum(duplicated(wave1_baseline$mcsid))
if (n_duplicates > 0) {
  warning("Found ", n_duplicates, " duplicate MCSIDs!")
  wave1_baseline <- wave1_baseline %>% distinct(mcsid, .keep_all = TRUE)
}

# Summary statistics
cat("\nSample composition:\n")
cat("  Sex:\n")
print(table(wave1_baseline$sex, useNA = "ifany"))

cat("\n  Ethnicity:\n")
print(table(wave1_baseline$ethnicity, useNA = "ifany"))

cat("\n  Maternal education:\n")
print(table(wave1_baseline$mat_edu_collapsed, useNA = "ifany"))

cat("\n  Income tertile:\n")
print(table(wave1_baseline$income_tertile, useNA = "ifany"))

cat("\n  Low birth weight: ",
    sum(wave1_baseline$low_birth_weight, na.rm = TRUE),
    " (", round(100 * mean(wave1_baseline$low_birth_weight, na.rm = TRUE), 1), "%)\n", sep = "")

cat("  Premature: ",
    sum(wave1_baseline$premature, na.rm = TRUE),
    " (", round(100 * mean(wave1_baseline$premature, na.rm = TRUE), 1), "%)\n", sep = "")

# Variable list
cat("\nFinal variables:\n")
cat(paste(" ", names(wave1_baseline), collapse = "\n"), "\n")

# ------------------------------------------------------------------------------
# SAVE OUTPUT
# ------------------------------------------------------------------------------

cat("\nSaving output...\n")

save(wave1_baseline, file = file.path(out_path, "wave1_baseline.RData"))
cat("  ✓ Saved: data/processed/wave1_baseline.RData\n")

# Also save variable list
var_list <- data.frame(
  variable = names(wave1_baseline),
  type = sapply(wave1_baseline, class),
  n_missing = sapply(wave1_baseline, function(x) sum(is.na(x))),
  pct_missing = round(100 * sapply(wave1_baseline, function(x) mean(is.na(x))), 1)
)

write_csv(var_list, file.path(out_path, "wave1_baseline_variables.csv"))
cat("  ✓ Saved: data/processed/wave1_baseline_variables.csv\n")

cat("\n=== WAVE 1 EXTRACTION COMPLETE ===\n")
cat("N =", nrow(wave1_baseline), "participants with baseline data\n\n")
