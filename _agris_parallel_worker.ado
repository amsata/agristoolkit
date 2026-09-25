program define _agris_parallel_worker
    version 14
    syntax, TASKS(string) SOURCE(string) [SUBpop(string)]
    quietly use "`tasks'", clear
    quietly keep if worker == $pll_instance
    local n = _N
    forvalues t=1/`n' {
        local tuple`t' = tuple[`t']
        local ind`t' = indicator[`t']
        local geo`t' = geo[`t']
        local ad`t' = alldim[`t']
        local id`t' = taskid[`t']
        local statistic`t' = statistic[`t']
    }
    tempfile accumulator
    forvalues t=1/`n' {
        local tuple `tuple`t''
        local ind `ind`t''
        local geo `geo`t''
        local ad `ad`t''
        local parameter `statistic`t''
        quietly use "`source'", clear
        if "`geo'"!="" {
            foreach v of local tuple {
                local old_vl : value label `v'
                elabel copy `old_vl' ld_`v'
            }
            tempfile dolabs
            quietly label save using "`dolabs'", replace
        }
        local tasksubpop `"`subpop'"'
        // Match the current geographic worker, which omits its subpop argument.
        // Preserve existing geographic subpopulation behavior.
        if "`geo'"!="" local tasksubpop
        // svyEstimate interprets survey output according to the installed release.
        // Do not force Stata 16+ to emit version-14 matrix stripes.
        local native_version = c(stata_version)
        quietly version `native_version': svyEstimate `tuple', param(`parameter') var(`ind') alldim(`ad') subpop("`tasksubpop'")
        if "`geo'"!="" {
            generate geoType="`geo'"
            capture confirm variable `geo'
            if !_rc {
                quietly run "`dolabs'"
                label values `geo' ld_`geo'
                rename `geo' geoVar
            }
        }
        generate long __agris_task = `id`t''
        generate long __agris_row = _n
        generate str6 __agris_statistic = "`parameter'"
        if `t'>1 quietly append using "`accumulator'"
        quietly save "`accumulator'", replace
    }
    quietly use "`accumulator'", clear
    quietly save "__pll${pll_id}_agris_${pll_instance}.dta", replace
    tempname completion
    file open `completion' using "__pll${pll_id}_agris_${pll_instance}.done", write replace
    file write `completion' "`n'" _n
    file close `completion'
end
