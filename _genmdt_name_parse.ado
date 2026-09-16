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
    local label=substr(`"`spec'"',`at'+1,.)
    local marker=strpos(`"`label'"',"{name}")
    local target
    if `marker' {
        local tail=substr(`"`label'"',`marker'+6,.)
        if strpos(`"`tail'"',"{name}") {
            di as error "Only one {name} marker is allowed per specification"
            exit 198
        }
        local hash=strpos(`"`tail'"',"#")
        local target=strtrim(`"`tail'"')
        local suffix
        if `hash' {
            local target=strtrim(substr(`"`tail'"',1,`hash'-1))
            local suffix=substr(`"`tail'"',`hash',.)
        }
        if !regexm("`target'","^[A-Za-z_][A-Za-z0-9_]*$") | strlen("`target'")>32 {
            di as error "{name} requires a nonempty destination ID of at most 32 letters, digits, or underscores, starting with a letter or underscore"
            exit 198
        }
        local prefix=substr(`"`label'"',1,`marker'-1)
        local label `"`prefix'`suffix'"'
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
end
