# rk.traminer: Sequence Analysis & Trajectory Mining for RKWard

![Version](https://img.shields.io/badge/Version-0.0.2-blue.svg)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.traminer/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.traminer/actions/workflows/lintr.yml)

**rk.traminer** brings the power of Sequence Analysis (Life-course trajectories) to the RKWard GUI. It provides a highly optimized, user-friendly interface for the gold-standard [`TraMineR`](http://traminer.unige.ch/) package. By integrating [`ggseqplot`](https://maraab23.github.io/ggseqplot/) and `patchwork`, it completely modernizes the visual output, allowing researchers in sociology, demography, and economics to easily construct state sequence objects and render stunning, publication-ready dashboards.

## 🚀 What's New in Version 0.0.2

**🧬 Sequence Clustering & Typology Generation**

*   **New Component - Sequence Clustering:** Added a powerful new module to discover hidden patterns in longitudinal data. It groups similar life trajectories using **Optimal Matching (Constant Cost)** distances and **Ward's Hierarchical Clustering** natively from the GUI.
*   **Automated Cross-Tabulation:** Easily profile your discovered clusters by selecting covariates (e.g., gender, income, region). The plugin automatically generates HTML cross-tabulations to reveal the demographic or structural composition of each trajectory typology.
*   **Dual Visual Diagnostics:** Toggle instantly between a classic **Hierarchical Dendrogram** (to visually justify your chosen number of clusters, $k$) and a modern **State Distribution Plot by Cluster** powered by `ggseqplot` and faceted automatically.
*   **Smart Data Management:** Seamlessly append the resulting cluster assignments directly to your original dataframe as a new factor variable with a single click. You can also export the mathematical clustering model (`hclust`) and the `ggplot2` distribution plots to your Global Environment for downstream reporting.
*   **TidySelect Integration:** The highly praised Smart Column Selection assistant (`starts_with`, `ends_with`, etc.) has been fully integrated into the Clustering component, preventing the need to manually drag dozens of chronological variables.

## 🚀 What's New in Version 0.0.1 (Initial Release)

*   **Modern ggplot2 Visuals:** Bypassed TraMineR's legacy base-R graphics. The plugin natively bridges `seqdef` objects with `ggseqplot`, rendering highly customizable, modern `ggplot2` charts.
*   **Dynamic Grid Layouts:** Utilizes the `patchwork` package to automatically assemble selected plots into a smart, mathematically aligned grid layout, perfect for RKWard's live Preview window.
*   **Aggressive Memory Optimization:** Implemented advanced R environment pruning (`p$plot_env <- emptyenv()` and `rm()`). This guarantees that heavy survey databases aren't secretly trapped inside the graphical objects, keeping saved plots ultra-lightweight (~15 KB instead of hundreds of MBs).
*   **Tidyselect Integration:** Interactive `dplyr` tidyselect assistant. Users can choose `starts_with()`, `ends_with()`, `contains()`, or `matches()` from a dropdown menu. The plugin automatically generates the correct syntax and handles string quoting, drastically lowering the barrier to entry for beginners while keeping a "Custom" option for advanced R users.
*   **UI Logic Polish:** The assistant's text box uses RKWard XML logic to dynamically appear or hide based on the user's selection, keeping the interface clean and preventing syntax errors.

## ✨ Features

### 1. Smart Sequence Definition
*   **Missing Data Mastery:** Real-world longitudinal data is full of gaps. Easily define how to handle missing data *before* the sequence starts (`left`), *during* the sequence (`gaps`), and *after* the sequence ends (`right`). Choose to delete/ignore gaps (`"DEL"`) to align trajectories of different lengths, or treat them as missing information (`"NA"`).
*   **Tidy Variable Parsing:** Safely parses columns using `dplyr` backends, automatically wrapping variable names in backticks to prevent syntax errors when handling special characters.

### 2. Multi-Plot Visual Dashboard
Select any combination of the following foundational Sequence Analysis plots. The plugin will automatically stitch them together into a single dashboard:
*   **State Distribution Plot:** Visualizes the cross-sectional state frequencies at each time point (`seqdplot`).
*   **Sequence Frequency Plot:** Displays the "Top 10" most common exact trajectories in your dataset (`seqfplot`).
*   **Sequence Index Plot:** Draws individual horizontal lines for each subject, dynamically sorted from their starting state (`seqIplot`).
*   **Mean Time Plot:** Shows the average number of events/time spent by subjects in each state (`seqmtplot`).

### 🛡️ Universal Features
*   **Live Preview:** Instantly preview your full trajectory dashboard before processing the final object.
*   **Dual Saving Output:** Upon submission, the plugin automatically saves both the generated `ggplot` grid object AND the mathematical `seqdef` object to your Global Environment, making it ready for downstream transition matrix analysis or clustering.
*   **Internationalization:** Fully localized interface available in:
    *   🇺🇸 English (Default)
    *   🇪🇸 Spanish (`es`)
    *   🇫🇷 French (`fr`)
    *   🇩🇪 German (`de`)
    *   🇧🇷 Portuguese (Brazil) (`pt_BR`)

## 📦 Installation

This plugin is not yet on CRAN. To install it, use the `remotes` or `devtools` package in RKWard.

1.  **Open RKWard**.
2.  **Run the following command** in the R Console:

    ```R
    # If you don't have remotes installed:
    # install.packages("remotes")
    
    local({
      require(remotes)
      install_github("AlfCano/rk.traminer", force = TRUE)
    })
    ```
3.  **Restart RKWard** to load the new menu entries.

## 💻 Usage

Once installed, the tool is organized under the **Plots** menu:

**`Plots` -> `Sequence Analysis (TraMineR)` -> `Sequence Dashboard`**

1. Select your dataframe.
2. Define your chronological state variables (e.g., using `starts_with()`).
3. Set your gap-handling rules.
4. Check the plots you want to render and click **Submit**.

## 🛠️ Dependencies

This plugin relies on the following R packages:
*   `TraMineR` (Core sequence math)
*   `ggseqplot` (ggplot2 wrapper for TraMineR)
*   `patchwork` (Plot grid assembly)
*   `dplyr` (Variable selection)
*   `rkwarddev` (Plugin generation)

#### Troubleshooting: Errors installing `devtools` or missing binary dependencies (Windows)

If you encounter errors mentioning "non-zero exit status", "namespace is already loaded", or requirements for compilation (compiling from source) when installing packages, it is likely because the R version bundled with RKWard is older than the current CRAN standard.

**Workaround:**
Until a new, more recent version of R (current bundled version is 4.3.3) is packaged into the RKWard executable, these issues will persist. To fix this:

1.  Download and install the latest version of R (e.g., 4.5.2 or newer) from [CRAN](https://cloud.r-project.org/).
2.  Open RKWard and go to the **Settings** (or Preferences) menu.
3.  Run the **"Installation Checker"**.
4.  Point RKWard to the newly installed R version.

This "two-step" setup (similar to how RStudio operates) ensures you have access to the latest pre-compiled binaries, avoiding the need for RTools and manual compilation.

## ✍️ Author & License

*   **Author:** Alfonso Cano (<alfonso.cano@correo.buap.mx>)
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)
