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


%macro months(mos);
data mhstartmonth&mos;
	set medihmo3a;
	if mhmonth = &mos;
	%let m&mos = &mos;
	%do i = &&m&mos %to 12;
		%put &i;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '3' then j_1_&i = 1;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = 'C' then j_1_&i = 1;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '0' then j_1_&i = 0;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '1' then j_1_&i = 0;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '2' then j_1_&i = 0;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = 'A' then j_1_&i = 0;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = 'B' then j_1_&i = 0;
	%end;
run;
data mhendmonth&mos;
	set medihmo3b;
	if mhmonth = &mos;
	%let m&mos = %eval(&mos-1);
	%do i = 1 %to &&m&mos;
		%let lim = %eval(&i + 12);
		%put &i &lim;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '3' then j_1_&lim = 1;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = 'C' then j_1_&lim = 1;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '0' then j_1_&lim = 0;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '1' then j_1_&lim = 0;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = '2' then j_1_&lim = 0;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = 'A' then j_1_&lim = 0;
		if BENE_MDCR_ENTLMT_BUYIN_IND_&i = 'B' then j_1_&lim = 0;
	%end;
run;
proc sql;
	create table mhmonth&mos
	as select *
	from mhstartmonth&mos a
	left join mhendmonth&mos b
	on a.bene_id = b.bene_id;
quit;
/*
proc datasets nolist;
	delete mhstartmonth&mos mhendmonth&mos;
run;
*/
data mo&mos;
	set mhmonth&mos;
	retain indicator i;
	i = 1;
	indicator = 0;
	%let end = %eval(&mos + 10);
	%put &mos &end;
	instart = j_1_&mos;
	list = "           ";
	%do i = &mos %to &end;
		%let k = %eval(&i + 1);
		%put &i &k;
		i = i + 1;
		if j_1_&k ~= j_1_&i then do;
		indicator = indicator + 1;
		i1 = put(i,8.);
		list = catx(',',list,i1);
		end;
	%end;
	insend = j_1_&k;
run;
/*
proc datasets nolist;
	delete mhmonth&mos;
run;
*/
proc sort data = mo&mos;
	by bene_id;
run;
%mend;
%months(1);%months(2);%months(3);%months(4);%months(5);%months(6);%months(7);%months(8);
%months(9);%months(10);%months(11);%months(12);



%macro testing;
	%do i = 1 %to 12;
		data mos&i;
			set mo&i;
			if indicator > 1;
		run;
	%end;
%mend;
%testing;

data test;
	set Mhstartmonth4;
	if bene_id = 'ZZZZZZZ3k3kkZuk';
run;
data test1;
	set Mhendmonth4;
	if bene_id = 'ZZZZZZZ3k3kkZuk';
run;
