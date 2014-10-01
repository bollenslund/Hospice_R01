/*This file starts with the claims files, collects all of the diagnoses
that have been coded for each beneficiary across all claims in the 12 months
prior to first hospice admission, and then codes categorical variables for the
chronic conditions based on the dx codes

Hospice start dates from working/hs_stays_cleaned dataset 
(created by Hospice_Claims program file)

List of beneficiaries to define sample from working/mb_final
(created from MB12mosforward.sas program file)

Final file saved as: ccw.overall_ds_add_cc

Note: There is STATA code in this file to convert dx codes from claims into
dot format to conform with the list of dx codes associated with each of the
chronic conditions
*/

libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';
libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';

/*get list of hospice start dates for each beneficiary id*/

/*start with sample as defined by insurance coverage and age in master beneficiary data processing
version with hospice start date merged in*/
data sample;
	set ccw.for_medpar(keep=bene_id start) ;
run;

/***********************************************************************/
/***********************************************************************/
/*Identify claims in the 12 months pre-hospice enrollment*/
/***********************************************************************/
/***********************************************************************/

/*start of MACRO */

/*Macro for all claims files except for medpar
Run this to get claims list files: xx_meet_###
xx = claim type
### days before hospice enrollment (365=12 months*/
%macro other(days_start=,days_bef_hs=,source=);

/*Identify claims within certain time from procedure date defined when run macro*/
proc sql;
create table &source._meet_&days_bef_hs. as select a.*,b.start as hospice_enr_dt
from merged.&source._claims_j a inner join
sample b
on trim(left(a.BENE_ID))=trim(left(b.bene_id))
and &days_start<=b.start-a.CLM_FROM_DT<=&days_bef_hs;
quit;
run;

%mend;

/*Macro for medpar claims
Creates file mp_meet_###
where ### = 365 - days before hospice enrollment*/
%macro mp(days_start=,days_bef_hs=,source=);
%let source0=mp;

/*Identify claims within certain time from hospice enroll date*/
proc sql;
create table &source._meet_&days_bef_hs. as select a.*,b.start as hospice_enr_dt
from merged.medpar_all_file a inner join
sample b
on trim(left(a.BENE_ID))=trim(left(b.bene_id)) 
and &days_start<=b.start-a.ADMSN_DT<=&days_bef_hs ;
quit;

%mend;

/*Run macros to identify claims that start within 1 year of the hospice
enrollment date
Don't have to check hospice claims because looking at claims prior to first
hospice enrollment*/
%other(days_start=0,days_bef_hs=365,source=bcarrier );

%other(days_start=0,days_bef_hs=365,source=dme );
%other(days_start=0,days_bef_hs=365,source=hha_base );
%other(days_start=0,days_bef_hs=365,source=outpatient_base );

%mp(days_start=0,days_bef_hs=365,source=mp );

/*check to see that claims in lists are within 1 year of hospice start date*/
data hha_check1;
set hha_base_meet_365;
clm_to_hs =  hospice_enr_dt - CLM_FROM_DT;
run;
proc freq;
table clm_to_hs /missprint;
run;

/***********************************************************************/
/***********************************************************************/
/*Get list of all dx codes for each beneficiary in the 12 months
before hospice enrollment*/
/***********************************************************************/
/***********************************************************************/

/* File created:
ccw.dx_0_12m: dx 12 months before initial hospice enrollment date

Saved in J:\Geriatrics\Geri\Hospice Project\Hospice\working

One macro runs through all claim types to determine dx codes present

range1 = 0 - name for final output file
range2 = 12m - name for final output file
days_bef_hs = 365 - identifies claims dataset to start with*/

%macro dx_time_range(range1=, range2=, days_bef_hs=);

