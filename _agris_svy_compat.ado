program define _agris_svy_compat, sortpreserve
    version 13
    syntax varlist, PARAMeter(string) VARiable(string asis) [SUBpop(string asis)]
    if c(stata_version)>=16 | "`parameter'"=="median" exit
    quietly svyset
    if missing(r(stages_wt)) | r(stages_wt)==0 exit
    // Use native sample/group setup, including survey design and subpop().
    // This setup precedes the affected stage-weight markout in native estimation.
    // Native svy constructs these groups before excluding missing indicators.
    // Do not narrow the sample by mean/total variables or ratio operands here.
    tempvar touse group weight
    quietly generate byte `touse'=1
    quietly _svy_setup `touse' `group' `weight', svy over(`varlist') subpop(`subpop')
    quietly summarize `group', meanonly
    local groups=r(max)
    // _svy_subpop creates a same-named matrix; release this temporary result.
    capture matrix drop `group'
    if !missing(`groups') & `groups'>100 {
        noisily di as error "Survey compatibility limitation in Stata " c(stata_version) ":"
        noisily di as error "`parameter' `variable', over(`varlist') creates `groups' groups with stage weights."
        noisily di as error "Native Stata versions below 16 fail above 100 groups in this setup."
        noisily di as error "If the weight is a final observation weight, use svyset PSU [pweight=weight], strata(stratum)."
        noisily di as error "For genuine stage weights, retain the design and use a supported newer Stata release or fewer groups."
        exit 459
    }
end
