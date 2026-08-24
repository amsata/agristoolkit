cap program drop odp_tab
program define odp_tab, rclass

	syntax varlist(default=none) [if], indicator(string asis) [tabtitle(string asis) truncate header(string asis) outfile(string) indicatorname(varlist) indvar(varlist) value(varlist) rowtotal (string) DECimal(string) valid (string) replace ONmemory has_over highlight source(string) LABELdim(string asis) SUBPOPvar(varname)]

					
/* TODO list
1. Add parser for valid
2. Controle when there is no observation after reshape whide
3. Controle code lines that depends on valid


*/
	local size_varlist:list sizeof varlist
	local size_tabtitle:list sizeof tabtitle
	local size_rowtotal:list sizeof rowtotal
	local size_header: list sizeof header
	local size_valid: list sizeof valid
	local size_source: list sizeof source
	local size_labeldim: list sizeof labeldim
	local size_subpopvar:list sizeof subpopvar

	if(`size_labeldim'>0) {
		if(`size_varlist'!=`size_labeldim') {
				di as error "the option {cmd: labeldim} should have {cmd: `size_varlist'} elements: label(s) for dimension(s) {cmd:`varlist'}"
		exit 198
		}
	}
	
	
	
	quietly {
****************defining default name for variables ****************************
	if (`size_valid'>0) {
		if ("`subpopvar'"=="") {
			capture confirm variable N_subPop
			if _rc {
				di as error "Please specify the option 'subpopvar'"
				exit 198
			}
			else {
				local subpopvar "N_subPop"
			}
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
	
	
	if ("`indicatorname'"=="") {
		capture confirm variable IndicatorName
		
		if _rc {
		*di as error "Please specify the option 'indicatorname'"
		gen IndicatorName=`indvar'
		local indicatorname="`indvar'"
		}
		else {
			local indicatorname "IndicatorName"
		}
	}
	
	
	if ("`value'"=="") {
		capture confirm variable Value_str
		if _rc {
			di as error "Please specify the option 'value'"
			exit 198
		}
		else {
			local value "Value_str"
		}
	}
	
	*checking if indicators are valide

levelsof `indvar', local(valid_indicators)
foreach v of local indicator {
	local pos_ind:list posof "`v'" in valid_indicators
	if (`pos_ind'==0) {
		di as error "`v' is not a valid indicator value in the variable `indvar' "
		exit 198
	}
}
	
	capture confirm string variable `value'
	
	if _rc {
	tempvar value_bis
	qui gen `value_bis'=cond(missing(`value'),"",string(`value', "%15.5f"))
	drop `value'
	ren `value_bis' `value'

	}
	
	
	
***************extract PATH, SHEET NAME and START CELL NUMBER from outfile ********
    local outfile = trim("`outfile'")  // Strip leading/trailing whitespace
    tokenize "`outfile'", parse(",")  // Split by comma
    local path = trim("`1'") // Assign values
    local sheet_name = trim("`3'") // Assign values
    local cell_start_num   = trim("`5'") // Assign values
	local cell_start   = trim("`7'") // Assign values

	if ("`sheet_name'"=="") local sheet_name "TABLES"
	if ("`cell_start_num'"=="") local cell_start_num=1
	if ("`cell_start'"=="") local cell_start "A"

	if ("`path'"!="no") {
	
	if ("`path'"=="") {
	 di as error "Please an excel file where tables will be saved"
	 exit 601
	}
	else {
	_check_excel_path, path("`path'")
	}
	
	if fileexists("`path'") {
		mata: excel_status("`path'")
		if ("`file_status'"=="open_or_locked") {
			di as error "Excel file open or locked"
			exit 603
		}
	}
	
		if ("`replace'"=="") {	
			capture putexcel describe
			
			if (_rc== 0) putexcel save
		
			putexcel set "`path'", modify sheet("`sheet_name'") open
			if _rc==3010 {
				di as error "Putexcel bug, please restart stata"
				exit  3010
			}
		}
		else {
			capture putexcel describe
			if (_rc== 0) {
				 capture putexcel save
				 if _rc==198 {
					di as error "Putexcel bug, please restart stata"
					exit  198
				}
			}
			
			cap putexcel set "`path'", replace sheet("`sheet_name'") open
			if _rc==3010 {
			
				di as error "Putexcel bug, please restart stata"
				exit  3010
			}
		} 
	}
	else {
		putexcel_describe
		local open_file_handle="`r(open_file_handle)'"
		if ("`open_file_handle'"=="no") {
			display as error "Not putexcel open for editing, please keep specify the 'onmemory' option in the previous table, if any, or specify valid excel path"
			exit 1
		}
	}

