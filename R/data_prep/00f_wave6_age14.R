# ==============================================================================
# Extract Age 14 Data from MCS Wave 6
# ==============================================================================

library(pacman)
p_load(tidyverse, haven, here)

cat("\n=== WAVE 6 (AGE 14): SELF-CONTROL & MONITORING ===\n\n")

raw_path <- here("data", "raw", "MCS 6", "stata11")
out_path <- here("data", "processed")

# Load data
parent_cm <- read_dta(file.path(raw_path, "mcs6_parent_cm_interview.dta"))
cm_interview <- read_dta(file.path(raw_path, "mcs6_cm_interview.dta"))
family_derived <- read_dta(file.path(raw_path, "mcs6_family_derived.dta"))

# Self-control items (prefix F, parent report)
sc_items <- parent_cm %>%
  select(
    mcsid = MCSID,
    sc_14_thac = FPCPSD0F, sc_14_tcom = FPCPSD0E, sc_14_obey = FPCPSD0H,
    sc_14_dist = FPCPSD0L, sc_14_temp = FPCPSD0G, sc_14_rest = FPCPSD0A,
    sc_14_fidg = FPCPSD0J, sc_14_lyin = FPCPSD0K
  ) %>%
  mutate(
    across(starts_with("sc_"), ~ifelse(. < 0, NA_real_, .)),
    sc_14_total = rowSums(select(., sc_14_thac:sc_14_fidg), na.rm = FALSE),
    sc_14_mean = rowMeans(select(., sc_14_thac:sc_14_fidg), na.rm = FALSE)
  )

# Parental monitoring - Parent report
mon_parent <- parent_cm %>%
  select(
    mcsid = MCSID,
    mon_14_pwhere = FPWHPR00,  # Parent knows where CM is
    mon_14_pwho = FPWWPR00,    # Parent knows who CM with
    mon_14_pwhat = FPWDPR00    # Parent knows what CM doing
  ) %>%
  mutate(
    across(starts_with("mon_"), ~ifelse(. < 0, NA_real_, .)),
    mon_14_parent = rowMeans(select(., starts_with("mon_14_p")), na.rm = TRUE)
  )

# Parental monitoring - Child report
mon_child <- cm_interview %>%
  select(
    mcsid = MCSID,
    mon_14_cwhere = FCWHRS00,  # CM: Parent knows where
    mon_14_cwho = FCWWRS00,    # CM: Parent knows who with
    mon_14_cwhat = FCWDRS00,   # CM: Parent knows what doing
    mon_14_ctback = FCTBRS00   # CM: Tells parent when get back
  ) %>%
  mutate(
    across(starts_with("mon_"), ~ifelse(. < 0, NA_real_, .)),
    mon_14_child = rowMeans(select(., starts_with("mon_14_c")), na.rm = TRUE)
  )

# Merge monitoring
monitoring <- mon_parent %>%
  left_join(mon_child, by = "mcsid") %>%
  mutate(mon_14_avg = (mon_14_parent + mon_14_child) / 2)

# Weights
weights <- family_derived %>%
  select(mcsid = MCSID, weight_14 = FOVWT1) %>%
  mutate(weight_14 = ifelse(weight_14 > 0, weight_14, NA_real_))

# Merge all
wave6_age14 <- sc_items %>%
  left_join(monitoring, by = "mcsid") %>%
  left_join(weights, by = "mcsid") %>%
  mutate(wave6_participant = TRUE)

# Save
save(wave6_age14, file = file.path(out_path, "wave6_age14.RData"))
var_list <- data.frame(
  variable = names(wave6_age14),
  type = sapply(wave6_age14, class),
  n_missing = sapply(wave6_age14, function(x) sum(is.na(x))),
  pct_missing = round(100 * sapply(wave6_age14, function(x) mean(is.na(x))), 1)
)
write_csv(var_list, file.path(out_path, "wave6_age14_variables.csv"))

cat("✓ Wave 6 complete: N =", nrow(wave6_age14), "\n\n")
