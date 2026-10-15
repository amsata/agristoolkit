cap program drop tab_from_mdt
program define tab_from_mdt, rclass
    version 14.1
    local invocation `"`0'"'
    syntax varlist(default=none) [if], indicator(string asis) outfile(string asis) [tabtitle(string asis)  indicatorname(varlist) indvar(varlist) over(string asis) value(varlist) rowtotal(string) by(varlist) DECimal(string) DIGits(integer 2) valid(string) replace ONmemory header(string asis) highlight source(string) LABELdim(string asis) SUBPOPvar(string asis) OMITabsentcomb BYIndicator NOPROGress HIDEdims HIDENOTE]
    if !inrange(`digits',0,15) {
        di as error "digits() must be an integer between 0 and 15"
        exit 198
    }
    if "`hidedims'"!="" & `"`labeldim'"'!="" {
        di as error "labeldim() cannot be combined with hidedims because dimension columns are hidden."
        exit 198
    }
    quietly _tab_from_mdt_outfile, spec(`"`outfile'"')
    // Preserve the caller's data even when a legacy writer converts value().
    preserve
    capture noisily _tab_from_mdt_impl `invocation'
    local rc = _rc
    if !`rc' {
        local legacy_end "`r(tab_end_cell_letter)'"
        local immediate "`r(tab_next_cell_letter)'"
        return add
        if "`immediate'"=="" {
        quietly _excel_cell_shift, cell("`legacy_end'1") rowinc(0) colinc(-2)
        local immediate = regexr("`r(cell)'", "[0-9]+$", "")
        }
        return local tab_next_cell_letter "`immediate'"
    }
    restore
    if `rc' exit `rc'
    // Run after every successful writer branch, including its early exits.
    if "`onmemory'"=="" {
        capture noisily putexcel_describe
        if !_rc {
            local path `"`r(filename)'"'
            if `"`path'"'!="" noisily di `"{browse "`path'":Click here to open the Excel workbook}"'
        }
    }
end

capture program drop _tab_from_mdt_impl
program define _tab_from_mdt_impl, rclass


	syntax varlist(default=none) [if], indicator(string asis) outfile(string asis) [tabtitle(string asis)  indicatorname(varlist) indvar(varlist) over(string asis) value(varlist) rowtotal(string) by(varlist) DECimal(string) DIGits(integer 2) valid(string) replace ONmemory header(string asis) highlight source(string) LABELdim(string asis) SUBPOPvar(string asis) OMITabsentcomb BYIndicator NOPROGress HIDEdims HIDENOTE]
    if !inrange(`digits',0,15) {
        di as error "digits() must be an integer between 0 and 15"
        exit 198
    }
	
quietly _tab_from_mdt_outfile, spec(`"`outfile'"')
local outfile `"`r(normalized)'"'

// Resolve blank labels inside the preserved working data, before any writer.
local label_source `indicatorname'
if "`label_source'"=="" local label_source IndicatorName
local id_source `indvar'
if "`id_source'"=="" local id_source Variable
capture confirm string variable `label_source' `id_source'
if !_rc {
    quietly replace `label_source' = `id_source' if ustrtrim(`label_source')==""
}

local hidedim
if "`hidedims'"!="" local hidedim hidedim
// Population counts are only used by valid(); ignore unused metadata before
// writer syntax checks attempt to resolve subpopvar() as an existing variable.
if `"`valid'"' == "" local subpopvar
// Keep the writers' internal progress flag; expose opt-out at the public command.
local progress
if "`over'"!="" & "`noprogress'"=="" local progress progress
if "`progress'"!="" noisily display as text "Preparing over() tables..."

