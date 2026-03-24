# Integration tests: Singularity/Apptainer container
#
# Tests the bloodstream container via Singularity/Apptainer with real ds004869 data.
# Gated by BLOODSTREAM_SINGULARITY_TESTS=true (also requires BLOODSTREAM_INTEGRATION_TESTS=true).
# No .def file needed — uses docker-daemon: reference for on-the-fly conversion.

test_that("Singularity: non-interactive mode with interpolation config", {
  skip_if_no_singularity()

  container <- find_singularity_container()
  if (is.null(container)) {
    skip("No Singularity container available")
  }

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")

  result <- run_bloodstream_singularity(ws, container = container,
                                         config_path = config_path)
  expect_equal(result$exit_code, 0L,
               info = paste("Singularity output:", paste(result$output, collapse = "\n")))

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 4)
})

test_that("Singularity: non-interactive mode with fitting config", {
  skip_if_no_singularity()

  container <- find_singularity_container()
  if (is.null(container)) {
    skip("No Singularity container available")
  }

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_fitting_config.json")

  result <- run_bloodstream_singularity(ws, container = container,
                                         config_path = config_path)
  expect_equal(result$exit_code, 0L,
               info = paste("Singularity output:", paste(result$output, collapse = "\n")))

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 4)
})

test_that("Singularity: non-interactive mode with HGAM config", {
  skip_if_no_singularity()

  container <- find_singularity_container()
  if (is.null(container)) {
    skip("No Singularity container available")
  }

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_hgam_config.json")

  result <- run_bloodstream_singularity(ws, container = container,
                                         config_path = config_path)
  expect_equal(result$exit_code, 0L,
               info = paste("Singularity output:", paste(result$output, collapse = "\n")))

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 20)
})

test_that("Singularity: custom analysis_foldername", {
  skip_if_no_singularity()

  container <- find_singularity_container()
  if (is.null(container)) {
    skip("No Singularity container available")
  }

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")
  custom_folder <- "Singularity_Test_Analysis"

  result <- run_bloodstream_singularity(ws, container = container,
                                         config_path = config_path,
                                         analysis_foldername = custom_folder)
  expect_equal(result$exit_code, 0L,
               info = paste("Singularity output:", paste(result$output, collapse = "\n")))

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", custom_folder)
  expect_true(dir.exists(analysis_path))
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 4)
})
