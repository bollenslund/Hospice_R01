data final_hs;
set ccw.final_hs;
drop BENE_RACE_CD re_white re_black re_other re_asian re_hispanic re_na re_unknown female BENE_CNTY_CD BENE_STATE_CD BENE_MLG_CNTCT_ZIP_CD DOB_DT;
run;

proc freq data=final_hs;
table start21;
run;

data final_mb_cc;
set ccw.mb_final_cc;
drop lengthmedi lengthmo allmedistatus1 allhmostatus1 allmedistatus2 allhmostatus2 allmedistatus3 allhmostatus3;
re_white = 0; re_black = 0; re_other = 0; re_asian = 0; re_hispanic = 0; re_na = 0; re_unknown = 0;
if BENE_RACE_CD = 1 then re_white = 1;
if BENE_RACE_CD = 2 then re_black = 1;
if BENE_RACE_CD = 3 then re_other = 1;
if BENE_RACE_CD = 4 then re_asian = 1;
if BENE_RACE_CD = 5 then re_hispanic = 1;
if BENE_RACE_CD = 6 then re_na = 1;
if BENE_RACE_CD = 0 then re_unknown = 1;
label re_white = "White race / ethnicity";
label re_black = "Black race / ethnicity";
label re_other = "Other race / ethnicity";
label re_asian = "Asian race / ethnicity";
label re_hispanic = "Hispanic race / ethnicity";
label re_na = "Native American race / ethnicity";
label re_unknown = "Unknown race / ethnicity";
run;

data final_inpat;
set ccw.ip_snf;
drop BENE_ENROLLMT_REF_YR FIVE_PERCENT_FLAG ENHANCED_FIVE_PERCENT_FLAG COVSTART CRNT_BIC_CD 
STATE_CODE BENE_COUNTY_CD BENE_ZIP_CD BENE_AGE_AT_END_REF_YR BENE_BIRTH_DT BENE_DEATH_DT NDI_DEATH_DT BENE_SEX_IDENT_CD BENE_RACE_CD BENE_VALID_DEATH_DT_SW start end;
run;

data final_outpat;
set ccw.outpat_fin;
run;

data final_dmehhacarr;
set ccw.dmehhacarr;
drop clm_id;
run;

proc sql;
create table final
as select *
from final_hs a
left join final_mb_cc b
on a.bene_id = b.bene_id;
quit;

data test;
set final;
if discharge = 40 then do;
ddiff40_1 = end - NDI_DEATH_DT;
if NDI_DEATH_DT = . then do;
ddiff40_1 = end - BENE_DEATH_DT;
end;
end;
if discharge = 41 then do;
ddiff40_1 = end - NDI_DEATH_DT;
if NDI_DEATH_DT = . then do;
ddiff41_1 = end - BENE_DEATH_DT;
end;
end;
if discharge = 42 then do;
ddiff40_1 = end - NDI_DEATH_DT;
if NDI_DEATH_DT = . then do;
ddiff42_1 = end - BENE_DEATH_DT;
end;
end;
run;
proc freq data=test;
table ddiff40_1 ddiff41_1 ddiff42_1;
run;
/*I did separately to see if any one of the discharge codes lead to more
discrepancy in the death date. Turns out, death dates do not entirely correlate
with one another between Hospice and MB files. Problem?*/
data zzztest;
set test (keep = bene_id start end discharge BENE_DEATH_DT ddiff40_1);
if ddiff40_1 < 0 AND ddiff40_1 ~= .;
run;
/*most of the differences seem to be around -1 which is one day off. Maybe it's a systematic thing
between the two different reports*/
data zzztest1;
set test (keep = bene_id start end discharge BENE_DEATH_DT ddiff40_1);
if ddiff40_1 < -1 AND ddiff40_1 ~= .;
run;
/*600 with differences > 2. Majority of the people have death dates in the Master Beneficiary that's in the last day so of the
month. This is probalby another systematic thing that we should probably discuss, but for now, I'm thinking that the Hospice date of death
might be more accurate. Thoughts?*/
data zzztest2;
set final;
if bene_id = 'ZZZZZZZOyZuO9O3';
run;
/*only thing I haven't really done yet is linking location data. If you're busy I will work on this when I get back. Melissa did
not come today to the office, so I didn't receive any update from her. I'll be checking my email during break. Feel free to email
or text me if you have any follow up questions.*/


