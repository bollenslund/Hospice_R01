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
	set Hospice_startdate;
	if bene_id = 'ZZZZZZZp339I3kp';
run;
/************* DATE OF DEATH ******************/

/*finding the date of death from the last beneficiary year (the only time the date of death is recorded)*/
proc sort data=mb_ab out=dod;
	by bene_id BENE_ENROLLMT_REF_YR;
run;
data dod1;
	set dod;
	by bene_id BENE_ENROLLMT_REF_YR;
	if last.bene_id;
	death_i = 1;
	if BENE_DEATH_DT = . then death_i = 0;
run;
/*only keep the variables listed in our varlist*/
data dod2;
	set dod1 (keep = bene_id BENE_DEATH_DT BENE_VALID_DEATH_DT_SW NDI_DEATH_DT BENE_ENROLLMT_REF_YR BENE_PTA_TRMNTN_CD BENE_PTB_TRMNTN_CD death_i);
run;
data test;
	set dod2;
	if BENE_DEATH_DT = .;
run;
proc freq data=test;
	table BENE_ENROLLMT_REF_YR;
run;
/*all but 17 of 16399 of the observations are in 2010*/
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
/*there are around 3% of people who have different from NDI of the 36000 people who have reported NDI. Use the regular date of death?*/
data dod_merge;
	set dod2 (keep = bene_id BENE_DEATH_DT death_i BENE_VALID_DEATH_DT_SW);
	dod = BENE_DEATH_DT;
	drop BENE_DEATH_DT;
	label dod = "Death Date";
	format dod date9.;
run;
proc sort data=dod_merge; by bene_id; run;
/*total 219153. Could be due to the fact that we have people deleted from our original list*/
/***********************************************/

/*Year in which a patient is terminated*/
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
proc freq data=death_check;
	table BENE_DEATH_DT;
run;
data dod2;
	set dod2;
	drop BENE_PTA_TRMNTN_CD BENE_PTB_TRMNTN_CD;
run;
/*all checked. No Date of death for any value that is not 1.*/

/*creating a final mb dataset with wanted variables*/

data mb_ab_fin;
	set mb_ab (keep = bene_id BENE_ENROLLMT_REF_YR BENE_AGE_AT_END_REF_YR BENE_BIRTH_DT BENE_SEX_IDENT_CD BENE_RACE_CD STATE_CODE BENE_COUNTY_CD BENE_ZIP_CD);
run;

data work.hospice_startdate;
	set ccw.unique (keep = bene_id start);
	startyear = year(start);
	startmonth = month(start);
run;

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

data mb_ab_fin2;
	set mb_ab_fin1;
	diff = BENE_ENROLLMT_REF_YR - startyear;
	if diff = 0;
	drop diff;
run;
data test3;
	set mb_ab_fin2;
	if death_i = 0;
run;
proc freq data=test3;
	table startyear;
run;
/*all people missing death year started in 2008 or 2009. They just didn't die*/
/*missing 4 of the patients from hospice data: 213516*/


/******************** MEDICARE/HMO stuff ************************/
data medihmo;
	merge Hospice_startdate dod_merge;
	by bene_id;
	if start ~= .;
run;
proc sql;
	create table medihmo1
	as select *
	from mb_ab a
	left join medihmo b
	on a.bene_id = b.bene_id;
quit;
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
	/*
	lengthmedi = length (medi_status);
	lengthmo = length(hmo_status);
	*/
	if dod = . then dod = '31DEC2010'd;
	if deathyr = . then deathyr = year(dod);
	if deathmonth = . then deathmonth = month(dod);
	if start = . then delete;
	yeardiff = deathyr - startyear;
run;
/*data test;
	set medihmo;
	by bene_id;
	if last.bene_id then output;
run;
*/
/*total of 213520 unique beneficiaries*/
proc freq data=medihmo2;
	table lengthmedi lengthmo;
run;
/*all length of strings are 12.*/
proc freq data=medihmo2;
	table yeardiff;
run;
data medihmo3_0;
	set medihmo2;
	if yeardiff = 0;
	if BENE_ENROLLMT_REF_YR = startyear;
	mosdif = (deathmonth - startmonth)+1;
	allmedistatus = substr(trim(left(medi_status)), startmonth, mosdif);
	allhmostatus = substr(trim(left(hmo_status)), startmonth, mosdif);
run;

data medihmo3_1_1;
	set medihmo2;
	if yeardiff = 1;
	if BENE_ENROLLMT_REF_YR = startyear;
	mosdif = (12 - startmonth)+1;
	allmedistatus1 = substr(trim(left(medi_status)), startmonth, mosdif);
	allhmostatus1 = substr(trim(left(hmo_status)), startmonth, mosdif);
run;
data medihmo3_1_2;
	set medihmo2;
	if yeardiff = 1;
	if BENE_ENROLLMT_REF_YR = deathyr;
	allmedistatus2 = substr(trim(left(medi_status)), 1, deathmonth);
	allhmostatus2 = substr(trim(left(hmo_status)), 1, deathmonth);
run;
proc sort data=medihmo3_1_1; by bene_id; run;
proc sort data=medihmo3_1_2; by bene_id; run;
proc sql;
	create table medihmo3_1
	as select a.*, b.allmedistatus2, b.allhmostatus2
	from medihmo3_1_1 a
	left join medihmo3_1_2 b
	on a.bene_id = b.bene_id;
quit;
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

data medihmo3_2_0;
	set medihmo2;
	if yeardiff = 2;
	if BENE_ENROLLMT_REF_YR = startyear;
	mosdif = (12 - startmonth)+1;
	allmedistatus1 = substr(trim(left(medi_status)), startmonth, mosdif);
	allhmostatus1 = substr(trim(left(hmo_status)), startmonth, mosdif);
run;
data medihmo3_2_1;
	set medihmo2;
	if yeardiff=2;
	if BENE_ENROLLMT_REF_YR = startyear +1;
	allmedistatus2 = medi_status;
	allhmostatus2 = hmo_status;
run;
data medihmo3_2_2;
	set medihmo2;
	if yeardiff = 2;
	if BENE_ENROLLMT_REF_YR = deathyr;
	allmedistatus3 = substr(trim(left(medi_status)), 1, deathmonth);
	allhmostatus3 = substr(trim(left(hmo_status)), 1, deathmonth);
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
	drop allmedistatus1 allmedistatus2 allhmostatus1 allhmostatus2 allmedistatus3 allhmostatus3;
run;

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
/*five that are read wrong.*/

data medihmo3;
	set medihmo3_2b medihmo3_1a medihmo3_0;
run;
proc sort data=medihmo3; by bene_id; run;

data medihmo4;
	set medihmo3;
	partab = 1;
	if indexc(allmedistatus, "0", "1", "2", "A", "B") then partab = 0;
	nohmo = 1;
	if indexc(allhmostatus, "1", "2", "4", "A", "B", "C") then nohmo = 0;
	age = 1;
	if BENE_AGE_AT_END_REF_YR <= 65 then age = 0;
run;

ods rtf body="C:\Users\leee20\Desktop\GitHub\Hospice_R01\results.rtf";
title "Frequency Tables";
proc freq data=medihmo4;
table partab nohmo age;
run;

data medihmo5;
	set medihmo4;
	if partab = 0 or nohmo = 0 or age = 0 then delete;
run; 

/*if excluded, the total is 149827*/
