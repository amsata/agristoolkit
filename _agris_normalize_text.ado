program define _agris_normalize_text, rclass
    version 13
    syntax, MODE(string) [TEXT(string)]
    if !inlist("`mode'","range","ratio") {
        di as error "Unknown text normalization mode"
        exit 198
    }
    local result `"`text'"'
    if c(stata_version)>=14 {
        if "`mode'"=="range" local result=ustrregexra(`"`result'"',"\s*-\s*","-")
        else {
            local result=ustrregexra(`"`result'"',"\s*:\s*",":")
            local result=ustrregexra(`"`result'"',"\s*/\s*","/")
            local result=subinstr(`"`result'"',"(","",.)
            local result=subinstr(`"`result'"',")","",.)
            local result=strtrim(ustrregexra(`"`result'"',"\s+"," "))
        }
    }
    else {
        // Stata 13 has no Unicode string functions. Normalize ASCII whitespace.
        forvalues code=9/13 {
            local result=subinstr(`"`result'"',char(`code')," ",.)
        }
        local separators "-"
        if "`mode'"=="ratio" local separators ": /"
        foreach separator of local separators {
            while strpos(`"`result'"'," `separator'") | strpos(`"`result'"',"`separator' ") {
                local result=subinstr(`"`result'"'," `separator'","`separator'",.)
                local result=subinstr(`"`result'"',"`separator' ","`separator'",.)
            }
        }
        if "`mode'"=="ratio" {
            local result=subinstr(`"`result'"',"(","",.)
            local result=subinstr(`"`result'"',")","",.)
            local result=strtrim(itrim(`"`result'"'))
        }
    }
    return local text `"`result'"'
end
