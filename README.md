# Self-Control Development Trajectory Heterogeneity Study

**Research Project: Identifying Subgroups in Self-Control Development Using Structural Equation Model Trees**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Data](#data)
- [Analyses](#analyses)
- [Key Findings](#key-findings)
- [Reproducibility](#reproducibility)
- [Requirements](#requirements)
- [Usage](#usage)
- [Citation](#citation)
- [Contact](#contact)

## Overview

This repository contains code and documentation for a longitudinal study examining heterogeneity in self-control development from early childhood through adolescence (ages 3-17). The project uses data from the **Millennium Cohort Study (MCS)**, a nationally representative UK birth cohort.

### Research Questions

1. **Measurement**: How well does the self-control construct perform across six developmental waves?
2. **Invariance**: Is self-control measured equivalently across time?
3. **Growth Trajectories**: What is the average developmental trajectory of self-control?
4. **Heterogeneity**: Do parenting practices and child characteristics predict distinct developmental subgroups?
5. **Classification**: Can machine learning methods identify patterns in self-control development?

### Methods

- **Confirmatory Factor Analysis (CFA)**: Measurement model validation
- **Measurement Invariance Testing**: Configural, weak, and strong invariance
- **Latent Basis Growth Models (LGBM)**: Developmental trajectories with ordinal indicators
- **Structural Equation Model Trees (SemTREE)**: Covariate-driven subgroup detection
- **Growth Mixture Models (GMM)**: Data-driven latent class identification
- **Machine Learning**: LightGBM for prediction and pattern recognition

## Project Structure

```
self_control_sem_trees/
│
├── README.md                          # This file
├── DESCRIPTION                        # Project metadata
├── .Rprofile                         # R environment configuration
├── renv.lock                         # R package dependencies (lockfile)
│
├── data/                             # Data directory (gitignored)
│   ├── README.md                     # Data documentation
│   ├── raw/                          # Original MCS data files
│   └── processed/                    # Derived datasets and factor scores
│
├── R/                                # Analysis scripts (run in order)
│   ├── 00_master.R                   # Master workflow script
│   ├── 01_measurement.R              # Measurement models (6 waves)
│   ├── 02_invariance.R               # Measurement invariance testing
│   ├── 03_merge_factor_scores.R      # Merge parenting & SC factor scores
│   ├── 04_lgbm.R                     # Latent basis growth models
│   ├── 05_gmm_lgbm.R                 # Growth mixture models
│   ├── 06_sem_trees.R                # SEM trees (standard parameters)
│   ├── 07_sem_trees_relaxed.R        # SEM trees (relaxed parameters)
│   └── utils/                        # Helper functions
│       └── functions.R               # Custom utility functions
│
├── results/                          # All outputs (gitignored except reports)
│   ├── figures/                      # Plots and visualizations
│   ├── tables/                       # Statistical tables
│   ├── models/                       # Model objects (.RData files)
│   └── reports/                      # Markdown analysis summaries
│
├── docs/                             # Documentation
│   ├── codebook.md                   # Variable descriptions
│   ├── methods.md                    # Detailed methodological notes
│   └── workflow.md                   # Step-by-step analysis guide
│
└── manuscript/                       # Publication materials
    └── supplementary/                # Supplementary materials
```

## Data

### Source

**Millennium Cohort Study (MCS)**: A longitudinal study following ~19,000 children born in the UK in 2000-2001 across seven waves.

- **Wave 2 (Age 3)**: 15,590 families
- **Wave 3 (Age 5)**: 15,246 families
- **Wave 4 (Age 7)**: 13,857 families
- **Wave 5 (Age 11)**: 13,287 families
- **Wave 6 (Age 14)**: 11,726 families
- **Wave 7 (Age 17)**: 11,142 families

**Access**: Data are available through the UK Data Service ([UKDS](https://ukdataservice.ac.uk/)).

### Measures

#### Self-Control Scale

Modified Strength and Difficulties Questionnaire (SDQ) - Self-Control subscale
- **7 core items** (consistent across all waves)
- **1 additional item** ("lying") at ages 5-17
- **Response format**: 0 (Certainly true) to 2 (Not true)
- **Reliability**: Ordinal α = 0.81-0.88, Ordinal ω = 0.83-0.90

#### Parenting Practices

- **Early harsh discipline** (ages 3, 5, 7): Smacking, shouting, telling off
- **Positive parenting** (ages 5, 7): Reasoning, praise, routines
- **Parental monitoring** (ages 14, 17): Knowledge of activities, whereabouts

#### Covariates (N=47)

- **Baseline characteristics**: SES, cognition, temperament, birth outcomes
- **Demographics**: Sex, race/ethnicity, family structure

### Data Access & Ethics

This project uses restricted-access data from the MCS. Researchers must:

1. Register with the [UK Data Service](https://ukdataservice.ac.uk/)
2. Complete required training on data security and confidentiality
3. Obtain institutional approval for secondary data analysis
4. Sign End User License agreements

**Data are NOT included in this repository** to comply with data sharing restrictions.

## Analyses

### 1. Measurement Models (`01_measurement.R`)

- Single-factor CFA at each wave
- Ordinal indicators with WLSMV estimation
- Survey weights applied (wave-specific)
- Reliability: Ordinal alpha and omega
- Multilevel CFA: Within/between reliability

**Key Results**:
- Good to acceptable fit across all waves
- High reliability (α > 0.80, ω > 0.82)
- ICC = 75.3% (high trait stability)

### 2. Measurement Invariance (`02_invariance.R`)

- Configural → Weak → Strong → Strict invariance
- Nested model comparisons (ΔCFI, ΔRMSEA)
- Partial invariance if needed

### 3. Factor Score Integration (`03_merge_factor_scores.R`)

- Extract self-control factor scores (6 waves)
- Merge with parenting practice scores
- Create analysis-ready dataset

### 4. Latent Basis Growth Models (`04_lgbm.R`)

- Second-order growth model
- 42 ordinal indicators across 6 waves
- WLSMV estimation
- Freely estimated time scores

### 5. Growth Mixture Models (`05_gmm_lgbm.R`)

- Data-driven latent class identification
- Test 1-5 class solutions
- Model selection: BIC, entropy, BLRT

### 6. SEM Trees (`06_sem_trees.R`, `07_sem_trees_relaxed.R`)

**Standard analysis**:
- α = 0.05, min N = 100
- 47 covariates
- N = 917 complete cases

**Relaxed analysis**:
- α = 0.10, min N = 50
- 16 theory-driven covariates
- N = 1,636

**Result**: **No significant splits detected** in either analysis (robust null finding)

### 7. Machine Learning (in progress)

- LightGBM for prediction
- Variable importance
- Interaction detection

## Key Findings

### Main Results

1. **Measurement Quality**: Self-control scale demonstrates strong psychometric properties across development (ages 3-17)

2. **Developmental Trajectory**: Self-control shows moderate stability (ICC=75%) with developmental change

3. **Subgroup Detection**: **No evidence of parenting-based subgroups** in growth trajectories
   - 151 total trees tested (all found no splits)
   - Robust across sensitivity analyses
   - Suggests uniform effects of parenting practices

4. **Substantive Interpretation**:
   - Self-control development may follow relatively uniform patterns
   - Heterogeneity exists but not explained by measured covariates
   - Points to unmeasured factors (genetic, peer, neighborhood effects)

### Implications

This **null finding is scientifically meaningful**:
- Challenges assumptions about strong moderation by parenting
- Aligns with recent meta-analyses showing small parenting effect sizes
- Informs precision prevention: universal vs. targeted approaches
- Highlights need for examining other sources of heterogeneity

## Reproducibility

### System Requirements

- **R version**: ≥ 4.2.0 (recommended: 4.4.0)
- **Operating System**: Linux, macOS, or Windows
- **Memory**: ≥ 16 GB RAM (some models require substantial memory)
- **Disk Space**: ≥ 5 GB (for data and results)

### R Package Dependencies

This project uses `renv` for reproducible package management. Key packages:

**Core Analysis**:
- `lavaan` (≥ 0.6-16): Structural equation modeling
- `semTools` (≥ 0.5-6): SEM utilities
- `semtree` (≥ 0.9.18): SEM trees and forests
- `OpenMx` (≥ 2.21): Alternative SEM engine

**Data Management**:
- `tidyverse` (≥ 2.0.0): Data wrangling and visualization
- `haven` (≥ 2.5.3): Reading Stata files
- `here` (≥ 1.0.1): Project-relative paths

**Survey Methodology**:
- `survey` (≥ 4.2-1): Complex survey design
- `psych` (≥ 2.3.6): Psychometric analysis

**Machine Learning**:
- `lightgbm` (≥ 4.0.0): Gradient boosting
- `randomForest` (≥ 4.7-1): Random forests

### Setup Instructions

#### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/self_control_sem_trees.git
cd self_control_sem_trees
```

#### 2. Install R Packages

**Option A: Using renv (Recommended)**

```r
# Install renv if needed
install.packages("renv")

# Restore project library
renv::restore()
```

**Option B: Manual Installation**

```r
# Install required packages
install.packages(c("tidyverse", "haven", "lavaan", "semTools",
                   "semtree", "survey", "psych", "here"))
```

#### 3. Obtain MCS Data

1. Register at [UK Data Service](https://ukdataservice.ac.uk/)
2. Request access to MCS datasets (SN 5350, 5795, 6411, 8156, 8682)
3. Download Stata files
4. Place in `data/raw/` directory

#### 4. Run Analyses

**Sequential execution**:

```r
# Source master script
source("R/00_master.R")
```

**Or run scripts individually**:

```r
source("R/01_measurement.R")
source("R/02_invariance.R")
# ... etc.
```

### Computational Time

| Script | Approximate Runtime | Memory |
|--------|---------------------|--------|
| 01_measurement.R | ~10 minutes | 2 GB |
| 02_invariance.R | ~20 minutes | 4 GB |
| 04_lgbm.R | ~30 minutes | 8 GB |
| 05_gmm_lgbm.R | ~2 hours | 12 GB |
| 06_sem_trees.R | ~2 minutes* | 4 GB |
| 07_sem_trees_relaxed.R | ~3 minutes* | 4 GB |

*Time assumes no splits found. If splits detected, add 1-2 hours for forest computation.

## Usage

### Quick Start

```r
# Load libraries
library(tidyverse)
library(lavaan)
library(semtree)
library(here)

# Set working directory to project root
setwd(here::here())

# Run complete workflow
source("R/00_master.R")
```

### Individual Analysis Examples

**Example 1: Fit Single-Wave CFA**

```r
source("R/01_measurement.R")

# Results saved to:
# - results/models/measurement_wave*.RData
# - results/tables/reliability_summary.csv
```

**Example 2: Test Measurement Invariance**

```r
source("R/02_invariance.R")

# Results saved to:
# - results/models/invariance_models.RData
# - results/tables/invariance_fit.csv
```

**Example 3: Run SEM Tree Analysis**

```r
source("R/06_sem_trees.R")

# Results saved to:
# - results/models/semtree_results.RData
# - results/figures/semtree_plot.pdf
# - results/reports/SEMTREE_FINAL_SUMMARY.md
```

### Modifying Parameters

Edit control parameters in script headers:

```r
# Example: More permissive SEM tree
ctrl <- semtree_control(
  method = "fair",
  alpha = 0.10,           # More liberal
  min.N = 50,             # Smaller nodes
  max.depth = 8,          # Deeper trees
  verbose = TRUE
)
```

## Citation

If you use this code or adapt these methods, please cite:

**APA Format**:
> [Author]. (2025). *Identifying subgroups in self-control development: A structural equation model tree approach*. [Journal/University]. [DOI/URL]

**BibTeX**:
```bibtex
@article{author2025selfcontrol,
  title={Identifying subgroups in self-control development: A structural equation model tree approach},
  author={Author, Name},
  journal={Journal Name},
  year={2025},
  doi={XX.XXXX/XXXXX}
}
```

### Methodological References

**SEM Trees**:
> Brandmaier, A. M., Prindle, J. J., McArdle, J. J., & Lindenberger, U. (2016). Theory-guided exploration with structural equation model trees. *Psychological Methods, 21*(4), 566-582.

**LGBM**:
> McArdle, J. J., & Epstein, D. B. (1987). Latent growth curves within developmental structural equation models. *Child Development, 58*, 110-133.

**MCS**:
> Connelly, R., & Platt, L. (2014). Cohort profile: UK Millennium Cohort Study (MCS). *International Journal of Epidemiology, 43*(6), 1719-1725.

## License

This project is licensed under the **MIT License** - see LICENSE file for details.

**Note**: The MCS data are subject to separate licensing restrictions. Code is openly available; data access requires UKDS registration.

## Contact

**Researcher**: [Your Name]
**Institution**: [Your Institution]
**Email**: [your.email@domain.com]
**GitHub**: [@yourusername](https://github.com/yourusername)

## Acknowledgments

This research uses data from the Millennium Cohort Study (MCS), funded by the UK Economic and Social Research Council (ESRC) and consortium of government departments. We thank the MCS families for their participation and the Centre for Longitudinal Studies (CLS) at UCL for data collection and management.

## Project Status

- [x] Data preparation
- [x] Measurement models
- [x] Invariance testing
- [x] Growth models (LGBM)
- [x] SEM tree analyses
- [ ] Growth mixture models (in progress)
- [ ] Machine learning analyses (in progress)
- [ ] Manuscript preparation (in progress)

**Last Updated**: November 2025

---

For questions, issues, or contributions, please open an issue on GitHub or contact the project maintainer.
