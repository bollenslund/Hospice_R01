/*This file processes the master beneficiary summary files and uses
age and Medicare coverage / HMO use to define the sample of 
hopsice enrollees to be analyzed 

Final files created are :
1. ccw.mb_final
   Cleaned MBS information for the sample
2. ccw.for_medpar
   Cleaned MBS information for the sample (same as above) with stay 1 hospice start and 
   end dates merged in
   
*/

libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

data mb_ab;
	set merged.mbsf_ab_summary;
run;
data mb_cc;
	set merged.mbsf_cc_summary;
run;

proc sort data=mb_ab;
	by bene_id BENE_ENROLLMT_REF_YR;
run;
proc sort data=mb_cc;
	by bene_id BENE_ENROLLMT_REF_YR;
run;

data test;
	set mb_ab;
	if bene_id = 'ZZZZZZZp339I3kp';
run;
data test3;
	set ccw.hs_stays_cleaned;
	if bene_id = 'ZZZZZZZp339I3kp';
run;

/*****************************************************************************/
/*************              PART 1: DATE OF DEATH           ******************/
/*****************************************************************************/

/*Identify the date of death from the last beneficiary year 
(the only time the date of death is recorded)*/
proc sort data=mb_ab out=dod;
	by bene_id BENE_ENROLLMT_REF_YR;
run;
/*get dataset of just last MBS year for each beneficiary
define an indicator variable for presence of death date in the MBS file*/
data dod1;
	set dod;
	by bene_id BENE_ENROLLMT_REF_YR;
	if last.bene_id;
	death_i = 1;
	if BENE_DEATH_DT = . then death_i = 0;
run;

proc freq;
table death_i;
run;

/*only keep the variables listed in our varlist
these are from the last year that a beneficiary has an entry in the MBS file*/
data dod2;
	set dod1 (keep = bene_id BENE_DEATH_DT BENE_VALID_DEATH_DT_SW NDI_DEATH_DT BENE_ENROLLMT_REF_YR BENE_PTA_TRMNTN_CD BENE_PTB_TRMNTN_CD death_i);
run;

/*dataset of those that have no death year 16399 observations*/
data test;
	set dod2;
	if BENE_DEATH_DT = .;
run;

/*all but 11 of 16399 of the observations are in 2010*/
proc freq data=test;
	table BENE_ENROLLMT_REF_YR;
run;

/*check for difference between claims death date and NDI verified death date
almost 98% have no difference between the two dates
Note that only ~17% of hospice patients have NDI verified death date reported*/
data test1;
	set dod2;
	diff = NDI_DEATH_DT - BENE_DEATH_DT;
	if NDI_DEATH_DT ~= .;
run;
proc freq data=test1;
	table diff;
run;
data test2;
	set test1;
	if diff ~=0 or diff ~=.;
run;
/*there are around 3% of people who have different from NDI of the 36000
people who have reported NDI. Use the regular date of death?*/

/*bring date of death, date death indicator and valid death date key in to dataset*/
data dod_merge;
	set dod2 (keep = bene_id BENE_DEATH_DT death_i BENE_VALID_DEATH_DT_SW);
	dod = BENE_DEATH_DT;
	drop BENE_DEATH_DT;
	label dod = "Death Date";
	format dod date9.;
run;
proc sort data=dod_merge; by bene_id; run;

/*approximately 2000 observations with death date do not have the valid death date
switch indicator in the master beneficiary file for their last year in the dataset*/
proc freq;
table BENE_VALID_DEATH_DT_SW /missprint;
run;
/*Unique beneficiaries in MBS file: 219153. 
In hospice claims, we have 213520 beneficiaries
We dropped those that had first hs enrollment before Sept 2008 so that is likely
why we have more BIDs in MBS than in HS file*/

/***********************************************/

/*Check DOD vs Year in which a patient is terminated*/
/*this is a way to check if the termination codes to make sure they line up with our death dates.
as said in the word document, this or the date of death can be used to see if a beneficiary died 
that year. I will primarily use date of death in regards to this matter*/
proc freq data=mb_ab;
	table BENE_PTA_TRMNTN_CD BENE_PTB_TRMNTN_CD;
run;
/*both part a and b are not coded as binary. 
CODES: 
0= NOT TERMINATED
1 = DEAD
2 = NON-PAYMENT OF PREMIUM
3 = VOLUNTARY WITHDRAWAL
9 = OTHER TERMINATION
*/
data death_check;
	set dod2;
	if BENE_PTA_TRMNTN_CD = 1 then delete;
