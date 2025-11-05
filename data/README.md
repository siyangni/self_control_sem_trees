# Data Directory Documentation

## Overview

This directory contains data files for the self-control development project. Due to data sharing restrictions, **raw MCS data files are not included in this repository**.

## Directory Structure

```
data/
├── README.md              # This file
├── raw/                   # Original MCS data files (gitignored)
│   ├── mcs2_*.dta        # Wave 2 (Age 3) data files
│   ├── mcs3_*.dta        # Wave 3 (Age 5) data files
│   ├── mcs4_*.dta        # Wave 4 (Age 7) data files
│   ├── mcs5_*.dta        # Wave 5 (Age 11) data files
│   ├── mcs6_*.dta        # Wave 6 (Age 14) data files
│   └── mcs7_*.dta        # Wave 7 (Age 17) data files
└── processed/             # Derived datasets (gitignored)
    ├── merged_waves_recoded.RData       # Main analysis dataset
    ├── merged_sc_pa_fscores.RData       # Self-control & parenting factor scores
    ├── sc_wave_fscores_complete.RData   # Complete case factor scores
    └── merged_sc_pa_fscores_varnames.txt # Variable names reference
```

## Data Sources

### Millennium Cohort Study (MCS)

**Official Name**: 1970 British Cohort Study, Millennium Cohort Study
**Study Number**: Various (5350, 5795, 6411, 8156, 8682, etc.)
**Data Archive**: UK Data Service ([https://ukdataservice.ac.uk/](https://ukdataservice.ac.uk/))

### Required Data Files

To reproduce these analyses, you need:

#### Wave 2 (Age 3) - MCS2 [SN 5350]
- Parent interview data
- Cognitive assessment data
- Self-control items (SDQ)

#### Wave 3 (Age 5) - MCS3 [SN 5795]
- Parent interview data
- Cognitive assessment data
- Self-control items (SDQ)
- Parenting practices

#### Wave 4 (Age 7) - MCS4 [SN 6411]
- Parent interview data
- Self-control items (SDQ)
- Parenting practices

#### Wave 5 (Age 11) - MCS5 [SN 8156]
- Parent interview data
- Self-control items (SDQ)
- Parenting practices

#### Wave 6 (Age 14) - MCS6 [SN 8682]
- Parent interview data
- Youth self-report
- Self-control items (SDQ)
- Parental monitoring

#### Wave 7 (Age 17) - MCS7
- Parent interview data
- Youth self-report
- Self-control items (SDQ)
- Parental monitoring

## Data Access

### How to Obtain MCS Data

1. **Register** with the UK Data Service:
   - Visit [https://ukdataservice.ac.uk/](https://ukdataservice.ac.uk/)
   - Create a free account
   - Verify your institutional affiliation

2. **Complete Training**:
   - Data security and confidentiality training
   - Safe Researcher training (for sensitive data)

3. **Request Access**:
   - Search for "Millennium Cohort Study"
   - Select required waves
   - Complete End User License (EUL) agreement
   - Provide project details

4. **Download Data**:
   - Stata (.dta) format recommended
   - Download all required waves
   - Place files in `data/raw/` directory

### Data Use Restrictions

The MCS data are subject to the following restrictions:

- **Confidentiality**: Individual identifiers must be protected
- **Usage**: For approved research purposes only
- **Sharing**: Cannot share raw data files
- **Storage**: Must be stored securely
- **Destruction**: Must be deleted after project completion (unless archived)

**Important**: These analyses use **de-identified** data. No personally identifiable information is included.

## Key Variables

### Self-Control Measures (SDQ - Self-Control Subscale)

**7 Core Items (all waves):**

| Variable Pattern | Item Content | Response Format |
|-----------------|--------------|-----------------|
| `sc*thac` | Thinks things out before acting | 0=Certainly true, 1=Somewhat true, 2=Not true |
| `sc*tcom` | Sees tasks through to the end | 0=Certainly true, 1=Somewhat true, 2=Not true |
| `sc*obey` | Generally obedient | 0=Certainly true, 1=Somewhat true, 2=Not true |
| `sc*dist` | Easily distracted** | 0=Certainly true, 1=Somewhat true, 2=Not true |
| `sc*temp` | Has temper tantrums** | 0=Certainly true, 1=Somewhat true, 2=Not true |
| `sc*rest` | Restless/overactive** | 0=Certainly true, 1=Somewhat true, 2=Not true |
| `sc*fidg` | Fidgety/squirming** | 0=Certainly true, 1=Somewhat true, 2=Not true |

**8th Item (ages 5-17 only):**
| `sc*lyin` | Often lies or cheats** | 0=Certainly true, 1=Somewhat true, 2=Not true |

**Note**: Items marked with ** are reverse-coded in the original data (higher = better self-control).

**Wave-specific prefixes:**
- Wave 2 (Age 3): `sc3*` (e.g., `sc3thac`)
- Wave 3 (Age 5): `sc5*`
- Wave 4 (Age 7): `sc7*`
- Wave 5 (Age 11): `sc11*`
- Wave 6 (Age 14): `sc14*`
- Wave 7 (Age 17): `sc17*`

### Parenting Practice Measures

#### Early Harsh Discipline (Ages 3, 5, 7)

| Variable Pattern | Item Content |
|-----------------|--------------|
| `smack*` | How often smack child when naughty |
| `shout*` | How often shout at child when naughty |
| `telloff*` | How often tell child off when naughty |

#### Positive Parenting (Ages 5, 7)

| Variable Pattern | Item Content |
|-----------------|--------------|
| `reason*` | How often reason with child |
| `praise*` | How often praise child |
| `cuddle*` | How often cuddle child |
| `routines*` | Regular bedtime/meal routines |

#### Parental Monitoring (Ages 14, 17)

| Variable Pattern | Item Content |
|-----------------|--------------|
| `know_where*` | Know where child is after school |
| `know_who*` | Know who child is with |
| `know_doing*` | Know what child is doing |

### Baseline Covariates

| Variable | Description | Wave |
|----------|-------------|------|
| `sex` | Child sex (1=Male, 2=Female) | All |
| `brace` | Child ethnicity (condensed) | Baseline |
| `bmarried` | Mother married/cohabiting | Baseline |
| `bpedu` | Mother's highest education | Baseline |
| `incomef` | Family income quintile | Baseline |
| `scoga` | Cognitive ability (BAS scores) | Age 3 |
| `lbw` | Low birth weight (1=Yes) | Birth |
| `inftemp` | Difficult infant temperament | Age 9 months |
| `hfae` | High frequency adverse events | Ages 0-3 |

### Survey Design Variables

| Variable | Description |
|----------|-------------|
| `bovwt1` - `govwt1` | Survey weights (wave-specific) |
| `sptn00` | Primary sampling unit (cluster ID) |
| `pttype2` | Stratum identifier |
| `nh2` | Finite population correction |
| `mcsid` | Cohort member ID (unique identifier) |

## Missing Data

### Patterns

1. **Wave Nonresponse**: Not all families participate in all waves
   - Age 3: N ≈ 15,590
   - Age 17: N ≈ 11,142 (28% attrition)

2. **Item Nonresponse**: Varies by measure
   - Self-control: <5% missing conditional on wave participation
   - Parenting: 5-15% missing
   - Covariates: Varies widely

3. **Analysis Samples**:
   - Complete case (all covariates): N = 917
   - Relaxed covariates: N = 1,636
   - Full available data (some missing): N ≈ 16,877

### Handling Missing Data

- **Survey weights**: Account for unit nonresponse
- **Full Information Maximum Likelihood (FIML)**: For growth models (when appropriate)
- **Complete case analysis**: For SEM trees (method requirement)
- **Multiple imputation**: Not used (SEM tree limitations)

## Processed Data Files

### File Descriptions

#### `merged_waves_recoded.RData`
- **Content**: All six waves merged by cohort member ID
- **Variables**: ~500+ variables
- **N**: 16,877 unique individuals
- **Format**: R data frame (tibble)
- **Recoding**: Reverse-coded items, category consolidation
- **Created by**: `01_measurement.R` (data preparation section)

#### `merged_sc_pa_fscores.RData`
- **Content**: Factor scores for self-control (6 waves) + parenting (4 waves)
- **Variables**: ~60 factor scores + covariates
- **N**: Varies by analysis (917-1,636)
- **Format**: R data frame
- **Created by**: `03_merge_factor_scores.R`

#### `sc_wave_fscores_complete.RData`
- **Content**: Self-control factor scores with complete case selection
- **Variables**: 6 wave-specific factor scores
- **N**: Complete cases for growth modeling
- **Format**: R data frame
- **Created by**: `04_lgbm.R` preparation

#### `merged_sc_pa_fscores_varnames.txt`
- **Content**: Variable names and descriptions
- **Format**: Text file
- **Purpose**: Reference for factor score variables

## Data Citation

When using MCS data, cite:

> University of London, Institute of Education, Centre for Longitudinal Studies. (2021). *Millennium Cohort Study: [Wave]* [data collection]. [Edition]. UK Data Service. SN: [Study Number], DOI: [DOI]

### Example Citations by Wave:

**Wave 2 (Age 3)**:
> University of London, Institute of Education, Centre for Longitudinal Studies. (2012). *Millennium Cohort Study: Second Survey, 2003-2005* [data collection]. 9th Edition. UK Data Service. SN: 5350. http://doi.org/10.5255/UKDA-SN-5350-4

**Wave 7 (Age 17)**:
> University of London, Institute of Education, Centre for Longitudinal Studies. (2020). *Millennium Cohort Study: Age 17 Survey* [data collection]. 2nd Edition. UK Data Service. SN: 8682.

## Data Quality

### Strengths

- Large, nationally representative sample
- High-quality survey methodology
- Complex survey design properly accounted for
- Extensive covariate coverage
- Validated measures

### Limitations

- Attrition over time (~28% by age 17)
- Self-report bias for parenting measures
- Differential missingness (higher in low-SES families)
- Measurement non-equivalence across time (some items)

## Support

For questions about:

- **MCS data access**: Contact UK Data Service ([help@ukdataservice.ac.uk](mailto:help@ukdataservice.ac.uk))
- **MCS study design**: Visit CLS website ([https://cls.ucl.ac.uk/cls-studies/millennium-cohort-study/](https://cls.ucl.ac.uk/cls-studies/millennium-cohort-study/))
- **This project's data processing**: Open an issue on GitHub

## Version History

- **v1.0** (November 2025): Initial data preparation and documentation

---

**Last Updated**: November 2025
