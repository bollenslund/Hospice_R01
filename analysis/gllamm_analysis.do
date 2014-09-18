/*
Looking at impact of five best practices on patient level outcomes
Best practices:
1. MD on call
2. Pain monitored at least every few days (vs less)
3. Symptoms monitored at least every few days (vs less)
4. Goals of care discussed at all 3 time points
5. Family preferences discussed at all 3 time points

Patient level outcomes (all binary):
1. Hospital admission
2. ED use (from IP or OP claims)
3. ICU use

Dataset set up in stata_data_setup.do 
*/

capture log close
clear all
set more off

local datapath J:\Geriatrics\Geri\Hospice Project\Hospice\working
local logpath J:\Geriatrics\Geri\Hospice Project\output

log using "`logpath'\meglm_stata_work-LOG-2.txt", text replace

cd "`datapath'"

use ltd_vars_for_analysis1_clean.dta, replace
************************************************************

//check correlation, from Degenholz, ICC > 0.05 then correlation needs to be accounted for
loneway hosp_adm_ind pos1 //by hospice
loneway hosp_adm_ind region1 //by region
loneway hosp_adm_ind county_state //by county

local xvars3 female age_70_74 age_75_79 age_80_84 age_gt84 ///
 re_white cancer cc_grp_ind2 cc_grp_ind3 ownership_ind2 ///
 sizecat_ind2 sizecat_ind3 sizecat_ind4
	 
local regvars urban_cd hospital_beds_per_res per_cap_inc_2009

**********************************************************************
//variable check before run gllamm model, drop observations where missing
local vars hosp_adm_ind pos1 region1 smd_on_call pan_efd symp_efd  ///
	poc_gocall3 fp_all3 `xvars3' `regvars'
	
foreach v in `vars'{
sum `v', detail
drop if `v'==.
}

//run gllamm as for loop for the 5 exposure variables
foreach expos in smd_on_call pan_efd symp_efd  poc_gocall3 fp_all3{
	gllamm hosp_adm_ind `expos' `xvars3' `regvars', ///
		i(pos1 region1) fam(binom) link(logit) adapt
	estimates save gllamm_est_`expos', replace
}
	
*********************************************************
log close
