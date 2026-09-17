*! version 1.1 2026-09-16

program define popmortsim, sortpreserve
	version 16.0
	
	// Define the syntax of the program.
	// The program requires exactly two new variables:
	//   1. survival time
	//   2. event indicator (1 = dead, 0 = alive)
	// It also requires a population mortality file and the age/date at diagnosis.
	
	syntax newvarlist(min=2 max=2) /// first variable: survival time, second variable: event indicator, 1=dead 0=alive
	using/ /// need popmort file 
	[if] [in], /// optional
	agediag(varname) /// age at diagnosis
	datediag(varname) /// date of diagnosis
	[pmage(string) /// name of age variable in popmort file, default is _age
	pmyear(string) /// name of year variable in popmort file, default is _year (pmyear(.) if no year variable)
	pmrate(string) /// name of mortality rate variable in popmort file, default is rate
	pmother(varlist) /// optional: name of other variables in the popmort file, must also be variables in the dataset
	pmmaxage(real -1) /// maximum age in popmort file, default is the maximum age in the provided popmort file
    pmmaxyear(real -1) /// maximum year in popmort file, default is the maximum year in the provided popmort file
	maxtime(real 10)] /// maximum follow-up time in years, default is 10 years.
	
	
	// Mark the observations that satisfy the optional if/in conditions.
	marksample touse, novarlist
	
	// Get variables from population mortality file
	local usingfilename `using'
	qui describe using "`usingfilename'", varlist short
	local popmortvars `r(varlist)'

	// Set default variable names for the population mortality file.
	// Age defaults to _age, mortality rate to rate, and year to _year.
	if "`pmage'" == "" local pmage _age
	if "`pmrate'" == "" local pmrate rate
	if "`pmyear'" == "" local pmyear _year
	else if "`pmyear'" == "." local pmyear
		
	
	// Load the population mortality data into a temporary frame.
	// This frame is used to determine the maximum available age and year.
	tempname popmortdata
	qui frame create `popmortdata'
	qui frame `popmortdata': use "`usingfilename'", clear

	// Default maximum age to the maximum age available in the population mortality file if pmmaxage() was not specified.
	if `pmmaxage' == -1 {
		qui frame `popmortdata': summarize `pmage', meanonly
		local pmmaxage = r(max)
	}

	// Default maximum year to maximum available in population mortality file.
	// This is only done when a year variable is being used.
	if `pmmaxyear' == -1 & "`pmyear'" != "" {
		quietly frame `popmortdata': summarize `pmyear', meanonly
		local pmmaxyear = r(max)
	}

	// The temporary frame is no longer needed.
	frame drop `popmortdata'

	// Check that the maximum age is a positive integer.
	// Population mortality tables are expected to use integer ages.
	if missing(`pmmaxage') | `pmmaxage' <= 0 | ///
	   `pmmaxage' != floor(`pmmaxage') {
		di as error "pmmaxage() must be a positive integer"
		exit 198
	}
	
	
	// If a year variable is being used, check that the maximum year is a positive integer.
	if "`pmyear'" != "" {
		if missing(`pmmaxyear') | `pmmaxyear' <= 0 | ///
		   `pmmaxyear' != floor(`pmmaxyear') {
			di as error "pmmaxyear() must be a positive integer"
			exit 198
		}
	}
	
	// Check that all variables required from the population mortality file actually exist in that file.
	foreach var in `pmage' `pmyear' `pmother' `pmrate' {
		local varinpopmort: list posof "`var'" in popmortvars
		if !`varinpopmort' {
			di as error "`var' is not in population mortality file"
			exit 198
		
		}
	}
	
	// Check that variables specified in pmother() are not also being used as the age, year, or mortality-rate variables.
	foreach var in pmage pmyear pmrate {
		local conflict: list pmother & `var'
		if "`conflict'" != "" {
			di as error ///
				"pmother() cannot contain the variable `conflict'"
			exit 198
		}
	}	
	
	// If additional matching variables were specified in pmother(),
	// check that those variables also exist in the current dataset.
	if "`pmother'" != "" {
		foreach var of varlist `pmother' {
			capture confirm variable `var'
			if _rc {
				di as error ///
					"Variable `var' specified in pmother() is not in the dataset"
				exit 198
			}
		}
	}
	
	
	// Check that the combination of age, year, and any additional
	// matching variables uniquely identifies records in the population mortality file.
	qui capture isid `pmage' `pmyear' `pmother' using `"`usingfilename'"'
	if _rc {
		display as error ///
        "The variables `pmyear' `pmage' `pmother' do not uniquely specify the records in the population mortality file"
		exit 198
	}
	
	// Check that the maximum follow-up time is a positive integer.
	if missing(`maxtime') | `maxtime' <= 0 | `maxtime' != floor(`maxtime') {
		di as error "maxtime() must be a positive integer"
		exit 198
	}
	
	// Check that date of diagnosis is a numeric Stata date.
	qui capture confirm numeric variable `datediag'
	if _rc {
		di as error "`datediag' must be a Stata date"
		exit 198
	}
	
	// Create a temporary ID that uniquely identifies each observation in the original dataset.
	tempvar id 
	gen `id' = _n if `touse'

	
	// Create a temporary frame containing the observations that will be used in the simulation.
	// Keep only the ID, age/date at diagnosis, and any additional population-mortality matching variables.
	tempname longdata
	frame put `id' `agediag' `datediag' `pmother' if `touse', into(`longdata')
quietly {	
	frame `longdata'{
		gen double timetoagechange = ceil(`agediag')-`agediag' // Calculate the time from diagnosis until the patient's next birthday (i.e., the next integer age).
		replace timetoagechange = 1 if timetoagechange == 0 // If the patient is already exactly an integer age, treat the first age change as occurring one year later rather than immediately.
		gen double timetoyearchange = (mdy(1,1,year(`datediag')+1)-`datediag')/365.25 // Calculate the time from diagnosis until the start of the next calendar year.
		gen byte agefirst = timetoagechange < timetoyearchange // Determine whether the age change occurs before the calendar-year change.
		
		// Expand each individual into multiple rows to represent changes in age and calendar year throughout the specified maximum follow-up period.
		// There are two potential changes per year plus the initial interval.
		local nrows = `maxtime'*2+1
		expand `nrows'

		sort `id'
		bysort `id': gen rownum = _n

		gen double timeagechange = floor((rownum-1)/2) + timetoagechange // Calculate the time from diagnosis at which each age change occurs.
		drop timetoagechange

		gen double timeyearchange = floor((rownum-1)/2) + timetoyearchange // Calculate the time from diagnosis at which each calendar-year change occurs.
		drop timetoyearchange

		gen double endofinterval = timeagechange // Initially define the end of each mortality interval using the age-change time.
		drop timeagechange
		
		replace endofinterval = timeyearchange if mod(rownum, 2) == 0 & agefirst == 1 // If age changes first, use the calendar-year change for alternating intervals where appropriate.
		replace endofinterval = timeyearchange if mod(rownum, 2) == 1 & agefirst == 0 // If the calendar year changes first, use the calendar-year change for the corresponding alternating intervals.
		drop agefirst timeyearchange
		
		bysort `id' (rownum): gen startofinterval = endofinterval[_n-1] // For each individual, the start of an interval is the end of the previous interval.
		replace startofinterval = 0 if missing(startofinterval)
			
		gen `pmage' = floor(`agediag' + startofinterval) // Determine the integer age corresponding to the beginning of each interval.
		replace `pmage' = `pmmaxage' if !missing(`pmage') & `pmage' > `pmmaxage' // Cap age at the maximum age available in the mortality table.
		
		if "`pmyear'" != "" { // If calendar year is being used, determine the calendar year at the beginning of each interval.
			gen `pmyear' = year(floor(`datediag' + startofinterval*365.25+1))
			
			replace `pmyear' = `pmmaxyear' if !missing(`pmyear') & `pmyear' > `pmmaxyear' // Cap calendar year at the maximum year available in the mortality table.
		}

		merge m:1 `pmage' `pmyear' `pmother' using `using', keep(matched master) // Match every simulated interval to the corresponding mortality rate in the population mortality file using age, year, and any additional matching variables.
		
		qui count if _merge == 1 // Count intervals for which no matching population mortality record was found.
		if r(N) > 0 {
			local nunmatched = r(N)
			di as error ///
			"`nunmatched' observations have no matching record in the population mortality file."
			di as error ///
			"This may be caused by values of pmage, pmyear and pmother() existing in the dataset but not in the population mortality file."
			exit 198
		}

		// Calculate the cumulative expected hazard at the end of each interval.
		// Hazard contribution = mortality rate × interval length.
		bysort `id' (rownum): gen double cumhazardend = sum(`pmrate'*(endofinterval - startofinterval))
		drop endofinterval
		
		bysort `id' (rownum): gen cumhazardstart = cumhazardend[_n-1] // Calculate the cumulative hazard at the start of each interval.
		replace cumhazardstart = 0 if missing(cumhazardstart) // The cumulative hazard at the beginning of follow-up is zero.
	
		bysort `id' (rownum): gen Hstar = -ln(runiform()) if _n==1 // Generate one random exponential hazard threshold for each individual.
		
		// Determine whether the simulated event occurs within each interval.
		// An event occurs when the individual's random hazard threshold falls between the cumulative hazards at the start and end of the interval.
		bysort `id' (rownum): gen event = Hstar[1] > cumhazardstart & Hstar[1] <= cumhazardend
		
		// For intervals containing an event, calculate the exact simulated event time by interpolating within the interval assuming a constant mortality rate.
		bysort `id' (rownum): gen double tstar = startofinterval + (Hstar[1]-cumhazardstart)/`pmrate' if event
		drop startofinterval cumhazardstart cumhazardend
		
		// Create an event indicator variable and a variable containing the time at which the event occurs
		// This is the maximum of the event varaible and the tstar variable respectively
		bysort `id': egen d = max(event)
		bysort `id': egen t = max(tstar)

		replace d = 0 if t > `maxtime' // If an individual has an event after the maxtime, this individual is alive at the end of follow-up and therefore their event indicator is set to 0.
		replace t = `maxtime' if d == 0 // If an individual did not have an event, set their event time to the maximum follow-up time (censoring)
		
		bysort `id' (rownum): keep if _n==1
		drop rownum
		
		local time: word 1 of `varlist'
		local death: word 2 of `varlist'
		
		rename t `time'
		rename d `death'
	}
}	
	
	//merge temporary frame to original dataset, adding the time and death variables created by this program
	qui frlink m:1 `id', frame(`longdata')
	qui frget `time' `death', from(`longdata')

end
