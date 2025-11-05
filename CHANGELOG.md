# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-05

### Added - Repository Reorganization

#### Project Structure
- Created publication-ready directory structure following best practices
- Organized into logical subdirectories: `R/`, `data/`, `results/`, `docs/`, `manuscript/`
- Renamed and numbered analysis scripts for clear workflow (01-07)

#### Documentation
- **README.md**: Comprehensive project overview with installation, usage, and citation
- **data/README.md**: Detailed data documentation and access instructions
- **docs/codebook.md**: Complete variable codebook with all measures
- **docs/workflow.md**: Step-by-step analysis workflow guide
- **docs/methods.md**: Detailed methodological documentation
- **LICENSE**: MIT License with data usage notice
- **CHANGELOG.md**: This file

#### Configuration Files
- **DESCRIPTION**: R package-style project metadata
- **.Rprofile**: R environment setup with helper functions
- **.gitignore**: Comprehensive gitignore for data protection
- **R/00_master.R**: Master workflow script to run complete pipeline

#### Utilities
- **R/utils/functions.R**: Reusable helper functions for:
  - Package loading
  - Data validation
  - Model fit extraction
  - Reliability calculations
  - Plotting utilities
  - Session info management

### Changed

#### File Organization
- Moved all R scripts to `R/` directory with numbered prefixes:
  - `measurement.R` → `R/01_measurement.R`
  - `invariance.R` → `R/02_invariance.R`
  - `merge_sc_pa_factor_scores.R` → `R/03_merge_factor_scores.R`
  - `lgbm.R` → `R/04_lgbm.R`
  - `gmm_lgbm.R` → `R/05_gmm_lgbm.R`
  - `sem_trees.R` → `R/06_sem_trees.R`
  - `sem_trees_relaxed.R` → `R/07_sem_trees_relaxed.R`

- Organized outputs into subdirectories:
  - Model objects → `results/models/`
  - Figures → `results/figures/`
  - Reports → `results/reports/`
  - Tables → `results/tables/`

- Moved data documentation:
  - Variable names → `data/processed/`
  - Markdown reports → `results/reports/`

#### .gitignore
- Enhanced to protect sensitive data
- Configured for new directory structure
- Added exceptions for important documentation

### Documentation Improvements

#### README.md
- Project overview and motivation
- Complete directory structure diagram
- Data access instructions
- Reproducibility guidelines
- Installation and usage instructions
- Citation information
- Key findings summary

#### Technical Documentation
- **Codebook**: All variables with descriptions, coding, and psychometrics
- **Workflow**: Step-by-step guide with expected outputs and runtimes
- **Methods**: Detailed methodological documentation with decisions and sensitivity analyses

### Reproducibility Enhancements

#### Package Management
- Set up for `renv` integration
- DESCRIPTION file with all dependencies
- Version-controlled package requirements

#### Project Organization
- Relative paths (prepared for `here` package)
- Clear separation of raw/processed data
- Standardized output structure

#### Workflow Automation
- Master script (`00_master.R`) for complete pipeline
- Error handling and progress reporting
- Session info capture for reproducibility

### Best Practices Implementation

#### Research Compendium Structure
✓ Clear directory organization
✓ Comprehensive documentation
✓ Reproducible workflow
✓ Version control ready
✓ Open science friendly

#### Code Quality
✓ Utility functions for common operations
✓ Consistent coding style
✓ Extensive documentation
✓ Error handling

#### Data Management
✓ Data access documentation
✓ Variable codebook
✓ Missing data documentation
✓ Survey design information

## Previous Work (Pre-reorganization)

### Initial Analyses Completed

- ✓ Measurement models (6 waves)
- ✓ Measurement invariance testing
- ✓ Factor score extraction and merging
- ✓ Latent basis growth model (LGBM)
- ✓ SEM trees analysis (standard and relaxed)
- ✓ Preliminary results documented

### Key Findings (Retained)

- Self-control scale: Strong psychometric properties (α = 0.81-0.88)
- SEM trees: **No subgroups detected** (robust null finding)
- Documentation: Comprehensive results summaries created

---

## Future Planned Changes

### Version 1.1.0 (Planned)

- [ ] Complete Growth Mixture Model (GMM) analysis
- [ ] Add machine learning analyses (LightGBM)
- [ ] Create publication-ready figures
- [ ] Add supplementary materials for manuscript

### Version 1.2.0 (Planned)

- [ ] Implement `renv` for package management
- [ ] Add unit tests for utility functions
- [ ] Create vignettes for key analyses
- [ ] Add interactive visualizations

---

## Notes

### Breaking Changes
None - this is the initial reorganization

### Migration Guide
If using old script names, update to new numbered versions:
```r
# Old
source("measurement.R")

# New
source("R/01_measurement.R")
```

### Data Protection
All data files remain gitignored. Only code and documentation are version controlled.

---

**For questions or contributions**: Open an issue on GitHub

**Last Updated**: November 5, 2025
