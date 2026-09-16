{smcl}
{title:expand_labelled_var}

{pstd}Expand numeric variables with attached value labels into category dummies.
Ordinary numeric variables remain in the returned list at their original position.

{p 8 12 2}{cmd:expand_labelled_var} {cmd:"}{it:expanded variable list}{cmd:"}

{pstd}Call {cmd:expand_varlist} first when the input contains ranges.
The helper creates variables in memory; it does not replace the source variables.
For each defined nonmissing category code {it:n}, it creates
{it:source}{it:n} = ({it:source} == {it:n}) if !missing({it:source}).
Categories are ordered by code, including labelled categories not observed in the
data. Missing codes, including extended missing values, do not create categories.
The dummies have no attached value label, so they are not expanded again.

{pstd}Category codes must be nonnegative integers. Observed nonmissing values must
have nonempty value labels. Undefined/empty label sets, invalid names, existing
target variables, and duplicate generated names are errors. No existing variable
is overwritten. The complete request is validated before creating dummies.

{title:Returned results}
{pstd}{cmd:r(expanded)} contains the complete list for estimation, including ordinary
variables. The following parallel lists describe generated variables only:
{cmd:r(generated)}, {cmd:r(sources)}, {cmd:r(codes)}, and the compound-quoted
{cmd:r(labels)}. {cmd:r(n_generated)} gives their count.
For reliable access to labels containing spaces or quotes, indexed macros
{cmd:r(variable1)}, {cmd:r(source1)}, {cmd:r(code1)}, {cmd:r(label1)}, etc.,
contain the same metadata. Copy these results before another r-class command.

{title:Example}
{cmd}
    expand_varlist "SEX_PROP age"
    local requested `r(expanded)'
    expand_labelled_var "`requested'"
    local mean_variables `r(expanded)'
{txt}

{pstd}See also {help genmdt}.
