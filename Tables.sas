libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

data tables;
set ccw.final_hosp_county;
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
if charlson_TOT_GRP = 0 then CC_grp = 0;
if charlson_TOT_GRP = 1 then CC_grp = 1;
if charlson_TOT_GRP > 1 then CC_grp = 2;
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

proc freq data=ccw.for_analysis;
table cc_grp;
run;
proc freq data=table1;
table cc_grp;
run;

/*table 1 material: gender, age, race, */
proc freq data=table1;
format prin_diag_cat1 prindiagfmt.;
table female agecat race sizecat region ownership prin_diag_cat1 cc_grp;
run;

proc freq data=table1;
table Open_access;
run;

data table2;
set table1;
loglos = log(total_los + 1);
run;

/*table 2 LOS*/
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
proc means data=table3 n mean median;
class open_access;
var totalcosts;
run;
/*t test of the costs*/
proc ttest data=table3;
class open_access;
var logtotalcosts;
run;
/* running the nonparametric test of costs*/
proc npar1way data=table3 wilcoxon;
class open_access;
var totalcosts;
run;

/*********************** ED Visits and LOS ***********************/

/*2x2 table for those who have ED visits greater or equal to 1*/
proc freq data=table3;
table open_access*ip_ed_visit_ind / chisq;
run;
/*doing a poisson regression on the number of visits. Crude model*/
proc genmod data=table3;
class open_access / param = glm;
model ip_ed_visit_cnt = open_access / type3 dist=poisson;
run;
/*non-parametric test for ED visit count*/
proc npar1way data=table3 wilcoxon;
class open_access;
var ip_ed_visit_cnt;
run;
/*number of stays in ED without zeros*/
proc means data = table3 n mean median min max;
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
proc freq data=table3;
table open_access*icu_stay_ind / chisq;
run;
/*doing a poisson regression on the number of ICU stays*/
proc genmod data=table3;
where icu_stay_cnt ~= 0;
class open_access / param = glm;
model icu_stay_cnt = open_access / type3 dist=poisson;
run;
/*non-parametric test for # of ICU stays*/
proc npar1way data=table3 wilcoxon;
class open_access;
var icu_stay_cnt;
run;
/*number of stays in ICU without zero*/
proc means data = table3 n mean median min max;
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
proc genmod data=table3;
class open_access / param = glm;
model hosp_adm_cnt = open_access / type3 dist=poisson;
run;
/*non-parametric for # of hosp stays*/
proc npar1way data=table3 wilcoxon;
class open_access;
var hosp_adm_cnt;
run;
/*number of stays in the Hosp without zeroes*/
proc means data = table3 n mean median min max;
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
proc genmod data=table3;
class open_access / param = glm;
model hosp_adm_days = open_access / type3 dist=poisson;
run;
/*non-parametric for the number of days in the hospital*/
proc npar1way data=table3 wilcoxon;
class open_access;
var hosp_adm_days;
run;


/******************** Total Patient Column ***********************/
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

run;
proc freq data=table5;
table pan_efd symptom_cat symptom_cat1 symptom_cat2 ownership1 region1 cancer monitor_pan;
run;


%let varlist = 
symp_efd smd_on_call symp_efd poc_gocall3 fp_all3;
%macro freq();
%let i=1;
%let var=%scan(&varlist,&i);
%do %while(&var ne ) ;
proc freq data=table5; 
format &var monfmt.;
table ip_ed_visit_ind*&var / chisq;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where ip_ed_visit_cnt > 0;
var ip_ed_visit_cnt;
run;
proc means data=table5 n mean median min max std;
format &var monfmt.;
where ip_ed_visit_cnt > 0;
class &var;
var ip_ed_visit_cnt;
run;
proc anova data=table5;
where ip_ed_visit_cnt > 0;
format &var monfmt.;
class &var;
model ip_ed_visit_cnt=&var;
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



