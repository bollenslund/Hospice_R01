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
	%let m&mos = &mos;
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

proc datasets nolist;
	delete mhstartmonth&mos mhendmonth&mos;
run;

data mo&mos;
	set mhmonth&mos;
	retain indicator i;
	i = 1;
	indicator = 0;
	%let end = %eval(&mos + 11);
	%put &mos &end;
	instart = j_1_&mos;
	list = "           ";
	%do i = &mos %to &end;
		%let k = %eval(&i + 1);
		%put &i &k;
		if j_1_&k ~= j_1_&i then do;
		indicator = indicator + 1;
		i1 = put(i,8.);
		list = catx(',',list,i1);
		end;
		i = i + 1;
	%end;
	insend = j_1_&k;
run;

proc datasets nolist;
	delete mhmonth&mos;
run;

proc sort data = mo&mos;
	by bene_id;
run;
%mend;
%months(1);%months(2);%months(3);%months(4);%months(5);%months(6);%months(7);%months(8);
%months(9);%months(10);%months(11);%months(12);

data months;
	set mo1 mo2 mo3 mo4 mo5 mo6 mo7 mo8 mo9 mo10 mo11 mo12;
run;
proc datasets nolist;
	delete mo1 mo2 mo3 mo4 mo5 mo6 mo7 mo8 mo9 mo10 mo11 mo12 mos1 mos2 mos3 mos4 mos5 mos6 mos7 mos8 mos9 mos10 mos11 mos12;
run;
proc freq data=months;
	table indicator;
run;
data months1;
	set months;
	if indicator = 0 and instart = 0 and insend=0 then delete;
run;
data months2;
	retain bene_id start indicator instart insend list;
	set months1 (keep = bene_id start indicator list instart insend);
run;
proc sort data=months2;
	by bene_id;
run;
data ccw.medi_months;
	set months2;
run;
proc freq data=medihmo3a;
	table BENE_HMO_IND_1;
run;
%macro hmonths(mos);
data hstartmonth&mos;
	set medihmo3a;
	if mhmonth = &mos;
	%let m&mos = &mos;
	%do i = &&m&mos %to 12;
		%put &i;
		if BENE_HMO_IND_&i = '0' then j_1_&i = 0;
		if BENE_HMO_IND_&i = '1' then j_1_&i = 1;
		if BENE_HMO_IND_&i = '2' then j_1_&i = 1;
		if BENE_HMO_IND_&i = '4' then j_1_&i = 1;
		if BENE_HMO_IND_&i = 'A' then j_1_&i = 1;
		if BENE_HMO_IND_&i = 'B' then j_1_&i = 1;
		if BENE_HMO_IND_&i = 'C' then j_1_&i = 1;
	%end;
run;
data hendmonth&mos;
	set medihmo3b;
	if mhmonth = &mos;
	%let m&mos = &mos;
	%do i = 1 %to &&m&mos;
		%let lim = %eval(&i + 12);
		%put &i &lim;
		if BENE_HMO_IND_&i = '0' then j_1_&lim = 0;
		if BENE_HMO_IND_&i = '1' then j_1_&lim = 1;
		if BENE_HMO_IND_&i = '2' then j_1_&lim = 1;
		if BENE_HMO_IND_&i = '4' then j_1_&lim = 1;
		if BENE_HMO_IND_&i = 'A' then j_1_&lim = 1;
		if BENE_HMO_IND_&i = 'B' then j_1_&lim = 1;
		if BENE_HMO_IND_&i = 'C' then j_1_&lim = 1;
	%end;
run;
proc sql;
	create table hmonth&mos
	as select *
	from hstartmonth&mos a
	left join hendmonth&mos b
	on a.bene_id = b.bene_id;
quit;

proc datasets nolist;
	delete hstartmonth&mos hendmonth&mos;
run;

data hmo&mos;
	set hmonth&mos;
	retain indicator i;
	i = 1;
	indicator = 0;
	%let end = %eval(&mos + 11);
	%put &mos &end;
	instart = j_1_&mos;
	list = "           ";
	%do i = &mos %to &end;
		%let k = %eval(&i + 1);
		%put &i &k;
		if j_1_&k ~= j_1_&i then do;
		indicator = indicator + 1;
		i1 = put(i,8.);
		list = catx(',',list,i1);
		end;
		i = i + 1;
	%end;
	insend = j_1_&k;
run;

proc datasets nolist;
	delete hmonth&mos;
run;

proc sort data = hmo&mos;
	by bene_id;
run;
%mend;
%hmonths(1);%hmonths(2);%hmonths(3);%hmonths(4);%hmonths(5);%hmonths(6);%hmonths(7);%hmonths(8);
%hmonths(9);%hmonths(10);%hmonths(11);%hmonths(12);

data hmonths;
	set hmo1 hmo2 hmo3 hmo4 hmo5 hmo6 hmo7 hmo8 hmo9 hmo10 hmo11 hmo12;
run;
proc datasets nolist;
	delete hmo1 hmo2 hmo3 hmo4 hmo5 hmo6 hmo7 hmo8 hmo9 hmo10 hmo11 hmo12;
run;

data test;
	set hmonths;
	if indicator = 0 and instart = 1 and insend = 1;
run;

data hmonths1;
	retain bene_id start indicator instart insend list;
	set hmonths (keep = bene_id start indicator list instart insend);
	if indicator = 0 and instart = 1 and insend=1 then delete;
	if indicator >= 1 and instart = 0 and insend=1 then delete;
	if indicator >= 1 and instart = 1 and insend=0 then delete;
	if indicator >= 1 and instart = 1 and insend = 1 then delete;
	if indicator >= 1 and instart = 0 and insend = 0 then delete;
run;
/*from 210947 to 168269 we should go over*/

data months3;
	set months2;
	medi_i = indicator;
	label medi_i = "Indicator of a change in status in Medicare plan";
	medi_start = instart;
	label medi_start = "Status of Medicare at the start of 12 month period";
	medi_end = insend;
	label medi_end = "Status of Medicare at the end of the 12 month period";
	medi_change = list ;
	label medi_change = "List of the months of when Medicare status changed";
	drop indicator instart insend list;
run;

data hmonths2;
	set hmonths1;
	hmo_i = indicator;
	label hmo_i = "Indicator of a change in status in HMO plan";
	hmo_start = instart;
	label hmo_start = "Status of HMO at the start of 12 month period";
	hmo_end = insend;
	label hmo_end = "Status of HMO at the end of the 12 month period";
	hmo_change = list;
	label hmo_change = "List of the months of when HMO status changed";
	drop indicator instart insend list;
run;

proc sql;
	create table medi_hmo
	as select *
	from months3 a
	left join hmonths2 b
	on a.bene_id = b.bene_id
	and a.start = b.start;
quit;

data ccw.medi_hmo;
	set medi_hmo;
run;

data mb_ab_fin3;
	merge mb_ab_fin2 medi_hmo;
	by bene_id;
run;

data test;
	set mb_ab_fin3;
	if medi_i = .;
run;

proc sql;
	create table test1
	as select *
	from test a
	left join medihmo3a b
	on a.bene_id = b.bene_id;
quit;
data test1;
	set test1;
	if BENE_ENROLLMT_REF_YR = . then delete;
run;
proc sql;
	create table test2
	as select *
	from test a
	left join medihmo3b b
	on a.bene_id = b.bene_id;
quit;
