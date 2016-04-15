libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

data tables;
set ccw.final_hosp_county;
run;
proc freq data=tables;
table BENE_DEATH_DATE;
run;

data table1;
set tables;
/*age recode*/
if age_at_enr < 65 then agecat = 0;
if age_at_enr >= 65 and age_at_enr < 70 then agecat = 1;
if age_at_enr >= 70 and age_at_enr < 75 then agecat = 2;
if age_at_enr >= 75 and age_at_enr < 80 then agecat = 3;
if age_at_enr >= 80 and age_at_enr < 85 then agecat = 4;
if age_at_enr >= 85 then agecat = 5;
/*race recode*/
if re_white = 1 then race = 1;
if re_black = 1 then race = 2;
if re_other = 1 then race = 3;
if re_asian = 1 then race = 4;
if re_hispanic = 1 then race = 5;
if re_na = 1 then race = 6;
if re_unknown = 1 then race = 7;
/*annual patients recode*/
if total_patient<20 then sizecat=1;
else if (total_patient>=20 and total_patient<50) then sizecat=2;
else if (total_patient>=50 and total_patient<100) then sizecat=3;
else if (total_patient>=100) then sizecat=4;
/*changing ownership stuff*/
ownership = 3;
if form_owner = 1 or form_owner = 2 then ownership = 1;
if form_owner = 3 then ownership = 2;
/*prim diag*/
prin_diag_cat = 0;
if substr(left(trim(primary_icd)),1,1) in ('V','E','v','e') then prin_diag_cat=17;*put "v,E" into the others group;
if substr(left(trim(primary_icd)),1,1) not in ('V','E','v','e') then do;
prim_diag_str = substr(primary_icd,1,3);
prim_diag = prim_diag_str+0;
end;
if (0<prim_diag<140) then prin_diag_cat=1;
if 240>prim_diag>=140 then prin_diag_cat=2;
if 280>prim_diag>=240 then prin_diag_cat=3;
if 290>prim_diag>=280 then prin_diag_cat=4;
if 320>prim_diag>=290 then prin_diag_cat=5;
if 390>prim_diag>=320 then prin_diag_cat=6;
if 460>prim_diag>=390 then prin_diag_cat=7;
if 520>prim_diag>=460 then prin_diag_cat=8;
if 580>prim_diag>=520 then prin_diag_cat=9;
if 630>prim_diag>=580 then prin_diag_cat=10;
if 678>prim_diag>=630 then prin_diag_cat=11;
if 710>prim_diag>=680 then prin_diag_cat=12;
if 740>prim_diag>=710 then prin_diag_cat=13;
if 760>prim_diag>=740 then prin_diag_cat=14;
if 780>prim_diag>=760 then prin_diag_cat=15;
if 800>prim_diag>=780 then prin_diag_cat=16;
if prim_diag>=800 then prin_diag_cat=17;
prin_diag_cat1 = 7;
if prin_diag_cat = 2 then prin_diag_cat1 = 1;
if prin_diag_cat = 5 then prin_diag_cat1 = 2;
if prin_diag_cat = 6 then prin_diag_cat1 = 3;
if prin_diag_cat = 7 then prin_diag_cat1 = 4;
if prin_diag_cat = 8 then prin_diag_cat1 = 5;
if prin_diag_cat = 16 then prin_diag_cat1 = 6;
/*CC*/
if CC_count = 0 then CC_grp = 0;
if CC_count = 1 then CC_grp = 1;
if CC_count > 1 then CC_grp = 2;
/*CHarlson*/
if charlson_TOT_GRP = 0 then CC_GRP1 = 0;
if charlson_TOT_GRP = 1 then CC_GRP1 = 1;
if charlson_TOT_GRP > 1 then CC_GRP1 = 2;
/*dementia*/
prim_dementia = 0;
if prim_diag = 290 then prim_dementia = 1;
if prim_diag = . then prim_dementia = .;
/*secondary Diagnosis (only for getting dementia numbers)*/
icd_2_str = substr(icd_2,1,3);
icd_2_diag = icd_2_str+0;
icd_3_str = substr(icd_3,1,3);
icd_3_diag = icd_3_str+0;
icd_4_str = substr(icd_4,1,3);
icd_4_diag = icd_4_str+0;
icd_5_str = substr(icd_5,1,3);
icd_5_diag = icd_5_str+0;
/*this zero is okay because all instances of prim_diag exists*/
any_dementia = 0;
if prim_diag = 290 | icd_2_diag = 290 | icd_3_diag = 290| icd_4_diag = 290 | icd_5_diag = 290 then any_dementia = 1;

run;
/*
proc freq data=ccw.ltd_vars_for_analysis_4_8_16 ;
table prim_dementia any_dementia;
run;
data test (keep = BENE_ID prim_dementia prim_diag primary_icd icd_2_diag icd_2);
set table1;
if any_dementia = 1;
run;

proc format;
value prindiagfmt
        1='NEOPLASMS'
        2='MENTAL DISORDERS'
        3='DISEASES OF THE NERVOUS SYSTEM AND SENSE ORGANS'
        4='DISEASES OF THE CIRCULATORY SYSTEM'
        5='DISEASES OF THE RESPIRATORY SYSTEM '
        6='SYMPTOMS, SIGNS, AND ILL-DEFINED CONDITIONS'
        7='Other'
;
run;
*/

/*table 1 material: gender, age, race, */
/*
proc freq data=table1;
format prin_diag_cat1 prindiagfmt.;
table female agecat race sizecat region ownership prin_diag_cat1 cc_grp;
run;

proc freq data=table1;
table Open_access;
run;
*/
data table2;
set table1;
loglos = log(total_los + 1);
run;