ods html close;
ods html;
proc genmod data=table5 descending;
class pos1 monitor_pan (ref = '3') ip_ed_visit_ind (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = monitor_pan agecat re_white cancer cc_grp ownership1 sizecat
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Pain" monitor_pan 0 1 0 / exp;
run;
proc genmod data=table5 descending;
class pos1 monitor_pan (ref = '3') icu_stay_ind (ref = '0') 
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = monitor_pan agecat re_white cancer cc_grp ownership1 sizecat
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Pain" monitor_pan 1 -1 / exp;
run;
proc genmod data=table5 descending;
class pos1 monitor_pan (ref = '3') hosp_adm_ind (ref = '0') 
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = monitor_pan agecat re_white cancer cc_grp ownership1 sizecat
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Pain" monitor_pan 1 -1 / exp;
run;
proc genmod data=table5 descending;
class pos1 symptom_cat2 (ref = '2') ip_ed_visit_ind (ref = '0') 
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = symptom_cat2 agecat re_white cancer cc_grp ownership1 sizecat
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Pain" symptom_cat2 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1 symptom_cat2 (ref = '2') icu_stay_ind (ref = '0') 
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = symptom_cat2 agecat re_white cancer cc_grp ownership1 sizecat
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
proc genmod data=table5 descending;
class pos1 symptom_cat2 (ref = '2') hosp_adm_ind (ref = '0') 
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = symptom_cat2 agecat re_white cancer cc_grp ownership1 sizecat
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
/*outcomes: ip_ed_visit_ind icu_stay_ind hosp_adm_ind
main predictor: monitor_pan symptom_cat2
covariates: 
*/
proc sort data=table5;
by descending pan_efd;
run;
data table5;
set ccw.ltd_vars_for_analysis;
hospital_beds_per_res = beds_2009/census_pop_2010;
run;
ods html close;
ods html;
proc glimmix data=table5 initglm;
class pos1 pan_efd ownership1 sizecat region1 agecat urban_cd hospital_beds_per_res per_cap_inc_2009;
model ip_ed_visit_ind = pan_efd agecat re_white cancer cc_grp ownership1 sizecat urban_cd hospital_beds_per_res per_cap_inc_2009
/dist = bin link=logit solution;
nloptions maxiter = 50 tech=nrridg;
random intercept / subject = pos1;
random intercept / subject = region1;
run;
proc glimmix data=table5 initglm;
class pos1 monitor_pan ownership1 sizecat region1 agecat;
model icu_stay_ind = monitor_pan agecat re_white cancer cc_grp ownership1 sizecat region1
/dist = bin link=logit solution;
nloptions maxiter = 50 tech=nrridg;
random intercept / subject = pos1;
run;
proc glimmix data=table5 initglm;
class pos1 monitor_pan ownership1 sizecat region1 agecat;
model hosp_adm_ind = monitor_pan agecat re_white cancer cc_grp ownership1 sizecat region1
/dist = bin link=logit solution;
nloptions maxiter = 50 tech=nrridg;
random intercept / subject = pos1;
run;
proc glimmix data=table5;
class pos1 pan_efd agecat re_white cancer cc_grp ownership1 sizecat region1;
model ip_ed_visit_ind (event='1') = pan_efd agecat re_white cancer cc_grp ownership1 sizecat region1
/solution dist = bin link=logit ddfm = satterth oddsratio ;
random intercept / subject = pos1 solution;
nloptions tech=nrridg;
ods exclude solutionr;
run;
proc glimmix data=table5;
class pos1 pan_efd agecat re_white cancer cc_grp ownership1 sizecat region1;
model icu_stay_ind (event='1') = pan_efd agecat re_white cancer cc_grp ownership1 sizecat region1
/solution dist = bin link=logit ddfm = satterth oddsratio ;
random intercept / subject = pos1 solution;
nloptions tech=nrridg;
ods exclude solutionr;
run;
proc glimmix data=table5 order=data;
class pos1 pan_efd agecat re_white cancer cc_grp ownership1 sizecat region1;
model hosp_adm_ind (event='1') = pan_efd agecat re_white cancer cc_grp ownership1 sizecat region1
/solution dist = bin link=logit ddfm = satterth oddsratio ;
random intercept / subject = pos1 solution;
nloptions tech=nrridg;
ods exclude solutionr;
run;


%let varlist1 = smd_on_call pan_efd symp_efd poc_gocall3 fp_all3;
/*%let varlist2 = ip_ed_visit_ind hosp_adm_ind icu_stay_ind;*/
%macro regression();
%let i = 1;
%let var=%scan(&varlist1,&i);
%do %while(&var ne ) ;
proc genmod data=table5 descending;
class pos1 ip_ed_visit_ind (ref = '0') &var (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = &var female agecat re_white cancer cc_grp ownership1 sizecat region1
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
class pos1 ip_ed_visit_ind (ref = '0') &var (ref = '0')
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
class pos1 ip_ed_visit_ind (ref = '0') &var (ref = '0')
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
%let var=%scan(&varlist,&i);
%end;
%mend;
ods html close;
ods html;
ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\covariatetables.rtf";
%regression;
ods rtf close;
%let varlist1 = smd_on_call pan_efd symp_efd poc_gocall3 fp_all3;
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




























ods html close;
ods html;
proc genmod data=table5 descending;
class pos1 ip_ed_visit_ind (ref = '0') pan_efd (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = pan_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald ;
repeated subject=pos1/type=exch;
run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
proc genmod data=table5 descending;
class pos1 hosp_adm_ind (ref = '0') pan_efd (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = pan_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
proc genmod data=table5 descending;
class pos1 ip_ed_visit_ind (ref = '0') smd_on_call(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = smd_on_call female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') smd_on_call(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = smd_on_call female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
prin_diag_cat1
proc genmod data=table5 descending;
class pos1 hosp_adm_ind (ref = '0') smd_on_call(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = smd_on_call female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;

proc genmod data=table5 descending;
class pos1 ip_ed_visit_ind (ref = '0') symp_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = symp_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" symp_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') symp_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = symp_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" symp_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1 hosp_adm_ind (ref = '0') symp_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = symp_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" symp_efd 1 -1 / exp;

run;

proc genmod data=table5 descending;
class pos1 ip_ed_visit_ind (ref = '0') poc_gocall3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = poc_gocall3 female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Patient GOC" poc_gocall3 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') poc_gocall3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = poc_gocall3 female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Patient GOC" poc_gocall3 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1 hosp_adm_ind (ref = '0') poc_gocall3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = poc_gocall3 female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Patient GOC" poc_gocall3 1 -1 / exp;
run;
proc genmod data=table5 descending;
class pos1 ip_ed_visit_ind (ref = '0') fp_all3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = fp_all3 female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. family GOC" fp_all3 1 -1 / exp;
run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') fp_all3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = fp_all3  female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. family GOC" fp_all3 1 -1 / exp;
run;
proc genmod data=table5 descending;
class pos1 hosp_adm_ind (ref = '0') fp_all3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = fp_all3 female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. family GOC" fp_all3 1 -1 / exp;
run;













ods html close;
ods html;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" pan_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female agecat re_white cancer cc_grp ownership1 sizecat 
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" pan_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female agecat re_white cancer cc_grp ownership1  region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" pan_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female agecat re_white cancer cc_grp  sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" pan_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female agecat re_white cancer  ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" pan_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female agecat re_white  cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" pan_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female agecat  cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" pan_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" pan_efd 1 -1 / exp;

run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
cancer (ref = '0') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" pan_efd 1 -1 / exp;

run;


data table6;
set table5;
if prin_diag_cat1 = 4;
run;
ods html close;
ods html;
proc genmod data=table6 descending;
class pos1 ip_ed_visit_ind (ref = '0') pan_efd (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = pan_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald ;
repeated subject=pos1/type=exch;
run;
proc genmod data=table6 descending;
class pos1  icu_stay_ind (ref = '0') pan_efd (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = pan_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
proc genmod data=table6 descending;
class pos1 hosp_adm_ind (ref = '0') pan_efd (ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = pan_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
proc genmod data=table6 descending;
class pos1 ip_ed_visit_ind (ref = '0') smd_on_call(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = smd_on_call female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
proc genmod data=table6 descending;
class pos1  icu_stay_ind (ref = '0') smd_on_call(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = smd_on_call female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
proc genmod data=table6 descending;
class pos1 hosp_adm_ind (ref = '0') smd_on_call(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
 CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = smd_on_call female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;

proc genmod data=table6 descending;
class pos1 ip_ed_visit_ind (ref = '0') symp_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = symp_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" symp_efd 1 -1 / exp;

run;
proc genmod data=table6 descending;
class pos1  icu_stay_ind (ref = '0') symp_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = symp_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" symp_efd 1 -1 / exp;

run;
proc genmod data=table6 descending;
class pos1 hosp_adm_ind (ref = '0') symp_efd(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = symp_efd female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Symptoms Every Few Days" symp_efd 1 -1 / exp;
run;

proc genmod data=table6 descending;
class pos1 ip_ed_visit_ind (ref = '0') poc_gocall3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
 CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = poc_gocall3 female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Patient GOC" poc_gocall3 1 -1 / exp;

run;
proc genmod data=table6 descending;
class pos1  icu_stay_ind (ref = '0') poc_gocall3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = poc_gocall3 female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Patient GOC" poc_gocall3 1 -1 / exp;

run;
proc genmod data=table6 descending;
class pos1 hosp_adm_ind (ref = '0') poc_gocall3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
 CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = poc_gocall3 female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. Patient GOC" poc_gocall3 1 -1 / exp;
run;
proc genmod data=table6 descending;
class pos1 ip_ed_visit_ind (ref = '0') fp_all3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = fp_all3 female agecat re_white cancer cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. family GOC" fp_all3 1 -1 / exp;
run;
proc genmod data=table6 descending;
class pos1  icu_stay_ind (ref = '0') fp_all3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = fp_all3  female agecat re_white  cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. family GOC" fp_all3 1 -1 / exp;
run;
proc genmod data=table6 descending;
class pos1 hosp_adm_ind (ref = '0') fp_all3(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = fp_all3 female agecat re_white cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
estimate "log O.R. family GOC" fp_all3 1 -1 / exp;
run;




/************** MELISSA REQUEST ON 8/1/14 *****************/
proc freq data=table5;
table prin_diag_cat1;
run;
proc genmod data=table5 descending;
class pos1 ip_ed_visit_ind (ref = '0') smd_on_call(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
prin_diag_cat1 (ref = '1') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model ip_ed_visit_ind = smd_on_call female agecat re_white prin_diag_cat1 cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
proc genmod data=table5 descending;
class pos1  icu_stay_ind (ref = '0') smd_on_call(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
prin_diag_cat1 (ref = '1') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model icu_stay_ind = smd_on_call female agecat re_white prin_diag_cat1 cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;

proc genmod data=table5 descending;
class pos1 hosp_adm_ind (ref = '0') smd_on_call(ref = '0')
ownership1 (ref = '2') agecat(ref = '1') re_white (ref = '0') 
prin_diag_cat1 (ref = '1') CC_grp(ref = '0') sizecat(ref = '1') 
region1 (ref = '3') / param = ref;
model hosp_adm_ind = smd_on_call female agecat re_white prin_diag_cat1 cc_grp ownership1 sizecat region1
/dist=bin link=logit type3 wald;
repeated subject=pos1/type=exch;
run;
