*! adoinit 1.0.1 17sep2026
program define adoinit, rclass
    version 13
    syntax, PATH(string) [NAME(string) REPLACE AGRISfrom(string) PARALLELfrom(string) SSCfrom(string)]
    if `"`name'"'=="" local name ado
    if inlist(`"`name'"', ".", "..") | regexm(`"`name'"', "[/\\:*?<>|]") {
        di as error "name() must be a single folder name, not a path"
        exit 198
    }
    local path = subinstr(`"`path'"', "\", "/", .)
    mata: st_local("exists", strofreal(direxists(st_local("path"))))
    if !`exists' {
        di as error "path() must identify an existing parent directory"
        exit 601
    }
    local target `"`path'/`name'"'
    mata: st_local("exists", strofreal(direxists(st_local("target"))))
    if `exists' & "`replace'"=="" {
        di as error "The ado folder already exists; specify replace to update its packages"
        exit 602
    }
    if !`exists' mkdir `"`target'"'
    if `"`agrisfrom'"'=="" local agrisfrom "https://raw.githubusercontent.com/amsata/agristoolkit/main/"
    if `"`parallelfrom'"'=="" local parallelfrom "https://raw.github.com/gvegayon/parallel/stable/"
    // net query has no returned settings; capture its ado destination in a private log.
    tempfile settings
    tempname netlog handle
    local old_linesize = c(linesize)
    nobreak {
        quietly set linesize 255
        quietly log using `"`settings'"', name(`netlog') text replace
        noisily net query
        quietly log close `netlog'
        quietly set linesize `old_linesize'
    }
    file open `handle' using `"`settings'"', read text
    local old_ado
    local reading 0
    file read `handle' line
    while r(eof)==0 {
        local clean = strtrim(`"`line'"')
        if substr(`"`clean'"',1,4)=="ado " {
            local old_ado = strtrim(substr(`"`clean'"',5,.))
            local reading 1
        }
        else if `reading' & substr(`"`clean'"',1,1)==">" {
            local part = strtrim(substr(`"`clean'"',2,.))
            local old_ado `"`old_ado'`part'"'
        }
        else if `reading' local reading 0
        file read `handle' line
    }
    file close `handle'
    if `"`old_ado'"'=="" {
        di as error "Could not determine the current net installation destination"
        exit 498
    }
    local rc 0
    nobreak {
        capture noisily break _adoinit_install, target(`"`target'"') ///
            agrisfrom(`"`agrisfrom'"') parallelfrom(`"`parallelfrom'"') sscfrom(`"`sscfrom'"')
        local rc = _rc
        quietly net set ado `"`old_ado'"'
    }
    if `rc' {
        di as error `"Initialization incomplete in `target'. Correct the installation error and rerun with replace."'
        exit `rc'
    }
    return local adopath `"`target'"'
    di as result `"Project ado folder initialized: `target'"'
    di as text "Keep this folder with the project. Use adopath ++ to select it in your master do-file."
end

program define _adoinit_install
    version 13
    syntax, TARGET(string) AGRISfrom(string) PARALLELfrom(string) [SSCfrom(string)]
    quietly net set ado `"`target'"'
    noisily net install agristoolkit, from(`"`agrisfrom'"') replace
    foreach package in tuples elabel confirmdir {
        if `"`sscfrom'"'=="" noisily ssc install `package', replace
        else noisily net install `package', from(`"`sscfrom'"') replace
    }
    noisily net install parallel, from(`"`parallelfrom'"') replace
end
