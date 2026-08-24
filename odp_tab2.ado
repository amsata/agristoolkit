cap program drop odp_tab2
program define odp_tab2, rclass
		
		 **  tablabelvar(varlist) indvar(varlist)
		*syntax [varlist(default=none)] [if], [  tabtitle(string asis) outfile(string) indicator(string asis) indicatorname(varlist) indvar(varlist) value(varlist)]
	syntax [varlist(default=none)] [if] , [tabtitle(string asis) header(string asis) outfile(string) indicator(string) indvar(varlist) value(varlist) by(varlist) rowtotal(string) decimal(string asis) indicatorname(varlist) replace ONmemory has_over highlight source(string) LABELdim(string asis) SUBPOPvar(varname) truncate valid(string)]

local n_if: list sizeof if
local size_varlist:list sizeof varlist
local size_tabtitle:list sizeof tabtitle
local size_rowtotal:list sizeof rowtotal
local size_header: list sizeof header
local size_valid: list sizeof valid
local size_source: list sizeof source
local size_labeldim: list sizeof labeldim
*local size_subpopvar:list sizeof subpopvar


	if(`size_labeldim'>0) {
		if(`size_varlist'!=`size_labeldim') {
				di as error "the option {cmd: labeldim} should have {cmd: `size_varlist'} elements: label(s) for dimension(s) {cmd:`varlist'}"
		exit 198
		}
	}


	
	
	*if ("`indvar'"=="") local indvar "Variable"
	*if ("`indicatorname'"=="") local indicatorname "IndicatorName"
	*if ("`value'"=="") local value "Value_str"
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

qui levelsof `indvar', local(valid_indicators)
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
		
	**start message 
	preserve
	qui if (`n_if'>0) keep `if'
	qui keep if `indvar'=="`indicator'"
	

	gen tablabel = regexr( `indicatorname' , "#.*", "")
	*qui replace tablabel = subinstr(tablabel, "#", "", .)
	*qui replace tablabel=`indicatorname' if tablabel==""
	
	*qui levelsof(tablabel),local(ind_name)
     local ind_name `"`=tablabel[1]'"'
	if (`size_tabtitle'>0) {
	*local ind_name_clean = subinstr(`"`ind_name'"', `"""', "", .)
		local tabtitle : subinstr local tabtitle "{title}" "`ind_name'", all
		
	}
	
	*if (`size_tabtitle'==0) di as result `"Generating table: {cmd:`ind_name'}..."'
	*else di as result `"Generating table: {cmd:`tabtitle'}..."'
	restore

***extract path, sheet name and start cell num from outfile
    // Strip leading/trailing whitespace
    local outfile = trim("`outfile'")
    // Split by comma
    tokenize "`outfile'", parse(",")
    // Assign values
    local path = trim("`1'")
    local sheet_name = trim("`3'")
    local cell_start_num   = trim("`5'")
	local cell_start   = trim("`7'") // Assign values
	
	if ("`sheet_name'"=="") local sheet_name "TABLES"
	if ("`cell_start_num'"=="") local cell_start_num=1
	if ("`cell_start'"=="") local cell_start A

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
	
	
	
quietly {

	******
local alphabet "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BA BC BD BE BF BG BH BI BJ BK BL BM BN BO BP BQ BR BS BT BU BV BW BX BY BZ"
local col_num_start_cell:list posof "`cell_start'" in alphabet

*putexcel set "`path'", modify sheet("`sheet_name'")  

preserve
local TitleCell_num=`cell_start_num'
if (`size_header'>0) local TabTitleCell_num=`TitleCell_num'+2
else local TabTitleCell_num=`TitleCell_num'+1
local TitleCell="`cell_start'`TitleCell_num'"
local TabTitleCell="`cell_start'`TabTitleCell_num'"

if (`n_if'>0) keep `if'
keep if `indvar'=="`indicator'"
keep `varlist' `by'

cap isid `varlist' `by'

if _rc {
		di as error "Error: `varlist' and `by' do not uniquely identify row in the dataset of the given subset specify in '`if'' !"
		exit 1
	}

gen sp=`by'

******convert by to string
if "`: value label `by''" != "" {
	decode  `by', gen(`by'_bis)
	drop `by' 
	ren `by'_bis `by'
	}

reshape wide `by', i(`varlist') j(sp) 



		*fill all the missing
	
			unab all_vars: *
			local indvar_bis:list all_vars-varlist

		foreach v of local indvar_bis {
			gsort -`v'
			replace `v' = `v'[_n-1] if missing(`v') & _n > 1
		}
	
foreach v of local varlist {

	if "`: value label `v''" != "" {
	tostring  `v', gen(`v'_bis)
	drop `v' 
	ren `v'_bis `v'
	}
	
	replace `v'="`v'"
}

keep if _n==1

if ("`rowtotal'"!="") gen Total= "`rowtotal'"

local end_num=`TabTitleCell_num'+1
local cell_end "`cell_start'`end_num'"
*if ("`replace'"!="") export excel using "`path'",  sheet("`sheet_name'", replace)  cell(`TabTitleCell')
*else export excel using "`path'",  sheet("`sheet_name'", modify)  cell(`TabTitleCell')

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
	
putexcel (`TabTitleCell':`EndTabTitleCell'), border(all, thin) bold font("Arial",10)  vcenter txtwrap

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

	
restore

preserve
if (`n_if'>0) keep `if'
keep if `indvar'=="`indicator'"
levelsof(`indicatorname'),local(ind_name)

keep `varlist' `by' `value'

	****************number of masked cells and cells with zero ***************
	gen strrrr=`value'
	replace strrrr="0" if strrrr=="0[w]"
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


reshape wide `value', i(`varlist') j(`by') 


if ("`rowtotal'"!="") {
	*because of label it connot compute sum
	unab all_vars: *
	local indvar2:list all_vars-varlist

	foreach v of local indvar2 {
	gen `v'_bis=`v'
	replace `v'_bis="0" if `v'_bis=="0[w]"
	destring `v'_bis, generate(addd_`v') force
	drop `v'_bis
	}

	ds addd_*
	*return list
	egen Total=rowtotal(`r(varlist)')
	ds addd_*
	drop `r(varlist)'
}

unab all_vars: *
local indvar2:list all_vars-varlist



if ("`rowtotal'"!="") local indvar2:list indvar2-rowtotal

foreach v of local indvar2 {
	replace `v'="[:]" if `v'==""
}

if ("`decimal'"!="") {
	foreach v of local indvar2 {
	replace `v' = subinstr(`v', ".", "`decimal'", .)
	}
}

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

if (`size_tabtitle'==0) putexcel `TitleCell' = `ind_name'
else putexcel `TitleCell' = `tabtitle'


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
/*	
putexcel (`TabCellEnd':`EndTabCell'), border(top, thin) bold font("Arial",10)
putexcel (`TabCellEnd':`EndTabCell'), border(bottom, thin) 
putexcel (`TabTitleCell':`TabCellEnd'), border(right, thin) bold font("Arial",10)
putexcel (`EndTabTitleCell':`EndTabCell'), border(right, thin) font("Arial",10)
putexcel (`TabTitleCell':`EndTabCell'),  hcenter vcenter
putexcel (`cell_end':`EndTabCell'),  nformat(number_d2) font("Arial",9) right
putexcel (`TabTitleCell':`TabCellEnd'),  left
putexcel (`TitleCell'),  left font("Arial",10,"blue") italic
*/
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
	
if ("`onmemory'"=="") qui putexcel save

restore
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