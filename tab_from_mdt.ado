cap program drop tab_from_mdt
program define tab_from_mdt, rclass


	syntax varlist(default=none) [if], indicator(string asis) outfile(string) [tabtitle(string asis)  indicatorname(varlist) indvar(varlist) over(string asis) value(varlist) rowtotal(string) by(varlist) DECimal(string) valid(string) replace ONmemory header(string asis) highlight source(string) LABELdim(string asis) SUBPOPvar(string asis)]
	
local number_ind: list sizeof indicator
local size_by: list sizeof by
local size_over: list sizeof over
local size_if: list sizeof if
local size_tabtitle: list sizeof tabtitle


capture which confirmdir.ado

if _rc {
di as error "please install confirmdir package by ssc install confirmdir"
exit 1

}
*TODO: absence de "on" dans precedant avec specificaion de "no" rend la generation lente: control a gerer

if("`size_tabtitle"!="") di as result `"Generating table: {cmd:`tabtitle'}..."'
else 					 di as result `"Generating table..."'
	
	
	*if ("`indvar'"=="") local indvar "Variable"
	*if ("`indicatorname'"=="") local indicatorname "IndicatorName"
	*if ("`value'"=="") local value "Value_str"
	
	local indicatorname_missing=0
	capture confirm variable `indicatorname'
	if _rc {
	capture confirm variable IndicatorName
	if _rc {
		local indicatorname_missing=1
	}
	}
	
		if ("`indvar'"=="") {
		capture confirm variable Variable 
		if _rc {
			di as error "Please specify the option 'indvar'"
			exit 198
		}
		else {
			local indvar "Variable"
		}
	}
	
	***extract path, sheet name and start cell num from outfile
    // Strip leading/trailing whitespace
    local outfile = trim("`outfile'")
    // Split by comma
    tokenize "`outfile'", parse(",")
    // Assign values
    local path = trim("`1'")
    local sheet_name = trim("`3'")
    local cell_start_num   = trim("`5'")
	
	*if ("`sheet_name'"=="") {
	*local sheet_name "TABLES"
	*local cell_start_num=1
*	}
	
/*	
	if regexm("`indicator'", "^regex=") {
	preserve
        // Extract the pattern from the option
        local pat : subinstr local indicator "regex=" "", all
		local pat:list clean pat
        // Keep only observations matching the regex
        tempvar keep_obs
        gen byte `keep_obs' = regexm(`indvar', `"`pat'"')

        // Collect unique values
        levelsof `indvar' if `keep_obs', local(matched_values)
		local indicator: list clean matched_values
        // Display or store in local macro
        *di `"Matched values: `matched_values'"'
		restore
    }*/
	
