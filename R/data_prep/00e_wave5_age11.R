# ==============================================================================
# Extract Age 11 Data from MCS Wave 5
# ==============================================================================

library(pacman)
p_load(tidyverse, haven, here)

cat("\n=== WAVE 5 (AGE 11): SELF-CONTROL & PARENTING ===\n\n")

raw_path <- here("data", "raw", "MCS 5", "stata11")
out_path <- here("data", "processed")

# Load data
parent_cm <- read_dta(file.path(raw_path, "mcs5_parent_cm_interview.dta"))
family_derived <- read_dta(file.path(raw_path, "mcs5_family_derived.dta"))

# Self-control items (prefix E, parent report)
sc_items <- parent_cm %>%
  select(
    mcsid = MCSID,
    sc_11_thac = EPCPSD0F, sc_11_tcom = EPCPSD0E, sc_11_obey = EPCPSD0H,
    sc_11_dist = EPCPSD0L, sc_11_temp = EPCPSD0G, sc_11_rest = EPCPSD0A,
    sc_11_fidg = EPCPSD0J, sc_11_lyin = EPCPSD0K
  ) %>%
  mutate(
    across(starts_with("sc_"), ~ifelse(. < 0, NA_real_, .)),
    sc_11_total = rowSums(select(., sc_11_thac:sc_11_fidg), na.rm = FALSE),
    sc_11_mean = rowMeans(select(., sc_11_thac:sc_11_fidg), na.rm = FALSE)
  )

# Parenting (reduced set at age 11)
parenting <- parent_cm %>%
  select(
    mcsid = MCSID,
    harsh_11_bedroom = matches(".*BED.*"),
    harsh_11_treats = matches(".*TREA.*"),
    pos_11_reason = matches(".*REA.*")
  ) %>%
  mutate(across(everything() & where(is.numeric), ~ifelse(. < 0, NA_real_, .)))

# Weights
weights <- family_derived %>%
  select(mcsid = MCSID, weight_11 = EOVWT1) %>%
  mutate(weight_11 = ifelse(weight_11 > 0, weight_11, NA_real_))

# Merge
wave5_age11 <- sc_items %>%
  left_join(parenting, by = "mcsid") %>%
  left_join(weights, by = "mcsid") %>%
  mutate(wave5_participant = TRUE)

# Save
save(wave5_age11, file = file.path(out_path, "wave5_age11.RData"))
var_list <- data.frame(
  variable = names(wave5_age11),
  type = sapply(wave5_age11, class),
  n_missing = sapply(wave5_age11, function(x) sum(is.na(x))),
  pct_missing = round(100 * sapply(wave5_age11, function(x) mean(is.na(x))), 1)
)
write_csv(var_list, file.path(out_path, "wave5_age11_variables.csv"))

cat("✓ Wave 5 complete: N =", nrow(wave5_age11), "\n\n")
