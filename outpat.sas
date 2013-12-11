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

proc transpose data=base_ed1 prefix=ed_start out=start_dates_ed;
by bene_id;
var CLM_FROM_DT;
run;
proc transpose data=base_ed1 prefix=ed_prim_icd out = prim_icd_ed;
by bene_id;
var ICD_DGNS_CD1;
run;
proc transpose data = base_ed1 prefix = ed_icd2_ out = sec_icd_ed;
by bene_id;
var ICD_DGNS_CD2;
run;
proc transpose data=base_ed1 prefix = ed_icd3_ out = third_icd_ed;
by bene_id;
var ICD_DGNS_CD3;
run;
proc transpose data=base_ed1 prefix = ed_icd4_ out = four_icd_ed;
by bene_id;
var ICD_DGNS_CD4;
run;
proc transpose data=base_ed1 prefix = ed_icd5_ out = five_icd_ed;
by bene_id;
var ICD_DGNS_CD5;
run;
proc transpose data=base_ed1 prefix = ed_icd6_ out = six_icd_ed;
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
			set base_ed2 (keep = bene_id ed_start&i ed_prim_icd&i ed_icd2_&i ed_icd3_&i ed_icd4_&i ed_icd5_&i ed_icd6_&i);
			label ed_start&i = "Start of ED Visit (Visit &i)";
			label ed_prim_icd&i = "ICD-9 Diagnosis Code I (Visit &i)";
			label ed_icd2_&i = "ICD-9 Diagnosis Code II (Visit &i)";
			label ed_icd3_&i = "ICD-9 Diagnosis Code III (Visit &i)";
			label ed_icd4_&i = "ICD-9 Diagnosis Code IV (Visit &i)";
			label ed_icd5_&i = "ICD-9 Diagnosis Code V (Visit &i)";
			label ed_icd6_&i = "ICD-9 Diagnosis Code VI (Visit &i)";
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

/************ COSTS ****************/

proc sort data=base2;
	by bene_id CLM_FROM_DT;
run;

data base3;
	set base2;
	rename start = start1;
	rename end = end1;
run;

data base_cost;
	set base3 (keep = bene_id clm_id CLM_FROM_DT CLM_PMT_AMT CLM_THRU_DT start1-start21 end1-end21) ;
run;

/*create indicator to identify op claims fully within hospice stays by dates*/
%macro inhospice;
options mlogic;
	%do i = 1 %to 14;
		data base_cost;
			set base_cost;
			if start&i = . then do;
			start&i = 99999;
			end;
			if end&i = . then do;
			end&i = 99999;
			end;
			/*comparing numerical vs. missing will output that the numerical is always better. thus reaction of these numbers for missing*/
		run;
		data  base_cost;
			set base_cost;
			inhospice&i = 0;
			posthospice&i = 0;
			if CLM_FROM_DT >= start&i and CLM_FROM_DT <= end&i then inhospice&i = 1;
			%let j = %eval(&i + 1);
			if start&j = . then do;
				if CLM_FROM_DT > end&i then posthospice&i = 1;
			end;
			if start&j ~= . then do;
				if CLM_FROM_DT > end&i and CLM_FROM_DT < start&j then posthospice&i = 1;
			end;
		run;
	%end;
%mend;
%inhospice;

data base_cost1;
	set base_cost (keep = BENE_ID CLM_ID CLM_FROM_DT CLM_THRU_DT CLM_PMT_AMT inhospice1-inhospice14 posthospice1-posthospice14);
run;

proc sort data=base_cost1;
	by bene_id clm_from_dt;
run;



%macro cost;
	%do i = 1 %to 14;
		data base_cost1;
			set base_cost1;
			by bene_id;
			retain inhospice_cost&i posthospice_cost&i;
			if first.bene_id then do;
			inhospice_cost&i = 0;
			posthospice_cost&i = 0;
			end;
			if inhospice&i = 1 then do;
			inhospice_cost&i = inhospice_cost&i + CLM_PMT_AMT;
			end;
			if posthospice&i = 1 then do;
			posthospice_cost&i = posthospice_cost&i + CLM_PMT_AMT;
			end;
		run;
	%end;