/*table 2 LOS*/
/*
proc ttest data=table2;
class open_access;
var total_los;
run;
proc ttest data=table2;
class chemo;
var total_los;
run;
proc ttest data=table2;
class Tpn;
var total_los;
run;
proc ttest data=table2;
class trnsfusion;
var total_los;
run;
proc ttest data=table2;
class Intracath;
var total_los;
run;
proc ttest data=table2;
class Pall_radiat;
var total_los;
run;
proc ttest data=table2;
class No_fam_cg;
var total_los;
run;
proc ttest data=table2;
class Tube_feed;
var total_los;
run;

/*obtain the mean/median values*/
/*
ods rtf body = "J:\Geriatrics\Geri\Hospice Project\meanandmedian.rtf";
proc means data=table2 n mean median;
	class open_access;
	var total_los;
run;
proc means data=table2 n mean median;
	class chemo;
	var total_los;
run;
proc means data=table2 n mean median;
	class tpn;
	var total_los;
run;
proc means data=table2 n mean median;
	class trnsfusion;
	var total_los;
run;
proc means data=table2 n mean median;
	class intracath;
	var total_los;
run;
proc means data=table2 n mean median;
	class pall_radiat;
	var total_los;
run;
proc means data=table2 n mean median;
	class no_fam_cg;
	var total_los;
run;
proc means data=table2 n mean median;
	class tube_feed;
	var total_los;
run;
ods rtf close;

/*table 2 wilcoxon p value*/
/*
proc npar1way data=table2 wilcoxon;
	class open_access;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class chemo;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class Tpn;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class trnsfusion;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class Intracath;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class Pall_radiat;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class No_fam_cg;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class Tube_feed;
	var total_los;
run;


/*table 2 disenrolled*/
/*
proc freq data=table2;
table open_access*disenr / chisq;
run;
proc freq data=table2;
table chemo*disenr / chisq;
run;
proc freq data=table2;
table Tpn*disenr / chisq;
run;
proc freq data=table2;
table trnsfusion*disenr / chisq;
run;
proc freq data=table2;
table Intracath*disenr / chisq;
run;
proc freq data=table2;
table Pall_radiat*disenr / chisq;
run;
proc freq data=table2;
table No_fam_cg*disenr / chisq;
run;
proc freq data=table2;
table Tube_feed*disenr / chisq;
run;

/*Table 2 cancer*/
/*
proc freq data=table2;
table open_access*CC_GRP_14 / chisq;
run;
proc freq data=table2;
table chemo*CC_GRP_14 / chisq;
run;
proc freq data=table2;
table Pall_radiat*CC_GRP_14 / chisq;
run;


/*table 3 information*/
data table3;
set table2;
totalcosts = sum(totalcost1, totalcost2, totalcost3, totalcost4, totalcost5, totalcost6, totalcost7, totalcost8, totalcost9, totalcost10, totalcost11, totalcost12, totalcost13, totalcost14,
totalcost15, totalcost16, totalcost17, totalcost18, totalcost19, totalcost20, totalcost21, dme_cost, hha_cost, carr_cost, ip_tot_cost, snf_cost, op_cost);

totalcosts_hospice = sum(totalcost1, totalcost2, totalcost3, totalcost4, totalcost5, totalcost6, totalcost7, totalcost8, totalcost9, totalcost10, totalcost11, totalcost12, totalcost13, totalcost14,
totalcost15, totalcost16, totalcost17, totalcost18, totalcost19, totalcost20, totalcost21);

totalcosts_nonhospice = sum(dme_cost, hha_cost, carr_cost, ip_tot_cost, snf_cost, op_cost);

logtotalcosts = log(totalcosts + 1);
logtotalcosts_hospice = log(totalcosts_hospice + 1);
logtotalcosts_nonhospice = log(totalcosts_nonhospice + 1);
end_date = dod_clean;
no_death_date = 0;
if end_date = . then do; end_date = '31DEC2010'd; no_death_date = 1;end;
num_of_days = end_date - start + 1;
avg_exp_perday = totalcosts/total_los;
log_avg_exp = log(avg_exp_perday + 1);
avg_exp_tilldeath = totalcosts/num_of_days;
log_exp_tilldeath = log(avg_exp_tilldeath + 1);
run;

/*********************** Total Expenditures ***********************/

/*obtaining the mean and median of costs*/

/*proc means data=table3 n mean median;
class open_access;
var totalcosts;
run;
/*t test of the costs*/
/*proc ttest data=table3;
class open_access;
var logtotalcosts;
run;
/* running the nonparametric test of costs*/
/*proc npar1way data=table3 wilcoxon;
class open_access;
var totalcosts;
run;

/*********************** ED Visits and LOS ***********************/

/*2x2 table for those who have ED visits greater or equal to 1*/
/*proc freq data=table3;
table open_access*ip_ed_visit_ind / chisq;
run;
/*doing a poisson regression on the number of visits. Crude model*/
/*proc genmod data=table3;
class open_access / param = glm;
model ip_ed_visit_cnt = open_access / type3 dist=poisson;
run;
/*non-parametric test for ED visit count*/
/*proc npar1way data=table3 wilcoxon;
class open_access;
var ip_ed_visit_cnt;
run;
/*number of stays in ED without zeros*/
/*proc means data = table3 n mean median min max;
class open_access;
where ip_ed_visit_cnt ~= 0;
var ip_ed_visit_cnt;
run;
proc npar1way data=table3 wilcoxon;
where ip_ed_visit_cnt ~=0;
class open_access;
var ip_ed_visit_cnt;
run;

/*********************** ICU Visits and LOS ***********************/

/*2x2 table for those have have ICU visits greater or equal to 1*/
/*proc freq data=table3;
table open_access*icu_stay_ind / chisq;
run;
/*doing a poisson regression on the number of ICU stays*/
/*proc genmod data=table3;
where icu_stay_cnt ~= 0;
class open_access / param = glm;
model icu_stay_cnt = open_access / type3 dist=poisson;
run;
/*non-parametric test for # of ICU stays*/
/*proc npar1way data=table3 wilcoxon;
class open_access;
var icu_stay_cnt;
run;
/*number of stays in ICU without zero*/
/*proc means data = table3 n mean median min max;
class open_access;
where icu_stay_cnt ~= 0;
var icu_stay_cnt;
run;
proc npar1way data=table3 wilcoxon;
where icu_stay_cnt ~=0;
class open_access;
var icu_stay_cnt;
run;

/*********************** HOSPITALIZATIONS ***********************/