run;
/*all beneficiaries that don't have termination code = dead do not have a deathdate*/
proc freq data=death_check;
	table BENE_DEATH_DT;
run;
data dod2;
	set dod2;
	drop BENE_PTA_TRMNTN_CD BENE_PTB_TRMNTN_CD;
run;
/*all checked. No Date of death for any value that is not 1.*/


/*****************************************************************************/
/* PART 2: GET MBS DATASET FROM JUST HOSPICE ENROLLMENT YEAR WITH DOD ADDED
   DROP BENEFICIARIES (*12) WHERE DATE OF DEATH IS BEFORE HOSPICE ENROLLMENT DATE  */
/*****************************************************************************/

/*creating a final mb dataset with wanted variables*/

/*just required variables from all years MBS file*/
data mb_ab_fin;
	set mb_ab (keep = bene_id BENE_ENROLLMT_REF_YR BENE_AGE_AT_END_REF_YR BENE_BIRTH_DT BENE_SEX_IDENT_CD BENE_RACE_CD STATE_CODE BENE_COUNTY_CD BENE_ZIP_CD);
run;

/*pull hospice first enrollment start date from clean hospice claims dataset*/
data work.hospice_startdate;
	set ccw.hs_stays_cleaned (keep = bene_id start);
	startyear = year(start);
	startmonth = month(start);
run;

proc freq;
table startyear /missprint;
run;

/*create single table of all mbs years + hospice start date + date of death
multiple rows for each BID if they are present in multiple years of the MBS file*/
proc sql;
	create table mb_ab_fin1
	as select *
	from mb_ab_fin a
	left join hospice_startdate b
	on a.bene_id = b.bene_id
	left join dod_merge c
	on a.bene_id = c.bene_id;
quit;
proc sort data=mb_ab_fin1;
	by bene_id BENE_ENROLLMT_REF_YR;
run;

/*keeps the mbs entry for the hospice start year only
213516 observatons (4 BIDs in the hospice claims dataset do not have mbs entry same year
as their hospice enrollment*/
data mb_ab_fin2;
	set mb_ab_fin1;
	diff = BENE_ENROLLMT_REF_YR - startyear;
	if (diff = 0 & startyear~=.);
	drop diff;
run;

/*drop beneficiaries where date of death is earlier than hospice enrollment date
this removes 12 beneficiaries from the sample*/
data mb_ab_fin3;
	set mb_ab_fin2;
        enr_to_dth=dod - start;
run;

proc freq data=mb_ab_fin3;
table enr_to_dth /missprint;
run;

data mb_ab_fin4;
set mb_ab_fin3;
if (enr_to_dth => 0 | enr_to_dth=. );
drop enr_to_dth;
run;
/*213504 beneficiaries*/

/*Look at observations without death date to confirm their enroll date is within
2008 or 2009*/
data test3;
	set mb_ab_fin4;
	if death_i = 0;
run;
proc freq data=test3;
	table startyear;
run;
/*all people missing death year started in 2008 or 2009. They just didn't die
by 2010 when the dataset ends*/
/*missing 4 of the patients from hospice data: 213504*/

/*****************************************************************************/
/********************      MEDICARE/HMO STATUS        ************************/
/*****************************************************************************/

/*Create indicators for (1) Parts A + B MC enrollment from time of
hospice enrollment forward (to end of 2010 or death) and (2) if MC 
is administered through an HMO */

/*get table of all mb entries for hospice enrollees with dod>hs enrollment*/
proc sql;
     create table medihmo as select *
     from mb_ab where bene_id in (select bene_id from mb_ab_fin4);
quit;


/*merge hs start dates and date of death with mbs file containing all years of data*/
proc sql;
	create table medihmo1
	as select *
	from medihmo(drop=BENE_VALID_DEATH_DT_SW) a
	left join mb_ab_fin4(keep=bene_id start startyear startmonth  BENE_VALID_DEATH_DT_SW
	death_i dod) b
	on a.bene_id = b.bene_id;
quit;

