cap program drop odp_tab3
program define odp_tab3, rclass
		
		 **  tablabelvar(varlist) indvar(varlist)
		*syntax [varlist(default=none)] [if], [  tabtitle(string asis) outfile(string) indicator(string asis) indicatorname(varlist) indvar(varlist) value(varlist)]
	syntax [varlist(default=none)] [if] , [tabtitle(string asis) header(string asis) outfile(string) indicator(string) indvar(varlist) value(varlist) by(varlist) rowtotal(string) decimal(string asis) indicatorname(varlist) replace ONmemory has_over highlight source(string) LABELdim(string asis) SUBPOPvar(varname) truncate valid(string) BYIndicator over(varlist max=3) OMITabsentcomb PROGress]
	
    // New orchestration branch. The original by() branch below is unchanged.
    if "`byindicator'" != "" {
        if "`by'" != "" {
            di as error "byindicator cannot be combined with by()"
            exit 198
        }
        local dimensions : word count `over'
        if "`omitabsentcomb'" != "" & !inrange(`dimensions',2,3) {
            di as error "omitabsentcomb requires two or three variables in over()"
            exit 198
        }
        local unique : list uniq indicator
        local count : word count `indicator'
        if `count'==0 | `: word count `unique''!=`count' {
            di as error "indicator() requires distinct indicator IDs"
            exit 198
        }
        if "`indvar'"=="" local indvar Variable
        if "`value'"=="" local value Value_str
        if "`indicatorname'"=="" {
            capture confirm variable IndicatorName
            if !_rc local indicatorname IndicatorName
            else local indicatorname `indvar'
        }
        confirm string variable `indvar' `indicatorname'
        confirm variable `value'
        preserve
        if `"`if'"'!="" quietly keep `if'
        // Validate all indicator selections before opening the workbook.
        tempvar key duplicates
        quietly egen long `key' = group(`varlist' `over')
        quietly bysort `indvar' `key': generate long `duplicates' = _N
        local i=0
        foreach ind of local indicator {
            local ++i
            quietly count if `indvar'==`"`ind'"'
            if !r(N) {
                di as error `"indicator `ind' has no observations in the selected data"'
                exit 2000
            }
            quietly levelsof `indicatorname' if `indvar'==`"`ind'"', local(names)
            local name_count : list sizeof names
            if `name_count'!=1 {
                di as error `"indicator `ind' must have one nonmissing label"'
                exit 459
            }
            local name : word 1 of `names'
            local hash = strpos(`"`name'"',"#")
            if `hash' local name = substr(`"`name'"',1,`hash'-1)
            local title`i' `"`name'"'
            if `"`tabtitle'"'!="" {
                local template `tabtitle'
                local title`i' : subinstr local template "{title}" `"`name'"', all
            }
            quietly count if `indvar'==`"`ind'"' & (missing(`key') | `duplicates'>1)
            if r(N) {
                di as error "row and over dimensions must uniquely identify nonmissing keys per indicator"
                exit 459
            }
        }
        tempfile selected
        quietly save `selected'
        tokenize `"`outfile'"', parse(",")
        local path = trim(`"`1'"')
        local sheet = trim(`"`3'"')
        local next = trim(`"`5'"')
        local col = upper(trim(`"`7'"'))
        if `"`sheet'"'=="" local sheet TABLES
        if "`next'"=="" local next 1
        if "`col'"=="" local col A
        _tab_from_mdt_excel, action(check) path(`"`path'"')
        local writerpath `"`path'"'
        local start = real("`next'")
        local widest = 0
        local i=0
        foreach ind of local indicator {
            local ++i
            quietly use `selected', clear
            quietly keep if `indvar'==`"`ind'"'
            if "`progress'"!="" noisily display as text "Indicator `i'/`count': `ind'"
            local writer odp_tab
            local columnopt
            if `dimensions'==1 {
                local writer odp_tab2
                local columnopt by(`over')
            }
            if `dimensions'>=2 {
                local writer _tab_from_mdt_over
                local columnopt over(`over') `omitabsentcomb'
            }
            `writer' `varlist', indicator(`ind') indvar(`indvar') indicatorname(`indicatorname') ///
                value(`value') `columnopt' outfile("`writerpath'", "`sheet'", `next', `col') ///
                tabtitle(`"`title`i''"') header(`header') rowtotal(`rowtotal') decimal(`decimal') ///
                valid(`valid') subpopvar(`subpopvar') `replace' onmemory `highlight' `progress' ///
                source(`source') labeldim(`labeldim')
            local next = r(tab_end_line)
            local endcol "`r(tab_end_cell_letter)'"
            // Legacy direct writers return two columns less spacing than the public command.
            if `dimensions'<2 {
                quietly _excel_cell_shift, cell("`endcol'") rowinc(0) colinc(2)
                local endcol = subinstr("`r(cell)'", ".", "", .)
            }
            local width=0
            forvalues j=1/`=length("`endcol'")' {
                local width=26*`width'+strpos("ABCDEFGHIJKLMNOPQRSTUVWXYZ",substr("`endcol'",`j',1))
            }
            if `width'>`widest' {
                local widest=`width'
                local lastcol "`endcol'"
            }
            local replace
            local writerpath no
        }
        if "`onmemory'"=="" {
            _tab_from_mdt_excel, action(save) path(`"`path'"')
        }
        restore
        return scalar tab_start_line=`start'
        return scalar tab_end_line=`next'
        return local tab_start_cell_letter "`col'"
        return local tab_end_cell_letter "`lastcol'"
        return scalar n_tables=`count'
        exit
    }

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

// Compatibility entry point for older callers.
capture program drop _tab_from_mdt_check_write
program define _tab_from_mdt_check_write
    version 14.1
    syntax, path(string)
    _tab_from_mdt_excel, action(check) path(`"`path'"')
end
