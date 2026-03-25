# Building the documentation locally

The bloodstream documentation uses [Sphinx](https://www.sphinx-doc.org/) with [MyST Parser](https://myst-parser.readthedocs.io/) for Markdown support.

## Prerequisites

- Python 3.10+
- pip

## Setup

Install the required Python packages:

```bash
pip install -r docs/requirements.txt
```

## Building

From the `docs/` directory:

```bash
cd docs
make html
```

The built site will be in `docs/_build/html/`. Open `docs/_build/html/index.html` in your browser to preview.

## Live rebuild during editing

For a live-reloading development server, install `sphinx-autobuild`:

```bash
pip install sphinx-autobuild
sphinx-autobuild docs docs/_build/html
```

Then open `http://127.0.0.1:8000` in your browser. Pages will automatically rebuild and refresh when you save changes.

## Cleaning

To remove all build artifacts and start fresh:

```bash
cd docs
make clean
```