/*combine individual buyin and hmo indicator variables into single string variable for 
each year. If no date of death, then set dod=Dec. 31, 2010 so we check for coverage
through end of 2010*/
data medihmo2;
	set medihmo1;
	deathyr = year(dod);
	deathmonth = month(dod);
	medi_status = BENE_MDCR_ENTLMT_BUYIN_IND_01 || BENE_MDCR_ENTLMT_BUYIN_IND_02 ||
	BENE_MDCR_ENTLMT_BUYIN_IND_03 || BENE_MDCR_ENTLMT_BUYIN_IND_04 || BENE_MDCR_ENTLMT_BUYIN_IND_05 ||
	BENE_MDCR_ENTLMT_BUYIN_IND_06 || BENE_MDCR_ENTLMT_BUYIN_IND_07 || BENE_MDCR_ENTLMT_BUYIN_IND_08 ||
	BENE_MDCR_ENTLMT_BUYIN_IND_09 || BENE_MDCR_ENTLMT_BUYIN_IND_10 || BENE_MDCR_ENTLMT_BUYIN_IND_11 ||
	BENE_MDCR_ENTLMT_BUYIN_IND_12;
	hmo_status = BENE_HMO_IND_01 || BENE_HMO_IND_02 || BENE_HMO_IND_03 || BENE_HMO_IND_04 ||
	 BENE_HMO_IND_05 || BENE_HMO_IND_06 || BENE_HMO_IND_07 || BENE_HMO_IND_08 ||
	 BENE_HMO_IND_09 || BENE_HMO_IND_10 || BENE_HMO_IND_11 || BENE_HMO_IND_12;
	drop BENE_MDCR_ENTLMT_BUYIN_IND_01-BENE_MDCR_ENTLMT_BUYIN_IND_12 BENE_HMO_IND_01-BENE_HMO_IND_12;
	label medi_status = "Medicare Entitlement/Buy-In Indicator";
	label hmo_status = "HMO Indicator";
	lengthmedi = length (medi_status);
	lengthmo = length(hmo_status);
	dod_ind = 0;
	if dod = . then do; dod = '31DEC2010'd; dod_ind = 1;end;
	if deathyr = . then deathyr = year(dod);
	if deathmonth = . then deathmonth = month(dod);
	if start = . then delete;
	yeardiff = deathyr - startyear;
run;

/*check to make sure dropped cases where date of death before hospice enrollment date*/
data test20;
set medihmo2;
enr_to_dth=dod - start;
run;

proc freq data=test20;
table enr_to_dth /missprint;
run;
/*no beneficiaries with date of death before hospice enrollment*/

data test;
	set medihmo2;
	by bene_id;
	if last.bene_id then output;
run;
/*total of 213504 unique beneficiaries*/

proc freq data=medihmo2;
	table lengthmedi lengthmo;
run;
/*all length of strings are 12.*/

proc freq data=test;
	table yeardiff;
run;
/*table of difference between death year and hospice enrollment year, all 0-2*/

/*for those that died the same year as they enrolled in hospice, trim buyin and hmo
indicator string variables to just month of hospice enrollment to death month
This is full mc and hmo status indicator variable for these beneficiaries*/
data medihmo3_0;
	set medihmo2;
	if yeardiff = 0;
	if BENE_ENROLLMT_REF_YR = startyear;
	mosdif = (deathmonth - startmonth)+1;
	allmedistatus = substr(trim(left(medi_status)), startmonth, mosdif);
	allhmostatus = substr(trim(left(hmo_status)), startmonth, mosdif);
run;

/*for beneficiaries that enrolled in hospice and died the next year
4 observations don't have mbs entries during the 2nd year so we don't have
insurance information on them, need to drop them*/
data medihmo3_1_1a;
	set medihmo2;
	if yeardiff = 1;
	if BENE_ENROLLMT_REF_YR = startyear;
	mosdif = (12 - startmonth)+1;
	/*mc ind variables for month of hospice enrollment to end of that year*/
	allmedistatus1 = substr(trim(left(medi_status)), startmonth, mosdif);
	allhmostatus1 = substr(trim(left(hmo_status)), startmonth, mosdif);
run;
data medihmo3_1_2;
	set medihmo2;
	if yeardiff = 1;
	if BENE_ENROLLMT_REF_YR = deathyr;
	/*mc ind variables for year after hs enrollment to death*/
	allmedistatus2 = substr(trim(left(medi_status)), 1, deathmonth);
	allhmostatus2 = substr(trim(left(hmo_status)), 1, deathmonth);
run;

