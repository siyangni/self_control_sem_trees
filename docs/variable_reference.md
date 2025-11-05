# MCS Variable Reference Guide

**Self-Control Development Study - Variable Lookup Table**

Last Updated: 2025-11-05

---

## Table of Contents

1. [Self-Control Variables](#self-control-variables)
2. [Parenting Variables](#parenting-variables)
3. [Baseline Covariates](#baseline-covariates)
4. [Derived Composite Variables](#derived-composite-variables)
5. [Survey Design Variables](#survey-design-variables)
6. [MCS Raw Variable Names](#mcs-raw-variable-names)

---

## Self-Control Variables

### Core Items (7 items, consistent across all waves)

| Variable | Item Content | Response Scale | Coding |
|----------|--------------|----------------|--------|
| `sc_*_thac` | Thinks things out before acting | 0-2 | 0=Certainly true, 2=Not true |
| `sc_*_tcom` | Sees tasks through to completion | 0-2 | 0=Certainly true, 2=Not true |
| `sc_*_obey` | Generally obedient | 0-2 | 0=Certainly true, 2=Not true |
| `sc_*_dist` | Easily distracted (R) | 0-2 | 0=Certainly true, 2=Not true |
| `sc_*_temp` | Has temper tantrums (R) | 0-2 | 0=Certainly true, 2=Not true |
| `sc_*_rest` | Restless, overactive (R) | 0-2 | 0=Certainly true, 2=Not true |
| `sc_*_fidg` | Constantly fidgeting (R) | 0-2 | 0=Certainly true, 2=Not true |

*Note: (R) = Reverse-coded item; higher scores = better self-control*

### Additional Item (ages 5-17 only)

| Variable | Item Content | Response Scale | Availability |
|----------|--------------|----------------|--------------|
| `sc_*_lyin` | Often lies or cheats (R) | 0-2 | Waves 3-7 only (ages 5-17) |

### Summary Scores

| Variable | Description | Range | Formula |
|----------|-------------|-------|---------|
| `sc_*_total` | Sum of 7 core items | 0-14 | Sum(thac, tcom, obey, dist, temp, rest, fidg) |
| `sc_*_mean` | Mean of 7 core items | 0-2 | Mean(thac, tcom, obey, dist, temp, rest, fidg) |
| `sc_*_n_items` | Number of items completed | 0-7 | Count of non-missing items |

### Wave-Specific Variables

Replace `*` with age: 3, 5, 7, 11, 14, or 17

Examples:
- `sc_3_thac` = Thinks before acting at age 3
- `sc_17_total` = Total self-control score at age 17

---

## Parenting Variables

### Harsh Discipline (Ages 3, 5, 7)

| Variable | Item Content | Response Scale |
|----------|--------------|----------------|
| `harsh_*_smack` | How often smack child when naughty | 0=Never, 4=Daily |
| `harsh_*_shout` | How often shout at child when naughty | 0=Never, 4=Daily |
| `harsh_*_telloff` | How often tell off/scold child | 0=Never, 4=Daily |
| `harsh_*_bedroom` | How often send to bedroom | 0=Never, 4=Daily |
| `harsh_*_ignore` | How often ignore misbehavior | 0=Never, 4=Daily |
| `harsh_*_bribe` | How often bribe/promise treat | 0=Never, 4=Daily |

| Composite | Description |
|-----------|-------------|
| `harsh_*_composite` | Mean of smack, shout, telloff |

### Positive Parenting (Ages 5, 7)

| Variable | Item Content | Response Scale |
|----------|--------------|----------------|
| `pos_*_reason` | How often reason with child | 0=Never, 4=Always |
| `pos_*_praise` | How often praise child | 0=Never, 4=Always |
| `pos_*_cuddle` | How often cuddle/hug child | 0=Never, 4=Always |

| Composite | Description |
|-----------|-------------|
| `pos_*_composite` | Mean of reason, praise, cuddle |

### Parental Monitoring (Ages 14, 17)

**Parent Report:**

| Variable | Item Content | Response Scale |
|----------|--------------|----------------|
| `mon_*_pwhere` | Parent knows where CM is | 0=Don't know, 3=Know very well |
| `mon_*_pwho` | Parent knows who CM with | 0=Don't know, 3=Know very well |
| `mon_*_pwhat` | Parent knows what CM doing | 0=Don't know, 3=Know very well |
| `mon_*_ptback` | CM tells when getting back | 0=Never, 3=Always |

**Child Report:**

| Variable | Item Content | Response Scale |
|----------|--------------|----------------|
| `mon_*_cwhere` | CM: Parent knows where | 0=Don't know, 3=Know very well |
| `mon_*_cwho` | CM: Parent knows who with | 0=Don't know, 3=Know very well |
| `mon_*_cwhat` | CM: Parent knows what doing | 0=Don't know, 3=Know very well |
| `mon_*_ctback` | CM: Tells parent when back | 0=Never, 3=Always |

**Composites:**

| Variable | Description |
|----------|-------------|
| `mon_*_parent` | Mean of parent-reported monitoring |
| `mon_*_child` | Mean of child-reported monitoring |
| `mon_*_avg` | Mean of parent + child reports |

---

## Baseline Covariates

### Demographics

| Variable | Description | Type | Values |
|----------|-------------|------|--------|
| `sex` | Child sex | Factor | Male, Female |
| `ethnicity` | Child ethnicity (collapsed) | Factor | White, Mixed, Indian, Pakistani/Bangladeshi, Black/Black British, Other |
| `birth_order` | Birth order in household | Integer | 1, 2, 3, ... |

### Birth Outcomes

| Variable | Description | Type | Values |
|----------|-------------|------|--------|
| `birth_weight` | Birth weight in grams | Numeric | 500-6000 |
| `gestational_age` | Gestational age in weeks | Numeric | 22-45 |
| `low_birth_weight` | Birth weight < 2500g | Logical | TRUE/FALSE |
| `very_low_birth_weight` | Birth weight < 1500g | Logical | TRUE/FALSE |
| `premature` | Gestational age < 37 weeks | Logical | TRUE/FALSE |
| `very_premature` | Gestational age < 32 weeks | Logical | TRUE/FALSE |

### Socioeconomic Status

| Variable | Description | Type | Values |
|----------|-------------|------|--------|
| `maternal_education` | Mother's NVQ level | Integer | 1-6 |
| `mat_edu_level` | Mother's education (labeled) | Factor | None, NVQ1, NVQ2, NVQ3, NVQ4, NVQ5 |
| `mat_edu_collapsed` | Mother's education (3 groups) | Factor | Low, Medium, High |
| `income_quintile` | OECD equivalized income quintile | Integer | 1-5 |
| `income_tertile` | Income tertile | Factor | Low, Medium, High |
| `ses_group` | SES tertile from income | Factor | Low, Middle, High |
| `maternal_age` | Mother's age at birth | Numeric | 14-50 |

### Family Structure

| Variable | Description | Type | Values |
|----------|-------------|------|--------|
| `married` | Married/cohabiting at baseline | Logical | TRUE/FALSE |
| `housing` | Housing tenure | Factor | Own/Mortgage, Rent social, Rent private, Other |
| `household_size` | Number in household | Integer | 2-15 |

### Child Characteristics

| Variable | Description | Type | Values |
|----------|-------------|------|--------|
| `cognitive_3` | BAS cognitive ability at age 3 | Numeric | 0-200 |
| `difficult_temperament` | Infant temperament score | Numeric | Higher = more difficult |
| `difficult_temp_flag` | Top quartile temperament | Logical | TRUE/FALSE |

---

## Derived Composite Variables

### Time-Averaged Parenting

| Variable | Description | Formula |
|----------|-------------|---------|
| `harsh_early_avg` | Mean harsh discipline ages 3-7 | Mean(harsh_3, harsh_5, harsh_7) |
| `pos_early_avg` | Mean positive parenting ages 5-7 | Mean(pos_5, pos_7) |
| `mon_adolescent_avg` | Mean monitoring ages 14-17 | Mean(mon_14, mon_17) |

### Parenting Stability

| Variable | Description | Formula |
|----------|-------------|---------|
| `harsh_stability_sd` | SD of harsh discipline ages 3-7 | SD(harsh_3, harsh_5, harsh_7) |
| `harsh_consistent` | Low variability in harsh parenting | harsh_stability_sd < median |

### Categorical Groupings

| Variable | Description | Categories |
|----------|-------------|------------|
| `harsh_group` | Harsh parenting tertiles | Low, Medium, High |
| `pos_group` | Positive parenting tertiles | Low, Medium, High |

### Cumulative Risk

| Variable | Description | Range |
|----------|-------------|-------|
| `risk_low_birth_weight` | Risk: LBW | 0/1 |
| `risk_premature` | Risk: Premature birth | 0/1 |
| `risk_low_ses` | Risk: Low SES | 0/1 |
| `risk_single_parent` | Risk: Single parent | 0/1 |
| `risk_harsh_parenting` | Risk: High harsh parenting | 0/1 |
| `risk_difficult_temp` | Risk: Difficult temperament | 0/1 |
| `risk_index` | Sum of risk indicators | 0-6 |
| `risk_group` | Risk categories | No risk, Low, Medium, High |

### Self-Control Trajectory Summaries

| Variable | Description | Formula |
|----------|-------------|---------|
| `sc_mean_all` | Mean SC across all waves | Mean(sc_3, ..., sc_17) |
| `sc_volatility` | Within-person SD | SD(sc_3, ..., sc_17) |
| `sc_change_simple` | Per-year linear change | (sc_17 - sc_3) / 14 |
| `sc_peak` | Maximum SC score | Max(sc_3, ..., sc_17) |
| `sc_minimum` | Minimum SC score | Min(sc_3, ..., sc_17) |
| `sc_range` | Range of SC | sc_peak - sc_minimum |

---

## Survey Design Variables

| Variable | Description | Type |
|----------|-------------|------|
| `mcsid` | Cohort member ID | Character |
| `strata` | Stratification variable (pttype2) | Integer |
| `psu` | Primary sampling unit (sptn00) | Integer |
| `survey_weight` | Default longitudinal weight | Numeric |
| `wt_longitudinal` | Wave 7 weight (most restrictive) | Numeric |
| `wt_age3` | Wave 2 cross-sectional weight | Numeric |
| `wt_age5` | Wave 3 cross-sectional weight | Numeric |
| `wt_age7` | Wave 4 cross-sectional weight | Numeric |
| `wt_age11` | Wave 5 cross-sectional weight | Numeric |
| `wt_age14` | Wave 6 cross-sectional weight | Numeric |
| `wt_age17` | Wave 7 cross-sectional weight | Numeric |

---

## MCS Raw Variable Names

### Self-Control Items by Wave

| Item | Wave 2 (3y) | Wave 3 (5y) | Wave 4 (7y) | Wave 5 (11y) | Wave 6 (14y) | Wave 7 (17y) |
|------|-------------|-------------|-------------|--------------|--------------|--------------|
| Thinks ahead | BSDQXF | CSDQXF | DSDQXF | EPCPSD0F | FPCPSD0F | GPCPSD0F |
| Task completion | BSDQXE | CSDQXE | DSDQXE | EPCPSD0E | FPCPSD0E | GPCPSD0E |
| Obedient | BSDQXH | CSDQXH | DSDQXH | EPCPSD0H | FPCPSD0H | GPCPSD0H |
| Distracted | BSDQXL | CSDQXL | DSDQXL | EPCPSD0L | FPCPSD0L | GPCPSD0L |
| Temper | BSDQXG | CSDQXG | DSDQXG | EPCPSD0G | FPCPSD0G | GPCPSD0G |
| Restless | BSDQXA | CSDQXA | DSDQXA | EPCPSD0A | FPCPSD0A | GPCPSD0A |
| Fidgeting | BSDQXJ | CSDQXJ | DSDQXJ | EPCPSD0J | FPCPSD0J | GPCPSD0J |
| Lying | - | CSDQXK | DSDQXK | EPCPSD0K | FPCPSD0K | GPCPSD0K |

*Note: Prefix changes by wave: B=Wave 2, C=Wave 3, D=Wave 4, E=Wave 5, F=Wave 6, G=Wave 7*

### Parenting Variables by Wave

| Measure | Wave 2 (3y) | Wave 3 (5y) | Wave 4 (7y) |
|---------|-------------|-------------|-------------|
| Smack | BPHYSM00 | CPHYSM00 | DPHYSM00 |
| Shout | BPSHSO00 | CPSHSO00 | DPSHSO00 |
| Tell off | BPHYTE00 | CPHYTE00 | DPHYTE00 |
| Bedroom | BPHYBD00 | CPHYBD00 | DPHYBD00 |
| Ignore | BPHYIG00 | CPHYIG00 | DPHYIG00 |
| Bribe | BPHYBR00 | CPHYBR00 | DPHYBR00 |
| Reason | - | CPPREA* | DPPREA* |
| Praise | - | CPPRAI* | DPPRAI* |
| Cuddle | - | CPCUDD* | DPCUDD* |

*Note: Exact variable names may vary; use pattern matching in scripts*

### Monitoring Variables (Ages 14, 17)

**Parent Report:**

| Measure | Wave 6 (14y) | Wave 7 (17y) |
|---------|--------------|--------------|
| Know where | FPWHPR00 | GPWHPR00 |
| Know who with | FPWWPR00 | (Not available) |
| Know what doing | FPWDPR00 | GWDPR00 |
| Tell when back | (Not available) | GPTBPR00 |

**Child Report:**

| Measure | Wave 6 (14y) | Wave 7 (17y) |
|---------|--------------|--------------|
| Parent knows where | FCWHRS00 | GCWHRS00 |
| Parent knows who | FCWWRS00 | (Not available) |
| Parent knows what | FCWDRS00 | (Not available) |
| Tell when back | FCTBRS00 | GCTBRS00 |

### Survey Weights

| Wave | Variable Name |
|------|---------------|
| Wave 2 (age 3) | BOVWT1 |
| Wave 3 (age 5) | COVWT1 |
| Wave 4 (age 7) | DOVWT1 |
| Wave 5 (age 11) | EOVWT1 |
| Wave 6 (age 14) | FOVWT1 |
| Wave 7 (age 17) | GOVWT1 |

### Baseline Covariates (Wave 1)

| Measure | Variable Name |
|---------|---------------|
| Child sex | AHCSEX00 |
| Child ethnicity | ADC06E00 |
| Birth weight | APWGHT00 |
| Gestational age | APGEST00 |
| Maternal education | AMDQNI00 |
| Maternal age | AMDAGE00 |
| Income (OECD) | AOECDUK0 |
| Marital status | APFCIN00 |
| Housing tenure | AHTEN00 |
| Household size | AHSIZE00 |
| Infant temperament | APSDST00 |
| Strata | PTTYPE2 |
| PSU | SPTN00 |

---

## Usage Examples

### Load Specific Dataset

```r
# For SEMTree analysis with maximum sample size
load("data/processed/mcs_semtree_complete_minimal.RData")

# For LGBM with FIML
load("data/processed/mcs_lavaan_fiml.RData")

# For mixed models
load("data/processed/mcs_long_format.RData")
```

### Access Covariate Lists

```r
# Load predefined covariate sets
load("data/processed/covariate_lists.RData")

# Use in analysis
semtree_model <- semtree(
  model = lgbm_fit,
  data = mcs_semtree_complete_minimal,
  predictors = covariate_lists$minimal
)
```

### Select Specific Variable Types

```r
# Self-control total scores only
sc_scores <- mcs_merged %>%
  select(mcsid, sc_3_total, sc_5_total, sc_7_total,
         sc_11_total, sc_14_total, sc_17_total)

# All harsh parenting composites
harsh_parenting <- mcs_merged %>%
  select(mcsid, starts_with("harsh_") & ends_with("composite"))

# Baseline covariates only
baseline <- mcs_merged %>%
  select(mcsid, all_of(covariate_lists$baseline))
```

---

## Data Files Reference

| File | N (participants) | Purpose |
|------|------------------|---------|
| `mcs_merged_wide.RData` | ~18,000 | Full dataset (all cases) |
| `mcs_semtree_complete_full.RData` | ~900 | SEMTree with all covariates |
| `mcs_semtree_complete_minimal.RData` | ~3,000 | SEMTree with minimal covariates |
| `mcs_semtree_complete_theory.RData` | ~2,000 | SEMTree with theory covariates |
| `mcs_lavaan_fiml.RData` | ~10,000 | LGBM with FIML (≥3 waves) |
| `mcs_long_format.RData` | ~60,000 obs | Mixed models (long format) |

---

## Missing Data Codes

Original MCS missing codes (recoded to NA in processed data):

- `-9`: Refusal
- `-8`: Don't know
- `-2`: Not applicable (inapplicable)
- `-1`: Not applicable (item not applicable)

---

## References

**MCS Documentation:**
- MCS Guide to Datasets (2012)
- Wave-specific user guides (see data/raw/MCS*/mrdoc/pdf/)
- UKDA study pages (SN: 5350, 5795, 6411, 8156, 8682)

**Strength and Difficulties Questionnaire (SDQ):**
- Goodman, R. (1997). The Strengths and Difficulties Questionnaire. *Journal of Child Psychology and Psychiatry, 38*(5), 581-586.

---

**Last Updated:** 2025-11-05
**For Questions:** See main project README.md or docs/workflow.md
