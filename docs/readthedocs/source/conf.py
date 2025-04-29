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
    "colon_fence",  # Allows ::: for directives
    "html_admonition",  # Allows HTML admonitions
    "html_image",  # Allows HTML images
    "attrs_inline",  # Allows inline attributes
    "dollarmath",  # Enables $...$ and $$...$$
    "amsmath",     # Enables amsmath environments
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
html_theme_options = {
    "source_repository": "https://github.com/AlexDCode/AutomatedRadioEvaluationSuite",
    "source_branch": "main",
    "source_directory": "docs/readthedocs/source/",
    "navigation_with_keys": True,
    "top_of_page_buttons": ["view", "edit"],
    "footer_icons": [
        {
            "name": "GitHub",
            "url": "https://github.com/AlexDCode/AutomatedRadioEvaluationSuite",
            "html": """
                <svg stroke="currentColor" fill="currentColor" stroke-width="0"
                     viewBox="0 0 1024 1024" height="1.2em" width="1.2em"
                     xmlns="http://www.w3.org/2000/svg">
                     <path d="M511.6 76C263.3 76 60 279.3 60 527.6c0 199.4 129.3 368.6 
                     308.6 428.3 22.6 4.3 30.9-9.8 30.9-21.7v-84.6c-125.5 27.3-151.8-60.5-151.8-60.5
                     -20.6-52.2-50.3-66.1-50.3-66.1-41.2-28.2 3.1-27.6 3.1-27.6 45.6 3.2 69.6 46.8 
                     69.6 46.8 40.5 69.4 106.2 49.3 132 37.7 4.1-29.3 15.8-49.3 28.8-60.6
                     -100.2-11.4-205.5-50.1-205.5-222.9 0-49.2 17.6-89.4 46.5-120.9
                     -4.7-11.4-20.1-57.4 4.4-119.7 0 0 37.8-12.1 123.7 46.2a426 426 0 0 1 225.3 0
                     c85.8-58.3 123.6-46.2 123.6-46.2 24.6 62.3 9.2 108.3 4.5 119.7
                     28.9 31.5 46.4 71.7 46.4 120.9 0 173.2-105.5 211.3-205.9 222.5
                     16.2 13.9 30.6 41.3 30.6 83.2v123.3c0 12 8.2 26.2 31 21.7
                     179.1-59.7 308.3-228.9 308.3-428.2C963.2 279.3 759.9 76 511.6 76z"/>
                </svg>
                <span class="visually-hidden">GitHub</span>
            """,
            "class": "",
        },
    ],
}
