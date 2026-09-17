cap program drop svyParallelGeo
program svyParallelGeo

args varlist hiergeovars variable parameter setcluster
	*tuples `varlist' // for looping over all dimensions
    local si: list sizeof variable
	local s_varlist: list sizeof varlist
	local s_geovars: list sizeof hiergeovars


	if(`s_varlist'==0 & `s_geovars'==0) {
		local alldim "yes"
		local ntuples 1
		local s_geovars=1

	}
	else {
		local alldim "no"
	}

if(`setcluster'==0){
tempfile odp_tab
scalar init=0
forvalues k=1/`s_geovars' {	
	*if ("`conditionals'"=="") {
		if(`s_varlist'==0) {
			local new_varlist "`:word `k' of `hiergeovars''"
		tuples `new_varlist', nopython
		}
		else {
			local new_varlist "`:word `k' of `hiergeovars'' `varlist'"
		tuples `new_varlist', nopython
		}
	*}
	*else{
	*	tuples `varlist', conditionals(`conditionals') 
	*}
	forvalues i=1/`si' {
		forvalues j=1/`ntuples' {
			*tuples `varlist'
			if("`alldim'"=="no") local tuple "`tuple`j''" 
			else local tuple "`new_varlist'"
			local var "`:word `i' of `variable''"
	di"GeoVar-{cmd:`:word `k' of `hiergeovars''} : Generating {cmd:`parameter'} of {cmd:`var'}  over {cmd:`tuple'}..."
quietly{
		use "$temp_file", clear

	foreach v of local tuple {	
	*Exploring labelsof command would reduce this number of line
	local old_vl: value label `v'
	elabel copy `old_vl' ld_`v' 
	}
	tempfile  dolabs
	// store them in a temporary do-file
	label save using `dolabs'
		************************************************************************
		*****check if there are hierarchical structure between 2 variables******
		************************************************************************	
			quietly svyEstimate `tuple' , param(`parameter') var(`var') alldim(`alldim') subpop("`subpop'")	
			gen geoType="`:word `k' of `hiergeovars''"

			
			capture confirm variable `:word `k' of `hiergeovars''
			if _rc == 0 {
				run `dolabs'
				label values `:word `k' of `hiergeovars'' ld_`:word `k' of `hiergeovars''
				ren `:word `k' of `hiergeovars'' geoVar

			}
	*drop rownames
			
				
			if (init==0) {
			save `odp_tab', replace
			scalar def init=1
			}
			else {
			 append using `odp_tab'
			 save `odp_tab', replace
			}
}

	}
	}	
} // forvalues geovars

use `odp_tab', clear
}
else{
	
tempfile worker_result
local worker_tasks = 0
forvalues k=1/`s_geovars' {	
	*if ("`conditionals'"=="") {
		if(`s_varlist'==0) {
			local new_varlist "`:word `k' of `hiergeovars''"
		tuples `new_varlist', nopython
		}
		else {
			local new_varlist "`:word `k' of `hiergeovars'' `varlist'"
		tuples `new_varlist', nopython
		}
	*}
	*else{
	*	tuples `varlist', conditionals(`conditionals') 
	*}
	forvalues i=1/`si' {
		forvalues j=1/`ntuples' {
			*tuples `varlist'
			if("`alldim'"=="no") local tuple "`tuple`j''" 
			else local tuple "`new_varlist'"
			local var "`:word `i' of `variable''"

			*local core = mod(`j' - 1, $PLL_CLUSTERS) + 1
			if(`ntuples'>=`si') local core = mod(`j' - 1, $PLL_CLUSTERS) + 1
			else local core = mod(`i' - 1, $PLL_CLUSTERS) + 1
			
		if($pll_instance == `core') {


		use "$temp_file", clear

	
	foreach v of local tuple {	
	*Exploring labelsof command would reduce this number of line
	local old_vl: value label `v'
	elabel copy `old_vl' ld_`v' 
	}
	tempfile  dolabs
	// store them in a temporary do-file
	label save using `dolabs'
		************************************************************************
		*****check if there are hierarchical structure between 2 variables******
		************************************************************************	
			quietly svyEstimate `tuple' , param(`parameter') var(`var') alldim(`alldim') subpop("`subpop'")	
			gen geoType="`:word `k' of `hiergeovars''"

			
			capture confirm variable `:word `k' of `hiergeovars''
			if _rc == 0 {
				run `dolabs'
				label values `:word `k' of `hiergeovars'' ld_`:word `k' of `hiergeovars''
				ren `:word `k' of `hiergeovars'' geoVar

			}
			
	*drop rownames
			
		if `worker_tasks'>0 append using `worker_result'
        save `worker_result', replace
        local ++worker_tasks
		*append using `odp_tab', force
		*save `odp_tab', replace
		*restore // restore the iniial dataset for the continuation of the loop on tuples
		}
	}
	}	
} // forvalues geovars


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
