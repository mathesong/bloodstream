# Configuration guide

bloodstream uses JSON configuration files to specify which models to apply to each blood component. Configuration files can be created interactively via the Shiny app or edited by hand.

## Overview

A config file has two top-level sections:

- **Subsets** — Filter which measurements to process (by subject, session, tracer, etc.)
- **Model** — Specify modelling choices for each blood component (Parent Fraction, BPR, AIF, Whole Blood)

## Data subsetting

The `Subsets` section filters which PET measurements to include. Leave a field as an empty string to include all values. Use semicolons to specify multiple values.

```json
{
  "Subsets": {
    "sub": "",
    "ses": "",
    "rec": "",
    "task": "",
    "run": "",
    "TracerName": "",
    "ModeOfAdministration": "",
    "InstitutionName": "",
    "PharmaceuticalName": ""
  }
}
```

| Field | Description | Example |
|-------|-------------|---------|
| `sub` | Subject IDs | `"01;02;03"` |
| `ses` | Session IDs | `"baseline;followup"` |
| `rec` | Recording labels | `""` |
| `task` | Task names | `""` |
| `run` | Run numbers | `""` |
| `TracerName` | Filter by tracer | `"[11C]PBR28"` |
| `ModeOfAdministration` | Filter by administration mode | `"bolus"` |
| `InstitutionName` | Filter by institution | `""` |
| `PharmaceuticalName` | Filter by pharmaceutical | `""` |

## Parent Fraction

The parent fraction represents the proportion of radioactivity in plasma that is from the unmetabolised parent compound. It typically declines over time as the tracer is metabolised.

```json
{
  "Model": {
    "ParentFraction": {
      "Method": "Interpolation",
      "set_ppf0": true,
      "starttime": 0,
      "endtime": "Inf",
      "gam_k": "6",
      "hgam_formula": ""
    }
  }
}
```

### Methods

| Method | Description |
|--------|-------------|
| `Interpolation` | Linear interpolation of observed data (default) |
| `Fit Individually: Choose the best-fitting model` | Compares all individual models via AIC and selects the best |
| `Fit Individually: Hill` | Hill function model |
| `Fit Individually: Exponential` | Exponential decay model |
| `Fit Individually: Power` | Power function model |
| `Fit Individually: Sigmoid` | Sigmoid (logistic) model |
| `Fit Individually: Inverse Gamma` | Inverse Gamma CDF model |
| `Fit Individually: Gamma` | Gamma CDF model |
| `Fit Individually: GAM` | Generalised Additive Model (smooth fit per measurement) |
| `Fit Hierarchically: HGAM` | Hierarchical GAM (group-level smooth with individual deviations) |

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `set_ppf0` | Constrain parent fraction to 100% at time 0 | `true` |
| `starttime` | Start time in minutes for model fitting | `0` |
| `endtime` | End time in minutes for model fitting | `Inf` |
| `gam_k` | GAM basis dimension (k) | `6` |
| `hgam_formula` | HGAM smooth formula | `"s(log(time), k=8) + s(log(time), pet, bs='fs', k=5)"` |

## Blood-to-Plasma Ratio (BPR)

The blood-to-plasma ratio describes the distribution of radioactivity between whole blood and plasma.

```json
{
  "Model": {
    "BPR": {
      "Method": "Interpolation",
      "starttime": 0,
      "endtime": "Inf",
      "gam_k": 6,
      "hgam_formula": ""
    }
  }
}
```

### Methods

| Method | Description |
|--------|-------------|
| `Interpolation` | Linear interpolation of observed data (default) |
| `Fit Individually: Constant` | Single mean value across all time points |
| `Fit Individually: Linear` | Linear fit |
| `Fit Individually: GAM` | Generalised Additive Model |
| `Fit Hierarchically: HGAM` | Hierarchical GAM |

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `starttime` | Start time in minutes | `0` |
| `endtime` | End time in minutes | `Inf` |
| `gam_k` | GAM basis dimension (k) | `6` |
| `hgam_formula` | HGAM smooth formula | `"s(time, k=8) + s(time, pet, bs='fs', k=5)"` |

## Arterial Input Function (AIF)

The AIF describes the time course of radioactivity in arterial plasma after injection. Models for the AIF should be used with caution as they can easily underfit the data.

```json
{
  "Model": {
    "AIF": {
      "Method": "Interpolation",
      "starttime": 0,
      "endtime": "Inf",
      "expdecay_props": ["NA", "NA"],
      "inftime": ["NA"],
      "spline_kb": "",
      "spline_ka_m": "",
      "spline_ka_a": "",
      "weightscheme": 2,
      "Method_weights": true,
      "taper_weights": true,
      "exclude_manual_during_continuous": false
    }
  }
}
```

### Methods

