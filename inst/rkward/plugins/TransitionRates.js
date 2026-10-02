// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(TraMineR)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var seq = getValue('c4_seq');
    if(seq !== '') {
        // Regla 3: El objeto de R se llama exactamente como el 'initial'
        echo('trans_matrix <- TraMineR::seqtrate(' + seq + ')\n');
    }
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Transition Rates results")).print();

    if(!is_preview) {
        echo('rk.header("Transition Rates Matrix")\n');
        echo('rk.print("<i>Probabilities of moving from state i (row) to state j (column).</i>")\n');

        // BUG FIX: Convert TraMineR matrix to a standard data.frame
        // This prevents rk.results() from crashing due to missing dimension titles.
        echo('print_mat <- as.data.frame(round(trans_matrix, 4))\n');
        echo('rk.results(print_mat)\n');

        // Clean up the temporary printing object
        echo('rm(print_mat)\n');
    }
  
	//// save result object
	// read in saveobject variables
	var c4Save = getValue("c4_save");
	var c4SaveActive = getValue("c4_save.active");
	var c4SaveParent = getValue("c4_save.parent");
	// assign object to chosen environment
	if(c4SaveActive) {
		echo(".GlobalEnv$" + c4Save + " <- trans_matrix\n");
	}

}

