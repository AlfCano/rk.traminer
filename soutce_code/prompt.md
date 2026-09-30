# The Golden Rules of RKWard Plugin Development (v4.1)

*Comprehensive guidelines for `rkwarddev` (0.10-3+) based on real-world debugging and advanced architectural design.*

## Part I: The Core Architecture

### 1. The R Script is the Single Source of Truth
Your output is always a single R script wrapped in `local({})`.
*   **Never** manually edit the generated `.xml`, `.js`, or `.pluginmap` files.
*   If you need to change something, change the generator script and regenerate.
*   **Structure:**
    1.  `require(rkwarddev)`
    2.  Metadata definition (`rk.XML.about`).
    3.  UI Component definitions.
    4.  JavaScript Logic (`calculate`, `printout`, `preview`).
    5.  Skeleton assembly (`rk.plugin.skeleton`).

### 2. The Hierarchy Case-Sensitivity Rule
RKWard's internal menu IDs are **case-sensitive** and predefined.
*   **Standard Menus:** `"data"`, `"analysis"`, `"plots"`, `"distributions"`.
*   **The Trap:** If you use `"Data"` (capital D), RKWard treats it as a custom menu (falling back to "Test") or creates a duplicate top-level menu.
*   **Correct:** `hierarchy = list("data", "My Submenu")`.

### 3. The `calculate` / `saveobj` Contract (The "Hardcoding" Rule)
This is the most frequently broken rule. RKWard handles variable assignment internally.
*   **The Rule:** The R object name generated inside the `calculate` block **must** be the hardcoded string defined in the `initial` argument of `rk.XML.saveobj`.
*   **The Trap:** Do not read the value of the save object to name your variable in the calculation phase.
*   **Correct Pattern:**
    *   XML: `my_save <- rk.XML.saveobj(..., initial = "my_result", id.name = "save_ui")`
    *   JS (`calculate`): `echo("my_result <- some_function(...)")`
    *   JS (`printout`): `echo("rk.header('Saved to: " + getValue("save_ui") + "')")`

---

## Part II: Internationalization (i18n)

### 4. The `po_id` Generation Logic
RKWard determines the "text domain" (translation ID) based on the **Plugin Map Name**, not the package name.
*   **Logic:** It strips spaces and special characters, CamelCases the string, and appends `_rkward`.
    *   Name: `"Survey Batch Transform"` -> ID: `SurveyBatchTransform_rkward`
*   **The Trap:** Do not manually pass `po_id` to `rk.plugin.skeleton()` in newer `rkwarddev` versions, as it throws an "unused argument" error. Let the system derive it automatically.

### 5. The Binary File Naming Convention
The compiled translation file (`.mo`) must match the `po_id` exactly.
*   **Format:** `rkward__[po_id].mo`
*   **Example:** `inst/rkward/po/es/LC_MESSAGES/rkward__SurveyBatchTransform_rkward.mo`
*   **Failure Mode:** If the filename does not match the internal ID, the translation will simply not load, with no error message.

### 6. The Manual Fallback Strategy
Automatic message extraction (`rk.updatePluginMessages`) often fails on Windows due to system dependency paths.
*   **Strategy:** Manually create the `.po` file (text), populate it with `msgid` (original) and `msgstr` (translated), compile it with **Poedit** (or `msgfmt` in Linux), and place the `.mo` file in the structure manually.

---

## Part III: Robust JavaScript Generation

### 7. The Quote Escaping Strategy (Single vs. Double)
When generating R code via JavaScript, you are nesting strings three levels deep.
*   **The Problem:** `echo("data[[\"" + var + "\"]]")` requires escaping double quotes inside a string that is inside another string. It is error-prone ("Backslash Hell").
*   **The Solution:** Use **Single Quotes** for R syntax where possible, and properly escape internal double quotes (`\\"`).

### 8. Variable Name Safety
Never assume a user's variable name is "safe" (no spaces, no special chars).
*   **The Rule:** Always quote variable names when passing them to R functions. For tidyverse/formulas, wrap them in backticks. For standard subsetting, use quoted strings.
*   **JS Helper Pattern:** Strip extraneous `[[` and `$` syntax using a custom `getRawCol(fullName)` JS parser function before generating the R code.

