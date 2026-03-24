# Configuration file for the Sphinx documentation builder.
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------

project = "bloodstream"
copyright = "2025, Granville Matheson"
author = "Granville Matheson"
version = "0.2"
release = "0.2.1"

# -- General configuration ---------------------------------------------------

extensions = [
    "myst_parser",
    "sphinx_rtd_theme",
    "sphinx_copybutton",
    "sphinx_design",
    "sphinx.ext.intersphinx",
]

# MyST parser configuration
myst_enable_extensions = [
    "colon_fence",
    "deflist",
    "fieldlist",
    "substitution",
    "tasklist",
]

myst_heading_anchors = 3

# Source file configuration
source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

# -- Options for HTML output -------------------------------------------------

html_theme = "sphinx_rtd_theme"
html_theme_options = {
    "logo_only": False,
    "prev_next_buttons_location": "bottom",
    "style_external_links": True,
    "navigation_depth": 3,
    "collapse_navigation": False,
    "sticky_navigation": True,
}

html_static_path = ["_static"]
html_css_files = ["custom.css"]

html_context = {
    "display_github": True,
    "github_user": "mathesong",
    "github_repo": "bloodstream",
    "github_version": "main",
    "conf_py_path": "/docs/",
}

# -- Options for intersphinx -------------------------------------------------

intersphinx_mapping = {}

# -- Copybutton configuration ------------------------------------------------

copybutton_prompt_text = r">>> |\.\.\. |\$ |> |# "
copybutton_prompt_is_regexp = True
copybutton_remove_prompts = True
