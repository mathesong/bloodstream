# bloodstream: A BIDS App for PET Blood Processing

bloodstream is a [BIDS App](https://bids-apps.neuroimaging.io/) for processing blood data for PET imaging. It takes blood sampling data in [BIDS](https://bids-specification.readthedocs.io/) format and produces parameterised reports along with processed blood derivatives for pharmacokinetic modelling.

```{note}
bloodstream is currently in active development (v0.2.1). If you encounter any bugs, please report them on the [GitHub issues page](https://github.com/mathesong/bloodstream/issues) — they are extremely valuable for making this pipeline robust.
```

For a short introduction to processing blood data for PET, as well as a tutorial for how to use bloodstream, see the [explainer video](https://www.youtube.com/watch?v=Kud6MWYPKxg).

## How it works

bloodstream can be used in two ways:

- **Interactive mode**: Use a Shiny web application to configure modelling choices for each blood component, preview data, and optionally run the pipeline. The app generates a JSON configuration file that records all your choices.
- **Automatic mode**: Run the pipeline non-interactively using a pre-defined configuration file. This is ideal for batch processing and HPC environments. Running without a config file applies linear interpolation to all blood components.

## Getting started

::::{grid} 2
:gutter: 3

:::{grid-item-card} Installation
:link: installation
:link-type: doc

Pull the Docker image, install the R package, or build an Apptainer container.
:::

:::{grid-item-card} Quick start
:link: quickstart
:link-type: doc

A minimal end-to-end example to get you up and running.
:::

:::{grid-item-card} Configuration
:link: usage/configuration
:link-type: doc

Full guide to the config.json file and all modelling options.
:::

:::{grid-item-card} Outputs
:link: outputs
:link-type: doc

What files bloodstream produces and how they are organised.
:::

::::


```{toctree}
:maxdepth: 2
:caption: Getting Started

installation
quickstart
```

```{toctree}
:maxdepth: 2
:caption: User Guide

usage/index
containers/index
outputs
models
```

```{toctree}
:maxdepth: 2
:caption: Reference

troubleshooting
api
citation
changes
license
```

```{toctree}
:maxdepth: 2
:caption: Development

contributing
```
