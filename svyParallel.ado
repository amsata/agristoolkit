
	capture program drop svyParallel
	program svyParallel
	args varlist variable parameter setcluster subpop

		*tuples `varlist' // for looping over all dimensions
		local si: list sizeof variable
		local s_varlist: list sizeof varlist
		
		if(`s_varlist'==0) {
			local alldim "yes"
			local ntuples 1
		}
		else {
			local alldim "no"
			*if ("`conditionals'"=="") {
			tuples `varlist', nopython
		*}
		*else{
		*	tuples `varlist', conditionals(`conditionals') 
		*}
		
		} 

	if (`setcluster'==0) {

	tempfile odp_tab
	scalar def init=0

	forvalues i=1/`si' {
			forvalues j=1/`ntuples' {
				*tuples `varlist'
				if("`alldim'"=="no") local tuple "`tuple`j''" 
				else local tuple "`varlist'"
				local var "`:word `i' of `variable''"				
				if("`alldim'"=="no") di"Generating {cmd: `parameter'} of {cmd:`var'}  over {cmd:`tuple'}..."
				else di"Generating {cmd:`parameter'} of {cmd:`var'} in the population/sub-population..."
			quietly{
			use "$temp_file", clear

			************************************************************************
			*****check if there are hierarchical structure between 2 variables******
			************************************************************************	
				quietly svyEstimate `tuple' , param(`parameter') var(`var') alldim(`alldim') subpop("`subpop'")				
			if (init==0) {
			save `odp_tab', replace
			scalar def init=1
			}
			else {
			 append using `odp_tab'
			 save `odp_tab', replace
			}			
			}		
			*restore // restore the iniial dataset for the continuation of the loop on tuplesS
		}
		}	
	use  `odp_tab', clear
	}
	else{
    tempfile worker_result
    local worker_tasks = 0
	forvalues i=1/`si' {
			forvalues j=1/`ntuples' {
				*tuples `varlist'
				if("`alldim'"=="no") local tuple "`tuple`j''" 
				else local tuple "`varlist'"
				local var "`:word `i' of `variable''"

				*local core = mod(`j' - 1, $PLL_CLUSTERS) + 1
				if(`ntuples'>=`si') local core = mod(`j' - 1, $PLL_CLUSTERS) + 1
				else local core = mod(`i' - 1, $PLL_CLUSTERS) + 1
				
			if($pll_instance == `core') {

			use "$temp_file", clear			
			************************************************************************
			*****check if there are hierarchical structure between 2 variables******
			************************************************************************	
				quietly svyEstimate `tuple' , param(`parameter') var(`var') alldim(`alldim') subpop("`subpop'")	
			if `worker_tasks'>0 append using `worker_result'
        save `worker_result', replace
        local ++worker_tasks
			}
		}
		}	


    local workerfile "__pll${pll_id}_agris_${pll_instance}.dta"
    if `worker_tasks'>0 {
        use `worker_result', clear
        save "`workerfile'", replace
    }
    tempname completion
    file open `completion' using "__pll${pll_id}_agris_${pll_instance}.done", write replace
    file write `completion' "`worker_tasks'" _n
    file close `completion'
}
	end
