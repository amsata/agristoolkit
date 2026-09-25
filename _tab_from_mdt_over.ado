*! Nested column headers for one, two or three column dimensions.
capture program drop _tab_from_mdt_over
program define _tab_from_mdt_over, rclass

    version 14.1
    syntax varlist [if], indicator(string asis) outfile(string) over(varlist min=1 max=3) ///
        [tabtitle(string) indicatorname(varname) indvar(varname) value(varname) ///
        rowtotal(string) decimal(string) valid(string) replace ONmemory header(string) ///
        highlight source(string) LABELdim(string asis) SUBPOPvar(varname) OMITabsentcomb PROGress]

    local nd : word count `varlist'
    local dup : list varlist & over
    if `"`dup'"' != "" {
        di as error "row dimensions and over() dimensions must be distinct"
        exit 198
    }
    local nover : word count `over'
    local unique : list uniq over
    if `: word count `unique'' != `nover' {
        di as error "over() requires distinct variables"
        exit 198
    }
    if `"`labeldim'"' != "" & `: word count `labeldim'' != `nd' {
        di as error "labeldim() must contain one label per row dimension"
        exit 198
    }
    local indicators : list uniq indicator
    local ni : word count `indicator'
    if `ni' == 0 | `: word count `indicators'' != `ni' {
        di as error "indicator() must contain a nonempty list of distinct indicator IDs"
        exit 198
    }
    if "`indvar'" == "" local indvar Variable
    if "`value'" == "" local value Value_str
    confirm string variable `indvar'
    confirm variable `value'
    if "`indicatorname'" == "" {
        capture confirm variable IndicatorName
        if !_rc local indicatorname IndicatorName
        else local indicatorname `indvar'
    }
    confirm string variable `indicatorname'
    if `"`valid'"' != "" {
        if "`subpopvar'" == "" local subpopvar N_subPop
        confirm numeric variable `subpopvar'
    }
    local np = (`"`valid'"' != "")
    local nt = (`"`rowtotal'"' != "")
    local block = `ni' + `np' + `nt'

    // Everything that can be validated from the MDT is checked before opening Excel.
    preserve
    if `"`if'"' != "" quietly keep `if'
    tempvar iid rid text total flagged usable pop lo hi
    quietly generate long `iid' = .
    forvalues i=1/`ni' {
        local id : word `i' of `indicator'
        quietly count if `indvar' == `"`id'"'
        if r(N) == 0 {
            di as error `"indicator `id' has no observations in the selected data"'
            exit 2000
        }
        quietly replace `iid' = `i' if `indvar' == `"`id'"'
        quietly levelsof `indicatorname' if `iid'==`i', local(names)
        local name_count : list sizeof names
        if `name_count' != 1 {
            di as error `"indicator `id' must have one nonmissing label"'
            exit 459
        }
        local title`i' : word 1 of `names'
        // Match odp_tab's indicator-heading convention: use the suffix after #.
        local hash = strpos(`"`title`i''"', "#")
        if `hash' local title`i' = substr(`"`title`i''"', `hash'+1, .)
    }
    quietly keep if !missing(`iid')
    capture isid `varlist' `over' `iid'
    if _rc {
        di as error "row dimensions, over() dimensions and indicator must uniquely identify nonmissing keys"
        exit 459
    }
    quietly egen long `rid' = group(`varlist')
    quietly summarize `rid', meanonly
    local nr = r(max)
    local groups
    local combinations = 1
    forvalues level=1/`nover' {
        local dimension : word `level' of `over'
        tempvar g`level'
        quietly egen long `g`level'' = group(`dimension'), label
        local groups `groups' `g`level''
        quietly summarize `g`level'', meanonly
        local categories`level' = r(max)
        local combinations = `combinations' * `categories`level''
        forvalues category=1/`categories`level'' {
            local label`level'_`category' : label (`g`level'') `category'
        }
    }
    // Strides convert a category tuple into a zero-based column-block index.
    local remaining = `combinations'
    forvalues level=1/`nover' {
        local remaining = `remaining' / `categories`level''
        local stride`level' = `remaining'
    }
    // Presence depends only on selected observations, never estimate values.
    tempvar cid
    local compact = ("`omitabsentcomb'" != "")
    quietly generate long `cid' = .
    if `compact' {
        drop `cid'
        quietly egen long `cid' = group(`groups')
        quietly summarize `cid', meanonly
        local combinations = r(max)
        forvalues c=0/`=`combinations'-1' {
            local raw`c' = 0
            forvalues level=1/`nover' {
                quietly summarize `g`level'' if `cid'==`c'+1, meanonly
                local cat`c'_`level' = r(min)
                local raw`c' = `raw`c''+(`cat`c'_`level''-1)*`stride`level''
            }
        }
    }
    // Capture row labels by a shared row ID, never by position within a subset.
    quietly sort `rid' `groups' `iid'
    forvalues r=1/`nr' {
        quietly count if `rid'<`r'
        local obs = r(N)+1
        forvalues d=1/`nd' {
            local v : word `d' of `varlist'
            capture confirm string variable `v'
            if !_rc local row`r'_`d' = `v'[`obs']
            else {
                local code = `v'[`obs']
                local vl : value label `v'
                if "`vl'" != "" local row`r'_`d' : label `vl' `code'
                else local row`r'_`d' = string(`code', "%18.0g")
            }
        }
    }
    tokenize `"`outfile'"', parse(",")
    local path = trim(`"`1'"')
    local sheet = trim(`"`3'"')
    local startrow = trim(`"`5'"')
    local startcol = upper(trim(`"`7'"'))
    if `"`sheet'"' == "" local sheet TABLES
    if "`startrow'" == "" local startrow 1
    if "`startcol'" == "" local startcol A
    if !regexm("`startcol'", "^[A-Z]+$") | missing(real("`startrow'")) {
        di as error "outfile() requires a valid starting row and Excel column"
        exit 198
    }
    local sr = real("`startrow'")
    if `sr'<1 | `sr'!=floor(`sr') {
        di as error "starting row must be a positive integer"
        exit 198
    }
    local sc = 0
    forvalues i=1/`=length("`startcol'")' {
        local sc = 26*`sc' + strpos("ABCDEFGHIJKLMNOPQRSTUVWXYZ",substr("`startcol'",`i',1))
    }
    local width = `nd' + `combinations'*`block'
    local top = (`"`tabtitle'"'!="") + (`"`header'"'!="")
    local dataoff = `top'+`nover'+1
    local lastrow = `sr'+`dataoff'+`nr'-1
    local lastnote = `lastrow'+2+(`"`source'"'!="")
    if `sc'+`width'+2>16384 | `lastnote'+2>1048576 {
        di as error "table and returned placement coordinates exceed Excel worksheet limits"
        exit 198
    }
    local anchor "`startcol'`sr'"
    quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`=`width'-1')
    local right = regexr("`r(cell)'", "[0-9]+$", "")

    capture confirm string variable `value'
    if !_rc quietly generate strL `text' = trim(`value')
    else quietly generate strL `text' = cond(missing(`value'), "", trim(string(`value', "%15.5f")))
    if `np' {
        quietly bysort `rid' `groups': egen double `lo' = min(`subpopvar')
        quietly bysort `rid' `groups': egen double `hi' = max(`subpopvar')
        capture assert `lo'==`hi' & !missing(`subpopvar')
        if _rc {
            di as error "valid() requires equal, nonmissing populations across indicators within each category combination"
            exit 459
        }
        quietly generate double `pop' = round(`subpopvar')
        keep `cid' `rid' `groups' `iid' `text' `pop'
    }
    else keep `cid' `rid' `groups' `iid' `text'
    if `compact' {
        drop `groups'
        quietly fillin `rid' `cid' `iid'
        forvalues level=1/`nover' {
            quietly generate long `g`level'' = .
            forvalues c=0/`=`combinations'-1' {
                quietly replace `g`level'' = `cat`c'_`level'' if `cid'==`c'+1
            }
        }
    }
    else quietly fillin `rid' `groups' `iid' 
    quietly replace `text' = "" if _fillin
    if `np' {
        quietly bysort `rid' `groups': egen double `lo' = max(`pop')
        quietly replace `pop' = `lo'
        drop `lo'
    }
    quietly generate byte `flagged' = (`text'!="" & missing(real(`text')))
    quietly generate byte `usable' = !missing(real(`text'))
    quietly count
    local cells = r(N)
    quietly count if missing(real(`text'))
    local masked = round(100*r(N)/`cells',1)
    quietly count if real(`text')==0
    local zeros = round(100*r(N)/`cells',1)
    if `nt' {
        quietly bysort `rid' `groups': egen double `total' = total(real(`text'))
        quietly bysort `rid' `groups': egen byte `hi' = max(`flagged')
        quietly bysort `rid' `groups': egen long `lo' = total(`usable')
    }
    quietly sort `rid' `groups' `iid'
    // Completing one combination at a time makes progress meaningful.
    if "`progress'"!="" quietly sort `groups' `rid' `iid'
    local progress_last = clock("`c(current_date)' `c(current_time)'", "DMYhms")
    if "`progress'"!="" noisily display as text "Writing combinations: 0/`combinations' (0%)"

    if `"`path'"' == "no" _tab_from_mdt_excel, action(reuse)
    else _tab_from_mdt_excel, action(open) path(`"`path'"') sheet(`"`sheet'"') `replace'

    _mdt_format init `replace'
    local resetstyle
    if "`replace'"!="" local resetstyle reset
    local off = 0
    foreach heading in tabtitle header {
        if `"``heading''"'!="" {
            local rr = `sr'+`off'
            _mdt_format `startcol'`rr' = `"``heading''"'
            _mdt_format (`startcol'`rr':`right'`rr'), merge italic font("Arial",10) left
            if "`heading'"=="tabtitle" {
                _mdt_format (`startcol'`rr':`right'`rr'), border(top,thin,white)
                _mdt_format (`startcol'`rr':`right'`rr'), border(left,thin,white)
                _mdt_format (`startcol'`rr':`right'`rr'), border(right,thin,white)
            }
            local ++off
        }
    }
    local h1 = `sr'+`top'
    local hlast = `h1'+`nover'
    _mdt_format (`startcol'`h1':`right'`lastrow'), font("Arial",9) border(all,thin,"217 217 217") `resetstyle'
    _mdt_format (`startcol'`h1':`right'`hlast'), bold font("Arial",10) hcenter vcenter txtwrap border(all,thin,black) `resetstyle'
    forvalues d=1/`nd' {
        quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`=`d'-1')
        local col = regexr("`r(cell)'", "[0-9]+$", "")
        local label : word `d' of `varlist'
        if `"`labeldim'"'!="" local label : word `d' of `labeldim'
        _mdt_format `col'`h1' = `"`label'"'
        _mdt_format (`col'`h1':`col'`hlast'), merge
        local firstdata=`sr'+`dataoff'
        _mdt_format (`col'`firstdata':`col'`lastrow'), font("Arial",9) bold left border(all,thin,"217 217 217") `resetstyle'
        forvalues r=1/`nr' {
            local rr = `sr'+`dataoff'+`r'-1
            _mdt_format `col'`rr' = `"`row`r'_`d''"'
        }
    }
    // Native 15/16 reset can leave a different numeric-format ID.
    // Restore General through the preserving path before writing numeric values.
    if "`replace'"!="" _mdt_format (`startcol'`h1':`right'`lastrow'), nformat("General")
    // Emit a header when entering its span, preserving depth-first write order.
    forvalues combination=0/`=`combinations'-1' {
        local first = `nd'+`combination'*`block'
        forvalues level=1/`nover' {
            local emit = mod(`combination',`stride`level'')==0
            local raw = `combination'
            local span = `stride`level''*`block'
            if `compact' {
                local raw = `raw`combination''
                local prefix = floor(`raw'/`stride`level'')
                local emit = 1
                if `combination'>0 {
                    local previous = `combination'-1
                    local emit = floor(`raw`previous''/`stride`level'')!=`prefix'
                }
                local descendants = 0
                forvalues next=`combination'/`=`combinations'-1' {
                    if floor(`raw`next''/`stride`level'')!=`prefix' continue, break
                    local ++descendants
                }
                local span = `descendants'*`block'
            }
            if `emit' {
                local category = mod(floor(`raw'/`stride`level''),`categories`level'')+1
                local hr = `h1'+`level'-1
                quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`first')
                local left = regexr("`r(cell)'", "[0-9]+$", "")
                quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`=`first'+`span'-1')
                local end = regexr("`r(cell)'", "[0-9]+$", "")
                _mdt_format `left'`hr' = `"`label`level'_`category''"'
                if `level'==1 {
                    if `span'>1 _mdt_format (`left'`hr':`end'`hr'), merge border(all,thin,black)
                    else _mdt_format `left'`hr', border(all,thin,black)
                }
                else {
                    if `span'>1 _mdt_format (`left'`hr':`end'`hr'), merge
                    _mdt_format (`left'`hr':`end'`hr'), border(all,thin,black)
                }
            }
        }
        forvalues k=1/`block' {
            local label `"`rowtotal'"'
            if `np' & `k'==1 local label `"`valid'"'
            else if `k'<=`ni'+`np' local label `"`title`=`k'-`np'''"'
            quietly _excel_cell_shift, cell("`anchor'") rowinc(`=`top'+`nover'') colinc(`=`first'+`k'-1')
            _mdt_format `r(cell)' = `"`label'"'
        }
    }
    // Explicit internal indicator dividers, including the indicator heading row.
    forvalues b=0/`=`combinations'-1' {
        local base = `nd'+`b'*`block'
        if `ni'>1 {
            forvalues j=1/`=`ni'-1' {
                quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`=`base'+`np'+`j'-1')
                local left = regexr("`r(cell)'", "[0-9]+$", "")
                quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`=`base'+`np'+`j'')
                local rightcol = regexr("`r(cell)'", "[0-9]+$", "")
                _mdt_format (`left'`hlast':`left'`lastrow'), border(right,thin,"217 217 217")
                _mdt_format (`rightcol'`hlast':`rightcol'`lastrow'), border(left,thin,"217 217 217")
            }
        }
        if `np' {
            quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`base')
            local left = regexr("`r(cell)'", "[0-9]+$", "")
            quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`=`base'+1')
            local rightcol = regexr("`r(cell)'", "[0-9]+$", "")
            _mdt_format (`left'`hlast':`left'`lastrow'), border(right,thin,black)
            _mdt_format (`rightcol'`hlast':`rightcol'`lastrow'), border(left,thin,black)
        }
    }
    // Black outlines and category boundaries override the internal grey grid.
    _mdt_format (`startcol'`h1':`right'`h1'), border(top,thin,black)
    _mdt_format (`startcol'`lastrow':`right'`lastrow'), border(bottom,thin,black)
    _mdt_format (`startcol'`h1':`startcol'`lastrow'), border(left,thin,black)
    _mdt_format (`right'`h1':`right'`lastrow'), border(right,thin,black)
    quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`=`nd'-1')
    local dimension_right = regexr("`r(cell)'", "[0-9]+$", "")
    _mdt_format (`dimension_right'`h1':`dimension_right'`lastrow'), border(right,thin,black)
    forvalues b=0/`=`combinations'-1' {
        local offset = `nd'+`b'*`block'
        quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`offset')
        local blockleft = regexr("`r(cell)'", "[0-9]+$", "")
        quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`=`offset'+`block'-1')
        local blockright = regexr("`r(cell)'", "[0-9]+$", "")
        _mdt_format (`blockleft'`hlast':`blockleft'`lastrow'), border(left,thin,black)
        _mdt_format (`blockright'`hlast':`blockright'`lastrow'), border(right,thin,black)
    }
    // The rectangular long grid guarantees every value uses the same row mapping.
    forvalues obs=1/`=_N' {
        local rr = `dataoff'+`rid'[`obs']-1
        local combination = 0
        forvalues level=1/`nover' {
            local combination = `combination'+(`g`level''[`obs']-1)*`stride`level''
        }
        if `compact' local combination = `cid'[`obs']-1
        local first = `nd'+`combination'*`block'
        local cc = `first'+`np'+`iid'[`obs']-1
        local rowkey = `rid'[`obs']
        local raw = `text'[`obs']
        quietly _excel_cell_shift, cell("`anchor'") rowinc(`rr') colinc(`cc')
        local cell "`r(cell)'"
        if `"`raw'"'=="" local raw "[:]"
        *if "`decimal'"!="" & "`decimal'"!="." local raw = subinstr(`"`raw'"',".","`decimal'",.)
        if !missing(real(`"`raw'"')) {
            _mdt_format `cell' = (real(`"`raw'"'))
            local format_`cc'_`rowkey' numeric
        }
        else {
            _mdt_format `cell' = `"`raw'"'
            local format_`cc'_`rowkey' flag
        }
        if `iid'[`obs']==1 {
            if `np' {
                quietly _excel_cell_shift, cell("`anchor'") rowinc(`rr') colinc(`first')
                if missing(`pop'[`obs']) _mdt_format `r(cell)' = "[:]"
                else {
                    _mdt_format `r(cell)' = (`pop'[`obs'])
                    local format_`first'_`rowkey' population
                }
            }
            if `nt' {
                quietly _excel_cell_shift, cell("`anchor'") rowinc(`rr') colinc(`=`first'+`block'-1')
                local cell "`r(cell)'"
                local totalcol=`first'+`block'-1
                local format_`totalcol'_`rowkey' flag
                if `hi'[`obs'] _mdt_format `cell' = "[-]"
                else if !`lo'[`obs'] _mdt_format `cell' = "[:]"
                else {
                    _mdt_format `cell' = (`total'[`obs'])
                    local format_`totalcol'_`rowkey' numeric
                }
            }
        }
        if "`progress'"!="" & mod(`obs',`nr'*`ni')==0 {
            local progress_done = `obs'/(`nr'*`ni')
            local progress_now = clock("`c(current_date)' `c(current_time)'", "DMYhms")
            if `progress_now'-`progress_last'>=1000 | `progress_done'==`combinations' {
                noisily display as text "Writing combinations: `progress_done'/`combinations' (" as result %3.0f (100*`progress_done'/`combinations') as text "%)"
                local progress_last = `progress_now'
            }
        }
    }
    // Apply value formats to contiguous runs; retain the finished borders.
    forvalues column=`nd'/`=`width'-1' {
        local previous
        local firstrun=1
        forvalues rowkey=1/`=`nr'+1' {
            local kind "`format_`column'_`rowkey''"
            if `rowkey'>1 & "`kind'"!="`previous'" {
                if "`previous'"!="" {
                    quietly _excel_cell_shift, cell("`anchor'") rowinc(`=`dataoff'+`firstrun'-1') colinc(`column')
                    local firstcell "`r(cell)'"
                    quietly _excel_cell_shift, cell("`anchor'") rowinc(`=`dataoff'+`rowkey'-2') colinc(`column')
                    local lastcell "`r(cell)'"
                    local style nformat("#,##0.00") right
                    if "`previous'"=="population" local style nformat("#,##0") right
                    if "`previous'"=="flag" local style font("Arial",9,"166 166 166") right
                    _mdt_format (`firstcell':`lastcell'), `style'
                }
                local firstrun=`rowkey'
            }
            local previous "`kind'"
        }
    }
    if "`highlight'"!="" _mdt_format (`startcol'`lastrow':`right'`lastrow'), bold border(top,thin,black)
    local note = `lastrow'+1
    if `"`source'"'!="" {
        _mdt_format `startcol'`note' = `"Source: `source'"', italic font("Arial",9)
        _mdt_format (`startcol'`note':`right'`note'), merge
        _mdt_format (`startcol'`note':`right'`note'), border(bottom,thin,white)
        _mdt_format (`startcol'`note':`right'`note'), border(left,thin,white)
        _mdt_format (`startcol'`note':`right'`note'), border(right,thin,white)
        local ++note
    }
    _mdt_format `startcol'`note' = "Percentage of masked cells: `masked'%", italic font("Arial",9,"red")
    local ++note
    _mdt_format `startcol'`note' = "Percentage of cells with value zero(0): `zeros'%", italic font("Arial",9,"red")
    _mdt_format flush
    if "`onmemory'"=="" quietly _tab_from_mdt_excel, action(save) path(`"`path'"')
    quietly _excel_cell_shift, cell("`anchor'") rowinc(0) colinc(`=`width'+2')
    local nextcol = regexr("`r(cell)'", "[0-9]+$", "")
    restore
    return scalar tab_start_line = `sr'
    return scalar tab_end_line = `lastnote'+2
    return local tab_start_cell_letter "`startcol'"
    return local tab_end_cell_letter "`nextcol'"
end
