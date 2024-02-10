/*******************************************************************************

Project Name		: 	Gathering House - Dryzone Humanitarian Survey
Purpose				:	measure the HH living condition, food security and humanitoarin need				
Author				:	Nicholus Tint Zaw
Date				: 	2/09/2024
Modified by			:


*******************************************************************************/

** Settings for stata ** 
clear all
label drop _all

set more off
set mem 100m
set matsize 11000
set maxvar 32767


********************************************************************************
***SET ROOT DIRECTORY HERE AND ONLY HERE***

// create a local to identify current user
local user = c(username)
di "`user'"

// Set root directory depending on current user
if "`user'" == "Nicholus Tint Zaw" {
    * Nicholus Directory
	
	global dir		"C:\Users\Nicholus Tint Zaw\Dropbox\GH_Dryzone_Assessment\00_workflow"
	global github	"C:\Users\Nicholus Tint Zaw\Documents\GitHub\gh_dryzone_svy"
	
}


else if "`user'" == "" {
    * NCL
	global dir			""
	global github		""
	
}

// Adam, please update your machine directory 
else if "`user'" == "XX" {
    * Adam Directory

}

// CPI team, please update your machine directory. 
// pls replicate below `else if' statement based on number of user going to use this analysis dofiles  
else if "`user'" == "XX" {
    * CPI team Directory
	
}


	* dofile directory 
	// Village survey
	global 	do_dir			"$github/00_do"
	global	do_import		"$do_dir/01_Import"
	global	do_hfc			"$do_dir/02_HFC"
	global	do_clean		"$do_dir/03_Cleaning"
	global	do_construct	"$do_dir/04_Construct"
	global	do_analysis		"$do_dir/05_Analysis"

	* data directory  
	global  raw	 			"$dir/01_raw"
	global 	dta				"$dir/02_dta"
	global 	out				"$dir/03_output"
	global 	result 			"$dir/04_result"
	global 	plots			"$dir/04_result/Figures"

	****************************************************************************
	****************************************************************************

