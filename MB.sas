libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\raw_sas';

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

/*working getting date of death information*/
proc sort data=mb_ab out=dod;
	by bene_id BENE_ENROLLMT_REF_YR;
run;
data dod1;
	set dod;
	by bene_id BENE_ENROLLMT_REF_YR;
	if last.bene_id then output;
run;
data dod2;
	set dod1 (keep = bene_id BENE_DEATH_DT BENE_VALID_DEATH_DT_SW NDI_DEATH_DT BENE_ENROLLMT_REF_YR);
run;

/*Year in which a patient is terminated*/
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
all checked. No Date of death for any value that is not 1.
*/

data mb_ab_fin;
	set mb_ab (keep = bene_id BENE_ENROLLMT_REF_YR BENE_AGE_AT_END_REF_YR BENE_BIRTH_DT BENE_SEX_IDENT_CD BENE_RACE_CD STATE_CODE BENE_COUNTY_CD BENE_ZIP_CD);
run;

data work.hospice_startdate;
	set ccw.unique (keep = bene_id start);
	startyear = year(start);
run;

proc sql;
	create table mb_ab_fin1
	as select *
	from mb_ab_fin a
	left join hospice_startdate b
	on a.bene_id = b.bene_id;
quit;
proc sort data=mb_ab_fin1;
	by bene_id BENE_ENROLLMT_REF_YR;
run;

data mb_ab_fin2;
	set mb_ab_fin1;
	diff = BENE_ENROLLMT_REF_YR - startyear;
	if diff = 0;
	drop start startyear diff;
run;
/*missing 4 of the patients from hospice data*/

/*to do tomorrow:
do the medicare and hmo coverage
*/

data medihmo;
	set hospice_startdate;
	mhmonth = month(start);
	mhstartyr = year(start) - 1;
	mhendyr = year(start);
	drop startyear;
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
	rename BENE_MDCR_ENTLMT_BUYIN_IND_01 = BENE_MDCR_ENTLMT_BUYIN_IND_1;
	rename BENE_MDCR_ENTLMT_BUYIN_IND_02 = BENE_MDCR_ENTLMT_BUYIN_IND_2;
	rename BENE_MDCR_ENTLMT_BUYIN_IND_03 = BENE_MDCR_ENTLMT_BUYIN_IND_3;
	rename BENE_MDCR_ENTLMT_BUYIN_IND_04 = BENE_MDCR_ENTLMT_BUYIN_IND_4;
	rename BENE_MDCR_ENTLMT_BUYIN_IND_05 = BENE_MDCR_ENTLMT_BUYIN_IND_5;
	rename BENE_MDCR_ENTLMT_BUYIN_IND_06 = BENE_MDCR_ENTLMT_BUYIN_IND_6;
	rename BENE_MDCR_ENTLMT_BUYIN_IND_07 = BENE_MDCR_ENTLMT_BUYIN_IND_7;
	rename BENE_MDCR_ENTLMT_BUYIN_IND_08 = BENE_MDCR_ENTLMT_BUYIN_IND_8;
	rename BENE_MDCR_ENTLMT_BUYIN_IND_09 = BENE_MDCR_ENTLMT_BUYIN_IND_9;
	rename BENE_HMO_IND_01 = BENE_HMO_IND_1;
	rename BENE_HMO_IND_02 = BENE_HMO_IND_2;
	rename BENE_HMO_IND_03 = BENE_HMO_IND_3;
	rename BENE_HMO_IND_04 = BENE_HMO_IND_4;
	rename BENE_HMO_IND_05 = BENE_HMO_IND_5;
	rename BENE_HMO_IND_06 = BENE_HMO_IND_6;
	rename BENE_HMO_IND_07 = BENE_HMO_IND_7;
	rename BENE_HMO_IND_08 = BENE_HMO_IND_8;
	rename BENE_HMO_IND_09 = BENE_HMO_IND_9;
run;

data medihmo3a;
	set medihmo2;
	if start = . then delete;
	if BENE_ENROLLMT_REF_YR = mhstartyr;
