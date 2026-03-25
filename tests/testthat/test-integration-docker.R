# Integration tests: Docker container
#
# Tests the bloodstream Docker container with real ds004869 data.
# Gated by BLOODSTREAM_DOCKER_TESTS=true (also requires BLOODSTREAM_INTEGRATION_TESTS=true).

test_that("Docker: non-interactive mode with interpolation config", {
  skip_if_no_docker()
  ensure_docker_image()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")

  result <- run_bloodstream_docker(ws, config_path = config_path)
  expect_equal(result$exit_code, 0L,
               info = paste("Docker output:", paste(result$output, collapse = "\n")))

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 4)

  aifraw_tsvs <- list.files(analysis_path, pattern = "_desc-aifraw_timeseries\\.tsv$", recursive = TRUE)
  expect_equal(length(aifraw_tsvs), 4)
})

test_that("Docker: non-interactive mode with fitting config", {
  skip_if_no_docker()
  ensure_docker_image()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_fitting_config.json")

  result <- run_bloodstream_docker(ws, config_path = config_path)
  expect_equal(result$exit_code, 0L,
               info = paste("Docker output:", paste(result$output, collapse = "\n")))

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 4)
})

test_that("Docker: non-interactive mode with HGAM config", {
  skip_if_no_docker()
  ensure_docker_image()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_hgam_config.json")

  result <- run_bloodstream_docker(ws, config_path = config_path)
  expect_equal(result$exit_code, 0L,
               info = paste("Docker output:", paste(result$output, collapse = "\n")))

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", "Primary_Analysis")
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 20)
})

test_that("Docker: custom analysis_foldername", {
  skip_if_no_docker()
  ensure_docker_image()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")
  custom_folder <- "Docker_Test_Analysis"

  result <- run_bloodstream_docker(ws, config_path = config_path,
                                    analysis_foldername = custom_folder)
  expect_equal(result$exit_code, 0L,
               info = paste("Docker output:", paste(result$output, collapse = "\n")))

  analysis_path <- file.path(ws$derivatives_dir, "bloodstream", custom_folder)
  expect_true(dir.exists(analysis_path))
  inputfunction_tsvs <- list.files(analysis_path, pattern = "_inputfunction\\.tsv$", recursive = TRUE)
  expect_equal(length(inputfunction_tsvs), 4)
})

test_that("Docker: output contains expected log markers", {
  skip_if_no_docker()
  ensure_docker_image()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")

  result <- run_bloodstream_docker(ws, config_path = config_path)
  output_text <- paste(result$output, collapse = "\n")

  expect_true(grepl("bloodstream Docker Container", output_text, ignore.case = TRUE),
              info = "Missing 'bloodstream Docker Container' marker")
  expect_true(grepl("Non-Interactive Mode", output_text, ignore.case = TRUE),
              info = "Missing 'Non-Interactive Mode' marker")
  expect_true(grepl("pipeline completed successfully", output_text, ignore.case = TRUE),
              info = "Missing 'pipeline completed successfully' marker")
})

test_that("Docker: non-interactive mode fails with helpful message when derivatives_dir is not writable", {
  skip_if_no_docker()
  ensure_docker_image()

  dataset_dir <- ensure_testdata()
  ws <- create_integration_workspace(dataset_dir)
  on.exit(cleanup_workspace(ws))

  # Create a root-owned directory to simulate what Docker does when the host

  # path doesn't exist: it creates the mount point owned by root, which is
  # unwritable when --user is passed.
  unwritable_dir <- file.path(ws$workspace, "unwritable_derivatives")
  dir.create(unwritable_dir, recursive = TRUE)
  Sys.chmod(unwritable_dir, mode = "0555")

  config_path <- get_config_fixture("ds004869_bloodstream_interpolation_config.json")

  docker_args <- c(
    "run", "--rm",
    "--user", paste0(as.integer(system("id -u", intern = TRUE)), ":",
                     as.integer(system("id -g", intern = TRUE))),
    "-v", paste0(ws$bids_dir, ":/data/bids_dir:ro"),
    "-v", paste0(unwritable_dir, ":/data/derivatives_dir:rw"),
    "-v", paste0(normalizePath(config_path), ":/config.json:ro"),
    DOCKER_IMAGE
  )

  result <- suppressWarnings(
    system2("docker", docker_args, stdout = TRUE, stderr = TRUE)
  )
  exit_code <- attr(result, "status") %||% 0L

  expect_true(exit_code != 0L,
              info = "Expected non-zero exit code with unwritable derivatives_dir")

  output_text <- paste(result, collapse = "\n")
  expect_true(grepl("not writable", output_text),
              info = "Error should mention the directory is not writable")
  expect_true(grepl("mkdir -p", output_text),
              info = "Error should include mkdir instruction for the user")

  # Restore permissions for cleanup
  Sys.chmod(unwritable_dir, mode = "0755")
})

test_that("Docker: fails without bids_dir mount", {
  skip_if_no_docker()
  ensure_docker_image()

  # Run with no bids_dir - only derivatives
  ws_dir <- tempfile(pattern = "bloodstream_docker_fail_")
  dir.create(ws_dir, recursive = TRUE)
  on.exit(unlink(ws_dir, recursive = TRUE))

  deriv_dir <- file.path(ws_dir, "derivatives")
  dir.create(deriv_dir)

  docker_args <- c(
    "run", "--rm",
    "--user", paste0(as.integer(system("id -u", intern = TRUE)), ":",
                     as.integer(system("id -g", intern = TRUE))),
    "-v", paste0(deriv_dir, ":/data/derivatives_dir:rw"),
    DOCKER_IMAGE
  )

  result <- suppressWarnings(
    system2("docker", docker_args, stdout = TRUE, stderr = TRUE)
  )
  exit_code <- attr(result, "status") %||% 0L

  expect_true(exit_code != 0L,
              info = "Expected non-zero exit code without bids_dir mount")
})
