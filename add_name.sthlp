{smcl}
{title:add_name — build indicator naming metadata}

{p 8 12 2}{cmd:add_name} {it:sourceID}{cmd:@}{it:long label}[{cmd:#}{it:short label}][{cmd:{c -(}name{c )-}}{it:finalID}][{cmd:{c -(}qxvars{c )-}}{it:source variables}][{cmd:{c -(}dst{c )-}}{it:source datasets}] [{cmd:, start}]

{pstd}{cmd:add_name} appends metadata to {cmd:$indicatornames}.
{cmd:start} starts a new list. It validates structure only; the source ID need
not exist in the dataset. It never modifies data or renames IDs. Invalid input
leaves the global unchanged, including when {cmd:start} is specified.

{pstd}The optional {cmd:{c -(}name{c )-}} marker may follow the short label or
occur between the long label and {cmd:#}. Its destination ends at the next
{cmd:#}, the next metadata marker, or the end of the specification.
Only one marker of each type is permitted per specification.
IDs use at most 32 ASCII letters, digits, or underscores and start with a letter
or underscore. The long label and destination must be nonempty. The short label
and the marker are optional. IDs are case sensitive.

{pstd}{cmd:genmdt} accepts the same specifications directly in
{cmd:indicatorname()}. After category expansion, it validates source IDs against
selected indicators and checks destination collisions, including unchanged IDs.
It removes the marker and destination from {cmd:IndicatorName}, preserving
{cmd:#short label}. Only at the end, after unit assignment, percentage conversion,
and integer formatting, does it rename values of {cmd:Variable}.
Use original/generated IDs in {cmd:units()} and {cmd:integer()}, and final IDs
in subsequent {cmd:tab_from_mdt} commands.

{title:Example}
{cmd}
    add_name SEX_PROP1@Male household head#Male{c -(}name{c )-}MALE_HH_HEAD_PCT, start
    add_name SEX_PROP2@Female household head{c -(}name{c )-}FEMALE_HH_HEAD_PCT#Female
    clonevar SEX_PROP = sex
    genmdt region, mean(SEX_PROP) units("SEX_PROP*@%") indicatorname($indicatornames)
{txt}

{pstd}The first entry produces {cmd:Variable = "MALE_HH_HEAD_PCT"} and
{cmd:IndicatorName = "Male household head#Male"}. Category value labels are
not interpreted as renaming instructions; only explicit metadata is parsed.

{pstd}Conflicting destinations for one source and duplicate final IDs are errors.
Swaps and chains use original IDs and do not cascade. Repeated label assignments
retain the existing last-label-wins behavior; a later label-only specification
does not cancel an earlier explicit rename. Without the marker, IDs are unchanged.

{pstd}See also {help genmdt}, {help tab_from_mdt}.

{title:Source variables and datasets}

{pstd}Optional {cmd:{c -(}qxvars{c )-}} and {cmd:{c -(}dst{c )-}} markers
record the source variables and datasets used to calculate an indicator. Example:
{cmd:add_name PROD@Total production#Production{c -(}name{c )-}TOTAL_PROD{c -(}qxvars{c )-}harvest_qty conversion_factor{c -(}dst{c )-}harvest.dta conversion.dta, start}

{pstd}When passed to {cmd:genmdt}'s {opt indicatorname()}, this metadata creates
string columns {cmd:qxvars} and {cmd:datasets}, respectively. Each column is
created only if its marker occurs in at least one specification. Indicators
without that field receive an empty string. Values repeat on every result row
for the indicator, across statistics and geographic levels. This is supplied
provenance, not automatically discovered calculation history. The referenced
variables and files need not exist in the current dataset or on disk.

{pstd}The three markers may occur in any order. A field ends at the next
recognized marker, at {cmd:#} (which starts or resumes the short label), or at
the end of the specification. These delimiters are reserved and cannot occur
literally inside field values. Surrounding spaces are trimmed; internal text
is retained. Each marker may appear at most once per specification and must
have a nonempty value. All marker fields are removed from {cmd:IndicatorName}.

{pstd}Across repeated specifications for the same source ID, the last explicit
{cmd:qxvars} or {cmd:datasets} value wins independently. Omitting a marker does
not erase an earlier value. Existing {cmd:{c -(}name{c )-}} conflict checks
remain unchanged. Metadata is matched to original/generated indicator IDs,
before renaming. A requested dimension named {cmd:qxvars} or {cmd:datasets}
cannot also be used as an active metadata output column; this is an error.
