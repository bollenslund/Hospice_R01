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
/*sas code trying to replicate
proc genmod data=table5 descending;
class pos1 ip_ed_visit_ind (ref = '0') &var (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = &var female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald ;
repeated subject=pos1/type=exch;
***where &var is each of the best practices
***class = pos1 - hospice identifier - clustered in repeated subject option
type3 = type 3 analysis, provides likelihood ratio tests for each parameter
wald = wald confidence intervals
*** /type=exch specifies the correlation matrix structure, exch=exchangeable
Per Melissa, it was the best fit on similar analysis before so we used it
for this initial analysis*/

/*local xvars2 i.female ib1.agecat2 i.re_white i.cancer ib0.cc_grp ///
	ib2.ownership1 ib1.sizecat ib3.region1

glm hosp_adm_ind smd_on_call `xvars2' , family(binomial) link(logit) vce(cluster pos1) 
glm, eform*/

//can't run this b/c matsize too small! can't set it > 800 in stata IC
//xtset pos1
//xtgee hosp_adm_ind smd_on_call `xvars2',family(binomial) link(probit) corr(exchangeable) eform

//check correlation, from Degenholz, ICC > 0.05 then correlation needs to be accounted for
loneway hosp_adm_ind pos1 //by hospice
loneway hosp_adm_ind region1 //by region
loneway hosp_adm_ind county_state //by county

local xvars3 female age_70_74 age_75_79 age_80_84 age_gt84 ///
 re_white cancer cc_grp_ind2 cc_grp_ind3 ownership_ind2 ///
 sizecat_ind2 sizecat_ind3 sizecat_ind4
	 
local regvars urban_cd hospital_beds_per_res per_cap_inc_2009

/* does not converge, flat or discontinuous region encountered message
will converge with no covariates and random effect at the region level only (not hospice)*/
meglm ed_visit_ind /*smd_on_call `xvars3' `regvars'*/ || region1: /*|| pos1:*/ , ///
family(binomial) link(logit) evaltype(gf0)

estimates save meglm_est, replace
	
*********************************************************
log close
