# Supported models

bloodstream supports a range of models for each blood component. When several methods are listed for a component, bloodstream fits each one, compares them by AIC (Akaike Information Criterion), and selects the best-fitting model per measurement. See the [configuration guide](usage/configuration.md) for the JSON parameters of each method.

## Parent Fraction

The proportion of plasma radioactivity from the unmetabolised parent compound, typically declining over time.

- **Interpolation** — Linear interpolation of observed data (default; no fitting).
- **Hill, Exponential, Power, Sigmoid, Inverse Gamma, Gamma** — A family of three-parameter nonlinear parametric models, fit per measurement. They differ in curve shape; selecting "Choose the best-fitting model" fits all of them and keeps the lowest-AIC one.
- **GAM** — A non-parametric smooth fit; `gam_k` controls wiggliness (lower it when there are few points).
- **HGAM** — Hierarchical GAM; shares a group-level smooth across measurements while allowing individual deviations. Best when borrowing strength across subjects helps.

## Blood-to-Plasma Ratio (BPR)

The distribution of radioactivity between whole blood and plasma.

| Method | Notes |
|--------|-------|
| Interpolation | Linear interpolation (default). |
| Constant | Single mean value; appropriate when BPR is stable over time (common for many tracers). |
| Linear | Linear fit; for a slow, steady trend. |
| GAM | Smooth fit for non-linear time dependence. |
| HGAM | Hierarchical GAM for group-level modelling, analogous to the parent fraction HGAM. |

## Arterial Input Function (AIF)

The time course of radioactivity in arterial plasma after injection. AIF models should be used with caution — they can easily underfit the data for minimal gains.

| Method | Notes |
|--------|-------|
| Interpolation | Linear interpolation (default; often sufficient). |
| Linear Rise, Triexponential Decay | Linear rise plus three exponential decay components; a classic model for bolus injections. |
| Feng | Widely used parametric input function model. |
| FengConv | Feng convolved with the infusion duration; for slow infusions rather than a bolus (set `inftime`). |
| Splines | Flexible spline fit, with separate basis functions before and after the peak. |

### Weighting

The AIF fits (both parametric and spline) are weighted, so that some samples count more than others. Three options control this:

- **Weight scheme** (`weightscheme`) — how each sample's base weight is derived: `1` = uniform (all samples equal), `2` = time/activity (the default; downweights the noisy, high-activity early peak), `3` = activity (proportional to activity), `4` = inverse activity.
- **Method weights** (`Method_weights`) — when both discrete (manual) and continuous (autosampler) samples are present, divides the total weight equally between the two methods, so that densely-sampled continuous data does not swamp the sparser discrete samples.
- **Taper weights** (`taper_weights`) — after the peak, gradually trades weighting off from the continuous samples toward the discrete samples, which are usually more reliable at later times.

These options are exposed only for the AIF. Whole blood spline fits use the same underlying fitter with default weighting, but do not expose separate weighting controls.

## Whole Blood

Total radioactivity in whole blood over time. Whole blood models rarely make a large difference except when measurements are noisy or brain uptake is very low.

| Method | Notes |
|--------|-------|
| Interpolation | Linear interpolation (default; usually sufficient). |
| Splines | Flexible spline fit; useful when whole blood measurements are noisy and smoothing would help downstream modelling. |

## Model comparison

When the parent fraction method is set to `"Fit Individually: Choose the best-fitting model"`, bloodstream fits all individual parametric models (Hill, Exponential, Power, Sigmoid, Inverse Gamma, Gamma) to each measurement, computes AIC for each, and applies the model with the lowest total AIC across all measurements (for consistency). The AIC values are reported in the HTML report.