local alphabet "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BA BC BD BE BF BG BH BI BJ BK BL BM BN BO BP BQ BR BS BT BU BV BW BX BY BZ CA CB CC CD CE CF CG CH CI CJ CK CL CM CN CO CP CQ CR CS CT CU CV CW CX CY CZ DA DB DC DD DE DF DG DH DI DJ DK DL DM DN DO DP DQ DR DS DT DU DV DW DX DY DZ EA EB EC ED EE EF EG EH EI EJ EK EL EM EN EO EP EQ ER ES ET EU EV EW EX EY EZ"
local col_num_start_cell:list posof "`cell_start'" in alphabet


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
    }

	preserve

	***extract indocator labels from the variable containing the indicator name	
	gen tablabel = regexs(0) if regexm(`indicatorname', "#.*")	
	replace tablabel = subinstr(tablabel, "#", "", .)
	replace tablabel=`indicatorname' if tablabel==""

	local TitleCell_num=`cell_start_num'
	
	
/************* SETTING THE TABLE COLUMN HEADINGS ********************************/
	if (`size_header'>0) local TabTitleCell_num=`TitleCell_num'+2
	else local TabTitleCell_num=`TitleCell_num'+1
	local TitleCell="`cell_start'`TitleCell_num'"
	local TabTitleCell="`cell_start'`TabTitleCell_num'"
	


	if ("`if'"!="") keep `if'
	
	tempvar keepflag
	gen `keepflag' = 0
	foreach d of local indicator {
		replace `keepflag' = 1 if `indvar' == "`d'"
	}
	keep if `keepflag'==1
	drop `keepflag'
	
	tempfile filtered_dataset
	save `filtered_dataset', replace
	
	keep `varlist' `indvar' tablabel
	cap isid `varlist' `indvar'
	if _rc {
		di as error "Error: `varlist' and `indvar' do not uniquely identify row in the dataset of the given subset specify in '`if'' !"
		exit 1
	}
	order `varlist' `indvar' tablabel
	tempfile dataset_to_use
	save `dataset_to_use', replace
	
	****************************************************************************
	*********** ADDING VALID IF ALL INDICATOR HAVE THE SAME POPULATION**********
	****************************************************************************
	if (`size_valid'>0) {
		use  `filtered_dataset', clear
		keep `varlist' `indvar' `subpopvar'
		replace `subpopvar'=round(`subpopvar')
		reshape wide `subpopvar', i(`varlist') j(`indvar') string
		ds, has(type numeric)
		mkmat `r(varlist)', matrix(M)
		mat list M
		mata: allcols_equal("M", "max_diff")
		
		if (`max_diff'==0) {
			use `filtered_dataset',clear
			keep if `indvar' =="`:word 1 of `indicator''"
			keep `varlist' `indvar'
			replace `indvar'="Valid"
			local indicator Valid `indicator'
			if (`size_valid'==0) gen tablabel="Valid"
			else gen tablabel="`valid'"
			order `varlist' `indvar' tablabel
			tempfile valid_dataset
			save `valid_dataset', replace
		}

		use `dataset_to_use',clear
		if (`max_diff'==0) append using `valid_dataset'
	}
	else {
		use `dataset_to_use',clear
	}
	
	
	************create order****************
	gen indvar2=.
	local n_ind:list sizeof indicator
	forvalues i=1/`n_ind' {
	replace indvar2=`i' if `indvar'== "`:word `i' of `indicator''"
	}
	cap label drop ind_label
	label define ind_label 1 "`:word 1 of `indicator''"
		forvalues i=2/`n_ind' {
			label define ind_label `i' `"`:word `i' of `indicator''"', add
		}
	label val indvar2 ind_label
	drop `indvar'
	ren indvar2 `indvar'
	*************end order creation ***********
	
	reshape wide tablabel, i(`varlist') j(`indvar')
	
	*fill all the missing
	
			unab all_vars: *
			local indvar_bis:list all_vars-varlist

		foreach v of local indvar_bis {
			gsort -`v'
			replace `v' = `v'[_n-1] if missing(`v') & _n > 1
		}
		
		********adding labels for varlist for additional formating
	

	foreach v of local varlist {
	
		if "`: value label `v''" != "" {
			tostring  `v', gen(`v'_bis)
			drop `v' 
			ren `v'_bis `v'
			}
		replace `v'="`v'"
	}

	
	if (`size_labeldim'>0) {
		forvalues i=1/`size_varlist' {
		replace `:word `i' of `varlist''="`:word `i' of `labeldim''"
		}	

	}
	
	
	keep if _n==1
	
	if ("`truncate'"!="") drop `varlist'

	if (`size_rowtotal'!=0) gen Total= `"`rowtotal'"'
	local end_num=`TabTitleCell_num'+1
	local cell_end "`cell_start'`end_num'"
*===============================================================================
/*======================= Write the data in excel =============================*/

unab vars:*
local nrows = _N
local ncols : word count `vars'
local startcell "`TabTitleCell'"
forvalues i = 1/`nrows' {
    local rowinc = `i' - 1
    forvalues j = 1/`ncols' {
        local colinc = `j' - 1
        local v : word `j' of `vars'
        quietly _excel_cell_shift, cell("`startcell'") rowinc(`rowinc') colinc(`colinc')
        local xcell "`r(cell)'"
        capture confirm string variable `v'
        if !_rc {
            putexcel `xcell' = "`=`v'[`i']'"
        }
        else {
            putexcel `xcell' = `=`v'[`i']'
        }
    }
}

	qui describe
	local leng_tab=`r(k)'+`col_num_start_cell'-1
	local leng_tab_final=`r(k)'+`col_num_start_cell'
	local tab_end_cell_letter="`:word `leng_tab' of `alphabet''"
	local tab_after_end_cell_letter="`:word `leng_tab_final' of `alphabet''"

	local EndTabTitleCell="`:word `leng_tab' of `alphabet''`TabTitleCell_num'"
	putexcel (`TabTitleCell':`EndTabTitleCell'), border(all, thin, black) bold font("Arial",10)  vcenter txtwrap
	if("`has_over'"!="") {
		putexcel (`TabTitleCell':`EndTabTitleCell'), border(top, medium, black)
		putexcel (`TabTitleCell':`EndTabTitleCell'), border(bottom, medium, black)
	}
		****specify header cell
	if(`size_header'>0){
	local line_header_cell=`TitleCell_num'+1
	if("`truncate'"=="") local pos_header_cell=`col_num_start_cell'+`size_varlist'
	else local pos_header_cell=`col_num_start_cell'
	local letter_header_cell= "`:word `pos_header_cell' of `alphabet''"
	local header_cell_start= "`letter_header_cell'`line_header_cell'"
	local header_cell_end="`tab_end_cell_letter'`line_header_cell'"
	if("`has_over'"!="") putexcel `header_cell_start'=`header',bold font("Arial",10) border(all, medium, black)
	else                 putexcel `header_cell_start'=`header',bold font("Arial",10) border(all, thin, black)
	*putexcel `header_cell_start',
	
	di "header_cell_end: `header_cell_start'"
	di "header_cell_end=`header_cell_end'"

	putexcel (`header_cell_start':`header_cell_end'), merge  hcenter  vcenter
	}

	

	*********************ADDING VALID*********************************
	
	if(`size_valid'>0) {
		if (`max_diff'==0) {
		use `filtered_dataset',clear
		keep if  `indvar'=="`:word 2 of `indicator''"
		keep `varlist' `indvar' `subpopvar'
		replace `subpopvar'=round(`subpopvar')
		gen `value' = string(`subpopvar', "%15.2f")
		drop `subpopvar'
		replace `indvar'="Valid"
		order `varlist' `indvar' `value'
		tempfile valid_dataset
		save `valid_dataset', replace
		}
		
		use `filtered_dataset', clear
		keep  `varlist' `indvar' `value'
		order `varlist' `indvar' `value'
		if (`max_diff'==0) append using `valid_dataset'
	}
	else {
	use `filtered_dataset',clear
	keep `varlist' `indvar' `value'
	order `varlist' `indvar' `value'
	}

	

	************create order****************
	gen indvar2=.
	local n_ind:list sizeof indicator
	forvalues i=1/`n_ind' {
	replace indvar2=`i' if `indvar'== "`:word `i' of `indicator''"
	}
	cap label drop ind_label
	label define ind_label 1 "`:word 1 of `indicator''"
		forvalues i=2/`n_ind' {
			label define ind_label `i' `"`:word `i' of `indicator''"', add
		}
	label val indvar2 ind_label
	drop `indvar'
	ren indvar2 `indvar'
	*************end order creation ***********
	
	
	****************number of masked cells and cells with zero ***************
	gen strrrr=`value'
	*replace strrrr="0" if strrrr=="0[w]"
	destring strrrr, generate(strrrr_bis) force
	qui count 
	local number_of_cells=`r(N)'
	count if missing(strrrr_bis)
	local masked_cells_number=`r(N)'
	count if strrrr_bis==0
	local zero_cells_number=`r(N)'
	local per_masked_cells=`masked_cells_number'/`number_of_cells'*100
	local per_zero_cells=`zero_cells_number'/`number_of_cells'*100
	local per_masked_cells=round(`per_masked_cells',1)
	local per_zero_cells=round(`per_zero_cells')
	drop strrrr strrrr_bis
	
	reshape wide `value', i(`varlist') j(`indvar')

/*==========================================================================
					ADDING rowtotal IF SPECIFIED
==========================================================================*/
	
	if (`size_rowtotal'!=0) {
		*because of label it connot compute sum
		unab all_vars: *
		local nom_valid="Value_str1"
		local indvar2:list all_vars-varlist 
		
		if (`size_valid'>0) {
			if(`max_diff'==0) local indvar2: list indvar2-nom_valid
		}

		foreach v of local indvar2 {
			gen `v'_bis=`v'
			destring `v'_bis, generate(addd_`v') force
			drop `v'_bis
		}
		ds addd_*
		egen Total=rowtotal(`r(varlist)')
		ds addd_*
		drop `r(varlist)'
		local rowtot_name="Total"
		
	*convert rowtotal to string
	qui gen Total_bis=cond(missing(Total),"",string(Total, "%15.5f"))
	drop Total
	ren Total_bis Total
	
	gen byte has_flag = 0
	foreach v of local indvar2 {
		replace has_flag = 1 if trim(`v') != "" & missing(real(trim(`v')))
	}
	
	replace Total="[-]" if has_flag==1
	drop has_flag
	}
	
	********replacing empty  with the the flag [:]
	unab all_vars: *
	local indvar2:list all_vars-varlist
	
	if (`size_rowtotal'!=0) local indvar2:list indvar2-rowtot_name
	
	foreach v of local indvar2 {
	replace `v'="[:]" if `v'==""
}


	if ("`truncate'"!="") drop `varlist'

	*export excel using  "`path'", sheet("`sheet_name'", modify) cell(`cell_end')
/*** Adding table values in excel ***/
unab vars:*
local nrows = _N
local ncols : word count `vars'
local startcell "`cell_end'"
forvalues i = 1/`nrows' {
    local rowinc = `i' - 1
    forvalues j = 1/`ncols' {
        local colinc = `j' - 1
        local v : word `j' of `vars'
        quietly _excel_cell_shift, cell("`startcell'") rowinc(`rowinc') colinc(`colinc')
        local xcell "`r(cell)'"
        capture confirm string variable `v'
        if !_rc {
			local raw "`=`v'[`i']'"
			local my_scal = real("`raw'")
			if !missing(`my_scal') {
				putexcel `xcell' = `my_scal', nformat("_* #,##0.00_-") 
				}
			else {
				putexcel `xcell' = "`raw'", font("Arial",9, "166 166 166")
			}
        }
        else {
            local vallab : value label `v'
            if "`vallab'" != "" {
                local code = `v'[`i']
                local lab : label `vallab' `code'
                putexcel `xcell' = "`lab'"
            }
            else {
                putexcel `xcell' = `=`v'[`i']' 
            }
        }
		
		putexcel `xcell', border(all, thin, "217 217 217") 
    }
}		
********************************************************************************
***************************TABLE FORMATING**************************************
********************************************************************************
	if (`size_tabtitle'!=0) putexcel `TitleCell' = `tabtitle'
	qui count 
	local TabCellEnd_num=`r(N)'+`end_num'-1
	local TabCellEnd= "`cell_start'`TabCellEnd_num'"

	qui describe
	local leng_tab=`r(k)'+`col_num_start_cell'-1
	local EndTabCell="`:word `leng_tab' of `alphabet''`TabCellEnd_num'"

	if (`size_header'>0 & "`truncate'"=="") {
		local header_start_cell="`TabTitleCell'"

	forvalues i=1/`size_varlist' {
		quietly _excel_cell_shift, cell("`header_start_cell'") rowinc(-1) colinc(0)
		local end_header_cell "`r(cell)'"
	if(`size_labeldim'>0)	putexcel `end_header_cell'="`:word `i' of `labeldim''"
	else 					putexcel `end_header_cell'="`:word `i' of `varlist''"
	if("`has_over'"=="") putexcel (`end_header_cell':`header_start_cell'), border(all, thin, black) bold
	else 				 putexcel (`end_header_cell':`header_start_cell'), border(all, medium, black) bold
	putexcel (`end_header_cell':`header_start_cell'), merge  hcenter  vcenter 
	quietly _excel_cell_shift, cell("`header_start_cell'") rowinc(0) colinc(1)
		local header_start_cell "`r(cell)'"
	}
	}

	*putexcel (`TabCellEnd':`EndTabCell'), border(top, thin) bold font("Arial",10) // if margin is absent
	if ("`has_over'"=="") {		
		if ("`highlight'"!="") {
			putexcel (`TabCellEnd':`EndTabCell'), border(top, thin, black) bold
			putexcel (`TabCellEnd':`EndTabCell'), border(bottom, thin, black)
		}
		else {
			putexcel (`TabCellEnd':`EndTabCell'), border(bottom, thin, black)
		}
	} 	
	else {
		if ("`highlight'"!="") {
			putexcel (`TabCellEnd':`EndTabCell'), border(top, medium, black) bold
			putexcel (`TabCellEnd':`EndTabCell'), border(bottom, medium, black)
		}
		else {
			putexcel (`TabCellEnd':`EndTabCell'), border(bottom, medium, black)
		}
	}
	
	
	if ("`truncate'"=="") putexcel (`TabTitleCell':`TabCellEnd'), border(right, thin, black) bold font("Arial",10)
	**adding thin line after valide
	if (`size_valid'>0) {
		if (`max_diff'==0) {
			quietly _excel_cell_shift, cell("`TabTitleCell'") rowinc(0) colinc(1)
			local valid_cell_top "`r(cell)'"
			quietly _excel_cell_shift, cell("`TabCellEnd'") rowinc(0) colinc(1)
			local valid_cell_bottom "`r(cell)'"	
			if ("`truncate'"=="") putexcel (`valid_cell_top':`valid_cell_bottom'), border(right,thin,black)
			else 				  putexcel (`TabTitleCell':`TabCellEnd'), border(right,thin,black)
		}
	}
	
	
		*putexcel (`TabTitleCell':`EndTabCell'), border(all, thin, blue)  
	putexcel (`TabTitleCell':`TabCellEnd'), border(left, thin, black)  
	

	if ("`truncate'"=="") {
		putexcel (`EndTabTitleCell':`EndTabCell'), border(right, thin, black) font("Arial",10)
	}
	else {
		putexcel (`EndTabTitleCell':`EndTabCell'), border(right, medium, black) font("Arial",10)
	}
	
	putexcel (`TabTitleCell':`EndTabCell'),  hcenter vcenter
	putexcel (`cell_end':`EndTabCell'), font("Arial",9) right
	if ("`truncate'"=="" & "`has_over'"=="") {
	putexcel (`TabTitleCell':`TabCellEnd'),  left
	}
	else {
	quietly _excel_cell_shift, cell("`TabTitleCell'") rowinc(-1) colinc(0)
	local end_header_cell "`r(cell)'"
	putexcel (`end_header_cell':`TabCellEnd'),  border(left, medium, black)
	}
	
	if (`size_header'>0 & "`truncate'"=="" & "`has_over'"!="") {
	quietly _excel_cell_shift, cell("`TabTitleCell'") rowinc(-1) colinc(0)
	local end_header_cell "`r(cell)'"
	putexcel (`end_header_cell':`TabCellEnd'), border(right, medium, black)
	}
	
	*if(`size_tabtitle'>0) {
	
	if ("`truncate'"=="") quietly _excel_cell_shift, cell("`TitleCell'") rowinc(0) colinc(`=`leng_tab'-1')
	else 				  quietly _excel_cell_shift, cell("`TitleCell'") rowinc(0) colinc(`=`leng_tab'-2')

		local tabtitle_left_cell "`r(cell)'"
		putexcel (`TitleCell':`tabtitle_left_cell'), merge border(left,thin,white)
		putexcel (`TitleCell':`tabtitle_left_cell'),  border(right,thin,white)
		putexcel (`TitleCell':`tabtitle_left_cell'),  border(top,thin,white)
		if("`truncate'"=="") putexcel (`TitleCell'),  font("Arial",10,"black") italic
	*}

	
	
	if (`size_source'>0) {
		quietly _excel_cell_shift, cell("`TabCellEnd'") rowinc(1) colinc(0)
		local source_note_cell "`r(cell)'"
		quietly _excel_cell_shift, cell("`EndTabCell'") rowinc(1) colinc(0)
		local source_note_cell_end "`r(cell)'"
		local source_note="Source: `source'"
		putexcel (`source_note_cell':`source_note_cell_end'), merge border(left,thin,white)
		putexcel (`source_note_cell':`source_note_cell_end'),  border(right,thin,white)
		putexcel (`source_note_cell':`source_note_cell_end'),  border(bottom,thin,white)
		if ("`truncate'"=="") putexcel `source_note_cell'="`source_note'",  left font("Arial",9,black) italic
		local TabCellEnd_num=`TabCellEnd_num'+1
	}
	************ Masked cells footnote
	local maskedCellNote_cell_num=`TabCellEnd_num'+1
	local empy_cell_meta="`cell_start'`maskedCellNote_cell_num'"
	local maskedCellNote="Percentage of masked cells: `per_masked_cells'%"
	putexcel `empy_cell_meta' = "`maskedCellNote'"
	putexcel (`empy_cell_meta'),  left font("Arial",9,"red") italic

	**************** Zero cells footnote
	local zeroCellNote_cell_num=`TabCellEnd_num'+2
	local zero_cell_meta="`cell_start'`zeroCellNote_cell_num'"
	local zeroCellNote="Percentage of cells with value zero(0): `per_zero_cells'%"
	putexcel `zero_cell_meta' = "`zeroCellNote'"
	putexcel (`zero_cell_meta'),  left font("Arial",9,"red") italic
	restore
	
if ("`onmemory'"=="") qui putexcel save
}
	
return scalar tab_start_line=`cell_start_num'
return local tab_start_cell_letter="`cell_start'"
return local tab_end_cell_letter="`tab_after_end_cell_letter'"
return scalar tab_end_line=`TabCellEnd_num'+4

end
	

	mata:
void allcols_equal(string scalar matname, string scalar localname)
{
    real matrix M
    real scalar all_equal

    // Load Stata matrix into Mata
    M = st_matrix(matname)

    // Check if all columns equal the first one
    all_equal = all(M :== M[,1])

    // Put result into a local macro in Stata
    st_local(localname, strofreal(all_equal))
}
end

cap mata: mata drop excel_status()
mata:

void excel_status(string scalar filename)
{
    real scalar fh


    fh = _fopen(filename, "r")

    if (fh < 0) {
        st_local("file_status", "open_or_locked")
    }
    else {
        fclose(fh)
        st_local("file_status", "closed")
    }
}

end

mata:
if (direxists("C:/MyData/")) {
    display("The directory exists!")
}
else {
    display("The directory does not exist.")
}
end