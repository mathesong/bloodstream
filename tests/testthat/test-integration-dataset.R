# Integration tests: Validate test data (ds004869)
#
# These tests verify that the test dataset is correctly extracted and has
# the expected structure for bloodstream processing.

test_that("test data extracts successfully", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()

  expect_true(dir.exists(dataset_dir))
  expect_true(file.exists(file.path(dataset_dir, "participants.tsv")))
  expect_true(file.exists(file.path(dataset_dir, "dataset_description.json")))
})

test_that("test data contains 54 blood TSV files", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()

  blood_files <- list.files(dataset_dir, pattern = "_blood\\.tsv$", recursive = TRUE)
  expect_equal(length(blood_files), 54)
})

test_that("blood TSV files are parseable with expected columns", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()

  blood_files <- list.files(dataset_dir, pattern = "_blood\\.tsv$",
                            recursive = TRUE, full.names = TRUE)
  expect_true(length(blood_files) > 0)

  # Check the first file
  blood_data <- read.delim(blood_files[1], sep = "\t")
  expect_true(nrow(blood_data) > 0)

  expected_cols <- c("time", "plasma_radioactivity",
                     "metabolite_parent_fraction", "whole_blood_radioactivity")
  for (col in expected_cols) {
    expect_true(col %in% names(blood_data),
                info = paste("Missing column:", col))
  }
})

test_that("blood JSON sidecars are valid JSON", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()

  json_files <- list.files(dataset_dir, pattern = "_blood\\.json$",
                           recursive = TRUE, full.names = TRUE)
  expect_true(length(json_files) > 0)

  # Check a sample of JSON files
  for (jf in head(json_files, 5)) {
    parsed <- jsonlite::fromJSON(jf)
    expect_true(is.list(parsed), info = paste("Invalid JSON:", jf))
  }
})

test_that("subject/session structure matches expectations", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()

  # sub-01 should have ses-baseline and ses-blocked
  sub01_dir <- file.path(dataset_dir, "sub-01")
  expect_true(dir.exists(sub01_dir))
  expect_true(dir.exists(file.path(sub01_dir, "ses-baseline")))
  expect_true(dir.exists(file.path(sub01_dir, "ses-blocked")))
})

test_that("workspace creation and cleanup works", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)

  expect_true(dir.exists(ws$workspace))
  expect_true(dir.exists(ws$derivatives_dir))
  expect_equal(ws$bids_dir, dataset_dir)

  cleanup_workspace(ws)
  expect_false(dir.exists(ws$workspace))
})