/*number of stays in hospital poisson regression*/
/*proc genmod data=table3;
class open_access / param = glm;
model hosp_adm_cnt = open_access / type3 dist=poisson;
run;
/*non-parametric for # of hosp stays*/
/*proc npar1way data=table3 wilcoxon;
class open_access;
var hosp_adm_cnt;
run;
/*number of stays in the Hosp without zeroes*/
/*proc means data = table3 n mean median min max;
class open_access;
where hosp_adm_cnt~= 0;
var hosp_adm_cnt;
run;
proc npar1way data=table3 wilcoxon;
where hosp_adm_cnt ~=0;
class open_access;
var hosp_adm_cnt;
run;
proc freq data=table3;
table open_access*hosp_adm_ind / chisq;
run;
data missing;
set table3;
if open_access = .;
run;
proc freq data=missing;
table POS1;
run;
/*poisson for the number of days a person was in the hospital*/
/*proc genmod data=table3;
class open_access / param = glm;
model hosp_adm_days = open_access / type3 dist=poisson;
run;
/*non-parametric for the number of days in the hospital*/
/*proc npar1way data=table3 wilcoxon;
class open_access;
var hosp_adm_days;
run;


/******************** Total Patient Column ***********************/
/*
proc means data=table3 n mean median min max;
var totalcosts;
run;
proc means data=table3 n mean median min max;
var avg_costs;
run;
proc freq data=table3;
table ip_ed_visit_ind / chisq;
run;
proc means data = table3 n mean median min max;
where ip_ed_visit_cnt ~= 0;
var ip_ed_visit_cnt;
run;
proc freq data=table3;
table icu_stay_ind / chisq;
run;
proc means data = table3 n mean median min max;
where icu_stay_cnt ~= 0;
var icu_stay_cnt;
run;
proc freq data=table3;
table hosp_adm_ind / chisq;
run;
proc means data = table3 n mean median min max;
class open_access;
where hosp_adm_cnt~= 0;
var hosp_adm_cnt;
run;
proc means data = table3 n mean median min max;
class open_access;
where hosp_adm_days~= 0;
var hosp_adm_days;
run;

proc univariate data=table3;
var num_of_days;
histogram;
run;


/******************************************************** TABLE 4 STUFF. VERY LONG**************************************/
/*
proc format;
*24 hour crisis mggt phone access
*Crisis management*;
value crisfmt     0="No"
                        1="7 days a week"
                        2="5 days a week"
                        3="Missing";

*Monitoring pain and symptoms
*Frequency of monitoring*;
value monfmt      1="Daily"
                        2="Every few days"
                        3="Weekly"
                        4="Less often"
                        5="Missing";

*Discussion of goals of care in patient plan of care and
*Adv directive, legal surrogate and pat pref included in discussions of patient plan of care
*Frequency of discussion*;
value discfmt    1="At admission only (1)"
                        2="As clinical conditions change only (2)"
                        3="On a routine schedule only (3)"
                        4="Not discussed"
                        5="Did not answer"
                        6="1, 2 and 3"
                        7="1 and 2"
                        8="1 and 3"
                        9="2 and 3";

value monfmt1f      	1="Daily"
                        2="Weekly"
                        3="All Else";

value monfmt2f     		1="Daily/Every Few Days"
                        2="Weekly"
                        3="All Else";
run;

*/
data table4;
set table3;
monitor_cat1 = 3;
if monitor_pan = 1 and monitor_ax = 1 and monitor_con = 1 and monitor_del = 1 and monitor_dep = 1 and monitor_dys = 1 and monitor_fat = 1 and monitor_nau= 1  then monitor_cat1 = 1;
if monitor_pan = 3 and monitor_ax = 3 and monitor_con = 3 and monitor_del = 3 and monitor_dep = 3 and monitor_dys = 3 and monitor_fat = 3 and monitor_nau= 3  then monitor_cat1 = 2;
monitor_cat2 = 3;
if (monitor_pan = 1 | monitor_pan = 2) and (monitor_ax = 1 | monitor_ax = 2) and (monitor_con = 1 | monitor_con = 2) and (monitor_del = 1 | monitor_del = 2) and (monitor_dep = 1 | monitor_dep = 2) and
(monitor_dys = 1 | monitor_dys = 2) and (monitor_fat = 1 | monitor_fat = 2) and (monitor_nau= 1 | monitor_nau= 2)  then monitor_cat2 = 1;
if monitor_pan = 3 and monitor_ax = 3 and monitor_con = 3 and monitor_del = 3 and monitor_dep = 3 and monitor_dys = 3 and monitor_fat = 3 and monitor_nau= 3  then monitor_cat2 = 2;
run;


/************************ Hospice Monitors Categorical Time Periods ****************************/

data table5;
set table4;

symptom_cat = 0;
if monitor_ax = 1 and monitor_con = 1 and monitor_del = 1
and monitor_dep = 1 and monitor_dys = 1 and monitor_fat = 1
and monitor_nau = 1 then symptom_cat = 1;
if monitor_ax = 2 and monitor_con = 2 and monitor_del = 2
and monitor_dep = 2 and monitor_dys = 2 and monitor_fat = 2
and monitor_nau = 2 then symptom_cat = 2;
if monitor_ax = 3 and monitor_con = 3 and monitor_del = 3
and monitor_dep = 3 and monitor_dys = 3 and monitor_fat = 3
and monitor_nau = 3 then symptom_cat = 3;

