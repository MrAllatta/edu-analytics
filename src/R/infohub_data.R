  # Row-bind all sheets
  result <- dplyr::bind_rows(dfs)

  message(sprintf("Loaded %d rows from %d sheets", nrow(result), length(dfs)))

  return(result)
}

#' Load InfoHub data with caching
#'
#' Top-level function that reads a category from data/raw/,
#' caches to parquet, and returns tibble. Cache-first pattern.
#'
#' @param category Category name (e.g., "attendance", "enrollment")
#' @param raw_dir Directory containing downloaded Excel files (default: data/raw)
#' @param use_cache If FALSE, re-read from Excel and overwrite cache
#'
#' @return tibble with InfoHub data
#'
load_infohub <- function(category, raw_dir = NULL, use_cache = TRUE) {

  # Use global DATA_DIR if raw_dir not specified
  if (is.null(raw_dir)) {
    raw_dir <- file.path(DATA_DIR, "raw")
  }

  # Validate category
  if (!category %in% names(INFOHUB_DATA)) {
    available <- paste(names(INFOHUB_DATA), collapse = ", ")
    stop(sprintf(
      "Unknown category '%s'. Available: %s",
      category,
      available
    ))
  }

  meta <- INFOHUB_DATA[[category]]

  # Check cache first
  cache_path <- file.path(DATA_DIR, sprintf("%s_infohub.parquet", category))
  if (use_cache && file.exists(cache_path)) {
    message(sprintf("Loading from cache: %s", cache_path))
    return(arrow::read_parquet(cache_path))
  }

  # Find file in raw directory
  pattern <- sprintf("^%s.*\\.xlsx$", meta$pattern)
  files <- list.files(
    raw_dir,
    pattern = pattern,
    ignore.case = TRUE,
    full.names = TRUE
  )

  if (length(files) == 0) {
    stop(sprintf(
      "No Excel file found for category '%s' in %s\n  Expected pattern: %s",
      category,
      raw_dir,
      pattern
    ))
  }

  if (length(files) > 1) {
    warning(sprintf("Found %d matching files; using first: %s", length(files), files[1]))
  }

  file_path <- files[1]

  # Read and process file
  df <- read_infohub_file(
    file_path,
    category_name = category,
    sheets = meta$sheets
  )

  # Cache to parquet
  arrow::write_parquet(df, cache_path)
  message(sprintf("Cached to: %s", cache_path))

  return(df)
}

#' List available InfoHub files in data/raw/
#'
#' Scans data/raw/ directory for Excel files matching registered categories.
#'
#' @param raw_dir Directory to scan (default: data/raw)
#'
#' @return tibble with file info (category, file_name, path, size_kb)
#'
list_infohub <- function(raw_dir = NULL) {

  if (is.null(raw_dir)) {
    raw_dir <- file.path(DATA_DIR, "raw")
  }

  if (!dir.exists(raw_dir)) {
    message(sprintf("Directory not found: %s", raw_dir))
    return(tibble::tibble(
      category = character(),
      file_name = character(),
      path = character(),
      size_kb = numeric()
    ))
  }

  # Find all Excel files
  files <- list.files(
    raw_dir,
    pattern = "\\.xlsx$",
    ignore.case = TRUE,
    full.names = TRUE
  )

  if (length(files) == 0) {
    message(sprintf("No Excel files found in %s", raw_dir))
    return(tibble::tibble(
      category = character(),
      file_name = character(),
      path = character(),
      size_kb = numeric()
    ))
  }

  # Match files to categories
  results <- list()
  for (file_path in files) {
    file_name <- basename(file_path)
    size_kb <- round(file.size(file_path) / 1024, 2)

    # Try to match to a category
    category <- NA_character_
    for (cat in names(INFOHUB_DATA)) {
      if (grepl(INFOHUB_DATA[[cat]]$pattern, file_name, ignore.case = TRUE)) {
        category <- cat
        break
      }
    }

    results[[file_path]] <- tibble::tibble(
      category = category,
      file_name = file_name,
      path = file_path,
      size_kb = size_kb
    )
  }

  df <- dplyr::bind_rows(results)

  # Show summary
  n_matched <- sum(!is.na(df$category))
  n_total <- nrow(df)
  message(sprintf(
    "Found %d Excel file%s in %s (%d matched to categories)",
    n_total,
    if (n_total != 1) "s" else "",
    raw_dir,
    n_matched
  ))

  return(df)
}

## ==========================================================
## UNIFIED ACCESSOR - Fallback to API
## ==========================================================

#' Load education data with InfoHub priority, API fallback
#'
#' Attempts to load from InfoHub cache first, then API.
#' Useful for metrics available in both sources.
#'
#' @param category Category name (e.g., "attendance", "enrollment")
#' @param use_infohub If TRUE, prefer InfoHub (default: TRUE)
#' @param use_api If TRUE, use API as fallback (default: TRUE)
#' @param ... Additional arguments passed to fetch_dataset()
#'
#' @return tibble with requested data
#'
load_education_data <- function(category,
                                 use_infohub = TRUE,
                                 use_api = TRUE,
                                 ...) {

  # Try InfoHub first
  if (use_infohub && category %in% names(INFOHUB_DATA)) {
    tryCatch({
      df <- load_infohub(category, use_cache = TRUE)
      message(sprintf("Using InfoHub data for %s", category))
      return(df)
    }, error = function(e) {
      warning(sprintf("InfoHub load failed: %s", conditionMessage(e)))
    })
  }

  # Fall back to API
  if (use_api && category %in% names(NYC_DATA)) {
    message(sprintf("Falling back to API for %s", category))
    return(fetch_dataset(NYC_DATA[[category]], ...))
  }

  stop(sprintf(
    "Data source '%s' not found in InfoHub or NYC_DATA",
    category
  ))
}

message("✓ NYC InfoHub data module loaded.")
message("  Use list_infohub() to see available Excel files.")
message("  Use load_infohub('<category>') to load and cache data.")