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
    function getSafeCol(fullPath) {
        var raw = getRawCol(fullPath);
        if (!raw) return '';
        return '`' + raw + '`';
    }
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
    var p_left = getValue('c1_left'); var p_gaps = getValue('c1_void'); var p_right = getValue('c1_right');
    if (df !== '') {
        var sel_args = [];
        if (raw_vars.length > 0) sel_args.push(raw_vars.join(', '));
        if (h_mode !== 'none' && h_val !== '') {
            if (h_mode === 'custom') sel_args.push(h_val);
            else sel_args.push(h_mode + '("' + h_val + '")');
        }
        if(sel_args.length > 0) echo('datos_secuencia <- ' + df + ' %>% dplyr::select(' + sel_args.join(', ') + ')\n');
        else echo('datos_secuencia <- ' + df + '\n');

        var seq_args = ['data = datos_secuencia', "left = '" + p_left + "'", "gaps = '" + p_gaps + "'", "right = '" + p_right + "'"];
        if (id_col !== '') seq_args.push("id = " + df + "[['" + getRawCol(id_col) + "']]");
        echo('tray_seq <- TraMineR::seqdef(' + seq_args.join(', ') + ')\n');
    }
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Sequence Dashboard results")).print();	
	}
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"').replace(/\n/g, '\\n');
    }
  
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
    function getSafeCol(fullPath) {
        var raw = getRawCol(fullPath);
        if (!raw) return '';
        return '`' + raw + '`';
    }
    function getArrayCols(vars) {
        if(!vars) return [];
        var arr = vars.split('\n');
        return arr.map(function(v) { return getSafeCol(v); });
    }
  
    var p_dist = getValue('c1_p_dist') == 'TRUE';
    var p_freq = getValue('c1_p_freq') == 'TRUE';
    var p_idx  = getValue('c1_p_idx') == 'TRUE';
    var p_time = getValue('c1_p_time') == 'TRUE';

    // Títulos
    var t_dist = cleanStr(getValue('c1_t_dist'));
    var t_freq = cleanStr(getValue('c1_t_freq'));
    var t_idx  = cleanStr(getValue('c1_t_idx'));
    var t_time = cleanStr(getValue('c1_t_time'));

    // Ejes Y
    var y_dist = cleanStr(getValue('c1_y_dist'));
    var y_freq = cleanStr(getValue('c1_y_freq'));
    var y_idx  = cleanStr(getValue('c1_y_idx'));
    var y_time = cleanStr(getValue('c1_y_time'));

    var uni_leg = getValue('c1_uni_leg') == 'TRUE';
    var angle = getValue('c1_x_angle');

    if (!is_preview) echo('rk.header("Sequence Analysis Dashboard")\n');

    var n_plots = 0;
    if(p_dist) n_plots++;
    if(p_freq) n_plots++;
    if(p_idx) n_plots++;
    if(p_time) n_plots++;

    if (n_plots > 0) {
        if(!is_preview) echo('rk.graph.on(device.type="' + getValue('c1_dev_type') + '", width=' + getValue('c1_dev_w') + ', height=' + getValue('c1_dev_h') + ', res=' + getValue('c1_dev_res') + ', bg="' + getValue('c1_dev_bg') + '")\n');

        echo('try({\n  plot_list <- list()\n');

        var keep_leg = true;
        function get_guide() {
            if (!uni_leg) return '';
            if (keep_leg) { keep_leg = false; return ''; }
            return ' + ggplot2::guides(fill = "none", color = "none")';
        }

        // Helper para inyectar ylab solo si no está en blanco
        function get_ylab(val) {
            return (val !== '') ? ' + ggplot2::ylab("' + val + '")' : '';
        }

        if(p_dist) echo('  plot_list[["p_dist"]] <- ggseqplot::ggseqdplot(tray_seq) + ggplot2::ggtitle("' + t_dist + '")' + get_ylab(y_dist) + get_guide() + '\n');
        if(p_freq) echo('  plot_list[["p_freq"]] <- ggseqplot::ggseqfplot(tray_seq) + ggplot2::ggtitle("' + t_freq + '")' + get_ylab(y_freq) + get_guide() + '\n');
        if(p_idx)  echo('  plot_list[["p_idx"]]  <- ggseqplot::ggseqiplot(tray_seq, sortv = "from.start") + ggplot2::ggtitle("' + t_idx + '")' + get_ylab(y_idx) + get_guide() + '\n');
        if(p_time) echo('  plot_list[["p_time"]] <- ggseqplot::ggseqmtplot(tray_seq) + ggplot2::ggtitle("' + t_time + '")' + get_ylab(y_time) + get_guide() + '\n');

        echo('  require(patchwork)\n');
        echo('  p <- patchwork::wrap_plots(plot_list, ncol = ' + (n_plots == 1 ? '1' : '2') + ')\n');

        if (uni_leg) {
            echo('  p <- p + patchwork::plot_layout(guides = "collect")\n');
        }

        var themes = [];
        if (uni_leg) themes.push('legend.position = "bottom"');
        if (angle !== '0') themes.push('axis.text.x = ggplot2::element_text(angle = ' + angle + ', hjust = 1, vjust = 1)');

        if (themes.length > 0) {
            echo('  p <- p & ggplot2::theme(' + themes.join(', ') + ')\n');
        }

        echo('  p$plot_env <- emptyenv()\n');
        echo('  print(p)\n');
        echo('})\n');

        if(!is_preview) {
            echo('rk.graph.off()\n');
            if(getValue('c1_save.active')) {
                echo('assign(paste0("' + getValue('c1_save') + '", "_plot"), p, envir = .GlobalEnv)\n');
            }
        }
    } else {
        if(!is_preview) echo('rk.print("<i>No plots were selected. Only the sequence object was generated.</i>")\n');
    }
    echo('rm(list = intersect(ls(), c("datos_secuencia", "plot_list", "p")))\ngc()\n');
  
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

