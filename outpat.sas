libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

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

/**************************************************************************/
/* Identify emergency department use */
/**************************************************************************/

data hospice1;
	set hospice (keep = bene_id start end start2-start21 end2-end21);
run;

proc sql;
	create table base1
	as select *
	from base a
	left join hospice1 b
	on a.bene_id = b.bene_id;
quit;

data base2;
	set base1;
	if CLM_FROM_DT < start then delete;
	if start = . then delete;
run;

proc sort data=revenue;
	by bene_id clm_id REV_CNTR;
run;

data revenue1;
	set revenue;
	by bene_id clm_id;
	if first.clm_id;
run;

proc freq data=revenue1;
	table REV_CNTR;
run;
/*all total values*/


/*keep only revenue center codes for ED use*/
data ed;
	set revenue;
	if REV_CNTR >= 450 and REV_CNTR < 460;
run;
proc sort data=ed;
	by bene_id clm_id clm_thru_dt;
run;
/*creates total cost of ed use across all ed rev. codes by claim id*/
data ed1;
	set ed;
	retain cost i;
	by bene_id clm_id;
	cost = cost + REV_CNTR_PMT_AMT_AMT;
	i = i + 1;
	if first.clm_id then do; cost = REV_CNTR_PMT_AMT_AMT; i = 0; end;
run;

proc freq data=ed1;
	table i REV_CNTR;
run;

/*just keep last ed entry per claim id to get total cost
331828 claims*/
data ed2;
	set ed1;
	by bene_id clm_id;
	if last.clm_id;
run;

/*bring in ed cost to base op claims dataset*/
proc sql;
	create table base_ed
	as select a.*, b.cost
	from base2 a
	left join ed2 b
	on a.clm_id = b.clm_id
	and a.CLM_THRU_DT = b.CLM_THRU_DT;
quit;

proc sort data=base_ed;
	by bene_id CLM_FROM_DT;
run;

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

/*only keep claims with ed cost
331828 claims*/
data base_ed1;
	set base_ed_1;
	start = CLM_FROM_DT;
	end = CLM_THRU_DT;
	format start date9. end date9.;
run;

proc sort data=base_ed1;
	by bene_id CLM_FROM_DT;
run;

/*check of length of stay for these outpatient ed claims*/
data testop_1;
set base_ed1;
los=end-start+1;
run;

proc freq;
table los /missprint;
run;

/*create count variable for number of claims per bene id
max is 198*/
data test;
	set base_ed1;
	by bene_id;
	retain i;
	i = i+1;
	if first.bene_id then i = 0;
run;
proc freq data=test;
	table i;
run;

/*transpose start dates so get start1, start2... start198 variables*/
proc transpose data = base_ed1 prefix = start out=start_dates;
	by bene_id;
	var start;
run;
/*transpose end dates*/
proc transpose data= base_ed1 prefix = end out=end_dates;
	by bene_id;
	var end;
run;
/*transpose costs*/
proc transpose data= base_ed1 prefix = cost out=cost;
	by bene_id;
	var cost;
run;
/*transpose principle diagnosis*/
proc transpose data= base_ed1 prefix = prim_icd out=icd;
	by bene_id;
	var PRNCPAL_DGNS_CD;
run;
/*bring start, end, costs and principle dx together into single dataset*/
data base_ed2;
	merge start_dates end_dates cost icd;
	by bene_id;
	drop _NAME_ _LABEL_;
run;

/*re-sort variables so claim #1 variables all together, etc.*/
%macro resort;
	%do i = 1 %to 199;
		data resort&i;
			set base_ed2 (keep = bene_id start&i end&i cost&i prim_icd&i);
		run;
	%end;
	data base_ed3;
		merge resort1-resort199;
		by bene_id;
	run;
	proc datasets nolist;
		delete resort1-resort199;
	run;
%mend;
%resort;

/*save outpatient claims dataset to the working folder*/
data ccw.outpat;
	set base_ed3;
run;
