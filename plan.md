# Plan: Output raw AIF timeseries before AIF modeling

## Context
Users who want to apply their own AIF models need the pre-modeling AIF data — i.e., the arterial input function values computed from the fitted parent fraction and BPR models, but *before* any AIF curve fitting. This change adds a TSV + JSON sidecar output of that raw AIF data early in the AIF section of the pipeline.

## File to modify
- `inst/qmd/template.qmd` (the active template; `R/run_bloodstream.R:77` uses QMD, not the old RMD)

## Changes

### 1. Add raw AIF extraction + save chunk

**Insert location:** After the `aif-setup` chunk (line ~1074), before `aif-exclude-manual` (line ~1076). This ensures the raw data is saved before any AIF filtering or modeling occurs.

**Add a markdown header and new code chunk** that:

1. Extracts AIF data via `bd_extract(blooddata, output = "AIF", what = "pred")`
2. Renames columns to BIDS-consistent names:
   - `time` → `time` (convert min→sec, ×60)
   - `blood` → `whole_blood_radioactivity` (convert kBq→Bq via `unit_convert()`)
   - `Method` → `recording` (map "Continuous"→"autosampler", "Discrete"→"manual")
   - `bpr` → `blood_plasma_ratio`
   - `parentFraction` → `metabolite_parent_fraction`
   - `plasma_uncor` → `plasma_radioactivity` (convert kBq→Bq via `unit_convert()`)
   - `aif` → `AIF` (convert kBq→Bq via `unit_convert()`)
3. Constructs output filename using the same pattern as `_inputfunction.tsv` but ending in `_desc-AIFraw_timeseries.tsv`
4. Saves TSV files
5. Saves JSON sidecar (`_desc-AIFraw_timeseries.json`) with column descriptions and units

**Markdown text before the chunk:**
> Below we save the raw arterial input function data — computed from the modelled parent fraction and blood-to-plasma ratio, but **before** any AIF curve fitting. This allows users who wish to apply their own AIF models to start from the metabolite-corrected plasma data directly.

**New chunk to insert (between line 1074 `\`\`\`` and line 1076 `\`\`\`{r aif-exclude-manual}`):**

```r
```{r aif-raw-output}
#| echo: false

# Extract raw AIF data (after PF and BPR modeling, before AIF modeling)
aif_raw_data <- bidsdata %>%
  mutate(aif_raw = map(blooddata, ~bd_extract(.x, output = "AIF", what = "pred"))) %>%
  mutate(aif_raw = map(aif_raw, ~.x %>%
    rename(
      "whole_blood_radioactivity" = blood,
      "recording" = Method,
      "blood_plasma_ratio" = bpr,
      "metabolite_parent_fraction" = parentFraction,
      "plasma_radioactivity" = plasma_uncor,
      "AIF" = aif
    ) %>%
    mutate(
      time = time * 60,  # min to sec
      whole_blood_radioactivity = unit_convert(whole_blood_radioactivity, "kBq", "Bq"),
      plasma_radioactivity = unit_convert(plasma_radioactivity, "kBq", "Bq"),
      AIF = unit_convert(AIF, "kBq", "Bq"),
      recording = case_when(
        recording == "Continuous" ~ "autosampler",
        recording == "Discrete" ~ "manual",
        TRUE ~ recording
      )
    )
  )) %>%
  select(pet, aif_raw)

# Build output filenames
aif_raw_filenames <- bidsdata %>%
  mutate(bloodfilename = map_chr(filedata, ~.x %>%
    filter(measurement == "blood") %>%
    filter(str_detect(path, "manual_blood.json")) %>%
    slice(1) %>%
    pull(path))) %>%
  mutate(
    output_basename = basename(bloodfilename),
    output_basename = str_replace(output_basename,
      "_recording-manual_blood.json",
      "_desc-AIFraw_timeseries.tsv"),
    output_folder = dirname(bloodfilename),
    aifraw_tsv_filename = paste0(params$derivatives_dir, "/bloodstream/",
      params$analysis_foldername, "/",
      output_folder, "/", output_basename),
    aifraw_json_filename = str_replace(aifraw_tsv_filename,
      "_desc-AIFraw_timeseries.tsv",
      "_desc-AIFraw_timeseries.json")
  ) %>%
  select(pet, aifraw_tsv_filename, aifraw_json_filename)

