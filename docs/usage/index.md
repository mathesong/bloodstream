# Usage guide

bloodstream provides a single pipeline for processing BIDS blood data for PET imaging.

## The workflow

Every bloodstream analysis follows this flow:

1. **Input** — BIDS blood sampling data (discrete and/or continuous samples).
2. **Configure** — Choose modelling approaches for each blood component (parent fraction, BPR, AIF, whole blood).
3. **Process** — Fit models (or apply linear interpolation) and generate processed blood curves.
4. **Output** — TSV files for pharmacokinetic modelling, JSON sidecars, and an HTML report.

## Interactive vs automatic mode

Both modes produce identical results. The difference is how you interact with the pipeline.

**Interactive mode** launches a Shiny web app in your browser. You configure modelling choices for each blood component using a graphical interface, preview data, and optionally run the pipeline. The app generates a JSON configuration file that records all your choices.

**Automatic mode** reads an existing JSON configuration file and runs the pipeline without any user interaction. Running without a config file applies linear interpolation to all components. This is designed for batch processing, HPC clusters, and reproducible workflows.

A common workflow is to use interactive mode once to create and validate your configuration, then switch to automatic mode for production runs.

## Configuration files

The interactive app generates JSON configuration files that record every modelling choice — data subsets, model selections, time ranges, and model parameters. These files make analyses fully reproducible.

You do not need to write configuration files by hand. Use the interactive app to create and validate your configuration, then reuse the config file in automatic mode.

See the [Configuration guide](configuration.md) for full details on the config file structure.

## Analysis folders

bloodstream writes outputs into analysis-specific subfolders within `derivatives/bloodstream/`. The default folder is called `Primary_Analysis`, but you can create as many as you like with descriptive names (e.g. `GAM_ParentFraction`, `Spline_AIF`, `Linear_Only`).

Each analysis folder contains its own report, config file, and per-measurement output files.

```{toctree}
:maxdepth: 2

configuration
```
