/********************************************************************/
/******** Making the corrected date of death variable        ********/
/********************************************************************/
/*bring in all factors needed to calculate date of death*/
data test;
set ccw.final2 (keep = bene_id dod_clean start end disenr discharge start2-start21 end2-end21 discharge2-discharge21 ip_end1-ip_end39 ip_death1-ip_death39 snf_end1-snf_end12 snf_death1-snf_death12);
ddiff_1 = dod_clean - end;
run;
/*obs that did not die during hospice stay per discharge code, but per dod they did **2386 obs*/
/*A total of 34,017 people do not have a date of death in MBS*/
proc freq data=test;
table ddiff_1 dod_clean;
run;
/*changing name*/
data death;
set test;
run;
/*discharge2-discharge10 as well as discharge 14 and 21 all have codes 40-42. I will give them date of deaths based on their discharge codes*/
data death1;
set death;
if (discharge = 40|discharge = 41|discharge = 42) then dod_clean = end;
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
/*a total of 13265 now do not have a date of death*/
proc freq data=death1;
table dod_clean;
run;

/*macro to bring the dates from inpatient and SNF in*/
%macro deathdate;
%do i = 1 %to 39;
data death1;
set death1;
if IP_death&i = 1 then ip_deathdate = IP_end&i;
run;
%end;
%do i = 1 %to 12;
data death1;
set death1;
if snf_death&i  = 1 then snf_deathdate = snf_end&i;
run;
%end;
%mend;
%deathdate;
/*bring in date of death from medpar to see if i am missing death dates*/
proc sql;
create table death2
as select a.*, b.medpardeath
from death1 a
left join ccw.Deathfrommedpar b
on a.bene_id = b.bene_id;
quit;
proc freq data=death2;
table medpardeath;
run;
data death3_1;
set death2;
if dod_clean = . and medpardeath ~=. then dod_clean = medpardeath;
run;
/*one observation has a date of death before Jan 1 2008. I made that date of death blank*/
data death3_2;
set death3_1;
if dod_clean < '01JAN2008'd then dod_clean = .;
run;
/*9420 are now missing date of deaths*/
proc freq data=death3_2;
table dod_clean;
run;

/*test to see if there's an entry for date of death for ip and snf. There is 5 beneficiaries that do, but I'll make IP death date a priority*/

/*putting the death dates for those in IP and SNF.*/
data death3;
set death3_2;
if dod_clean = . and ip_deathdate ~=. then dod_clean = ip_deathdate;
if dod_clean = . and snf_deathdate ~=. then dod_clean = snf_deathdate;
run;
data death3_3;
set death3;
if ip_deathdate ~= . and medpardeath ~= .; 
format ip_deathdate date9.;
run;
data death3_4;
set death3;
if snf_deathdate ~= . and medpardeath ~=.;
format snf_deathdate date9.;
run;
/*All those with medpar death dates have IP and SNF death dates. Total without death dates is still 9420*/

data death4;
set death3;
ddiff = dod_clean - end;
run;
proc freq data=death4;
table ddiff;
run;
data neg;
set death4;
if ddiff < 0 and ddiff ~=.;
run;
/*About 38% of the patients have end dates at december 31st*/
proc freq data=death4;
table end end2 end3 end4 end5 end6 end7 end8 end9 end10 end14 end21;
run;
data death4_1;
set death3;
if disenr = 1;
run;
/*16121 total of those who disenrolled after first visit have death dates. 6857 are still missing.*/
proc freq data=death4_1;
table dod_clean;
run;
data death4_2;
set death4_1;
if dod_clean =.;
run;
data ccw.deathdates;
set death4 (keep = bene_id end dod_clean disenr);
run;
data final_mb;
set ccw.final_mb_cc;
drop dod_clean;
run;
proc sql;
create table final_mb1
as select a.*, b.dod_clean, b.disenr, b.end
from final_mb a
left join ccw.deathdates b
on a.bene_id = b.bene_id;
quit;
data final_mb2;
set final_mb1;
if disenr = 1 then do;
time_disenr_to_death = dod_clean - end;
end;
if disenr = 0 then time_disenr_to_death = 0;
run;
proc freq data=final_mb2;
table disenr time_disenr_to_death;
run;
data final_mb3;
set final_mb2;
if time_disenr_to_death < 0 then dod_clean = .;
drop end disenr;
run;
data ccw.final_mb_cc1;
set final_mb3;
run;