if (`size_by'==0) {
	if(`size_over'==0) {

		odp_tab `varlist' `if' , tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indicatorname(`indicatorname')  ///
		indvar(`indvar') value(`value') rowtotal(`rowtotal') decimal(`decimal') valid(`valid') `replace' `onmemory' header(`header') `highlight' source(`source') labeldim(`labeldim') subpopvar(`subpopvar')
		local tab_start_line=`r(tab_start_line)'
		local tab_end_line=`r(tab_end_line)'
		local tab_end_cell_letter="`r(tab_end_cell_letter)'"

	}
	else if (`size_over'==1 & `number_ind'==1) {
			odp_tab2 `varlist' `if' , tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indicatorname(`indicatorname')  ///
		indvar(`indvar') value(`value') rowtotal(`rowtotal') decimal(`decimal') valid(`valid') `replace' `onmemory' header(`header') `highlight' source(`source') labeldim(`labeldim') subpopvar(`subpopvar') by(`over')
		
		local tab_start_line=`r(tab_start_line)'
		local tab_end_line=`r(tab_end_line)'
		local tab_end_cell_letter="`r(tab_end_cell_letter)'"

	
	}
	else {
	
		qui levelsof `over', local(my_macro)
		local size_cat_over: list sizeof my_macro
		local init=0
		foreach v of local my_macro {
			local init=`init'+1
			if (`init'==1){
					local lbl : label (`over') `v'
					
				gen keepflag = 0
				foreach d of local indicator {
					qui replace keepflag = 1 if `indvar' == "`d'"
				}
				if(`size_if'>0) qui count `if' &  `over'==`v' & keepflag==1
				else qui count if `over'==`v' & keepflag==1
				else 
				local nobs = r(N)	
				di as result "over: `lbl'..."
				drop keepflag
				*keep if `over'==`v'
				if ( `nobs'>0) {
					if(`size_if'>0)  odp_tab `varlist' `if' 	 & `over'==`v', tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indicatorname(`indicatorname') indvar(`indvar') ///
					value(`value') rowtotal(`rowtotal') decimal(`decimal')  header("`lbl'") valid (`valid') `replace' on has_over `highlight' source(`source') labeldim(`labeldim') subpopvar(`subpopvar')

					else odp_tab `varlist' if `over'==`v', tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indicatorname(`indicatorname') indvar(`indvar') ///
					value(`value') rowtotal(`rowtotal') decimal(`decimal')  header("`lbl'") valid (`valid') `replace' on has_over `highlight' source(`source') labeldim(`labeldim') subpopvar(`subpopvar')
					
					
					
					local init=1
					local tab_start_cell_letter_in="`r(tab_start_cell_letter)'"
					local tab_start_line=`r(tab_start_line)'
					local tab_end_line=`r(tab_end_line)'
					local tab_end_cell_letter="`r(tab_end_cell_letter)'"
				}
			}
			else {
				local lbl : label (`over') `v'
				if (`nobs'>0) { // nobs in init==0
				local line_start=`r(tab_start_line)'
				local start_cell="`r(tab_end_cell_letter)'"
				local tab_end_line=`r(tab_end_line)'
				local tab_end_cell_letter="`r(tab_end_cell_letter)'"
				}
				else {
				local line_start=`tab_start_line'
				local tmp1 "`r(tab_end_cell_letter)'"
				if ("`tmp1'"!="") local start_cell="`r(tab_end_cell_letter)'"
				local tab_end_line=`tab_end_line'
				local tmp2 "`r(tab_end_cell_letter)'"
				if ("`tmp2'"!="") local tab_end_cell_letter="`r(tab_end_cell_letter)'"
			}
			
			gen keepflag = 0
			foreach d of local indicator {
				qui replace keepflag = 1 if `indvar' == "`d'"
			}
			if(`size_if'>0) qui count `if' &  `over'==`v' & keepflag==1
			else qui count if `over'==`v' & keepflag==1
			local nobs = r(N)
			di "over: `lbl'..."
			drop keepflag 
				if ( `nobs'>0) {
					if(`size_if'>0) odp_tab `varlist' `if' & `over'==`v' , outfile("`path'", "`sheet_name'", `line_start',`start_cell') indicator(`indicator') ///
					indicatorname(`indicatorname')  indvar(`indvar') value(`value') rowtotal(`rowtotal') decimal(`decimal')  header("`lbl'") valid(`valid') truncate on has_over `highlight' source(`source') subpopvar(`subpopvar')
					else odp_tab `varlist' if `over'==`v' , outfile("`path'", "`sheet_name'", `line_start',`start_cell') indicator(`indicator') ///
					indicatorname(`indicatorname')  indvar(`indvar') value(`value') rowtotal(`rowtotal') decimal(`decimal')  header("`lbl'") valid(`valid') truncate on has_over `highlight' source(`source') subpopvar(`subpopvar')
				}
				else {
					local tab_start_line=`line_start'
					local tab_end_line=`tab_end_line'
					*local tab_start_cell_letter="`start_cell'"
					local tab_end_cell_letter="`start_cell'"
				}
			}
		}
		if ((`init'==`size_cat_over') & "`onmemory'"=="") qui putexcel save
	}
}

else if (`size_by'!=0 & `number_ind'==1) {
		odp_tab2 `varlist' `if' , tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indvar(`indvar') value(`value') by(`by') rowtotal(`rowtotal') decimal(`decimal') indicatorname(`indicatorname') `replace' `onmemory' header(`header') `highlight' source(`source') labeldim(`labeldim')
		
local tab_start_line=`r(tab_start_line)'
local tab_end_line=`r(tab_end_line)'
local tab_end_cell_letter="`r(tab_end_cell_letter)'"
}
else {
odp_tab3 `varlist' `if' ,  outfile(`outfile') indicator(`indicator') indvar(`indvar') value(`value') by(`by') rowtotal(`rowtotal') decimal(`decimal') indicatorname(`indicatorname') `replace' header(`header') `onmemory' `highlight' source(`source') labeldim(`labeldim') tabtitle(`tabtitle')

local tab_start_line=`r(tab_start_line)'
local tab_end_line=`r(tab_end_line)'
local tab_end_cell_letter="`r(tab_end_cell_letter)'"
}

if (`indicatorname_missing'==1) drop IndicatorName

qui _excel_cell_shift, cell("`tab_end_cell_letter'") rowinc(0) colinc(2)
local end_cell="`r(cell)'"
local end_cell = subinstr("`end_cell'", ".", "", .)
*di "`end_cell'"

return scalar tab_start_line=`tab_start_line'
if(`size_over'>0) return local tab_start_cell_letter= "`tab_start_cell_letter_in'"
else return local tab_start_cell_letter= "`r(tab_start_cell_letter)'"
return local tab_end_cell_letter="`end_cell'"
return scalar tab_end_line=`tab_end_line'


*if("`path'"!="no") di `"{browse "`path'":Click here to open the Excel workbook}"'
if("`onmemory'"==""){
noisily  putexcel_describe
local path="`r(filename)'"
 di `"{browse "`path'":Click here to open the Excel workbook}"'
}

end
