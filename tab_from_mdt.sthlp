{smcl}
{* *! tab_from_mdt help updated 10sep2026}{...}
{vieweralsosee "genmdt" "help genmdt"}{...}
{vieweralsosee "putexcel" "help putexcel"}{...}
{viewerjumpto "Syntax" "tab_from_mdt##syntax"}{...}
{viewerjumpto "Description and data" "tab_from_mdt##description"}{...}
{viewerjumpto "Layouts" "tab_from_mdt##layouts"}{...}
{viewerjumpto "Options" "tab_from_mdt##options"}{...}
{viewerjumpto "Examples" "tab_from_mdt##examples"}{...}
{viewerjumpto "Stored results" "tab_from_mdt##results"}{...}
{viewerjumpto "Requirements and limitations" "tab_from_mdt##requirements"}{...}

{title:Title}

{p2colset 5 23 25 2}{...}
{p2col:{bf:tab_from_mdt}}Create formatted Excel tables from a multidimensional table{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tab_from_mdt} {it:rowvars} [{cmd:if} {it:exp}],
{cmd:indicator(}{it:IDs}{cmd:)}
{cmd:outfile(}{it:filename} [{cmd:,} {it:sheet} [{cmd:,} {it:row} [{cmd:,} {it:column}]]]{cmd:)}
[{it:options}]

{pstd}
{it:rowvars} lists the variables identifying table rows. Supply indicator IDs as
space-separated string values, without a separate comma between IDs.
Only {cmd:if} is supported; {cmd:in}, weights, and a colon estimation command are
not part of this syntax. Options follow the comma after the row variables.

{synoptset 29 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Required}
{synopt:{cmd:indicator(}{it:IDs}{cmd:)}}indicator IDs to display{p_end}
{synopt:{cmd:outfile(}{it:filename ...}{cmd:)}}Excel workbook and optional placement{p_end}
{synopt:{opt noprog:ress}}suppress automatic over() progress display{p_end}
{syntab:Layout}
{synopt:{cmd:over(}{it:varlist}{cmd:)}}one, two, or three column dimensions{p_end}
{synopt:{opt byi:ndicator}}one table per indicator, stacked vertically{p_end}
{synopt:{opt omit:absentcomb}}omit absent pairs/triples; requires two or three over variables{p_end}
{synopt:{cmd:by(}{it:varlist}{cmd:)}}legacy category layout and indicator stacking{p_end}
{syntab:Input variables}
{synopt:{cmd:indvar(}{it:varname}{cmd:)}}string ID variable; default {cmd:Variable}{p_end}
{synopt:{cmd:indicatorname(}{it:varname}{cmd:)}}string indicator-label variable; default {cmd:IndicatorName}{p_end}
{synopt:{cmd:value(}{it:varname}{cmd:)}}string or numeric values; default {cmd:Value_str}{p_end}
{syntab:Content and formatting}
{synopt:{cmd:tabtitle(}{it:string}{cmd:)}}table title; supports an indicator-title template with {cmd:byindicator}{p_end}
{synopt:{cmd:header(}{it:string}{cmd:)}}additional heading{p_end}
{synopt:{cmd:labeldim(}{it:strings}{cmd:)}}one quoted heading per row variable{p_end}
{synopt:{cmd:rowtotal(}{it:string}{cmd:)}}add a total column with this heading; meaning depends on layout{p_end}
{synopt:{cmd:valid(}{it:string}{cmd:)}}population-column heading where supported{p_end}
{synopt:{cmd:subpopvar(}{it:varname}{cmd:)}}population variable; default {cmd:N_subPop} where supported{p_end}
{synopt:{opt dec:imal(string)}}display decimal separator; default period{p_end}
{synopt:{cmd:source(}{it:string}{cmd:)}}source note below each table{p_end}
{synopt:{opt highlight}}emphasize the last displayed data row{p_end}
{syntab:Workbook management}
{synopt:{opt replace}}replace the workbook when starting output{p_end}
{synopt:{opt prog:ress}}report completed over() combinations{p_end}
{synopt:{opt on:memory}}leave the workbook open for subsequent writes{p_end}
{synoptline}

{marker description}{...}
{title:Description and input data}

{pstd}
{cmd:tab_from_mdt} formats estimates already stored in the dataset in memory,
usually the MDT produced by {help genmdt}. It writes Excel tables using
{help putexcel}. It does not estimate survey statistics, recompute variances,
create population margins, or require {cmd:svyset} for table formatting.
An {cmd:if} condition selects existing MDT observations for display.

