// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(TraMineR)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var seq = getValue('c3_seq');
    var df = getValue('c3_df');
    var append = getValue('c3_append') == '1';

    if(seq !== '' && df !== '') {
        // Validación de seguridad
        echo('if (nrow(' + df + ') == nrow(' + seq + ')) {\n');

        if(getValue('c3_trans') == '1') echo('  ' + df + '$seq_trans <- as.numeric(TraMineR::seqtransn(' + seq + ')[,1])\n');
        if(getValue('c3_ent') == '1')   echo('  ' + df + '$seq_entropy <- as.numeric(TraMineR::seqient(' + seq + ')[,1])\n');
        if(getValue('c3_turb') == '1')  echo('  ' + df + '$seq_turb <- as.numeric(TraMineR::seqST(' + seq + ')[,1])\n');
        if(getValue('c3_comp') == '1')  echo('  ' + df + '$seq_complex <- as.numeric(TraMineR::seqici(' + seq + ')[,1])\n');

        if(append && !is_preview) {
            echo('  assign("' + df + '", ' + df + ', envir = .GlobalEnv)\n');
        }

        echo('} else {\n');
        echo('  stop("Error: The Sequence Object and the Dataframe do not have the same number of rows.")\n');
        echo('}\n');
    }
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Extract Sequence Indicators results")).print();

    if(!is_preview) {
        echo('rk.header("Sequence Indicators Extracted")\n');
        echo('rk.print("<b>Metrics successfully calculated and appended to:</b> <code>' + getValue('c3_df') + '</code>")\n');
        echo('rk.print("<i>You can now use these variables in regressions or descriptive statistics.</i>")\n');
    }
  

}

