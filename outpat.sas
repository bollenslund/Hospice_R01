/*
Code process outpatient MC claims. Variables defined for each outpatietn stay are:
1. Indicator for ED use for each outpatient claim
2. Start/end date
3. Cost
4. Whether or not claim was within a hospice stay

*/

libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

/*Initialize datasets for base claims and revenue center codes*/

data hospice;
	set ccw.unique;
run;
data base;
	set merged.outpatient_base_claims_j;
run;
data revenue;
	set merged.outpatient_revenue_center_j;
run;

proc freq data=revenue;
	table REV_CNTR;
run;
proc freq data=base;
	table CLM_SRVC_CLSFCTN_TYPE_CD /missprint;
run;


/*drop beneficiary ids that aren't in sample as defined in 
master beneficiary summary file processing (age, ins status, hs stay)*/
proc sql;
create table base0 as select * from base
where bene_id in (select bene_id from ccw.for_medpar);
quit;
proc sql;
create table revenue0 as select BENE_ID,CLM_ID,REV_CNTR from revenue
where bene_id in (select bene_id from ccw.for_medpar) ;
quit;

data hospice1;
	set hospice (keep = bene_id start end start2-start21 end2-end21);
run;

/*bring hospice stay dates into outpatient claims dataset*/
proc sql;
	create table base1
	as select *
	from base0 a
	left join hospice1 b
	on a.bene_id = b.bene_id;
quit;

/*only keep inpatient claims after first hs enrollment*/
data base2;
	set base1;
	if CLM_FROM_DT < start then delete;
	if start = . then delete;
run;

proc sort data=revenue0;
	by bene_id clm_id REV_CNTR;
run;

/**************************************************************************/
/* Identify emergency department use */
/**************************************************************************/


/*keep only revenue center codes for ED use*/
data ed;
	set revenue0;
	if REV_CNTR >= 450 and REV_CNTR < 460;
	ed = 1;
run;
proc sort data=ed;
	by bene_id clm_id;
run;

/*bring in ed cost to base op claims dataset - can use this to get
indicator for ED use if cost>0 and not null*/
proc sql;
	create table base_ed
	as select *
	from base2 a
	left join ed b
	on a.clm_id = b.clm_id;
quit;

data base_ed1;
	set base_ed (keep = bene_id clm_id CLM_FROM_DT ICD_DGNS_CD1 ICD_DGNS_CD2 ICD_DGNS_CD3 ICD_DGNS_CD4 ICD_DGNS_CD5 ICD_DGNS_CD6 ed);
	if ed = . then delete;
run;

proc sort data=base_ed1 nodupkey;
	by bene_id clm_from_dt;
run;

proc transpose data=base_ed1 prefix=start out=start_dates_ed;
by bene_id;
var CLM_FROM_DT;
run;
proc transpose data=base_ed1 prefix=prim_icd out = prim_icd_ed;
by bene_id;
var ICD_DGNS_CD1;
run;
proc transpose data = base_ed1 prefix = icd2_ out = sec_icd_ed;
by bene_id;
var ICD_DGNS_CD2;
run;
proc transpose data=base_ed1 prefix = icd3_ out = third_icd_ed;
by bene_id;
var ICD_DGNS_CD3;
run;
proc transpose data=base_ed1 prefix = icd4_ out = four_icd_ed;
by bene_id;
var ICD_DGNS_CD4;
run;
proc transpose data=base_ed1 prefix = icd5_ out = five_icd_ed;
by bene_id;
var ICD_DGNS_CD5;
run;
proc transpose data=base_ed1 prefix = icd6_ out = six_icd_ed;
by bene_id;
var ICD_DGNS_CD6;
run;

data base_ed2;
	merge start_dates_ed prim_icd_ed sec_icd_ed third_icd_ed four_icd_ed five_icd_ed six_icd_ed;
	by bene_id;
	drop _NAME_ _LABEL_;
run;

%macro resort;
	%do i = 1 %to 33;
		data resort&i;
			set base_ed2 (keep = bene_id start&i prim_icd&i icd2_&i icd4_&i icd5_&i icd6_&i);
		run;
	%end;
	data base_ed3;
		merge resort1-resort33;
		by bene_id;
	run;
	proc datasets nolist;
		delete resort1-resort33;
	run;
	quit;
%mend;
%resort;

data ccw.ed;
	set base_ed3;
run;

/*brings in revenue center charges for first rc entry for each claim*/
proc sql;
	create table base_ed_1
	as select a.*, b.REV_CNTR_TOT_CHRG_AMT
	from base_ed a
	left join revenue1 b
	on a.clm_id = b.clm_id
	and a.CLM_THRU_DT = b.CLM_THRU_DT;
