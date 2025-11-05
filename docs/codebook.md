# Variable Codebook

## Self-Control Development Study - Variable Documentation

**Last Updated**: November 2025
**Data Source**: Millennium Cohort Study (MCS)
**Coverage**: Waves 2-7 (Ages 3-17)

---

## Table of Contents

- [Outcome Variables](#outcome-variables)
- [Parenting Variables](#parenting-variables)
- [Baseline Covariates](#baseline-covariates)
- [Survey Design Variables](#survey-design-variables)
- [Derived Variables](#derived-variables)

---

## Outcome Variables

### Self-Control (Strength and Difficulties Questionnaire)

**Source**: Parent report (ages 3-14), Youth self-report (ages 14-17)
**Response Format**: 0 = Certainly true, 1 = Somewhat true, 2 = Not true
**Scoring**: Higher values = Better self-control

#### Core Items (All 6 Waves)

| Variable | Label | Wave | Reverse Coded |
|----------|-------|------|---------------|
| `sc3thac` | Thinks things out before acting | Age 3 | No |
| `sc5thac` | Thinks things out before acting | Age 5 | No |
| `sc7thac` | Thinks things out before acting | Age 7 | No |
| `sc11thac` | Thinks things out before acting | Age 11 | No |
| `sc14thac` | Thinks things out before acting | Age 14 | No |
| `sc17thac` | Thinks things out before acting | Age 17 | No |
| | | | |
| `sc3tcom` | Sees tasks through to completion | Age 3 | No |
| `sc5tcom` | Sees tasks through to completion | Age 5 | No |
| `sc7tcom` | Sees tasks through to completion | Age 7 | No |
| `sc11tcom` | Sees tasks through to completion | Age 11 | No |
| `sc14tcom` | Sees tasks through to completion | Age 14 | No |
| `sc17tcom` | Sees tasks through to completion | Age 17 | No |
| | | | |
| `sc3obey` | Generally obedient | Age 3 | No |
| `sc5obey` | Generally obedient | Age 5 | No |
| `sc7obey` | Generally obedient | Age 7 | No |
| `sc11obey` | Generally obedient | Age 11 | No |
| `sc14obey` | Generally obedient | Age 14 | No |
| `sc17obey` | Generally obedient | Age 17 | No |
| | | | |
| `sc3dist` | Easily distracted, concentration wanders | Age 3 | **Yes** |
| `sc5dist` | Easily distracted, concentration wanders | Age 5 | **Yes** |
| `sc7dist` | Easily distracted, concentration wanders | Age 7 | **Yes** |
| `sc11dist` | Easily distracted, concentration wanders | Age 11 | **Yes** |
| `sc14dist` | Easily distracted, concentration wanders | Age 14 | **Yes** |
| `sc17dist` | Easily distracted, concentration wanders | Age 17 | **Yes** |
| | | | |
| `sc3temp` | Has temper tantrums or hot tempers | Age 3 | **Yes** |
| `sc5temp` | Has temper tantrums or hot tempers | Age 5 | **Yes** |
| `sc7temp` | Has temper tantrums or hot tempers | Age 7 | **Yes** |
| `sc11temp` | Has temper tantrums or hot tempers | Age 11 | **Yes** |
| `sc14temp` | Has temper tantrums or hot tempers | Age 14 | **Yes** |
| `sc17temp` | Has temper tantrums or hot tempers | Age 17 | **Yes** |
| | | | |
| `sc3rest` | Restless, overactive, cannot stay still | Age 3 | **Yes** |
| `sc5rest` | Restless, overactive, cannot stay still | Age 5 | **Yes** |
| `sc7rest` | Restless, overactive, cannot stay still | Age 7 | **Yes** |
| `sc11rest` | Restless, overactive, cannot stay still | Age 11 | **Yes** |
| `sc14rest` | Restless, overactive, cannot stay still | Age 14 | **Yes** |
| `sc17rest` | Restless, overactive, cannot stay still | Age 17 | **Yes** |
| | | | |
| `sc3fidg` | Constantly fidgeting or squirming | Age 3 | **Yes** |
| `sc5fidg` | Constantly fidgeting or squirming | Age 5 | **Yes** |
| `sc7fidg` | Constantly fidgeting or squirming | Age 7 | **Yes** |
| `sc11fidg` | Constantly fidgeting or squirming | Age 11 | **Yes** |
| `sc14fidg` | Constantly fidgeting or squirming | Age 14 | **Yes** |
| `sc17fidg` | Constantly fidgeting or squirming | Age 17 | **Yes** |

#### Additional Item (Ages 5-17 Only)

| Variable | Label | Wave | Reverse Coded |
|----------|-------|------|---------------|
| `sc5lyin` | Often lies or cheats | Age 5 | **Yes** |
| `sc7lyin` | Often lies or cheats | Age 7 | **Yes** |
| `sc11lyin` | Often lies or cheats | Age 11 | **Yes** |
| `sc14lyin` | Often lies or cheats | Age 14 | **Yes** |
| `sc17lyin` | Often lies or cheats | Age 17 | **Yes** |

**Note**: Items marked "Yes" for reverse coding are already reverse-coded in the processed data.

**Reliability** (Ordinal Alpha):
- Age 3: α = 0.81, ω = 0.83
- Age 5: α = 0.86, ω = 0.87
- Age 7: α = 0.87, ω = 0.88
- Age 11: α = 0.88, ω = 0.89
- Age 14: α = 0.88, ω = 0.90
- Age 17: α = 0.88, ω = 0.90

---

## Parenting Variables

### Harsh Discipline (Ages 3, 5, 7)

**Source**: Parent interview
**Question**: "When [child] is naughty, how often do you..."

| Variable | Label | Values |
|----------|-------|--------|
| `smack3` | Smack child | 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily |
| `smack5` | Smack child | 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily |
| `smack7` | Smack child | 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily |
| | | |
| `shout3` | Shout at child | 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily |
| `shout5` | Shout at child | 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily |
| `shout7` | Shout at child | 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily |
| | | |
| `telloff3` | Tell child off | 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily |
| `telloff5` | Tell child off | 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily |
| `telloff7` | Tell child off | 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily |

### Positive Parenting (Ages 5, 7)

**Source**: Parent interview

| Variable | Label | Values |
|----------|-------|--------|
| `reason5` | Reason with child | 0=Never, 1=Rarely, 2=Sometimes, 3=Often, 4=Always |
| `reason7` | Reason with child | 0=Never, 1=Rarely, 2=Sometimes, 3=Often, 4=Always |
| | | |
| `praise5` | Praise child | 0=Never, 1=Rarely, 2=Sometimes, 3=Often, 4=Always |
| `praise7` | Praise child | 0=Never, 1=Rarely, 2=Sometimes, 3=Often, 4=Always |
| | | |
| `cuddle5` | Cuddle child | 0=Never, 1=Rarely, 2=Sometimes, 3=Often, 4=Always |
| `cuddle7` | Cuddle child | 0=Never, 1=Rarely, 2=Sometimes, 3=Often, 4=Always |

### Parental Monitoring (Ages 14, 17)

**Source**: Parent interview
**Question**: "How much do you know about..."

| Variable | Label | Values |
|----------|-------|--------|
| `know_where14` | Know where child is | 0=Don't know, 1=Know a little, 2=Know quite well, 3=Know very well |
| `know_where17` | Know where child is | 0=Don't know, 1=Know a little, 2=Know quite well, 3=Know very well |
| | | |
| `know_who14` | Know who child is with | 0=Don't know, 1=Know a little, 2=Know quite well, 3=Know very well |
| `know_who17` | Know who child is with | 0=Don't know, 1=Know a little, 2=Know quite well, 3=Know very well |
| | | |
| `know_doing14` | Know what child is doing | 0=Don't know, 1=Know a little, 2=Know quite well, 3=Know very well |
| `know_doing17` | Know what child is doing | 0=Don't know, 1=Know a little, 2=Know quite well, 3=Know very well |

---

## Baseline Covariates

### Demographics

| Variable | Label | Values | Wave |
|----------|-------|--------|------|
| `sex` | Child sex | 1=Male, 2=Female | All |
| `brace` | Child ethnicity | 1=White, 2=Mixed, 3=Indian, 4=Pakistani/Bangladeshi, 5=Black, 6=Other | Baseline |
| `bmarried` | Mother marital status | 0=Single, 1=Married/cohabiting | Baseline |

### Socioeconomic Status

| Variable | Label | Values | Wave |
|----------|-------|--------|------|
| `bpedu` | Mother education | 1=None, 2=NVQ1, 3=NVQ2, 4=NVQ3, 5=NVQ4, 6=NVQ5 | Baseline |
| `incomef` | Family income quintile | 1=Lowest to 5=Highest | Each wave |
| `tenure` | Housing tenure | 1=Own, 2=Rent social, 3=Rent private | Each wave |

### Child Characteristics

| Variable | Label | Values | Wave |
|----------|-------|--------|------|
| `scoga` | Cognitive ability (BAS) | Continuous (standardized) | Age 3 |
| `lbw` | Low birth weight | 0=No (<2500g), 1=Yes (≥2500g) | Birth |
| `premature` | Premature birth | 0=No, 1=Yes (<37 weeks) | Birth |
| `inftemp` | Difficult infant temperament | Continuous scale | Age 9 months |

### Family Context

| Variable | Label | Values | Wave |
|----------|-------|--------|------|
| `hfae` | High frequency adverse events | 0=No, 1=Yes | Ages 0-3 |
| `famsize` | Family size | Count of children | Each wave |
| `birthorder` | Birth order | 1=First, 2=Second, 3=Third+ | Baseline |
| `matage` | Maternal age at birth | Continuous (years) | Baseline |

---

## Survey Design Variables

### Weights

| Variable | Label | Description |
|----------|-------|-------------|
| `bovwt1` | Wave 2 weight | Age 3 survey weight (all UK) |
| `covwt1` | Wave 3 weight | Age 5 survey weight (all UK) |
| `dovwt1` | Wave 4 weight | Age 7 survey weight (all UK) |
| `eovwt1` | Wave 5 weight | Age 11 survey weight (all UK) |
| `fovwt1` | Wave 6 weight | Age 14 survey weight (all UK) |
| `govwt1` | Wave 7 weight | Age 17 survey weight (all UK) |

**Note**: Use wave-specific weights for cross-sectional analyses. For longitudinal analyses, use appropriate longitudinal weights or modeling approaches.

### Complex Survey Design

| Variable | Label | Description |
|----------|-------|-------------|
| `sptn00` | PSU identifier | Primary sampling unit (cluster) |
| `pttype2` | Stratum | Sampling stratum |
| `nh2` | FPC | Finite population correction factor |

### Identifiers

| Variable | Label | Description |
|----------|-------|-------------|
| `mcsid` | Cohort member ID | Unique person identifier (de-identified) |
| `wave` | Survey wave | 2=Age 3, 3=Age 5, ..., 7=Age 17 |

---

## Derived Variables

### Factor Scores

**Extraction Method**: WLSMV estimation with polychoric correlations
**Standardization**: Mean=0, SD=1 within wave

#### Self-Control Factor Scores

| Variable | Label | Description |
|----------|-------|-------------|
| `sc_fs_3` | Self-control FS (Age 3) | 7-item factor score |
| `sc_fs_5` | Self-control FS (Age 5) | 7-item factor score |
| `sc_fs_7` | Self-control FS (Age 7) | 7-item factor score |
| `sc_fs_11` | Self-control FS (Age 11) | 7-item factor score |
| `sc_fs_14` | Self-control FS (Age 14) | 7-item factor score |
| `sc_fs_17` | Self-control FS (Age 17) | 7-item factor score |

**Note**: We use the 7-item version (excluding "lying") for consistency across all waves.

#### Parenting Factor Scores

| Variable | Label | Description |
|----------|-------|-------------|
| `harsh_fs_3` | Harsh discipline FS (Age 3) | 3-item composite |
| `harsh_fs_5` | Harsh discipline FS (Age 5) | 3-item composite |
| `harsh_fs_7` | Harsh discipline FS (Age 7) | 3-item composite |
| `positive_fs_5` | Positive parenting FS (Age 5) | 3-item composite |
| `positive_fs_7` | Positive parenting FS (Age 7) | 3-item composite |
| `monitor_fs_14` | Parental monitoring FS (Age 14) | 3-item composite |
| `monitor_fs_17` | Parental monitoring FS (Age 17) | 3-item composite |

### Growth Parameters (from LGBM)

| Variable | Label | Description |
|----------|-------|-------------|
| `sc_intercept` | Self-control intercept | Initial level (age 3) |
| `sc_slope` | Self-control slope | Linear change rate |
| `sc_quad` | Self-control quadratic | Non-linear change (if estimated) |

### Analysis Indicators

| Variable | Label | Description |
|----------|-------|-------------|
| `.complete` | Complete case indicator | 1=Complete on all variables |
| `.nmiss` | Number missing | Count of missing items |
| `.ok` | Analysis ready | 1=Complete + valid weight + design vars |

---

## Missing Data Codes

### Original MCS Codes

- `-9` = Refusal
- `-8` = Don't know
- `-1` = Not applicable
- `.` = System missing

### Processed Data

All special missing values are recoded to `NA` in R.

---

## Variable Naming Conventions

### Patterns

- **Wave prefix**: `sc3*`, `sc5*`, `sc7*`, etc. for self-control
- **Baseline**: `b*` prefix (e.g., `bpedu`, `brace`)
- **Factor scores**: `*_fs_*` pattern (e.g., `sc_fs_3`)
- **Survey weights**: `*ovwt1` pattern (e.g., `bovwt1`)

### Abbreviations

- `sc` = Self-control
- `fs` = Factor score
- `b` = Baseline
- `ovwt` = Overall weight (all UK)
- `psu` = Primary sampling unit
- `fpc` = Finite population correction

---

## Data Quality Notes

### Item-Level

- **Self-control items**: <5% missing conditional on wave participation
- **Parenting items**: 5-15% missing (varies by item and wave)
- **Covariates**: Varies (SES variables have ~10-20% missing)

### Wave-Level

- **Attrition**: ~28% cumulative attrition from age 3 to age 17
- **Differential attrition**: Higher among low-SES families
- **Weights**: Adjust for attrition and differential response

### Scale-Level

- **Measurement invariance**: Partial strong invariance established (ages 3-17)
- **Cross-informant**: Parent report ages 3-14, some youth self-report at 14+
- **Developmental appropriateness**: All items validated across age range

---

## References

### Original Measures

**Strength and Difficulties Questionnaire**:
> Goodman, R. (1997). The Strengths and Difficulties Questionnaire: A research note. *Journal of Child Psychology and Psychiatry, 38*(5), 581-586.

**MCS Documentation**:
> Centre for Longitudinal Studies. (2021). *Millennium Cohort Study User Guide (Surveys 1-7)* [PDF]. UCL Institute of Education.

---

**Version**: 1.0
**Last Updated**: November 2025
**Contact**: Open an issue on GitHub for questions or corrections