symptom_cat1 = 0;
if monitor_ax = 1 and monitor_con = 1 and monitor_del = 1
and monitor_dep = 1 and monitor_dys = 1 and monitor_fat = 1
and monitor_nau = 1 then symptom_cat1 = 1;
if (monitor_ax = 1 or monitor_ax = 2) and (monitor_con = 1 or monitor_con = 2) and (monitor_del = 1 or monitor_del = 2)
and (monitor_dep = 1 or monitor_dep = 2) and (monitor_dys = 1 or monitor_dys = 2) and (monitor_fat = 1 or monitor_fat = 2)
and (monitor_nau = 1 or monitor_nau = 2) and symptom_cat1 ~= 1 then symptom_cat1 = 2;
if monitor_ax = 2 and monitor_con = 2 and monitor_del = 2
and monitor_dep = 2 and monitor_dys = 2 and monitor_fat = 2
and monitor_nau = 2 then symptom_cat1 = 3;
if (monitor_ax = 2 or monitor_ax = 3) and (monitor_con = 2 or monitor_con = 3) and (monitor_del = 2 or monitor_del = 3)
and (monitor_dep = 2 or monitor_dep = 3) and (monitor_dys = 2 or monitor_dys = 3) and (monitor_fat = 2 or monitor_fat = 3)
and (monitor_nau = 2 or monitor_nau = 3) and symptom_cat1 ~= 3 then symptom_cat1 = 4;
if monitor_ax = 3 and monitor_con = 3 and monitor_del = 3
and monitor_dep = 3 and monitor_dys = 3 and monitor_fat = 3
and monitor_nau = 3 then symptom_cat1 = 5;
if monitor_ax = 3 and monitor_con = 3 and (monitor_del = 3 or monitor_del = 4) and (monitor_dep = 3 or monitor_dep = 4) 
and monitor_dys = 3 and (monitor_fat = 3 or monitor_fat = 4) and (monitor_nau = 3 or monitor_nau = 4) and symptom_cat1 ~= 5 
then symptom_cat1 = 6;

if symptom_cat1 = 1 or symptom_cat1 = 2 then symptom_cat2 = 0;
if symptom_cat1 = 3 then symptom_cat2 = 1;
if symptom_cat1 = 4 or symptom_cat1 = 5 or symptom_cat1 = 6 then symptom_cat2 = 2;

if ownership = 1 then ownership1 = 1;
if ownership = 2 or ownership = 3 then ownership1 = 2;
ownership_1 = (ownership1 = 1);
ownership_2 = (ownership2 = 1);

if region = 1 or region = 2 then region1 = 1;
if region = 3 or region = 4 then region1 = 2;
if region = 5 then region1 = 3;
if region = 6 or region = 7 then region1 = 4;
if region = 8 or region = 9 then region1 = 5;
region_1 = (region1=1);
region_2 = (region1=2);
region_3 = (region1=3);
region_4 = (region1=4);
region_5 = (region1=5);

cancer = 0;
if prin_diag_cat1 = 1 then cancer = 1;

all_17 = 0;
if Smech = 1 and Sberev_12_mo = 1  and Sscreen_bd = 1 and SFP_ALL3 = 1 and Sq32predeathplan = 1 and Sfam_satA = 1 and Sber_satA = 1 and Scrisis_mgt = 1
and Smd_on_call = 1 and Span_EFD = 1 and SSYMP_EFD = 1 and SCORE4 = 1 and SPOC_ADMIT = 1 and SPOC_GOCALL3 = 1 and SIT_SAF_A = 1 and SIT_patsat_A = 1 and Sstandard2 = 1 then all_17 = 1;
all_10 = 0;
if Scrisis_mgt = 1 and Smd_on_call = 1 and Span_EFD = 1 and SSYMP_EFD = 1 and SCORE4 = 1 and SPOC_ADMIT = 1 and SPOC_GOCALL3 = 1 and SIT_SAF_A = 1 and SIT_patsat_A = 1 and Sstandard2 = 1 then all_10 = 1;

/*calculation checks out*/
ed_visit_ind = 0;
if op_ed_count > 0 or ip_ed_visit_ind = 1 then ed_visit_ind = 1;
run;

