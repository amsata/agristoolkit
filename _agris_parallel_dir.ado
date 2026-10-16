program define _agris_parallel_dir, rclass
    version 13
    syntax, SUFFIX(name)
    tempfile anchor
    local base `"`anchor'_`suffix'"'
    local attempt=0
    while `attempt'<10000 {
        local candidate `"`base'"'
        if `attempt' local candidate `"`base'_`attempt'"'
        capture mkdir `"`candidate'"'
        local rc=_rc
        if !`rc' {
            return local path `"`candidate'"'
            exit
        }
        // Keep retained diagnostics; retry only when the name is already taken.
        mata: st_local("exists",strofreal(direxists(st_local("candidate"))))
        if !`exists' {
            noisily di as error `"Could not create parallel working directory: `candidate'"'
            exit `rc'
        }
        local ++attempt
    }
    noisily di as error "Could not allocate a fresh parallel working directory after 10000 attempts."
    exit 693
end
