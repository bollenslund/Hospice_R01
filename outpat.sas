libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';


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
	table CLM_OP_SRVC_TYPE_TB ;
run;

data ed;
	set revenue;
	if REV_CNTR >= 450 and REV_CNTR < 460;
run;
proc sort data=ed;
	by bene_id clm_id clm_thru_dt;
run;
data ed1;
	set ed;
	retain cost i;
	by bene_id clm_id;
	cost = cost + REV_CNTR_PMT_AMT_AMT;
	i = i + 1;
	if first.clm_id then do; cost = REV_CNTR_PMT_AMT_AMT; i = 0; end;
run;

proc freq data=ed1;
	table i;
run;

data ed2;
	set ed1;
	by bene_id clm_id;
	if last.clm_id;
run;

proc sql;
	create table base_ed
	as select a.*, b.cost
	from base a
	left join ed2 b
	on a.clm_id = b.clm_id
	and a.CLM_THRU_DT = b.CLM_THRU_DT;
quit;

data base_ed1;
	set base_ed;
	if cost = . then delete;
	start = CLM_FROM_DT;
	end = CLM_THRU_DT;
	format start date9. end date9.;
run;

proc sort data=base_ed1;
	by bene_id;
run;

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

proc transpose data = base_ed1 prefix = start out=start_dates;
	by bene_id;
	var start;
run;

proc transpose data= base_ed1 prefix = end out=end_dates;
	by bene_id;
	var end;
	label 
run;

proc transpose data= base_ed1 prefix = cost out=cost;
	by bene_id;
	var cost;
run;

proc transpose data= base_ed1 prefix = prim_icd out=icd;
	by bene_id;
	var PRNCPAL_DGNS_CD;
run;

data base_ed2;
	merge start_dates end_dates cost icd;
	by bene_id;
	drop _NAME_;
run;

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

data ccw.outpat;
	set base_ed3;
run;
