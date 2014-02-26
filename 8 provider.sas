libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';
libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10'; 
libname hospices 'J:\Geriatrics\Geri\Hospice Project';
libname costs 'N:\Documents\Downloads\Melissa\Hospice_Cost_Data\data';


data work.hospice_base;
        set merged.hospice_base_claims_j;
run;        
/*all hopsices from our claims data*/

data providers;
set hospice_base(keep = bene_id CLM_FROM_DT PRVDR_NUM);
pos1 = PRVDR_NUM + 0;
run;
proc sort data=providers out=providers1;
by bene_id descending CLM_FROM_DT;
run;
data hsurvey;
set ccw.hsurvey_r01_1;
flag = 1;
run;
proc sql;
create table providers2
as select a.*, b.flag
from providers1 a
left join hsurvey b
on a.pos1 = b.pos1;
quit;
proc freq data=providers2;
table flag;
run;
proc sort data=providers2 out=providers2a nodupkey;
by bene_id pos1;
run;
data providers2b;
set providers2a;
by bene_id;
retain pos_change;
pos_change = pos_change+1;
if first.bene_id then pos_change = 0;
run;
data nos_change;
set providers2b (keep = bene_id pos_change);
by bene_id; 
if last.bene_id;
run;
proc freq data=nos_change;
table pos_change;
run;
proc sort data=providers2;
by bene_id descending CLM_FROM_DT;
run;
data providers3;
set providers2;
if flag = 1;
run;
proc sort data=providers3 out=providers4 nodupkey;
by bene_id;
run;
proc sql;
create table providers5
as select *
from providers4 a
left join nos_change b
on a.bene_id = b.bene_id;
quit;
proc freq data=providers5;
table pos_change;
run;
data ccw.providers;
set providers4;
run;

proc sql;
create table ccw.Final_hs_mb_mp_op_dhc_dod_cc_p
as select a.*, b.pos1
from ccw.Final_hs_mb_ip_snf_op_dhc_dod_cc a
left join ccw.providers b
on a.bene_id = b.bene_id;
quit;
