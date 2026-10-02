# rk.traminer: Sequence Analysis & Trajectory Mining for RKWard

![Version](https://img.shields.io/badge/Version-0.0.3-blue.svg)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.traminer/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.traminer/actions/workflows/lintr.yml)

**rk.traminer** brings the power of Sequence Analysis (Life-course trajectories) to the RKWard GUI. It provides a highly optimized, user-friendly interface for the gold-standard [`TraMineR`](http://traminer.unige.ch/) package. By integrating [`ggseqplot`](https://maraab23.github.io/ggseqplot/) and `patchwork`, it completely modernizes the visual output, allowing researchers in sociology, demography, and economics to easily construct state sequence objects and render stunning, publication-ready dashboards and complexity analysis.

---

## 🚀 What's New in Version 0.0.3

**🧠 Analytical Power & Data-Driven Costs**

*   **Extract Complexity Metrics:** A new module to calculate longitudinal indicators (Turbulence, Entropy, Transitions, Complexity Index) and automatically append them as numeric columns to your dataframe for regression analysis.
*   **Transition Matrices:** Calculate Markov-chain transition probabilities (`seqtrate`) to analyze state-to-state movements.
*   **Data-Driven Clustering:** The Clustering component now supports Data-Driven Transition Rates (`TRATE`) as the Substitution Cost Method, ensuring highly accurate Optimal Matching (OM) distances.

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

---

## ✨ Features

### 1. Smart Sequence Definition & Dashboard
*   **Tidy Variable Selection:** Easily select dozens of chronological states without manual clicking using the built-in `tidyselect` assistant (e.g., `starts_with("job_")`).
*   **Missing Data Mastery:** Natively handle left, internal (`gaps`), and right missing data. Choose to delete/ignore gaps (`"DEL"`) to align trajectories of different lengths, or treat them as missing information (`"NA"`).
*   **Modern Visual Dashboard:** Generates a unified, `patchwork`-assembled grid of `ggseqplot` charts (State Distribution, Frequencies, Index, and Mean Time plots) optimized for RKWard's live Preview.

### 2. Sequence Clustering & Typologies
*   **Optimal Matching (OM):** Group similar life trajectories using Ward's Hierarchical Clustering with Constant (`CONSTANT`) or Data-driven (`TRATE`) substitution costs.
*   **Automated Profiling:** Select covariates (e.g., gender, age, income) to instantly generate HTML cross-tabulations profiling your newly discovered trajectory clusters.
*   **Dual Visual Diagnostics:** Toggle between a classic **Hierarchical Dendrogram** to visually justify your chosen number of clusters ($k$), or a modern faceted **State Distribution Plot**.
*   **Seamless Integration:** Automatically append the resulting cluster assignments back to your original dataframe as a new factor variable.

### 3. Extract Sequence Indicators
*   **Quantify Life-Courses:** Calculate individual longitudinal metrics to measure how chaotic or stable a trajectory is, including **Turbulence (`seqST`)**, **Longitudinal Entropy (`seqient`)**, and **Complexity Index (`seqici`)**.
*   **Ready for Modeling:** These metrics are perfectly extracted as continuous numeric vectors and safely appended to your dataset, making them instantly available for ANOVA or Logistic Regressions.

### 4. Transition Rates Matrix
*   **Markov Probabilities:** Calculate the exact mathematical probability of moving from State A (row) to State B (column) in the next consecutive time period.
*   **Clean Reporting:** The matrix is converted and printed as a clean, presentation-ready HTML table, while saving the raw matrix to your Global Environment for downstream Network Analysis mapping.

---

### 🛡️ Universal Features
*   **Live Preview:** Instantly preview your full trajectory dashboard before processing the final object.
*   **Dual Saving Output:** Upon submission, the plugin automatically saves both the generated `ggplot` grid object AND the mathematical `seqdef` object to your Global Environment, making it ready for downstream transition matrix analysis or clustering.
*   **Internationalization:** Fully localized interface available in:
    *   🇺🇸 English (Default)
    *   🇪🇸 Spanish (`es`)
    *   🇫🇷 French (`fr`)
    *   🇩🇪 German (`de`)
    *   🇧🇷 Portuguese (Brazil) (`pt_BR`)
    
---

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

---

## 💻 Usage

Once installed, the tool is organized under the **Plots** menu:

**`Plots` -> `Sequence Analysis (TraMineR)` -> `Sequence Dashboard`**

1. Select your dataframe.
2. Define your chronological state variables (e.g., using `starts_with()`).
3. Set your gap-handling rules.
4. Check the plots you want to render and click **Submit**.

---

## 🛠️ Dependencies

This plugin relies on the following R packages:
*   `TraMineR` (Core sequence math)
*   `ggseqplot` (ggplot2 wrapper for TraMineR)
*   `patchwork` (Plot grid assembly)
*   `dplyr` (Variable selection)
*   `rkwarddev` (Plugin generation)

---

#### Troubleshooting: Compilation errors or missing binary dependencies (Windows)

If you encounter errors mentioning "non-zero exit status", "namespace is already loaded", or prompts asking you to compile packages from source (which subsequently fail), this typically happens when the R version bundled with your RKWard Windows installer is slightly behind the current CRAN standard.

CRAN provides easy-to-install, pre-compiled binaries primarily for the latest R versions. To bypass the need for manual compilation and RTools:

1.  **Update R:** Download and install the latest stable version of R directly from [CRAN](https://cloud.r-project.org/).
2.  **Link to RKWard:** Open RKWard, navigate to the **Settings** (or Preferences) menu, and run the **"Installation Checker"**.
3.  **Switch the Engine:** Point RKWard to the newly installed R executable (e.g., `C:\Program Files\R\R-4.x.x`).

This standard "two-step" setup (updating R independently of RKWard) guarantees you always have access to the latest pre-compiled binaries, keeping your plugin installations smooth and error-free.


---

## ✍️ Author & License

*   **Author:** Alfonso Cano (<alfonso.cano@correo.buap.mx>)
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)
