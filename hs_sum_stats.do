capture log close

clear all
set mem 1g
set matsize 800
set more off

log using "J:\Geriatrics\Geri\Hospice Project\output\hs_claims_sum_stats.txt", text replace

cd "J:\Geriatrics\Geri\Hospice Project\Hospice\working"

use hs_stays_cleaned.dta

describe

/*
la def discharge 1 "Discharged to home/self care" 30 "Still patient" 40 "Expired at home" ///
 41 "Expired in a medical facility" 42 "Expired - Location unknown" ///
 43 " Transferred to a federal hospital" 50 "Hospice - home" ///
 51 "Hospice - medical facility" 63 "Transferred to a long term care hospitals" ///
 70 "Transferred to another type of health care institution"
la val discharge discharge 

tabout count_hs_stays using "J:\Geriatrics\Geri\Hospice Project\output\hs_freq_tab.csv", ///
	cells(freq col) f(0c 2p) oneway replace
tabout discharge using "J:\Geriatrics\Geri\Hospice Project\output\hs_freq_tab.csv", ///
	cells(freq col) f(0c 2p) oneway append
tabout discharge_i using "J:\Geriatrics\Geri\Hospice Project\output\hs_freq_tab.csv", ///
	cells(freq col) f(0c 2p) oneway append
tabout provider_i using "J:\Geriatrics\Geri\Hospice Project\output\hs_freq_tab.csv", ///
	cells(freq col) f(0c 2p) oneway append
*/
replace age_at_enr = age_at_enr/365.25

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
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\hs_sum_stats", ///
	statmat(mean_demo) title("Means of demographics from hospice claims") ///
	rtitle("Female" \ "Age at First HS Enrollment" \ "White" \ "Black" \ "Asian" \ "Hispanic" \ ///
	"Native American" \ "Other" \ "Unknown") sdec(2 \ 1 \ 3 \ 3 \ 3 \ 3 \ 3 \ 3 \ 3) replace
 
//means tables other variables
local hsvars totalcost total_los stay_los disenr count_hs_stays total_650 total_651 total_652 ///
 total_655 total_656 total_657
 
mat mean_hs = J(11,2,.)
 local j=1
 foreach v in `hsvars' {
 qui sum(`v'), detail
 mat mean_hs[`j',1]=r(mean)
 mat mean_hs[`j',2]=r(p50)
 local j=`j'+1
 }
 
mat list mean_hs
 frmttable using "J:\Geriatrics\Geri\Hospice Project\output\hs_sum_stats", ///
	statmat(mean_hs) title("Means and medians of hospice variables from hospice claims") ///
	ctitle("" , "Mean" , "Median") ///
	rtitle("Total Hospice Cost (all stays)" \ "Total LOS (all stays)" \ "LOS First Stay" \ ///
	"Disenrollment" \ "Number of Hospice Stays" \ "Revenue days - Hospice General Services" \ ///
	"Revenue days - Routine Home Care" \ ///
	"Revenue days - Continuous Home Care" \ "Revenue days - Inpatient Hospice Care" \ ///
	"Revenue days - General Inpatient Care under Hospice services (non-Respite)" \ ///
	"Total Number of Procedures in Hospice Physician Services") ///
	sdec(0,0 \ 2,0 \ 2,0 \ 2,0 \ 2,0 \  2,0 \  2,0 \  2,0 \  2,0 \  2,0 \  2,0) addtable
	
log close



