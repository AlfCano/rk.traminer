local({
  # =========================================================================================
  # 1. Package Definition and Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.10-3")

  package_about <- rk.XML.about(
    name = "rk.traminer",
    author = person(given = "Alfonso", family = "Cano", email = "alfonso.cano@correo.buap.mx", role = c("aut", "cre")),
    about = list(
      desc = "An RKWard GUI plugin for Sequence Analysis and Trajectory mining using TraMineR.",
      version = "0.0.3",
      url = "https://github.com/AlfCano/rk.traminer",
      license = "GPL (>= 3)"
    )
  )

  h_seq <- list("plots", "Sequence Analysis (TraMineR)")

  # =========================================================================================
  # 2. UI Helpers (JS Parser and Device Tab Generator)
  # =========================================================================================
  js_parse_col <- "
    function getRawCol(fullPath) {
        if (!fullPath) return '';
        var raw = fullPath;
        if (raw.indexOf('[[') > -1) {
             raw = raw.split('[[')[1].replace(']]', '').replace(/[\\\"']/g, '');
        } else if (raw.indexOf('$') > -1) {
             raw = raw.split('$')[1];
        }
        return raw;
    }
    function getSafeCol(fullPath) {
        var raw = getRawCol(fullPath);
        if (!raw) return '';
        return '`' + raw + '`';
    }
    function getArrayCols(vars) {
        if(!vars) return [];
        var arr = vars.split('\\n');
        return arr.map(function(v) { return getSafeCol(v); });
    }
  "

  make_device_tab <- function(prefix, initial_save, show_save = TRUE) {
    elements <- list(
      rk.XML.frame(label = "Graphics Device",
          rk.XML.dropdown(label = "Device type", id.name = paste0(prefix, "_dev_type"), options = list("PNG" = list(val = "PNG", chk = TRUE), "SVG" = list(val = "SVG"))),
          rk.XML.row(
              rk.XML.spinbox(label = "Width (px)", id.name = paste0(prefix, "_dev_w"), min = 100, max = 4000, initial = 1024),
              rk.XML.spinbox(label = "Height (px)", id.name = paste0(prefix, "_dev_h"), min = 100, max = 4000, initial = 1024)
          ),
          rk.XML.col(
             rk.XML.spinbox(label = "Resolution (ppi)", id.name = paste0(prefix, "_dev_res"), min = 50, max = 600, initial = 150),
             rk.XML.dropdown(label = "Background", id.name = paste0(prefix, "_dev_bg"), options = list("Transparent" = list(val = "transparent", chk = TRUE), "White" = list(val = "white")))
          )
      )
    )
    if(show_save) {
      elements[[length(elements) + 1]] <- rk.XML.saveobj(label = "Save Object As", initial = initial_save, id.name = paste0(prefix, "_save"), chk = TRUE)
    }
    elements[[length(elements) + 1]] <- rk.XML.preview(id.name = paste0(prefix, "_preview"))
    do.call(rk.XML.col, elements)
  }

  # =========================================================================================
  # COMPONENT 1: Sequence Dashboard (Tu código original)
  # =========================================================================================
  c1_sel <- rk.XML.varselector(id.name = "c1_sel")
  c1_df  <- rk.XML.varslot("Select Dataframe", source = "c1_sel", classes = "data.frame", required = TRUE, id.name = "c1_df")
  c1_vars <- rk.XML.varslot("Variables (Sequence states over time)", source = "c1_sel", multi = TRUE, required = FALSE, id.name = "c1_vars")
  c1_helper_mode <- rk.XML.dropdown("Smart Column Selection (tidyselect)", id.name = "c1_helper_mode", options = list("None" = list(val = "none", chk = TRUE), "starts_with()" = list(val = "starts_with"), "ends_with()" = list(val = "ends_with"), "contains()" = list(val = "contains"), "matches()" = list(val = "matches"), "Custom" = list(val = "custom")))
  c1_helper_val <- rk.XML.input("Value / Pattern", id.name = "c1_helper_val")
  c1_helper_frame <- rk.XML.frame(rk.XML.col(c1_helper_mode, c1_helper_val), label = "Advanced Select", id.name = "c1_helper_frame")
  c1_id <- rk.XML.varslot("Identifier (Optional)", source = "c1_sel", id.name = "c1_id")
  show_helper_val <- rk.XML.convert(sources = list("c1_helper_mode.string"), mode = c(notequals = "none"), id.name = "show_helper_val")
  c1_logic <- rk.XML.logic(show_helper_val, rk.XML.connect(governor = c1_df, get = "available", client = c1_sel, set = "root"), rk.XML.connect(governor = "show_helper_val", client = "c1_helper_val.visible"))
  c1_left  <- rk.XML.dropdown("Left gaps", options = list("DEL" = list(val = "DEL", chk = TRUE), "NA" = list(val = "NA")), id.name = "c1_left")
  c1_void  <- rk.XML.dropdown("Void gaps", options = list("DEL" = list(val = "DEL", chk = TRUE), "NA" = list(val = "NA")), id.name = "c1_void")
  c1_right <- rk.XML.dropdown("Right gaps", options = list("DEL" = list(val = "DEL", chk = TRUE), "NA" = list(val = "NA")), id.name = "c1_right")
  c1_p_dist  <- rk.XML.cbox("State Distribution Plot", value = "TRUE", chk = TRUE, id.name = "c1_p_dist")
  c1_p_freq  <- rk.XML.cbox("Sequence Frequency Plot", value = "TRUE", chk = TRUE, id.name = "c1_p_freq")
  c1_p_idx   <- rk.XML.cbox("Sequence Index Plot", value = "TRUE", chk = TRUE, id.name = "c1_p_idx")
  c1_p_time  <- rk.XML.cbox("Mean Time Plot", value = "TRUE", chk = TRUE, id.name = "c1_p_time")

  dialog_dash <- rk.XML.dialog(label = "Sequence Analysis Dashboard", child = rk.XML.row(c1_sel, rk.XML.col(c1_df, rk.XML.tabbook(tabs = list(
      "Data & Variables" = rk.XML.col(c1_vars, c1_helper_frame, rk.XML.frame(c1_id, label="Metadata"), rk.XML.stretch()),
      "Missing Data Handling" = rk.XML.col(c1_left, c1_void, c1_right, rk.XML.stretch()),
      "Dashboard Plots" = rk.XML.col(c1_p_dist, c1_p_freq, c1_p_idx, c1_p_time, rk.XML.stretch()),
      "Output" = make_device_tab(prefix = "c1", initial_save = "tray_seq", show_save = TRUE)
  )))))

  js_calc_dash <- paste0(js_parse_col, "
    var df = getValue('c1_df');
    var raw_vars = getArrayCols(getValue('c1_vars'));
    var id_col = getValue('c1_id');
    var h_mode = getValue('c1_helper_mode');
    var h_val = getValue('c1_helper_val');
    var p_left = getValue('c1_left'); var p_gaps = getValue('c1_void'); var p_right = getValue('c1_right');
    if (df !== '') {
        var sel_args = [];
        if (raw_vars.length > 0) sel_args.push(raw_vars.join(', '));
        if (h_mode !== 'none' && h_val !== '') {
            if (h_mode === 'custom') sel_args.push(h_val);
            else sel_args.push(h_mode + '(\"' + h_val + '\")');
        }
        if(sel_args.length > 0) echo('datos_secuencia <- ' + df + ' %>% dplyr::select(' + sel_args.join(', ') + ')\\n');
        else echo('datos_secuencia <- ' + df + '\\n');

        var seq_args = ['data = datos_secuencia', \"left = '\" + p_left + \"'\", \"gaps = '\" + p_gaps + \"'\", \"right = '\" + p_right + \"'\"];
        if (id_col !== '') seq_args.push(\"id = \" + df + \"[['\" + getRawCol(id_col) + \"']]\");
        echo('tray_seq <- TraMineR::seqdef(' + seq_args.join(', ') + ')\\n');
    }
  ")

  js_print_dash <- "
    var p_dist = getValue('c1_p_dist') == 'TRUE'; var p_freq = getValue('c1_p_freq') == 'TRUE'; var p_idx  = getValue('c1_p_idx') == 'TRUE'; var p_time = getValue('c1_p_time') == 'TRUE';
    if (!is_preview) echo('rk.header(\"Sequence Analysis Dashboard\")\\n');
    var n_plots = 0; if(p_dist) n_plots++; if(p_freq) n_plots++; if(p_idx) n_plots++; if(p_time) n_plots++;
    if (n_plots > 0) {
        if(!is_preview) echo('rk.graph.on(device.type=\"' + getValue('c1_dev_type') + '\", width=' + getValue('c1_dev_w') + ', height=' + getValue('c1_dev_h') + ', res=' + getValue('c1_dev_res') + ', bg=\"' + getValue('c1_dev_bg') + '\")\\n');
        echo('try({\\n  plot_list <- list()\\n');
        if(p_dist) echo('  plot_list[[\"p_dist\"]] <- ggseqplot::ggseqdplot(tray_seq) + ggplot2::ggtitle(\"State Distribution\")\\n');
        if(p_freq) echo('  plot_list[[\"p_freq\"]] <- ggseqplot::ggseqfplot(tray_seq) + ggplot2::ggtitle(\"Most Frequent Sequences\")\\n');
        if(p_idx)  echo('  plot_list[[\"p_idx\"]]  <- ggseqplot::ggseqiplot(tray_seq, sortv = \"from.start\") + ggplot2::ggtitle(\"Individual Trajectories\")\\n');
        if(p_time) echo('  plot_list[[\"p_time\"]] <- ggseqplot::ggseqmtplot(tray_seq) + ggplot2::ggtitle(\"Mean Time in States\")\\n');
        echo('  require(patchwork)\\n');
        if(n_plots == 1) echo('  p <- plot_list[[1]]\\n'); else echo('  p <- patchwork::wrap_plots(plot_list, ncol = 2)\\n');
        echo('  p$plot_env <- emptyenv()\\n  print(p)\\n})\\n');
        if(!is_preview) { echo('rk.graph.off()\\n'); if(getValue('c1_save.active')) echo('assign(paste0(\"' + getValue('c1_save') + '\", \"_plot\"), p, envir = .GlobalEnv)\\n'); }
    }
    echo('rm(list = intersect(ls(), c(\"datos_secuencia\", \"plot_list\", \"p\")))\\ngc()\\n');
  "
  comp_dash <- rk.plugin.component("Sequence Dashboard", xml = list(dialog = dialog_dash, logic = c1_logic), js = list(require = c("TraMineR", "dplyr", "ggseqplot", "patchwork"), calculate = js_calc_dash, printout = js_print_dash), hierarchy = h_seq)

  # =========================================================================================
  # NUEVO COMPONENT 2: Sequence Clustering (Tipología)
  # =========================================================================================
  c2_sel <- rk.XML.varselector(id.name = "c2_sel")
  c2_df  <- rk.XML.varslot("Main Dataframe", source = "c2_sel", classes = "data.frame", required = TRUE, id.name = "c2_df")

  # 1. Creamos la conversión lógica primero
  show_helper_val2 <- rk.XML.convert(sources = list("c2_helper_mode.string"), mode = c(notequals = "none"), id.name = "show_helper_val2")

  # 2. Metemos TODO en una sola variable c2_logic separando por comas
  c2_logic <- rk.XML.logic(
      show_helper_val2,
      rk.XML.connect(governor = c2_df, get = "available", client = c2_sel, set = "root"), # La Magia del Focus original
      rk.XML.connect(governor = "show_helper_val2", client = "c2_helper_val.visible")     # El control del asistente
  )

  # Pestaña 1: Vars
  c2_vars <- rk.XML.varslot("Sequence Variables", source = "c2_sel", multi = TRUE, required = FALSE, id.name = "c2_vars")
  c2_covs <- rk.XML.varslot("Covariates for Profiling (e.g. sexo, migracion)", source = "c2_sel", multi = TRUE, id.name = "c2_covs")

  c2_k <- rk.XML.spinbox("Number of clusters (k)", min = 2, max = 50, initial = 4, id.name = "c2_k")
  c2_name <- rk.XML.input("Save cluster factor as (column name)", initial = "cluster_tray", id.name = "c2_name")
  c2_append <- rk.XML.cbox("Append cluster factor to original dataframe", value = "1", chk = TRUE, id.name = "c2_append")

  c2_plot_type <- rk.XML.radio("Plot Type", options = list(
      "State Distribution Plot by Cluster (ggseqplot)" = list(val = "dist", chk = TRUE),
      "Hierarchical Dendrogram (hclust)" = list(val = "dendro")
  ), id.name = "c2_plot_type")

  # NUEVO: Guardar el modelo jerárquico
  c2_save_model <- rk.XML.saveobj("Save Clustering Model (hclust) as", initial = "cluster_ward", chk = FALSE, id.name = "c2_save_model")

  c2_name <- rk.XML.input(label = "Name for new Cluster column", id.name = "c2_name", initial = "cluster_tray", required = TRUE)
  c2_append <- rk.XML.cbox("Append cluster column to original Dataframe", id.name = "c2_append", value = "1", chk = TRUE)

  c2_helper_mode <- rk.XML.dropdown("Smart Column Selection (tidyselect)", id.name = "c2_helper_mode", options = list(
      "None (Use manual selection above)" = list(val = "none", chk = TRUE),
      "starts_with() - Exact prefix" = list(val = "starts_with"),
      "ends_with() - Exact suffix" = list(val = "ends_with"),
      "contains() - Literal string" = list(val = "contains"),
      "matches() - Regular expression" = list(val = "matches"),
      "Custom (Raw tidyselect expression)" = list(val = "custom")
  ))
  c2_helper_val <- rk.XML.input("Value / Pattern (No quotes needed)", id.name = "c2_helper_val")
  c2_helper_frame <- rk.XML.frame(rk.XML.col(c2_helper_mode, c2_helper_val), label = "Advanced Select", id.name = "c2_helper_frame")

  c2_sm <- rk.XML.dropdown("Substitution Cost Method (sm)", options = list(
      "Constant Cost (CONSTANT)" = list(val = "CONSTANT", chk = TRUE),
      "Transition Rates (TRATE) - Data driven" = list(val = "TRATE")
  ), id.name = "c2_sm")

  # UI Integration
   dialog_clust <- rk.XML.dialog(
      label = "Sequence Clustering & Typology",
      child = rk.XML.row(
          c2_sel,
          rk.XML.col(
              c2_df,
              rk.XML.tabbook(tabs = list(
                  "Data & Covariates" = rk.XML.col(
                      c2_vars,
                      c2_helper_frame,
                      rk.XML.frame(c2_covs, label = "Cross-tabulation"),
                      rk.XML.stretch()
                  ),
                  "Clustering Settings" = rk.XML.col(
                      rk.XML.text("<b>Method:</b> Optimal Matching (Constant Cost) to Ward Hierarchical Clustering"),
                      c2_k,
                      c2_sm,
                      c2_name,
                      c2_append,
                      c2_plot_type,
                      c2_save_model, # <-- Añadido aquí
                      rk.XML.stretch()
                  ),
                  # CAMBIO: show_save = TRUE, initial_save = "cluster_plot"
                  "Output" = make_device_tab(prefix = "c2", initial_save = "cluster_plot", show_save = TRUE)
              ))
          )
      )
  )

js_calc_clust <- paste0(js_parse_col, "
    var df = getValue('c2_df');
    var raw_vars = getArrayCols(getValue('c2_vars'));
    var k = getValue('c2_k');
    var sm = getValue('c2_sm');
    var cl_name = getValue('c2_name');
    var append = getValue('c2_append') == '1';

    // TidySelect Helper variables
    var h_mode = getValue('c2_helper_mode');
    var h_val = getValue('c2_helper_val');

    if (df !== '') {
        var sel_args = [];

        // 1. Add manual variables if they exist
        if (raw_vars.length > 0) sel_args.push(raw_vars.join(', '));

        // 2. Inject the TidySelect logic
        if (h_mode !== 'none' && h_val !== '') {
            if (h_mode === 'custom') {
                sel_args.push(h_val);
            } else {
                sel_args.push(h_mode + '(\"' + h_val + '\")');
            }
        }

        // 3. Generate the dplyr::select code safely
        if (sel_args.length > 0) {
            echo('datos_secuencia <- ' + df + ' %>% dplyr::select(' + sel_args.join(', ') + ')\\n');
        } else {
            echo('datos_secuencia <- ' + df + '\\n');
        }

        echo('tray_seq <- TraMineR::seqdef(datos_secuencia, left = \"DEL\", gaps = \"DEL\", right = \"DEL\")\\n\\n');

        echo('# 1. Optimal Matching Distance\\n');
        // ¡CORRECCIÓN AQUÍ! Se inyecta dinámicamente la variable sm ('TRATE' o 'CONSTANT')
        echo('dist_matrix <- TraMineR::seqdist(tray_seq, method = \"OM\", indel = 1, sm = \"' + sm + '\")\\n\\n');

        echo('# 2. Wards Hierarchical Clustering\\n');
        echo('cluster_ward <- hclust(as.dist(dist_matrix), method = \"ward.D2\")\\n');
        echo('cluster_factor <- factor(cutree(cluster_ward, k = ' + k + '), labels = paste(\"Tipo\", 1:' + k + '))\\n\\n');

        // Only append to the original dataset if it's the final Submit (not preview)
        if(append && !is_preview) {
            echo('# Append to Dataframe\\n');
            echo('assign(\"' + df + '\", ' + df + ', envir = .GlobalEnv)\\n'); // Ensure it's in GlobalEnv
            echo(df + '[[\"' + cl_name + '\"]] <- cluster_factor\\n');
        }
    }
  ")

js_print_clust <- paste0(js_parse_col, "
    var k = getValue('c2_k');
    var df = getValue('c2_df');
    var plot_type = getValue('c2_plot_type');

    var cov_val = getValue('c2_covs');
    var cov_list = [];
    if (cov_val !== '') {
        var arr = cov_val.split('\\n');
        cov_list = arr.map(function(v) { return '\"' + getRawCol(v) + '\"'; });
    }

    if (!is_preview) {
        echo('rk.header(\"Sequence Clustering & Typology\", parameters=list(\"Clusters (k)\" = as.integer(' + k + ')))\\n');

        if (cov_list.length > 0) {
            echo('rk.header(\"Cross-Tabulation: Covariates by Cluster\", level=4)\\n');
            echo('for (cv in c(' + cov_list.join(', ') + ')) {\\n');
            echo('  rk.print(paste(\"<b>Covariate:</b>\", cv))\\n');
            echo('  rk.results(table(' + df + '[[cv]], cluster_factor))\\n');
            echo('}\\n');
        }
    }

    if(!is_preview){
        echo('rk.graph.on(device.type=\"' + getValue('c2_dev_type') + '\", width=' + getValue('c2_dev_w') + ', height=' + getValue('c2_dev_h') + ', res=' + getValue('c2_dev_res') + ', bg=\"' + getValue('c2_dev_bg') + '\")\\n');
    }

    echo('try({\\n');

    if (plot_type === 'dist') {
        echo('  cluster_plot <- ggseqplot::ggseqdplot(tray_seq, group = cluster_factor) + ggplot2::ggtitle(\"State Distribution by Cluster\")\\n');
        echo('  cluster_plot$plot_env <- emptyenv()\\n');
        echo('  print(cluster_plot)\\n');
    } else {
        echo('  plot(cluster_ward, labels = FALSE, main = \"Hierarchical Dendrogram (Ward)\", xlab = \"\", sub = \"\")\\n');
        echo('  rect.hclust(cluster_ward, k = ' + k + ', border = \"red\")\\n');

        // TRUCO SALVAVIDAS: Creamos un objeto NULL para que RKWard no explote al intentar guardar el gráfico
        echo('  cluster_plot <- NULL\\n');
    }

    echo('})\\n');

    if(!is_preview){
        echo('rk.graph.off()\\n');

        // Imprimimos el mensaje rojo AFUERA del gráfico
        if (plot_type !== 'dist' && getValue('c2_save.active')) {
            echo('rk.print(\"<span style=\\'color:red;\\'>Note: Base R Dendrograms cannot be saved as plot objects. Save object set to NULL.</span>\")\\n');
        }
    }

    echo('rm(list = intersect(ls(), c(\"datos_secuencia\", \"tray_seq\", \"dist_matrix\", \"cluster_factor\")))\\n');
    echo('gc()\\n');
  ")

  comp_clust <- rk.plugin.component("Sequence Clustering", xml = list(dialog = dialog_clust, logic = c2_logic), js = list(require = c("TraMineR", "dplyr", "ggseqplot", "cluster"), calculate = js_calc_clust, printout = js_print_clust), hierarchy = h_seq)

# =========================================================================================
  # COMPONENT 3: Extract Sequence Indicators
  # =========================================================================================
  help_c3 <- rk.rkh.doc(title = rk.rkh.title("Sequence Indicators"), summary = rk.rkh.summary("Calculates complexity, entropy, and turbulence and appends them to the dataframe."))

  c3_sel <- rk.XML.varselector(id.name = "c3_sel")
  c3_seq <- rk.XML.varslot("Sequence Object (seqdef)", source = "c3_sel", required = TRUE, id.name = "c3_seq")
  c3_df  <- rk.XML.varslot("Original Dataframe (To append metrics)", source = "c3_sel", classes = "data.frame", required = TRUE, id.name = "c3_df")

  c3_logic <- rk.XML.logic(rk.XML.connect(governor = c3_df, get = "available", client = c3_sel, set = "root"))

  c3_trans <- rk.XML.cbox("Number of Transitions (seqtransn)", value = "1", chk = TRUE, id.name = "c3_trans")
  c3_ent <- rk.XML.cbox("Longitudinal Entropy (seqient)", value = "1", chk = TRUE, id.name = "c3_ent")
  c3_turb <- rk.XML.cbox("Turbulence (seqST)", value = "1", chk = TRUE, id.name = "c3_turb")
  c3_comp <- rk.XML.cbox("Complexity Index (seqici)", value = "1", chk = TRUE, id.name = "c3_comp")

  c3_append <- rk.XML.cbox("Append selected metrics to Original Dataframe", value = "1", chk = TRUE, id.name = "c3_append")

  dialog_c3 <- rk.XML.dialog(label = "Extract Sequence Indicators", child = rk.XML.row(
      c3_sel,
      rk.XML.col(
          c3_seq, c3_df,
          # FIX: Se agregó explícitamente 'label =' para evitar el error de XiMpLe
          rk.XML.frame(c3_trans, c3_ent, c3_turb, c3_comp, label = "Metrics to Extract"),
          c3_append,
          rk.XML.stretch()
      )
  ))

  js_calc_c3 <- "
    var seq = getValue('c3_seq');
    var df = getValue('c3_df');
    var append = getValue('c3_append') == '1';

    if(seq !== '' && df !== '') {
        // Validación de seguridad
        echo('if (nrow(' + df + ') == nrow(' + seq + ')) {\\n');

        if(getValue('c3_trans') == '1') echo('  ' + df + '$seq_trans <- as.numeric(TraMineR::seqtransn(' + seq + ')[,1])\\n');
        if(getValue('c3_ent') == '1')   echo('  ' + df + '$seq_entropy <- as.numeric(TraMineR::seqient(' + seq + ')[,1])\\n');
        if(getValue('c3_turb') == '1')  echo('  ' + df + '$seq_turb <- as.numeric(TraMineR::seqST(' + seq + ')[,1])\\n');
        if(getValue('c3_comp') == '1')  echo('  ' + df + '$seq_complex <- as.numeric(TraMineR::seqici(' + seq + ')[,1])\\n');

        if(append && !is_preview) {
            echo('  assign(\"' + df + '\", ' + df + ', envir = .GlobalEnv)\\n');
        }

        echo('} else {\\n');
        echo('  stop(\"Error: The Sequence Object and the Dataframe do not have the same number of rows.\")\\n');
        echo('}\\n');
    }
  "

  js_print_c3 <- "
    if(!is_preview) {
        echo('rk.header(\"Sequence Indicators Extracted\")\\n');
        echo('rk.print(\"<b>Metrics successfully calculated and appended to:</b> <code>' + getValue('c3_df') + '</code>\")\\n');
        echo('rk.print(\"<i>You can now use these variables in regressions or descriptive statistics.</i>\")\\n');
    }
  "

  comp_c3 <- rk.plugin.component("Extract Sequence Indicators", xml=list(dialog=dialog_c3, logic=c3_logic), js=list(require="TraMineR", calculate=js_calc_c3, printout=js_print_c3), hierarchy=h_seq, rkh=list(help=help_c3))

# =========================================================================================
  # COMPONENT 4: Transition Rates
  # =========================================================================================
  help_c4 <- rk.rkh.doc(title = rk.rkh.title("Transition Rates Matrix"), summary = rk.rkh.summary("Calculates transition probabilities between states."))

  c4_sel <- rk.XML.varselector(id.name = "c4_sel")
  c4_seq <- rk.XML.varslot("Sequence Object (seqdef)", source = "c4_sel", required = TRUE, id.name = "c4_seq")

  c4_save <- rk.XML.saveobj("Save Transition Matrix as", initial="trans_matrix", chk=TRUE, id.name="c4_save")

  dialog_c4 <- rk.XML.dialog(label="Transition Rates Matrix", child=rk.XML.row(
      c4_sel, rk.XML.col(c4_seq, c4_save, rk.XML.stretch())
  ))

  js_calc_c4 <- "
    var seq = getValue('c4_seq');
    if(seq !== '') {
        // Regla 3: El objeto de R se llama exactamente como el 'initial'
        echo('trans_matrix <- TraMineR::seqtrate(' + seq + ')\\n');
    }
  "

  js_print_c4 <- "
    if(!is_preview) {
        echo('rk.header(\"Transition Rates Matrix\")\\n');
        echo('rk.print(\"<i>Probabilities of moving from state i (row) to state j (column).</i>\")\\n');

        // BUG FIX: Convert TraMineR matrix to a standard data.frame
        // This prevents rk.results() from crashing due to missing dimension titles.
        echo('print_mat <- as.data.frame(round(trans_matrix, 4))\\n');
        echo('rk.results(print_mat)\\n');

        // Clean up the temporary printing object
        echo('rm(print_mat)\\n');
    }
  "

  comp_c4 <- rk.plugin.component("Transition Rates", xml=list(dialog=dialog_c4), js=list(require="TraMineR", calculate=js_calc_c4, printout=js_print_c4), hierarchy=h_seq, rkh=list(help=help_c4))


# =========================================================================================
  # 3. BUILD SKELETON (Corregido: 2 Plug-ins exactos)
  # =========================================================================================

  # 1. Definir el objeto de ayuda que faltaba
  help_dash <- rk.rkh.doc(
      title = rk.rkh.title("Sequence Dashboard"),
      summary = rk.rkh.summary("Creates a State Sequence Object (seqdef) and plots a descriptive dashboard.")
  )

  # 2. El Componente 2 (Tipología) se declara como secundario:
  comp_clust <- rk.plugin.component(
      "Sequence Clustering",
      xml = list(dialog = dialog_clust, logic = c2_logic),
      js = list(require = c("TraMineR", "dplyr", "ggseqplot", "cluster"), calculate = js_calc_clust, printout = js_print_clust),
      hierarchy = h_seq
  )

  # 3. El Componente 1 (Dashboard) toma su lugar como MAIN component:
  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    xml = list(dialog = dialog_dash, logic = c1_logic),
    js = list(require = c("TraMineR", "dplyr", "ggseqplot", "patchwork"), calculate = js_calc_dash, printout = js_print_dash),
    rkh = list(help = help_dash),
    pluginmap = list(name = "Sequence Dashboard", hierarchy = h_seq),
    components = list(comp_clust, comp_c3, comp_c4),
    create = c("pmap", "xml", "js", "desc", "rkh"),
    load = TRUE, overwrite = TRUE, show = FALSE
  )

  cat("\nPlugin package 'rk.traminer' (v0.0.3) generated successfully.\n")
})