/*
proc freq data=table5;
table ip_ed_visit_ind op_ed_count ed_visit_ind;
run;
proc freq data=table5;
table pan_efd symptom_cat symptom_cat1 symptom_cat2 ownership1 region1 cancer monitor_pan;
run;
*/
/*
%let varlist = 
symp_efd smd_on_call symp_efd poc_gocall3 fp_all3 all_17 all_10;
%macro freq();
%let i=1;
%let var=%scan(&varlist,&i);
%do %while(&var ne ) ;
proc freq data=table5; 
format &var monfmt.;
table ed_visit_ind*&var / chisq;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where ed_visit_ind > 0;
var ed_visit_ind;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where ed_visit_ind > 0;
class &var;
var ed_visit_ind;
run;
proc anova data=table5;
where ed_visit_ind > 0;
format &var monfmt.;
class &var;
model ed_visit_ind=&var;
run;
proc freq data=table5;
format &var monfmt.;
table icu_stay_ind*&var / chisq;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where icu_stay_cnt > 0;
var icu_stay_cnt;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where icu_stay_cnt > 0;
class &var;
var icu_stay_cnt;
run;
proc anova data=table5;
where icu_stay_cnt > 0;
format &var monfmt.;
class &var;
model icu_stay_cnt=&var;
run;
proc freq data=table5;
format &var monfmt.;
table hosp_adm_ind*&var / chisq;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where hosp_adm_cnt > 0;
var hosp_adm_cnt;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where hosp_adm_cnt > 0;
class &var;
var hosp_adm_cnt;
run;
proc anova data=table5;
where hosp_adm_cnt > 0;
format &var monfmt.;
class &var;
model hosp_adm_cnt=&var;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where hosp_adm_days > 0;
var hosp_adm_days;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where hosp_adm_days > 0;
class &var;
var hosp_adm_days;
run;
proc anova data=table5;
where hosp_adm_days > 0;
format &var monfmt.;
class &var;
model hosp_adm_days=&var;
run;
%let i=%eval(&i+1);
%let var=%scan(&varlist,&i);
%end;
%mend;
ods html close;
ods html;
%freq;
quit;
%let varlist = 
symp_efd smd_on_call symp_efd poc_gocall3 fp_all3;
%let = female agecat re_white cancer cc_grp ownership1 sizecat region1;
proc genmod data=table5 descending;
class pos1 ed_visit_ind (ref = '0') symp_efd (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ed_visit_ind = pan_efd region1
/dist=bin link=logit type3 wald ;
repeated subject=pos1/type=exch;
run;

%let varlist0 = smd_on_call pan_efd symp_efd poc_gocall3 fp_all3 all_17 all_10;
%let varlist1 = smd_on_call pan_efd symp_efd poc_gocall3 fp_all3 all_17 all_10;
/*%let varlist2 = ip_ed_visit_ind hosp_adm_ind icu_stay_ind;*/
/*
%macro regression();
%let i = 1;
%let var=%scan(&varlist1,&i);
%do %while(&var ne ) ;
proc genmod data=table5 descending;
class pos1 ed_visit_ind (ref = '0') &var (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ed_visit_ind = &var female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald ;
repeated subject=pos1/type=exch;
estimate "log O.R. Main Effect" &var 1 -1 / exp;
estimate "log O.R. Female" female 1 -1 / exp;
estimate "log O.R. Age 70-74 vs. <69" agecat 1 0 0 0 0 /exp;
estimate "log O.R. Age 75-79 vs. <69" agecat 0 1 0 0 0 /exp;
estimate "log O.R. Age 80-84 vs. <69" agecat 0 0 1 0 0 /exp;
estimate "log O.R. Age 84+ vs. <69" agecat 0 0 0 1 0 /exp;
estimate "log O.R. White" re_white 1 -1 /exp;
estimate "log O.R. Cancer" cancer 1 -1/exp;
estimate "log O.R. CC Group 1 vs. 0" cc_grp 1 0 0/exp;
estimate "log O.R. CC Group >1 vs. 0" cc_grp 0 1 0 / exp;
estimate "log O.R. ownership" ownership1 1 -1/exp;
estimate "log O.R. Size (250 to <600) vs. <250" sizecat 1 0 0 0/exp;
estimate "log O.R. size (600 to <1300) vs. <250" sizecat 0 1 0 0 / exp;
estimate "log O.R. size (1300 or more) vs. <250" sizecat 0 0 1 0 / exp;
estimate "log O.R. region (New England/MA vs. South Atlantic)" region1 1 0 0 0 0/exp;
estimate "log O.R. region (E/W North Central vs. South Atlantic)" region1 0 1 0 0 0/exp;
estimate "log O.R. region (E/W South Central vs. South Atlantic)" region1 0 0 1 0/exp;
estimate "log O.R. region (Mountain/Pacific vs. South Atlantic)" region1 0 0 0 1/exp;
run;
proc genmod data=table5 descending;
class pos1 hosp_adm_ind (ref = '0') &var (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = &var female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald ;
repeated subject=pos1/type=exch;
estimate "log O.R. Main Effect" &var 1 -1 / exp;
estimate "log O.R. Female" female 1 -1 / exp;
estimate "log O.R. Age 70-74 vs. <69" agecat 1 0 0 0 0 /exp;
estimate "log O.R. Age 75-79 vs. <69" agecat 0 1 0 0 0 /exp;
estimate "log O.R. Age 80-84 vs. <69" agecat 0 0 1 0 0 /exp;
estimate "log O.R. Age 84+ vs. <69" agecat 0 0 0 1 0 /exp;
estimate "log O.R. White" re_white 1 -1 /exp;
estimate "log O.R. Cancer" cancer 1 -1/exp;
estimate "log O.R. CC Group 1 vs. 0" cc_grp 1 0 0/exp;
estimate "log O.R. CC Group >1 vs. 0" cc_grp 0 1 0 / exp;
estimate "log O.R. ownership" ownership1 1 -1/exp;
estimate "log O.R. Size (250 to <600) vs. <250" sizecat 1 0 0 0/exp;
estimate "log O.R. size (600 to <1300) vs. <250" sizecat 0 1 0 0 / exp;
estimate "log O.R. size (1300 or more) vs. <250" sizecat 0 0 1 0 / exp;
estimate "log O.R. region (New England/MA vs. South Atlantic)" region1 1 0 0 0 0/exp;
estimate "log O.R. region (E/W North Central vs. South Atlantic)" region1 0 1 0 0 0/exp;
estimate "log O.R. region (E/W South Central vs. South Atlantic)" region1 0 0 1 0/exp;
estimate "log O.R. region (Mountain/Pacific vs. South Atlantic)" region1 0 0 0 1/exp;
run;
proc genmod data=table5 descending;
class pos1 icu_stay_ind (ref = '0') &var (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = &var female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald ;
repeated subject=pos1/type=exch;
estimate "log O.R. Main Effect" &var 1 -1 / exp;
estimate "log O.R. Female" female 1 -1 / exp;
estimate "log O.R. Age 70-74 vs. <69" agecat 1 0 0 0 0 /exp;
estimate "log O.R. Age 75-79 vs. <69" agecat 0 1 0 0 0 /exp;
estimate "log O.R. Age 80-84 vs. <69" agecat 0 0 1 0 0 /exp;
estimate "log O.R. Age 84+ vs. <69" agecat 0 0 0 1 0 /exp;
estimate "log O.R. White" re_white 1 -1 /exp;
estimate "log O.R. Cancer" cancer 1 -1/exp;
estimate "log O.R. CC Group 1 vs. 0" cc_grp 1 0 0/exp;
estimate "log O.R. CC Group >1 vs. 0" cc_grp 0 1 0 / exp;
estimate "log O.R. ownership" ownership1 1 -1/exp;
estimate "log O.R. Size (250 to <600) vs. <250" sizecat 1 0 0 0/exp;
estimate "log O.R. size (600 to <1300) vs. <250" sizecat 0 1 0 0 / exp;
estimate "log O.R. size (1300 or more) vs. <250" sizecat 0 0 1 0 / exp;
estimate "log O.R. region (New England/MA vs. South Atlantic)" region1 1 0 0 0 0/exp;
estimate "log O.R. region (E/W North Central vs. South Atlantic)" region1 0 1 0 0 0/exp;
estimate "log O.R. region (E/W South Central vs. South Atlantic)" region1 0 0 1 0/exp;
estimate "log O.R. region (Mountain/Pacific vs. South Atlantic)" region1 0 0 0 1/exp;
run;
%let i=%eval(&i+1);
%let var=%scan(&varlist1,&i);
%end;
%mend;
ods html close;
ods html;
%regression;
%let varlist1 = smd_on_call pan_efd symp_efd poc_gocall3 fp_all3 all_17 all_10;
%let varlist2 = ip_ed_visit_ind hosp_adm_ind icu_stay_ind;
Options symbolgen mlogic mprint mfile;
%macro freq1();
%let j = 1;
%let var1=%scan(&varlist2,&j);
%do %while(&var1 ne );
	%let i = 1;
	%let var=%scan(&varlist1,&i);
	%do %while(&var ne ) ;
	proc freq data=table5;
	table &var1*&var;
	run;
	proc freq data=table5;
	table &var1*female;
	run;
	proc freq data=table5;
	table &var1*agecat;
	run;
	proc freq data=table5;
	table &var1*re_white;
	run;
	proc freq data=table5;
	table &var1*cancer;
	run;
	proc freq data=table5;
	table &var1*cc_grp;
	run;
	proc freq data=table5;
	table &var1*ownership1;
	run;
	proc freq data=table5;
	table &var1*sizecat;
	run;
	proc freq data=table5;
	table &var1*region1;
	run;
	%let i=%eval(&i+1);
	%let var=%scan(&varlist,&i);
	%end;
%let j=%eval(&j+1);
%let var1=%scan(&varlist2,&j);
%end;
%mend;
ods html close;
ods html;
%freq1;

proc freq data=table5;
table Sberev_12_mo Sberev_12_mo Sscreen_routine screen_routine Sscreen_bd screen_bd SFP_ALL3 FP_ALL3 Sq32predeathplan q32predeathplan Sfam_satA fam_satA Sber_satA ber_satA;
run;
proc freq data=table5;
table Scrisis_mgt crisis_mgt Smd_on_call md_on_call Span_EFD pan_EFD SSYMP_EFD SYMP_EFD SCORE4 CORE4 SPOC_ADMIT POC_ADMIT SPOC_GOCALL3 POC_GOCALL3 Sstandard2
standard2 SIT_SAF_A IT_SAF_A SIT_patsat_A IT_patsat_A;
run;

data table5;
set table5;
run;
proc freq data=table5;
table ip_ed_visit_ind*all_17 hosp_adm_ind*all_17 icu_stay_ind*all_17
ip_ed_visit_ind*all_10 hosp_adm_ind*all_10 icu_stay_ind*all_10 / chisq;
run;
*/
*saves a version with only a few variables to export to Stata;
data ccw.ltd_vars_for_analysis;
set ccw.for_analysis(keep= ip_ed_visit_ind ed_visit_ind hosp_adm_ind icu_stay_ind
female agecat re_white cancer cc_grp ownership1
pos1 sizecat region1 smd_on_call pan_efd symp_efd poc_gocall3 fp_all3
county_state beds_2009 nursing_beds_2009 per_cap_inc_2009 Census_Pop_2010 urban_cd CC_2_ALZH CC_3_ALZHDMTA total_los disenr hosp_death prim_dementia any_dementia);
run;
proc means data=ccw.ltd_vars_for_analysis;
var total_los;
run;
proc freq data=ccw.ltd_vars_for_analysis;
table CC_2_ALZH;
run;
proc export data=ccw.ltd_vars_for_analysis
	outfile='J:\Geriatrics\Geri\Hospice Project\Hospice\working\ltd_vars_for_analysis1.dta'
	replace;
	run;

