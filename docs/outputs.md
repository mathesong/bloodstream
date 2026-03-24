# Outputs

bloodstream produces output files following BIDS derivatives conventions. All outputs go into the `derivatives/bloodstream/` directory.

## Directory structure

```
derivatives/
└── bloodstream/
    └── <analysis_foldername>/
        ├── bloodstream_report.html
        ├── bloodstream_config.json
        ├── dataset_description.json
        └── sub-XX/
            └── ses-YY/
                ├── sub-XX_ses-YY_pet-NAME_inputfunction.tsv
                ├── sub-XX_ses-YY_pet-NAME_inputfunction.json
                ├── sub-XX_ses-YY_pet-NAME_config.json
                ├── sub-XX_ses-YY_desc-aifraw_timeseries.tsv
                └── sub-XX_ses-YY_desc-aifraw_timeseries.json
```

## File descriptions

### bloodstream_report.html

A comprehensive HTML report generated for each analysis run. Contains:

- Model fitting results and comparisons for each blood component
- Before/after plots showing raw data and fitted curves
- Quality control metrics and warnings
- Processing configuration details
- Per-measurement summaries

### bloodstream_config.json

A copy of the configuration file used for this analysis, preserving full reproducibility.

### dataset_description.json

BIDS-required metadata file describing the derivative dataset.

### Per-measurement files

For each PET measurement, bloodstream produces:

#### *_inputfunction.tsv

The processed blood curves ready for pharmacokinetic modelling. Contains interpolated or model-fitted values for the arterial input function, including plasma activity, whole blood activity, and parent fraction at a fine time resolution.

#### *_inputfunction.json

JSON sidecar accompanying the TSV file, containing metadata about the blood processing (units, column descriptions, etc.).

#### *_config.json

Per-measurement model configuration and fit results. Records which models were used, fit parameters, and AIC values if model comparison was performed.

#### *_desc-aifraw_timeseries.tsv / .json

Raw AIF data extracted from the BIDS blood files, before any modelling or interpolation is applied. Useful for quality control and comparison with processed outputs.
