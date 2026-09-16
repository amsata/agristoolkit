{smcl}
{title:add_name — build indicator naming metadata}

{p 8 12 2}{cmd:add_name} {it:sourceID}{cmd:@}{it:long label}[{cmd:#}{it:short label}][{cmd:{c -(}name{c )-}}{it:finalID}] [{cmd:, start}]

{pstd}{cmd:add_name} appends metadata to {cmd:$indicatornames}.
{cmd:start} starts a new list. It validates structure only; the source ID need
not exist in the dataset. It never modifies data or renames IDs. Invalid input
leaves the global unchanged, including when {cmd:start} is specified.

{pstd}The optional {cmd:{c -(}name{c )-}} marker may follow the short label or
occur between the long label and {cmd:#}. Its destination ends at the next
{cmd:#}, or at the end of the specification. Only one marker is permitted.
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
