/*
Looking at impact of five best practices on patient level outcomes
Best practices:
1. MD on call**
2. Pain monitored at least every few days (vs less)
3. Symptoms monitored at least every few days (vs less)
4. Goals of care discussed at all 3 time points
5. Family preferences discussed at all 3 time points

Patient level outcomes (all binary):
1. Hospital admission
2. ED use (from IP or OP claims)
3. ICU use

This code builds up the model from just intercept to adding in random effects,
then adding in covariates for the impact of MD on call on hospital admission

Then runs the full model looking at impact of each of the 5 best practices
on hospital admission (nothing is run with ED or ICU use at this time)

Dataset exported from SAS at the end of the table1.sas code
and then cleaned in the stata_data_setup.do file

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
foreach v in `pat_vars' smd_on_call `hosp_vars' `regvars' {
        drop if `v'==.
        }

//base model - just coefficient and patient level random error
glm hosp_adm_ind, family(binomial) link(logit)

//begin to manually create a matrix of the coef, se, ci's
mat est1=J(1,4,.)
mat e_1=e(b)
mat est1[1,1]=e_1[1,1] //coef

mat est1[1,2]=_se[_cons] //se

mat est1[1,3] = est1[1,1]-invttail(e(N)-1,0.05/2)*est1[1,2] //ci
mat est1[1,4] = est1[1,1]+invttail(e(N)-1,0.05/2)*est1[1,2] //ci

mat list est1
mat rownames est1="Patient intercept"
mat dcols = (0,0,0,1)
frmttable, statmat(est1) doubles(dcols) substat(2) sdec(3) store(est1_1)

//add n, ll
mat esta=J(2,1,.)
mat esta[1,1]=e(N)
mat esta[2,1]=e(ll)
mat rownames esta="N" "log likelihood"

frmttable, sdec(0) statmat(esta) append(est1_1) store(est1_2)

*******************************************************
//add random intercept at hospice level
meqrlogit hosp_adm_ind || pos1:
mat est2=J(2,4,.)
mat e_2=e(b)
//coefficient, fixed part
mat est2[1,1]=e_2[1,1] //coef const

mat est2[1,2]=_se[_cons] //se

mat est2[1,3] = est2[1,1]-invttail(e(N)-1,0.05/2)*est2[1,2] //ci
mat est2[1,4] = est2[1,1]+invttail(e(N)-1,0.05/2)*est2[1,2] //ci

//random parts
mat est2[2,1]=exp(2*e_2[1,2]) //coef hosp int

sca se_re1 =_se[lns1_1_1:_cons] //se
mat est2[2,2]=se_re1*2*exp(2*e_2[1,2])

mat est2[2,3] = exp( 2*(e_2[1,2]-invttail(e(N)-1,0.05/2)*se_re1) ) //ci
mat est2[2,4] = exp( 2*(e_2[1,2]+invttail(e(N)-1,0.05/2)*se_re1) ) //ci

mat list est2
mat rownames est2="Patient intercept" "Hospice intercept"
mat dcols = (0,0,0,1)
frmttable, statmat(est2) doubles(dcols) substat(2) sdec(3) store(est2_1)

//add n, ll
mat esta[1,1]=e(N)
mat esta[2,1]=e(ll)

frmttable, sdec(0) statmat(esta) append(est2_1) store(est2_2)

*******************************************************
//add random intercept at region level
meqrlogit hosp_adm_ind || region1:

mat est3=J(2,4,.)
mat e_3=e(b)
//coefficient, fixed part
mat est3[1,1]=e_3[1,1] //coef const

mat est3[1,2]=_se[_cons] //se

mat est3[1,3] = est3[1,1]-invttail(e(N)-1,0.05/2)*est3[1,2] //ci
mat est3[1,4] = est3[1,1]+invttail(e(N)-1,0.05/2)*est3[1,2] //ci

//random parts
mat est3[2,1]=exp(2*e_3[1,2]) //coef reg int

sca se_re1 =_se[lns1_1_1:_cons] //se
mat est3[2,2]=se_re1*2*exp(2*e_3[1,2])

mat est3[2,3] = exp( 2*(e_3[1,2]-invttail(e(N)-1,0.05/2)*se_re1) ) //ci
mat est3[2,4] = exp( 2*(e_3[1,2]+invttail(e(N)-1,0.05/2)*se_re1) ) //ci

mat list est3
mat rownames est3="Patient intercept" "Region intercept"
mat dcols = (0,0,0,1)
frmttable, statmat(est3) doubles(dcols) substat(2) sdec(3) store(est3_1)

//add n, ll
mat esta[1,1]=e(N)
mat esta[2,1]=e(ll)

frmttable, sdec(0) statmat(esta) append(est3_1) store(est3_2)


*******************************************************
//now add random intercept at the hospice and region levels
meqrlogit hosp_adm_ind || region1: || pos1:

mat est4=J(3,4,.)
mat e_4=e(b)
mat list e_4

//coefficient, fixed part
mat est4[1,1]=e_4[1,1] //coef const

mat est4[1,2]=_se[_cons] //se

mat est4[1,3] = est4[1,1]-invttail(e(N)-1,0.05/2)*est4[1,2] //ci
mat est4[1,4] = est4[1,1]+invttail(e(N)-1,0.05/2)*est4[1,2] //ci

//random parts - region (col 2 in estimates)
mat est4[3,1]=exp(2*e_4[1,2]) //coef reg int

sca se_re1 =_se[lns1_1_1:_cons] //se
mat est4[3,2]=se_re1*2*exp(2*e_4[1,2])

mat est4[3,3] = exp( 2*(e_4[1,2]-invttail(e(N)-1,0.05/2)*se_re1) ) //ci
mat est4[3,4] = exp( 2*(e_4[1,2]+invttail(e(N)-1,0.05/2)*se_re1) ) //ci

//random parts - hospice (col 3 in estimates)
mat est4[2,1]=exp(2*e_4[1,3]) //coef reg int

sca se_re2 =_se[lns2_1_1:_cons] //se
mat est4[2,2]=se_re2*2*exp(2*e_4[1,3])

mat est4[2,3] = exp( 2*(e_4[1,3]-invttail(e(N)-1,0.05/2)*se_re2) ) //ci
mat est4[2,4] = exp( 2*(e_4[1,3]+invttail(e(N)-1,0.05/2)*se_re2) ) //ci

mat list est4
mat rownames est4="Patient intercept" "Hospice intercept" "Region intercept"
mat dcols = (0,0,0,1)
frmttable, statmat(est4) doubles(dcols) substat(2) sdec(3) store(est4_1)

//add n, ll
mat esta[1,1]=e(N)
mat esta[2,1]=e(ll)

frmttable, sdec(0) statmat(esta) append(est4_1) store(est4_2)

******************************************************* 
//add individual level (level 1) independent variables

local pat_vars female age_70_74 age_75_79 age_80_84 age_gt84 ///
 re_white cancer cc_grp_ind2 cc_grp_ind3 
 
meqrlogit hosp_adm_ind `pat_vars' || region1: || pos1:

//get all coef except the patient intercept (constant)
outreg, nocons stats(b se ci) sdec(3) varlabels store(est5_1) ///
		nostars noautosumm
 
mat est5=J(3,4,.)
mat e_5=e(b)
mat list e_5

//coefficient, fixed part (col 10 in estimates)
mat est5[1,1]=e_5[1,10] //coef const

mat est5[1,2]=_se[_cons] //se

mat est5[1,3] = est5[1,1]-invttail(e(N)-1,0.05/2)*est5[1,2] //ci
mat est5[1,4] = est5[1,1]+invttail(e(N)-1,0.05/2)*est5[1,2] //ci

//random parts - region (col 11 in estimates)
mat est5[3,1]=exp(2*e_5[1,11]) //coef reg int

sca se_re1 =_se[lns1_1_1:_cons] //se
mat est5[3,2]=se_re1*2*exp(2*e_5[1,11])

mat est5[3,3] = exp( 2*(e_5[1,11]-invttail(e(N)-1,0.05/2)*se_re1) ) //ci
mat est5[3,4] = exp( 2*(e_5[1,11]+invttail(e(N)-1,0.05/2)*se_re1) ) //ci

//random parts - hospice (col 12 in estimates)
mat est5[2,1]=exp(2*e_5[1,12]) //coef reg int

sca se_re2 =_se[lns2_1_1:_cons] //se
mat est5[2,2]=se_re2*2*exp(2*e_5[1,12])

mat est5[2,3] = exp( 2*(e_5[1,12]-invttail(e(N)-1,0.05/2)*se_re2) ) //ci
mat est5[2,4] = exp( 2*(e_5[1,12]+invttail(e(N)-1,0.05/2)*se_re2) ) //ci

mat list est5
mat rownames est5="Patient intercept" "Hospice intercept" "Region intercept"
mat dcols = (0,0,0,1)
frmttable, statmat(est5) doubles(dcols) substat(2) sdec(3) store(est5_2)

//add n, ll
mat esta[1,1]=e(N)
mat esta[2,1]=e(ll)

frmttable, sdec(0) statmat(esta) append(est5_2) store(est5_3)
outreg, replay(est5_3) append(est5_1) store(est5_4)

*******************************************************
//add hospice level (level 2) independent variables - includes exposure variable
//add individual level (level 1) independent variables

meqrlogit hosp_adm_ind `pat_vars' smd_on_call `hosp_vars' || region1: || pos1:

//get all coef except the patient intercept (constant)
outreg, nocons stats(b se ci) sdec(3) varlabels store(est6_1) ///
		nostars noautosumm
 
mat est6=J(3,4,.)
mat e_6=e(b)
mat list e_6

//coefficient, fixed part (col 15 in estimates)
mat est6[1,1]=e_6[1,15] //coef const

mat est6[1,2]=_se[_cons] //se

mat est6[1,3] = est6[1,1]-invttail(e(N)-1,0.05/2)*est6[1,2] //ci
mat est6[1,4] = est6[1,1]+invttail(e(N)-1,0.05/2)*est6[1,2] //ci

//random parts - region (col 16 in estimates)
mat est6[3,1]=exp(2*e_6[1,16]) //coef reg int

sca se_re1 =_se[lns1_1_1:_cons] //se
mat est6[3,2]=se_re1*2*exp(2*e_6[1,16])

mat est6[3,3] = exp( 2*(e_6[1,16]-invttail(e(N)-1,0.05/2)*se_re1) ) //ci
mat est6[3,4] = exp( 2*(e_6[1,16]+invttail(e(N)-1,0.05/2)*se_re1) ) //ci

//random parts - hospice (col 17 in estimates)
mat est6[2,1]=exp(2*e_6[1,17]) //coef reg int

sca se_re2 =_se[lns2_1_1:_cons] //se
mat est6[2,2]=se_re2*2*exp(2*e_6[1,17])

mat est6[2,3] = exp( 2*(e_6[1,17]-invttail(e(N)-1,0.05/2)*se_re2) ) //ci
mat est6[2,4] = exp( 2*(e_6[1,17]+invttail(e(N)-1,0.05/2)*se_re2) ) //ci

mat list est6
mat rownames est6="Patient intercept" "Hospice intercept" "Region intercept"
mat dcols = (0,0,0,1)
frmttable, statmat(est6) doubles(dcols) substat(2) sdec(3) store(est6_2)

//add n, ll
mat esta[1,1]=e(N)
mat esta[2,1]=e(ll)

frmttable, sdec(0) statmat(esta) append(est6_2) store(est6_3)
outreg, replay(est6_3) append(est6_1) store(est6_4)

************************************************************
//full model, adding region level independent variables
meqrlogit hosp_adm_ind  `pat_vars' smd_on_call `hosp_vars' `regvars' || ///
	region1: || pos1:
estimates save meqrlogit_est_smd_on_call, replace

//get all coef except the patient intercept (constant)
outreg, nocons stats(b se ci) sdec(3) varlabels store(est7_1) ///
		nostars noautosumm
 
mat est7=J(3,4,.)
mat e_7=e(b)
mat list e_7

//coefficient, fixed part (col 18 in estimates)
mat est7[1,1]=e_7[1,18] //coef const

mat est7[1,2]=_se[_cons] //se

mat est7[1,3] = est7[1,1]-invttail(e(N)-1,0.05/2)*est7[1,2] //ci
mat est7[1,4] = est7[1,1]+invttail(e(N)-1,0.05/2)*est7[1,2] //ci

//random parts - region (col 19 in estimates)
mat est7[3,1]=exp(2*e_7[1,19]) //coef reg int

sca se_re1 =_se[lns1_1_1:_cons] //se
mat est7[3,2]=se_re1*2*exp(2*e_7[1,19])

mat est7[3,3] = exp( 2*(e_7[1,19]-invttail(e(N)-1,0.05/2)*se_re1) ) //ci
mat est7[3,4] = exp( 2*(e_7[1,19]+invttail(e(N)-1,0.05/2)*se_re1) ) //ci

//random parts - hospice (col 20 in estimates)
mat est7[2,1]=exp(2*e_7[1,20]) //coef reg int

sca se_re2 =_se[lns2_1_1:_cons] //se
mat est7[2,2]=se_re2*2*exp(2*e_7[1,20])

mat est7[2,3] = exp( 2*(e_7[1,20]-invttail(e(N)-1,0.05/2)*se_re2) ) //ci
mat est7[2,4] = exp( 2*(e_7[1,20]+invttail(e(N)-1,0.05/2)*se_re2) ) //ci

mat list est7
mat rownames est7="Patient intercept" "Hospice intercept" "Region intercept"
mat dcols = (0,0,0,1)
frmttable, statmat(est7) doubles(dcols) substat(2) sdec(3) store(est7_2)

//add n, ll
mat esta[1,1]=e(N)
mat esta[2,1]=e(ll)

frmttable, sdec(0) statmat(esta) append(est7_2) store(est7_3)
outreg, replay(est7_3) append(est7_1) store(est7_4)

************************************************************
//now combine all models into single table
outreg, replay(est1_2) merge(est2_2) store(table1)
outreg, replay(table1) merge(est3_2) store(table2) 
outreg, replay(table2) merge(est4_2) store(table3) 
outreg, replay(table3) merge(est5_4) store(table4) 
outreg, replay(table4) merge(est6_4) store(table5)

outreg using "`logpath'/meqrlogit_table", ///
	replay(table5) merge(est7_4) store(table6) ///
	ctitles("","(1)","(2)","(3)","(4)","(5)","(6)","(7)" \ ///
	 "","Null","Hospice Random Int","Region Random Int","Hospice&Region Random Int" ///
	 "Patient Covariates","Add Hospice Cov.","Add Region Cov.") ///
	 replace

/*esttab est1 est2 est3 est4 est5 est6 est7 using "`logpath'/meqrlogit_table.rtf", ///
	nostar transform(/*ln*:*/ 1: exp(2*@) 2*exp(2*@)) scalars("ll Log likelihood")  ///
	equations(1:1:1:1:1:1:1 , .:2:.:3:3:3:3 , .:.:2:2:2:2:2) ///
        eqlabels("Patient Intercept" "Hospice Intercept" "Region Intercept" , none) ///
	varwidth(13) label replace ///
	mtitles("Null" "Hospice Random Int""Region Random Int" "Hospice&Region Random Int" ///
	"Patient Covariates" "Hospice Covariates" "Full Model")  ///
	cells(b(fmt(a3)) se(fmt(a4)) ci(fmt(a3))) */
/*  
*****************************************************************
//run meqrlogit as for loop for the remaining 4 exposure variables
//hospices within regions, covariance structure=independent (default)
foreach expos in /*smd_on_call*/ pan_efd symp_efd  poc_gocall3 fp_all3{
	meqrlogit hosp_adm_ind `expos' `pat_vars' `hosp_vars' `regvars' || ///
		region1: || pos1: //, cov(ex)
	estimates save meqrlogit_est_`expos', replace
}
*/
*****************************************************************
log close