| Method | Description |
|--------|-------------|
| `Interpolation` | Linear interpolation of observed data (default) |
| `Fit Individually: Linear Rise, Triexponential Decay` | Parametric model with linear rise and three exponential decay components |
| `Fit Individually: Feng` | Feng input function model |
| `Fit Individually: FengConv` | Feng model convolved with infusion duration |
| `Fit Individually: Splines` | Flexible spline fit |

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `starttime` | Start time in minutes | `0` |
| `endtime` | End time in minutes | `Inf` |
| `expdecay_props` | Proportions for exponential decay starting parameters | `[NA, NA]` |
| `inftime` | Infusion duration in seconds (required for FengConv) | `NA` |
| `spline_kb` | Spline k before peak | `""` (auto) |
| `spline_ka_m` | Spline k after peak (manual samples) | `""` (auto) |
| `spline_ka_a` | Spline k after peak (auto-sampler) | `""` (auto) |
| `weightscheme` | Weight scheme: `1` = uniform, `2` = time/activity-based | `2` |
| `Method_weights` | Divide weights equally between discrete and continuous methods | `true` |
| `taper_weights` | Taper weights after peak | `true` |
| `exclude_manual_during_continuous` | Exclude manual samples during continuous sampling | `false` |

## Whole Blood

The whole blood curve describes the time course of total radioactivity in whole blood. Models for whole blood don't tend to make much difference except when blood measurements are noisy or brain uptake is very low.

```json
{
  "Model": {
    "WholeBlood": {
      "Method": "Interpolation",
      "dispcor": false,
      "exclude_manual_during_continuous": false,
      "starttime": 0,
      "endtime": "Inf",
      "spline_kb": "",
      "spline_ka_m": "",
      "spline_ka_a": ""
    }
  }
}
```

### Methods

| Method | Description |
|--------|-------------|
| `Interpolation` | Linear interpolation of observed data (default) |
| `Fit Individually: Splines` | Flexible spline fit |

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `dispcor` | Apply dispersion correction on autosampler samples | `false` |
| `exclude_manual_during_continuous` | Exclude manual samples during continuous sampling | `false` |
| `starttime` | Start time in minutes | `0` |
| `endtime` | End time in minutes | `Inf` |
| `spline_kb` | Spline k before peak | `""` (auto) |
| `spline_ka_m` | Spline k after peak (manual samples) | `""` (auto) |
| `spline_ka_a` | Spline k after peak (auto-sampler) | `""` (auto) |

## Example configurations

### Simple interpolation (no modelling)

This is the default when no config file is provided:

```json
{
  "Subsets": {
    "sub": "", "ses": "", "rec": "", "task": "", "run": "",
    "TracerName": "", "ModeOfAdministration": "",
    "InstitutionName": "", "PharmaceuticalName": ""
  },
  "Model": {
    "ParentFraction": { "Method": "Interpolation", "set_ppf0": true, "starttime": 0, "endtime": "Inf" },
    "BPR": { "Method": "Interpolation", "starttime": 0, "endtime": "Inf" },
    "AIF": { "Method": "Interpolation", "starttime": 0, "endtime": "Inf" },
    "WholeBlood": { "Method": "Interpolation", "starttime": 0, "endtime": "Inf" }
  }
}
```

### GAM parent fraction + spline AIF

```json
{
  "Subsets": {
    "sub": "", "ses": "", "rec": "", "task": "", "run": "",
    "TracerName": "", "ModeOfAdministration": "",
    "InstitutionName": "", "PharmaceuticalName": ""
  },
  "Model": {
    "ParentFraction": {
      "Method": "Fit Individually: GAM",
      "set_ppf0": true,
      "starttime": 0,
      "endtime": "Inf",
      "gam_k": "6"
    },
    "BPR": { "Method": "Fit Individually: GAM", "starttime": 0, "endtime": "Inf", "gam_k": 6 },
    "AIF": { "Method": "Fit Individually: Splines", "starttime": 0, "endtime": "Inf", "weightscheme": 2, "Method_weights": true, "taper_weights": true },
    "WholeBlood": { "Method": "Interpolation", "starttime": 0, "endtime": "Inf" }
  }
}
```

### Best-fitting model comparison

```json
{
  "Subsets": {
    "sub": "", "ses": "", "rec": "", "task": "", "run": "",
    "TracerName": "", "ModeOfAdministration": "",
    "InstitutionName": "", "PharmaceuticalName": ""
  },
  "Model": {
    "ParentFraction": {
      "Method": "Fit Individually: Choose the best-fitting model",
      "set_ppf0": true,
      "starttime": 0,
      "endtime": "Inf",
      "gam_k": "6"
    },
    "BPR": { "Method": "Fit Individually: Constant", "starttime": 0, "endtime": "Inf" },
    "AIF": { "Method": "Interpolation", "starttime": 0, "endtime": "Inf" },
    "WholeBlood": { "Method": "Interpolation", "starttime": 0, "endtime": "Inf" }
  }
}
```

## Using the interactive app

The interactive Shiny app provides a graphical interface for creating configuration files. It has tabs for each blood component:

1. **Parent Fraction** — Select model, set time range, configure GAM/HGAM options
2. **Blood-to-Plasma Ratio** — Select model, set time range
3. **Arterial Input Function** — Select model, configure weighting and spline options
4. **Whole Blood** — Select model, configure dispersion correction and spline options
5. **Download & Run** — Download the config file and optionally run the pipeline

The sidebar panel allows you to define data subsets (subject, session, tracer, etc.).

When a BIDS directory is provided, the app also enables direct pipeline execution with the current configuration.
