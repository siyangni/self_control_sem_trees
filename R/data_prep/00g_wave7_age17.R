# ==============================================================================
# Extract Age 17 Data from MCS Wave 7
# ==============================================================================

library(pacman)
p_load(tidyverse, haven, here)

cat("\n=== WAVE 7 (AGE 17): SELF-CONTROL & MONITORING ===\n\n")

raw_path <- here("data", "raw", "MCS 7", "stata13")
out_path <- here("data", "processed")

# Load data
parent_cm <- read_dta(file.path(raw_path, "mcs7_parent_cm_interview.dta"))
cm_interview <- read_dta(file.path(raw_path, "mcs7_cm_interview.dta"))
family_derived <- read_dta(file.path(raw_path, "mcs7_family_derived.dta"))

# Self-control items (prefix G, parent report)
sc_items <- parent_cm %>%
  select(
    mcsid = MCSID,
    sc_17_thac = GPCPSD0F, sc_17_tcom = GPCPSD0E, sc_17_obey = GPCPSD0H,
    sc_17_dist = GPCPSD0L, sc_17_temp = GPCPSD0G, sc_17_rest = GPCPSD0A,
    sc_17_fidg = GPCPSD0J, sc_17_lyin = GPCPSD0K
  ) %>%
  mutate(
    across(starts_with("sc_"), ~ifelse(. < 0, NA_real_, .)),
    sc_17_total = rowSums(select(., sc_17_thac:sc_17_fidg), na.rm = FALSE),
    sc_17_mean = rowMeans(select(., sc_17_thac:sc_17_fidg), na.rm = FALSE)
  )

# Parental monitoring - Parent report
mon_parent <- parent_cm %>%
  select(
    mcsid = MCSID,
    mon_17_pwhere = GPWHPR00,  # Parent knows where CM is
    mon_17_ptback = GPTBPR00   # Parent: CM tells when get back
  ) %>%
  mutate(
    across(starts_with("mon_"), ~ifelse(. < 0, NA_real_, .)),
    mon_17_parent = rowMeans(select(., starts_with("mon_17_p")), na.rm = TRUE)
  )

# Parental monitoring - Child report
mon_child <- cm_interview %>%
  select(
    mcsid = MCSID,
    mon_17_cwhere = GCWHRS00,  # CM: Parent knows where
    mon_17_ctback = GCTBRS00   # CM: Tells parent when get back
  ) %>%
  mutate(
    across(starts_with("mon_"), ~ifelse(. < 0, NA_real_, .)),
    mon_17_child = rowMeans(select(., starts_with("mon_17_c")), na.rm = TRUE)
  )

# Merge monitoring
monitoring <- mon_parent %>%
  left_join(mon_child, by = "mcsid") %>%
  mutate(mon_17_avg = (mon_17_parent + mon_17_child) / 2)

# Weights (FINAL wave - most restrictive longitudinal weight)
weights <- family_derived %>%
  select(mcsid = MCSID, weight_17 =GOVWT1) %>%
  mutate(weight_17 = ifelse(weight_17 > 0, weight_17, NA_real_))

# Merge all
wave7_age17 <- sc_items %>%
  left_join(monitoring, by = "mcsid") %>%
  left_join(weights, by = "mcsid") %>%
  mutate(wave7_participant = TRUE)

# Save
save(wave7_age17, file = file.path(out_path, "wave7_age17.RData"))
var_list <- data.frame(
  variable = names(wave7_age17),
  type = sapply(wave7_age17, class),
  n_missing = sapply(wave7_age17, function(x) sum(is.na(x))),
  pct_missing = round(100 * sapply(wave7_age17, function(x) mean(is.na(x))), 1)
)
write_csv(var_list, file.path(out_path, "wave7_age17_variables.csv"))

cat("✓ Wave 7 complete: N =", nrow(wave7_age17), "\n\n")
