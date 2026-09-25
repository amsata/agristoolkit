program define _agris_parallel_queue
    version 14
    syntax, [DIMensions(string) GEOgraphy(string) MEAN(string asis) MEDIAN(string asis) TOTAL(string asis) RATIO(string asis) SUBpop(string)]
    tempfile tasks job_anchor
    tempname taskpost
    postfile `taskpost' long taskid str244 tuple str244 indicator str32 geo str3 alldim str6 statistic using "`tasks'", replace
    local taskid = 0
    local ng : word count `geography'
    local nk = max(1, `ng')
    foreach parameter in mean median total ratio {
        local indicators ``parameter''
        if `"`indicators'"'!="" {
            forvalues k=1/`nk' {
                local geo : word `k' of `geography'
                local newdims `geo' `dimensions'
                local nd : word count `newdims'
                if `nd' {
                    tuples `newdims', nopython
                }
                else {
                    local ntuples = 1
                    local tuple1
                }
                foreach ind of local indicators {
                    forvalues j=1/`ntuples' {
                        local tuple `tuple`j''
                        local ad = cond(`nd'==0, "yes", "no")
                        local ++taskid
                        post `taskpost' (`taskid') ("`tuple'") ("`ind'") ("`geo'") ("`ad'") ("`parameter'")
                    }
                }
            }
            foreach ind of local indicators {
                local ++taskid
                post `taskpost' (`taskid') ("") ("`ind'") ("") ("yes") ("`parameter'")
            }
        }
    }
    postclose `taskpost'
    if `taskid'==0 error 2000
    local original_children = $PLL_CHILDREN
    local original_clusters = $PLL_CLUSTERS
    local children = min(`original_children', `taskid')
    quietly use "`tasks'", clear
    generate long worker = mod(taskid-1, `children')+1
    quietly save "`tasks'", replace
    mata: st_local("jobid", pathbasename(st_local("job_anchor")))
    local jobid = subinstr("`jobid'", ".", "", .)
    global PLL_CHILDREN = `children'
    global PLL_CLUSTERS = `children'
    mata: parallel_sandbox(0, st_local("jobid"))
    capture noisily parallel, setparallelid(`jobid') keep nodata: ///
        _agris_parallel_worker, tasks("`tasks'") source("$temp_file") subpop(`"`subpop'"')
    local rc = _rc
    global PLL_CHILDREN = `original_children'
    global PLL_CLUSTERS = `original_clusters'
    mata: parallel_sandbox(2, st_local("jobid"))
    if `rc' exit `rc'
    _agris_parallel_collect, jobid("`jobid'") children(`children')
    gsort -__agris_task __agris_row
    drop __agris_task __agris_row
    quietly parallel clean, e(`jobid')
end
