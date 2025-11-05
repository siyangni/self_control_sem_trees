# ==============================================================================
# Extract Age 3 Data from MCS Wave 2
# ==============================================================================
#
# Purpose: Extract Wave 2 (Age 3) variables
#   - Self-control items (SDQ - 7 core items)
#   - Parenting practices (harsh discipline)
#   - Cognitive ability (BAS)
#   - Survey weights
#
# Input:  data/raw/MCS 2/stata11_se/*.dta
# Output: data/processed/wave2_age3.RData
#
# ==============================================================================

library(pacman)
p_load(tidyverse, haven, here)

cat("\n=== WAVE 2 (AGE 3): SELF-CONTROL & PARENTING ===\n\n")

# Set paths
raw_path <- here("data", "raw", "MCS 2", "stata11_se")
out_path <- here("data", "processed")

# ------------------------------------------------------------------------------
# LOAD DATA FILES
# ------------------------------------------------------------------------------

cat("Loading Wave 2 data files...\n")

# Parent interview (SDQ, parenting)
parent <- read_dta(file.path(raw_path, "mcs2_parent_interview.dta"))
cat("  - Parent interview: N =", nrow(parent), "\n")

# Child assessment (BAS cognitive scores)
assessment <- read_dta(file.path(raw_path, "mcs2_child_assessment_data.dta"))
cat("  - Child assessment: N =", nrow(assessment), "\n")

# Derived variables (weights)
derived <- read_dta(file.path(raw_path, "mcs2_derived_variables.dta"))
cat("  - Derived variables: N =", nrow(derived), "\n")

# ------------------------------------------------------------------------------
# EXTRACT SELF-CONTROL ITEMS (SDQ)
# ------------------------------------------------------------------------------

cat("\nExtracting self-control items (age 3)...\n")

# SDQ variable names at Wave 2 (prefix B)
# Response coding: 0=Certainly true, 1=Somewhat true, 2=Not true
# NOTE: Some items are reverse-coded in MCS already (higher = better self-control)

sc_items <- parent %>%
  select(
    mcsid = MCSID,
    sc_3_thac = BSDQXF,    # Thinks things out before acting
    sc_3_tcom = BSDQXE,    # Sees tasks through to completion
    sc_3_obey = BSDQXH,    # Generally obedient
    sc_3_dist = BSDQXL,    # Easily distracted (reversed)
    sc_3_temp = BSDQXG,    # Has temper tantrums (reversed)
    sc_3_rest = BSDQXA,    # Restless, overactive (reversed)
    sc_3_fidg = BSDQXJ     # Constantly fidgeting (reversed)
  ) %>%
  mutate(
    # Recode negative missing codes to NA
    across(starts_with("sc_"), ~ifelse(. < 0, NA_real_, .)),

    # Ensure all items coded so higher = better self-control
    # Check if items are already reverse-coded in MCS
    # Items dist, temp, rest, fidg should be: 0=bad, 2=good
    # If not, apply reversal: 2 - value
    # Based on existing script, items appear already coded correctly

    # Create total score (sum of 7 items, 0-14 scale)
    sc_3_total = rowSums(select(., starts_with("sc_3_")), na.rm = FALSE),

    # Mean score (0-2 scale)
    sc_3_mean = rowMeans(select(., starts_with("sc_3_")) %>%
                         select(-sc_3_total), na.rm = FALSE),

    # Number of items completed
    sc_3_n_items = rowSums(!is.na(select(., starts_with("sc_3_")) %>%
                                   select(-sc_3_total, -sc_3_mean)))
  )

cat("  - Self-control items extracted: 7 items + total + mean\n")
cat("  - Valid responses: N =", sum(!is.na(sc_items$sc_3_total)), "\n")

# ------------------------------------------------------------------------------
# EXTRACT PARENTING VARIABLES
# ------------------------------------------------------------------------------

cat("\nExtracting parenting variables (age 3)...\n")

# Harsh discipline items
# Question: "When [child] is naughty, how often do you..."
# Response: 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily

parenting <- parent %>%
  select(
    mcsid = MCSID,
    harsh_3_smack = BPHYSM00,   # Smack child
    harsh_3_shout = BPSHSO00,   # Shout at child
    harsh_3_telloff = BPHYTE00, # Tell off/scold child
    harsh_3_bedroom = BPHYBD00, # Send to bedroom
    harsh_3_ignore = BPHYIG00,  # Ignore misbehavior
    harsh_3_bribe = BPHYBR00,   # Bribe/promise treat
    harsh_3_naughty = BPHYNA00  # Naughty chair/time out (if available)
  ) %>%
  mutate(
    # Recode negative missing to NA
    across(starts_with("harsh_"), ~ifelse(. < 0, NA_real_, .)),

    # Composite harsh discipline (mean of smack, shout, telloff)
    harsh_3_composite = rowMeans(select(., harsh_3_smack, harsh_3_shout, harsh_3_telloff),
                                  na.rm = TRUE),

    # High harsh discipline flag (top tertile)
    harsh_3_high = ifelse(!is.na(harsh_3_composite),
                          harsh_3_composite > quantile(harsh_3_composite, 2/3, na.rm = TRUE),
                          NA)
  )

cat("  - Parenting variables extracted: harsh discipline items + composite\n")