quit;
proc sort data=base_ed_1;
	by bene_id CLM_FROM_DT;
run;

/*list of op claims, one row per claim, w/ hs start/end dates*/
data base_ed1;
	set base_ed_1;
	start1 = start; /*hs start var renamed*/
	end1 = end;     /*hs end var renamed*/
	start = CLM_FROM_DT;  /*op start date */
	end = CLM_THRU_DT;    /*op end date */
	label start1 = "Start Date (HS Stay 1)";
	label end1 = "End Date (HS Stay 1)";
	label start = "Start of OP Claim";
	label end = "End of OP Claim";
	format start date9. end date9. start1 date9. end1 date9.;
run;

/*create indicator to identify op claims fully within hospice stays by dates*/
%macro inhospice;
options mlogic;
	%do i = 1 %to 21;
		data base_ed1;
			set base_ed1;
			inhospice&i = 0;
			if end <= end&i and start >= start&i then inhospice&i = 1;
		run;
	%end;
%mend;
%inhospice;

/*creates indicator for op claim within any hs stay
drops indicators for individual hs stays - not sure we want to drop them yet*/
/*************************************************************************/
/*************************************************************************/
/*************************************************************************/
/*************************************************************************/
data base_ed1a;
	set base_ed1;
	inhospice = 0;
	if inhospice1 = 1 or inhospice2 = 1  or inhospice3 = 1 or inhospice4 = 1 or inhospice5 = 1 or inhospice6 = 1 or inhospice7 = 1 or inhospice8 = 1 or inhospice9 = 1 or inhospice10 = 1
	or inhospice11 = 1 or inhospice12 = 1 or inhospice13 = 1 or inhospice14 = 1 or inhospice15 = 1 or inhospice16 = 1 or inhospice17 = 1 or inhospice18 = 1 or inhospice19 = 1 or inhospice20 = 1
	or inhospice21 = 1 then inhospice = 1;
	drop inhospice1-inhospice21;
run;

/*identify op claims partially within hs stay, 251 claims
What do we do with these claims?? Ask Melissa*/
data test;
	set base_ed1 (keep = start end start1 end1 inhospice1);
	if start > start1 and end > end1 and start < end1 then i = 1;
run;
proc freq data=test;
	table i;
run;
/*337 who start during hospice and end claim out of the hospice start/end date*/
data test1;
	set test;
	if i = 1;
run;

proc freq data=base_ed1a;
	table inhospice;
run;

proc sort data=base_ed1a;
	by bene_id CLM_FROM_DT;
run;

/*check of length of stay for the outpatient claims*/
data testop_1;
set base_ed1a;
los=end-start+1;
run;

proc freq;
table los /missprint;
run;

/*create count variable for number of claims per bene id
max is 197*/
data test;
	set base_ed1a;
	by bene_id;
	retain i;
	i = i+1;
	if first.bene_id then i = 0;
run;
proc freq data=test;
	table i;
run;

/*transpose start dates so get start1, start2... start197 variables*/
proc transpose data = base_ed1a prefix = start out=start_dates;
	by bene_id;
	var start;
run;
/*transpose end dates*/
proc transpose data= base_ed1a prefix = end out=end_dates;
	by bene_id;
	var end;
run;
/*transpose ED costs*/
proc transpose data= base_ed1a prefix = edcost out=edcost;
	by bene_id;
	var cost;
run;
/*transpose principle diagnosis*/
proc transpose data= base_ed1a prefix = prim_icd out=icd;
	by bene_id;
	var PRNCPAL_DGNS_CD;
run;
/*transpose total cost regardless of ED
*********************************
Need to pull total claim payment amount, not this rev center
cost **************************************
*/
proc transpose data= base_ed1a prefix = total_cost out=cost;
	by bene_id;
	var REV_CNTR_TOT_CHRG_AMT;
run;
/*an indicator saying whether the claim is within hospice day*/
proc transpose data= base_ed1a prefix = inhospice out=hospice_indic;
	by bene_id;
	var inhospice;
run;

/*bring start, end, costs and principle dx together into single dataset*/
data base_ed2;
	merge start_dates end_dates edcost icd cost hospice_indic;
	by bene_id;
	drop _NAME_ _LABEL_;
run;

/*re-sort variables so claim #1 variables all together, etc.*/
%macro resort;
	%do i = 1 %to 218;
		data resort&i;
			set base_ed2 (keep = bene_id start&i end&i inhospice&i total_cost&i edcost&i prim_icd&i);
		run;
	%end;
	data base_ed3;
		merge resort1-resort218;
		by bene_id;
	run;
	proc datasets nolist;
		delete resort1-resort218;
	run;
%mend;
%resort;

/*save outpatient claims dataset to the working folder*/
data ccw.outpat;
	set base_ed3;
run;
