local({
  # =========================================================================================
  # 1. Package Definition and Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.10-3")

  package_about <- rk.XML.about(
    name = "rk.traminer",
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "An RKWard GUI plugin for Sequence Analysis and Trajectory mining using TraMineR.",
      version = "0.0.1",
      url = "https://github.com/AlfCano/rk.traminer",
      license = "GPL (>= 3)"
    )
  )

  h_seq <- list("plots", "Sequence Analysis (TraMineR)")

    # =========================================================================================
  # 2. UI Helpers (JS Parser and Device Tab Generator)
  # =========================================================================================
  js_parse_col <- "
    // 1. Extrae el nombre puro (sin backticks) para usar con [['columna']]
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

    // 2. Extrae el nombre y lo envuelve en backticks para dplyr (`columna`)
    function getSafeCol(fullPath) {
        var raw = getRawCol(fullPath);
        if (!raw) return '';
        return '`' + raw + '`';
    }

    // 3. Procesa múltiples variables (para dplyr)
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
  # COMPONENT 1: Sequence Dashboard
  # =========================================================================================
  help_dash <- rk.rkh.doc(
      title = rk.rkh.title("Sequence Dashboard"),
      summary = rk.rkh.summary("Creates a State Sequence Object (seqdef) and plots a descriptive dashboard.")
  )

  c1_sel <- rk.XML.varselector(id.name = "c1_sel")
  c1_df  <- rk.XML.varslot("Select Dataframe", source = "c1_sel", classes = "data.frame", required = TRUE, id.name = "c1_df")

  c1_logic <- rk.XML.logic(
      rk.XML.connect(governor = c1_df, get = "available", client = c1_sel, set = "root") # Focus Magic
  )

  # --- Pestaña 1: Data ---
  c1_vars <- rk.XML.varslot("Variables (Sequence states over time)", source = "c1_sel", multi = TRUE, id.name = "c1_vars")

 # NUEVO: Asistente Inteligente de Tidyselect
  c1_helper_mode <- rk.XML.dropdown("Smart Column Selection (tidyselect)", id.name = "c1_helper_mode", options = list(
      "None (Use manual selection above)" = list(val = "none", chk = TRUE),
      "starts_with() - Exact prefix" = list(val = "starts_with"),
      "ends_with() - Exact suffix" = list(val = "ends_with"),
      "contains() - Literal string" = list(val = "contains"),
      "matches() - Regular expression" = list(val = "matches"),
      "Custom (Raw tidyselect expression)" = list(val = "custom")
  ))

  c1_helper_val <- rk.XML.input("Value / Pattern (No quotes needed for prefix/suffix)", id.name = "c1_helper_val")

  c1_helper_frame <- rk.XML.frame(
      rk.XML.col(c1_helper_mode, c1_helper_val),
      label = "Advanced Select",
      id.name = "c1_helper_frame"
  )

  c1_id <- rk.XML.varslot("Identifier (Optional, e.g., Patient/Subject ID)", source = "c1_sel", id.name = "c1_id")

  show_helper_val <- rk.XML.convert(sources = list("c1_helper_mode.string"), mode = c(notequals = "none"), id.name = "show_helper_val")

  c1_logic <- rk.XML.logic(
      show_helper_val,
      rk.XML.connect(governor = c1_df, get = "available", client = c1_sel, set = "root"), # Focus Magic
      rk.XML.connect(governor = "show_helper_val", client = "c1_helper_val.visible")      # Oculta la caja si es "None"
  )

  c1_left  <- rk.XML.dropdown("Left gaps (Before sequence starts)", options = list("Delete / Ignore (DEL)" = list(val = "DEL", chk = TRUE), "Treat as missing (NA)" = list(val = "NA")), id.name = "c1_left")
  c1_void  <- rk.XML.dropdown("Void gaps (Internal missing data)", options = list("Delete / Ignore (DEL)" = list(val = "DEL", chk = TRUE), "Treat as missing (NA)" = list(val = "NA")), id.name = "c1_void")
  c1_right <- rk.XML.dropdown("Right gaps (After sequence ends)", options = list("Delete / Ignore (DEL)" = list(val = "DEL", chk = TRUE), "Treat as missing (NA)" = list(val = "NA")), id.name = "c1_right")

  # --- Pestaña 3: Dashboard Plots ---
  c1_p_dist  <- rk.XML.cbox("State Distribution Plot (seqdplot)", value = "TRUE", chk = TRUE, id.name = "c1_p_dist")
  c1_p_freq  <- rk.XML.cbox("Sequence Frequency Plot (seqfplot)", value = "TRUE", chk = TRUE, id.name = "c1_p_freq")
  c1_p_idx   <- rk.XML.cbox("Sequence Index Plot (seqIplot)", value = "TRUE", chk = TRUE, id.name = "c1_p_idx")
  c1_p_time  <- rk.XML.cbox("Mean Time Plot (seqmtplot)", value = "TRUE", chk = TRUE, id.name = "c1_p_time")

  dialog_dash <- rk.XML.dialog(label = "Sequence Analysis Dashboard", child = rk.XML.row(
      c1_sel,
      rk.XML.col(
          c1_df,
          rk.XML.tabbook(tabs = list(
              # SE ACTUALIZÓ c1_adv por c1_helper_frame
              "Data & Variables" = rk.XML.col(c1_vars, c1_helper_frame, rk.XML.frame(c1_id, label="Metadata"), rk.XML.stretch()),
              "Missing Data Handling" = rk.XML.col(c1_left, c1_void, c1_right, rk.XML.stretch()),
              "Dashboard Plots" = rk.XML.col(c1_p_dist, c1_p_freq, c1_p_idx, c1_p_time, rk.XML.stretch()),
              "Output" = make_device_tab(prefix = "c1", initial_save = "tray_seq", show_save = TRUE)
          ))
      )
  ))

  js_calc_dash <- paste0(js_parse_col, "
    var df = getValue('c1_df');
    var raw_vars = getArrayCols(getValue('c1_vars'));
    var id_col = getValue('c1_id');

    var h_mode = getValue('c1_helper_mode');
    var h_val = getValue('c1_helper_val');

    var p_left = getValue('c1_left');
    var p_gaps = getValue('c1_void');
    var p_right = getValue('c1_right');

    if (df !== '') {
        // 1. Data Selection via dplyr
        var sel_args = [];
        if (raw_vars.length > 0) sel_args.push(raw_vars.join(', '));

        // Magia del Asistente de Tidyselect
        if (h_mode !== 'none' && h_val !== '') {
            if (h_mode === 'custom') {
                sel_args.push(h_val); // Código crudo (ej. num_range(\"x\", 1:5))
            } else {
                // Le pone comillas automáticamente para evitar errores de sintaxis
                sel_args.push(h_mode + '(\"' + h_val + '\")');
            }
        }

        if(sel_args.length > 0) {
            echo('datos_secuencia <- ' + df + ' %>% dplyr::select(' + sel_args.join(', ') + ')\\n');
        } else {
            echo('datos_secuencia <- ' + df + '\\n');
        }

        // 2. TraMineR seqdef
        var seq_args = ['data = datos_secuencia'];
        seq_args.push(\"left = '\" + p_left + \"'\");
        seq_args.push(\"gaps = '\" + p_gaps + \"'\");
        seq_args.push(\"right = '\" + p_right + \"'\");

        if (id_col !== '') {
            var raw_id = getRawCol(id_col);
            seq_args.push(\"id = \" + df + \"[['\" + raw_id + \"']]\");
        }

        echo('tray_seq <- TraMineR::seqdef(' + seq_args.join(', ') + ')\\n');
    }
  ")

  js_print_dash <- "
    var p_dist = getValue('c1_p_dist') == 'TRUE';
    var p_freq = getValue('c1_p_freq') == 'TRUE';
    var p_idx  = getValue('c1_p_idx') == 'TRUE';
    var p_time = getValue('c1_p_time') == 'TRUE';

    if (!is_preview) {
        echo('rk.header(\"Sequence Analysis Dashboard\")\\n');
    }

    var n_plots = 0;
    if(p_dist) n_plots++;
    if(p_freq) n_plots++;
    if(p_idx) n_plots++;
    if(p_time) n_plots++;

    if (n_plots > 0) {
        if(!is_preview){
            echo('rk.graph.on(device.type=\"' + getValue('c1_dev_type') + '\", width=' + getValue('c1_dev_w') + ', height=' + getValue('c1_dev_h') + ', res=' + getValue('c1_dev_res') + ', bg=\"' + getValue('c1_dev_bg') + '\")\\n');
        }

        echo('try({\\n');

        // Construir la lista de gráficos de ggseqplot
        echo('  plot_list <- list()\\n');

        if(p_dist) echo('  plot_list[[\"p_dist\"]] <- ggseqplot::ggseqdplot(tray_seq) + ggplot2::ggtitle(\"State Distribution\")\\n');
        if(p_freq) echo('  plot_list[[\"p_freq\"]] <- ggseqplot::ggseqfplot(tray_seq) + ggplot2::ggtitle(\"Most Frequent Sequences\")\\n');
        if(p_idx)  echo('  plot_list[[\"p_idx\"]]  <- ggseqplot::ggseqiplot(tray_seq, sortv = \"from.start\") + ggplot2::ggtitle(\"Individual Trajectories\")\\n');
        if(p_time) echo('  plot_list[[\"p_time\"]] <- ggseqplot::ggseqmtplot(tray_seq) + ggplot2::ggtitle(\"Mean Time in States\")\\n');

        // Ensamblar con patchwork
        echo('  require(patchwork)\\n');
        if(n_plots == 1) echo('  p <- plot_list[[1]]\\n');
        else if(n_plots == 2) echo('  p <- patchwork::wrap_plots(plot_list, ncol = 2)\\n');
        else echo('  p <- patchwork::wrap_plots(plot_list, ncol = 2)\\n'); // Automáticamente acomoda 3 o 4 gráficos en rejilla

        // REGLA DORADA: Optimización de memoria para ggplot2
        echo('  p$plot_env <- emptyenv()\\n');
        echo('  print(p)\\n');

        echo('})\\n');

        if(!is_preview){
            echo('rk.graph.off()\\n');

            if(getValue('c1_save.active')) {
                echo('assign(paste0(\"' + getValue('c1_save') + '\", \"_plot\"), p, envir = .GlobalEnv)\\n');

                // 2. El objeto matemático (tray_seq) se queda intacto.
                // RKWard lo guardará automáticamente al final del script usando el nombre que eligió el usuario.
            }
        }
    } else {
        if(!is_preview) echo('rk.print(\"<i>No plots were selected. Only the sequence object was generated.</i>\")\\n');
    }

    echo('rm(list = intersect(ls(), c(\"datos_secuencia\", \"plot_list\", \"p\")))\\n');
    echo('gc()\\n');
  "


  # =========================================================================================
  # 3. BUILD SKELETON
  # =========================================================================================
  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    xml = list(dialog = dialog_dash, logic = c1_logic),
    js = list(require = c("TraMineR", "dplyr", "ggseqplot", "patchwork"), calculate = js_calc_dash, printout = js_print_dash),
    rkh = list(help = help_dash),
    pluginmap = list(name = "Sequence Dashboard", hierarchy = h_seq),
    create = c("pmap", "xml", "js", "desc", "rkh"),
    load = TRUE, overwrite = TRUE, show = FALSE
  )

  cat("\nPlugin package 'rk.traminer' (v0.0.1) generated successfully.\n")
})