/*Process carrier medicare claims to pull out dx codes
Starts with bcarrier_meet_365 which is list of claims 12 months enroll
List of all diagnosis codes in 12 months pre-enroll
Multiple lines per each BID*/
data bcarrier_last_&range2._dx(keep=bene_id diag);
set bcarrier_meet_&days_bef_hs.(keep=bene_id PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD12 );
array dx PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD12;
do over dx;
diag=dx ;
output;
end;
run;
/*check for and remove duplicates, note this doesn't remove blanks*/
proc sort data=bcarrier_last_&range2._dx out=bcarrier_last_&range2._dx2 nodupkey;
by bene_id diag;
run;


/*Process outpatient medicare claims to pull out dx codes
Dataset being created: op_last_&range2._dx2*/
data op_last_&range2._dx(keep=bene_id diag);
set outpatient_base_meet_&days_bef_hs.(keep=bene_id PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD25  );
array dx PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD25 ;
do over dx;
diag=dx ;
output;
end;
run;
proc sort data=op_last_&range2._dx out=op_last_&range2._dx2 nodupkey;
by bene_id diag;
run;

/*Process medpar medicare claims to pull out dx codes
Dataset being created: mp_last_&range2._dx2*/

/*first renane icd9 dx variables so can refer to them with a range*/
data mp_meet_rename_dx;
set mp_meet_&days_bef_hs.(rename=(DGNS_1_CD=DGNS_1) rename=(DGNS_2_CD=DGNS_2)
	rename=(DGNS_3_CD=DGNS_3) rename=(DGNS_4_CD=DGNS_4) rename=(DGNS_5_CD=DGNS_5)
	rename=(DGNS_6_CD=DGNS_6) rename=(DGNS_7_CD=DGNS_7) rename=(DGNS_8_CD=DGNS_8)
	rename=(DGNS_9_CD=DGNS_9) rename=(DGNS_10_CD=DGNS_10) rename=(DGNS_11_CD=DGNS_11)
	rename=(DGNS_12_CD=DGNS_12) rename=(DGNS_13_CD=DGNS_13) rename=(DGNS_14_CD=DGNS_14)
	rename=(DGNS_15_CD=DGNS_15) rename=(DGNS_16_CD=DGNS_16) rename=(DGNS_17_CD=DGNS_17)
	rename=(DGNS_18_CD=DGNS_18) rename=(DGNS_19_CD=DGNS_19) rename=(DGNS_20_CD=DGNS_20)
	rename=(DGNS_21_CD=DGNS_21) rename=(DGNS_22_CD=DGNS_22) rename=(DGNS_23_CD=DGNS_23)
	rename=(DGNS_24_CD=DGNS_24) rename=(DGNS_25_CD=DGNS_25) );
run;

data mp_last_&range2._dx(keep=bene_id diag);
set mp_meet_rename_dx(keep=bene_id ADMTG_DGNS_CD DGNS_1-DGNS_25 );
array dx ADMTG_DGNS_CD DGNS_1-DGNS_25 ;
do over dx;
diag=dx ;
output;
end;
run;
proc sort data=mp_last_&range2._dx out=mp_last_&range2._dx2 nodupkey;
by bene_id diag;
run;

/*Process dme medicare claims to pull out dx codes
Dataset being created: dme_last_&range2._dx2*/
data dme_last_&range2._dx(keep=bene_id diag);
set dme_meet_&days_bef_hs.(keep=bene_id PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD12 );
array dx  PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD12 ;
do over dx;
diag=dx ;
output;
end;
run;
proc sort data=dme_last_&range2._dx out=dme_last_&range2._dx2 nodupkey;
by bene_id diag;
run;

/*Process hh medicare claims to pull out dx codes
Dataset being created: hha_last_&range2._dx2*/
data hha_last_&range2._dx(keep=bene_id diag);
set hha_base_meet_&days_bef_hs.(keep=bene_id PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD25 );
array dx PDGNS_CD PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD25 ;
do over dx;
diag=dx ;
output;
end;
run;
proc sort data=hha_last_&range2._dx out=hha_last_&range2._dx2 nodupkey;
by bene_id diag;
run;

