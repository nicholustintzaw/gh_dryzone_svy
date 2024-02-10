/*******************************************************************************

Project Name		: 	Gathering House - Dryzone Humanitarian Survey
Purpose				:	Village Tract preparation				
Author				:	Nicholus Tint Zaw
Date				: 	2/09/2024
Modified by			:


*******************************************************************************/


	********************************************************************************
	** Directory Settings **
	********************************************************************************

	do "00_dir_setting.do"
	
	********************************************************************************
	* Population Data  *
	********************************************************************************
	import excel 	using "$raw/Assessment Coverage.xlsx", ///
					sheet("vt_pop") firstrow case(lower) cellrange(A2) clear 

	drop a 
	rename b zone 
	rename c region 
	rename d township 
	rename e village_tract 
	rename f village_num
	
	gen est_hh = round(total / 5, 0.1)
	
	* township level info 
	bysort region township: gen vt_tot = _N
	bysort region township: egen village_tot = total(village_num)
	bysort region township: egen pop_tot = total(total)
	
	gen vt_all_tot = _N
	egen village_all_tot = total(village_num)
	egen pop_all_tot = total(total)	
	
	gen vt_prop = round(vt_tot / vt_all_tot, 0.0001)
	gen village_prop = round(village_tot / village_all_tot, 0.0001)
	gen pop_prop = round(pop_tot / pop_all_tot, 0.0001) 

	
	
	* sample size 
	local samplesize = 634
	sum pop_all_tot 
	local totpop = `r(sum)'
	
	

	// Sort the data by population size in descending order
	sort region township total 

	// Sample villages with probability proportional to size
	
	gsample 20 [w = total], strata(zone)
	
	* end of dofile 
