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

proc means data=pt_level;
var disenr_to_death;
run;

proc sql;
create table hsp_level
as select pos1 as Hospital_ID, count(*) as Num_pts_in_Sample, mean(hosp_adm_ind)*100 as Pct_Hospitalized, mean(ed_visit_ind)*100 as Pct_ED, mean(icu_stay_ind)*100 as Pct_ICU, mean(hosp_death)*100 as Pct_Hospital_Death,
mean(death_hospice)*100 as Pct_Hospice_Death, mean(hospital_death)*100 as Pct_Hosp_Hsp_Death, mean(disenr)*100 as Pct_Disenrolled, avg(disenr_to_death) as Avg_Num_days_disenr_to_Death, 
avg(hosp_adm_days) as Avg_num_hosp_days, avg(ed_count_total) as Avg_num_ED_visits, avg(icu_stay_days) as Avg_num_ICU_days, avg(total_los) as Avg_Hospice_LOS, STD(total_los) as SD_Hospice_LOS,
avg(age_at_enr) as Avg_Age, mean(female)*100 as Pct_Female, mean(re_white)*100 as Pct_White, mean(cancer)*100 as Pct_cancer, mean(mental_dis)*100 as Pct_Mental_Disorder, mean(nervous_dis)*100 as Pct_Nervous_Disorder,
mean(circ_dis)*100 as Pct_Circulatory_Disorder, mean(resp_dis)*100 as Pct_Respiratory_Disorder, mean(symp_dis)*100 as Pct_Symp_Sign_Illness, mean(other_dis)*100 as Pct_Other_Disorders, avg(CC_Count) as Avg_Num_CC,
mean(ccgrp1)*100 as Pct_greater_2_CC
from pt_level
group by pos1;
quit;
ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\Hospice_Level_Variables.rtf";
proc univariate data=hsp_level;
histogram;
run;
ods rtf close;
proc sql;
create table hsp_level1
as select *
from hsp_level a
left join ccw.Hsurvey_r01_1 b
on a.Hospital_ID = b.pos1;
quit;

data ccw.hospice_level_numbers;
set hsp_level1;
run;
