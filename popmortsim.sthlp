{smcl}
{*      *! version 0.1 2026-08-31}{...}
{vieweralsosee "[R] ..." "mansection R ..."}{...}
{viewerjumpto "Syntax" "popmortsim##syntax"}{...}
{viewerjumpto "Description" "popmortsim##description"}{...}
{viewerjumpto "Options" "popmortsim##options"}{...}
{viewerjumpto "Examples" "popmortsim##examples"}{...}
{hline}

{title:Title}

{p2colset 5 18 10 2}{...}
{p2col :{hi:popmortsim} {hline 1}} Simulate expected survival using population mortality rates {p_end}	
{p2colreset}{...}


{title:Syntax}
{p 8 16 2}{cmd:popmortsim} {it:survtime event} {cmd:using} {it:filename} [{it:if}] [{it:in}], 
{opt agediag(varname)} {opt datediag(varname)} [{it:options}]


{marker options}{...}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Options}

{synopt :{opt agediag(varname)}} age at diagnosis (in years){p_end}
{synopt :{opt datediag(varname)}} date at diagnosis{p_end}
{synopt :{opt pmage(varname)}} name of age variable in popmort file{p_end}
{synopt :{opt pmyear(varname)}} name of calendar year variable in popmort file {p_end}
{synopt :{opt pmother(varname)}} name of other variables in popmort file{p_end}
{synopt :{opt pmrate(varname)}} name of rate variable in popmort file{p_end}
{synopt :{opt pmmaxage(#)}} maximum age in the popmort file {p_end}
{synopt :{opt pmmaxyear(#)}} maximum year in the popmort file {p_end}
{synopt :{opt maxtime(#)}} maximum follow-up time in years {p_end}

{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
{cmd:popmortsim} simulates survival time and death status for individuals using age-, calendar year-, and optionally other characteristic-specific mortality rates from a population mortality file.

{pstd}
The program generates two new variables. The first contains simulated survival time and the second contains a simulated event indicator, where 1 indicates death and 0 indicates that the individual remains alive until the end of follow-up.

{pstd}
{cmd:using} {it:filename} specifies a file containing general-population mortality rates typically stratified by age, sex, calendar year and potentially other variables. In the {cmd:using} file, age must be specified in one-year increments and calendar year in one-year intervals.

{pstd}
For each observation in the dataset, the command uses the individual's age at diagnosis ({cmd:agediag()}) and date of diagnosis ({cmd:datediag()}) to construct intervals during follow-up over which the individual's age and/or calendar year changes. The population mortality rate corresponding to each interval is then obtained from the population mortality file.

{pstd}
The simulation is based on the cumulative hazard implied by the supplied population mortality rates. Consequently, the population mortality rates should be expressed as hazards or rates on the same time scale as the follow-up intervals, here years.
A random threshold is generated and compared to the cumulative hazard. Death is assumed to occur at the time at which the cumulative hazard exceeds the threshold. The simulated event indicator is 1 if death occurs within the specified follow-up period and 0 otherwise. For individuals who survive beyond the maximum follow-up time, survival time is set to {cmd:maxtime()}.


{title:Options}

{phang}
{opt agediag(varname)} names the variable containing age at diagnosis. This should be in years. It is best to avoid using truncated (integer) age as this assumes that each person was diagnosed on their birthday. This option is required.

{phang}
{opt datediag(varname)} names the variable containing date at diagnosis. This option is required.

{phang}
{opt pmage(varname)} gives the name of the age variable in the population mortality file. This variable cannot exist in the patient data file, but should exist in the population mortality file. The default is {cmd:_age}.

{phang}
{opt pmyear(varname)} gives the name of the year variable in the population mortality file. This variable cannot exist in the patient data file, but should exist in the population mortality file. The default is {cmd:_year}. If there is no year variable in the population mortality file, use {cmd: pmyear(.)}. 

{phang}
{opt pmother(varlist)} gives all the additional variables in the population mortality file. All variables listed should be in both the data and the population mortality file. Variables specified in {cmd:pmother()} must uniquely identify records in combination with {cmd:pmage()} and {cmd:pmyear()}.

{phang}
{opt pmrate(varname)} name of the rate variable in the population mortality file. The default is {cmd:rate}. The rate should be expressed per person year. If you only have one year survival probabilities in the population mortality file, then you can obtain the rate using {cmd:gen rate = -ln(survprob)}, where {cmd:survprob} is the one year survival probability.

{phang}
{opt pmmaxage(#)} specifies the maximum age for which general-population mortality rates are provided in the population mortality file. Rates for individuals older than this value are assumed to be the same as for the maximum age {it:#}. The default maximum age is the maximum value of {cmd:pmage()} available in the provided popmort file.

{phang}
{opt pmmaxyear(#)} specifies the maximum year for which population mortality rates are provided in the population mortality file. Rates for individuals still at risk after this year are assumed to be the same as for the maximum year {it:#}. The default maximum year is the maximum value of {cmd:pmyear()} available in the provided population mortality file. This option is ignored when {cmd:pmyear(.)} is specified.

{phang}
{opt maxtime(#)} specifies the maximum follow-up time in years. The default is 10 years. The value must be a positive integer. Individuals for whom the simulated death time exceeds {cmd:maxtime()} are assigned an event indicator of 0 and a survival time equal to {cmd:maxtime()}.

{title:Examples}
{pstd}
All examples use the following data setup. You will need to clear data in memory before running.

{pmore}
{stata "set seed 27889":. set seed 27889}{p_end}
{pmore}
{stata "set obs 1000":. set obs 1000}{p_end}
{pmore}
{stata "gen agediag = runiform(70,90)":. gen agediag = runiform(70,90)}{p_end}
{pmore}
{stata "gen datediag = runiformint(mdy(1,1,1985), mdy(12,31,1990))":. gen datediag = runiformint(mdy(1,1,1985), mdy(12,31,1990))}{p_end}
{pmore}
{stata "format %d datediag":. format %d datediag}{p_end}
{pmore}
{stata "gen sex = runiformint(1,2)":. gen sex = runiformint(1,2)}{p_end}
{pmore}
{stata "gen dep = runiformint(1,5)":. gen dep = runiformint(1,5)}{p_end}

{title:Example 1}
{pstd}
Simulate survival time and death indicator using a popmort file with age variable {cmd:_age}, year variable {cmd:_year} and additional stratification by sex.

{phang2}
{stata "popmortsim time dead using https://pclambert.net/data/popmort.dta, agediag(age) datediag(datediag) pmother(sex)":. popmortsim time dead using https://pclambert.net/data/popmort.dta, agediag(age) datediag(diagdate) pmother(sex)}{p_end}


{title:Example 2}
{pstd}
Set the maximum follow-up time 20 years.

{phang2}
{stata "popmortsim time dead using https://pclambert.net/data/popmort.dta, agediag(age) datediag(datediag) pmother(sex) maxtime(20)":. popmortsim time dead using https://pclambert.net/data/popmort.dta, agediag(age) datediag(diagdate) pmother(sex) maxtime(20)}{p_end}

{title:Example 2}
{pstd}
Use a popmort file in which deprevation is included. 
Note that the age variable is not {cmd:_age} and the year variable is not {cmd:_year} which is why the variable names need to be specified in the {cmd:pmage()} and {cmd:pmyear()} options, respectively.

{phang2}
{stata "popmortsim time dead using https://pclambert.net/data/popmort_NW.dta, agediag(age) datediag(datediag) pmage(age) pmyear(year) pmother(sex dep)":. popmortsim time dead using https://pclambert.net/data/popmort_NW.dta, agediag(age) datediag(diagdate) pmage(age) pmyear(year) pmother(sex dep)}{p_end}

{title:Author}

{pstd}
Rebecka Johansson, Department of Medical Epidemiology and Biostatistics, Karolinska Institutet, Sweden.
({browse "mailto:rebecka.johansson.2@ki.se":rebecka.johansson.2@ki.se})




















