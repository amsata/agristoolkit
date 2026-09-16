cap program drop tab_from_mdt
program define tab_from_mdt, rclass
    version 14.1
    // Preserve the caller's data even when a legacy writer converts value().
    preserve
    capture noisily _tab_from_mdt_impl `0'
    local rc = _rc
    if !`rc' return add
    restore
    if `rc' exit `rc'
end

capture program drop _tab_from_mdt_impl
program define _tab_from_mdt_impl, rclass


	syntax varlist(default=none) [if], indicator(string asis) outfile(string) [tabtitle(string asis)  indicatorname(varlist) indvar(varlist) over(string asis) value(varlist) rowtotal(string) by(varlist) DECimal(string) valid(string) replace ONmemory header(string asis) highlight source(string) LABELdim(string asis) SUBPOPvar(string asis) OMITabsentcomb BYIndicator]
	
local number_ind: list sizeof indicator
local size_by: list sizeof by
local size_over: list sizeof over
local size_if: list sizeof if
local size_tabtitle: list sizeof tabtitle


* Nested headers share one row-label area for multi-indicator over() tables.
if `size_over' > 3 {
    di as error "over() accepts at most three variables"
    exit 198
}
* Count expanded variable ranges/wildcards too, before invoking a writer.
if `size_over' > 0 {
    unab expanded_over : `over'
    local size_over : word count `expanded_over'
    if `size_over' > 3 {
        di as error "over() accepts at most three variables"
        exit 198
    }
    local unique_over : list uniq expanded_over
    if `: word count `unique_over'' != `size_over' {
        di as error "over() requires distinct variables"
        exit 198
    }
    local over `expanded_over'
}
if "`omitabsentcomb'" != "" & !inrange(`size_over', 2, 3) {
    di as error "omitabsentcomb requires two or three variables in over()"
    exit 198
}
if "`byindicator'" != "" {
    if "`by'" != "" {
        di as error "byindicator cannot be combined with by()"
        exit 198
    }
    odp_tab3 `varlist' `if', byindicator indicator(`indicator') outfile(`outfile') over(`over') ///
        tabtitle(`tabtitle') indicatorname(`indicatorname') indvar(`indvar') value(`value') ///
        rowtotal(`rowtotal') decimal(`decimal') valid(`valid') `replace' `onmemory' ///
        header(`header') `highlight' source(`source') labeldim(`labeldim') subpopvar(`subpopvar') `omitabsentcomb'
    return add
    exit
}
if inrange(`size_over', 2, 3) | (`size_over' == 1 & `number_ind' > 1 & `size_by' == 0) {
    if `size_by' != 0 {
        di as error "by() cannot be combined with two- or three-variable over()"
        exit 198
    }
    _tab_from_mdt_over `varlist' `if', indicator(`indicator') outfile(`outfile') over(`over') ///
        tabtitle(`tabtitle') indicatorname(`indicatorname') indvar(`indvar') value(`value') ///
        rowtotal(`rowtotal') decimal(`decimal') valid(`valid') `replace' `onmemory' ///
        header(`header') `highlight' source(`source') labeldim(`labeldim') subpopvar(`subpopvar') `omitabsentcomb'
    return add
    exit
}


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
    if "`sheet_name'"=="" local sheet_name TABLES
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
	
        // Filter once, before enumerating categories. Temporary names avoid
        // collisions, and numeric group codes also support string categories.
        preserve
        if `"`if'"'!="" quietly keep `if'
        tempvar selected category
        quietly generate byte `selected'=0
        foreach d of local indicator {
            quietly replace `selected'=1 if `indvar'==`"`d'"'
        }
        quietly keep if `selected'
        quietly egen long `category'=group(`over'), label
        quietly levelsof `category', local(categories)
        if `"`categories'"'=="" exit 2000
        local init=0
        foreach v of local categories {
            local lbl : label (`category') `v'
            if !`init' {
                odp_tab `varlist' if `category'==`v', tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indicatorname(`indicatorname') indvar(`indvar') ///
                    value(`value') rowtotal(`rowtotal') decimal(`decimal') header(`"`lbl'"') valid(`valid') `replace' onmemory has_over `highlight' source(`source') labeldim(`labeldim') subpopvar(`subpopvar')
                local tab_start_cell_letter_in "`r(tab_start_cell_letter)'"
                local tab_start_line=r(tab_start_line)
                local tab_end_line=r(tab_end_line)
            }
            else {
                odp_tab `varlist' if `category'==`v', outfile("no", "`sheet_name'", `tab_start_line', `tab_end_cell_letter') indicator(`indicator') ///
                    indicatorname(`indicatorname') indvar(`indvar') value(`value') rowtotal(`rowtotal') decimal(`decimal') header(`"`lbl'"') valid(`valid') truncate onmemory has_over `highlight' source(`source') subpopvar(`subpopvar')
                local tab_end_line=max(`tab_end_line',r(tab_end_line))
            }
            local tab_end_cell_letter "`r(tab_end_cell_letter)'"
            local ++init
        }
        restore
        if "`onmemory'"=="" quietly _tab_from_mdt_excel, action(save) path(`"`path'"')
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
