capture log close

clear all
set mem 1200m
set matsize 800
set more off

local logpath J:\Geriatrics\Geri\Hospice Project\output\

log using "`logpath'claims_sum_stats.txt", text replace

local datapath J:\Geriatrics\Geri\Hospice Project\Hospice\working\

use "`datapath'all_claims_clean.dta"

describe

**********************************************************
********Demographics sum stats from MBS ******************
**********************************************************

//create means tables of claims demographic variables
local demo female age_at_enr re_white re_black re_asian re_hispanic ///
 re_na re_other re_unknown

 mat mean_demo = J(9,1,.)
 local j=1
 foreach v in `demo' {
 qui sum(`v'), detail
 mat mean_demo[`j',1]=r(mean)
 local j=`j'+1
 }
 mat list mean_demo
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(mean_demo) title("Means of demographics from master beneficiary files") ///
	rtitle("Female" \ "Age at First HS Enrollment" \ "White" \ "Black" \ "Asian" \ "Hispanic" \ ///
	"Native American" \ "Other" \ "Unknown") sdec(2 \ 1 \ 3 \ 3 \ 3 \ 3 \ 3 \ 3 \ 3) replace

**********************************************************
********Hospice claims sum stats          ****************
**********************************************************	
	
//means tables other variables
local hsvars totalcost total_los stay_los disenr count_hs_stays total_650 total_651 total_652 ///
 total_655 total_656 total_657
 