// Resolve regex selections once, before counting indicators or choosing a writer.
if regexm(strtrim(`"`indicator'"'), "^regex[ ]*=") {
    local pattern = strtrim(substr(`"`indicator'"', strpos(`"`indicator'"', "=")+1, .))
    if substr(`"`pattern'"',1,1)==char(34) & substr(`"`pattern'"',-1,1)==char(34) {
        local pattern = substr(`"`pattern'"',2,strlen(`"`pattern'"')-2)
    }
    if `"`pattern'"'=="" {
        di as error "indicator(regex=...) requires a nonempty pattern"
        exit 198
    }
    confirm string variable `id_source'
    tempvar regex_match
    capture quietly generate byte `regex_match' = regexm(`id_source', `"`pattern'"') `if'
    if _rc {
        di as error "Invalid indicator regular expression"
        exit 198
    }
    quietly count if `regex_match'==1 & `id_source'!=""
    if r(N)==0 {
        di as error "No indicators match the regular expression in the selected observations"
        exit 198
    }
    quietly levelsof `id_source' if `regex_match'==1 & `id_source'!="", local(matched_indicators)
    local indicator : list clean matched_indicators
    drop `regex_match'
}

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
        rowtotal(`rowtotal') decimal(`decimal') digits(`digits') `hidedim' valid(`valid') `replace' `onmemory' ///
        header(`header') `highlight' source(`source') `hidenote' labeldim(`labeldim') subpopvar(`subpopvar') `omitabsentcomb' `progress'
    return add
    if "`progress'"!="" {
        if "`onmemory'"!="" noisily display as text "Tables complete; workbook remains in memory."
        else noisily display as text "Tables complete; workbook saved."
    }
    exit
}
if inrange(`size_over', 2, 3) | (`size_over' == 1 & `number_ind' > 1 & `size_by' == 0) {
    if `size_by' != 0 {
        di as error "by() cannot be combined with two- or three-variable over()"
        exit 198
    }
    _tab_from_mdt_over `varlist' `if', indicator(`indicator') outfile(`outfile') over(`over') ///
        tabtitle(`tabtitle') indicatorname(`indicatorname') indvar(`indvar') value(`value') ///
        rowtotal(`rowtotal') decimal(`decimal') digits(`digits') `hidedim' valid(`valid') `replace' `onmemory' ///
        header(`header') `highlight' source(`source') `hidenote' labeldim(`labeldim') subpopvar(`subpopvar') `omitabsentcomb' `progress'
    return add
    if "`progress'"!="" {
        if "`onmemory'"!="" noisily display as text "Tables complete; workbook remains in memory."
        else noisily display as text "Tables complete; workbook saved."
    }
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
quietly _tab_from_mdt_outfile, spec(`"`outfile'"')
    local path `"`r(path)'"'
    local sheet_name `"`r(sheet)'"'
    local cell_start_num = r(row)
    local outfile_start_column "`r(column)'"
	
	*if ("`sheet_name'"=="") {
	*local sheet_name "TABLES"
	*local cell_start_num=1
*	}
	

	
if (`size_by'==0) {
	if(`size_over'==0) {

		odp_tab `varlist' `if' , tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indicatorname(`indicatorname')  ///
		indvar(`indvar') value(`value') rowtotal(`rowtotal') decimal(`decimal') digits(`digits') `hidedim' valid(`valid') `replace' `onmemory' header(`header') `highlight' source(`source') `hidenote' labeldim(`labeldim') subpopvar(`subpopvar')
		local tab_start_line=`r(tab_start_line)'
		local tab_end_line=`r(tab_end_line)'
		local tab_end_cell_letter="`r(tab_end_cell_letter)'"
local direct_next "`r(tab_next_cell_letter)'"

	}
	else if (`size_over'==1 & `number_ind'==1) {
			odp_tab2 `varlist' `if' , tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indicatorname(`indicatorname')  ///
		indvar(`indvar') value(`value') rowtotal(`rowtotal') decimal(`decimal') digits(`digits') `hidedim' valid(`valid') `replace' `onmemory' header(`header') `highlight' source(`source') `hidenote' labeldim(`labeldim') subpopvar(`subpopvar') by(`over') `progress'
		
		local tab_start_line=`r(tab_start_line)'
		local tab_end_line=`r(tab_end_line)'
		local tab_end_cell_letter="`r(tab_end_cell_letter)'"
local direct_next "`r(tab_next_cell_letter)'"

	
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
        local progress_total : word count `categories'
        local progress_last = clock("`c(current_date)' `c(current_time)'", "DMYhms")
        if "`progress'"!="" noisily display as text "Writing combinations: 0/`progress_total' (0%)"
        foreach v of local categories {
            local lbl : label (`category') `v'
            if !`init' {
                odp_tab `varlist' if `category'==`v', tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indicatorname(`indicatorname') indvar(`indvar') ///
                    value(`value') rowtotal(`rowtotal') decimal(`decimal') digits(`digits') `hidedim' header(`"`lbl'"') valid(`valid') `replace' onmemory has_over `highlight' source(`source') `hidenote' labeldim(`labeldim') subpopvar(`subpopvar')
                local tab_start_cell_letter_in "`r(tab_start_cell_letter)'"
                local tab_start_line=r(tab_start_line)
                local tab_end_line=r(tab_end_line)
            }
            else {
                odp_tab `varlist' if `category'==`v', outfile("no", "`sheet_name'", `tab_start_line', `tab_end_cell_letter') indicator(`indicator') ///
                    indicatorname(`indicatorname') indvar(`indvar') value(`value') rowtotal(`rowtotal') decimal(`decimal') digits(`digits') `hidedim' header(`"`lbl'"') valid(`valid') truncate onmemory has_over `highlight' source(`source') `hidenote' subpopvar(`subpopvar')
                local tab_end_line=max(`tab_end_line',r(tab_end_line))
            }
            local tab_end_cell_letter "`r(tab_end_cell_letter)'"
            local ++init
            if "`progress'"!="" {
                local progress_now = clock("`c(current_date)' `c(current_time)'", "DMYhms")
                if `progress_now'-`progress_last'>=1000 | `init'==`progress_total' {
                    noisily display as text "Writing combinations: `init'/`progress_total' (" as result %3.0f (100*`init'/`progress_total') as text "%)"
                    local progress_last = `progress_now'
                }
            }
        }
        restore
        if "`onmemory'"=="" quietly _tab_from_mdt_excel, action(save) path(`"`path'"')
	}
}

else if (`size_by'!=0 & `number_ind'==1) {
		odp_tab2 `varlist' `if' , tabtitle(`tabtitle') outfile(`outfile') indicator(`indicator') indvar(`indvar') value(`value') by(`by') rowtotal(`rowtotal') decimal(`decimal') digits(`digits') `hidedim' indicatorname(`indicatorname') `replace' `onmemory' header(`header') `highlight' source(`source') `hidenote' labeldim(`labeldim')
		
local tab_start_line=`r(tab_start_line)'
local tab_end_line=`r(tab_end_line)'
local tab_end_cell_letter="`r(tab_end_cell_letter)'"
local direct_next "`r(tab_next_cell_letter)'"
}
else {
odp_tab3 `varlist' `if' ,  outfile(`outfile') indicator(`indicator') indvar(`indvar') value(`value') by(`by') rowtotal(`rowtotal') decimal(`decimal') digits(`digits') `hidedim' indicatorname(`indicatorname') `replace' header(`header') `onmemory' `highlight' source(`source') `hidenote' labeldim(`labeldim') tabtitle(`tabtitle')

local tab_start_line=`r(tab_start_line)'
local tab_end_line=`r(tab_end_line)'
local tab_end_cell_letter="`r(tab_end_cell_letter)'"
local direct_next "`r(tab_next_cell_letter)'"
}

if "`progress'"!="" {
    if "`onmemory'"!="" noisily display as text "Tables complete; workbook remains in memory."
    else noisily display as text "Tables complete; workbook saved."
}
if (`indicatorname_missing'==1) drop IndicatorName

qui _excel_cell_shift, cell("`tab_end_cell_letter'") rowinc(0) colinc(2)
local end_cell="`r(cell)'"
local end_cell = subinstr("`end_cell'", ".", "", .)
*di "`end_cell'"

return scalar tab_start_line=`tab_start_line'
// Keep the requested start column independently of helpers that overwrite r().
return local tab_start_cell_letter "`outfile_start_column'"
return local tab_end_cell_letter="`end_cell'"
if "`direct_next'"!="" return local tab_next_cell_letter "`direct_next'"
return scalar tab_end_line=`tab_end_line'


end
