data pt_level;
set ccw.Ltd_vars_for_analysis1;
drop county_state beds_2009 nursing_beds_2009 per_cap_inc_2009 Census_Pop_2010 urban_cd;
if hosp_adm_ind = 0 then hosp_adm_days = .;
if icu_stay_ind = 0 then icu_stay_days = .;
if ed_visit_ind = 0 then ed_count_total = .;
ccgrp1 = 0;
if cc_grp = 2 then ccgrp1 = 1;
mental_dis = 0;
if prin_diag_cat1 = 2 then mental_dis = 1;
nervous_dis = 0;
if prin_diag_cat1 = 3 then nervous_dis = 1;
circ_dis = 0;
if prin_diag_cat1 = 4 then circ_dis = 1;
resp_dis = 0;
if prin_diag_cat1 = 5 then resp_dis = 1;
symp_dis = 0;
if prin_diag_cat1 = 6 then symp_dis = 1;
other_dis = 0;
if prin_diag_cat1 = 7 then other_dis = 1;
run;
proc freq data=pt_level;
table cc_count;
run;
proc sort data=pt_level;
by POS1;
run;
proc means data=pt_level median;
var disenr_to_death total_los;
output out = stats;
output out = medians median =;
by pos1;
run;
data stats;
set stats medians(in=in2);
by _type_;
if in2 then _STAT_ = 'MEDIAN';
run;
proc means data=pt_level median;
where pos1 = 11548;
var disenr_to_death total_los;
run;

proc sql;
create table pt_level1
as select *
from pt_level a
left join ccw.beforeafterhospice b
on a.bene_id = b.bene_id;
quit;

proc freq data=pt_level1;
table ed_visit_ind ed_during_hosp ed_after_hosp hdeath_during_hosp hdeath_after_hosp hosp_death;
run;

proc sql;
create table hsp_level
as select pos1 as Hospital_ID, count(*) as Num_pts_in_Sample, mean(hosp_adm_ind)*100 as Pct_Hospitalized, mean(hospital_during_hosp)*100 as Pct_Hospitalized_during_Hospice, mean(hospital_after_hosp)*100 as Pct_Hospitalized_after_Hospice,
mean(ed_visit_ind)*100 as Pct_ED, mean(ed_during_hosp)*100 as Pct_ED_During_Hospice, mean(ed_after_hosp)*100 as Pct_ED_After_Hospice, mean(icu_stay_ind)*100 as Pct_ICU, mean(icu_during_hosp)*100 as Pct_ICU_During_Hospice, mean(icu_after_hosp)*100 as Pct_ICU_After_Hospice, 
mean(hosp_death)*100 as Pct_Hospital_Death, mean(hdeath_during_hosp)*100 as Pct_Hospital_Death_During, mean(hdeath_after_hosp)*100 as Pct_Hospital_Death_After, mean(death_hospice)*100 as Pct_Hospice_Death, mean(hospital_death)*100 as Pct_Hosp_Hsp_Death, mean(disenr)*100 as Pct_Disenrolled, avg(disenr_to_death) as Avg_Num_days_disenr_to_Death, 
avg(hosp_adm_days) as Avg_num_hosp_days, avg(ed_count_total) as Avg_num_ED_visits, avg(icu_stay_days) as Avg_num_ICU_days, avg(total_los) as Avg_Hospice_LOS, STD(total_los) as SD_Hospice_LOS,
avg(age_at_enr) as Avg_Age, mean(female)*100 as Pct_Female, mean(re_white)*100 as Pct_White, mean(cancer)*100 as Pct_cancer, mean(mental_dis)*100 as Pct_Mental_Disorder, mean(nervous_dis)*100 as Pct_Nervous_Disorder,
mean(circ_dis)*100 as Pct_Circulatory_Disorder, mean(resp_dis)*100 as Pct_Respiratory_Disorder, mean(symp_dis)*100 as Pct_Symp_Sign_Illness, mean(other_dis)*100 as Pct_Other_Disorders, avg(CC_Count) as Avg_Num_CC,
mean(ccgrp1)*100 as Pct_greater_2_CC, mean(
from pt_level1
group by pos1;
quit;
ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\Hospice_Level_Variables.rtf";
proc univariate data=hsp_level;
histogram;
run;
ods rtf close;
proc sql;
create table hsp_level1
as select b.*, a.*
from ccw.Hsurvey_r01_1 a
left join hsp_level b
on a.pos1 = b.Hospital_ID;
quit;
data hsp_level1;
set hsp_level1;
hospital_id = pos1;
run;
proc sql;
create table hsp_level2
as select a.*, b.disenr_to_death as Median_Num_Days_Disenr_to_Death, b.total_los as Median_LOS
from hsp_level1 a
left join medians b
on a.hospital_id = b.POS1;
quit;
data ccw.hospice_level_numbers;
set hsp_level2;
run;
proc contents data=ccw.hospice_level_numbers varnum out = var_list;
run;
proc export data=var_list outfile = "\\home\users$\leee20\Documents\Downloads\Melissa\varlist.csv" dbms = csv replace;
run;

/*testing to see where some of the hospices went*
proc sql;
select sum(Num_pts_in_Sample)
from hsp_level;
quit;
data hospice;
set ccw.hsurvey_r01_1;
indic = 1;
run;
data all_claims;
set merged.hospice_base_claims_j (keep = CLM_ID PRVDR_NUM);
provider = prvdr_num + 0;
run;
proc sql;
create table all_claims1
as select a.*, b.indic
from all_claims a
left join hospice b
on a.provider = b.pos1;
quit;
data all_claims1;
set all_claims1;
if indic ~=.;
run;
proc sort data=all_claims1;
by provider;
run;
proc sql;
create table all_claims2
as select provider as Hospital_ID, count(*) as number
from all_claims1
group by provider;
quit;

proc sort data=all_claims2 out=all_claims3;
by number;
run;
proc sort data=hsp_level out=hsp_level_sort;
by Num_pts_in_Sample;
run;

proc sql;
create table all_claims4
as select a.*, b.Num_pts_in_Sample
from all_claims3 a
left join hsp_level_sort b
on a.Hospital_ID = b.hospital_id;
quit;
proc sort data=all_claims4;
by number;
run;
*/
/*three hospitals are in the claims database, but are not in the final sample*/

/*now getting a list of the hospitals without claims data*/
/*
data hsp_level_no_data;
set hsp_level1;
if Num_pts_in_Sample = .;
j = 1;
run;
proc sql;
create table hsp_level_no_data1
as select a.*, b.j
from ccw.Hsurvey_r01_1 a 
left join hsp_level_no_data b
on a.pos1 = b.hospital_id;quit;
data hsp_level_no_data1;
set hsp_level_no_data1;
if j = 1;
run;

data ccw.hospices_with_no_claims;
set hsp_level_no_data1;
run;
*/

