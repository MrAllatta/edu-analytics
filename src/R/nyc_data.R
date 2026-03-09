## ============================================================
## nyc_data.R - NYC Open Data Education Dataset Library
## 
## Curated collection of education-focused datasets from
## https://data.cityofnewyork.us
##
## All dataset IDs are for the Socrata SODA API
## Format: https://data.cityofnewyork.us/resource/{id}.json
## ============================================================

## ==========================================================
## NYC OPEN DATA - EDUCATION DATASET REGISTRY
## ==========================================================

NYC_DATA <- list(
  
  ## --------------------------------------------------------
  ## SCHOOLS - Buildings, Locations, Facilities
  ## --------------------------------------------------------
  
  # 2019-2020 DOE School Directory
  # Comprehensive list of all NYC public schools

  school_directory = "8b6c-7uty",
  
  # DOE Building Space Usage
  # Annual space utilization in school buildings
  building_space_usage = "wavz-fkw8",

  # School Point Locations
  # Geographic coordinates for all schools
  school_locations = "jfju-ynrr",
  
  # DOE High School Directory
  # Detailed info on high schools
  hs_directory = "uq7m-95z8",
  
  # Universal Pre-K Directory
  # Pre-K program locations
  upk_directory = "kiyv-ks3f",
  
  ## --------------------------------------------------------
  ## STUDENTS - Enrollment, Demographics, Attendance
  ## --------------------------------------------------------
  
  # Demographic Snapshot - School Level
  # Student demographics by school
  demographic_snapshot = "s52a-8aq6",
  
  # Enrollment - School Level
  # Student enrollment counts by school and grade
  enrollment = "7z8d-msnt",
  
  # Attendance and Chronic Absenteeism
  # School-level attendance rates
  attendance = "hrwk-wb2d",
  
  # Students with Disabilities
  # Special education enrollment
  swd_enrollment = "47xe-dv98",
  
  # English Language Learners
  # ELL student counts by school
  ell_enrollment = "72bx-k62e",
  
  # Free/Reduced Lunch

  # Poverty indicator data
  free_lunch = "5vpy-c8t4",
  
  ## --------------------------------------------------------
  ## LEARNING - Test Scores, Graduation, Academic Progress
  ## --------------------------------------------------------
  
  # Math Test Results (Grades 3-8)
  # NY State Math Assessment results
  math_test_results = "74kb-55u9",
  
  # ELA Test Results (Grades 3-8)
  # NY State ELA Assessment results
  ela_test_results = "qkpp-pbi8",
  
  # Graduation Outcomes - School Level
  # 4-year and 6-year graduation rates
  graduation_outcomes = "bn5q-ia5v",
  
  # Regents Exam Results
  # NY State Regents exam pass rates
  regents_results = "2hcd-bsun",
  
  # SAT Results
  # College Board SAT scores by school
  sat_results = "f9bf-2cp4",
  
  # AP Exam Results
  # Advanced Placement exam results
  ap_results = "itfs-ms3e",
  
  # College Enrollment Rates
  # Post-secondary enrollment by school
  college_enrollment = "6j6k-8s4t",
  
  ## --------------------------------------------------------
  ## SUPPLEMENTARY - Programs, Resources
  ## --------------------------------------------------------
  
  # Class Size Report
  # Average class sizes by school
  class_size = "urz7-pzb3",
  
  # School Quality Reports
  # Annual school performance reports
  quality_reports = "dnpx-dfnc",
  
  # After School Programs
  # DYCD after-school program locations
  after_school = "6ej9-7qyi",
  
  # Summer Programs
  # Summer Rising program sites
  summer_programs = "rtk9-67un"
)


## ============================================================
## OPEN DATA URL GENERATION FUNCTIONS
## ============================================================

#' Generate Open Data Share Link
#' 
#' @param dataset_id Socrata dataset identifier
#' @return URL string for sharing dataset  
#'

generate_share_link <- function(dataset_id) {
  sprintf("https://data.cityofnewyork.us/d/%s", dataset_id)
}


## ==========================================================
## DATA FETCHING FUNCTIONS
## ==========================================================

