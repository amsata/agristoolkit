*! Compatibility entry point for the original internal two-dimension writer.
capture program drop _tab_from_mdt_over2
program define _tab_from_mdt_over2, rclass
    _tab_from_mdt_over `0'
    return add
end
