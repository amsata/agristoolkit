program define _agris_parallel_stats
    version 14
    local invocation `"`0'"'
    local original_dir `"`c(pwd)'"'
    local original_temp : copy global temp_file
    tempfile run_anchor
    local run_dir `"`run_anchor'_allstats"'
    mkdir `"`run_dir'"'
    nobreak {
        quietly cd `"`run_dir'"'
        capture noisily break _agris_parallel_stats_impl `invocation'
        local rc = _rc
        quietly cd `"`original_dir'"'
        global temp_file `"`original_temp'"'
        if `rc' noisily display as error `"All-statistics run failed; diagnostics retained in `run_dir'"'
        else capture rmdir `"`run_dir'"'
        if `rc' exit `rc'
    }
end

program define _agris_parallel_stats_impl
    syntax [varlist(default=none)], [MEAN(string asis) MEDIAN(string asis) TOTAL(string asis) RATIO(string asis) ///
        MARGINlabels(string asis) HIERGEOvars(string asis) GEOMARGINlabel(string) CONDitionals(string asis) SUBpop(string asis)]
    tempfile source raw accumulated
    quietly save "`source'", replace
    global temp_file "`source'"
    // Restore the original survey dataset automatically if any task/formatting fails.
    preserve
    _agris_parallel_queue, dimensions("`varlist'") geography("`hiergeovars'") ///
        mean(`mean') median(`median') total(`total') ratio(`ratio') subpop(`"`subpop'"')
    quietly save "`raw'", replace
    local formatted = 0
    foreach parameter in mean median total ratio {
        if `"``parameter''"'!="" {
            quietly use "`source'", clear
            _agris_stat_format `varlist', parameter("`parameter'") raw("`raw'") ///
                marginlabels(`marginlabels') hiergeovars(`hiergeovars') geomarginlabel(`geomarginlabel')
            if `formatted' quietly append using "`accumulated'"
            quietly save "`accumulated'", replace
            local formatted = 1
        }
    }
    quietly use "`accumulated'", clear
    restore, not
end
