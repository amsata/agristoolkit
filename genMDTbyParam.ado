capture program drop genMDTbyParam
program define genMDTbyParam
    local invocation `"`0'"'
    syntax [anything], [SETCluster(integer 0) *]
    if `setcluster'==0 {
        _agris_param_impl `invocation'
        exit
    }
    local original_dir `"`c(pwd)'"'
    local original_temp : copy global temp_file
    tempfile run_anchor
    local run_dir `"`run_anchor'_agris"'
    mkdir `"`run_dir'"'
    nobreak {
        quietly cd `"`run_dir'"'
        capture noisily break _agris_param_impl `invocation'
        local rc = _rc
        quietly cd `"`original_dir'"'
        global temp_file `"`original_temp'"'
        if `rc' {
            noisily display as error `"Parallel run failed; diagnostic files retained in `run_dir'"'
        }
        else {
            // Only remove an empty run directory; never recursively delete shared temp storage.
            capture rmdir `"`run_dir'"'
            if _rc noisily display as text `"Run finished; remaining diagnostics: `run_dir'"'
        }
        if `rc' exit `rc'
    }
end



cap program drop _agris_param_impl
program define _agris_param_impl
		
	syntax [varlist(default=none)] , PARAMeter(string asis) VARiable(string asis) [MARGINlabels(string asis) HIERGEOvars(string asis) ///
	GEOMARGINlabel(string) CONDitionals(string asis) subpop(string asis) setcluster(integer 0)]
	
	local n_geovar: list sizeof hiergeovars
	local n_varlist: list sizeof varlist
	local n_geomarginlabel: list sizeof geomarginlabel
	  
	tempfile tmp_data_odt
	qui save `tmp_data_odt', replace
	global temp_file "`tmp_data_odt'"

	preserve

	if(`n_geovar'==0) {
		qui findfile svyParallel.ado
		qui return list
		local mypath "`r(fn)'"
		run "`mypath'"
		local parameter: list clean parameter
		
		if(`setcluster'==0) {
			svyParallel "`varlist'" "`variable'" "`parameter'" `setcluster' "`subpop'"
			tempfile dataset_dims
			qui save `dataset_dims',  replace
		} 
		else {
        tempfile job_anchor
        mata: st_local("jobid", pathbasename(st_local("job_anchor")))
        local jobid = subinstr("`jobid'", ".", "", .)
        mata: parallel_sandbox(0, st_local("jobid"))
        capture noisily parallel, setparallelid(`jobid') prog(svyParallel) keep nodata: svyParallel "`varlist'" "`variable'" "`parameter'" `setcluster' "`subpop'"
        local job_rc = _rc
        local children = r(pll_n)
        mata: parallel_sandbox(2, st_local("jobid"))
        if `job_rc' exit `job_rc'
        _agris_parallel_collect, jobid("`jobid'") children(`children')
        quietly parallel clean, e(`jobid')

        tempfile dataset_dims
        quietly save `dataset_dims', replace
		}
	}
	else {
		qui findfile svyParallelGeo.ado
		qui return list
		local mypath "`r(fn)'"
		qui run "`mypath'"	
		local parameter: list clean parameter	
		if (`setcluster'==0) {
			svyParallelGeo "`varlist'" "`hiergeovars'" "`variable'" "`parameter'" `setcluster' "`subpop'"
			tempfile dataset_dims
			qui save `dataset_dims',  replace
		}
		else{
        tempfile job_anchor
        mata: st_local("jobid", pathbasename(st_local("job_anchor")))
        local jobid = subinstr("`jobid'", ".", "", .)
        mata: parallel_sandbox(0, st_local("jobid"))
        capture noisily parallel, setparallelid(`jobid') prog(svyParallelGeo) keep nodata: svyParallelGeo "`varlist'" "`hiergeovars'" "`variable'" "`parameter'" `setcluster' "`subpop'"
        local job_rc = _rc
        local children = r(pll_n)
        mata: parallel_sandbox(2, st_local("jobid"))
        if `job_rc' exit `job_rc'
        _agris_parallel_collect, jobid("`jobid'") children(`children')
        quietly parallel clean, e(`jobid')

        tempfile dataset_dims
        quietly save `dataset_dims', replace
		}
	}

	restore
	
	*generating for all diension
	preserve 
	qui findfile svyParallel.ado
	qui return list
	local mypath "`r(fn)'"
	run "`mypath'"

	if(`setcluster'==0) {
		svyParallel "" "`variable'" "`parameter'" `setcluster' "`subpop'"
		tempfile dataset_alldims
		qui save `dataset_alldims',  replace
		qui append using `dataset_dims'
	}
	else {
        tempfile job_anchor
        mata: st_local("jobid", pathbasename(st_local("job_anchor")))
        local jobid = subinstr("`jobid'", ".", "", .)
        mata: parallel_sandbox(0, st_local("jobid"))
        capture noisily parallel, setparallelid(`jobid') prog(svyParallel) keep nodata: svyParallel "" "`variable'" "`parameter'" `setcluster' "`subpop'"
        local job_rc = _rc
        local children = r(pll_n)
        mata: parallel_sandbox(2, st_local("jobid"))
        if `job_rc' exit `job_rc'
        _agris_parallel_collect, jobid("`jobid'") children(`children')
        quietly parallel clean, e(`jobid')

        tempfile dataset_alldims
        quietly save `dataset_alldims', replace
        quietly append using `dataset_dims'
	}

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

