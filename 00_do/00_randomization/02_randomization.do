/*******************************************************************************

Project Name		: 	Project Nourish
Purpose				:	2nd round data collection - village profile preparation				
Author				:	Nicholus Tint Zaw
Date				: 	9/19/2022
Modified by			:


*******************************************************************************/

********************************************************************************
** Directory Settings **
********************************************************************************

do "$do/00_dir_setting.do"

********************************************************************************
* IP villages *
********************************************************************************

**  feasibility first wave **
import excel 	using "$sample/01_village_profile/Updated_PN_Coverage_List_2022_accessiblityinfo,emergencyresponse_20221026.xlsx", ///
				sheet("LIFT") cellrange(A2:AH506) firstrow case(lower) clear 

* drop un-necessary var
drop lift liftremark ofhhtotal ofpoptotal feasibility123 inpersondatacollectionyn phonedatacollectionyn

* rename variable 
rename ad 							 vill_accessibility
rename projectimplementationstatusc  vill_proj_implement

replace vill_proj_implement = "" if vill_proj_implement == "-"
destring vill_proj_implement, replace 

tab vill_proj_implement, m 

egen u5_pop = rowtotal(pop25years pop2years)
replace u5_pop = .m if mi(pop2years) & mi(pop25years)
order u5_pop, after(pop25years)
tab u5_pop, m 


rename emergencyresposeyn emergency_vill

* drop if there is no project implementation or missing ingo 3 villages *

keep if vill_proj_implement != 0 & !mi(vill_proj_implement)

tab vill_proj_implement, m 

tab vill_accessibility, m 

gen stratum = (vill_accessibility != "3. neither in person nor phone interviews")
tab stratum, m 

********************************************************************************
* SAMPLING - stratum - 2: Limited Accessible villages *
********************************************************************************

preserve

keep if stratum == 0 
replace stratum = 2 if stratum == 0
tab emergency_vill, m // 59 villages 

set seed 234

gen rnd_num = runiform()


** setting priority cluster and reserve cluster 
sort organization rnd_num
bysort organization: gen rdm_order = _n 

bysort organization: gen cluster_cat = (rdm_order <= round(_N/2, 1))
lab def cluster_cat 1"priority cluster" 0"reserved cluster"
lab val cluster_cat cluster_cat
tab cluster_cat organization, m

drop rnd_num rdm_order

bysort organization cluster_cat: gen cluster_order = _n 

order cluster_cat cluster_order, after(organization)
lab var cluster_cat 	"Cluster category"
lab var cluster_order 	"Cluster selection order (random assignment)"


sum u5_pop, d // average U2 pop: 16 per village

gen vill_samplesize = 12 if emergency_vill == "Yes"
replace vill_samplesize = 20 if emergency_vill == "No"
tab vill_samplesize, m 

gen sample_check = (u5_pop >= vill_samplesize)
lab def sample_check 1"have enough U5 sample size" 0"not enough U5 sample size"
lab val sample_check sample_check
tab sample_check, m 


gsort organization -cluster_cat


replace fieldnamevillagetracteho = "Lay Wal" if villagecode == "KRN-001-VIL-225"

export excel using "$result/01_sample_village_list.xlsx", ///
					sheet("stratum_2_emergency", replace) firstrow(varlabels) 


//export excel using "$result/01_sample_village_list.xlsx" if emergency_vill == "No", ///
//					sheet("stratum_2_no_emergency", replace) firstro(variable) 


* save as tempfile 
tempfile stratum2 
save `stratum2', replace 

restore 



********************************************************************************
* SAMPLING - stratum - 1: Accessible villages *
********************************************************************************

di 5 * 59 // sample size from stratum 2 
di 788 - (5 * 59) // required sample for stratum 1 
di 15 * 34


preserve 
keep if stratum == 1

sum u5_pop, d // average U2 pop: 81 per village

// 34 clusters and 15 HH per cluster 

set seed 234

samplepps pps_cluster, size(population) n(34) withrepl // add one additional cluster to save sample size from rounding work

tab pps_cluster, m


** setting priority cluster and reserve cluster 
gen cluster_cat = (pps_cluster > 0)
lab def cluster_cat 1"priority cluster" 0"reserved cluster"
lab val cluster_cat cluster_cat
tab cluster_cat organization, m

set seed 234
gen rnd_num = runiform() if cluster_cat == 0

sort organization cluster_cat rnd_num
bysort organization cluster_cat: gen cluster_order = _n if cluster_cat == 0

drop rnd_num 

order cluster_cat cluster_order, after(organization)
lab var cluster_cat 	"Cluster category"
lab var cluster_order 	"Cluster selection order (random assignment)"

sort organization cluster_cat cluster_order

// keep if pps_cluster != 0 

rename pps_cluster num_cluster
gen vill_samplesize = (num_cluster * 10)

gen sample_check = (u5_pop >= vill_samplesize)
lab def sample_check 1"have enough U5 sample size" 0"not enough U5 sample size"
lab val sample_check sample_check
tab sample_check, m 

gsort organization -cluster_cat

replace fieldnamevillagetracteho = "Wal Ta Ran" if villagecode == "KRN-002-VIL-305"


export excel using "$result/01_sample_village_list.xlsx", sheet("stratum_1", replace) firstrow(varlabels) 

* save as tempfile 
tempfile stratum1 
save `stratum1', replace 

restore 

clear 

** export for preloaded dataset **
use `stratum1', clear 

append using `stratum2'

* keep only required variables
//keep township_name townshippcode fieldnamevillagetracteho villagenameeho stratum num_cluster vill_samplesize sample_check organization cluster_cat
replace stratum = 2 if stratum == 0

* generate pseudo code
preserve
keep townshippcode fieldnamevillagetracteho
bysort townshippcode fieldnamevillagetracteho: keep if _n == 1

gen vt_sir_num = _n + 1000

tempfile vt_sir_num
save `vt_sir_num', replace 

restore 

merge m:1 townshippcode fieldnamevillagetracteho using `vt_sir_num', keepusing(vt_sir_num)
drop _merge 

gen vill_sir_num = _n + 2000


tostring cluster_cat, gen(cluster_cat_str)
tostring vt_sir_num, gen(vt_sir_num_str)

gen vt_cluster_cat = cluster_cat_str + "_" + vt_sir_num_str 

drop cluster_cat_str vt_sir_num_str

decode cluster_cat, gen(cluster_cat_str) 


order organization  township_name townshippcode fieldnamevillagetracteho vt_sir_num cluster_cat cluster_cat_str villagenameeho vill_sir_num

export delimited using "$result/pn_2_samplelist.csv", nolabel replace  
save "$dta/pn_2_samplelist.dta", replace 

export excel using "$result/pn_2_samplelist.xlsx", sheet("pn_2_samplelist") firstrow(variable)  nolabel replace 


			