data final_hs;
set ccw.final_hs;
drop BENE_RACE_CD re_white re_black re_other re_asian re_hispanic re_na re_unknown female;
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
if BENE_RACE_CD = 3 then re_other =1;
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
