*! install_agristoolkit_dep 1.0.0 16oct2026
program define install_agristoolkit_dep
    version 13
    syntax [, REPLACE]

    foreach package in parallel elabel tuples confirmdir {
        capture which `package'
        if !_rc & "`replace'"=="" {
            di as text "`package' is already available; skipped (specify replace to reinstall)."
            continue
        }
        di as text "Installing `package'..."
        if "`package'"=="parallel" {
            capture noisily net install parallel, ///
                from("https://raw.github.com/gvegayon/parallel/stable/") `replace'
        }
        else if "`package'"=="elabel" {
            capture noisily net install elabel, ///
                from("https://raw.githubusercontent.com/kleindaniel81/elabel/master/") `replace'
        }
        else {
            capture noisily ssc install `package', `replace'
        }
        local rc = _rc
        if `rc' {
            di as error "Could not install `package' (r(`rc')). Correct the installation error and rerun install_agristoolkit_dep."
            exit `rc'
        }
    }
    mata: mata mlib index
    di as result "Agristoolkit dependencies are ready."
end
