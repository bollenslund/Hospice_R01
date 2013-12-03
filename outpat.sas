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
	start1 = start;
	end1 = end;
	start = CLM_FROM_DT;
	end = CLM_THRU_DT;
	label start1 = "Start Date (Stay 1)";
	label end1 = "End Date (Stay 1)";
	label start = "Start of Claim";
	label end = "End of Claim";
	format start date9. end date9. start1 date9. end1 date9.;
run;

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

data base_ed1a;
	set base_ed1;
	inhospice = 0;
	if inhospice1 = 1 or inhospice2 = 1  or inhospice3 = 1 or inhospice4 = 1 or inhospice5 = 1 or inhospice6 = 1 or inhospice7 = 1 or inhospice8 = 1 or inhospice9 = 1 or inhospice10 = 1
	or inhospice11 = 1 or inhospice12 = 1 or inhospice13 = 1 or inhospice14 = 1 or inhospice15 = 1 or inhospice16 = 1 or inhospice17 = 1 or inhospice18 = 1 or inhospice19 = 1 or inhospice20 = 1
	or inhospice21 = 1 then inhospice = 1;
	drop inhospice1-inhospice21;
run;
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

/*check of length of stay for these outpatient ed claims*/
data testop_1;
set base_ed1a;
los=end-start+1;
run;

proc freq;
table los /missprint;
run;

/*create count variable for number of claims per bene id
max is 218*/
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

/*transpose start dates so get start1, start2... start198 variables*/
proc transpose data = base_ed1a prefix = start out=start_dates;
	by bene_id;
	var start;
run;
/*transpose end dates*/
proc transpose data= base_ed1a prefix = end out=end_dates;
	by bene_id;
	var end;
run;
/*transpose costs*/
proc transpose data= base_ed1a prefix = edcost out=edcost;
	by bene_id;
	var cost;
run;
/*transpose principle diagnosis*/
proc transpose data= base_ed1a prefix = prim_icd out=icd;
	by bene_id;
	var PRNCPAL_DGNS_CD;
run;
/*transpose total cost regardless of ED*/
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