{marker varlist}{...}
{pstd}
Each observation should identify one indicator for one complete combination of
row and column dimensions. Keep or filter any additional MDT dimensions so they
do not create duplicate keys. For example, if age group remains in the MDT but
is neither a row variable nor an over variable, select one age group first.

{pstd}
With the default input names, the MDT contains row/column dimension variables,
{cmd:Variable} (string indicator ID), {cmd:IndicatorName} (string label), and
{cmd:Value_str} (display value). {cmd:Value_str} may contain numeric text or
flags such as {cmd:[c]}. To use the underlying numeric estimate, specify
{cmd:value(Value)}. Renamed input variables can be selected with the corresponding
options. The option is {cmd:value()}, not {cmd:valvar()}.

{pstd}
If {cmd:IndicatorName} is unavailable and {cmd:indicatorname()} is omitted, the
indicator ID is used as its label. With two/three over variables or
{cmd:byindicator}, each selected indicator must have one nonmissing label and
nonmissing, unique row/column keys. Missing selected indicators cause an error.

{marker layouts}{...}
{title:Layouts}

{pstd}
Without {cmd:byindicator} or legacy {cmd:by()}:

{phang}No {cmd:over()}: row dimensions at the left and indicators in columns.{p_end}
{phang}One over variable, one indicator: categories of that variable in columns.{p_end}
{phang}One over variable, multiple indicators: category blocks placed side by side,
with indicators within each block. This is the retained legacy layout.{p_end}
{phang}Two or three over variables: one table with nested category headers,
followed by the selected indicator headings.{p_end}

{marker over2}{...}
{pstd}
For {cmd:over(rural sex agegroup)}, the outer header is rural, the next is sex,
and the innermost category header is agegroup. The final header row contains
indicators. Two over variables therefore give three header rows; three give
four. Even a single indicator retains these header levels.

{pstd}
In the two-/three-dimensional writer, numeric codes or string sort order determine
category order, value labels supply numeric category text, and {cmd:indicator()}
determines indicator order. Row variables must be distinct from over variables.
Unused value-label definitions do not create categories.

{marker byindicator}{...}
{pstd}
{cmd:byindicator} creates one table for each selected indicator, in the supplied
order, below the previous table on the same worksheet. It works with zero, one,
two, or three over variables. With one indicator it creates one table.
Each table uses that indicator's observed row and category sets after {cmd:if};
rows, widths, and category sets can differ between tables.

{pstd}
{cmd:by(varlist)} retains the older layout: categories are columns and multiple
indicators are written as separate tables. For new scripts, use
{cmd:byindicator over(varname)} for the single-column-dimension counterpart.
Do not combine {cmd:by()} with {cmd:byindicator}. Combining {cmd:by()} with two or
three over variables is rejected. Avoid combining {cmd:by()} and {cmd:over()}
in new scripts; use one layout specification.

{marker options}{...}
{title:Options}

{marker vars_options}{...}
{dlgtab:Selecting values}

{phang}
{cmd:indicator(}{it:IDs}{cmd:)} is required. IDs are values of {cmd:indvar()}, not
necessarily names of dataset variables. Use distinct IDs, for example
{cmd:indicator(highbp diabetes)}. With {cmd:byindicator}, each ID produces a table.