%mend;
%cost;

data base_cost2;
	set base_cost1;
	by bene_id;
	if last.bene_id;
run;

/*perm dataset*/
data ccw.outpat_cost;
	set base_cost2 (keep = BENE_ID CLM_ID inhospice_cost1-inhospice_cost14 posthospice_cost1-posthospice_cost14);
run;

/*working dataset*/
data outpat_cost;
	set base_cost2 (keep = BENE_ID CLM_ID inhospice_cost1-inhospice_cost14 posthospice_cost1-posthospice_cost14);
run;

data base_count;
	set base_cost1;
run;

proc sort data=base_count;
	by bene_id CLM_FROM_DT ;
run;

%macro count;
	%do i=1 %to 14;
		data base_count;
			set base_count;
			by bene_id;
			retain in_count&i post_count&i;
			in_count&i = in_count&i + inhospice&i;
			post_count&i = post_count&i + posthospice&i;
			if first.bene_id then do;
			in_count&i = inhospice&i;
			post_count&i = posthospice&i;
			end;
		run;
	%end;
%mend;
%count;

data base_count1;
	set base_count;
	by bene_id;
	if last.bene_id;
run;

data test;
	set base_count1;
	if bene_id = 'ZZZZZZZkOkk9yOy';
run;

data base_count_cost;
	set base_count1;
	drop inhospice1-inhospice14 posthospice1-posthospice14 CLM_PMT_AMT;
run;
/*last Start date 14th, not 21st*/

%macro resort;
	%do i = 1 %to 14;
		data resort&i;
			set base_count_cost (keep = bene_id inhospice_cost&i in_count&i posthospice_cost&i post_count&i);
			OPcost_durHS&i = inhospice_cost&i;
			OPcnt_durHS&i = in_count&i;
			OPcost_aftHS&i = posthospice_cost&i;
			OPcnt_aftHS&i = post_count&i;
			drop inhospice_cost&i in_count&i posthospice_cost&i post_count&i;
		run;
	%end;
	data base_count_cost1;
		merge resort1-resort14;
		by bene_id;
	run;
	proc datasets nolist;
		delete resort1-resort14;
	run;
	quit;
%mend;
%resort;

proc sql;
	create table outpat_fin
	as select *
	from base_count_cost1 a
	left join base_ed3 b
	on a.bene_id = b.bene_id;
quit;

data ccw.outpat_fin;
	set outpat_fin;
run;

/*relabel at some point*/

/*summary statistics*/

data op1;
set ccw.outpat_fin;
op_cost=0;                          /*skilled nursing facility admission indicator*/
op_visit=0;
op_ed_count = 0; 
label op_cost="Total Oupatient Cost";
label avg_visit="Total Number of Visits to Outpatient";
label op_ed_count="Total Number of ED visits";
run;

/*macro to run through all ip stays to get count variables*/
%macro op_vars;
data op2;
set op1;
retain op_cost op_visit op_ed_count;
%do i = 1 %to 14;
op_cost = op_cost + OPcost_durHS&i;
op_cost = op_cost + OPcost_aftHS&i;
op_visit = op_visit + OPcnt_durHS&i;
op_visit = op_visit + OPcnt_aftHS&i; 
%end;
%do j = 1 %to 33;
if ed_start&j ~=. then op_ed_count = op_ed_count + 1;
%end;
run;
%mend;

%op_vars;
quit;

proc means data=op2 sum mean median ;
var op_cost op_visit;
run;
proc  means data=op2 sum mean median;
where ed_start1 ~= .;
var op_ed_count;
run;

proc sql;
create table op_total as select * from
ccw.for_medpar a
left join op2 b
on a.bene_id=b.bene_id;
quit;
