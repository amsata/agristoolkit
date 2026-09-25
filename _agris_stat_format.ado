program define _agris_stat_format
    syntax [varlist(default=none)], PARAMeter(string) RAW(string) [MARGINlabels(string asis) HIERGEOvars(string asis) GEOMARGINlabel(string)]
    local n_geovar : list sizeof hiergeovars
    preserve
    quietly use "`raw'", clear
    quietly keep if __agris_statistic=="`parameter'"
    drop __agris_statistic
	quietly {	
		if(`n_geovar'==0) local final_varlist "`varlist'"
		else local final_varlist "geoType geoVar `varlist'"
		
		order `final_varlist' Indicator b n_Obs N_subPop CV_pct
		
		tempfile final_dataset
		qui save `final_dataset', replace

		restore
		* Extracting variable labels
		foreach v of local varlist {	
			*Exploring labelsof command would reduce this number of line
			local old_vl: value label `v'
			elabel copy `old_vl' ld_`v' 
		}
		* Adding the value label for the magins of dimensions
		local n_marginlabels: list sizeof marginlabels
		*local c: word count `varlist'
		local i = 1  // Initialize the iteration counter
		*local i = `i' + 1  // Increment the counter
		if (`n_marginlabels'>0) {
			foreach name of local marginlabels {
				local pos=strpos("`name'", "@")
				local varname=substr("`name'", 1, strpos("`name'", "@") - 1)
				local new_val_lab=substr("`name'", strpos("`name'", "@") + 1, .)
				cap label list ld_`varname'
				return list
				local n_lev=`r(max)'+1
				cap elabel list ld_`varname'
				return list 
				local lev `r(values)'
				local ap: list posof `"`n_lev'"' in lev
				if (`ap'==0) label define ld_`varname' `n_lev' "`new_val_lab'", add	
			}	
		}
		
		tempfile  dolabs
		label save using `dolabs' // store them in a temporary do-file
		use `final_dataset', clear
		run `dolabs' // get the value labels
		* see https://www.statalist.org/forums/forum/general-stata-discussion/general/251350-how-can-i-apply-value-labels-stored-in-different-dataset-into-my-primary-data
		local c: word count `varlist'
		
		if (`n_marginlabels'>0) {
			foreach name of local marginlabels {
				local pos=strpos("`name'", "@")
				local varname=substr("`name'", 1, strpos("`name'", "@") - 1)
				cap label list ld_`varname'
				return list
				local n_lev=`r(max)'
				qui replace `varname'= `n_lev' if `varname'==.
			}	
		}
		
		foreach v of local varlist {
			drop if `v'==.
			label values `v' ld_`v'	
		}

		if(`n_geovar'!=0) {

		local size_geomarginlabel: list sizeof geomarginlabel
			if(`size_geomarginlabel'==0){
				drop if geoVar==.
			} 
			else{
			
				cap label list labels_geovars
				return list
				local n_lev=`r(max)'+1
				label define labels_geovars `n_lev' `"`geomarginlabel'"', add	
				qui label list labels_geovars
				la li labels_geovars
				qui replace geoVar= `r(max)' if missing(geoVar) & geoType==""
				qui replace geoVar= `r(max)' if missing(geoVar) & geoType=="`:word 1 of `hiergeovars''"
				label val geoVar labels_geovars
				qui replace geoType=`"`geomarginlabel'"' if geoVar== `r(max)'
				drop if missing(geoVar)
			} 
			
		}
	
		gen Parameter="`parameter'"
		rename Indicator Variable
		rename se standError
		rename ll LL_confInt
		rename ul UL_confInt
		rename b Value
		format Value %15.5f
		order `final_varlist' Variable Parameter  Value 

	} // quietly

end

