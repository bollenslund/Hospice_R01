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
data hsurvey;
set ccw.hsurvey_r01_1;
flag = 1;
run;
proc sql;
create table providers1
as select a.*, b.flag
from providers a
left join hsurvey b
on a.pos1 = b.pos1;
quit;
proc freq data=providers1;
table flag;
run;
proc sort data=providers1 out=providers1a;
by bene_id CLM_FROM_DT;
run;
data providers1b;
set providers1a;
by bene_id;
retain pos_change;
diff = pos1 - lag(pos1);
if diff ~= 0 then do; pos_change = pos_change+1; end;
if first.bene_id then pos_change = 0;
run;
data nos_change;
set providers1b (keep = bene_id pos_change);
by bene_id; 
if last.bene_id;
run;
proc freq data=nos_change;
table pos_change;
run;
proc sort data=providers1;
by bene_id descending CLM_FROM_DT;
run;
data providers2;
set providers1;
if flag = 1;
drop flag;
run;
proc sort data=providers2 out=providers3 nodupkey;
by bene_id;
run;
proc sql;
create table providers4
as select *
from providers3 a
left join nos_change b
on a.bene_id = b.bene_id;
quit;
proc freq data=providers5;
table pos_change;
run;
data ccw.providers;
set providers4;
rename pos1 = provider_id;
run;
ods rtf body = '\\home\users$\leee20\Documents\Downloads\Melissa\providers.rtf';
proc contents data=ccw.providers varnum;
run;
ods rtf close;

proc sql;
create table ccw.Final_hs_mb_mp_op_dhc_dod_cc_p
as select a.*, b.provider_id, b.pos_change
from ccw.Final_hs_mb_ip_snf_op_dhc_dod_cc a
left join ccw.providers b
on a.bene_id = b.bene_id;
quit;
