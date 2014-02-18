/********************************************************************/
/******** Check MBS death date  vs hospice claims disch date ********/
/********************************************************************/
/*section to check death dates from mbs and discharge codes from hospice claims
Death date should be coded as discharge dates for beneficiaries that die in hospice
for mbs death date, use NDI death date, if missing use non NDI verified death date*/
data test;
set ccw.final2;
if discharge = 40 then ddiff_1 = dod_clean - end;
if discharge = 41 then ddiff_1 = dod_clean - end;
if discharge = 42 then ddiff_1 = dod_clean - end;
run;
/*obs that did not die during hospice stay per discharge code, but per dod they did **2386 obs*/
proc freq data=test;
table ddiff_1;
run;
data testest;
set test;
if discharge = 30 and disenr = 0;
run;
/*discharge2-discharge10 as well as discharge 14 and 21 all have codes 40-42. I will give them date of deaths based on their discharge codes*/
data zzztest3;
set test;
ddiff_didnotdie = dod_clean - end;
if (discharge2 = 40|discharge2 = 41|discharge2 = 42) then dod_clean = end2;
if (discharge3 = 40|discharge3 = 41|discharge3 = 42) then dod_clean = end3;
if (discharge4 = 40|discharge4 = 41|discharge4 = 42) then dod_clean = end4;
if (discharge5 = 40|discharge5 = 41|discharge5 = 42) then dod_clean = end5;
if (discharge6 = 40|discharge6 = 41|discharge6 = 42) then dod_clean = end6;
if (discharge7 = 40|discharge7 = 41|discharge7 = 42) then dod_clean = end7;
if (discharge8 = 40|discharge8 = 41|discharge8 = 42) then dod_clean = end8;
if (discharge9 = 40|discharge9 = 41|discharge9 = 42) then dod_clean = end9;
if (discharge10 = 40|discharge10 = 41|discharge10 = 42) then dod_clean = end10;
if (discharge14 = 40|discharge14 = 41|discharge14 = 42) then dod_clean = end14;
if (discharge21 = 40|discharge21 = 41|discharge21 = 42) then dod_clean = end21;
run;

/*date of death from places outside of hospice*/
proc freq data = zzztest3;
table dod_clean hosp_death snf_death/missprint;
run;
/*macro to bring these dates in*/
%macro deathdate;
%do i = 1 %to 39;
data zzztest3;
set zzztest3;
if IP_death&i = 1 then ip_deathdate = IP_end&i;
run;
%end;
%do i = 1 %to 12;
data zzztest3;
set zzztest3;
if snf_death&i  = 1 then snf_deathdate = snf_end&i;
run;
%end;
%mend;
%deathdate;
/*test to see if there's an entry for date of death for ip and snf. There is 5 beneficiaries that do, but I'll make IP death date a priority*/
data zzzztest;
set zzztest3;
if ip_deathdate ~= . and snf_deathdate ~= .; 
run;
/*putting the death dates for those in IP and SNF. Total with date of death is now 13969*/
data zzztest3a;
set zzztest3;
if dod_clean = . and ip_deathdate ~=. then dod_clean = ip_deathdate;
if dod_clean = . and snf_deathdate ~=. then dod_clean = snf_deathdate;
run;
proc freq data=zzztest3a;
table dod_clean;
run;
/*bring in date of death from medpar to see if i am missing death dates*/
proc sql;
create table zzztest3b
as select a.*, b.medpardeath
from zzztest3a a
left join ccw.Deathfrommedpar b
on a.bene_id = b.bene_id;
quit;
proc freq data=zzztest3b;
table medpardeath;
run;
data zzztest3c;
set zzztest3b;
if dod_clean = . and medpardeath ~=. then dod_clean = medpardeath;
run;
proc freq data=zzztest3c;
table dod_clean;
run;

/*total of 16120 people have death dates now. Still 6858 without death dates*/

/*look at those without death dates*/
data zzztest3d;
set zzztest3c;
if dod_clean = .;
run;
data ccw.deathdraft;
set zzztest3c;
run;
/*of these 27 have date of death conflict where death date is earlier than hs discharge date. Total of 2359 have death dates exactly on that day. Turn them into disenrolled*/
data zzztest4;
set zzztest3c (keep = bene_id ddiff_1 start end discharge disenr dod_clean ddiff_didnotdie);
if ddiff_didnotdie<= 0 & ddiff_didnotdie~=. then disenr1 = 0;
dod_clean1 = dod_clean;
format dod_clean1 date9.;
run;

proc freq data=zzztest4;
table disenr;
run;

