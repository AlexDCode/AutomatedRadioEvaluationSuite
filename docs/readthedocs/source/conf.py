# Configuration file for the Sphinx documentation builder.
# Build with: python3.9 -m sphinx -b html docs/readthedocs/source/ docs/readthedocs/build/
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'ARES'
copyright = '2025, Alex D. Santiago-Vargas, José Abraham Bolaños Vargas'
author = 'Alex D. Santiago-Vargas, José Abraham Bolaños Vargas'
release = '1.0'
ARES_logo = './../../../src/support/ARES Icon.png'
ARES_favicon = './../../../src/support/ARES Icon.png'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.mathjax',  # For HTML math rendering
    'myst_parser',         # If you use Markdown (MyST)
]
templates_path = ['_templates']
exclude_patterns = []

myst_enable_extensions = [
    "attrs_inline",  # Allows inline attributes
    "amsmath",     # Enables amsmath environments
    "colon_fence",  # Allows ::: for directives
    "dollarmath",  # Enables $...$ and $$...$$
    "html_admonition",  # Allows HTML admonitions
    "html_image",  # Allows HTML images
]

latex_engine = 'pdflatex'

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'furo'
html_static_path = ['_static']
html_logo = ARES_logo
html_favicon = ARES_favicon
html_title = "ARES"
master_doc = "index"
html_additional_pages = {"index": "home.html"}
html_theme_options = {
    "source_repository": "https://github.com/AlexDCode/AutomatedRadioEvaluationSuite",
    "source_branch": "main",
    "source_directory": "docs/readthedocs/source/",
    "navigation_with_keys": True,
    "top_of_page_buttons": ["view"],
    "sidebar_hide_name": True,
    "light_css_variables": {
        "color-brand-primary": "#245A80",
        "color-brand-content": "#E2712D",
    },
    "dark_css_variables": {
        "color-brand-primary": "#245A80",
        "color-brand-content": "#E2712D",
    },

    "footer_icons": [
        {
            "name": "GitHub",
            "url": "https://github.com/AlexDCode/AutomatedRadioEvaluationSuite",
            "html": "",
            "class": "fa-brands fa-solid fa-github fa-2x",
        },
    ],
}

# -- Options for LaTeX output -------------------------------------------------
# https://sphinx-themed.readthedocs.io/en/latest/latex.html
latex_elements = {
    'preamble': r'''
    \usepackage{titlesec}
    \titleformat{\chapter}[display]
    {\normalfont\huge\bfseries} % Format
    {\chaptername\ \thechapter} % Label
    {20pt}                      % Separation
    {\centering}             % Alignment (use \centering for center)
    ''',
}
