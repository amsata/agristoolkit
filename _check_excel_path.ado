capture program drop _check_excel_path
program define _check_excel_path, rclass
    version 14.1

    syntax , PATH(string asis)

    // Clean path
    local filepath `"`path'"'
    local filepath = strtrim(`"`filepath'"')

    // Remove surrounding quotes if any
    if substr(`"`filepath'"', 1, 1) == `"""' {
        local filepath = substr(`"`filepath'"', 2, .)
    }

    if substr(`"`filepath'"', -1, 1) == `"""' {
        local filepath = substr(`"`filepath'"', 1, length(`"`filepath'"') - 1)
    }

    // Extract folder and filename
    if regexm(`"`filepath'"', "^(.*)[/\\]([^/\\]+)$") {
        local folder   `"`=regexs(1)'"'
        local filename `"`=regexs(2)'"'
    }
    else {
        di as err "invalid file path: no folder found"
        exit 198
    }

    local folder   = strtrim(`"`folder'"')
    local filename = strtrim(`"`filename'"')

    // Check folder exists
    confirmdir `"`folder'"'
    if _rc {
        di as err `"directory does not exist: `folder'"'
        exit 601
    }

    // Check valid Excel extension
    local lowername = lower(`"`filename'"')

    if regexm(`"`lowername'"', "\.(xlsx|xlsm|xls|xltx|xltm)$") {
        local extension `"`=regexs(1)'"'
    }
    else {
        di as err "invalid Excel file extension"
        di as err "valid extensions are: .xlsx, .xlsm, .xls, .xltx, .xltm"
        exit 198
    }

    // Return results
    return local path      `"`filepath'"'
    return local folder    `"`folder'"'
    return local filename  `"`filename'"'
    return local extension `"`extension'"'
end
