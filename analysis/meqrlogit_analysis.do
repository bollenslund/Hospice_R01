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

Dataset exported from SAS at the end of the table1.sas code
and then cleaned in the beginning of the meglm_analysis.do file
*/

capture log close
clear all
set more off

local datapath J:\Geriatrics\Geri\Hospice Project\Hospice\working
local logpath J:\Geriatrics\Geri\Hospice Project\output

log using "`logpath'\meqrlogit_stata_LOG.txt", text replace

cd "`datapath'"

use ltd_vars_for_analysis1_clean.dta, replace
*****************************************************************

//define variables
local xvars3 female age_70_74 age_75_79 age_80_84 age_gt84 ///
 re_white cancer cc_grp_ind2 cc_grp_ind3 ownership_ind2 ///
 sizecat_ind2 sizecat_ind3 sizecat_ind4
	 
local pat_vars female age_70_74 age_75_79 age_80_84 age_gt84 ///
 re_white cancer cc_grp_ind2 cc_grp_ind3 
 
local hosp_vars ownership_ind2 ///
 sizecat_ind2 sizecat_ind3 sizecat_ind4
	 
local regvars urban_cd hospital_beds_per_res per_cap_inc_2009

//base model - just coefficient and patient level random error
meqrlogit hosp_adm_ind

//now add random intercept at the hospice and region levels
meqrlogit hosp_adm_ind || region1: || pos1:

//add individual level independent variables
meqrlogit hosp_adm_ind `pat_vars' || region1: || pos1:



meqrlogit hosp_adm_ind smd_on_call `xvars3' `regvars' || ///
	region1: || pos1: 
estimates save meqrlogit_est_smd_on_call, replace


*****************************************************************
//run meqrlogit as for loop for the remaining 4 exposure variables
//hospices within regions, covariance structure=independent (default)
foreach expos in /*smd_on_call*/ pan_efd symp_efd  poc_gocall3 fp_all3{
	meqrlogit hosp_adm_ind `expos' `xvars3' `regvars' || ///
		region1: || pos1: //, cov(ex)
	estimates save meqrlogit_est_`expos', replace
}

*****************************************************************
log close
