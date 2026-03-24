# Plan: Integration Tests for bloodstream

## Context

The bloodstream package has **no tests or CI** currently. The sibling package `petfit` has a comprehensive integration test suite with R-native, Docker, and Singularity tests using real PET data from ds004869. We'll replicate that pattern for bloodstream.

The ds004869 test data tarball (2.7MB, from petfit's GitHub release `testdata-v1.0`) contains 54 blood files (27 subjects × 2 sessions) with `_blood.tsv` + `_blood.json` pairs — suitable for all bloodstream components (parent fraction, BPR, AIF, whole blood).

---

## Files to Create/Modify

### 1. `DESCRIPTION` — Add Suggests and testthat edition

Add:
```
Suggests:
    testthat (>= 3.0.0),
    withr,
    here
Config/testthat/edition: 3
```

### 2. `.Rbuildignore` — Exclude test fixtures and CI

Append:
```
^tests/testthat/fixtures$
^\.github$
^CLAUDE\.md$
```

### 3. `tests/testthat.R` — Standard testthat runner

```r
library(testthat)
library(bloodstream)
test_check("bloodstream")
```

### 4. `tests/testthat/helper-setup.R` — Basic setup

```r
library(here)
```

### 5. `tests/testthat/helper-integration.R` — Core test infrastructure (~300 lines)

Adapted from `/home/granville/Repositories/petfit/tests/testthat/helper-integration.R`.

**Key components:**

- **Constants**: `DOCKER_IMAGE = "mathesong/bloodstream:latest"`, GitHub repo/tag for test data download from `mathesong/petfit` release `testdata-v1.0`
- **Skip functions**: `skip_if_no_integration()` (checks `BLOODSTREAM_INTEGRATION_TESTS`), `skip_if_no_docker()` (checks `BLOODSTREAM_DOCKER_TESTS` + docker CLI), `skip_if_no_singularity()` (checks `BLOODSTREAM_SINGULARITY_TESTS` + apptainer/singularity CLI)
- **Test data management**: `get_integration_cache_dir()`, `find_testdata_tarball()` (env var → local fixtures → GitHub release download), `ensure_testdata()` (extract once with sentinel file)
- **Workspace management**: `create_integration_workspace(dataset_dir)` → creates temp dir with writable `derivatives/` subdir, returns `list(bids_dir, derivatives_dir, workspace)`. `cleanup_workspace()` via `unlink()`. Simpler than petfit — no petprep symlink needed.
- **Config helper**: `get_config_fixture(name)` → returns `test_path("fixtures", "integration", name)`
- **Docker runner**: `run_bloodstream_docker(ws, config_path, analysis_foldername, image)` — builds `docker run --rm --user UID:GID -v bids:/data/bids_dir:ro -v derivs:/data/derivatives_dir:rw [-v config:/config.json:ro] image [--analysis_foldername name]`. Returns `list(output, exit_code)`.
- **Singularity runner**: `run_bloodstream_singularity(ws, container, config_path, analysis_foldername)` — uses `--cleanenv --bind`. Auto-detects `apptainer` vs `singularity`.
- **Container helpers**: `ensure_docker_image()`, `get_singularity_cmd()`, `find_singularity_container()` (env var → docker-daemon reference)

### 6. Config Fixtures (2 JSON files in `tests/testthat/fixtures/integration/`)

**`ds004869_bloodstream_interpolation_config.json`**: Default config with `sub: ["01;02"]` subset — interpolation for all components. Produces 4 measurements (2 subjects × 2 sessions). Fastest possible run.

**`ds004869_bloodstream_fitting_config.json`**: Same subset, but `ParentFraction.Method: ["Fit Individually: Hill"]`. Tests model fitting path.

### 7. `tests/testthat/test-integration-dataset.R` — Validate test data

Tests (all gated by `skip_if_no_integration()`):
- Test data extracts successfully (dataset_dir, participants.tsv, dataset_description.json exist)
- 54 `_blood.tsv` files found
- Blood TSV parseable with expected columns (time, plasma_radioactivity, metabolite_parent_fraction, whole_blood_radioactivity)
- Blood JSON sidecars are valid JSON
- Subject/session structure matches expectations (sub-01 has ses-baseline + ses-blocked)
- Workspace creation and cleanup works

### 8. `tests/testthat/test-integration-pipeline.R` — R-native pipeline tests

Tests (all gated by `skip_if_no_integration()`):

1. **Pipeline succeeds with interpolation config** — runs `bloodstream()`, checks:
   - `bloodstream_report.html` exists
   - `bloodstream_config.json` exists
   - `dataset_description.json` exists
   - 4 `_inputfunction.tsv` files (recursive search)
   - 4 `_inputfunction.json` files
   - 4 `_config.json` files
   - 4 `_desc-AIFraw_timeseries.tsv` files
   - 4 `_desc-AIFraw_timeseries.json` files

2. **inputfunction TSV has expected columns** — reads one TSV, checks columns: time, whole_blood_radioactivity, plasma_radioactivity, metabolite_parent_fraction, AIF. Checks nrow > 0.

3. **AIFraw TSV has expected columns** — reads one TSV, checks columns: time, recording, whole_blood_radioactivity, plasma_radioactivity, blood_plasma_ratio, metabolite_parent_fraction, AIF

4. **Pipeline succeeds with model fitting config** — Hill model for PF. Same output count validation.

5. **Custom analysis_foldername works** — outputs land in correct subfolder

6. **Fails gracefully with invalid bids_dir** — `expect_error()`

7. **Fails gracefully with invalid config** — `expect_error()`

### 9. `tests/testthat/test-integration-docker.R` — Docker container tests

Tests (gated by `skip_if_no_docker()`):

1. **Non-interactive mode with interpolation config** — exit code 0, 4 output files
2. **Non-interactive mode with fitting config** — exit code 0, 4 output files
3. **Custom analysis_foldername** — outputs in correct folder
4. **Output contains expected log markers** — "bloodstream Docker Container", "Non-Interactive Mode", "pipeline completed successfully"
5. **Fails without bids_dir mount** — non-zero exit code

### 10. `tests/testthat/test-integration-singularity.R` — Singularity tests

Tests (gated by `skip_if_no_singularity()`):

1. **Non-interactive mode with interpolation config** — exit code 0, correct outputs
2. **Non-interactive mode with fitting config** — exit code 0, correct outputs
3. **Custom analysis_foldername** — outputs in correct folder

No `.def` file needed — uses `docker-daemon:mathesong/bloodstream:latest` reference for on-the-fly conversion.

### 11. `.github/workflows/integration-tests.yml` — GHA workflow

**Triggers**: push/PR to main, workflow_dispatch with `run_docker` and `run_singularity` boolean inputs.

**Concurrency**: cancel-in-progress per PR/branch.

**3 parallel jobs:**

| Job | Timeout | Key Steps | Env Vars |
|-----|---------|-----------|----------|
| `r-native` | 60min | checkout, setup-r, quarto-actions/setup, install bloodstream, download testdata via `gh release download testdata-v1.0 --repo mathesong/petfit`, run `devtools::test(filter='integration')` | `BLOODSTREAM_INTEGRATION_TESTS=true`, `BLOODSTREAM_INTEGRATION_CACHE=/tmp/bloodstream_integration` |
| `docker` | 90min | + Docker Buildx, build image (`docker/dockerfile`), run `devtools::test(filter='integration.*docker')` | + `BLOODSTREAM_DOCKER_TESTS=true` |
| `singularity` | 90min | + eWaterCycle/setup-apptainer@v2, build Docker image, run `devtools::test(filter='integration.*singularity')` | + `BLOODSTREAM_SINGULARITY_TESTS=true` |

Test data download step (shared across all jobs):
```yaml
- name: Download test data
  run: |
    mkdir -p tests/testthat/fixtures/integration
    gh release download testdata-v1.0 --repo mathesong/petfit \
      --pattern 'ds004869_testdata.tar.gz' \
      --dir tests/testthat/fixtures/integration/
  env:
    GH_TOKEN: ${{ github.token }}
```

---

## Key Design Decisions

1. **Test data NOT committed** to bloodstream repo — downloaded from petfit's GitHub release at CI time. Local devs set `BLOODSTREAM_TESTDATA_PATH` or place tarball manually.
2. **No Singularity .def file** — apptainer converts Docker image via `docker-daemon:` reference.
3. **Subset to 2 subjects** (4 measurements) for speed.
4. **Quarto required** for R-native tests — GHA uses `quarto-dev/quarto-actions/setup@v2`.

---

## Verification

1. **Local R-native test**: `BLOODSTREAM_INTEGRATION_TESTS=true Rscript -e "devtools::test(filter='integration')"` (requires Quarto + test data)
2. **Local Docker test**: Build image, then `BLOODSTREAM_INTEGRATION_TESTS=true BLOODSTREAM_DOCKER_TESTS=true Rscript -e "devtools::test(filter='integration.*docker')"`
3. **GHA**: Push to branch, open PR against main — all 3 jobs should pass
