// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

function preview(){
	preprocess(true);
	calculate(true);
	printout(true);
}

function preprocess(is_preview){
	// add requirements etc. here
	if(is_preview) {
		echo("if(!base::require(TraMineR)){stop(" + i18n("Preview not available, because package TraMineR is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(TraMineR)\n");
	}	if(is_preview) {
		echo("if(!base::require(dplyr)){stop(" + i18n("Preview not available, because package dplyr is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(dplyr)\n");
	}	if(is_preview) {
		echo("if(!base::require(ggseqplot)){stop(" + i18n("Preview not available, because package ggseqplot is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(ggseqplot)\n");
	}	if(is_preview) {
		echo("if(!base::require(patchwork)){stop(" + i18n("Preview not available, because package patchwork is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(patchwork)\n");
	}
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    // 1. Extrae el nombre puro (sin backticks) para usar con [['columna']]
    function getRawCol(fullPath) {
        if (!fullPath) return '';
        var raw = fullPath;
        if (raw.indexOf('[[') > -1) {
             raw = raw.split('[[')[1].replace(']]', '').replace(/[\"']/g, '');
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
        var arr = vars.split('\n');
        return arr.map(function(v) { return getSafeCol(v); });
    }
  
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
                sel_args.push(h_val); // Código crudo (ej. num_range("x", 1:5))
            } else {
                // Le pone comillas automáticamente para evitar errores de sintaxis
                sel_args.push(h_mode + '("' + h_val + '")');
            }
        }

        if(sel_args.length > 0) {
            echo('datos_secuencia <- ' + df + ' %>% dplyr::select(' + sel_args.join(', ') + ')\n');
        } else {
            echo('datos_secuencia <- ' + df + '\n');
        }

        // 2. TraMineR seqdef
        var seq_args = ['data = datos_secuencia'];
        seq_args.push("left = '" + p_left + "'");
        seq_args.push("gaps = '" + p_gaps + "'");
        seq_args.push("right = '" + p_right + "'");

        if (id_col !== '') {
            var raw_id = getRawCol(id_col);
            seq_args.push("id = " + df + "[['" + raw_id + "']]");
        }

        echo('tray_seq <- TraMineR::seqdef(' + seq_args.join(', ') + ')\n');
    }
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Sequence Dashboard results")).print();	
	}
    var p_dist = getValue('c1_p_dist') == 'TRUE';
    var p_freq = getValue('c1_p_freq') == 'TRUE';
    var p_idx  = getValue('c1_p_idx') == 'TRUE';
    var p_time = getValue('c1_p_time') == 'TRUE';

    if (!is_preview) {
        echo('rk.header("Sequence Analysis Dashboard")\n');
    }

    var n_plots = 0;
    if(p_dist) n_plots++;
    if(p_freq) n_plots++;
    if(p_idx) n_plots++;
    if(p_time) n_plots++;

    if (n_plots > 0) {
        if(!is_preview){
            echo('rk.graph.on(device.type="' + getValue('c1_dev_type') + '", width=' + getValue('c1_dev_w') + ', height=' + getValue('c1_dev_h') + ', res=' + getValue('c1_dev_res') + ', bg="' + getValue('c1_dev_bg') + '")\n');
        }

        echo('try({\n');

        // Construir la lista de gráficos de ggseqplot
        echo('  plot_list <- list()\n');

        if(p_dist) echo('  plot_list[["p_dist"]] <- ggseqplot::ggseqdplot(tray_seq) + ggplot2::ggtitle("State Distribution")\n');
        if(p_freq) echo('  plot_list[["p_freq"]] <- ggseqplot::ggseqfplot(tray_seq) + ggplot2::ggtitle("Most Frequent Sequences")\n');
        if(p_idx)  echo('  plot_list[["p_idx"]]  <- ggseqplot::ggseqiplot(tray_seq, sortv = "from.start") + ggplot2::ggtitle("Individual Trajectories")\n');
        if(p_time) echo('  plot_list[["p_time"]] <- ggseqplot::ggseqmtplot(tray_seq) + ggplot2::ggtitle("Mean Time in States")\n');

        // Ensamblar con patchwork
        echo('  require(patchwork)\n');
        if(n_plots == 1) echo('  p <- plot_list[[1]]\n');
        else if(n_plots == 2) echo('  p <- patchwork::wrap_plots(plot_list, ncol = 2)\n');
        else echo('  p <- patchwork::wrap_plots(plot_list, ncol = 2)\n'); // Automáticamente acomoda 3 o 4 gráficos en rejilla

        // REGLA DORADA: Optimización de memoria para ggplot2
        echo('  p$plot_env <- emptyenv()\n');
        echo('  print(p)\n');

        echo('})\n');

        if(!is_preview){
            echo('rk.graph.off()\n');

            if(getValue('c1_save.active')) {
                echo('assign(paste0("' + getValue('c1_save') + '", "_plot"), p, envir = .GlobalEnv)\n');

                // 2. El objeto matemático (tray_seq) se queda intacto.
                // RKWard lo guardará automáticamente al final del script usando el nombre que eligió el usuario.
            }
        }
    } else {
        if(!is_preview) echo('rk.print("<i>No plots were selected. Only the sequence object was generated.</i>")\n');
    }

    echo('rm(list = intersect(ls(), c("datos_secuencia", "plot_list", "p")))\n');
    echo('gc()\n');
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var c1Save = getValue("c1_save");
		var c1SaveActive = getValue("c1_save.active");
		var c1SaveParent = getValue("c1_save.parent");
		// assign object to chosen environment
		if(c1SaveActive) {
			echo(".GlobalEnv$" + c1Save + " <- tray_seq\n");
		}	
	}

}

