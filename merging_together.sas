data final_hs;
set ccw.final_hs;
run;

proc freq data=final_hs;
table start21;
run;

data final_mb;
set ccw.mb_final;
drop lengthmedi lengthmo allmedistatus1 allhmostatus1 allmedistatus2 allhmostatus2 allmedistatus3 allhmostatus3;
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
left join final_mb b
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

data ccw.final;
set final3;
run;