/*merge diagnoses from each claim type into single dataset*/
data dx_all_last_&range2.;
set hha_last_&range2._dx2
mp_last_&range2._dx2
dme_last_&range2._dx2
op_last_&range2._dx2
bcarrier_last_&range2._dx2;
run;
/*remove blank dx codes and duplicates by beneficiary id*/
proc sort data=dx_all_last_&range2.(where=(diag~="")) out=ccw.dx_&range1._&range2 nodupkey;
by bene_id diag;
run;

%mend;


/*run the macro - 12 months pre-surgery - get sas dataset ccw.dx_0_12m*/
%dx_time_range(range1=0, range2=12m, days_bef_hs=365);

/*compare beneficiaries in dx code list with list of beneficiaries that
meet our hospice start date, age and insurance criteria*/

proc sort data=ccw.dx_0_12m out=dx_list_test1 nodupkey;
by bene_id;
run ;

proc sql;
create table dx_list_test2 as select a.*,b.diag
from sample a left join
dx_list_test1 b
on a.bene_id=b.bene_id;
quit;

data dx_list_test3;
set dx_list_test2;
dx_ind=0;
if diag ~='' then dx_ind=1;
run;
/*view frequency table of beneficiary IDs with at least one dx code 12 months pre hospice
approximately 0.3% of beneficiaries do not have any dx codes
n=149379 have at least 1 dx
n=435 have none in the year prior to hospice enrollment*/
proc freq;
table dx_ind;
run;


/***********************************************************************/
/***********************************************************************/
/*Create indicator variables for each of the 21 chronic conditions*/
/***********************************************************************/
/***********************************************************************/

/*Step 1 - Convert to Stata to get dx codes in dot format*/
/*begin of chronic 21 conditions.
Need to do two times, one for 6 month pre-surgery, one for 12 months pre-surgery

Note this pulls from a list of icd-9 codes associated with each of the chronic
conditions. The file path may need to be updated depending on the PC the
code is run from
*/

/*export list of diagnosis codes to stata*/

proc export data=ccw.dx_0_12m
outfile="J:\Geriatrics\Geri\Hospice Project\Hospice\working\dx_0_12m.dta" replace;
run;

/*******************************************************************/
/*put the dx codes into dot format
This is STATA code*/
/*******************************************************************/

capture log close

clear all
set more off
set memory 500m

//process diagnosis codes 12 months pre-hospice enrollment

use "J:\Geriatrics\Geri\Hospice Project\Hospice\working\dx_0_12m.dta",clear

// convert diagnosis codes to string variables, tostring diag,gen(icd9_c)
gen new=ltrim(diag)
icd9 check new,gen(icd9_c)
replace new="" if icd9_c>0 
// convert into dot format (ex 12.1 instead of 121)
icd9 clean new,dots 

replace diag=new
drop icd9_c new

save "J:\Geriatrics\Geri\Hospice Project\Hospice\working\dx_0_12m_2.dta",replace

//save to csv since sas can't read in stata 13 files
outsheet using "J:\Geriatrics\Geri\Hospice Project\Hospice\working\dx_0_12m_2.csv", comma replace

/*******************************************************************/
/* End of STATA code, back to SAS   */ 
/*******************************************************************/

*bring in formatted Stata dataset of dx codes;
proc import
datafile="J:\Geriatrics\Geri\Hospice Project\Hospice\working\dx_0_12m_2.csv"
out=dx_0_12m_2 DBMS=csv replace;
getnames=yes ;
run;


/*bring in excel list of dx codes associated with each chronic condition*/
proc import 
datafile='J:\Geriatrics\Geri\Hospice Project\Hospice\Reference\chronic_21_condition_icd9.xls'
out=icd9_21_chronic dbms=xls replace;
run;

proc contents data=icd9_21_chronic;
run;

/*creates macro variables of each of the chronic conditions listing of dx codes*/
proc sql;
select icd_9 into :chronic_desc1-:chronic_desc21 from icd9_21_chronic;
quit;
%put &chronic_desc10;
%put &chronic_desc5;