/*obs where dod before hospice death date: 150 obs. Turn all dod_clean to end.*/
data zzztest5;
set test (keep = bene_id start end discharge dod_clean ddiff_1);
if (ddiff_1 < 0 AND ddiff_1 ~= .);
mod_death = 1;
dod_clean = end;
drop ddiff_1;
run;

/*obs where dod after hospice death date: 1790 obs*/
data zzztest6;
set test (keep = bene_id start end discharge dod_clean ddiff_1);
if (ddiff_1 > 0 AND ddiff_1 ~= .);
mod_death = 1;
dod_clean = end;
drop ddiff_1;
run;

/*bring two together and get a total of 1940*/
proc append base=zzztest5 data=zzztest6; run;
data zzztest6;
set zzztest5;
dod_clean1 = dod_clean;
format dod_clean1 date9.;
run;
/*merge with mbs*/
proc sql;
create table zzztest7
as select a.*, b.dod_clean1
from ccw.final_mb_cc a
left join zzztest6 b
on a.bene_id = b.bene_id;
quit;
data zzztest8;
set zzztest7;
if dod_clean1 ~= . then do;
dod_clean = dod_clean1;
dod_ndi_ind = 2;
end;
drop dod_clean1;
run;
/*all 1940 people had date of death corrected*/
proc freq data=zzztest8;
table dod_ndi_ind;
run;
proc sql;
create table zzztest9
as select a.*, b.dod_clean1, b.disenr1
from zzztest8 a
left join zzztest4 b
on a.bene_id = b.bene_id;
quit;
data zzzztest;
set zzztest9;
if dod_clean1 ~= . then do;
dod_clean = dod_clean1;
dod_ndi_ind = 3;
end;
drop dod_clean1;
run;
proc freq data=zzzztest;
table dod_ndi_ind;
run;
proc freq data=zzzztest;
table dod_clean;
run;
/*
proc append base=zzztest1 data=zzztest2; run;

data zzztest1a;
set zzztest1;
if ddiff40_1 ~=. and ddiff41_1 = . and ddiff42_1 = . then ddiff = ddiff40_1;
if ddiff40_1 =. and ddiff41_1 ~= . and ddiff42_1 = . then ddiff = ddiff41_1;
if ddiff40_1 =. and ddiff41_1 = . and ddiff42_1 ~= . then ddiff = ddiff42_1;
dayofmonth = day(dod_clean);
month = month(dod_clean);
if month = 4 | month = 6 | month = 9 | month = 11 then _30day = 1;
if month = 2 then _30day = 0;
if month = 1 | month = 3 | month = 5 | month = 7 | month = 8 | month = 10 | month = 12 then _30day = 2;
drop ddiff40_1 ddiff41_1 ddiff42_1;
run;
proc sort data=zzztest1a out=zzzsort; by _30day;
run;
proc freq data=zzzsort;
table dayofmonth;
by _30day;
run;
data zzztest1b;
set zzztest1a;
if ddiff = 1 or ddiff = -1 then delete;
run;
proc sort data=zzztest1b out=zzzsort; by _30day;
run;
proc freq data=zzzsort;
table dayofmonth;
by _30day;
run;

*/
/*I did separately to see if any one of the discharge codes lead to more
discrepancy in the death date. Turns out, death dates do not entirely correlate
with one another between Hospice and MB files. Just use MBS death dates*/
data zzztest;
set test (keep = bene_id start end discharge dod_clean ddiff40_1);
if ddiff40_1 < 0 AND ddiff40_1 ~= .;
run;
/*most of the differences seem to be around -1 which is one day off. Maybe it's a systematic thing
between the two different reports*/
/*600 with differences > 2. Majority of the people have death dates in the Master Beneficiary that's in the last day so of the
month. This is probalby another systematic thing that we should probably discuss, but for now, I'm thinking that the Hospice date of death
might be more accurate. Thoughts?*/
/*
data zzztest2;
set final;
if bene_id = 'ZZZZZZZOyZuO9O3';
run;

data final;
set ccw.final2;
if disenr = 1 then do;
time_disenr_to_death = dod_clean - end + 1;
end;
if disenr = 0 then time_disenr_to_death = 0;
run;
proc freq data=final;
table disenr;
run;

data zzztest;
set final;
if time_disenr_to_death <= 0 and time_disenr_to_death ~= . and disenr = 1;

run;
data zzztest1;
set zzztest (keep = bene_id start end discharge discharge_i dod_clean time_disenr_to_death totalcost);
run;
proc export data=zzztest1 outfile = '\\home\users$\leee20\Documents\Downloads\Melissa\negative.xls' dbms = excelcs replace label; run;

proc freq data=final;
table time_disenr_to_death;
run;
*/
