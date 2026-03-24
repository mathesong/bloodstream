# Integration test helpers for bloodstream
#
# Provides dataset management, workspace isolation, and skip functions
# for integration tests using real OpenNeuro data (ds004869).
#
# Integration tests are disabled by default. Enable with environment variables:
#   BLOODSTREAM_INTEGRATION_TESTS=true  -- R-native integration tests
#   BLOODSTREAM_DOCKER_TESTS=true       -- Docker container tests
#   BLOODSTREAM_SINGULARITY_TESTS=true  -- Apptainer/Singularity tests
#
# Test data source (in priority order):
#   1. BLOODSTREAM_TESTDATA_PATH env var (explicit path to .tar.gz)
#   2. Local file: tests/testthat/fixtures/integration/ds004869_testdata.tar.gz
#   3. GitHub Release download (R-native HTTP, then gh CLI fallback)

# Constants
DOCKER_IMAGE <- "mathesong/bloodstream:latest"
BLOODSTREAM_GH_REPO <- "mathesong/petfit"
BLOODSTREAM_TESTDATA_RELEASE_TAG <- "testdata-v1.0"
BLOODSTREAM_TESTDATA_FILENAME <- "ds004869_testdata.tar.gz"

# ---------------------------------------------------------------------------
# Skip functions
# ---------------------------------------------------------------------------

#' Skip test if integration tests are not enabled
skip_if_no_integration <- function() {
  testthat::skip_if(
    Sys.getenv("BLOODSTREAM_INTEGRATION_TESTS") == "",
    "Integration tests disabled. Set BLOODSTREAM_INTEGRATION_TESTS=true to enable."
  )
}

#' Skip test if Docker tests are not enabled or Docker is not available
skip_if_no_docker <- function() {
  skip_if_no_integration()
  testthat::skip_if(
    Sys.getenv("BLOODSTREAM_DOCKER_TESTS") == "",
    "Docker tests disabled. Set BLOODSTREAM_DOCKER_TESTS=true to enable."
  )
  testthat::skip_if_not(
    nchar(Sys.which("docker")) > 0,
    "Docker not available on this system"
  )
}

#' Skip test if Singularity/Apptainer tests are not enabled or not available
skip_if_no_singularity <- function() {
  skip_if_no_integration()
  testthat::skip_if(
    Sys.getenv("BLOODSTREAM_SINGULARITY_TESTS") == "",
    "Singularity tests disabled. Set BLOODSTREAM_SINGULARITY_TESTS=true to enable."
  )
  testthat::skip_if_not(
    nchar(Sys.which("singularity")) > 0 || nchar(Sys.which("apptainer")) > 0,
    "Singularity/Apptainer not available on this system"
  )
}

# ---------------------------------------------------------------------------
# Test data management
# ---------------------------------------------------------------------------

#' Get the integration cache directory
get_integration_cache_dir <- function() {
  cache_dir <- Sys.getenv("BLOODSTREAM_INTEGRATION_CACHE", unset = "")
  if (cache_dir == "") {
    cache_dir <- file.path(tempdir(), "bloodstream_integration")
  }
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  cache_dir
}

#' Find the test data tarball
#'
#' Searches in priority order:
#' 1. BLOODSTREAM_TESTDATA_PATH env var
#' 2. Local fixtures directory
#' 3. GitHub Release download from mathesong/petfit testdata-v1.0
find_testdata_tarball <- function() {
  # Priority 1: Explicit path from env var
  explicit_path <- Sys.getenv("BLOODSTREAM_TESTDATA_PATH", unset = "")
  if (explicit_path != "" && file.exists(explicit_path)) {
    return(explicit_path)
  }

  # Priority 2: Local file in fixtures
  local_path <- testthat::test_path("fixtures", "integration", BLOODSTREAM_TESTDATA_FILENAME)
  if (file.exists(local_path)) {
    return(local_path)
  }

  # Priority 3: Download from GitHub Release (fallback)
  cache_dir <- get_integration_cache_dir()
  cached_tarball <- file.path(cache_dir, BLOODSTREAM_TESTDATA_FILENAME)

  if (file.exists(cached_tarball)) {
    return(cached_tarball)
  }

  # 3a: R-native HTTP download
  download_url <- sprintf(
    "https://github.com/%s/releases/download/%s/%s",
    BLOODSTREAM_GH_REPO, BLOODSTREAM_TESTDATA_RELEASE_TAG, BLOODSTREAM_TESTDATA_FILENAME
  )
  tryCatch({
    message("Test data not found locally. Downloading from GitHub Release...")
    utils::download.file(download_url, cached_tarball, mode = "wb", quiet = FALSE)
    if (file.exists(cached_tarball)) {
      message("Downloaded test data to: ", cached_tarball)
      return(cached_tarball)
    }
  }, error = function(e) {
    message("R download failed: ", conditionMessage(e))
    if (file.exists(cached_tarball)) file.remove(cached_tarball)
  })

  # 3b: gh CLI fallback
  if (nchar(Sys.which("gh")) > 0) {
    message("Trying gh CLI download...")
    result <- system2(
      "gh", c(
        "release", "download", BLOODSTREAM_TESTDATA_RELEASE_TAG,
        "--repo", BLOODSTREAM_GH_REPO,
        "--pattern", BLOODSTREAM_TESTDATA_FILENAME,
        "--dir", cache_dir
      ),
      stdout = TRUE, stderr = TRUE
    )
    exit_code <- attr(result, "status") %||% 0L
    if (exit_code == 0L && file.exists(cached_tarball)) {
      message("Downloaded test data to: ", cached_tarball)
      return(cached_tarball)
    }
    warning("gh CLI download failed: ", paste(result, collapse = "\n"))
  }

  NULL
}

