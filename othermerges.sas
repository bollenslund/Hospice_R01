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
statenum1 = input(statenum, 2.);
countynum1 = input(countynum, 3.);
drop statenum countynum;
run;

proc sql;
create table hosp_ahrf
as select *
from hospice a
left join ahrf b
on a.countynum = b.countynum1
and a.statenum =  b.statenum1;
quit;

data hosp_ahrf1;
set hosp_ahrf;
drop statenum countynum fips_stat_county state cens_reg_cd cens_div_cd fed_reg_cd;
run;

proc sql;
create table hosp_ahrf2
as select *
from hosp_ahrf1 a
left join ccw.Charlson b
on a.bene_id = b.bene_id;
quit;

data ccw.final1;
set hosp_ahrf2;
run;

ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\newvar.rtf";
title "IP Hospital visits before Hospice visits";
proc tabulate data=hosp_ahrf2;
var admit_pre12m;
table admit_pre12m, n mean min max median;
run;
title "Charlson Score";
proc tabulate data=hosp_ahrf2;
var CC_GRP_1-CC_GRP_17 Dx_count TOT_GRP charlson_index;
table (CC_GRP_1-CC_GRP_17 Dx_count TOT_GRP charlson_index ),(n mean min max median);
run;
title "County Group information";
proc tabulate data=hosp_ahrf2;
var beds_2009 nursing_beds_2009 per_cap_inc_2009;
table (beds_2009 nursing_beds_2009 per_cap_inc_2009),(n mean min max median);
run;
ods rtf close;
