cap program drop expand_varlist
program define expand_varlist, rclass
    args varlist

	*remove extra space before and/or after "-", if any
	local varlist = ustrregexra("`varlist'", "\s*-\s*", "-")

    local expanded_list ""	

    foreach word in `varlist' {
        // Check if the word contains a range (indicated by "-")
        if regexm("`word'", "^-|-$") == 0 & strpos("`word'", "-") {
            local start_var = substr("`word'", 1, strpos("`word'", "-") - 1)
            local end_var = substr("`word'", strpos("`word'", "-") + 1, .)
            
            local temp_list ""
            local found = 0
            foreach var of varlist * {
                if "`var'" == "`start_var'" {
                    local found = 1
                }
                if `found' {
                    local temp_list "`temp_list' `var'"
                }
                if "`var'" == "`end_var'" {
                    continue, break
                }
            }
            local expanded_list "`expanded_list' `temp_list'"
        }
        else {
            local expanded_list "`expanded_list' `word'"
        }
    }

    return local expanded "`expanded_list'"
end

* Keep the program's closing end line terminated for older Stata loaders.
