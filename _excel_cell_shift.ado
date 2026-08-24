capture program drop _excel_cell_shift
program define _excel_cell_shift, rclass
    syntax , Cell(string) Rowinc(integer) Colinc(integer)

    // Extract column letters and row number
    local col ""
    local row ""

    // Separate letters and digits manually
    forvalues i = 1/`=length("`cell'")' {
        local ch = substr("`cell'", `i', 1)
        if regexm("`ch'", "[A-Z]") {
            local col "`col'`ch'"
        }
        else if regexm("`ch'", "[0-9]") {
            local row "`row'`ch'"
        }
    }

    // Convert column letters to number
    local colnum = 0
    local len = length("`col'")
    forvalues i = 1/`len' {
        local ch = substr("`col'", `i', 1)

        // find position in alphabet using strpos()
        local value = strpos("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "`ch'")

        local colnum = `colnum' * 26 + `value'
    }

    // Apply increments
    local newrow = real("`row'") + `rowinc'
    local newcolnum = `colnum' + `colinc'

    // Convert number back to column letters
    local newcol ""
    while (`newcolnum' > 0) {
        local rem = mod(`newcolnum' - 1, 26)
        local letter = substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", `rem' + 1, 1)
        local newcol "`letter'`newcol'"
        local newcolnum = floor((`newcolnum' - 1) / 26)
    }

    // Final result
    local result "`newcol'`newrow'"
    return local cell "`result'"

    di "`result'"
end