/*only keep beneficiaries that have both years mbs entry*/
proc sql;
     create table medihmo3_1_1 as select * from
     medihmo3_1_1a where bene_id in (select bene_id from medihmo3_1_2);
quit;
proc sort data=medihmo3_1_1; by bene_id; run;
proc sort data=medihmo3_1_2; by bene_id; run;
/*bring in death year mc ind variables*/
proc sql;
	create table medihmo3_1
	as select a.*, b.allmedistatus2, b.allhmostatus2
	from medihmo3_1_1 a
	left join medihmo3_1_2 b
	on a.bene_id = b.bene_id;
quit;
/*combine mc ind variables across the 2 years so single variable covers time from hs to death*/
data medihmo3_1a;
	set medihmo3_1;
	allmedistatus = trim(left(allmedistatus1)) || trim(left(allmedistatus2));
	allhmostatus = trim(left(allhmostatus1)) || trim(left(allhmostatus2));
	drop allmedistatus1 allmedistatus2 allhmostatus1 allhmostatus2;
run;
/*
data test;
	set medihmo3_1a;
	retain totmonth;
	totmonth = intck("month",start,dod);
	totmonth = totmonth + 1;
	totmlength = length (allmedistatus);
	diff = totmonth - totmlength;
run;
proc freq data=test;
	table diff;
run;
*/
/*all months are accounted for*/

/*similar to above steps, process mc ind variables for beneficiaries who die
2 calendar years after hospice enrollment
there are 5473 beneficiaries but 5 are missing 2nd and/or 3rd year mbs file*/
data medihmo3_2_0a;
	set medihmo2;
	if yeardiff = 2;
	if BENE_ENROLLMT_REF_YR = startyear;
	mosdif = (12 - startmonth)+1;
	allmedistatus1 = substr(trim(left(medi_status)), startmonth, mosdif);
	allhmostatus1 = substr(trim(left(hmo_status)), startmonth, mosdif);
run;
/*only 5470 - 3 missing 2nd year mbs file*/
data medihmo3_2_1a;
	set medihmo2;
	if yeardiff=2;
	if BENE_ENROLLMT_REF_YR = startyear +1;
	allmedistatus2 = medi_status;
	allhmostatus2 = hmo_status;
run;
/*only 5468 - 5 missing 2nd year mbs file*/
data medihmo3_2_2;
	set medihmo2;
	if yeardiff = 2;
	if BENE_ENROLLMT_REF_YR = deathyr;
	allmedistatus3 = substr(trim(left(medi_status)), 1, deathmonth);
	allhmostatus3 = substr(trim(left(hmo_status)), 1, deathmonth);
run;

/*only keep 5468 beneficiaries that have mbs entry for all 3 years*/
proc sql;
     create table medihmo3_2_0 as select * from
     medihmo3_2_0a where bene_id in (select bene_id from medihmo3_2_2);
quit;
proc sql;
     create table medihmo3_2_1 as select * from
     medihmo3_2_1a where bene_id in (select bene_id from medihmo3_2_2);
quit;

proc freq data=medihmo3_2_2;
table allmedistatus3 /missprint;
run;

data test4;
set medihmo3_2_2;
if allmedistatus3='';
run;

proc sort data=medihmo3_2_0; by bene_id; run;
proc sort data=medihmo3_2_1; by bene_id; run;
proc sort data=medihmo3_2_2; by bene_id; run;
proc sql;
	create table medihmo3_2
	as select a.*, b.allmedistatus2, b.allhmostatus2
	from medihmo3_2_0 a
	left join medihmo3_2_1 b
	on a.bene_id = b.bene_id;
quit;
proc sql;
	create table medihmo3_2a
	as select a.*, b.allmedistatus3, b.allhmostatus3
	from medihmo3_2 a
	left join medihmo3_2_2 b
	on a.bene_id = b.bene_id;
quit;
data medihmo3_2b;
	set medihmo3_2a;
	allmedistatus = trim(left(allmedistatus1)) || trim(left(allmedistatus2)) || trim(left(allmedistatus3));
	allhmostatus = trim(left(allhmostatus1)) || trim(left(allhmostatus2))|| trim(left(allhmostatus3));
	*drop allmedistatus1 allmedistatus2 allhmostatus1 allhmostatus2 allmedistatus3 allhmostatus3;
run;

proc freq data=medihmo3_2b;
table startmonth deathmonth;
run;