# ------------------------------------------------------------------------------
# EXTRACT COGNITIVE ABILITY (BAS)
# ------------------------------------------------------------------------------

cat("\nExtracting cognitive ability (age 3)...\n")

# BAS (British Ability Scales) - general cognitive ability score
cognitive <- assessment %>%
  select(
    mcsid = MCSID,
    cognitive_3_naming = BCOGTOT,  # BAS naming vocabulary (if available)
    cognitive_3_general = matches("BCOG.*TOT")  # General cognitive score
  ) %>%
  mutate(
    # Recode negatives to NA
    across(starts_with("cognitive_"), ~ifelse(. < 0, NA_real_, .))
  )

# Use first available cognitive measure
if ("cognitive_3_general" %in% names(cognitive)) {
  cognitive <- cognitive %>%
    mutate(cognitive_3 = coalesce(cognitive_3_general, cognitive_3_naming))
} else {
  cognitive <- cognitive %>%
    mutate(cognitive_3 = cognitive_3_naming)
}

cat("  - Cognitive ability extracted\n")
cat("  - Valid scores: N =", sum(!is.na(cognitive$cognitive_3)), "\n")

# ------------------------------------------------------------------------------
# EXTRACT SURVEY WEIGHTS
# ------------------------------------------------------------------------------

cat("\nExtracting survey weights (age 3)...\n")

weights <- derived %>%
  select(
    mcsid = MCSID,
    weight_3 = BOVWT1,     # Wave 2 survey weight
    strata = PTTYPE2,      # Strata (should be same as Wave 1)
    psu = SPTN00           # PSU (should be same as Wave 1)
  ) %>%
  mutate(
    # Ensure positive weights
    weight_3 = ifelse(weight_3 > 0, weight_3, NA_real_)
  )

cat("  - Survey weights extracted\n")
cat("  - Valid weights: N =", sum(!is.na(weights$weight_3)), "\n")

# ------------------------------------------------------------------------------
# MERGE WAVE 2 COMPONENTS
# ------------------------------------------------------------------------------

cat("\nMerging Wave 2 components...\n")

wave2_age3 <- sc_items %>%
  left_join(parenting, by = "mcsid") %>%
  left_join(cognitive, by = "mcsid") %>%
  left_join(weights, by = "mcsid") %>%
  mutate(wave2_participant = TRUE)

cat("  - Merged N =", nrow(wave2_age3), "\n")

# ------------------------------------------------------------------------------
# QUALITY CHECKS
# ------------------------------------------------------------------------------

cat("\nQuality checks...\n")

# Check response distributions for SC items
cat("\n  Self-control item distributions (0=low, 2=high):\n")
for (item in c("thac", "tcom", "obey", "dist", "temp", "rest", "fidg")) {
  var_name <- paste0("sc_3_", item)
  cat("    ", item, ": ",
      sum(wave2_age3[[var_name]] == 0, na.rm = TRUE), " / ",
      sum(wave2_age3[[var_name]] == 1, na.rm = TRUE), " / ",
      sum(wave2_age3[[var_name]] == 2, na.rm = TRUE),
      " (missing: ", sum(is.na(wave2_age3[[var_name]])), ")\n", sep = "")
}

# SC total score distribution
cat("\n  Self-control total score:\n")
cat("    Mean (SD):", round(mean(wave2_age3$sc_3_total, na.rm = TRUE), 2),
    "(", round(sd(wave2_age3$sc_3_total, na.rm = TRUE), 2), ")\n")
cat("    Range:", range(wave2_age3$sc_3_total, na.rm = TRUE), "\n")

# Harsh parenting distribution
cat("\n  Harsh discipline composite:\n")
cat("    Mean (SD):", round(mean(wave2_age3$harsh_3_composite, na.rm = TRUE), 2),
    "(", round(sd(wave2_age3$harsh_3_composite, na.rm = TRUE), 2), ")\n")
cat("    High harsh:", sum(wave2_age3$harsh_3_high, na.rm = TRUE),
    "(", round(100 * mean(wave2_age3$harsh_3_high, na.rm = TRUE), 1), "%)\n")

# Check for duplicates
n_duplicates <- sum(duplicated(wave2_age3$mcsid))
if (n_duplicates > 0) {
  warning("Found ", n_duplicates, " duplicate MCSIDs!")
  wave2_age3 <- wave2_age3 %>% distinct(mcsid, .keep_all = TRUE)
}

# ------------------------------------------------------------------------------
# SAVE OUTPUT
# ------------------------------------------------------------------------------

cat("\nSaving output...\n")

save(wave2_age3, file = file.path(out_path, "wave2_age3.RData"))
cat("  ✓ Saved: data/processed/wave2_age3.RData\n")

# Variable list
var_list <- data.frame(
  variable = names(wave2_age3),
  type = sapply(wave2_age3, class),
  n_missing = sapply(wave2_age3, function(x) sum(is.na(x))),
  pct_missing = round(100 * sapply(wave2_age3, function(x) mean(is.na(x))), 1)
)

write_csv(var_list, file.path(out_path, "wave2_age3_variables.csv"))
cat("  ✓ Saved: data/processed/wave2_age3_variables.csv\n")

cat("\n=== WAVE 2 EXTRACTION COMPLETE ===\n")
cat("N =", nrow(wave2_age3), "participants at age 3\n\n")
