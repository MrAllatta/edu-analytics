# ============================================================
# test_infohub.R - Unit tests for InfoHub data module
# ============================================================

library(testthat)
library(here)

# Setup: source the module
source(here::here("src/R/setup.R"))

# Define paths for testing
test_fixture_dir <- here::here("tests/fixtures")
test_file <- file.path(test_fixture_dir, "attendance_test.xlsx")

# ============================================================
# Test: INFOHUB_DATA registry structure
# ============================================================

test_that("INFOHUB_DATA has expected categories", {
  expect_true(exists("INFOHUB_DATA"))
  expect_type(INFOHUB_DATA, "list")
  
  expected_categories <- c("attendance", "enrollment", "test_results", "demographic_snapshot")
  for (cat in expected_categories) {
    expect_true(cat %in% names(INFOHUB_DATA))
  }
})

test_that("Each INFOHUB_DATA entry has pattern and sheets", {
  for (cat in names(INFOHUB_DATA)) {
    entry <- INFOHUB_DATA[[cat]]
    expect_true("pattern" %in% names(entry))
    expect_true("sheets" %in% names(entry))
    expect_type(entry$pattern, "character")
    expect_type(entry$sheets, "character")
  }
})

# ============================================================
# Test: read_infohub_sheet function
# ============================================================

test_that("read_infohub_sheet returns tibble with source column", {
  skip_if_not(file.exists(test_file))
  
  df <- read_infohub_sheet(test_file, sheet = "All Students")
  
  expect_true("source" %in% names(df))
  expect_equal(df$source[1], "infohub")
  expect_true(inherits(df, "tbl_df"))
})

test_that("read_infohub_sheet cleans column names", {
  skip_if_not(file.exists(test_file))
  
  df <- read_infohub_sheet(test_file, sheet = "All Students")
  
  # Expect snake_case from janitor::clean_names
  expect_true(all(names(df) == tolower(names(df))))
  expect_false(any(grepl(" ", names(df))))
})

# ============================================================
# Test: read_infohub_file function
# ============================================================

test_that("read_infohub_file returns combined tibble with subgroup column", {
  skip_if_not(file.exists(test_file))
  
  sheets <- c(
    "All Students" = "All Students",
    "SWD" = "Students with Disabilities"
  )
  
  df <- read_infohub_file(test_file, "attendance", sheets = sheets)
  
  expect_true("subgroup" %in% names(df))
  expect_true("source" %in% names(df))
  expect_true(nrow(df) > 0)
  expect_equal(length(unique(df$subgroup)), 2)
  expect_true("All Students" %in% df$subgroup)
  expect_true("SWD" %in% df$subgroup)
})

test_that("read_infohub_file handles missing sheets gracefully", {
  skip_if_not(file.exists(test_file))
  
  sheets <- c(
    "All Students" = "All Students",
    "NonExistent" = "Does Not Exist"
  )
  
  expect_warning({
    df <- read_infohub_file(test_file, "attendance", sheets = sheets)
  })
  
  # Should still return data from the valid sheet
  expect_true(nrow(df) > 0)
  expect_true("All Students" %in% df$subgroup)
})

# ============================================================
# Test: list_infohub function
# ============================================================

test_that("list_infohub returns empty tibble when directory is empty", {
  empty_dir <- tempdir()
  
  result <- list_infohub(raw_dir = empty_dir)
  
  expect_true(inherits(result, "tbl_df"))
  expect_equal(nrow(result), 0)
  expect_true("category" %in% names(result))
  expect_true("file_name" %in% names(result))
})

test_that("list_infohub detects test fixture file", {
  result <- list_infohub(raw_dir = test_fixture_dir)
  
  expect_true(nrow(result) > 0)
  expect_true("attendance_test.xlsx" %in% result$file_name)
  expect_true("attendance" %in% result$category)
})

# ============================================================
# Test: load_infohub cache functionality
# ============================================================

test_that("load_infohub uses cache when available", {
  skip_if_not(file.exists(test_file))
  
  # Clear any existing cache
  cache_file <- file.path(DATA_DIR, "attendance_infohub.parquet")
  if (file.exists(cache_file)) {
    file.remove(cache_file)
  }
  
  # First load: no cache
  df1 <- load_infohub("attendance", raw_dir = test_fixture_dir, use_cache = FALSE)
  
  # Check cache was created
  expect_true(file.exists(cache_file))
  
  # Second load: should use cache
  expect_message({
    df2 <- load_infohub("attendance", raw_dir = test_fixture_dir, use_cache = TRUE)
  }, "Loading from cache")
  
  # Should be identical
  expect_equal(nrow(df1), nrow(df2))
  expect_equal(names(df1), names(df2))
})

test_that("load_infohub validates category", {
  expect_error({
    load_infohub("nonexistent_category")
  }, "Unknown category")
})

# ============================================================
# Test: load_education_data fallback
# ============================================================

test_that("load_education_data returns a tibble", {
  skip_if_not(file.exists(test_file))
  
  df <- load_education_data(
    "attendance",
    use_infohub = TRUE,
    use_api = FALSE
  )
  
  expect_true(inherits(df, "tbl_df"))
})

test_that("load_education_data prefers InfoHub when available", {
  skip_if_not(file.exists(test_file))
  
  expect_message({
    df <- load_education_data(
      "attendance",
      use_infohub = TRUE,
      use_api = FALSE
    )
  }, "Using InfoHub data")
})

# ============================================================
# Cleanup
# ============================================================

# Clean up cache after tests
on.exit({
  cache_file <- file.path(DATA_DIR, "attendance_infohub.parquet")
  if (file.exists(cache_file)) {
    file.remove(cache_file)
  }
})
