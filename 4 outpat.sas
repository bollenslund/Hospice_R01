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

/*this hospice dataset is already restricted to the sample*/
data hospice;
	set  ccw.final_hs;
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
proc freq data=base ;
	table CLM_SRVC_CLSFCTN_TYPE_CD /missprint;
run;


/*drop beneficiary ids that aren't in sample as defined in 
master beneficiary summary file processing (age, ins status, hs stay)*/
proc sql;
create table base0 as select * from base
where bene_id in (select bene_id from hospice);
quit;

proc sql;
create table revenue0 as select BENE_ID,CLM_ID,REV_CNTR from revenue
where bene_id in (select bene_id from hospice) ;
quit;

data hospice1;
	set hospice (keep = bene_id start end start2-start21 end2-end21 count_hs_stays);
run;

/*bring hospice stay dates into outpatient claims dataset*/
proc sql;
	create table base1
	as select *
	from base0 a
	left join hospice1 b
	on a.bene_id = b.bene_id;
quit;

data test556;
set base1;
if count_hs_stays=21;
run;

/*only keep outpatient claims after first hs enrollment
also, don't keep those that aren't in the sample
Note - for beneficiaries with 1 or more op claim, the maximum number of hospice
stays is 14 so all loops from here on in op processing will go for 14 iterations*/
data base2;
	set base1;
	if CLM_FROM_DT < start then delete;
	if start = . then delete;
run;

proc freq data=base2;
table count_hs_stays;
run;
/*
proc sort data=base2 out=base_test nodupkey;
by bene_id clm_from_dt;
run;
*/
proc sort data=base2 out=base_test2 nodupkey;
by bene_id clm_id;
run;

proc sort data=revenue0;
	by bene_id clm_id REV_CNTR;
run;

/**************************************************************************/
/* Identify emergency department use 
This is done using revenue center codes. If any ed revenue center code
is present on the claim, set the indicator for ed use = 1
This is different from how we identify ed use in the inpatient claims
(for ip claims, look at ed costs > 0 = ed visit)*/
/**************************************************************************/


/*keep only revenue center codes for ED use
set ed indicator = 1 if ed code is present for the claim*/
data ed;
	set revenue0;
	if REV_CNTR >= 450 and REV_CNTR < 460;
	ed = 1;
run;
proc sort data=ed;
	by bene_id clm_id;
run;

/*count of unique claim ids with ed codes present - 274154*/
proc sql;
       create table unique_ed as select count(distinct(clm_id)) as clm_count from ed;
       quit;
proc print;title 'count unique claims';
run;

/*keep just the indicator of ed use for each claim, one row per claim*/
data ed_1;
set ed(drop=REV_CNTR);
by bene_id clm_id;
if first.clm_id;
run;

/*keep only those ed indicators from rev codes that are in list of op claims post-first hs enrollment
22270 claims*/
proc sql;
create table base_ed_test as select * from ed_1
 where clm_id in (select clm_id from base2);
quit;

/*bring in ed indicator to base op claims dataset -
so if any revenue code present for ed use, identify op claim as an ed visit*/
proc sql;
	create table base_ed
	as select *
	from base_ed_test a
	left join base2 b
	on a.clm_id = b.clm_id;
quit;

proc freq; table ed; run;

data base_ed1;
	set base_ed (keep = bene_id clm_id CLM_FROM_DT ICD_DGNS_CD1 ICD_DGNS_CD2 ICD_DGNS_CD3 ICD_DGNS_CD4 
		ICD_DGNS_CD5 ICD_DGNS_CD6 ed CLM_PMT_AMT);
	if ed = . then delete;
run;

proc sort data=base_ed1; by bene_id clm_from_dt;
run;

/*looking at claim from dates to see there are cases where a bene id has 2 ed visit claims on the same day*/
data base_ed_test3;
set base_ed1;
retain i;
by bene_id clm_from_dt;
if first.clm_from_dt then i=0;
i=i+1;
run;

/*sort before transpose to get long dataset*/
proc sort data=base_ed1;
	by bene_id clm_from_dt;
run;

/*ED visit date is assumed to be start date of op claim*/
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

/*save dataset - 14057 bids in sample have outpatient claims with at least 1 ed visit
This dataset is only bids with at least 1 ed visit*/
data ccw.ed;
	set base_ed3;
run;

/*********************************************************************/
/************                  COSTS                  ****************/
/*********************************************************************/

/* start with list of base op claims for bene ids in our sample and after 
first hospice admission date
This has all hospice stay start and end dates included*/
proc sort data=base2;
	by bene_id CLM_FROM_DT;
run;

