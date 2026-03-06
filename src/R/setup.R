## ============================================================
## setup.R - Package Loading and Configuration
## NYC Education Analytics Project
## ============================================================

## -- Required Packages --
required_packages <- c(
  # Core tidyverse
  "tidyverse",
  "dplyr",
  "tidyr",
  "ggplot2",
  "readr",
  "stringr",
  "forcats",
  "lubridate",
  "here",

  # Data access
  "httr",
  "jsonlite",
  
  # Data storage
  "arrow",      # Parquet files
  
  # Tables
  "knitr",
  "kableExtra",
  
  # Visualization
  "scales",
  "viridis",
  "patchwork"
)

## -- Install Missing Packages --
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("Installing %s...", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

invisible(lapply(required_packages, install_if_missing))

## -- Load Packages --
suppressPackageStartupMessages({
  library(tidyverse)
  library(httr)
  library(jsonlite)
  library(arrow)
  library(scales)
  library(viridis)
})

## -- Global Options --
options(
  dplyr.summarise.inform = FALSE,
  scipen = 999,              # Avoid scientific notation
  digits = 4,
  tibble.print_max = 20,
  tibble.width = Inf
)

## -- ggplot2 Theme --
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
)

## -- Project Paths --
PROJECT_ROOT <- here::here()
DATA_DIR     <- file.path(PROJECT_ROOT, "data")
OUTPUT_DIR   <- file.path(PROJECT_ROOT, "output")

# Create directories if they don't exist
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

## -- Confirmation --
message("✓ Setup complete. Packages loaded.")
message(sprintf("  Data directory: %s", DATA_DIR))
message(sprintf("  Output directory: %s", OUTPUT_DIR))
