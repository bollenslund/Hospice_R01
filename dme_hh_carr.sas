libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

/*dme costs*/

data dme;
	set merged.dme_claims_j;
run;

proc sort data=dme;
by bene_id clm_id CLM_FROM_DT;
run;

proc sql;
create table dme1 as select a.*, b.start, b.end from dme a
left join ccw.for_medpar b
on a.bene_id = b.bene_id;
quit;

/*should I get rid of zero costs?*/

data dme1;
	set dme1;
	if start ~=.;
	if clm_from_dt > start;
	if CLM_PMT_AMT ~= 0;
run;

proc sort data=dme1;
by bene_id CLM_FROM_DT;
run;

data hospice;
	set ccw.unique;
run;

data hospice1;
	set hospice (keep = bene_id start end start2-start14 end2-end14);
run;

proc sql;
	create table dme2
	as select *
	from dme1 a
	left join hospice1 b
	on a.bene_id = b.bene_id;
quit;

data dme2;
	set dme2;
	rename start = start1;
	rename end = end1;
run;

data dme_cost;
	set dme2 (keep = bene_id clm_id CLM_FROM_DT CLM_PMT_AMT CLM_THRU_DT start1-start14 end1-end14) ;
run;

%macro inhospice;
options mlogic;
	%do i = 1 %to 14;
		data dme_cost;
			set dme_cost;
			if start&i = . then do;
			start&i = 99999;
			end;
			if end&i = . then do;
			end&i = 99999;
			end;
			/*comparing numerical vs. missing will output that the numerical is always better. thus reaction of these numbers for missing*/
		run;
		data dme_cost;
			set dme_cost;
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

proc freq data=dme_cost;
	table inhospice1 ;
run;

data dme_cost1;
	set dme_cost (keep = BENE_ID CLM_ID CLM_FROM_DT CLM_THRU_DT CLM_PMT_AMT inhospice1-inhospice14 posthospice1-posthospice14);
run;

proc freq data=dme_cost1;
	table posthospice13;
run;

proc sort data=dme_cost1;
	by bene_id clm_from_dt;
run;

%macro cost;
	%do i = 1 %to 14;
		data dme_cost1;
			set dme_cost1;
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

proc freq data=dme_cost1;
	table inhospice_cost8;
run;

data dme_cost2;
	set dme_cost1;
	by bene_id;
	if last.bene_id;
run;

data dme_cost3;
	set dme_cost2 (keep = BENE_ID CLM_ID inhospice_cost1-inhospice_cost8 posthospice_cost1-posthospice_cost7);
run;

data ccw.dme_cost;
	set dme_cost3;
run;

/*Home Health Costs*/

data hha;
	set merged.hha_base_claims_j;
run;

proc sort data=hha;
by bene_id clm_id CLM_FROM_DT;
run;

proc sql;
create table hha1 as select a.*, b.start, b.end from hha a
left join ccw.for_medpar b
on a.bene_id = b.bene_id;
quit;

/*should I get rid of zero costs?*/

data hha1;
	set hha1;
	if start ~=.;
	if clm_from_dt > start;
	if CLM_PMT_AMT ~= 0;
run;

proc sort data=hha1;
by bene_id CLM_FROM_DT;
run;

proc sql;
	create table hha2
	as select *
	from hha1 a
	left join hospice1 b
	on a.bene_id = b.bene_id;
quit;

data hha2;
	set hha2;
	rename start = start1;
	rename end = end1;
run;

data hha_cost;
	set hha2 (keep = bene_id clm_id CLM_FROM_DT CLM_PMT_AMT CLM_THRU_DT start1-start14 end1-end14) ;
run;

%macro inhospice;
options mlogic;
	%do i = 1 %to 14;
		data hha_cost;
			set hha_cost;
			if start&i = . then do;
			start&i = 99999;
			end;
			if end&i = . then do;
			end&i = 99999;
			end;
			/*comparing numerical vs. missing will output that the numerical is always better. thus reaction of these numbers for missing*/
		run;
		data hha_cost;
			set hha_cost;
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

proc freq data=hha_cost;
	table inhospice1 ;
run;

data hha_cost1;
	set hha_cost (keep = BENE_ID CLM_ID CLM_FROM_DT CLM_THRU_DT CLM_PMT_AMT inhospice1-inhospice14 posthospice1-posthospice14);
run;

proc freq data=hha_cost1;
	table posthospice13;
run;

proc sort data=hha_cost1;
	by bene_id clm_from_dt;
run;

%macro cost;
	%do i = 1 %to 14;
		data hha_cost1;
			set hha_cost1;
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

proc freq data=hha_cost1;
	table inhospice_cost8;
run;

data hha_cost2;
	set hha_cost1;
	by bene_id;
	if last.bene_id;
run;

data hha_cost3;
	set hha_cost2 (keep = BENE_ID CLM_ID inhospice_cost1-inhospice_cost8 posthospice_cost1-posthospice_cost7);
run;

data ccw.hha_cost;
	set hha_cost3;
run;

/*carrier cost*/

data carr;
	set merged.bcarrier_claims_j;
run;

proc sort data=carr;
by bene_id clm_id CLM_FROM_DT;
run;

proc sql;
create table carr1 as select a.*, b.start, b.end from carr a
left join ccw.for_medpar b
on a.bene_id = b.bene_id;
quit;

/*should I get rid of zero costs?*/

data carr1;
	set carr1;
	if start ~=.;
	if clm_from_dt > start;
	if CLM_PMT_AMT ~= 0;
run;

proc sort data=hha1;
by bene_id CLM_FROM_DT;
run;

proc sql;
	create table carr2
	as select *
	from carr1 a
	left join hospice1 b
	on a.bene_id = b.bene_id;
quit;

data carr2;
	set carr2;
	rename start = start1;
	rename end = end1;
run;

data carr_cost;
	set carr2 (keep = bene_id clm_id CLM_FROM_DT CLM_PMT_AMT CLM_THRU_DT start1-start14 end1-end14) ;
run;

%macro inhospice;
options mlogic;
	%do i = 1 %to 14;
		data carr_cost;
			set carr_cost;
			if start&i = . then do;
			start&i = 99999;
			end;
			if end&i = . then do;
			end&i = 99999;
			end;
			/*comparing numerical vs. missing will output that the numerical is always better. thus reaction of these numbers for missing*/
		run;
		data carr_cost;
			set carr_cost;
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

proc freq data=carr_cost;
	table inhospice1 ;
run;

data carr_cost1;
	set carr_cost (keep = BENE_ID CLM_ID CLM_FROM_DT CLM_THRU_DT CLM_PMT_AMT inhospice1-inhospice14 posthospice1-posthospice14);
run;
proc freq data=carr_cost1;
	table posthospice13;
run;
proc sort data=carr_cost1;
	by bene_id clm_from_dt;
run;

%macro cost;
	%do i = 1 %to 14;
		data carr_cost1;
			set carr_cost1;
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

proc freq data=carr_cost1;
	table posthospice_cost14;
run;

data carr_cost2;
	set carr_cost1;
	by bene_id;
	if last.bene_id;
run;

data carr_cost3;
	set carr_cost2 (keep = BENE_ID CLM_ID inhospice_cost1-inhospice_cost14 posthospice_cost1-posthospice_cost14);
run;

data ccw.carr_cost;
	set carr_cost3;
run;