/*rename hospice start and end date variables*/
data base3;
	set base2;
	rename start = start1;
	rename end = end1;
run;

/*only keep variables needed to calculate costs for op claims*/
data base_cost;
	set base3 (keep = bene_id clm_id CLM_FROM_DT CLM_PMT_AMT CLM_THRU_DT start1-start14 end1-end14) ;
run;

/*create indicator to identify op claims that start during or after hospice stays by dates
Loop 14 times - once for each hospice stay start/end date pair*/
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
			/*comparing numerical vs. missing will output that the numerical is always better. 
                        thus reaction of these numbers for missing*/
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

proc freq data=base_cost1;
table inhospice1-inhospice14 posthospice1-posthospice14;
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

/*36077 beneficiaries have at least 1 op claim*/
data base_cost2;
	set base_cost1;
	by bene_id;
	if last.bene_id;
run;

/*check comparison of all op claims - checks out with the 36077 above*/
proc sql;
       create table unique_op as select count(distinct(bene_id)) as bene_count from base2;
       quit;
proc print;title 'count unique beneids with op claim';
run;

/*perm dataset*/
data ccw.outpat_cost;
	set base_cost2 (keep = BENE_ID CLM_ID inhospice_cost1-inhospice_cost14 posthospice_cost1-posthospice_cost14;
run;

/*working dataset*/
data outpat_cost;
	set base_cost2 (keep = BENE_ID CLM_ID inhospice_cost1-inhospice_cost14 posthospice_cost1-posthospice_cost14);
run;

/*get count of op claims within each hospice stay and between hospice stays*/
/*this is list of all op claims for the sample after the first hs enroll date*/
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

/*merge in ed information and cost information to get a complete outpatient dataset*/
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

/*summary statistics for the outpatient dataset
(not for overall sample)*/

data op1;
set ccw.outpat_fin;
op_cost=0;
op_visit=0;
op_ed_count = 0; 
label op_cost="Total Oupatient Cost";
label op_visit="Total Number of Visits to Outpatient";
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
op_visit_ind=0;
if op_visit>0 & op_visit~=. then op_visit_ind=1;
op_ed_ind=0;
if op_ed_count>0 & op_ed_count~=. then op_ed_ind=1;
label op_ed_ind="Indicator for any ED visit (from OP claims)"
op_visit_ind="Indicator for any OP claim";
run;
%mend;

%op_vars;
quit;

proc means data=op2 sum mean median ;
var op_cost op_visit op_ed_ind op_visit_ind;
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


data op_total2;
set op_total;
if op_ed_ind=. then op_ed_ind=0;
if op_visit_ind=. then op_visit_ind=0;
label op_ed_ind = "ED in OP Visit Indicator";
label op_visit_ind = "Visit to Outpatient Indicator";
drop BENE_ENROLLMT_REF_YR FIVE_PERCENT_FLAG ENHANCED_FIVE_PERCENT_FLAG COVSTART CRNT_BIC_CD 
STATE_CODE BENE_COUNTY_CD BENE_ZIP_CD BENE_AGE_AT_END_REF_YR BENE_BIRTH_DT BENE_DEATH_DT NDI_DEATH_DT BENE_SEX_IDENT_CD BENE_RACE_CD BENE_VALID_DEATH_DT_SW
lengthmedi lengthmo allmedistatus1 allhmostatus1 allmedistatus2 allhmostatus2 allmedistatus3 allhmostatus3 start end;
if op_cost = . then op_cost = 0;
if op_visit = . then op_visit = 0;
if op_ed_count = . then op_ed_count = 0;
run;

data ccw.outpat_fin;
set op_total2;
run;
ods rtf body = '\\home\users$\leee20\Documents\Downloads\Melissa\outpat.rtf';
proc contents data=ccw.outpat_fin varnum;
run;
ods rtf close;
data hs_mb_others;
set ccw.final_hs_mb_ip_snf;
run;

data final_sample;
set ccw.outpat_fin;
run;

proc sql;
create table hs_mb_ip_snf_op as select * from hs_mb_others a
left join final_sample b
on a.bene_id = b.bene_id;
quit;

data ccw.final_hs_mb_ip_snf_op;
set hs_mb_ip_snf_op;
run;

proc freq data=op_total2;
table op_visit_ind op_ed_ind /missprint;
run;

/*save working dataset with full sample and additional variables coded*/
data ccw.op_sample;
set op_total2;
run;

/*****************************************************************/
/*Output to stata for sum stats*/
/*****************************************************************/
proc export data=ccw.op_sample
	outfile='J:\Geriatrics\Geri\Hospice Project\Hospice\working\op_sample.dta'
	replace;
	run;