/*******************************************************************/
/*Generate chronic conditions indicator variables using dx
codes 12 months pre hospice enrollment */
/*******************************************************************/

%macro cc(prehs=);

/*initialize the chronic conditions variables*/
data list_&prehs._dx;
set dx_0_&prehs._2;
array list CC_1_AMI
CC_2_ALZH
CC_3_ALZHDMTA
CC_4_ATRIALFB
CC_5_CATARACT
CC_6_CHRNKIDN
CC_7_COPD
CC_8_CHF
CC_9_DIABETES
CC_10_GLAUCOMA
CC_11_HIPFRAC
CC_12_ISCHMCHT
CC_13_DEPRESSN
CC_14_OSTEOPRS
CC_15_RA_OA
CC_16_STRKETIA
CC_17_CNCRBRST
CC_18_CNCRCLRC
CC_19_CNCRPRST
CC_20_CNCRLUNG
CC_21_CNCREndM
;
do over list ;
list=0;
end;

diag_string=diag;

/* for dx codes that begin with numbers, process chronic cond variables*/
if anydigit(substr(trim(left(diag_string)),1,1))=1 then do;
diag=diag_string+0;

if diag in (&chronic_desc1) then CC_1_AMI=1;
if diag in (&chronic_desc2)  then CC_2_ALZH=1;
if diag in (&chronic_desc3)  then CC_3_ALZHDMTA=1;
if diag in (&chronic_desc4) then CC_4_ATRIALFB=1;
if diag in (&chronic_desc5) then CC_5_CATARACT=1;
if diag in (&chronic_desc6) then CC_6_CHRNKIDN=1;
if diag in (&chronic_desc7) then CC_7_COPD=1;
if diag in (&chronic_desc8) then CC_8_CHF=1;
if diag in (&chronic_desc9) then CC_9_DIABETES=1;
if diag in (&chronic_desc10) then CC_10_GLAUCOMA=1;
if diag in (&chronic_desc11) then CC_11_HIPFRAC=1;
if diag in (&chronic_desc12) then CC_12_ISCHMCHT=1;
if diag in (&chronic_desc13) then CC_13_DEPRESSN=1;
if diag in (&chronic_desc14) then CC_14_OSTEOPRS=1;
if diag in (&chronic_desc15) then CC_15_RA_OA=1;
if diag in (&chronic_desc16) then CC_16_STRKETIA=1;
if diag in (&chronic_desc17) then CC_17_CNCRBRST=1;
if diag in (&chronic_desc18) then CC_18_CNCRCLRC=1;
if diag in (&chronic_desc19) then CC_19_CNCRPRST=1;
if diag in (&chronic_desc20) then CC_20_CNCRLUNG=1;
if diag in (&chronic_desc21) then CC_21_CNCREndM=1;
end;

/*deal with dx codes that start with letters
Only two of them in the list we have to worry about*/
if anydigit(substr(trim(left(diag_string)),1,1))=0 then do;
if trim(left(diag_string)) in ("V431") then CC_5_CATARACT=1;
if trim(left(diag_string)) in ("V801") then CC_10_GLAUCOMA=1;
end;

run;

/*aggregate all chronic condition variables by bid*/
proc sql;
create table bid_dx_0_&prehs. as
select distinct bene_id,
sum(CC_1_AMI) as CC_1_AMI,
sum(CC_2_ALZH) as CC_2_ALZH,
sum(CC_3_ALZHDMTA) as CC_3_ALZHDMTA,
sum(CC_4_ATRIALFB) as CC_4_ATRIALFB,
sum(CC_5_CATARACT) as CC_5_CATARACT,
sum(CC_6_CHRNKIDN) as CC_6_CHRNKIDN,
sum(CC_7_COPD) as CC_7_COPD,
sum(CC_8_CHF) as CC_8_CHF,
sum(CC_9_DIABETES) as CC_9_DIABETES,
sum(CC_10_GLAUCOMA) as CC_10_GLAUCOMA,
sum(CC_11_HIPFRAC) as CC_11_HIPFRAC,
sum(CC_12_ISCHMCHT) as CC_12_ISCHMCHT,
sum(CC_13_DEPRESSN) as CC_13_DEPRESSN,
sum(CC_14_OSTEOPRS) as CC_14_OSTEOPRS,
sum(CC_15_RA_OA) as CC_15_RA_OA,
sum(CC_16_STRKETIA) as CC_16_STRKETIA,
sum(CC_17_CNCRBRST) as CC_17_CNCRBRST,
sum(CC_18_CNCRCLRC) as CC_18_CNCRCLRC,
sum(CC_19_CNCRPRST) as CC_19_CNCRPRST,
sum(CC_20_CNCRLUNG) as CC_20_CNCRLUNG,
sum(CC_21_CNCREndM) as CC_21_CNCREndM

