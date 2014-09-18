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

This code cleans the data file from SAS and saves a version to be
used for the remaining analysis

Runs tabulations, summaries of variables to see what they look like
*/

capture log close
clear all
set more off

local datapath J:\Geriatrics\Geri\Hospice Project\Hospice\working
local logpath J:\Geriatrics\Geri\Hospice Project\output

log using "`logpath'\stata_set_up-LOG.txt", text replace

cd "`datapath'"
use ltd_vars_for_analysis1.dta

compress

*********************************************************
local outcomes hosp_adm_ind ed_visit_ind icu_stay_ind
foreach v in `outcomes'{
tab `v', missing
}

local xvars female agecat re_white cancer cc_grp ownership1 sizecat region1
foreach v in `xvars'{
tab `v', missing
}

local bpvars smd_on_call pan_efd symp_efd  poc_gocall3 fp_all3
foreach v in `bpvars'{
tab `v', missing
}

local region county_state beds_2009 nursing_beds_2009 per_cap_inc_2009 ///
census_pop_2010 urban_cd
foreach v in  `region'{
sum `v', detail
}

//per email 8/29 variables to control for are hospital beds/1000 residents
//urban indicator and per captia income
la var urban_cd "Urban county indicator"
la def urban_cd 1 "Urban" 0 "Rural"
la val urban_cd urban_cd
tab urban_cd, missing

gen hospital_beds_per_res = beds_2009 / census_pop_2010 * 1000
sum hospital_beds_per_res, detail
la var hospital_beds_per_res "Hospital beds per 1000 residents"

replace per_cap_inc_2009 = per_cap_inc_2009 / 1000
la var per_cap_inc_2009 "Per capita income (scaled by $1000)"
sum per_cap_inc_2009, detail

//recode age categorical variable since it imported as text
gen agecat2 = .
forvalues i = 1/5{
replace agecat2 = `i' if agecat=="     `i'"
}

la var agecat2 "Age at enrollment, categorical"
la def agecat2 1 "Age 65-69" 2 "Age 70-74" 3 "Age 75-79" 4 "Age 80-84" 5 "Age 85+"
la val agecat2 agecat2
tab agecat2, missing

//addtional variable labels
la var female "Female"
la var re_white "White, non-Hispanic"
la var cancer "Primary diagnosis = cancer"
la var cc_grp "Count of chronic conditions, categorical"
la def cc_grp 0 "None" 1 "One" 2 "Two+"
la val cc_grp cc_grp
la var ownership1 "Hospice ownership"
la def ownership1 1"Nonprofit" 2"For profit"
la val ownership1 ownership1
la var sizecat "Hospice size, no. beds, cat."
la def sizecat 1 "<250" 2 "250-599" 3 "600-1299" 4 "1300+"
la val sizecat sizecat
la var region1 "Hospice region"
la def region1 1 "New England/ Mid-Atlantic" 2 "E/W North Central" ///
	3 "South Atlantic" 4 "E/W South Central" 5 "Mountain/Pacific"
la val region1 region1
************************************************************
//create indicator variables for categorical variables
tab agecat2, gen(age_ind) //base for models <70
rename age_ind1 age_65_69
rename age_ind2 age_70_74
rename age_ind3 age_75_79
rename age_ind4 age_80_84
rename age_ind5 age_gt84

tab cc_grp, gen(cc_grp_ind) //base for models = 0
la var cc_grp_ind1 "No chronic conditions"
la var cc_grp_ind2 "1 Chronic condition"
la var cc_grp_ind3 "2+ Chronic conditions"

tab ownership1, gen(ownership_ind) //base for models = 
la var ownership_ind1 "Nonprofit hospice"
la var ownership_ind2 "For profit hospice"

tab sizecat, gen(sizecat_ind) //base for models = 
la var sizecat_ind1 "Hospice size <250 beds"
la var sizecat_ind2 "Hospice size 250-599 beds"
la var sizecat_ind3 "Hospice size 600-1299 beds"
la var sizecat_ind4 "Hospice size 1300+ beds"

************************************************************
//save this dataset now that its been compressed, etc.
save ltd_vars_for_analysis1_clean.dta, replace

************************************************************
//replicate means comparison across outcome categories
foreach v in `bpvars' `xvars'{
tab `v' hosp_adm_ind, missing
tab `v' ip_ed_visit_ind, missing
tab `v' icu_stay_ind, missing
}

loneway hosp_adm_ind pos1 //by hospice
loneway hosp_adm_ind region1 //by region
loneway hosp_adm_ind county_state //by county

*********************************************************
log close
