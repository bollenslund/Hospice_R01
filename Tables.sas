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
if TOT_GRP = 0 then CC_grp = 0;
if TOT_GRP = 1 then CC_grp = 1;
if TOT_GRP = 2 then CC_grp = 2;
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
logtotalcosts = log(totalcosts + 1);
run;

ods rtf body = "J:\Geriatrics\Geri\Hospice Project\exp.rtf";
proc univariate data=table3;
var totalcosts;
histogram;
run;
proc univariate data=table3;
var logtotalcosts;
histogram;
run;
ods rtf close;

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

/*those who have no costs*/
data zerocost;
set table3;
if totalcosts = 0;
run;
/*these people have charges. Total of 308*/




TOT_GRP (total CCI groups per record)
op_visit (total number of outpatient visits)
op_ed_count (total number of outpatient ED visits)
op_cost (total outpatient costs)
snf_adm_ind (Admission into SNF indicator)
snf_adm_days (total number of SNF days)
snf_adm_cnt (number of admissions)
snf_cost (SNF total cost)
hosp_adm_cnt (number of admissions to Hospital)
ip_ed_visit_cnt (total number of inpatient visits)
hosp_adm_days (number of days)
hosp_death (death in hospital)
icu_stay_cnt (number of stays in icu)
icu_stay_days (number of days in icu)
ip_tot_cost (total costs in inpatient)
total_651 (total number in routine home care)
total_656 (general inpatient care hospice services)
