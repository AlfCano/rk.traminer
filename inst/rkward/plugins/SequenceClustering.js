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
		echo("if(!base::require(cluster)){stop(" + i18n("Preview not available, because package cluster is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(cluster)\n");
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
                sel_args.push(h_mode + '("' + h_val + '")');
            }
        }

        // 3. Generate the dplyr::select code safely
        if (sel_args.length > 0) {
            echo('datos_secuencia <- ' + df + ' %>% dplyr::select(' + sel_args.join(', ') + ')\n');
        } else {
            echo('datos_secuencia <- ' + df + '\n');
        }

        echo('tray_seq <- TraMineR::seqdef(datos_secuencia, left = "DEL", gaps = "DEL", right = "DEL")\n\n');

        echo('# 1. Optimal Matching Distance\n');
        // ¡CORRECCIÓN AQUÍ! Se inyecta dinámicamente la variable sm ('TRATE' o 'CONSTANT')
        echo('dist_matrix <- TraMineR::seqdist(tray_seq, method = "OM", indel = 1, sm = "' + sm + '")\n\n');

        echo('# 2. Wards Hierarchical Clustering\n');
        echo('cluster_ward <- hclust(as.dist(dist_matrix), method = "ward.D2")\n');
        echo('cluster_factor <- factor(cutree(cluster_ward, k = ' + k + '), labels = paste("Tipo", 1:' + k + '))\n\n');

        // Only append to the original dataset if it's the final Submit (not preview)
        if(append && !is_preview) {
            echo('# Append to Dataframe\n');
            echo('assign("' + df + '", ' + df + ', envir = .GlobalEnv)\n'); // Ensure it's in GlobalEnv
            echo(df + '[["' + cl_name + '"]] <- cluster_factor\n');
        }
    }
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Sequence Clustering results")).print();	
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
  
    var k = getValue('c2_k');
    var df = getValue('c2_df');
    var plot_type = getValue('c2_plot_type');

    var cov_val = getValue('c2_covs');
    var cov_list = [];
    if (cov_val !== '') {
        var arr = cov_val.split('\n');
        cov_list = arr.map(function(v) { return '"' + getRawCol(v) + '"'; });
    }

    if (!is_preview) {
        echo('rk.header("Sequence Clustering & Typology", parameters=list("Clusters (k)" = as.integer(' + k + ')))\n');

        if (cov_list.length > 0) {
            echo('rk.header("Cross-Tabulation: Covariates by Cluster", level=4)\n');
            echo('for (cv in c(' + cov_list.join(', ') + ')) {\n');
            echo('  rk.print(paste("<b>Covariate:</b>", cv))\n');
            echo('  rk.results(table(' + df + '[[cv]], cluster_factor))\n');
            echo('}\n');
        }
    }

    if(!is_preview){
        echo('rk.graph.on(device.type="' + getValue('c2_dev_type') + '", width=' + getValue('c2_dev_w') + ', height=' + getValue('c2_dev_h') + ', res=' + getValue('c2_dev_res') + ', bg="' + getValue('c2_dev_bg') + '")\n');
    }

    echo('try({\n');

    if (plot_type === 'dist') {
        echo('  cluster_plot <- ggseqplot::ggseqdplot(tray_seq, group = cluster_factor) + ggplot2::ggtitle("State Distribution by Cluster")\n');
        echo('  cluster_plot$plot_env <- emptyenv()\n');
        echo('  print(cluster_plot)\n');
    } else {
        echo('  plot(cluster_ward, labels = FALSE, main = "Hierarchical Dendrogram (Ward)", xlab = "", sub = "")\n');
        echo('  rect.hclust(cluster_ward, k = ' + k + ', border = "red")\n');

        // TRUCO SALVAVIDAS: Creamos un objeto NULL para que RKWard no explote al intentar guardar el gráfico
        echo('  cluster_plot <- NULL\n');
    }

    echo('})\n');

    if(!is_preview){
        echo('rk.graph.off()\n');

        // Imprimimos el mensaje rojo AFUERA del gráfico
        if (plot_type !== 'dist' && getValue('c2_save.active')) {
            echo('rk.print("<span style=\'color:red;\'>Note: Base R Dendrograms cannot be saved as plot objects. Save object set to NULL.</span>")\n');
        }
    }

    echo('rm(list = intersect(ls(), c("datos_secuencia", "tray_seq", "dist_matrix", "cluster_factor")))\n');
    echo('gc()\n');
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var c2SaveModel = getValue("c2_save_model");
		var c2SaveModelActive = getValue("c2_save_model.active");
		var c2SaveModelParent = getValue("c2_save_model.parent");		var c2Save = getValue("c2_save");
		var c2SaveActive = getValue("c2_save.active");
		var c2SaveParent = getValue("c2_save.parent");
		// assign object to chosen environment
		if(c2SaveModelActive) {
			echo(".GlobalEnv$" + c2SaveModel + " <- cluster_ward\n");
		}
		if(c2SaveActive) {
			echo(".GlobalEnv$" + c2Save + " <- cluster_plot\n");
		}	
	}

}

