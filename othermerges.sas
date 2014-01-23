libname costs 'J:\Geriatrics\Geri\Hospice Project\Hospice\Costs\data';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';
libname ref 'J:\Geriatrics\Geri\Hospice Project\Hospice\Reference';

data hospice;
set ccw.final1;
statenum = input(STATE_CODE,2.);
countynum = input(BENE_COUNTY_CD,3.);
run;

data ahrf;
set ccw.ahrf;
statenum = substr(SSA_stat_County,1,2);
countynum = substr(SSA_stat_County,3,3);
run;

proc sql;
create table pid_county4
as select *
from pid_county3 a
left join ahrf b
on a.countynum = b.countynum
and a.statenum =  b.statenum;
quit;

proc sql;
create table hospice_add
as select *
from ccw.final1 a
left join pid_county4 b
on a.provider = b.pid;
;
quit;
proc freq data=hospice_add;
table RPT_REC_NUM;
run;
/*only 49% of the people in the hospice files match the people from the ahrf/cost files*/

data test;
set Hospicecosts20101;
if PRVDR_NUM = 101539 or PRVDR_NUM = 451705;
run;
/*a value exists here. May be something wrong with the original coding*/
data test;
set Hospicecosts20103;
if RPT_REC_NUM = 25548;
run;