from list_&prehs._dx group by bene_id;
quit;

/*convert to chronic condition vars. to binary variables*/
 data bid_dx_0_&prehs.1;
 set bid_dx_0_&prehs.;
 array list CC_1_AMI
CC_2_ALZH
CC_3_ALZHDMTA
CC_4_ATRIALFB
CC_5_CATARACT
CC_6_CHRNKIDN
CC_7_COPD
CC_8_CHF
CC_9_DIABETES
CC_10_GLAUCOMA
CC_11_HIPFRAC
CC_12_ISCHMCHT
CC_13_DEPRESSN
CC_14_OSTEOPRS
CC_15_RA_OA
CC_16_STRKETIA
CC_17_CNCRBRST
CC_18_CNCRCLRC
CC_19_CNCRPRST
CC_20_CNCRLUNG
CC_21_CNCREndM
;
do over list ;
if list>0 then list=1;
if list<=0 then list=0;
end;

/*create aggregated indicators*/
CC_AMI_isch=CC_1_AMI|CC_12_ISCHMCHT;
CC_alzheim=CC_2_ALZH|CC_3_ALZHDMTA;
CC_cncr_chronic=CC_17_CNCRBRST | CC_18_CNCRCLRC | CC_19_CNCRPRST | CC_20_CNCRLUNG | 
	CC_21_CNCREndM ;
CC_count=CC_1_AMI + CC_2_ALZH + CC_3_ALZHDMTA + CC_4_ATRIALFB + CC_5_CATARACT +
CC_6_CHRNKIDN + CC_7_COPD + CC_8_CHF + CC_9_DIABETES + CC_10_GLAUCOMA +
CC_11_HIPFRAC + CC_12_ISCHMCHT + CC_13_DEPRESSN + CC_14_OSTEOPRS + CC_15_RA_OA +
CC_16_STRKETIA + CC_17_CNCRBRST + CC_18_CNCRCLRC + CC_19_CNCRPRST + 
CC_20_CNCRLUNG + CC_21_CNCREndM ;

run;


proc means;
var CC_1_AMI
CC_2_ALZH
CC_3_ALZHDMTA
CC_4_ATRIALFB
CC_5_CATARACT
CC_6_CHRNKIDN
CC_7_COPD
CC_8_CHF
CC_9_DIABETES
CC_10_GLAUCOMA
CC_11_HIPFRAC
CC_12_ISCHMCHT
CC_13_DEPRESSN
CC_14_OSTEOPRS
CC_15_RA_OA
CC_16_STRKETIA
CC_17_CNCRBRST
CC_18_CNCRCLRC
CC_19_CNCRPRST
CC_20_CNCRLUNG
CC_21_CNCREndM
CC_AMI_isch
CC_alzheim
CC_cncr_chronic
CC_count;
run;

%mend;

%cc(prehs=12m);

/*so resulting datastet from macro is bid_dx_0_12m1*/
/*merge this chronic conditions information in to full list of bids that meet sample criteria
set in the master beneficiary data processing (since have ffs medicare, make assumption that
if no dx, then set chronic conditions to 0*/

proc sql;
create table chronic_conditions_12m_1(drop=bene_id2) as select *
from sample a left join
bid_dx_0_12m1(rename=(bene_id=bene_id2)) b
on a.bene_id=b.bene_id2;
quit;

