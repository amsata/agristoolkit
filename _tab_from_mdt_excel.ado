*! Shared workbook checks and save/open error handling.
capture program drop _tab_from_mdt_excel
program define _tab_from_mdt_excel
    version 14.1
    syntax, ACTION(string) [PATH(string) SHEET(string) REPLACE]
    if !inlist("`action'", "check", "open", "reuse", "save") exit 198
    if "`action'"=="reuse" {
        capture quietly putexcel describe
        if _rc {
            di as error "outfile(no) requires an active putexcel workbook"
            exit 198
        }
        exit
    }
    if `"`path'"'!="" & `"`path'"'!="no" {
        _check_excel_path, path("`path'")
        if fileexists(`"`path'"') {
            tempname handle
            // Append-open checks write access without changing existing bytes.
            mata: st_local("`handle'", strofreal(_fopen(st_local("path"), "a")))
            if real("``handle''")<0 {
                di as error "Excel file is open, locked, or not writable; close it and check write access"
                exit 603
            }
            mata: fclose(strtoreal(st_local("`handle'")))
        }
    }
    if "`action'"=="check" exit
    if "`action'"=="save" {
        // Older putexcel saves pending writes with close, not save.
        local savecmd save
        if c(stata_version)<16 local savecmd close
        capture noisily putexcel `savecmd'
        local rc=_rc
        if `rc' {
            di as error "Workbook could not be saved. Release the lock or check the destination, then try putexcel `savecmd' before rerunning the table command."
            exit `rc'
        }
        exit
    }
    if `"`path'"'=="" | `"`path'"'=="no" exit 198
    // Never switch away from a workbook whose pending save failed.
    capture quietly putexcel describe
    if !_rc _tab_from_mdt_excel, action(save)
    if `"`sheet'"'=="" local sheet TABLES
    local mode modify
    if "`replace'"!="" local mode replace
    if c(stata_version)<16 {
        capture noisily putexcel set `"`path'"', `mode' sheet("`sheet'") open
    }
    else {
        capture noisily putexcel set `"`path'"', `mode' sheet(`"`sheet'"') open
    }
    local rc=_rc
    if `rc' {
        di as error "Unable to open the Excel workbook for writing; check the destination and file access"
        exit `rc'
    }
end
