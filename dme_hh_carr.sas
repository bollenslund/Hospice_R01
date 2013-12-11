libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

/************************************************************/
/************************DME costs***************************/
/************************************************************/

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
			retain dme_inhospice_cost&i dme_posthospice_cost&i;
			if first.bene_id then do;
			dme_inhospice_cost&i = 0;
			dme_posthospice_cost&i = 0;
			end;
			if inhospice&i = 1 then do;
			dme_inhospice_cost&i = dme_inhospice_cost&i + CLM_PMT_AMT;
			label dme_inhospice_cost&i = "Cost of DME during Hospice Visit &i";
			end;
			if posthospice&i = 1 then do;
			dme_posthospice_cost&i = dme_posthospice_cost&i + CLM_PMT_AMT;
			label dme_posthospice_cost&i = "Cost of DME after Hospice Visit &i";
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
	set dme_cost2 (keep = BENE_ID CLM_ID dme_inhospice_cost1-dme_inhospice_cost8 dme_posthospice_cost1-dme_posthospice_cost8);
run;

data ccw.dme_cost;
	set dme_cost3;
run;

/*************************************************************/
/*******************Home Health Costs*************************/
/*************************************************************/

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
			retain hha_inhospice_cost&i hha_posthospice_cost&i;
			if first.bene_id then do;
			hha_inhospice_cost&i = 0;
			hha_posthospice_cost&i = 0;
			end;
			if inhospice&i = 1 then do;
			hha_inhospice_cost&i = hha_inhospice_cost&i + CLM_PMT_AMT;
			label hha_inhospice_cost&i = "Cost of HHA during Hospice Visit &i";
			end;
			if posthospice&i = 1 then do;
			hha_posthospice_cost&i = hha_posthospice_cost&i + CLM_PMT_AMT;
			label hha_posthospice_cost&i = "Cost of HHA after Hospice Visit &i";
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
	set hha_cost2 (keep = BENE_ID CLM_ID hha_inhospice_cost1-hha_inhospice_cost8 hha_posthospice_cost1-hha_posthospice_cost8);
run;

data ccw.hha_cost;
	set hha_cost3;
run;

/****************************************************************/
/********************** Carrier Cost ****************************/
/****************************************************************/

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
			retain carr_inhospice_cost&i carr_posthospice_cost&i;
			if first.bene_id then do;
			carr_inhospice_cost&i = 0;
			carr_posthospice_cost&i = 0;
			end;
			if inhospice&i = 1 then do;
			carr_inhospice_cost&i = carr_inhospice_cost&i + CLM_PMT_AMT;
			label carr_inhospice_cost&i = "Cost of Carrier during Hospice Visit &i";
			end;
			if posthospice&i = 1 then do;
			carr_posthospice_cost&i = carr_posthospice_cost&i + CLM_PMT_AMT;
			label carr_posthospice_cost&i = "Cost of Carrier after Hospice Visit &i";
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
	set carr_cost2 (keep = BENE_ID CLM_ID carr_inhospice_cost1-carr_inhospice_cost14 carr_posthospice_cost1-carr_posthospice_cost14);
run;

data ccw.carr_cost;
	set carr_cost3;
run;


/********************************************************************/
/******************************** Analysis **************************/
/********************************************************************/

data DME_analysis;
	set ccw.dme_cost;
run;
data HHA_analysis;
	set ccw.hha_cost;
run;
data CARR_analysis;
	set ccw.carr_cost;
run;

data dme_analysis1;
set dme_analysis;
dme_cost=0;                        
label dme_cost="Total DME Cost";
run;
data hha_analysis1;
set hha_analysis;
hha_cost=0;
label hha_cost="Total HHA Cost";
run;
data carr_analysis1;
set carr_analysis;
carr_cost=0;
label carr_cost = "Total Carrier costs";
run;
%macro dmehhacarr;
data dme_analysis2;
set dme_analysis1;
retain dme_cost;
%do i = 1 %to 8;
dme_cost = dme_cost + dme_inhospice_cost&i;
dme_cost = dme_cost + dme_posthospice_cost&i;
%end;
run;
data hha_analysis2;
set hha_analysis1;
retain hha_cost;
%do i = 1 %to 8;
hha_cost = hha_cost + hha_inhospice_cost&i;
hha_cost = hha_cost + hha_posthospice_cost&i;
%end;
run;
data carr_analysis2;
set carr_analysis1;
retain carr_cost;
%do i = 1 %to 14;
carr_cost = carr_cost + carr_inhospice_cost&i;
carr_cost = carr_cost + carr_posthospice_cost&i;
%end;
run;

%mend;
%dmehhacarr;

proc sort data=dme_analysis2;
by bene_id;
run;
proc sort data=hha_analysis2;
by bene_id;
run;
proc sort data=carr_analysis2;
by bene_id;
run;

data sample;
	set ccw.for_medpar (keep = bene_id);
run;

data dmee;
	merge sample dme_analysis2;
	by bene_id;
run;
data dmehha;
	merge dmee hha_analysis2;
	by bene_id;
run;
data dmehhacarr;
	merge dmehha carr_analysis2;
	by bene_id;
run;


proc means data=dmehhacarr n mean median;
where dme_cost ~=.;
var dme_cost;
run;
proc means data=dmehhacarr n mean median;
where hha_cost ~=.;
var hha_cost;
run;
proc means data=dmehhacarr n mean median;
where carr_cost ~=.;
var carr_cost;
run;
