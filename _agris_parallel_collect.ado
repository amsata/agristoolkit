program define _agris_parallel_collect
    syntax, JOBID(string) CHILDREN(integer)
    local loaded = 0
    forvalues child=1/`children' {
        local prefix "__pll`jobid'_agris_`child'"
        confirm file "`prefix'.done"
        tempname handle
        file open `handle' using "`prefix'.done", read text
        file read `handle' count
        file close `handle'
        if missing(real("`count'")) | real("`count'")<0 error 459
        if real("`count'")>0 {
            confirm file "`prefix'.dta"
            if !`loaded' use "`prefix'.dta", clear
            else append using "`prefix'.dta"
            local loaded = 1
        }
    }
    if !`loaded' error 2000
end
