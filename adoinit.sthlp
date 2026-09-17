{smcl}
{title:adoinit - Initialize a project's ado folder}

{p 8 16 2}{cmd:adoinit, path("parent directory")} [{cmd:name("ado")} {cmd:replace}
{cmd:agrisfrom("source")} {cmd:parallelfrom("source")} {cmd:sscfrom("source")}]

{pstd}Creates one folder under an existing parent and installs agristoolkit,
tuples, elabel, confirmdir, and parallel into it.

{pstd}The default folder name is ado. An existing folder requires replace;
this updates packages and can change results. Do not initialize on every analysis
run. Keep and share the populated folder with the project to preserve its packages.
Downloads use current upstream versions; this is not a package-version lockfile.

{pstd}The command restores the previous net ado-install destination on success or
installation error, and does not change adopath, sysdir, the working directory,
or the dataset. The net browsing source may change during installation.
A failed installation leaves a partial folder for inspection/retry with replace.

{pstd}agrisfrom() defaults to
https://raw.githubusercontent.com/amsata/agristoolkit/main/ .
parallelfrom() defaults to https://raw.github.com/gvegayon/parallel/stable/ .
sscfrom(), when omitted, uses ssc install. Source options accept local net-package
repositories or URLs and allow archived/pinned sources and offline installation.

{title:Example}
{phang}{cmd:adoinit, path("$ODP_wd/2.Scripts") name("ado")}
{phang}{cmd:adopath ++ "$ODP_wd/2.Scripts/ado"}

{pstd}Use adopath ++ in the master do-file to prioritize the project folder.
Other ado directories remain available. adoinit does not clear data or set a project version.
The initializer requires Stata 13; installed packages have their own requirements.
In particular, tab_from_mdt requires native Stata 14.1 or later. Native Stata 14.0
can initialize a folder but cannot run tab_from_mdt.

{pstd}For a first installation, obtain agristoolkit with net install before
calling adoinit. After this command is published it is included in agristoolkit.
The current upstream main branch may differ from a local development checkout.

{title:Stored results}
{pstd}{cmd:r(adopath)} contains the populated ado-folder path.