{phang}
{cmd:indvar()}, {cmd:indicatorname()}, and {cmd:value()} select the ID, label,
and value variables described above. Supply one variable for each option.
For ordinary indicator column headings, the text after {cmd:#} is used when
present. For separate-indicator table titles, the text before {cmd:#} is used.
A label without a hash is used in full.

{marker dimension_options}{...}
{dlgtab:Absent combinations}

{phang}
{cmd:omitabsentcomb} changes only the two-/three-dimensional layout.
Without it, the table uses the Cartesian product of all categories present in
each dimension among the selected observations. An entirely unobserved pair or
triple is displayed with missing cells, {cmd:[:]}.

{pstd}
With {cmd:omitabsentcomb}, a complete pair or triple is omitted only if there
are no MDT observations for any selected indicator across all displayed rows,
after applying {cmd:if}. A combination present in any row remains for all rows;
row-specific missing cells remain {cmd:[:]}.

{pstd}
Blank estimates, flags, numeric zeros, and observations with {cmd:n_Obs == 0}
still count as present. The option does not consult {cmd:n_Obs} or remove existing
placeholder observations. With {cmd:byindicator}, presence is evaluated separately
for each indicator table. Header spans and returned placement columns adjust to
the combinations retained. Without {cmd:over()}, or with only one over variable,
{cmd:omitabsentcomb} is rejected with error 198.

{marker formating_options}{...}
{dlgtab:Titles, headings, and notes}

{phang}
{cmd:tabtitle(}{it:string}{cmd:)} supplies a title. For {cmd:byindicator}, the
default is the indicator label before the first hash. The literal placeholder
{cmd:{c -(}title{c )-}} in a supplied title is replaced for each indicator; for
example, {cmd:tabtitle("Results: {c -(}title{c )-}")}.
The legacy separate-indicator layout also supports this placeholder.
It is not expanded for a combined two-/three-dimensional table.

{phang}
{cmd:header(}{it:string}{cmd:)} adds another heading. With two/three over variables,
title and header each occupy one row above the category headers. Legacy layouts
place headings differently; the one-over, multiple-indicator layout uses category
labels for its block headings.

{phang}
{cmd:labeldim(}{it:strings}{cmd:)} replaces row-variable headings, for example
{cmd:labeldim("Region" "District")}. Supply one label for each row variable.
Category labels still come from dimension values/value labels.

{phang}
{cmd:source(}{it:string}{cmd:)} writes a source note. Masked-cell and zero-cell
percentage notes are also generated. With {cmd:byindicator}, each table has its
own notes. In the two-/three-dimensional writer these percentages are calculated
from indicator cells in the displayed grid, including missing cells, and exclude
population and derived-total columns. Blank/nonnumeric values count as masked.

{phang}
{cmd:highlight} emphasizes the last displayed data row. It does not identify or
calculate a national total; select/order the MDT appropriately.

{phang}
{cmd:decimal(}{it:string}{cmd:)} replaces the decimal separator in displayed value
strings, for example {cmd:decimal(",")}. It is not a request for a number of
decimal places. In the two-/three-dimensional writer, converted strings may be
stored as Excel text; calculated totals retain their numeric Excel formatting.

{dlgtab:Totals and population columns}

{phang}
{cmd:rowtotal(}{it:string}{cmd:)} adds a total with the supplied heading.
The meaning follows the selected layout:

{phang2}No over variable: sum indicator columns within each row.{p_end}
{phang2}One over variable and one indicator (including {cmd:byindicator}):
sum across category columns.{p_end}
{phang2}One over variable and multiple indicators, without {cmd:byindicator}:
sum indicators within each category block.{p_end}
{phang2}Two/three over variables: sum selected indicators within each complete
category pair/triple, excluding the population column. Do not sum across category
levels. With {cmd:byindicator}, each numeric total repeats its one indicator.{p_end}

{pstd}
For two/three over variables, a nonempty nonnumeric component produces
{cmd:[-]} in its total. Blank components are omitted; a combination with no
numeric or flagged components produces {cmd:[:]}, not zero. Legacy writers retain
their existing missing/flag rules. Select indicators/categories whose sum is meaningful.

{phang}
{cmd:valid(}{it:string}{cmd:)} requests a population column with this heading.
{cmd:subpopvar(}{it:varname}{cmd:)} selects its numeric source, normally
{cmd:N_subPop}. These values are read from the MDT, not computed from row counts.
When {cmd:valid()} is omitted, {cmd:subpopvar()} is ignored and its variable need not exist.

{pstd}
With two/three over variables, one population column is written per complete
category combination. The selected indicators must have equal, nonmissing
populations within each observed row/category combination; otherwise error 459
is issued. Population values are rounded to integers. With {cmd:byindicator},
checks occur within each separate indicator table.

{pstd}
The legacy no-over writer adds a shared population column only when its population
consistency check passes. The one-over, multiple-indicator block layout uses that
writer per block. The legacy one-indicator category writer does not render
{cmd:valid()} columns, even though it accepts the option; this also applies to
one-over {cmd:byindicator} tables. Legacy {cmd:by()} does not forward these
population options. Use the supported two-/three-dimensional layout when a
population column per category combination is needed.

{marker saving_options}{...}
{dlgtab:Workbook and placement}

{phang}
{cmd:outfile()} is required. Its positional arguments are filename, sheet,
starting row, and starting column, for example
{cmd:outfile("./report.xlsx", "Results", 4, C)}. Defaults are worksheet
{cmd:TABLES}, row 1, column A. Specify intervening arguments when supplying a later
argument. Include a directory component in the filename, for example "./report.xlsx" or an absolute path. Relative paths are relative to Stata's working directory.

{phang}
{cmd:replace} replaces the workbook, not just a table or worksheet. Without it,
the selected worksheet is modified at the requested cells. With {cmd:byindicator},
replacement occurs only for the first table. Writing a narrower table into an
existing range does not clear unrelated old cells; use a fresh area or workbook.

{phang}
Progress is displayed automatically with {cmd:over()}. It reports completed combinations while
writing values, at most once per second plus the initial and final counts.
With {cmd:omitabsentcomb}, the denominator counts retained combinations.
With {cmd:byindicator}, each indicator has its own counter and indicator ID.
100% means the combination values have been written; remaining formatting and
saving finish before the separate table-completion message. Preparation can take
time before the counter starts. Messages are written to Results and active logs.
Specify {opt noprog:ress} (or {cmd:noprog}) to suppress progress messages.
Without {cmd:over()}, no progress is displayed; {cmd:noprogress} is harmless.
The former {cmd:progress} option is no longer accepted. Workbook saving is unchanged.

{phang}
{cmd:onmemory} keeps the putexcel workbook open for subsequent writes.
Use {cmd:putexcel close} on Stata versions below 16, or {cmd:putexcel save}
on Stata 16 or later, to finish. Without {cmd:onmemory}, the command saves
when it finishes the table or indicator stack.

{pstd}
{cmd:outfile("no", "Results", 20, A)} reuses the active putexcel worksheet.
It requires an already configured workbook, normally kept open by
{cmd:onmemory}. The sheet argument does not switch sheets in this mode.
Use an explicit filename and sheet to select another worksheet.

{marker examples}{...}
{title:Examples}

{pstd}
The following self-contained example uses a small illustrative MDT, not survey
estimates. Run it in a writable working directory. It replaces the example
workbooks named below. With an installed package, the adopath line is unnecessary;
for this development checkout use:

{phang2}{cmd:. adopath ++ "C:\Users\USER\Documents\GitHub\agrisvyst"}{p_end}

{pstd}Create the example MDT:{p_end}
{cmd}
    clear
    input byte(region rural sex agegroup) str1 Variable double Value
    1 1 1 1 "a" 10
    1 1 1 1 "b" 20
    1 2 1 1 "a" 30
    1 2 1 1 "b" 40
    1 2 2 2 "a" 50
    1 2 2 2 "b" 60
    2 1 1 1 "a" 15
    2 1 1 1 "b" 25
    2 2 1 1 "a" 35
    2 2 1 1 "b" 45
    2 2 2 2 "a" 55
    2 2 2 2 "b" 65
    end
    generate str12 Value_str = trim(string(Value))
    generate str30 IndicatorName = "Measure " + Variable
    generate double N_subPop = 100 * region
    label define regions 1 "North" 2 "South"
    label values region regions
    label define residence 1 "Rural" 2 "Urban"
    label values rural residence
    label define sexes 1 "Female" 2 "Male"
    label values sex sexes
    label define ages 1 "Younger" 2 "Older"
    label values agegroup ages
{txt}

{pstd}Simple table without over(): select the other dimensions to ensure unique keys.{p_end}
{cmd}
    tab_from_mdt region if rural==1 & sex==1 & agegroup==1, indicator(a b) ///
        outfile("./example_simple.xlsx") replace
{txt}

{pstd}One column dimension, with a separate table per indicator:{p_end}
{cmd}
    tab_from_mdt region if sex==1 & agegroup==1, indicator(a b) over(rural) ///
        byindicator outfile("./example_byindicator.xlsx") replace
{txt}

{pstd}Two nested dimensions, including populations and indicator totals:{p_end}
{cmd}
    tab_from_mdt region if agegroup==1, indicator(a b) over(rural sex) ///
        valid("Population") rowtotal("Total") ///
        outfile("./example_over2.xlsx") replace
{txt}

{pstd}Three nested dimensions, first rectangular and then omitting absent triples:{p_end}
{cmd}
    tab_from_mdt region, indicator(a b) over(rural sex agegroup) ///
        outfile("./example_full.xlsx") replace
    tab_from_mdt region, indicator(a b) over(rural sex agegroup) ///
        omitabsentcomb outfile("./example_compact.xlsx") replace
{txt}

{pstd}Separate compact tables with a title template and a source note:{p_end}
{cmd}
    tab_from_mdt region, indicator(b a) over(rural sex agegroup) byindicator ///
        omitabsentcomb tabtitle("Results: {c -(}title{c )-}") ///
        source("Illustrative data") ///
        outfile("./example_separate.xlsx", "Results", 3, C) replace
{txt}

{pstd}Append using returned row coordinates and an open workbook:{p_end}
{cmd}
    tab_from_mdt region, indicator(a) over(rural sex agegroup) ///
        outfile("./example_append.xlsx") replace onmemory
    local next = r(tab_end_line)
    tab_from_mdt region, indicator(b) over(rural sex agegroup) ///
        outfile("no", "TABLES", `next', A) onmemory
    if c(stata_version)<16 putexcel close
    else putexcel save
{txt}

{pstd}
For survey work, first run {help genmdt} on the survey dataset, then apply
{cmd:tab_from_mdt} to its output. The package's development baseline examples
under {cmd:codex/base_line_examples} demonstrate this workflow with NHANES II.
That local development folder is not required for installed-package use.

{marker results}{...}
{title:Stored results}

{pstd}{cmd:tab_from_mdt} returns placement information in {cmd:r()}, not estimation results in {cmd:e()}.{p_end}
{synoptset 29 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:r(tab_start_line)}}starting row{p_end}
{synopt:{cmd:r(tab_end_line)}}row coordinate for placing subsequent output{p_end}
{synopt:{cmd:r(n_tables)}}number of tables; returned only with {cmd:byindicator}{p_end}
{syntab:Macros}
{synopt:{cmd:r(tab_start_cell_letter)}}starting Excel column{p_end}
{synopt:{cmd:r(tab_end_cell_letter)}}column coordinate for placing subsequent output{p_end}

{pstd}
These are placement coordinates, not the occupied cell range. For the two-/three-
dimensional writer, the end row is two rows after the final note and the end
column is three columns after the last data column. With {cmd:byindicator},
the start belongs to the first table, the end row follows the last table, and
the end column is the furthest returned placement column across the stack.

{pstd}
Legacy return conventions are retained: some zero-/one-over paths return an empty
starting-column macro, and legacy {cmd:by()} may report the last table's starting
row. Retain an explicit starting column in older scripts when needed. Copy
returned values into locals before running another command that changes {cmd:r()}.

{marker requirements}{...}
{title:Requirements and limitations}

{pstd}
The command requires Stata 14.1 or later and is tested with Stata 15.1 and 16.
Native Stata 14.1 remains untested. On Stata versions below 16, workbook saving
uses {cmd:putexcel close}; Stata 16 or later uses {cmd:putexcel save}.
With {cmd:onmemory}, writing remains pending until explicitly saved; use the
appropriate command for your installed version after completing your tables.
Install the package's helper ado-files together; legacy paths also check for
{cmd:confirmdir} (available via {cmd:ssc install confirmdir}).

{pstd}
The two-/three-dimensional writer supports numeric and string categories and
checks Excel's row/column limits, including its returned placement coordinates.
The legacy writers have shorter fixed column-letter lists and different string-
category/formatting behavior. Their full Excel-width support is not guaranteed.
The {cmd:byindicator} branch reuses these writers for zero/one over variable.

{pstd}
Errors 198 cover invalid option combinations, duplicate or more than three over
variables (including expanded ranges/wildcards), and invalid placement in the
new writer. Errors 2000 and 459 identify missing selections and inconsistent
labels/keys/populations in the new paths. Select the correct MDT slice rather
than dropping duplicates arbitrarily. A failure while writing later tables can
leave earlier workbook output; Excel writes are not transactional.

{pstd}
The new multi-dimensional and {cmd:byindicator} paths restore the original dataset.
Legacy behavior is retained, including formatting and return-value limitations.
{cmd:tab_from_mdt} does not change the estimation logic in {cmd:genmdt}.

{pstd}
Table writers reuse complete Excel styles to reduce stored formatting records.
Values and merges are written before final formatting is applied. Formatting
outside the cells touched by the table is retained. The helper tracks its own
prior table formatting; it does not import arbitrary pre-existing styles inside
the target cells. The implementation uses Stata's open workbook handle and has
been tested on native Stata 15.1 and 16. Error 498 indicates that the required
open workbook handle is unavailable.

{title:Also see}

{psee}{help genmdt}, {help add_name}, {help erase_after_hash}, {help putexcel}{p_end}
