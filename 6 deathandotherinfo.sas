/********************************************************************/
/******** Making the corrected date of death variable        ********/
/********************************************************************/

/*Date of death comes from several sources
1. Use date of death from the master beneficary summary file
(either NDI verified dod or CMS dod if NDI dod not available)
2. Hospice claims - where discharge code indicates hospice death, then
dod set to the last day of the hospice claim.
This step overwrites the mbs dates for those beneficiaries with a hospice death.
3. If no mbs or hospice death date, then use the medpar date of death variable.
Also checks for date of death from IP and SNF stays but none are found.

Dataset that is saved is:
ccw.final_mb_cc1
This needs to be merged in with the other datasets in the merging_together.sas program
*/
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

/*bring in all factors needed to calculate date of death
Start with the dataset created in the hsurvey.sas
dod_clean = death date from the MBS file
BENE_DEATH_DATE = processed date of death (dod) from mb12mosforward.sas code cleaning the mbs file*/
data test;
set ccw.Final_hs_mb_ip_snf_op_dhc (keep = bene_id BENE_DEATH_DATE start end count_hs_stays hs1_death discharge start2-start21 end2-end21 discharge2-discharge21 ip_end1-ip_end39 ip_death1-ip_death39 snf_end1-snf_end12 snf_death1-snf_death12);
ind_dod_mbs=0;
if BENE_DEATH_DATE~=. then ind_dod_mbs=1 ;
run;
/*A total of 34,017???? Eric please check this, I'm getting 10317 with no mbs dod 
people do not have a date of death in MBS*/
proc freq data=test;
table ind_dod_mbs;
run;
/*changing name. Make indicator variable.
death_claim is categorical variable indicating source of final death date
1 = mbs death date*/
data death;
set test;
rename bene_death_date = dod_clean;
run;


data disenroll_1;
set death;
hs1_death=0;
if (discharge=40|discharge=41|discharge=42)then hs1_death=1;
run;

data disenroll_2;
set disenroll_1;
disenr = .;
if count_hs_stays>1 then disenr=1;
if (count_hs_stays=1 and hs1_death=1) then disenr=0;
if (count_hs_stays=1 and hs1_death=0) then disenr=1;
if hs1_death=0 and end = '31DEC2010'd then disenr = 0;
run;
proc freq;
table disenr /missprint;
run;
/*paste*/

data death0;
set disenroll_2;
if dod_clean ~=. then death_claim = 1;
diff = dod_clean - end;
/*should this updating disenr still be done?*/
if disenr = 1 and diff <= 0 and diff~=. then do;disenr = 0;dod_clean = end;end; 
run;

proc freq data=death0;
table death_claim disenr;
run;

/*For claims where discharge code from hospice claims indicates died in hospice
AND there is no later hospice stay,
replace date of death variable with discharge date
discharge2-discharge10 as well as discharge 14 and 21 all have codes 40-42.
I will give them date of deaths based on their discharge codes
set death_claim (source final death date) variable = 2 to indicate
date of death is from hospice claims*/
data death1;
set death0;
if (discharge = 40|discharge = 41|discharge = 42 & start2=.) then do; dod_clean = end; death_claim = 2; end;
if (discharge2 = 40|discharge2 = 41|discharge2 = 42 & start3=.) then do; dod_clean = end2; death_claim = 2; end;
if (discharge3 = 40|discharge3 = 41|discharge3 = 42 & start4=.) then do; dod_clean = end3; death_claim = 2; end;
if (discharge4 = 40|discharge4 = 41|discharge4 = 42 & start5=.) then do; dod_clean = end4; death_claim = 2; end;
if (discharge5 = 40|discharge5 = 41|discharge5 = 42 & start6=.) then do; dod_clean = end5; death_claim = 2; end;
if (discharge6 = 40|discharge6 = 41|discharge6 = 42 & start7=.) then do; dod_clean = end6; death_claim = 2; end;
if (discharge7 = 40|discharge7 = 41|discharge7 = 42 & start8=.) then do; dod_clean = end7; death_claim = 2; end;
if (discharge8 = 40|discharge8 = 41|discharge8 = 42 & start9=.) then do; dod_clean = end8; death_claim = 2; end;
if (discharge9 = 40|discharge9 = 41|discharge9 = 42 & start10=.) then do; dod_clean = end9; death_claim = 2; end;
if (discharge10 = 40|discharge10 = 41|discharge10 = 42 & start11=.) then do; dod_clean = end10; death_claim = 2; end;
if (discharge14 = 40|discharge14 = 41|discharge14 = 42 & start15=.) then do; dod_clean = end14; death_claim = 2; end;
if (discharge21 = 40|discharge21 = 41|discharge21 = 42) then do; dod_clean = end21; death_claim = 2; end;
run;
/*a total of 13265 now do not have a date of death, I'm getting  10297, need to check this*/
proc freq data=death1;
table dod_clean death_claim;
run;

/*macro to bring the dates from inpatient and SNF 
creates new dod variables from the claims where discharge code indicates died
in hospital or snf*/
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

proc freq data=death1;
table ip_deathdate  snf_deathdate;
run;

