capture program drop _gen_all_dimcomb_dataset
program define _gen_all_dimcomb_dataset
    version 13
    syntax varlist(min=1)

    tempfile labelsdo
    quietly label save using "`labelsdo'", replace

    * Collect values and metadata
    foreach v of local varlist {

        local lab_`v' : value label `v'
        local varlab_`v' : variable label `v'
        local type_`v' : type `v'

        capture confirm string variable `v'
        local isstr_`v' = (_rc == 0)

        if "`lab_`v''" != "" {
            quietly elabel list `lab_`v''
            local vals_`v' `r(values)'
        }
        else {
            quietly levelsof `v', local(vals_`v')
        }

        if `"`vals_`v''"' == "" {
            di as error "No values found for variable `v'"
            exit 198
        }
    }

    * Create one temporary dataset per variable
    foreach v of local varlist {

        clear
        set obs `: word count `vals_`v'''

        if `isstr_`v'' {

            * Convert strL to regular str#
            if "`type_`v''" == "strL" {
                local maxlen = 1

                foreach x of local vals_`v' {
                    local len = length(`"`x'"')
                    if `len' > `maxlen' local maxlen = `len'
                }

                if `maxlen' > 2045 local maxlen = 2045
                gen str`maxlen' `v' = ""
            }
            else {
                gen `type_`v'' `v' = ""
            }
        }
        else {
            gen `type_`v'' `v' = .
        }

        local i = 1
        foreach x of local vals_`v' {
            if `isstr_`v'' {
                replace `v' = `"`x'"' in `i'
            }
            else {
                replace `v' = `x' in `i'
            }
            local ++i
        }

        quietly do "`labelsdo'"

        if "`lab_`v''" != "" {
            label values `v' `lab_`v''
        }

        label variable `v' "`varlab_`v''"

        tempfile f_`v'
        save `f_`v'', replace
    }

    * Build Cartesian product
    local first : word 1 of `varlist'
    use `f_`first'', clear

    local n : word count `varlist'
    forvalues j = 2/`n' {
        local v : word `j' of `varlist'
        cross using `f_`v''
    }

    * Reapply labels in final dataset
    quietly do "`labelsdo'"

    foreach v of local varlist {
        if "`lab_`v''" != "" {
            label values `v' `lab_`v''
        }
        label variable `v' "`varlab_`v''"
    }

    order `varlist'
    sort `varlist'
end