/*check that months mc indicator variables match count of months from hospice enroll to death*/
data test;
	set medihmo3_2b;
	retain totmonth;
	totmonth = intck("month",start,dod);
	totmonth = totmonth + 1;
	totmlength = length (allmedistatus);
	diff = totmonth - totmlength;
run;
proc freq data=test;
	table diff;
run;
data test1;
	set test;
	if diff > 0;
run;

/*bring all beneficiaries into single dataset with their complete mc ind vars
213495 have full insurance information (213504 - 4 - 5 = 213495)*/
data medihmo3;
	set medihmo3_2b medihmo3_1a medihmo3_0;
run;
proc sort data=medihmo3; by bene_id; run;

/*create indicator variables for part a and b coverage and hmo coverage*/
data medihmo4;
	set medihmo3;
	partab = 1;
	if indexc(allmedistatus, "0", "1", "2", "A", "B") then partab = 0;
	nohmo = 1;
	if indexc(allhmostatus, "1", "2", "4", "A", "B", "C") then nohmo = 0;
	age = 1;
	if BENE_AGE_AT_END_REF_YR <= 65 then age = 0;
	if dod_ind = 1 then dod = .;
run;

ods rtf body="J:\Geriatrics\Geri\Hospice Project\output\results.rtf";
title "Frequency Tables";
proc freq data=medihmo4;
table partab nohmo age;
run;
ods rtf close;

data medihmo5;
	set medihmo4;
	if partab = 0 or nohmo = 0 or age = 0 then delete;
	drop allmedistatus allhmostatus partab nohmo age mosdif yeardiff hmo_status medi_status deathmonth BENE_DEATH_DT NDI_DEATH_DT deathyr death_i startmonth BENE_HMO_CVRAGE_TOT_MONS BENE_STATE_BUYIN_TOT_MONS BENE_SMI_CVRAGE_TOT_MONS BENE_HI_CVRAGE_TOT_MONS BENE_PTB_TRMNTN_CD BENE_PTA_TRMNTN_CD
	BENE_ENTLMT_RSN_CURR BENE_ENTLMT_RSN_ORIG RTI_RACE_CD startyear BENE_MDCR_STATUS_CD BENE_ESRD_IND start lengthmedi lengthmo allmedistatus1 allhmostatus1 allmedistatus2 allhmostatus2 allmedistatus3 allhmostatus3;
	/*race and ethnicity variables*/
	re_white = 0; re_black = 0; re_other = 0; re_asian = 0; re_hispanic = 0; re_na = 0; re_unknown = 0;
	if BENE_RACE_CD = 1 then re_white = 1;
	if BENE_RACE_CD = 2 then re_black = 1;
	if BENE_RACE_CD = 3 then re_other = 1;
	if BENE_RACE_CD = 4 then re_asian = 1;
	if BENE_RACE_CD = 5 then re_hispanic = 1;
	if BENE_RACE_CD = 6 then re_na = 1;
	if BENE_RACE_CD = 0 then re_unknown = 1;
	label re_white = "White race / ethnicity";
	label re_black = "Black race / ethnicity";
	label re_other = "Other race / ethnicity";
	label re_asian = "Asian race / ethnicity";
	label re_hispanic = "Hispanic race / ethnicity";
	label re_na = "Native American race / ethnicity";
	label re_unknown = "Unknown race / ethnicity";
	rename dod = BENE_DEATH_DATE;
	/*gender variable*/
	female = .;
	if BENE_SEX_IDENT_CD=1 then female = 0;
	if BENE_SEX_IDENT_CD=2 then female = 1;
	label female = "Female indicator";
	/*date of death, use NDI if present, otherwise, use bene_dod variable from mbs*/
run; 

/*save final mbs file, not merged with hospice stay dataset*/
data ccw.mb_final;
	set medihmo5;
run;
/*if excluded, the total is 149814*/
proc freq data=medihmo5;
table Bene_death_date;
run;

/*bring in hs start/end dates and stay count so can use this to process claims files*/
proc sql;
	create table formedpar
	as select a.*, b.start, b.end,b.count_hs_stays
	from ccw.mb_final a
	left join ccw.hs_stays_cleaned b
	on a.bene_id = b.bene_id;
quit;

/*save working dataset that has medpar sample, info and hospice stay #1 start and end dates*/
data ccw.for_medpar;
	set formedpar;
run;
