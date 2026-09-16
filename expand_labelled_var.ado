*! Expand labelled numeric inputs into missing-preserving category indicators.
capture program drop expand_labelled_var
program define expand_labelled_var, rclass
    version 13
    args inputs
    local expanded
    local generated
    local sources
    local codes
    local labels
    local k=0
    // Plan and validate the entire request before creating any variables.
    foreach source of local inputs {
        confirm numeric variable `source'
        local vl : value label `source'
        if `"`vl'"'=="" {
            local expanded `expanded' `source'
            continue
        }
        tempname values texts
        mata: st_local("defined", strofreal(st_vlexists(st_local("vl"))))
        if !real("`defined'") {
            di as error "`source': attached value label `vl' is not defined"
            exit 198
        }
        capture mata: st_vlload(st_local("vl"), `values'=., `texts'="")
        if _rc {
            capture mata: mata drop `values' `texts'
            di as error "`source': attached value label `vl' is not defined"
            exit 198
        }
        mata: st_local("nlevels", strofreal(sum(`values':<.)))
        if !`nlevels' {
            mata: mata drop `values' `texts'
            di as error "`source': value label must define at least one nonmissing category"
            exit 198
        }
        mata: st_local("levels", invtokens(strofreal(select(`values', `values':<.), "%21.0g")'))
        mata: mata drop `values' `texts'
        local nlevels : list sizeof levels
        if !`nlevels' {
            di as error "`source': value label must define at least one nonmissing category"
            exit 198
        }
        tempvar covered
        quietly generate byte `covered'=missing(`source')
        foreach code of local levels {
            if `code'<0 | `code'!=floor(`code') {
                di as error "`source': category codes must be nonnegative integers for source-plus-code names"
                exit 198
            }
            local suffix = strtrim(string(`code',"%21.0f"))
            local target `source'`suffix'
            capture confirm new variable `target'
            if _rc {
                di as error "Cannot create `target': name already exists or exceeds Stata's name limit"
                exit 198
            }
            local duplicate : list posof "`target'" in generated
            if `duplicate' {
                di as error "Duplicate generated indicator name: `target'"
                exit 198
            }
            local label : label `vl' `code', strict
            if strtrim(`"`label'"')=="" {
                di as error "`source': category `code' has an empty value label"
                exit 198
            }
            local ++k
            local target`k' `target'
            local source`k' `source'
            local code`k' `code'
            local label`k' `"`label'"'
            local expanded `expanded' `target'
            local generated `generated' `target'
            local sources `sources' `source'
            local codes `codes' `code'
            local labels `"`labels' `"`label'"'"'
            quietly replace `covered'=1 if `source'==`code'
        }
        quietly count if !`covered'
        if r(N) {
            di as error "`source': observed nonmissing values have no category label"
            exit 198
        }
    }
    if `k' {
        forvalues i=1/`k' {
            quietly generate byte `target`i''=(`source`i''==`code`i'') if !missing(`source`i'')
            local short_label=usubstr(`"`label`i''"',1,80)
            label variable `target`i'' `"`short_label'"'
            return local variable`i' `target`i''
            return local source`i' `source`i''
            return local code`i' `code`i''
            return local label`i' `"`label`i''"'
        }
    }
    return local expanded : list retokenize expanded
    return local generated : list retokenize generated
    return local sources : list retokenize sources
    return local codes : list retokenize codes
    return local labels `"`labels'"'
    return scalar n_generated=`k'
end