#' Ensure test data is extracted and ready
#'
#' @return Path to the extracted ds004869 directory
ensure_testdata <- function() {
  cache_dir <- get_integration_cache_dir()
  dataset_dir <- file.path(cache_dir, "ds004869")
  sentinel <- file.path(cache_dir, ".ds004869_ready")

  if (file.exists(sentinel) && dir.exists(dataset_dir)) {
    return(dataset_dir)
  }

  tarball <- find_testdata_tarball()
  if (is.null(tarball)) {
    testthat::skip(paste0(
      "Test data tarball not found. Provide it via one of:\n",
      "  1. BLOODSTREAM_TESTDATA_PATH=/path/to/ds004869_testdata.tar.gz\n",
      "  2. Place at tests/testthat/fixtures/integration/ds004869_testdata.tar.gz\n",
      "  3. Upload to GitHub Release '", BLOODSTREAM_TESTDATA_RELEASE_TAG, "' (requires gh CLI)"
    ))
  }

  if (dir.exists(dataset_dir)) {
    unlink(dataset_dir, recursive = TRUE)
  }

  message("Extracting test data from: ", tarball)
  result <- utils::untar(tarball, exdir = cache_dir)
  if (result != 0 || !dir.exists(dataset_dir)) {
    testthat::skip("Failed to extract test data tarball")
  }

  writeLines(format(Sys.time()), sentinel)
  message("Test data ready at: ", dataset_dir)

  dataset_dir
}

# ---------------------------------------------------------------------------
# Workspace management
# ---------------------------------------------------------------------------

#' Create an isolated writable workspace for integration tests
#'
#' @param dataset_dir Path to the extracted ds004869 directory
#' @return List with bids_dir, derivatives_dir, and workspace paths
create_integration_workspace <- function(dataset_dir) {
  cache_dir <- get_integration_cache_dir()
  workspace <- tempfile(pattern = "bloodstream_ws_", tmpdir = cache_dir)
  dir.create(workspace, recursive = TRUE)

  derivatives_dir <- file.path(workspace, "derivatives")
  dir.create(derivatives_dir, recursive = TRUE)

  list(
    bids_dir = dataset_dir,
    derivatives_dir = derivatives_dir,
    workspace = workspace
  )
}

#' Clean up an integration workspace
cleanup_workspace <- function(workspace_info) {
  if (!is.null(workspace_info$workspace) && dir.exists(workspace_info$workspace)) {
    unlink(workspace_info$workspace, recursive = TRUE)
  }
}

# ---------------------------------------------------------------------------
# Config helpers
# ---------------------------------------------------------------------------

#' Get path to a config fixture file
get_config_fixture <- function(name) {
  testthat::test_path("fixtures", "integration", name)
}

# ---------------------------------------------------------------------------
# Container runners
# ---------------------------------------------------------------------------

