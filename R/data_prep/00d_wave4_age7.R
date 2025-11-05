# ==============================================================================
# Extract Age 7 Data from MCS Wave 4
# ==============================================================================

library(pacman)
p_load(tidyverse, haven, here)

cat("\n=== WAVE 4 (AGE 7): SELF-CONTROL & PARENTING ===\n\n")

raw_path <- here("data", "raw", "MCS 4", "stata11_se")
out_path <- here("data", "processed")

# Load data
parent <- read_dta(file.path(raw_path, "mcs4_parent_interview.dta"))
derived <- read_dta(file.path(raw_path, "mcs4_derived_variables.dta"))

# Self-control items (prefix D)
sc_items <- parent %>%
  select(
    mcsid = MCSID,
    sc_7_thac = DSDQXF, sc_7_tcom = DSDQXE, sc_7_obey = DSDQXH,
    sc_7_dist = DSDQXL, sc_7_temp = DSDQXG, sc_7_rest = DSDQXA,
    sc_7_fidg = DSDQXJ, sc_7_lyin = DSDQXK
  ) %>%
  mutate(
    across(starts_with("sc_"), ~ifelse(. < 0, NA_real_, .)),
    sc_7_total = rowSums(select(., sc_7_thac:sc_7_fidg), na.rm = FALSE),
    sc_7_mean = rowMeans(select(., sc_7_thac:sc_7_fidg), na.rm = FALSE)
  )

# Parenting
parenting <- parent %>%
  select(
    mcsid = MCSID,
    harsh_7_smack = DPHYSM00, harsh_7_shout = DPSHSO00, harsh_7_telloff = DPHYTE00,
    harsh_7_bedroom = DPHYBD00, harsh_7_ignore = DPHYIG00, harsh_7_bribe = DPHYBR00,
    pos_7_reason = matches("DPPREA.*00"), pos_7_praise = matches("DPPRAI.*00"),
    pos_7_cuddle = matches("DPCUDD.*00")
  ) %>%
  mutate(
    across(everything() & where(is.numeric), ~ifelse(. < 0, NA_real_, .)),
    harsh_7_composite = rowMeans(select(., harsh_7_smack, harsh_7_shout, harsh_7_telloff), na.rm = TRUE),
    pos_7_composite = rowMeans(select(., starts_with("pos_7_")), na.rm = TRUE)
  )

# Weights
weights <- derived %>%
  select(mcsid = MCSID, weight_7 = DOVWT1) %>%
  mutate(weight_7 = ifelse(weight_7 > 0, weight_7, NA_real_))

# Merge
wave4_age7 <- sc_items %>%
  left_join(parenting, by = "mcsid") %>%
  left_join(weights, by = "mcsid") %>%
  mutate(wave4_participant = TRUE)

# Save
save(wave4_age7, file = file.path(out_path, "wave4_age7.RData"))
var_list <- data.frame(
  variable = names(wave4_age7),
  type = sapply(wave4_age7, class),
  n_missing = sapply(wave4_age7, function(x) sum(is.na(x))),
  pct_missing = round(100 * sapply(wave4_age7, function(x) mean(is.na(x))), 1)
)
write_csv(var_list, file.path(out_path, "wave4_age7_variables.csv"))

cat("✓ Wave 4 complete: N =", nrow(wave4_age7), "\n\n")