/*bring in date of death from medpar to see if i am missing death dates
pulls date of death variable (bene_death_dt) from medpar dataset*/
* ***Eric, why not pull directly from the medpar file using the bene_death_dt variable?*** ;
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
/*brings in medpar date of death variable that is populated by Resdac / CMS
where date of death from previous sources is missing*/
data death3_1;
set death2;
if dod_clean = . and medpardeath ~=. then do; dod_clean = medpardeath; death_claim = 3;end;
run;

proc freq;
table death_claim;
run;

/*one observation has a date of death before Jan 1 2008. I made that date of death blank
*****Do we want to drop data, or just flag it as invalid??***** */
data death3_2;
set death3_1;
if dod_clean < '01SEP2008'd and dod_clean ~=. then dod_date_invalid = 1;
run;
/*9419 are now missing date of deaths with one date invalid*/
proc freq data=death3_2;
table dod_date_invalid;
run;

/*test to see if there's an entry for date of death for ip and snf. There is 5 beneficiaries that do, but I'll make IP death date a priority*/

/*putting the death dates for those in IP and SNF.*/
data death3;
set death3_2;
if dod_clean = . and ip_deathdate ~=. then do; 
   dod_clean = ip_deathdate;
   death_claim =4;
   end;
if dod_clean = . and snf_deathdate ~=. then do;
   dod_clean = snf_deathdate;
   death_claim =5;
   end;
run;
/*no observations have the dod replaced with an ip or snf death date*/
proc freq data=death3;
table death_claim;
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

/*flag death dates as invalid if the cleaned death date is before the
first hospice stay end date*/
data death4;
set death3;
ddiff = dod_clean - end;
if ddiff < 0 and ddiff ~= . then dod_date_invalid = 1;
run;

proc freq data=death4;
table dod_date_invalid ;
run;
/*About 38% of the patients have end dates at december 31st*/
proc freq data=death4;
table end end2 end3 end4 end5 end6 end7 end8 end9 end10 end14 end21;
run;

/*look at those who disenrolled*/
data death4_1;
set death3;
if disenr = 1;
ddiff = dod_clean - end;
run;
/*16121 total of those who disenrolled after first visit have death dates. 6857 are still missing.*/
proc freq data=death4_1;
table ddiff;
run;
/*obs that did not die during hospice stay per discharge code, but per dod they did **2386 obs*/
proc freq data=death4_1;
table dod_clean;
run;
data death4_2;
set death4_1;
if dod_clean =.;
run;

/*save the working dataset with the cleaned dod variables with source information and invalid flag*/
data ccw.deathdates;
set death4 (keep = bene_id end dod_clean disenr dod_date_invalid death_claim);
label death_claim = "Where did Date come from? 1 = MBS 2 = Hospice 3 = Medpar";
label dod_date_invalid = "Date does not correctly correlate with Hospice. (1 = error)";
run;
proc freq data=ccw.deathdates;
table death_claim*disenr/missprint;
run;
ods rtf body = '\\home\users$\leee20\Documents\Downloads\Melissa\death.rtf';
proc contents data=ccw.deathdates varnum;
run;
ods rtf close;

data hs_mb_others;
set ccw.final_hs_mb_ip_snf_op_dhc;
drop disenr;
run;

data final_sample;
set ccw.deathdates;
run;

proc sql;
create table hs_mb_ip_snf_op_dhc_dod as select * from hs_mb_others a
left join final_sample b
on a.bene_id = b.bene_id;
quit;

data ccw.final_hs_mb_ip_snf_op_dhc_dod;
set hs_mb_ip_snf_op_dhc_dod;
run;
ods rtf body = '\\home\users$\leee20\Documents\Downloads\Melissa\num_death.rtf';
proc freq data=ccw.final_hs_mb_ip_snf_op_dhc_dod;
table death_claim*disenr /missprint;
run;
ods rtf close;

data final_mb;
set ccw.mb_final_cc;
drop dod_clean;
run;
/*bring in clean death date to cleaned mbs dataset*/
proc sql;
create table final_mb1
as select a.*, b.dod_clean, b.disenr, b.end, b.dod_date_invalid, b.death_claim
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
label time_disenr_to_death = "Time from Disenrollment to Death";
run;
proc freq data=final_mb2;
where dod_date_invalid ~= 1;
table disenr time_disenr_to_death;
run;
proc means data=final_mb2 n mean median;
where dod_date_invalid ~= 1;
var time_disenr_to_death;
run;
data final_mb3;
set final_mb2;
/*I don't think we want to drop any data, just use the not valid indicator*/
if time_disenr_to_death < 0 then dod_clean = .;
drop end disenr;
run;
/*save new version of the mb_cc dataset with the disenrollment to death variable added*/
data ccw.final_mb_cc_dod;
set final_mb3;
run;

data missing;
set death4;
if dod_clean = . then group = 0;
if dod_clean ~= . then group = 1;
later_date =0; 
if end >= '01JAN2010'd then later_date = 1;
if discharge = 30 then disenroll = 0;
if discharge = 1 then disenroll = 1;
run;

proc ttest data=missing;
class group;
where dod_date_invalid ~= 1 and end ~= '31DEC2010'd ;
var later_date;
run;
proc freq data=missing;
table later_date*group / chisq;
run;
proc freq data=missing;
table disenroll*group / chisq;
run;

