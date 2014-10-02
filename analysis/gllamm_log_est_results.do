capture log close
clear all
set more off

local logpath J:\Geriatrics\Geri\Hospice Project\output

log using "`logpath'\glamm_estimates_for_comparison.txt", text replace

local datapath J:\Geriatrics\Geri\Hospice Project\Hospice\working

cd "`datapath'"

use ltd_vars_for_analysis1_clean.dta, replace
***************************************************
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

//run gllamm from estimates, 0 iterations to get log of estimation results
foreach expos in smd_on_call pan_efd symp_efd  poc_gocall3 fp_all3{
	di "Estimates from gllamm hosp_adm_ind `expos' xvars, i(pos1 region1) fam(binom) link(logit) adapt"
	estimates use gllamm_est_`expos'
	gllamm
	
}

***************************************************
log close
