cap program drop add_name
program define add_name, rclass

syntax anything, [start]

local anything `anything'
// Validate label, rename and optional provenance fields before changing the global.
// Source variables and datasets describe prior calculations and need not exist here.
_genmdt_name_parse, spec(`"`anything'"')
local newtext = subinstr(`"`anything'"', "'", "&&&", .)
local newtext = subinstr(`"`newtext'"', " ", "***", .)

if ("`start'"!="") {
    local combined `" `"`newtext'"' "'
	cap macro drop _global indicatornames
}
else {

local gobmac : copy global indicatornames

local combined = `"`gobmac' `"`newtext'"'"'
}
    global indicatornames `"`combined'"'
end
