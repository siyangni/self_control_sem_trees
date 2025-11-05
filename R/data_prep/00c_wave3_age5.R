# ==============================================================================
# Extract Age 5 Data from MCS Wave 3
# ==============================================================================
#
# Purpose: Extract Wave 3 (Age 5) variables
#   - Self-control items (SDQ - 7 core items + lying)
#   - Parenting practices (harsh discipline + positive parenting)
#   - Survey weights
#
# Input:  data/raw/MCS 3/stata11_se/*.dta
# Output: data/processed/wave3_age5.RData
#
# ==============================================================================

library(pacman)
p_load(tidyverse, haven, here)

cat("\n=== WAVE 3 (AGE 5): SELF-CONTROL & PARENTING ===\n\n")

# Set paths
raw_path <- here("data", "raw", "MCS 3", "stata11_se")
out_path <- here("data", "processed")

# ------------------------------------------------------------------------------
# LOAD DATA
# ------------------------------------------------------------------------------

cat("Loading Wave 3 data files...\n")

parent <- read_dta(file.path(raw_path, "mcs3_parent_interview.dta"))
derived <- read_dta(file.path(raw_path, "mcs3_derived_variables.dta"))

cat("  - Parent interview: N =", nrow(parent), "\n")
cat("  - Derived variables: N =", nrow(derived), "\n")

# ------------------------------------------------------------------------------
# SELF-CONTROL ITEMS
# ------------------------------------------------------------------------------

cat("\nExtracting self-control items (age 5)...\n")

# SDQ at Wave 3 (prefix C)
sc_items <- parent %>%
  select(
    mcsid = MCSID,
    sc_5_thac = CSDQXF,    # Thinks before acting
    sc_5_tcom = CSDQXE,    # Sees tasks through
    sc_5_obey = CSDQXH,    # Generally obedient
    sc_5_dist = CSDQXL,    # Easily distracted (R)
    sc_5_temp = CSDQXG,    # Temper tantrums (R)
    sc_5_rest = CSDQXA,    # Restless (R)
    sc_5_fidg = CSDQXJ,    # Fidgeting (R)
    sc_5_lyin = CSDQXK     # Lies/cheats (R) - ADDITIONAL ITEM
  ) %>%
  mutate(
    across(starts_with("sc_"), ~ifelse(. < 0, NA_real_, .)),

    # Total score using 7 core items (for consistency with age 3)
    sc_5_total_7items = rowSums(select(., sc_5_thac:sc_5_fidg), na.rm = FALSE),

    # Total score using all 8 items
    sc_5_total_8items = rowSums(select(., starts_with("sc_5_")) %>%
                                 select(-contains("total")), na.rm = FALSE),

    # Mean scores
    sc_5_mean_7items = rowMeans(select(., sc_5_thac:sc_5_fidg), na.rm = FALSE),
    sc_5_mean_8items = rowMeans(select(., sc_5_thac:sc_5_lyin), na.rm = FALSE),

    # For primary analyses, use 7-item version for consistency
    sc_5_total = sc_5_total_7items,
    sc_5_mean = sc_5_mean_7items
  )

cat("  - 7 core items + 1 additional (lying)\n")
cat("  - Valid 7-item responses: N =", sum(!is.na(sc_items$sc_5_total)), "\n")

# ------------------------------------------------------------------------------
# PARENTING VARIABLES
# ------------------------------------------------------------------------------

cat("\nExtracting parenting variables (age 5)...\n")

# Harsh discipline
parenting_harsh <- parent %>%
  select(
    mcsid = MCSID,
    harsh_5_smack = CPHYSM00,
    harsh_5_shout = CPSHSO00,
    harsh_5_telloff = CPHYTE00,
    harsh_5_bedroom = CPHYBD00,
    harsh_5_ignore = CPHYIG00,
    harsh_5_bribe = CPHYBR00
  ) %>%
  mutate(
    across(starts_with("harsh_"), ~ifelse(. < 0, NA_real_, .)),
    harsh_5_composite = rowMeans(select(., harsh_5_smack, harsh_5_shout, harsh_5_telloff),
                                  na.rm = TRUE)
  )

# Positive parenting (NEW at age 5)
parenting_positive <- parent %>%
  select(
    mcsid = MCSID,
    pos_5_reason = matches("CPPREA.*00"),   # Reason with child
    pos_5_praise = matches("CPPRAI.*00"),   # Praise child
    pos_5_cuddle = matches("CPCUDD.*00")    # Cuddle/hug child
  ) %>%
  mutate(
    across(starts_with("pos_"), ~ifelse(. < 0, NA_real_, .)),
    pos_5_composite = rowMeans(select(., starts_with("pos_5_")), na.rm = TRUE)
  )

# Merge parenting
parenting <- parenting_harsh %>%
  left_join(parenting_positive, by = "mcsid")

cat("  - Harsh discipline + positive parenting extracted\n")

# ------------------------------------------------------------------------------
# SURVEY WEIGHTS
# ------------------------------------------------------------------------------

cat("\nExtracting survey weights (age 5)...\n")

weights <- derived %>%
  select(
    mcsid = MCSID,
    weight_5 = COVWT1
  ) %>%
  mutate(weight_5 = ifelse(weight_5 > 0, weight_5, NA_real_))

# ------------------------------------------------------------------------------
# MERGE
# ------------------------------------------------------------------------------

wave3_age5 <- sc_items %>%
  left_join(parenting, by = "mcsid") %>%
  left_join(weights, by = "mcsid") %>%
  mutate(wave3_participant = TRUE)

cat("\nMerged N =", nrow(wave3_age5), "\n")

# ------------------------------------------------------------------------------
# SAVE
# ------------------------------------------------------------------------------

save(wave3_age5, file = file.path(out_path, "wave3_age5.RData"))

var_list <- data.frame(
  variable = names(wave3_age5),
  type = sapply(wave3_age5, class),
  n_missing = sapply(wave3_age5, function(x) sum(is.na(x))),
  pct_missing = round(100 * sapply(wave3_age5, function(x) mean(is.na(x))), 1)
)
write_csv(var_list, file.path(out_path, "wave3_age5_variables.csv"))

cat("✓ Saved: wave3_age5.RData\n")
cat("\n=== WAVE 3 EXTRACTION COMPLETE ===\n\n")
