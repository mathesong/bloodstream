# Supported models

bloodstream supports a range of models for each blood component. When several methods are listed for a component, bloodstream fits each one, compares them by AIC (Akaike Information Criterion), and selects the best-fitting model per measurement. See the [configuration guide](usage/configuration.md) for the JSON parameters of each method.

## Parent Fraction

The proportion of plasma radioactivity from the unmetabolised parent compound, typically declining over time.

| Method | Notes |
|--------|-------|
| Interpolation | Linear interpolation of observed data (default; no fitting). |
| Hill | Sigmoidal decay; flexible, captures many metabolite curve shapes. |
| Exponential | Exponential decay; common for many tracers. |
| Power | For curves where the rate of decline changes slowly over time. |
| Sigmoid | Logistic form; smooth, monotonically decreasing curves. |
| Inverse Gamma | Flexible parametric CDF form. |
| Gamma | Parametric CDF, with different flexibility to Inverse Gamma. |
| GAM | Smooth per-measurement fit; `gam_k` controls wiggliness (lower it when there are few points). |
| HGAM | Hierarchical GAM; shares a group-level smooth across measurements while allowing individual deviations. Best when borrowing strength across subjects helps. |

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

## Whole Blood

Total radioactivity in whole blood over time. Whole blood models rarely make a large difference except when measurements are noisy or brain uptake is very low.

| Method | Notes |
|--------|-------|
| Interpolation | Linear interpolation (default; usually sufficient). |
| Splines | Flexible spline fit; useful when whole blood measurements are noisy and smoothing would help downstream modelling. |

## Model comparison

When the parent fraction method is set to `"Fit Individually: Choose the best-fitting model"`, bloodstream fits all individual parametric models (Hill, Exponential, Power, Sigmoid, Inverse Gamma, Gamma) to each measurement, computes AIC for each, and applies the model with the lowest total AIC across all measurements (for consistency). The AIC values are reported in the HTML report.
