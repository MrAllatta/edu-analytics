## ============================================================
## utils.R - Helper Functions for NYC Education Analytics
## ============================================================

#' Standardize borough names
#' 
#' @param x Vector of borough names/codes
#' @return Factor with standardized borough names
#'
standardize_borough <- function(x) {
  x <- toupper(as.character(x))
  
  borough_map <- c(
    "M" = "Manhattan",
    "MANHATTAN" = "Manhattan",
    "NEW YORK" = "Manhattan",
    "X" = "Bronx",
    "BRONX" = "Bronx",
    "K" = "Brooklyn",
    "BROOKLYN" = "Brooklyn",
    "KINGS" = "Brooklyn",
    "Q" = "Queens",
    "QUEENS" = "Queens",
    "R" = "Staten Island",
    "STATEN ISLAND" = "Staten Island",
    "RICHMOND" = "Staten Island"
  )
  
  result <- borough_map[x]
  result[is.na(result)] <- x[is.na(result)]
  
  factor(result, levels = c("Manhattan", "Bronx", "Brooklyn", "Queens", "Staten Island"))
}

#' Parse school DBN (District-Borough-Number)
#' 
#' @param dbn School DBN code (e.g., "01M015")
#' @return tibble with district, borough, school_num columns
#'
parse_dbn <- function(dbn) {
  tibble::tibble(
    dbn = dbn,
    district = as.integer(substr(dbn, 1, 2)),
    borough_code = substr(dbn, 3, 3),
    school_num = substr(dbn, 4, 6),
    borough = standardize_borough(substr(dbn, 3, 3))
  )
}

#' Convert percentage strings to numeric
#' 
#' @param x Vector of percentage values (e.g., "45.2%" or "45.2")
#' @return Numeric vector
#'
parse_pct <- function(x) {
  x <- gsub("%", "", as.character(x))
  x <- gsub(",", "", x)  # Remove commas
  as.numeric(x)
}

#' Safe numeric conversion
#' 
#' @param x Vector to convert
#' @param default Value for NA/errors (default 0)
#' @return Numeric vector
#'
safe_numeric <- function(x, default = NA_real_) {
  result <- suppressWarnings(as.numeric(x))
  result[is.na(result)] <- default
  result
}

#' Format numbers for display
#' 
#' @param x Numeric vector
#' @param digits Decimal places
#' @return Character vector
#'
fmt_num <- function(x, digits = 1) {
  format(round(x, digits), big.mark = ",", nsmall = digits)
}

#' Format percentages for display
#' 
#' @param x Numeric vector (0-100 scale)
#' @param digits Decimal places
#' @return Character vector
#'
fmt_pct <- function(x, digits = 1) {
  paste0(format(round(x, digits), nsmall = digits), "%")
}

#' Calculate year-over-year change
#' 
#' @param df Data frame with year and value columns
#' @param year_col Name of year column
#' @param value_col Name of value column
#' @return Data frame with yoy_change and yoy_pct columns added
#'
add_yoy_change <- function(df, year_col = "year", value_col = "value") {
  df |>
    arrange(.data[[year_col]]) |>
    mutate(
      yoy_change = .data[[value_col]] - lag(.data[[value_col]]),
      yoy_pct = yoy_change / lag(.data[[value_col]]) * 100
    )
}

#' Summary statistics for a numeric column by group
#' 
#' @param df Data frame
#' @param group_col Grouping column name
#' @param value_col Numeric column to summarize
#' @return Summary tibble
#'
summarize_by_group <- function(df, group_col, value_col) {
  df |>
    group_by(.data[[group_col]]) |>
    summarise(
      n = n(),
      mean = mean(.data[[value_col]], na.rm = TRUE),
      median = median(.data[[value_col]], na.rm = TRUE),
      sd = sd(.data[[value_col]], na.rm = TRUE),
      min = min(.data[[value_col]], na.rm = TRUE),
      max = max(.data[[value_col]], na.rm = TRUE),
      .groups = "drop"
    )
}

#' Create a summary table for reports
#' 
#' @param df Data frame
#' @param caption Table caption
#' @return kable object
#'
make_table <- function(df, caption = NULL) {
  knitr::kable(df, caption = caption, format = "html") |>
    kableExtra::kable_styling(
      bootstrap_options = c("striped", "hover", "condensed"),
      full_width = FALSE
    )
}

#' Save ggplot with consistent sizing
#' 
#' @param plot ggplot object
#' @param filename Output filename (in OUTPUT_DIR)
#' @param width Width in inches
#' @param height Height in inches
#' @param dpi Resolution
#'
save_plot <- function(plot, filename, width = 8, height = 6, dpi = 300) {
  path <- file.path(OUTPUT_DIR, filename)
  ggsave(path, plot, width = width, height = height, dpi = dpi)
  message(sprintf("Saved: %s", path))
}

#' Quick data quality check
#' 
#' @param df Data frame to check
#' @return Prints summary and returns invisibly
#'
data_quality_check <- function(df) {
  cat("=== Data Quality Check ===\n\n")
  cat(sprintf("Rows: %s\n", format(nrow(df), big.mark = ",")))
  cat(sprintf("Columns: %d\n\n", ncol(df)))
  
  # Missing values
  missing <- df |>
    summarise(across(everything(), ~sum(is.na(.)))) |>
    pivot_longer(everything(), names_to = "column", values_to = "missing") |>
    filter(missing > 0) |>
    mutate(pct_missing = missing / nrow(df) * 100) |>
    arrange(desc(pct_missing))
  
  if (nrow(missing) > 0) {
    cat("Columns with missing values:\n")
    print(missing, n = 20)
  } else {
    cat("No missing values!\n")
  }
  
  invisible(df)
}

#' Color palette for NYC boroughs
#' 
#' @return Named vector of colors
#'
borough_colors <- function() {
  c(
    "Manhattan" = "#1f77b4",
    "Bronx" = "#ff7f0e",
    "Brooklyn" = "#2ca02c",
    "Queens" = "#d62728",
    "Staten Island" = "#9467bd"
  )
}

#' Apply borough colors to ggplot
#' 
#' @return scale_color_manual layer
#'
scale_color_borough <- function() {
  scale_color_manual(values = borough_colors(), name = "Borough")
}

#' Apply borough fill to ggplot
#' 
#' @return scale_fill_manual layer
#'
scale_fill_borough <- function() {
  scale_fill_manual(values = borough_colors(), name = "Borough")
}

message("✓ Utility functions loaded.")