aif_raw_data <- inner_join(aif_raw_data, aif_raw_filenames, by = "pet")

# Create directories and save TSV files
walk(dirname(aif_raw_data$aifraw_tsv_filename),
     dir.create, recursive = TRUE, showWarnings = FALSE)
walk2(aif_raw_data$aif_raw, aif_raw_data$aifraw_tsv_filename,
  ~write_delim(.x, file = .y, delim = "\t"))

# Save JSON sidecars
aifraw_description <- list(
  time = list(
    Description = "Time of blood sample in relation to time zero defined in _pet.json",
    Units = "s"
  ),
  whole_blood_radioactivity = list(
    Description = "Radioactivity in whole blood samples",
    Units = "Bq"
  ),
  recording = list(
    Description = "Blood sampling method",
    Levels = list(
      autosampler = "Continuous blood sampling via autosampler",
      manual = "Discrete manual blood samples"
    )
  ),
  blood_plasma_ratio = list(
    Description = "Modelled ratio of whole blood to plasma radioactivity"
  ),
  metabolite_parent_fraction = list(
    Description = "Modelled fraction of unchanged parent compound in plasma"
  ),
  plasma_radioactivity = list(
    Description = "Radioactivity in plasma samples before metabolite correction",
    Units = "Bq"
  ),
  AIF = list(
    Description = "Arterial input function: metabolite-corrected arterial plasma radioactivity before AIF model fitting",
    Units = "Bq"
  )
)

walk(aif_raw_data$aifraw_json_filename,
     ~write_json(aifraw_description, path = .x, pretty = TRUE))
```
```

### 2. Add cleanup of AIFraw files in the output section

**Insert location:** In the output section (~line 1713-1715), after the existing `file.remove()` calls for `output_filename`, `output_json_filename`, and `output_cfg_filename`.

**Code to add:**

```r
# Also remove AIFraw files from previous runs
aifraw_cleanup <- bidsdata %>%
  mutate(aifraw_tsv = str_replace(output_filename, "_inputfunction.tsv", "_desc-AIFraw_timeseries.tsv"),
         aifraw_json = str_replace(output_filename, "_inputfunction.tsv", "_desc-AIFraw_timeseries.json"))
suppressWarnings(file.remove(aifraw_cleanup$aifraw_tsv))
suppressWarnings(file.remove(aifraw_cleanup$aifraw_json))
```

## Key design decisions
- **Recording column values**: "Continuous" → "autosampler", "Discrete" → "manual" (matches BIDS `_recording-` entity convention)
- **Unit conversions**: Same as existing outputs — min→sec (×60), kBq→Bq (via `unit_convert()`)
- **Column names**: Consistent with existing `_inputfunction.tsv` output (`whole_blood_radioactivity`, `plasma_radioactivity`, `metabolite_parent_fraction`, `AIF`) plus `recording` and `blood_plasma_ratio`
- **Filename pattern**: Uses `_desc-AIFraw_timeseries.tsv` suffix as requested, derived from the same base filename as `_inputfunction.tsv`

## Verification
1. Run the bloodstream pipeline on test data and confirm:
   - `_desc-AIFraw_timeseries.tsv` files are created alongside `_inputfunction.tsv`
   - Columns are: `time`, `whole_blood_radioactivity`, `recording`, `blood_plasma_ratio`, `metabolite_parent_fraction`, `plasma_radioactivity`, `AIF`
   - Units are seconds and Bq (not minutes/kBq)
   - `recording` values are "autosampler"/"manual" (not "Continuous"/"Discrete")
   - JSON sidecar describes all columns
2. Verify the AIF raw data appears in the output *before* any AIF model fitting in the report
