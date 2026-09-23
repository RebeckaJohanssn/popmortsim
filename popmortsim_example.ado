program define popmortsim_example
	version 16.0
	syntax [, EGNUMBER(integer 1)]
  
	if `egnumber' == 0 {
		
		display ". set seed 27889"
		display ". set obs 1000"
		di ". gen agediag = runiform(70,90)"
		di ". gen datediag = runiformint(mdy(1,1,1985), mdy(12,31,1990))"
		di ". format %d datediag"
		di ". gen sex = runiformint(1,2)"  
		di ". gen dep = runiformint(1,5)" 
		
		set seed 27889
		set obs 1000
		gen agediag = runiform(70,90)
		gen datediag = runiformint(mdy(1,1,1985), mdy(12,31,1990))
		format %d datediag
		gen sex = runiformint(1,2)
		gen dep = runiformint(1,5)
		
	}
	
	else if `egnumber' == 1 {
		display ///
			". popmortsim time dead using https://pclambert.net/data/popmort.dta, ///" _newline ///
"agediag(agediag) datediag(datediag) pmother(sex)"

popmortsim time dead using https://pclambert.net/data/popmort.dta, ///
	agediag(agediag) datediag(datediag) pmother(sex)
	}
	
	
	else if `egnumber' == 2 {
		display ///
			". popmortsim time2 dead2 using https://pclambert.net/data/popmort.dta, ///" _newline ///
"agediag(agediag) datediag(datediag) pmother(sex) maxtime(20)"

popmortsim time2 dead2 using https://pclambert.net/data/popmort.dta, ///
	agediag(agediag) datediag(datediag) pmother(sex) maxtime(20)
	}
	
	
	else if `egnumber' == 3 {
		display ///
			". popmortsim time3 dead3 using https://pclambert.net/data/popmort_NW.dta, ///" _newline ///
"agediag(agediag) datediag(datediag) pmage(age) pmyear(year) pmother(sex dep)"

popmortsim time3 dead3 using https://pclambert.net/data/popmort_NW.dta, ///
	agediag(agediag) datediag(datediag) pmage(age) pmyear(year) pmother(sex dep)
	}
end
