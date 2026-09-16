cap program drop add_name
program define add_name, rclass

syntax anything, [start]

local anything `anything'
// Structural validation only: generated IDs need not exist yet.
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
