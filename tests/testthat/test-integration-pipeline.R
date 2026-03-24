# Integration tests: R-native bloodstream pipeline
#
# Tests the bloodstream() function directly with real ds004869 data.
# Gated by BLOODSTREAM_INTEGRATION_TESTS=true.

test_that("pipeline succeeds with interpolation config", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")

  expect_no_error(
    bloodstream(
      bids_dir = ws$bids_dir,
      configpath = config_path,
      derivatives_dir = ws$derivatives_dir,
      analysis_foldername = "Primary_Analysis"
    )
  )

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")

  expect_true(file.exists(file.path(analysis_path, "bloodstream_report.html")))
  expect_true(file.exists(file.path(analysis_path, "bloodstream_config.json")))
  expect_true(file.exists(file.path(analysis_path, "dataset_description.json")))

  # 2 subjects × 2 sessions = 4 measurements
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 4)

  inputfunction_jsons <- list.files(analysis_path, pattern = "_inputfunction\\.json$", recursive = TRUE)
  expect_equal(length(inputfunction_jsons), 4)

  aifraw_tsvs <- list.files(analysis_path, pattern = "_desc-aifraw_timeseries\\.tsv$", recursive = TRUE)
  expect_equal(length(aifraw_tsvs), 4)

  aifraw_jsons <- list.files(analysis_path, pattern = "_desc-aifraw_timeseries\\.json$", recursive = TRUE)
  expect_equal(length(aifraw_jsons), 4)
})

test_that("inputfunction TSV has expected columns", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")

  bloodstream(
    bids_dir = ws$bids_dir,
    configpath = config_path,
    derivatives_dir = ws$derivatives_dir
  )

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")
  tsv_files <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$",
                          recursive = TRUE, full.names = TRUE)
  expect_true(length(tsv_files) > 0)

  data <- read.delim(tsv_files[1], sep = "\t")
  expect_true(nrow(data) > 0)

  expected_cols <- c("time", "whole_blood_radioactivity", "plasma_radioactivity",
                     "metabolite_parent_fraction", "AIF")
  for (col in expected_cols) {
    expect_true(col %in% names(data),
                info = paste("Missing column in inputfunction TSV:", col))
  }
})

test_that("AIFraw TSV has expected columns", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")

  bloodstream(
    bids_dir = ws$bids_dir,
    configpath = config_path,
    derivatives_dir = ws$derivatives_dir
  )

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")
  tsv_files <- list.files(analysis_path, pattern = "_desc-aifraw_timeseries\\.tsv$",
                          recursive = TRUE, full.names = TRUE)
  expect_true(length(tsv_files) > 0)

  data <- read.delim(tsv_files[1], sep = "\t")
  expect_true(nrow(data) > 0)

  expected_cols <- c("time", "recording", "whole_blood_radioactivity",
                     "plasma_radioactivity", "blood_plasma_ratio",
                     "metabolite_parent_fraction", "AIF")
  for (col in expected_cols) {
    expect_true(col %in% names(data),
                info = paste("Missing column in AIFraw TSV:", col))
  }
})

test_that("pipeline succeeds with model fitting config", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_fitting_config.json")

  expect_no_error(
    bloodstream(
      bids_dir = ws$bids_dir,
      configpath = config_path,
      derivatives_dir = ws$derivatives_dir,
      analysis_foldername = "Primary_Analysis"
    )
  )

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")

  expect_true(file.exists(file.path(analysis_path, "bloodstream_report.html")))
  expect_true(file.exists(file.path(analysis_path, "bloodstream_config.json")))

  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 4)

  inputfunction_jsons <- list.files(analysis_path, pattern = "_inputfunction\\.json$", recursive = TRUE)
  expect_equal(length(inputfunction_jsons), 4)

  aifraw_tsvs <- list.files(analysis_path, pattern = "_desc-aifraw_timeseries\\.tsv$", recursive = TRUE)
  expect_equal(length(aifraw_tsvs), 4)

  aifraw_jsons <- list.files(analysis_path, pattern = "_desc-aifraw_timeseries\\.json$", recursive = TRUE)
  expect_equal(length(aifraw_jsons), 4)
})

test_that("pipeline succeeds with HGAM config", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_hgam_config.json")

  expect_no_error(
    bloodstream(
      bids_dir = ws$bids_dir,
      configpath = config_path,
      derivatives_dir = ws$derivatives_dir,
      analysis_foldername = "Primary_Analysis"
    )
  )

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")

  expect_true(file.exists(file.path(analysis_path, "bloodstream_report.html")))
  expect_true(file.exists(file.path(analysis_path, "bloodstream_config.json")))

  # 10 subjects × 2 sessions = 20 measurements
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 20)

  inputfunction_jsons <- list.files(analysis_path, pattern = "_inputfunction\\.json$", recursive = TRUE)
  expect_equal(length(inputfunction_jsons), 20)

  aifraw_tsvs <- list.files(analysis_path, pattern = "_desc-aifraw_timeseries\\.tsv$", recursive = TRUE)
  expect_equal(length(aifraw_tsvs), 20)

  aifraw_jsons <- list.files(analysis_path, pattern = "_desc-aifraw_timeseries\\.json$", recursive = TRUE)
  expect_equal(length(aifraw_jsons), 20)
})

test_that("custom analysis_foldername works", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")
  custom_folder <- "Custom_Test_Analysis"

  expect_no_error(
    bloodstream(
      bids_dir = ws$bids_dir,
      configpath = config_path,
      derivatives_dir = ws$derivatives_dir,
      analysis_foldername = custom_folder
    )
  )

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", custom_folder)
  expect_true(dir.exists(analysis_path))
  expect_true(file.exists(file.path(analysis_path, "bloodstream_report.html")))

  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 4)
})

test_that("fails gracefully with invalid bids_dir", {
  skip_if_no_integration()

  expect_error(
    bloodstream(bids_dir = "/nonexistent/path/to/bids"),
    "bids_dir"
  )
})

test_that("fails gracefully with invalid config", {
  skip_if_no_integration()

  dataset_dir <- ensure_testdata()

  expect_error(
    bloodstream(bids_dir = dataset_dir, configpath = "/nonexistent/config.json"),
    "Config file"
  )
})
