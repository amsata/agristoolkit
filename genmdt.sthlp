{smcl}
{* *! version 1.3.22  01apr2019}{...}

{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:genmdt} [{help genmdt##varlist:{it:varlist}}] [{cmd:,}
           {help genmdt##svy_options:{it: svy_options}}
		   {help genmdt##dimension_options:{it: dimension_options}}
		   {help genmdt##formating_options:{it: formating_options}}] {cmd::} {it:command}


{marker varlist}{...}
{synopthdr:varlist}
{synoptline}
{synopt :{opt varlist}{cmd:(}[{varlist}]{cmd:)}}identify a subpopulation{p_end}

{marker svy_options}{...}
{synopthdr:svy_options}
{synoptline}

{syntab:parameters}
{synopt :{it:{help mean} ([{help varlist}])}}Used to specify list of variables that will estimated with svy:mean (see {manhelp svy_estimation SVY:svy:mean }){p_end}
{synopt :{it:{help median} ([{help varlist}])}}Used to specify list of variables that will be estimated with median (see {helpb collapse}){p_end}
{synopt :{it:{help total} ([{help varlist}])}}Used to specify list of variables that will be estimated with svy:total (see {manhelp svy_estimation SVY:svy:total}){p_end}
{synopt :{it:{help ratio} ([{help varlist}])}}Used to specify list of variables that will be estimated with svy:ratio (see {manhelp svy_estimation SVY:svy:ratio}){p_end}

{syntab:if}
{synopt :{opt sub:pop}{cmd:(}[{varname}] [{it:{help if}}]{cmd:)}}identify a subpopulation within which estimation should be done (see {help svy##svy_options:{it:svy survvey options}}){p_end}

{syntab:Reporting and formating}
{synopt :{opt units}{cmd:(}"[{varname}]@Unit",...{cmd:)}} Allow to add unit for estimated indicators{p_end}

{synopt :{opt indicator:name}{cmd:(}"[{varname}]@Indicator name",...{cmd:)}} Allow to add indicator label for estimated indicators {p_end}

{synopt :{opt int:eger}{cmd:(}[{varlist}]{cmd:)}}Convert estimation results for variables in varlist into interger in the final output{p_end}

{marker dimension_options}{...}
{synopthdr:dimension_options}
{synoptline}
	
{syntab:label}
{synopt :{opt margin:labels}{cmd:(}"[{varname}]@label",...{cmd:)}} Allow to add a label in the margin when parameters are estimated convering all categories of a disaggregation variable specidied in  
	{help genmdt##varlist:{it: genmdt varlist}} {p_end}

{syntab: aditional dimensions}
{synopt :{opt hiergeo:vars}{cmd:(}[{varlist}]{cmd:)}}List of hierarchical geographic variables which results should be put in one column{p_end}

{synopt :{opt geomargin:labels (string)}}Label of margin of the geographic variables{p_end}

You can see an article dedicated to this usecase (see example)


{marker description}{...}
{title:Description}

{p 4 6 2}
{cmd:genmdt} requires that the survey design variables be identified using
{helpb svyset}.
{p_end}
{p 4 6 2}
{it:command} defines the estimation command to be executed.  The {helpb by}
prefix cannot be part of {it:command}.{p_end}
{p 4 6 2}
Warning:  Using {cmd:if} or {cmd:in} restrictions will often not produce correct
variance estimates for subpopulations.  To compute estimates
for subpopulations, use the {cmd:subpop()} option.
{p_end}
{p 4 6 2}
See {helpb svy postestimation:[SVY] svy postestimation} for features available
after estimation.
{p_end}
{p2colreset}{...}


{pstd}
{cmd:genmdt} uses the advantages of the command {helpb svy} to compile multidimensional statistical table containing indicator estimated by {helpb mean},  {helpb total}, or {helpb ratio} (see {manhelp svy_estimation SVY:svy estimation})  for complex survey data by adjusting the results of a command for survey settings identified by {helpb svyset}. Exeptionally, the {helpb median} is estimate using by {helpb collapse}.
{marker linksweb}{...}
{title:Links to external documentation}

        {browse "https://amsata.github.io/agristoolkit/":Quick start}

        {browse "https://amsata.github.io/agristoolkit/":Remarks and examples}

        {browse "https://amsata.github.io/agristoolkit/":Methods and formulas}

{pstd}
The above sections are not included in this help file.


{marker options}{...}
{title:Options}

{dlgtab:Disaggregation dimensions}

{phang}
[{it:{help varlist}}] in {opt genmdt}{cmd:[}{it:varlist}{cmd:]} allow to specifies disagregation dimensions or estimation domains fro the different indicator to be computed.

{pmore}
Varlist are literally passed throught the over option in svy once inside genmdt. If no varlist is specified, indicators are estimated in the sampling domain. One have the possiblity to computed the different indicator in both specified domains and the sampling domain, in this case, you shoud use the option {cmd:[}{it:marginlabel}{cmd:]} which, on the one hand, allow to compute the indicators for the sampling dimain, and in the other hand specify which label to consider when indicators are compute regardless of a dimension variable. For example, {cmd:}{it:marginlabel("SEX@Both sex")}{cmd:} allow to estimate indicators for both sex when sex is part of the estimation domains.

{pmore}
For example, {cmd:}{it:marginlabel("SEX@Both sex")}{cmd:} allow to estimate indicators for both sex when sex is part of the estimation domains and the value "Both sex" will be added among the category of the sex variable ("Male", "Female" and "Both sex").

{pmore}
In case of hierarchical geographic dimensions, the dimensions should be specidied in the optons hiergeovars intead of varlist to account for this specifity


{dlgtab:Parameters}

{phang}

genmdt allow to compute indicators using different estimation parameters like mean, total , ratio and ratio. Variables to be estimated using a given parater should be specified parameters (varlist). It is possible to use ranges like varJ-varK in mean, total or median. In ratio option, variable to be estimated shpuld be specified like in ratio estimation in svy, example ratio(varK/VarJ varN/VarM RatName:V1/V2). 

{pmore}
 The result of genmdt after estimation of parameters is a long format layout with the dimensions, the variable to be estimated, the parameter used, the estimation value, the number of non-missing observation used (non-weighted and weighted) the cofficient of variation, the confidence interval bounds , the standard error, etc. (see layout example in {browse "https://amsata.github.io/agristoolkit/getting-started.html#indicators": getting started})


{dlgtab:if/in}

{phang}
{opt subpop}{cmd:(}{it:subpop}{cmd:)} specifies that
estimates be computed for the single subpopulation identified by
{it:subpop}, which is

{pmore2}
[{varname}] [{it:{help if}}]

{pmore}
Thus the subpopulation is defined by the observations for which
{it:varname}!=0 that also meet the {cmd:if} conditions.  Typically,
{it:varname}=1 defines the subpopulation, and {it:varname}=0 indicates
observations not belonging to the subpopulation.  For observations whose
subpopulation status is uncertain, {it:varname} should be set to a missing
value; such observations are dropped from the estimation sample.

{pmore}
See {manlink SVY Subpopulation estimation}.


{dlgtab:Reporting}

{phang}
To make the genmdt layout more userfriendly and enhance the presentation, it is possible to assiciate with each indicator its unit and label. Those are done with the option {opt units} and {opt indicator:names}. 

{pmore}
Units and indicator labels should be specified as follow : {cmd:}{it: units("VarK@unit of varK" "VarJ@unit of varJ", etc.)}{cmd:} and {cmd:}{it: indicatornames("VarK@Indicator label for varK", "VarJ@Indicator label for varJ", etc.)}{cmd:}

{pmore}
Incase some indicators should be displayed as interger, one can use the  {opt integer(varlist)} options to list variables which estimation results should be displayed as interger.


{marker examples}{...}
{title:Examples}

In this exemple we are going to use the nhanes2f dataset and generate a multidimensional statistical tables containings different indicators

Example 1:
Estimating the following indicator:
	1. Average age of the reference population  
	
{phang}
{cmd:. webuse nhanes2f}
{p_end}
{phang}
{cmd:. svyset psuid [pweight=finalwgt], strata(stratid)}
{p_end}
{phang}
{cmd:. genmdt region, mean(age)}
{p_end}

Example 2:
Estimating the following indicator:
	1. Average age of the reference population
by adding the options {opt marginlabels}, {opt units} and {opt indicatornames}

{phang}
{cmd:. webuse nhanes2f}
{p_end}
{phang}
{cmd:. svyset psuid [pweight=finalwgt], strata(stratid)}
{p_end}
{phang}
{cmd:. genmdt region, marginlabels("region@USA") mean(age) units("age@Years") indicator("age@average age of individuals")}
{p_end}

Example 3:
Estimating the following indicator:
	1. Proportion of people with diabetes (percentage)
	2. Proportion of people with high blood pressure (percentage)
	3. Total number of people who have had a heart attack (count)
by adding the options {opt marginlabels}, {opt units} and {opt indicatornames} and {opt integer}

{phang}
{cmd:. genmdt region sex rural , marginlabels("region@USA" "sex@both") mean(highbp diabetes) total(heartatk) integer(heartatk) units("highbp@%" "diabetes@%" "heartatk@people") indicator( "highbp@Proportion of people with high blood pressure" "diabetes@Proportion of people with diabetes" "heartatk@Total number of people who have had a heart attack" )}
{p_end}

{marker reference}{...}
{title:Reference}