#' Run bloodstream Docker container
#'
#' @param ws Workspace info from create_integration_workspace()
#' @param config_path Path to config JSON file (or NULL for default)
#' @param analysis_foldername Analysis folder name (default: "Primary_Analysis")
#' @param image Docker image name
#' @return List with output (character vector) and exit_code (integer)
run_bloodstream_docker <- function(ws, config_path = NULL,
                                    analysis_foldername = "Primary_Analysis",
                                    image = DOCKER_IMAGE) {
  # Build docker args
  docker_args <- c(
    "run", "--rm",
    "--user", paste0(as.integer(system("id -u", intern = TRUE)), ":",
                     as.integer(system("id -g", intern = TRUE)))
  )

  # Volume mounts
  docker_args <- c(docker_args,
    "-v", paste0(ws$bids_dir, ":/data/bids_dir:ro"),
    "-v", paste0(ws$derivatives_dir, ":/data/derivatives_dir:rw")
  )

  # Config mount
  if (!is.null(config_path)) {
    docker_args <- c(docker_args,
      "-v", paste0(normalizePath(config_path), ":/config.json:ro")
    )
  }

  docker_args <- c(docker_args, image)

  # App arguments
  if (!is.null(analysis_foldername) && analysis_foldername != "Primary_Analysis") {
    docker_args <- c(docker_args, "--analysis_foldername", analysis_foldername)
  }

  result <- suppressWarnings(
    system2("docker", docker_args, stdout = TRUE, stderr = TRUE)
  )
  exit_code <- attr(result, "status") %||% 0L

  list(
    output = result,
    exit_code = exit_code
  )
}

#' Run bloodstream Singularity/Apptainer container
#'
#' @param ws Workspace info from create_integration_workspace()
#' @param container Path to SIF file or Docker reference
#' @param config_path Path to config JSON file (or NULL for default)
#' @param analysis_foldername Analysis folder name (default: "Primary_Analysis")
#' @return List with output (character vector) and exit_code (integer)
run_bloodstream_singularity <- function(ws, container,
                                         config_path = NULL,
                                         analysis_foldername = "Primary_Analysis") {
  cmd <- get_singularity_cmd()

  # Build command args
  cmd_args <- c("run", "--cleanenv")

  # Bind mounts
  cmd_args <- c(cmd_args,
    "--bind", paste0(ws$bids_dir, ":/data/bids_dir:ro"),
    "--bind", paste0(ws$derivatives_dir, ":/data/derivatives_dir:rw")
  )

  if (!is.null(config_path)) {
    cmd_args <- c(cmd_args,
      "--bind", paste0(normalizePath(config_path), ":/config.json:ro")
    )
  }

  cmd_args <- c(cmd_args, container)

  if (!is.null(analysis_foldername) && analysis_foldername != "Primary_Analysis") {
    cmd_args <- c(cmd_args, "--analysis_foldername", analysis_foldername)
  }

  result <- suppressWarnings(
    system2(cmd, cmd_args, stdout = TRUE, stderr = TRUE)
  )
  exit_code <- attr(result, "status") %||% 0L

  list(
    output = result,
    exit_code = exit_code
  )
}

# ---------------------------------------------------------------------------
# Docker container helpers
# ---------------------------------------------------------------------------

#' Ensure Docker image is available
ensure_docker_image <- function() {
  if (Sys.getenv("BLOODSTREAM_DOCKER_BUILD") == "true") {
    pkg_root <- testthat::test_path("..", "..")
    build_result <- system2(
      "docker",
      c("build", "-t", DOCKER_IMAGE, "-f", "docker/dockerfile", "."),
      stdout = TRUE, stderr = TRUE
    )
    exit_code <- attr(build_result, "status") %||% 0L
    if (exit_code != 0L) {
      testthat::skip(paste("Docker build failed:", paste(build_result, collapse = "\n")))
    }
  }

  check <- system2("docker", c("image", "inspect", DOCKER_IMAGE),
                    stdout = FALSE, stderr = FALSE)
  if (check != 0L) {
    testthat::skip(paste("Docker image not available:", DOCKER_IMAGE,
                         "\nPull with: docker pull", DOCKER_IMAGE,
                         "\nOr set BLOODSTREAM_DOCKER_BUILD=true to build from source"))
  }
}

# ---------------------------------------------------------------------------
# Singularity/Apptainer container helpers
# ---------------------------------------------------------------------------

#' Locate singularity/apptainer command
get_singularity_cmd <- function() {
  if (nchar(Sys.which("apptainer")) > 0) return("apptainer")
  if (nchar(Sys.which("singularity")) > 0) return("singularity")
  NULL
}

#' Find or build Singularity container image
find_singularity_container <- function() {
  # Check for explicit path
  sif_path <- Sys.getenv("BLOODSTREAM_SINGULARITY_SIF", unset = "")
  if (sif_path != "" && file.exists(sif_path)) {
    return(sif_path)
  }

  # Try docker-daemon reference if Docker image exists
  docker_check <- system2("docker", c("image", "inspect", DOCKER_IMAGE),
                          stdout = FALSE, stderr = FALSE)
  if (docker_check == 0L) {
    return(paste0("docker-daemon:", DOCKER_IMAGE))
  }

  NULL
}
