# Changelog

## 0.2.1 (current)

- API cleanup: renamed `launch_bloodstream_app()` to `bloodstream_interactive()`
- Argument harmonisation: `config_file` to `configpath`, `analysis_folder` to `analysis_foldername` across all functions
- Default `analysis_foldername` changed from `"default"` to `"Primary_Analysis"` in `bloodstream_config_app()`
- Added Read the Docs documentation site

## 0.2.0

- Quarto-based report generation
- Docker container with interactive and non-interactive modes
- Shiny configuration app with pipeline execution support
- Standalone config creation mode (no BIDS data required)
- AIF weighting options (method weights, taper weights, weight schemes)
- Dispersion correction for whole blood autosampler samples
- HGAM (Hierarchical GAM) support for parent fraction and BPR

## 0.1.0

- Initial release
- BIDS blood data processing pipeline
- Parent fraction modelling (Hill, Exponential, Power, Sigmoid, Inverse Gamma, Gamma, GAM)
- BPR modelling (Constant, Linear, GAM)
- AIF modelling (Triexponential decay, Feng, FengConv, Splines)
- Whole blood modelling (Splines)
- R Markdown report generation
- JSON configuration system
