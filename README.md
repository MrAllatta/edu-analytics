# NYC Education Analytics

A data analysis portfolio project exploring NYC public education through Open Data. Built with Org-mode literate programming and Quarto publishing.

## 📊 Project Overview

This project analyzes NYC Department of Education data across three domains:

- **Schools** - Building locations, space utilization, facilities
- **Students** - Enrollment, demographics, attendance patterns  
- **Learning** - Test scores, graduation rates, academic outcomes

## 🛠️ Technology Stack

| Component | Purpose |
|-----------|---------|
| **Org-mode** | Literate programming, source documents |
| **R** | Data analysis, visualization |
| **Quarto** | Website generation, publishing |
| **NYC Open Data** | Data source (Socrata API) |
| **Parquet** | Local data caching |

## 📁 Project Structure

```
edu-analytics/
├── org/                    # Org-mode source files
│   ├── index.org           # Home page
│   ├── schools.org         # Schools analysis
│   ├── students.org        # Students analysis
│   └── learning.org        # Learning outcomes
│
├── src/R/                  # R scripts
│   ├── setup.R             # Package loading
│   ├── nyc_data.R          # NYC Open Data library
│   └── utils.R             # Helper functions
│
├── scripts/                # Build scripts
│   ├── org-to-qmd.sh       # Shell export script
│   └── org-to-qmd.el       # Emacs export script
│
├── data/                   # Cached data (parquet)
├── output/                 # Generated figures
├── docs/                   # Quarto output (website)
│
├── _quarto.yml             # Quarto configuration
├── Makefile                # Build automation
└── README.md               # This file
```

## 🚀 Getting Started

### Prerequisites

- **R** (≥ 4.0) with packages: tidyverse, httr, jsonlite, arrow
- **Quarto** (≥ 1.3) - [Install from quarto.org](https://quarto.org/docs/get-started/)
- **Emacs** (optional) - For org-mode editing and export

### Setup

```bash
# Clone and enter project
cd edu-analytics

# Install R packages
make setup

# Or manually:
Rscript -e "source('src/R/setup.R')"
```

### Workflow

The project follows a literate programming workflow:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Edit .org  │ --> │ Export .qmd │ --> │   Render    │ --> │   Publish   │
│   (Emacs)   │     │ (make qmd)  │     │  (Quarto)   │     │   (docs/)   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### Commands

```bash
# Convert org files to Quarto markdown
make qmd

# Preview site locally (hot reload)
make preview

# Build final website
make render

# Fetch all datasets
make fetch-data

# Full build
make all

# See all commands
make help
```

## 📚 Data Library

The project includes a curated library of 22 NYC education datasets in `src/R/nyc_data.R`:

### Schools
| Dataset | ID | Description |
|---------|-----|-------------|
| `school_directory` | wg9x-4ke6 | DOE School Directory |
| `building_space_usage` | wavz-fkw8 | Building utilization |
| `school_locations` | jfju-ynrr | Geographic coordinates |
| `hs_directory` | uq7m-95z8 | High school details |
| `upk_directory` | kiyv-ks3f | Pre-K programs |

### Students
| Dataset | ID | Description |
|---------|-----|-------------|
| `demographic_snapshot` | s52a-8aq6 | Demographics by school |
| `enrollment` | 7z8d-msnt | Enrollment counts |
| `attendance` | hrwk-wb2d | Attendance rates |
| `swd_enrollment` | 47xe-dv98 | Special education |
| `ell_enrollment` | 72bx-k62e | English learners |

### Learning
| Dataset | ID | Description |
|---------|-----|-------------|
| `math_test_results` | jufi-gzgp | Math scores (Gr. 3-8) |
| `ela_test_results` | qkpp-pbi8 | ELA scores (Gr. 3-8) |
| `graduation_outcomes` | bn5q-ia5v | Graduation rates |
| `regents_results` | 2hcd-bsun | Regents exams |
| `sat_results` | f9bf-2cp4 | SAT scores |

### Usage

```r
source("src/R/setup.R")
source("src/R/nyc_data.R")

# List all available datasets
list_datasets()

# Fetch a dataset (with caching)
schools <- fetch_dataset(NYC_DATA$school_directory, cache_name = "schools")

# Fetch large dataset with pagination
demographics <- fetch_large_dataset(
  NYC_DATA$demographic_snapshot,
  cache_name = "demographics"
)
```

## ✏️ Org-mode Literate Programming

### R Code Block Template

```org
#+NAME: analysis-name
#+BEGIN_SRC R :results output graphics :file output/figure.png
## ============================================================
## Description of analysis
## ============================================================

data <- fetch_dataset(NYC_DATA$school_directory)

ggplot(data, aes(x = borough, y = enrollment)) +
  geom_boxplot() +
  labs(title = "Enrollment by Borough")
#+END_SRC
```

### Header Arguments

| Argument | Purpose |
|----------|---------|
| `:session *R*` | Use persistent R session |
| `:exports both` | Export code and results |
| `:results output` | Capture printed output |
| `:results graphics` | Generate image |
| `:file output/x.png` | Output file path |
| `:cache yes` | Cache results |

### Executing Code

In Emacs:
- `C-c C-c` - Execute block at point
- `C-c C-v b` - Execute all blocks in buffer
- `C-c C-e m m` - Export to markdown

## 🌐 Quarto Publishing

### Local Preview

```bash
make preview
# Opens http://localhost:4200
```

### Build Site

```bash
make render
# Output in docs/
```

### Deploy to GitHub Pages

1. Push `docs/` to repository
2. Enable GitHub Pages in Settings → Source: `docs/`

Or use Quarto Publish:

```bash
quarto publish gh-pages
```

## 📈 Example Analysis

```r
# Load libraries
source("src/R/setup.R")
source("src/R/nyc_data.R")
source("src/R/utils.R")

# Fetch school data
schools <- fetch_dataset(NYC_DATA$school_directory, cache_name = "schools")

# Analyze by borough
schools |>
  count(borough = standardize_borough(boro)) |>
  ggplot(aes(x = reorder(borough, n), y = n, fill = borough)) +
  geom_col() +
  scale_fill_borough() +
  coord_flip() +
  labs(
    title = "NYC Public Schools by Borough",
    x = NULL, y = "Number of Schools"
  ) +
  theme_minimal()
```

## 📄 License

This project is for educational purposes. Data is from [NYC Open Data](https://opendata.cityofnewyork.us/) under the NYC Open Data Terms of Use.

## 🔗 Resources

- [NYC Open Data Portal](https://opendata.cityofnewyork.us/)
- [Socrata SODA API](https://dev.socrata.com/)
- [Quarto Documentation](https://quarto.org/docs/)
- [Org-mode Manual](https://orgmode.org/manual/)
- [R for Data Science](https://r4ds.hadley.nz/)
