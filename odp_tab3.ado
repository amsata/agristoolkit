cap program drop odp_tab3
program define odp_tab3, rclass
		
		 **  tablabelvar(varlist) indvar(varlist)
		*syntax [varlist(default=none)] [if], [  tabtitle(string asis) outfile(string) indicator(string asis) indicatorname(varlist) indvar(varlist) value(varlist)]
	syntax [varlist(default=none)] [if] , [tabtitle(string asis) header(string asis) outfile(string) indicator(string) indvar(varlist) value(varlist) by(varlist) rowtotal(string) decimal(string asis) indicatorname(varlist) replace ONmemory has_over highlight source(string) LABELdim(string asis) SUBPOPvar(varname) truncate valid(string)]
	
	***extract path, sheet name and start cell num from outfile
    // Strip leading/trailing whitespace
    local outfile = trim("`outfile'")

	local size_indicator: list sizeof indicator
    // Remove parentheses if present
   * local outfile = subinstr("`outfile'", "(", "", .)
   * local outfile = subinstr("`outfile'", ")", "", .)

    // Split by comma
    tokenize "`outfile'", parse(",")

    // Assign values
    local path = trim("`1'")
    local sheet_name = trim("`3'")
    local cell_start_num   = trim("`5'")
	
	if ("`sheet_name'"=="") {
	local sheet_name "TABLES"
	local cell_start_num=1
	}
	
	local counter=1
	foreach ind of local indicator {
	if (`counter'==1) {
		odp_tab2 `varlist' `if' ,  outfile(`outfile') indicator(`ind') indvar(`indvar') value(`value') by(`by') rowtotal(`rowtotal') decimal(`decimal') indicatorname(`indicatorname') `replace' `onmemory' `highlight' `has_over' source(`source') labeldim(`labeldim') subpopvar(`subpopvar') `truncate' valid(`valid') header(`header') tabtitle(`tabtitle')
		
		local counter=`counter'+1
	}
	else {
		if(`size_indicator'==`counter')	odp_tab2 `varlist' `if' ,  outfile("`path'", "`sheet_name'",  `r(tab_end_line)',`r(tab_start_cell_letter)') indicator(`ind') indvar(`indvar') value(`value') by(`by') rowtotal(`rowtotal') decimal(`decimal') indicatorname(`indicatorname') `onmemory' `highlight' `has_over' source(`source') labeldim(`labeldim') subpopvar(`subpopvar') `truncate' valid(`valid') header(`header') tabtitle(`tabtitle')
		
		else odp_tab2 `varlist' `if' ,  outfile("`path'", "`sheet_name'",  `r(tab_end_line)',`r(tab_start_cell_letter)') indicator(`ind') indvar(`indvar') value(`value') by(`by') rowtotal(`rowtotal') decimal(`decimal') indicatorname(`indicatorname') on `highlight' `has_over' source(`source') labeldim(`labeldim') subpopvar(`subpopvar') `truncate' valid(`valid') header(`header') tabtitle(`tabtitle')
		
	}  
	
	}
return scalar tab_start_line=`r(tab_start_line)'
return local tab_start_cell_letter= "`r(tab_start_cell_letter)'"
return local tab_end_cell_letter="`r(tab_end_cell_letter)'"
return scalar tab_end_line=`r(tab_end_line)'
end