/*
proc genmod data=table5 descending;
class pos1 hosp_adm_ind (ref = '0') pan_efd (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = pan_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald ;
repeated subject=pos1/type=exch;
estimate "log O.R. Pain EFD" pan_efd 1 -1 / exp;
estimate "log O.R. Female" female 1 -1 / exp;
estimate "log O.R. Age 70-74 vs. <69" agecat 1 0 0 0 0 /exp;
estimate "log O.R. Age 75-79 vs. <69" agecat 0 1 0 0 0 /exp;
estimate "log O.R. Age 80-84 vs. <69" agecat 0 0 1 0 0 /exp;
estimate "log O.R. Age 84+ vs. <69" agecat 0 0 0 1 0 /exp;
estimate "log O.R. White" re_white 1 -1 /exp;
estimate "log O.R. Cancer" cancer 1 -1/exp;
estimate "log O.R. CC Group 1 vs. 0" cc_grp 1 0 0/exp;
estimate "log O.R. CC Group >1 vs. 0" cc_grp 0 1 0 / exp;
estimate "log O.R. ownership" ownership1 1 -1/exp;
estimate "log O.R. Size (250 to <600) vs. <250" sizecat 1 0 0 0/exp;
estimate "log O.R. size (600 to <1300) vs. <250" sizecat 0 1 0 0 / exp;
estimate "log O.R. size (1300 or more) vs. <250" sizecat 0 0 1 0 / exp;
estimate "log O.R. region (New England/MA vs. South Atlantic)" region1 1 0 0 0 0/exp;
estimate "log O.R. region (E/W North Central vs. South Atlantic)" region1 0 1 0 0 0/exp;
estimate "log O.R. region (E/W South Central vs. South Atlantic)" region1 0 0 1 0/exp;
estimate "log O.R. region (Mountain/Pacific vs. South Atlantic)" region1 0 0 0 1/exp;
run;
proc freq data=table5;
table cc_grp;
run;
proc freq data=table5;
table female agecat re_white cancer cc_grp ownership1 sizecat region1;
run;
*/
data table5;
set ccw.for_analysis;
run;
/*
proc freq data=table5;
table ed_visit_ind;
run;
*/
data table5;
set table5;
ed_visit_ind = 0;
if op_ed_count > 0 or ip_ed_visit_ind = 1 then ed_visit_ind = 1;
all_17 = 0;
if Smech = 1 and Sberev_12_mo = 1  and Sscreen_bd = 1 and SFP_ALL3 = 1 and Sq32predeathplan = 1 and Sfam_satA = 1 and Sber_satA = 1 and Scrisis_mgt = 1
and Smd_on_call = 1 and Span_EFD = 1 and SSYMP_EFD = 1 and SCORE4 = 1 and SPOC_ADMIT = 1 and SPOC_GOCALL3 = 1 and SIT_SAF_A = 1 and SIT_patsat_A = 1 and Sstandard2 = 1 then all_17 = 1;
all_10 = 0;
if Scrisis_mgt = 1 and Smd_on_call = 1 and Span_EFD = 1 and SSYMP_EFD = 1 and SCORE4 = 1 and SPOC_ADMIT = 1 and SPOC_GOCALL3 = 1 and SIT_SAF_A = 1 and SIT_patsat_A = 1 and Sstandard2 = 1 then all_10 = 1;
ed_visit_cnt = op_ed_count + ip_ed_visit_cnt;
run;
/*
proc means data=table5;
where ed_visit_cnt > 0;
var ed_visit_cnt ip_ed_visit_cnt op_ed_count;
run;
proc freq data=table5;
table all_17;
run;
*/
data ccw.for_analysis;
set table5;
run;
/*
proc freq data=table5;
table agecat;
run;

proc freq data=table5;
table female agecat re_white cancer cc_grp ownership1 sizecat region1;
run;
proc contents data=table5 varnum;
run;
proc contents data=table5;
run;

data test;
set ccw.charlson;
if CC_GRP_1 = .;
run;
*/