#' Fetch dataset from NYC Open Data
#' 
#' @param dataset_id Socrata dataset identifier (e.g., "wg9x-4ke6")
#' @param limit Maximum rows to fetch (default 50000)
#' @param offset Starting row for pagination
#' @param cache_name Optional name for local parquet cache
#' @param use_cache Whether to use cached data if available
#' @param ... Additional query parameters (where, select, etc.)
#' @return tibble with dataset
#' 
fetch_dataset <- function(dataset_id, 
                          limit = 50000, 
                          offset = 0,
                          cache_name = NULL,
                          use_cache = TRUE,
                          ...) {
  
  # Check cache first
  if (!is.null(cache_name) && use_cache) {
    cache_path <- file.path(DATA_DIR, paste0(cache_name, ".parquet"))
    if (file.exists(cache_path)) {
      message(sprintf("Loading from cache: %s", cache_path))
      return(arrow::read_parquet(cache_path))
    }
  }
  
  # Build API URL
  base_url <- sprintf(
    "https://data.cityofnewyork.us/resource/%s.json",
    dataset_id
  )
  
  # Query parameters
  params <- list(
    `$limit` = limit,
    `$offset` = offset,
    ...
  )
  
  message(sprintf("Fetching dataset: %s (limit=%d)", dataset_id, limit))
  
  # Make request
  response <- httr::GET(
    url = base_url,
    query = params,
    httr::add_headers(Accept = "application/json", `X-App-Token` = Sys.getenv("EDU_ANALYTICS_APP_TOKEN"))
  )
  
  # Check for errors
  if (httr::http_error(response)) {
    stop(sprintf(
      "API request failed [%s]: %s",
      httr::status_code(response),
      httr::content(response, "text")
    ))
  }
  
  # Parse JSON
  content <- httr::content(response, "text", encoding = "UTF-8")
  data <- jsonlite::fromJSON(content, flatten = TRUE)
  
  # Convert to tibble
  df <- tibble::as_tibble(data)
  
  message(sprintf("Retrieved %d rows", nrow(df)))
  
  # Cache if requested
  if (!is.null(cache_name)) {
    cache_path <- file.path(DATA_DIR, paste0(cache_name, ".parquet"))
    arrow::write_parquet(df, cache_path)
    message(sprintf("Cached to: %s", cache_path))
  }
  
  return(df)
}

#' Fetch large dataset with pagination
#' 
#' @param dataset_id Socrata dataset identifier
#' @param batch_size Rows per API call (max 50000 for SODA 2.1)
#' @param max_rows Maximum total rows to fetch (NULL for all)
#' @param cache_name Optional cache name
#' @return tibble with complete dataset
#'
fetch_large_dataset <- function(dataset_id,
                                 batch_size = 50000,
                                 max_rows = NULL,
                                 cache_name = NULL) {
  
  # Check cache
  if (!is.null(cache_name)) {
    cache_path <- file.path(DATA_DIR, paste0(cache_name, ".parquet"))
    if (file.exists(cache_path)) {
      message(sprintf("Loading from cache: %s", cache_path))
      return(arrow::read_parquet(cache_path))
    }
  }
  
  all_data <- list()
  offset <- 0
  batch_num <- 1
  
  repeat {
    message(sprintf("Fetching batch %d (offset %d)...", batch_num, offset))
    
    batch <- fetch_dataset(
      dataset_id,
      limit = batch_size,
      offset = offset,
      cache_name = NULL,  # Don't cache batches
      use_cache = FALSE
    )
    
    if (nrow(batch) == 0) break
    
    all_data[[batch_num]] <- batch
    offset <- offset + batch_size
    batch_num <- batch_num + 1
    
    # Check max rows limit
    total_rows <- sum(sapply(all_data, nrow))
    if (!is.null(max_rows) && total_rows >= max_rows) {
      message(sprintf("Reached max_rows limit: %d", max_rows))
      break
    }
    
    # Small delay to be nice to API
    Sys.sleep(0.5)
  }
  
  # Combine all batches
  df <- bind_rows(all_data)
  message(sprintf("Total rows retrieved: %d", nrow(df)))
  
  # Cache complete dataset
  if (!is.null(cache_name)) {
    cache_path <- file.path(DATA_DIR, paste0(cache_name, ".parquet"))
    arrow::write_parquet(df, cache_path)
    message(sprintf("Cached to: %s", cache_path))
  }
  
  return(df)
}

