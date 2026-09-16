program define extract_macro_elements, rclass
    args mymac start_elem end_elem

    // Convert macro to a list
    tokenize `"`mymac'"'

    local collect ""
    local inside = 0  // Flag to start collecting elements

    forvalues i = 1/`=_N' {
        if "``i''" == "`start_elem'" {
            local inside = 1  // Start collecting
        }
        if `inside' {
            local collect "`collect' ``i''"
        }
        if "``i''" == "`end_elem'" {
            continue, break  // Stop exactly at the end element
        }
    }

    return local subset `"`collect'"'
end

* Keep the program's closing end line terminated for older Stata loaders.