mat mean_hs = J(11,5,.)
 local j=1
 foreach v in `hsvars' {
 qui sum(`v'), detail
 mat mean_hs[`j',1]=r(mean)
 mat mean_hs[`j',2]=r(p50)
  mat mean_hs[`j',3]=r(min)
 mat mean_hs[`j',4]=r(max) 
 mat mean_hs[`j',5]=r(N)
 local j=`j'+1
 }
 
mat list mean_hs
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(mean_hs) title("Means and medians of hospice variables from hospice claims") ///
	ctitle("" , "Mean" , "Median", "Min", "Max", "N") ///
	rtitle("Total Hospice Cost (all stays)" \ "Total LOS (all stays)" \ "LOS First Stay" \ ///
	"Disenrollment" \ "Number of Hospice Stays" \ "Revenue days - Hospice General Services" \ ///
	"Revenue days - Routine Home Care" \ ///
	"Revenue days - Continuous Home Care" \ "Revenue days - Inpatient Hospice Care" \ ///
	"Revenue days - General Inpatient Care under Hospice services (non-Respite)" \ ///
	"Total Number of Procedures in Hospice Physician Services") ///
	sdec(2,0,0,0,0) addtable
	

**********************************************************
******** Inpatient claims sum stats *********************
**********************************************************

gen cost_per_adm=0
replace cost_per_adm=ip_tot_cost/hosp_adm_cnt if hosp_adm_ind==1
sum cost_per_adm

//create means tables of inpatient claims variables
local vars hosp_adm_ind hosp_adm_cnt hosp_adm_days ip_ed_visit_ind ip_ed_visit_cnt ///
icu_stay_ind icu_stay_cnt icu_stay_days hosp_death ip_tot_cost

 mat mean_vars = J(10,5,.)
 local j=1
 foreach v in `vars' {
 qui sum(`v'), detail
 mat mean_vars[`j',1]=r(mean)
 mat mean_vars[`j',2]=r(p50) 
 mat mean_vars[`j',3]=r(min)
 mat mean_vars[`j',4]=r(max) 
 mat mean_vars[`j',5]=r(N) 
 local j=`j'+1
 }
 mat list mean_vars
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(mean_vars) title("Means of hospital use variables from IP claims - overall sample") ///
	ctitle("", "Mean", "Median", "Min", "Max", "N") ///
	rtitle("Hospital admission?" \ "Hosp adm - count" \ "Hosp adm - days" \ "ED visit?" ///
	\ "ED visit count" \ "ICU Stay?" \ ///
	"ICU Stay - count" \ "ICU Stay - days" \ "Hospital death" \ "Total payments IP claims") ///
	sdec(3,0,0,0) addtable


local vars2 hosp_adm_cnt hosp_adm_days ip_ed_visit_ind ip_ed_visit_cnt ///
icu_stay_ind icu_stay_cnt icu_stay_days hosp_death ip_tot_cost cost_per_adm
	
 mat mean_vars2 = J(10,5,.)
 local j=1
 foreach v in `vars2' {
 qui sum(`v') if hosp_adm_ind==1, detail
 mat mean_vars2[`j',1]=r(mean)
 mat mean_vars2[`j',2]=r(p50)
 mat mean_vars2[`j',3]=r(min)
 mat mean_vars2[`j',4]=r(max)
 mat mean_vars2[`j',5]=r(N) 
 local j=`j'+1
 }
 mat list mean_vars2
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(mean_vars2) title("Means of hospital use variables from IP claims - for those with at least 1 hospital admission") ///
	ctitle("", "Mean", "Median", "Min", "Max", "N") ///
	rtitle( "Hosp adm - count" \ "Hosp adm - days" \ "ED visit?" ///
	\ "ED visit count" \ "ICU Stay?" \ "ICU Stay - count" \ "ICU Stay - days" \ ///
	"Hospital death"\ "Total payments IP claims"\ "Mean payment per admission") ///
	sdec(3,0,0,0) addtable	
	
tab ip_ed_visit_cnt, missing 

**********************************************************
******** SNF claims sum stats *********************
**********************************************************

local snf_vars snf_adm_ind snf_adm_cnt snf_adm_days  snf_death snf_cost

 mat snf_vars = J(5,5,.)
 local j=1
 foreach v in `snf_vars' {
 qui sum(`v'), detail
 mat snf_vars[`j',1]=r(mean)
 mat snf_vars[`j',2]=r(p50) 
 mat snf_vars[`j',3]=r(min)
 mat snf_vars[`j',4]=r(max) 
 mat snf_vars[`j',5]=r(N) 
 local j=`j'+1
 }
 mat list snf_vars
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(snf_vars) title("Means of SNF use variables from claims - overall sample") ///
	ctitle("", "Mean", "Median", "Min", "Max", "N") ///
	rtitle("SNF Claim?" \ "SNF Claim - count" \ "SNF Total LOS" \ "Died in SNF?" ///
	\ "Total SNF payments") ///
	sdec(3,0,0,0,0) addtable

local snf_vars2 snf_adm_cnt snf_adm_days  snf_death snf_cost

 mat snf_vars2 = J(4,5,.)
 local j=1
 foreach v in `snf_vars2' {
 qui sum(`v') if snf_adm_ind==1, detail
 mat snf_vars2[`j',1]=r(mean)
 mat snf_vars2[`j',2]=r(p50) 
 mat snf_vars2[`j',3]=r(min)
 mat snf_vars2[`j',4]=r(max) 
 mat snf_vars2[`j',5]=r(N) 
 local j=`j'+1
 }
 mat list snf_vars2
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(snf_vars2) title("Means of SNF use variables from claims - obs with at least 1 snf claim") ///
	ctitle("", "Mean", "Median", "Min", "Max", "N") ///
	rtitle("SNF Claim - count" \ "SNF Total LOS" \ "Died in SNF?" ///
	\ "Total SNF payments") ///
	sdec(3,0,0,0,0) addtable	
	
	
**********************************************************
******** Outpatient claims sum stats *********************
**********************************************************
replace op_visit_ind=1 if(op_visit>0 & op_visit!=.)
tab op_visit_ind, missing

replace op_ed_ind=1 if(op_ed_count>0 & op_ed_count!=.)
tab op_ed_ind, missing


local opvars op_visit_ind op_visit op_cost op_ed_ind op_ed_count

 mat op_vars = J(5,5,.)
 local j=1
 foreach v in `opvars' {
 qui sum(`v'), detail
 mat op_vars[`j',1]=r(mean)
 mat op_vars[`j',2]=r(p50) 
 mat op_vars[`j',3]=r(min)
 mat op_vars[`j',4]=r(max) 
 mat op_vars[`j',5]=r(N) 
 local j=`j'+1
 }
 mat list op_vars
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(op_vars) title("Means of hospital use variables from OP claims - overall sample") ///
	ctitle("", "Mean", "Median", "Min", "Max", "N") ///
	rtitle("OP Claim?" \ "OP Claim - count" \ "OP Claims total payments" \ "ED visit?" ///
	\ "ED visit count") ///
	sdec(3,0,0,0,0) addtable

local opvars2  op_visit op_cost op_ed_ind op_ed_count

 mat op_vars2 = J(4,5,.)
 local j=1
 foreach v in `opvars2' {
 qui sum(`v')  if op_visit_ind==1, detail
 mat op_vars2[`j',1]=r(mean)
 mat op_vars2[`j',2]=r(p50) 
 mat op_vars2[`j',3]=r(min)
 mat op_vars2[`j',4]=r(max) 
 mat op_vars2[`j',5]=r(N) 
 local j=`j'+1
 }
 mat list op_vars2
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(op_vars2) title("Means of hospital use variables from OP claims - those with at least 1 op claim") ///
	ctitle("Payments", "Mean", "Median", "Min", "Max", "N") ///
	rtitle("OP Claim - count" \ "OP Claims total payments" \ "ED visit?" ///
	\ "ED visit count") ///
	sdec(3,0,0,0) addtable
	
**********************************************************
******** ED Use - combined IP and OP claims  *************
**********************************************************	
tab ip_op_ed_cnt, missing

gen byte ip_op_ed_ind=0
replace ip_op_ed_ind=1 if ip_op_ed_cnt>0 & ip_op_ed_cnt!=.
tab ip_op_ed_ind, missing

mat ed = J(6,5,.)
//first two rows, whole sample
sum ip_op_ed_ind, detail
 mat  ed[2,1]=r(mean)
 mat  ed[2,2]=r(p50) 
 mat  ed[2,3]=r(min)
 mat  ed[2,4]=r(max) 
 mat  ed[2,5]=r(N)

sum ip_op_ed_cnt, detail
 mat  ed[3,1]=r(mean)
 mat  ed[3,2]=r(p50) 
 mat  ed[3,3]=r(min)
 mat  ed[3,4]=r(max) 
 mat  ed[3,5]=r(N)
 
//rows 3 and 4, obs who disenrolled
sum ip_op_ed_ind if disenr==1, detail
 mat  ed[5,1]=r(mean)
 mat  ed[5,2]=r(p50) 
 mat  ed[5,3]=r(min)
 mat  ed[5,4]=r(max) 
 mat  ed[5,5]=r(N) 

sum ip_op_ed_cnt if disenr==1, detail
 mat  ed[6,1]=r(mean)
 mat  ed[6,2]=r(p50) 
 mat  ed[6,3]=r(min)
 mat  ed[6,4]=r(max) 
 mat  ed[6,5]=r(N) 

mat list ed

 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(ed) title("ED Use - across IP and OP claims") ///
	ctitle("","Mean", "Median", "Min", "Max", "N") ///
	rtitle("Full sample" \ "Any ED use?" \ "Count of ED visits" \ ///
		"Obs who disenrolled from hospice" \ "Any ED use?" \ "Count of ED visits") ///
	sdec(3,0,0,0,0) addtable
 
**********************************************************
******** DME, HH and Carrier claims payments *************
**********************************************************	

replace dme_cost=0 if dme_cost==.
replace hha_cost=0 if hha_cost==.
replace carr_cost=0 if carr_cost==.

local otherclms dme_cost hha_cost carr_cost
mat other_vars = J(3,5,.)
 local j=1
 foreach v in `otherclms' {
 qui sum(`v') , detail
 mat other_vars[`j',1]=r(mean)
 mat other_vars[`j',2]=r(p50) 
 mat other_vars[`j',3]=r(min)
 mat other_vars[`j',4]=r(max) 
 mat other_vars[`j',5]=r(N) 
 local j=`j'+1
 }
 mat list other_vars
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(other_vars) title("Means of claims payments from DME, HHA and Carrier claims - full sample") ///
	ctitle("Payments", "Mean", "Median", "Min", "Max", "N") ///
	rtitle("Total DME" \ "Total HHA" \ "Total Carrier") ///
	sdec(0,0,0,0,0) addtable

local otherclms dme_cost hha_cost carr_cost
mat other_vars = J(3,5,.)
 local j=1
 foreach v in `otherclms' {
 qui sum(`v') if disenr==1, detail
 mat other_vars[`j',1]=r(mean)
 mat other_vars[`j',2]=r(p50) 
 mat other_vars[`j',3]=r(min)
 mat other_vars[`j',4]=r(max) 
 mat other_vars[`j',5]=r(N) 
 local j=`j'+1
 }
 mat list other_vars
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\claims_sum_stats", ///
	statmat(other_vars) title("Means of claims payments from DME, HHA and Carrier claims - obs who disenroll") ///
	ctitle("", "Mean", "Median", "Min", "Max", "N") ///
	rtitle("Total DME" \ "Total HHA" \ "Total Carrier") ///
	sdec(0,0,0,0,0) addtable
	
log close



