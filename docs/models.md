# Supported models

bloodstream supports a range of models for each blood component. When multiple methods are specified in the configuration, bloodstream compares them using AIC (Akaike Information Criterion) and selects the best-fitting model per measurement.

## Parent Fraction models

The parent fraction describes the proportion of radioactivity in plasma from the unmetabolised parent compound, typically declining over time.

### Interpolation

Linear interpolation of the observed data points. This is the default when no config file is provided. No model fitting is performed.

### Hill

A Hill function model. Suitable for parent fraction curves that follow a sigmoidal decay pattern. The Hill model is flexible and can capture a wide range of metabolite curve shapes.

### Exponential

An exponential decay model. Appropriate when the parent fraction decreases exponentially over time, which is common for many PET tracers.

### Power

A power function model. Can be useful for parent fraction curves where the rate of decline changes slowly over time.

### Sigmoid

A sigmoid (logistic) function model. Similar to the Hill model but with a different parameterisation. Works well for smooth, monotonically decreasing parent fraction curves.

### Inverse Gamma

An Inverse Gamma CDF model. Provides a flexible parametric form that can accommodate various shapes of parent fraction decline.

### Gamma

A Gamma CDF model. Another parametric option with different flexibility characteristics compared to the Inverse Gamma model.

### GAM

A Generalised Additive Model using smoothing splines. Fits a smooth curve to each measurement independently without assuming a specific parametric form. The basis dimension `k` controls the maximum wiggliness of the fit. Reduce `k` when there are few data points; increase it for more complex curves.

### HGAM

A Hierarchical Generalised Additive Model for group-level modelling. Fits a shared smooth across all measurements while allowing individual deviations. Best suited for studies with multiple measurements where borrowing strength across subjects improves estimation. Requires specifying an HGAM formula (e.g. `s(log(time), k=8) + s(log(time), pet, bs='fs', k=5)`).

## Blood-to-Plasma Ratio (BPR) models

The BPR describes the distribution of radioactivity between whole blood and plasma.

### Interpolation

Linear interpolation of the observed data points. Default method.

### Constant

A single mean value across all time points. Appropriate when the BPR is stable over time, which is the case for many tracers.

### Linear

A linear fit to the BPR over time. Suitable when there is a slow, steady trend in the BPR.

### GAM

A Generalised Additive Model. Appropriate for BPR curves with non-linear time dependence.

### HGAM

A Hierarchical GAM for group-level modelling of the BPR, analogous to the parent fraction HGAM.

## Arterial Input Function (AIF) models

The AIF describes the time course of radioactivity in arterial plasma after injection. AIF models should be used with caution as they can easily underfit the data for minimal gains.

### Interpolation

Linear interpolation of the observed data points. Default and often sufficient.

### Linear Rise, Triexponential Decay

A parametric model combining a linear rise phase with three exponential decay components. A classic input function model suitable for bolus injections.

### Feng

The Feng input function model. A widely used parametric model for arterial input functions with specific mathematical properties.

### FengConv

The Feng model convolved with the infusion duration. Required when the tracer was administered as a slow infusion rather than a bolus. The `inftime` parameter specifies the infusion duration in seconds.

### Splines

A flexible spline-based fit with separate basis functions before and after the peak. The `spline_kb`, `spline_ka_m`, and `spline_ka_a` parameters control the number of knots in different segments of the curve.

## Whole Blood models

The whole blood curve describes total radioactivity in whole blood over time. Models for whole blood rarely make a large difference except when measurements are noisy or brain uptake is very low.

### Interpolation

Linear interpolation of the observed data points. Default and usually sufficient.

### Splines

A flexible spline-based fit, with parameters analogous to the AIF spline model. Useful when whole blood measurements are noisy and smoothing would improve downstream pharmacokinetic modelling.

## Model comparison

When the configuration specifies `"Fit Individually: Choose the best-fitting model"` for the parent fraction, bloodstream automatically:

1. Fits all available individual models (Hill, Exponential, Power, Sigmoid, Inverse Gamma, Gamma) to each measurement
2. Computes AIC for each model-measurement combination
3. Selects the model with the lowest total AIC across all measurements
4. Applies that model to all measurements for consistency

The comparison results are reported in the HTML report, including AIC values for each model.
