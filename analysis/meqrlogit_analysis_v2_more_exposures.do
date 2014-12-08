/*
Looking at impact of five best practices on patient level outcomes
Best practices:
1. MD on call** (done in the meqrlogit_analysis.do file, not here
2. Pain monitored at least every few days (vs less)
3. Symptoms monitored at least every few days (vs less)
4. Goals of care discussed at all 3 time points
5. Family preferences discussed at all 3 time points

Patient level outcomes (all binary):
1. Hospital admission
2. ED use (from IP or OP claims)
3. ICU use

This code builds up the model from just intercept to adding in random effects,
then adding in covariates for the impact of exposure to best practices on hospital admission

Nothing is run with ED or ICU use at this time

Dataset exported from SAS at the end of the table1.sas code
and then cleaned in the stata_data_setup.do file

Sample here is not missing in any of the 4 exposure variables
This makes it different than the sample run for just if smd_on_call is present

*/

capture log close
clear all
set more off

local datapath J:\Geriatrics\Geri\Hospice Project\Hospice\working
local logpath J:\Geriatrics\Geri\Hospice Project\output

log using "`logpath'\meqrlogit_stata_LOG_v2_more_expos.txt", text replace

cd "`datapath'"

use ltd_vars_for_analysis1_clean.dta, replace
*****************************************************************

la var age_70_74 "Age 70-74"
la var age_75_79 "Age 75-79"
la var age_80_84 "Age 80-84"
la var age_gt84 "Age 85+"
la var smd_on_call "MD on call"

//define variables
local xvars3 female age_70_74 age_75_79 age_80_84 age_gt84 ///
 re_white cancer cc_grp_ind2 cc_grp_ind3 ownership_ind2 ///
 sizecat_ind2 sizecat_ind3 sizecat_ind4
	 
local pat_vars female age_70_74 age_75_79 age_80_84 age_gt84 ///
 re_white cancer cc_grp_ind2 cc_grp_ind3 
 
local hosp_vars ownership_ind2 ///
 sizecat_ind2 sizecat_ind3 sizecat_ind4
	 
local regvars urban_cd hospital_beds_per_res per_cap_inc_2009

//drop obs where any of the variables are missing
foreach v in `pat_vars' `hosp_vars' `regvars' pan_efd symp_efd  poc_gocall3 fp_all3 {
        drop if `v'==.
        }

//base model - just coefficient and patient level random error
glm hosp_adm_ind, family(binomial) link(logit)

*******************************************************
//add random intercept at hospice level
meqrlogit hosp_adm_ind || pos1:

*******************************************************
//add random intercept at region level
meqrlogit hosp_adm_ind || region1:

*******************************************************
//now add random intercept at the hospice and region levels
meqrlogit hosp_adm_ind || region1: || pos1:

******************************************************* 
//add individual level (level 1) independent variables

local pat_vars female age_70_74 age_75_79 age_80_84 age_gt84 ///
 re_white cancer cc_grp_ind2 cc_grp_ind3 
 
meqrlogit hosp_adm_ind `pat_vars' || region1: || pos1:

*******************************************************
//add hospice level (level 2) independent variables - includes exposure variable
//add individual level (level 1) independent variables

foreach expos in /*smd_on_call*/ pan_efd symp_efd  poc_gocall3 fp_all3{
//add hospice level (level 2) independent variables - includes exposure variable
//add individual level (level 1) independent variables
meqrlogit hosp_adm_ind `pat_vars' `expos' `hosp_vars' || region1: || pos1:

************************************************************
//full model, adding region level independent variables
meqrlogit hosp_adm_ind  `pat_vars' `expos' `hosp_vars' `regvars' || ///
	region1: || pos1:
estimates save meqrlogit_est_`expos', replace

}

*****************************************************************
log close