### 9. Preview Logic Stability & Output Spam
Previews run in a detached, clean R environment, but they execute *the entire code block* every time a parameter changes.
*   **Requirement 1:** You must re-`require()` any packages inside the preview block.
*   **Requirement 2 (The Output Spam):** Always wrap text outputs (`rk.header()`, `rk.results()`) and object saving (`my_plot <- p`) inside an `if (!is_preview) { ... }` block in your JavaScript `printout` logic. Otherwise, RKWard will spam the user's Output Window with duplicate text every time they tweak a setting during preview.

---

## Part IV: UI & Layout

### 10. The Tabbook Standard
For plugins with more than 3-4 input parameters:
*   **Use `rk.XML.tabbook`** to organize UI.
*   **Tab 1 (Variables):** Source selector and variable slots.
*   **Tab 2 (Settings/Rules):** Checkboxes, dropdowns, matrices.
*   **Tab 3 (Output):** Naming patterns, Save object, Preview button (or Graphics Device settings).

### 11. The "Auto-Focus" Magic (Standard vs. Complex Objects)
To drastically improve UX, the variable selector (left panel) should instantly filter to show *only* the columns of the dataset selected in the target `varslot`. How you achieve this depends on the object type:

*   **For Standard Dataframes (`data.frame`):**
    Connect the dataframe slot's `.available` property to the selector's `.root` property using standard XML logic.
    *   **The Trap:** Writing `governor = "my_df.available"` causes XML parsing bugs in `rkwarddev`. Explicitly use the `get` and `set` arguments.
    ```R
    # Standard Dataframe Auto-Focus
    rk.XML.logic(
        rk.XML.connect(governor = my_df, get = "available", client = my_selector, set = "root")
    )
    ```

*   **For Complex Objects (e.g., `survey.design`):**
    Complex objects hide their columns in internal sub-lists (like `my_survey$variables`). XML `<connect>` nodes only copy text 1:1; they cannot append strings to reach this sub-list.
    *   **The Solution:** Inject an advanced GUI Script (`<script>`) that listens for changes and dynamically concatenates `"$variables"` to the root using Javascript.
    ```R
    # Complex Object Auto-Focus
    gui_script <- XiMpLe::XMLNode("script", '
      gui.addChangeCommand("svy_object.available", "update_root()");
      function update_root() {
         var obj = gui.getValue("svy_object.available");
         if (obj !== "") {
            gui.setValue("svy_selector.root", obj + "$variables");
         } else {
            gui.setValue("svy_selector.root", "");
         }
      }
    ')
    rk.XML.logic(gui_script)
    ```

---

## Part V: Performance & Memory Management

### 12. The "Silent Killer" of Memory (`ggplot2` Environments)
A seemingly innocent 50KB plot can bloat an `.RData` workspace to 500MB+ if generated inside a plugin.
*   **The Cause:** RKWard plugins run inside a `local({})` environment. `ggplot2`'s `aes()` function captures a *quosure* (a snapshot) of the entire local environment when the plot is created. This traps raw, massive micro-datasets (like `svydesign` or census data) inside the plot object's backpack (`p$plot_env`).
*   **The Cure (The 3-Step Strategy):**
    1.  **Structural Pre-computation:** Never feed raw microdata to `ggplot()`. Use `survey::svytable()` for bars, `survey::svyby()` for boxplots, or isolate a micro-dataframe (only extracting the 2 or 3 required columns) *before* plotting. Filter out structural zeros (`%>% dplyr::filter(Freq > 0)`).
    2.  **Empty the Backpack:** Explicitly destroy the captured environment in the generated R code before saving the plot.
        ```R
        p$plot_env <- emptyenv()
        ```
    3.  **The Broom (Garbage Collection):** Delete any heavy intermediate dataframes from the local environment right before passing the plot to the global workspace, ensuring `aes()` captures an empty room.
        ```R
        rm(list = intersect(ls(), c("svy_filtered", "plot_data")))
        gc()
        ```