#' Get dataset metadata
#' 
#' @param dataset_id Socrata dataset identifier
#' @return list with metadata (name, description, row count, etc.)
#'
get_dataset_info <- function(dataset_id) {
  url <- sprintf(
    "https://data.cityofnewyork.us/api/views/%s.json",
    dataset_id
  )
  
  response <- httr::GET(url)
  
  if (httr::http_error(response)) {
    stop("Failed to fetch dataset metadata")
  }
  
  content <- httr::content(response, "parsed")
  
  list(
    id = content$id,
    name = content$name,
    description = content$description,
    rows = content$rowsUpdatedAt,
    columns = length(content$columns),
    last_updated = as.POSIXct(content$rowsUpdatedAt, origin = "1970-01-01")
  )
}

#' Report all NYC Open Data sources
#' 
#' Generates a formatted report of all datasets in NYC_DATA by calling 
#' get_dataset_info() on each, organized by category with metadata.
#' 
#' @return Prints report to stdout, returns invisibly
#'
report_data_sources <- function() {
  cat("\n")
  cat("=== NYC OPEN DATA SOURCES REPORT ===\n")
  cat("Total datasets: ", length(NYC_DATA), "\n\n")
  
  # Get all datasets and their info
  datasets_df <- list_datasets()
  
  # Process by category
  categories <- unique(datasets_df$category)
  
  for (cat in categories) {
    cat_datasets <- datasets_df |>
      filter(category == cat) |>
      arrange(name)
    
    cat("\n", strrep("─", 60), "\n")
    cat(sprintf("▸ %s (%d datasets)\n", cat, nrow(cat_datasets)))
    cat(strrep("─", 60), "\n\n")
    
    # Get info for each dataset in category
    for (i in seq_len(nrow(cat_datasets))) {
      row <- cat_datasets[i, ]
      dataset_id <- row$dataset_id
      
      # Safely get dataset info
      info <- tryCatch(
        get_dataset_info(NYC_DATA[[row$name]]),
        error = function(e) NULL
      )
      
      cat(sprintf("  %s\n", row$name))
      cat(sprintf("  ID: %s\n", dataset_id))
      cat(sprintf("  Columns: %d\n", if (!is.null(info)) info$columns else 0))
      if (!is.null(info) && !is.na(info$last_updated)) {
        cat(sprintf("  Last Updated: %s\n", info$last_updated))
      }
      cat(sprintf("  Link: https://data.cityofnewyork.us/d/%s\n", dataset_id))
      cat("\n")
    }
  }
  
  cat(strrep("─", 60), "\n")
  cat("End of report\n\n")
  
  invisible(NULL)
}

#' Clear cached data
#' 
#' @param cache_name Name of cache to clear, or "all" for everything
#'
clear_cache <- function(cache_name = "all") {
  if (cache_name == "all") {
    files <- list.files(DATA_DIR, pattern = "\\.parquet$", full.names = TRUE)
    if (length(files) > 0) {
      file.remove(files)
      message(sprintf("Removed %d cached files", length(files)))
    }
  } else {
    cache_path <- file.path(DATA_DIR, paste0(cache_name, ".parquet"))
    if (file.exists(cache_path)) {
      file.remove(cache_path)
      message(sprintf("Removed: %s", cache_path))
    }
  }
}

#' List all available datasets with descriptions
#' 
#' @return tibble with dataset names and IDs
#'
list_datasets <- function() {
  datasets <- tibble::tibble(
    category = c(
      rep("Schools", 5),
      rep("Students", 6),
      rep("Learning", 7),
      rep("Supplementary", 4)
    ),
    name = names(NYC_DATA),
    dataset_id = unlist(NYC_DATA),
    description = c(
      # Schools
      "DOE School Directory (2019-2020)",
      "Building Space Usage (annual)",
      "School Geographic Coordinates",
      "High School Directory",
      "Universal Pre-K Directory",
      # Students
      "Demographic Snapshot by School",
      "Enrollment by School/Grade",
      "Attendance & Chronic Absenteeism",
      "Students with Disabilities",
      "English Language Learners",
      "Free/Reduced Lunch Eligibility",
      # Learning
      "Math Test Results (Gr. 3-8)",
      "ELA Test Results (Gr. 3-8)",
      "Graduation Outcomes",
      "Regents Exam Results",
      "SAT Results by School",
      "AP Exam Results",
      "College Enrollment Rates",
      # Supplementary
      "Class Size Report",
      "School Quality Reports",
      "After School Programs",
      "Summer Programs"
    )
  )
  
  return(datasets)
}

## ==========================================================
## Print available datasets on source
## ==========================================================
message("✓ NYC Open Data library loaded.")
message("  Use list_datasets() to see available datasets.")
message("  Use fetch_dataset(NYC_DATA$<name>) to load data.")
