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
data ccw.providers;
set providers4;
run;
