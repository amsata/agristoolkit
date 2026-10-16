{smcl}
{title:install_agristoolkit_dep}

{pstd}Install agristoolkit dependencies without creating a project ado folder.

{title:Syntax}

{p 8 8 2}{cmd:install_agristoolkit_dep} [{cmd:, replace}]

{title:Description}

{pstd}Installs {cmd:parallel} from
{browse "https://raw.github.com/gvegayon/parallel/stable/":its stable GitHub repository},
{cmd:elabel} from
{browse "https://raw.githubusercontent.com/kleindaniel81/elabel/master/":its GitHub repository},
and {cmd:tuples} and {cmd:confirmdir} from SSC. Rebuilds the Mata library index after successful completion.

{pstd}By default, commands already available on the ado search path are skipped.
{cmd:replace} reinstalls all four dependencies using the specified sources.
If installation fails, the command stops, identifies the failed dependency,
and preserves its error code. Dependencies already installed remain installed.

{pstd}The command does not change {cmd:adopath} or the installation destination.
Installations use Stata's current ado installation destination (normally PLUS).
An existing custom destination set with {cmd:net set ado} is respected.

{title:Examples}

{phang2}{cmd:. install_agristoolkit_dep}
{phang2}{cmd:. install_agristoolkit_dep, replace}

{title:Also see}

{pstd}{help adoinit}, {help net}, {help ssc}