run;
/*possibly don't have 12 months before data for around 2500 beneficiaries*/
data medihmo3b;
	set medihmo2;
	if start = . then delete;
	if BENE_ENROLLMT_REF_YR = mhendyr;
run;

data medihmo3a_1;
	set medihmo3a;
	if mhmonth = 1 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_1_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_1_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_1_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_1_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_1_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_1_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_1_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_1_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 2 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_1_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_1_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_1_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_1_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_1_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_1_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 3 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_1_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_1_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_1_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_1_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 4 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_1_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_1_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 5 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_1_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 6 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_1_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 7 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_1_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 8 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_1_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 9 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_1_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 10 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_1_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 11 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_1_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
	if mhmonth = 12 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_1_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_1_12 = 1;
	end;
run;
data medihmo3b_1;
	set medihmo3b;
	if mhmonth = 1 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	end;
	if mhmonth = 2 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	end;
	if mhmonth = 3 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	end;
	if mhmonth = 4 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_2_4 = 1;
	end;
	if mhmonth = 5 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_2_5 = 1;
	end;
	if mhmonth = 6 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_2_6 = 1;
	end;
	if mhmonth = 7 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_2_7 = 1;
	end;
	if mhmonth = 8 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_2_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_2_8 = 1;
	end;
	if mhmonth = 9 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_2_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_2_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_2_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_2_9 = 1;
	end;
	if mhmonth = 10 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_2_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_2_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_2_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_2_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_2_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_2_10 = 1;
	end;
	if mhmonth = 11 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_2_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_2_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_2_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_2_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_2_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_2_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_2_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_2_11 = 1;
	end;
	if mhmonth = 12 then do;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = '3' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_1 = 'C' then j_2_1 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = '3' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_2 = 'C' then j_2_2 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = '3' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_3 = 'C' then j_2_3 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = '3' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_4 = 'C' then j_2_4 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = '3' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_5 = 'C' then j_2_5 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = '3' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_6 = 'C' then j_2_6 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = '3' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_7 = 'C' then j_2_7 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = '3' then j_2_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_8 = 'C' then j_2_8 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = '3' then j_2_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_9 = 'C' then j_2_9 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = '3' then j_2_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_10 = 'C' then j_2_10 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = '3' then j_2_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_11 = 'C' then j_2_11 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = '3' then j_2_12 = 1;
	if BENE_MDCR_ENTLMT_BUYIN_IND_12 = 'C' then j_2_12 = 1;
	end;
run;

%macro medi;
	data medihmo3a_1;
		set medihmo3a;
		%let month = mhmonth;
		b = &month;
		%do i = '&month' %to 12;
			if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '3' then j_1_&i = 1;
			if BENE_MDCR_ENTLMT_BUYIN_IND_&i = 'C' then j_1_&i = 1;
		%end;
	run;
	
	data medihmo3b_1;
		set medihmo3b;
		%do i = 1 %to 12;
			j_2_&i = 0;
			if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '3' then j_2_&i = 1;
			if BENE_MDCR_ENTLMT_BUYIN_IND_&i = 'C' then j_2_&i = 1;
		%end;
	run;
	
%mend;
%medi;
proc sql;
	create table medihmo3
	as select *
	from medihmo3a_1 a
	left join medihmo3b_1 b
	on a.bene_id = b.bene_id;
quit;

data medihmo3_1;
	set medihmo3;
	rename j_2_1 = j_1_13;
	rename j_2_2 = j_1_14;
	rename j_2_3 = j_1_15;
	rename j_2_4 = j_1_16;
	rename j_2_5 = j_1_17;
	rename j_2_6 = j_1_18;
	rename j_2_7 = j_1_19;
	rename j_2_8 = j_1_20;
	rename j_2_9 = j_1_21;
	rename j_2_10 = j_1_22;
	rename j_2_11 = j_1_23;
	rename j_2_12 = j_1_24;
run;

%macro scan;
	%do i = 2 %to 24;
		%let j = %eval(&i - 1);
		blah = 
