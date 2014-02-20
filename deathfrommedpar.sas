libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';
libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';

proc freq data=merged.Medpar_all_file;
table BENE_DSCHRG_STUS_CD DSCHRG_DSTNTN_CD /missprint;
run;

/*only keep obs where the death date is filled in*/
data medpar;
set merged.Medpar_all_file;
if BENE_DEATH_DT ~=.;
run;
proc freq data=medpar;
table DSCHRG_DSTNTN_CD;
run;
proc sort data=medpar out=medpar1;
by bene_id descending bene_death_dt;
run;
data medpar1;
set medpar1 (keep = bene_id DSCHRG_DT BENE_DEATH_DT);
medpardeath = bene_death_dt;
drop bene_death_dt;
label medpardeath = "Date Beneficiary Died";
format medpardeath date9.;
run;
data test;
set medpar1;
if bene_id = 'ZZZZZZZ3ppIuZ4I' or bene_id = 'ZZZZZZZk3pI44yy';
run;
proc sort data=medpar1 out=medpar2 nodupkey;
by bene_id;
run;

/*saves dataset with medpar death dates, using the bene_death_dt field*/
data ccw.deathfrommedpar;
set medpar2;
run;

data hospice_raw;
set merged.Hospice_base_claims_j;
if PTNT_DSCHRG_STUS_CD = "40"|PTNT_DSCHRG_STUS_CD = "41"|PTNT_DSCHRG_STUS_CD = "40";
rawhospice = CLM_THRU_DT;
run;
proc sql;
create table zzztest3e
as select a.*, b.rawhospice
from zzztest3d a
left join hospice_raw b
on a.bene_id = b.bene_id;
quit;

data hospice_raw1;
set ccw.final2;
if bene_id = 'ZZZZZZZ39ZOIukO';
run;
