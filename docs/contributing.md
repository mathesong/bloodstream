# Contributing

Contributions are welcome! Please report issues or submit pull requests on [GitHub](https://github.com/mathesong/bloodstream).

## Development setup

1. Clone the repository:

   ```bash
   git clone https://github.com/mathesong/bloodstream.git
   cd bloodstream
   ```

2. Install the package in development mode:

   ```r
   # Install dependencies
   remotes::install_deps()

   # Load the package for development
   devtools::load_all()
   ```

3. Open the RStudio project (`bloodstream.Rproj`) for the best development experience.

## Repository structure

```
bloodstream/
├── R/                          # Package source code
│   ├── run_bloodstream.R       # Main pipeline function
│   ├── config_app.R            # Shiny configuration app
│   ├── launch_apps.R           # App launcher function
│   ├── modelling.R             # Model comparison functions
│   ├── plotting.R              # Visualisation functions
│   ├── qc.R                    # Quality control
│   ├── helper_funcs.R          # Utility functions
│   └── subsetting.R            # Data subsetting
├── man/                        # Auto-generated roxygen2 documentation
├── inst/qmd/                   # Quarto report template
├── inst/extdata/               # Default configuration
├── docker/                     # Docker configuration
├── docs/                       # Sphinx documentation (this site)
├── DESCRIPTION                 # R package metadata
├── NAMESPACE                   # Exported functions
└── CLAUDE.md                   # Developer architecture guide
```

## Coding standards

### Tidyverse conventions

bloodstream follows tidyverse conventions:

- Use `tibble()` instead of `data.frame()`
- Use tidyverse functions for data manipulation (`dplyr`, `stringr`, `purrr`)
- Use `readr::read_tsv()` and `readr::write_tsv()` for file I/O

### Documentation

Functions use roxygen2 documentation. After modifying function documentation, regenerate with:

```r
devtools::document()
```

### Spelling

Use British English: "modelling" not "modeling", "colour" not "color".

## Testing

Run the package check:

```r
devtools::check()
```

## Docker development

Build and test the Docker image locally:

```bash
# Build from the repository root (not the docker/ subdirectory)
docker build -f docker/dockerfile -t mathesong/bloodstream:latest . --platform linux/amd64

# Test interactive mode
docker run -p 3838:3838 mathesong/bloodstream:latest --mode interactive
```

## Building documentation

The documentation uses Sphinx with MyST (Markdown):

```bash
pip install -r docs/requirements.txt
cd docs
make html
# Open _build/html/index.html in your browser
```

When making code changes, please update the relevant documentation pages as well.