data table6;
set table5;
death_hospice = 0;
if (discharge1=40|discharge1=41|discharge1=42) then death_hospice = 1;
if (discharge2=40|discharge2=41|discharge2=42) then death_hospice = 1;
if (discharge3=40|discharge3=41|discharge3=42) then death_hospice = 1;
if (discharge4=40|discharge4=41|discharge4=42) then death_hospice = 1;
if (discharge5=40|discharge5=41|discharge5=42) then death_hospice = 1;
if (discharge6=40|discharge6=41|discharge6=42) then death_hospice = 1;
if (discharge7=40|discharge7=41|discharge7=42) then death_hospice = 1;
if (discharge8=40|discharge8=41|discharge8=42) then death_hospice = 1;
if (discharge9=40|discharge9=41|discharge9=42) then death_hospice = 1;
if (discharge10=40|discharge10=41|discharge10=42) then death_hospice = 1;
if (discharge11=40|discharge11=41|discharge11=42) then death_hospice = 1;
if (discharge12=40|discharge12=41|discharge12=42) then death_hospice = 1;
if (discharge13=40|discharge13=41|discharge13=42) then death_hospice = 1;
if (discharge14=40|discharge14=41|discharge14=42) then death_hospice = 1;
if (discharge15=40|discharge15=41|discharge15=42) then death_hospice = 1;
if (discharge16=40|discharge16=41|discharge16=42) then death_hospice = 1;
if (discharge17=40|discharge17=41|discharge17=42) then death_hospice = 1;
if (discharge18=40|discharge18=41|discharge18=42) then death_hospice = 1;
if (discharge19=40|discharge19=41|discharge19=42) then death_hospice = 1;
if (discharge20=40|discharge20=41|discharge20=42) then death_hospice = 1;
if (discharge21=40|discharge21=41|discharge21=42) then death_hospice = 1;
hospital_death = 0;
if death_hospice = 1 or hosp_death = 1 then hospital_death = 1;
ed_count_total = op_ed_count + ip_ed_visit_cnt;
if disenr = 1 then do;
disenr_to_death = dod_clean - end1 + 1;
end;
if disenr_to_death < 0 then disenr_to_death = .; /*figure out what to do with the ones that are negative*/
run;



data ccw.for_analysis1;
set table6;
run;

