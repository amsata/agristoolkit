*! Parse indicator metadata without inspecting or changing the dataset.
capture program drop _genmdt_name_parse
program define _genmdt_name_parse, rclass
    version 13
    syntax, SPEC(string)
    local spec=subinstr(`"`spec'"',"***"," ",.)
    local spec=subinstr(`"`spec'"',"&&&","'",.)
    local at=strpos(`"`spec'"',"@")
    if `at'<=1 {
        di as error "Indicator metadata requires sourceID@label"
        exit 198
    }
    local source=strtrim(substr(`"`spec'"',1,`at'-1))
    if !regexm("`source'","^[A-Za-z_][A-Za-z0-9_]*$") | strlen("`source'")>32 {
        di as error "Invalid source indicator ID in naming metadata"
        exit 198
    }
    local remaining=substr(`"`spec'"',`at'+1,.)
    local label
    local target
    local qxvars
    local datasets
    local seen
    // Each field ends at the next marker or #short-label boundary.
    while `"`remaining'"'!="" {
        local first=0
        local field
        foreach candidate in name qxvars dst {
            local pos=strpos(`"`remaining'"',"{`candidate'}")
            if `pos'>0 & (`first'==0 | `pos'<`first') {
                local first=`pos'
                local field `candidate'
            }
        }
        if !`first' {
            local label `"`label'`remaining'"'
            continue, break
        }
        local duplicate : list posof "`field'" in seen
        if `duplicate' {
            di as error "Only one {`field'} marker is allowed per specification"
            exit 198
        }
        local seen `seen' `field'
        local prefix=substr(`"`remaining'"',1,`first'-1)
        local label `"`label'`prefix'"'
        local tail=substr(`"`remaining'"',`first'+strlen("{`field'}"),.)
        local boundary=strlen(`"`tail'"')+1
        foreach delimiter in "{name}" "{qxvars}" "{dst}" "#" {
            local pos=strpos(`"`tail'"',"`delimiter'")
            if `pos'>0 & `pos'<`boundary' local boundary=`pos'
        }
        local value=strtrim(substr(`"`tail'"',1,`boundary'-1))
        if `"`value'"'=="" {
            di as error "{`field'} requires a nonempty value"
            exit 198
        }
        if "`field'"=="name" {
            if !regexm(`"`value'"',"^[A-Za-z_][A-Za-z0-9_]*$") | strlen(`"`value'"')>32 {
                di as error "{name} requires a nonempty destination ID of at most 32 letters, digits, or underscores, starting with a letter or underscore"
                exit 198
            }
            local target `"`value'"'
        }
        if "`field'"=="qxvars" local qxvars `"`value'"'
        if "`field'"=="dst" local datasets `"`value'"'
        local remaining=substr(`"`tail'"',`boundary',.)
    }
    local longlabel `"`label'"'
    local hash=strpos(`"`label'"',"#")
    if `hash' local longlabel=substr(`"`label'"',1,`hash'-1)
    if strtrim(`"`longlabel'"')=="" {
        di as error "Indicator metadata requires a nonempty long label"
        exit 198
    }
    return local source "`source'"
    return local target "`target'"
    return local label `"`label'"'
    return local qxvars `"`qxvars'"'
    return local datasets `"`datasets'"'
end
