# Troubleshooting

## Docker issues

### Output files owned by root

**Symptom:** Files in the derivatives directory are owned by root and cannot be modified.

**Cause:** Docker containers run as root by default on Linux.

**Fix:** Add `--user $(id -u):$(id -g)` to your `docker run` command. See [Docker usage](containers/docker.md#file-permissions-on-linux).

### Port already in use

**Symptom:** Error when starting interactive mode about port 3838 being in use.

**Fix:** Map to a different host port: `-p 8080:3838` instead of `-p 3838:3838`.

## Apptainer / HPC issues

### No internet access on compute nodes

**Fix:** Build the container on a login node, then transfer the `.sif` file to your project space.

### Home directory size limits

**Fix:** Set `SINGULARITY_CACHEDIR` to a scratch directory:

```bash
export SINGULARITY_CACHEDIR=/scratch/$USER/singularity_cache
```

### Module loading

Common module names:

```bash
module load singularity
module load apptainer
module load singularity-ce
```

### Writable tmp directory

**Symptom:** Permission errors during report generation or model fitting.

**Fix:** Use the `--writable-tmpfs` flag:

```bash
apptainer run --writable-tmpfs \
  --bind /path/to/bids:/data/bids_dir \
  bloodstream_latest.sif
```

## Model fitting issues

### GAM k too high for the number of data points

**Symptom:** Error message about basis dimension being too large for the data.

**Fix:** Reduce the `gam_k` parameter in your config file. The value of `k` must be less than the number of data points. A value of 4-6 works well for most datasets.

### Model fails to converge

**Symptom:** Warnings about convergence failure or `NA` parameter estimates.

**Possible causes:**
- Too few data points for the chosen model
- Data does not follow the assumed model shape
- Time range is too narrow or too wide

**Fix:** Try a simpler model (e.g. Interpolation or Constant for BPR). Review the raw data in the HTML report to verify it looks reasonable before fitting complex models.

### HGAM formula errors

**Symptom:** Error when fitting hierarchical GAM models.

**Fix:** Ensure the HGAM formula references valid column names. The `pet` variable identifies individual measurements. Time should typically be log-transformed: `s(log(time), k=8) + s(log(time), pet, bs='fs', k=5)`.

## Config file issues

### JSON syntax errors

**Symptom:** Error about unexpected token or invalid JSON.

**Fix:** Validate your config file using a JSON linter. Common issues include trailing commas, missing quotes, and unmatched brackets. The interactive app always generates valid JSON.

### Method name typos

**Symptom:** Error about unknown or unsupported method.

**Fix:** Method names are case-sensitive and must match exactly (e.g. `"Fit Individually: GAM"` not `"fit individually: gam"`). Use the interactive app to generate correct method names.

## Data issues

### Missing blood data

**Symptom:** No measurements found in the BIDS directory.

**Fix:** Verify that your BIDS dataset contains blood data files (`*_blood.tsv` and associated JSON sidecars). Check that the BIDS structure is valid.

### Incorrect BIDS structure

**Symptom:** bloodstream cannot find or parse blood data files.

**Fix:** Ensure your dataset follows the [BIDS specification for blood data](https://bids-specification.readthedocs.io/). Files should be in `sub-XX/ses-YY/pet/` directories with correct naming conventions.

## Report generation issues

### Quarto errors

**Symptom:** Report generation fails with Quarto-related errors.

**Fix:** In Docker, this is usually a permissions issue with the temporary directory. The container handles this automatically, but if running outside Docker, ensure Quarto is installed and the working directory is writable.

### Missing dependencies

**Symptom:** Error about missing R packages during report generation.

**Fix:** When using the R package directly (not Docker), ensure all dependencies are installed:

```r
remotes::install_github("mathesong/bloodstream")
```

The Docker image includes all dependencies.