data ccw.ltd_vars_for_analysis_4_8_16;
set ccw.for_analysis1(keep= bene_id ip_ed_visit_ind ed_visit_ind hosp_adm_ind icu_stay_ind cc_count
female agecat re_white cancer cc_grp ownership1 prin_diag_cat1
pos1 sizecat region1 smd_on_call pan_efd symp_efd poc_gocall3 fp_all3
county_state beds_2009 nursing_beds_2009 per_cap_inc_2009 Census_Pop_2010 urban_cd CC_2_ALZH CC_3_ALZHDMTA total_los 
totalcosts totalcosts_hospice totalcosts_nonhospice op_cost dme_cost hha_cost ip_tot_cost snf_cost carr_cost disenr hosp_death disenr_to_death ed_count_total hospital_death death_hospice hosp_death hosp_adm_days icu_stay_days age_at_enr prim_dementia any_dementia);
run;
proc freq data=ccw.ltd_vars_for_analysis_4_8_16;
table prim_dementia any_dementia;
run;
/*
%macro hospice;
%do i = 1 %to 21;
data table5;
set table5;
death_hospice = 0;

run;
%end;
%mend;
options mprint mlogic;
%hospice;
proc freq data=table6;
table hospital_death;
run;
*/
/*
proc freq data=ccw.ltd_vars_for_analysis1;
table cc_grp;
run;



/*************************************************************** SECONDARY DIAGNOSIS *********************************************************/
/*
data table1b;
set table1;
run;
option symbolgen;
option mprint;
%macro icd2_5;
%do i = 2 %to 5;
data table1b;
set table1b;
/*other diag*/
/*
diag_cat&i. = 0;
if icd_&i. = "" then diag_cat&i. = .;
if substr(left(trim(icd_&i.)),1,1) in ('V','E','v','e') then diag_cat&i.=17;*put "v,E" into the others group;
if substr(left(trim(icd_&i.)),1,1) not in ('V','E','v','e') then do;
icd_&i._str = substr(icd_&i.,1,3);
icd_&i._diag = icd_&i._str+0;
end;
if (0<icd_&i._diag<140) then diag_cat&i.=1;
if 240>icd_&i._diag>=140 then diag_cat&i.=2;
if 280>icd_&i._diag>=240 then diag_cat&i.=3;
if 290>icd_&i._diag>=280 then diag_cat&i.=4;
if 320>icd_&i._diag>=290 then diag_cat&i.=5;
if 390>icd_&i._diag>=320 then diag_cat&i.=6;
if 460>icd_&i._diag>=390 then diag_cat&i.=7;
if 520>icd_&i._diag>=460 then diag_cat&i.=8;
if 580>icd_&i._diag>=520 then diag_cat&i.=9;
if 630>icd_&i._diag>=580 then diag_cat&i.=10;
if 678>icd_&i._diag>=630 then diag_cat&i.=11;
if 710>icd_&i._diag>=680 then diag_cat&i.=12;
if 740>icd_&i._diag>=710 then diag_cat&i.=13;
if 760>icd_&i._diag>=740 then diag_cat&i.=14;
if 780>icd_&i._diag>=760 then diag_cat&i.=15;
if 800>icd_&i._diag>=780 then diag_cat&i.=16;
if icd_&i._diag>=800 then diag_cat&i.=17;
if diag_cat&i. = 2 then diag_cat&i._1 = 1;
if diag_cat&i. = 5 then diag_cat&i._1 = 2;
if diag_cat&i. = 6 then diag_cat&i._1 = 3;
if diag_cat&i. = 7 then diag_cat&i._1 = 4;
if diag_cat&i. = 8 then diag_cat&i._1 = 5;
if diag_cat&i. = 16 then diag_cat&i._1 = 6;
if diag_cat&i. ~= . and diag_cat&i._1 = . then diag_cat&i._1 = 7;

run;
%end;
%mend;
%icd2_5();
proc freq data=table1b;
table diag_cat2;
run;

/*
data test (keep = bene_id icd_2 diag_cat2 icd_2_str icd_2_diag diag_cat2_1);
set table1b;
if diag_cat2 = 17;
run;
*/
/*
proc format;
value prindiagfmt
        1='NEOPLASMS'
        2='MENTAL DISORDERS'
        3='DISEASES OF THE NERVOUS SYSTEM AND SENSE ORGANS'
        4='DISEASES OF THE CIRCULATORY SYSTEM'
        5='DISEASES OF THE RESPIRATORY SYSTEM '
        6='SYMPTOMS, SIGNS, AND ILL-DEFINED CONDITIONS'
        7='Other'
;
run;
proc format;
value icd9catfmt
      1='INFECTIOUS AND PARASITIC DISEASES'
	  2='NEOPLASMS'
	  3='ENDOCRINE, NUTRITIONAL AND METABOLIC DISEASES, AND IMMUNITY DISORDERS'
	  4='DISEASES OF THE BLOOD AND BLOOD-FORMING ORGANS'
	  5='MENTAL DISORDERS'
	  6='DISEASES OF THE NERVOUS SYSTEM AND SENSE ORGANS'
	  7='DISEASES OF THE CIRCULATORY SYSTEM'
	  8='DISEASES OF THE RESPIRATORY SYSTEM '
	  9='DISEASES OF THE DIGESTIVE SYSTEM'
	  10='DISEASES OF THE GENITOURINARY SYSTEM'
	  11='COMPLICATIONS OF PREGNANCY, CHILDBIRTH, AND THE PUERPERIUM'
	  12='DISEASES OF THE SKIN AND SUBCUTANEOUS TISSUE'
	  13='DISEASES OF THE SKIN AND SUBCUTANEOUS TISSUE'
	  14='CONGENITAL ANOMALIES'
	  15='CERTAIN CONDITIONS ORIGINATING IN THE PERINATAL PERIOD'
	  16='SYMPTOMS, SIGNS, AND ILL-DEFINED CONDITIONS'
	  17='INJURY AND POISONING'
 ;
run;
ods rtf body = "J:\Geriatrics\Geri\Hospice Project\other_diag.rtf";
proc freq data=table1b;
format diag_cat2 icd9catfmt. diag_cat3 icd9catfmt. diag_cat4 icd9catfmt. diag_cat5 icd9catfmt. diag_cat2_1 prindiagfmt. diag_cat3_1 prindiagfmt. diag_cat4_1 prindiagfmt. diag_cat5_1 prindiagfmt.;
table diag_cat2 diag_cat3 diag_cat4 diag_cat5 diag_cat2_1 diag_cat3_1 diag_cat4_1 diag_cat5_1;
run;
ods rtf close;

data table1b_mrg (keep = bene_id icd_2-icd_5 diag_cat2 diag_cat3 diag_cat4 diag_cat5 diag_cat2_1 diag_cat3_1 diag_cat4_1 diag_cat5_1);
set table1b;
run;

proc sql;
create table ccw.Ltd_vars_for_analysis3
as select a.*, b.diag_cat2, b.diag_cat3, b.diag_cat4, b.diag_cat5, b.diag_cat2_1, b.diag_cat3_1, b.diag_cat4_1, b.diag_cat5_1
from ccw.Ltd_vars_for_analysis2 a
left join table1b_mrg b
on a.bene_id = b.bene_id;
quit;
proc freq data=ccw.Ltd_vars_for_analysis3;
table diag_cat2;
run;
*/
