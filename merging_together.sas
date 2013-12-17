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