proc sql;
create table final1
as select *
from final a
left join final_inpat b
on a.bene_id = b.bene_id;
quit;

proc freq data=final_inpat;
	where IP_death1 ~= .;
	table IP_death1;
RUN;

proc freq data=final1;
	where IP_death1 ~= .;
	table IP_death1;
RUN;

proc sql;
create table final2
as select *
from final1 a
left join final_outpat b
on a.bene_id = b.bene_id;
quit;

proc sql;
create table final3
as select *
from final2 a
left join final_dmehhacarr b
on a.bene_id = b.bene_id;
quit;

data final3;
set final3;
ip_op_ed_cnt = ip_ed_visit_cnt + op_ed_count;
label ip_op_ed_cnt = "Total ED visits from IP and OP claims";
run;

proc freq data=final3;
table ip_op_ed_cnt;
run;

data ccw.final;
set final3;
run;


/*Look at the race variable*/
proc freq data=final_hs;
table BENE_RACE_CD;
run;

proc freq data=final_mb;
table BENE_RACE_CD;
run;

data final_hs_race;
set final_hs (keep=bene_id bene_race_cd);
race1 = bene_race_cd + 0;
drop bene_race_cd;
run;
data final_mb_race;
set final_mb (keep=bene_id bene_race_cd);
race2 = bene_race_cd + 0;
drop bene_race_cd;
run;
proc sql;
create table race_diff
as select *
from final_hs_race a
left join final_mb_race b
on a.bene_id = b.bene_id;
quit;
data race_diff;
set race_diff;
diff = race2 - race1;
run;
proc freq data=race_diff;
table diff;
run;
data zzzztest;
set race_diff;
if diff ~= 0;
if race1 ~= .;
run;
data ccw.race;
set zzzztest;
run;
/*rebecca please take a look at this*/

/*negative costs*/

data costs;
set ccw.final;
if ip_tot_cost < 0;
run;

data medpar;
	set merged.medpar_all_file;
run;

data costs1;
set medpar;
if bene_id = 'ZZZZZZZ3IOZkyyk' or bene_id = 'ZZZZZZZ3OZIIOOu' or bene_id = 'ZZZZZZZ3pu9uyyy' or bene_id = 'ZZZZZZZOZuI3puu' or bene_id = 'ZZZZZZZOypO9pOI' or bene_id = 'ZZZZZZZypZZ9ku4';
run;

proc contents data=costs1 varnum;
run;

proc sort data=costs1;
by BENE_ID ADMSN_DT;
run;

proc sql;
create table costs2
as select a.*, b.start, b.end
from costs1 a
left join ccw.for_medpar b
on a.bene_id = b.bene_id;
run;

data costs2;
set costs2;
if admsn_dt >= start;
run;

proc freq data=base_cost;
table CLM_PMT_AMT;
run;

data costs_out;
set base_cost1;
if inhospice_cost1 < 0 or posthospice_cost1 < 0;
run;

/** changing those with DEC 31st Discharge date and coded still patient when discharged*/

data hospice1;
set ccw.final;
if end = '31DEC2010'd then do;
if discharge = 30 then disenr = 0;
end;
run;

proc freq data=ccw.final;
table disenr;
run;
proc freq data=hospice1;
table disenr;
run;

data ccw.final1;
set hospice1;
run;

data hospice3;
set ccw.final1;
if discharge = 1;
run;

proc freq data=hospice3;
table count_hs_stays;
run;
proc freq data=ccw.final1;
table count_hs_stays;
run;

data hospice3a;
set hospice3;
if count_hs_stays > 1 and hs1_death = 0;
hospice_death = 0;
run;

%macro death;
%do i = 2 %to 21;
	data hospice3a;
	set hospice3a;
	if discharge&i = 40 or discharge&i = 41 or discharge&i = 42 then hospice_death = 1;
	run;
%end;
%mend;
%death;

proc freq data=hospice3a;
table hospice_death;
run;

/*means for hospice*/

proc means data=ccw.final1;
var disenr;
run;