data ccw.chronic_conditions_12m;
set chronic_conditions_12m_1;
cc_ind = 0;
if CC_1_AMI ~= . then cc_ind = 1;

 array list CC_1_AMI
CC_2_ALZH
CC_3_ALZHDMTA
CC_4_ATRIALFB
CC_5_CATARACT
CC_6_CHRNKIDN
CC_7_COPD
CC_8_CHF
CC_9_DIABETES
CC_10_GLAUCOMA
CC_11_HIPFRAC
CC_12_ISCHMCHT
CC_13_DEPRESSN
CC_14_OSTEOPRS
CC_15_RA_OA
CC_16_STRKETIA
CC_17_CNCRBRST
CC_18_CNCRCLRC
CC_19_CNCRPRST
CC_20_CNCRLUNG
CC_21_CNCREndM
CC_AMI_isch
CC_alzheim
CC_cncr_chronic
CC_count
;
do over list ;
if list=. then list=0;
end;

label cc_ind = "Dx for chronic conditions indicator";
label CC_1_AMI = "Chronic condition - AMI";
label CC_2_ALZH = "Chronic condition - Alzheimer's Disease";
label CC_3_ALZHDMTA = "Chronic condition - Alzheimers / Dementia";
label CC_4_ATRIALFB = "Chronic condition - Atrial Fibrillation";
label CC_5_CATARACT = "Chronic condition - Cataract";
label CC_6_CHRNKIDN = "Chronic condition - Kidney disease";
label CC_7_COPD = "Chronic condition - COPD";
label CC_8_CHF = "Chronic condition - Heart Failure";
label CC_9_DIABETES = "Chronic condition - Diabetes";
label CC_10_GLAUCOMA = "Chronic condition - Glaucoma";
label CC_11_HIPFRAC = "Chronic condition - Hip Fracture";
label CC_12_ISCHMCHT = "Chronic condition - Ischemic Heart Dis.";
label CC_13_DEPRESSN = "Chronic condition - Depression";
label CC_14_OSTEOPRS = "Chronic condition - Osteoporosis";
label CC_15_RA_OA = "Chronic condition - Arthritis";
label CC_16_STRKETIA = "Chronic condition - Stroke / TIA";
label CC_17_CNCRBRST = "Chronic condition - Breast Cancer";
label CC_18_CNCRCLRC = "Chronic condition - Colorectal Cancer";
label CC_19_CNCRPRST = "Chronic condition - Prostate Cancer";
label CC_20_CNCRLUNG = "Chronic condition - Lung Cancer";
label CC_21_CNCREndM = "Chronic condition - Endometrial Cancer";
label CC_AMI_isch = "Chronic condition - AMI or Ischemic Heart Dis.";
label CC_alzheim = "Chronic condition - Alzh or Dementia";
label CC_cncr_chronic = "Chronic condition - Cancer (all types)";
label CC_count = "Count of Chronic Conditions";
run;


ods rtf file="J:\Geriatrics\Geri\Hospice Project\output\hs_cc_means.rtf";

proc means;
var CC_:;
run;

proc freq;
table cc_ind /missprint;
run;

ods rtf close;


/* the above file contains a list of beneficiary IDs with their chronic conditions variables*/

/*merge with the overall project dataset, as created in "6 deathandotherinfo.sas" code*/
proc sql;
create table ccw.overall_ds_add_cc(drop=bene_id2 start2) as select * from
ccw.final_hs_mb_ip_snf_op_dhc_dod a left join
ccw.chronic_conditions_12m (rename=(bene_id=bene_id2) rename=(start=start2)) b
on a.bene_id=b.bene_id2 and a.start=b.start2;
quit;

ods rtf file="J:\Geriatrics\Geri\Hospice Project\output\proc_contents_overall_ds.rtf";
proc contents data=ccw.overall_ds_add_cc;
run;

proc freq; table CC_: ; run;
ods rtf close;

