capture log close

clear all
set mem 1g
set matsize 800
set more off

log using "J:\Geriatrics\Geri\Hospice Project\output\ip_claims_sum_stats.txt", text replace

cd "J:\Geriatrics\Geri\Hospice Project\Hospice\working"

use ip_sample.dta

describe

gen cost_per_adm=0
replace cost_per_adm=ip_tot_cost/hosp_adm_cnt if hosp_adm_ind==1
sum cost_per_adm

//create means tables of claims variables
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
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\ip_sum_stats", ///
	statmat(mean_vars) title("Means of hospital use variables from IP claims - overall sample") ///
	ctitle("", "Mean", "Median", "Min", "Max", "N") ///
	rtitle("Hospital admission?" \ "Hosp adm - count" \ "Hosp adm - days" \ "ED visit?" ///
	\ "ED visit count" \ "ICU Stay?" \ ///
	"ICU Stay - count" \ "ICU Stay - days" \ "Hospital death" \ "Total cost IP claims") ///
	sdec(3,0,0,0) replace


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
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\ip_sum_stats", ///
	statmat(mean_vars2) title("Means of hospital use variables from IP claims - for those with at least 1 hospital admission") ///
	ctitle("", "Mean", "Median", "Min", "Max", "N") ///
	rtitle( "Hosp adm - count" \ "Hosp adm - days" \ "ED visit?" ///
	\ "ED visit count" \ "ICU Stay?" \ "ICU Stay - count" \ "ICU Stay - days" \ ///
	"Hospital death"\ "Total cost IP claims"\ "Mean cost per admission") ///
	sdec(3,0,0,0) addtable	
	
tab ip_ed_visit_cnt, missing 

	
log close



