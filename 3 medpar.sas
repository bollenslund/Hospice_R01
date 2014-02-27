/*
This file processes the inpatient and SNF claims from the medpar claims dataset
For inpatient claims, get:
    Start, end dates
    ICU and or ED use indicator
        ICU use comes from indicator in medpar dataset, ED use comes from
        whether or not there are ED charges associated with that claim
        (if charges>0, then ED=1)
    Costs/claim
    Hospital death
    Diagnosis codes (primary + next 5)
For SNF claims, get
    Start,end dates
    Costs/claim
*/

libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';
libname costs 'N:\Documents\Downloads\Melissa\Hospice_Cost_Data\data';

/*************************************************************************/
/*  Get list of IP and SNF claims for beneficiaries in clean MBS dataset */
/*************************************************************************/

data medpar;
	set merged.medpar_all_file;
run;

proc freq data=medpar;
	table ss_ls_SNF_IND_CD /missprint;
run;		

proc contents data=medpar;
run;

PROC sort data=medpar; by bene_id;
run;

/*bring hospice first stay start and end dates to medpar claims dataset*/
proc sql;
	create table medpar1
	as select a.*, b.start, b.end
	from medpar a
	left join ccw.for_medpar b
	on a.bene_id = b.bene_id;
quit;

/*drop medpar claims for beneficiaries with no hospice stay 1 end date
Note: this also limits to the sample defined in the MBS file processing
to those 65 and older with parts a + b coverage and no hmo coverage*/
data medpar1;
	set medpar1;
	if end = . then delete;
run;

/*dataset with just claims where admission date is after hs stay 1 start
33828 claims*/
data medpar2;
	set medpar1;
	if ADMSN_DT > start;
run;

/*************************************************************************/
/*    Identify ICU and ED use in inpatient claims                        */
/*************************************************************************/

/*Uses medpar variable ICUINDCD :
This field is derived by checking for the presence of icu 
revenue center codes (listed below) on any of the claim
records included in the stay. If more than one of the
revenue center codes listed below are included on these
claims, the code with the highest revenue center total 
charge amount is used.

LIMITATIONS: 
There is approximately a 20% error rate in the revenue
There is approximately a 20% error rate in the revenue 
center code category 0206 due to coders misunderstanding 
the term 'post ICU' as including any day after an ICU 
stay rather than just days in a step-down/lower case 
version of an ICU. 'Post' was removed from the revenue 
center code 0206 description, effective 10/1/96 
(12/96 MEDPAR update). 0206 Is now defined as 
'intermediate ICU'.

CODES:
0 = General (revenue center 0200)
1 = Surgical (revenue center 0201)
2 = Medical (revenue center 0202)
3 = Pediatric (revenue center 0203)
4 = Psychiatric (revenue center 0204)
6 = Intermediate ICU (revenue center 0206) 
7 = Burn care (revenue center 0207)   
8 = Trauma (revenue center 0208)
9 = Other intensive care (revenue code 0209) 
Blank = No ICU use indicated for stay
*/

proc freq data=medpar2;
table ICU_IND_CD /missprint;
run;

/*create indicator for ICU and/or ED use during stay
ICUED=0 - no icu or ed use
=1 ED only
=2 ICU only
=3 ICU and ED*/
data medpar3;
	set medpar2;
	if ICU_IND_CD ~= . or INTNSV_CARE_DAY_CNT>0 then ICU = 1;
	if ICU_IND_CD = . and INTNSV_CARE_DAY_CNT=0 then ICU = 0;
	if SS_LS_SNF_IND_CD ~= 'N';
	ED = 0;
	if ER_CHRG_AMT > 0 then ED = 1;
	if ICU = 1 and ED = 1 then ICUED = 3;
	if ICU = 1 and ED = 0 then ICUED = 2;
	if ICU = 0 and ED = 1 then ICUED = 1;
	if ICU = 0 and ED = 0 then ICUED = 0;
	drop icu ed;
run;

proc freq data=medpar3;
table INTNSV_CARE_DAY_CNT* ICU_IND_CD /missprint;
run;

proc freq;
table ICUED /missprint;
run;

proc freq;
table ICUED*SRC_IP_ADMSN_CD;
run;

/*check of icu los - it is not the same as the overall los
many observations have days within ip stay that are not icu days*/
data icu_check_1;
set medpar3;
if ICUED=2 or ICUED=3;
run;

data icu_check_2;
set icu_check_1;
mp_los_calc=DSCHRG_DT-ADMSN_DT;
mp_los_dif=LOS_DAY_CNT-mp_los_calc;
mp_ip_los_dif=INTNSV_CARE_DAY_CNT-mp_los_calc;
run;

proc freq;
table mp_los_calc LOS_DAY_CNT mp_los_dif mp_ip_los_dif;
run;

proc freq;
table INTNSV_CARE_DAY_CNT* ICUED /missprint;
run;


/*create dataset of SNF claims*/
data SNF;
	set medpar2;
	if SS_LS_SNF_IND_CD = 'N';
run;
/*no missing subjects (checked by proc freq)*/

/*er charges are present in the claim - this is the definition used to create
the icu ed indicator above*/
data ed;
	set medpar2;
	if ER_CHRG_AMT > 0;
run;

/*claim source of inpatient admissioin = 7 = emergency room*/
data src;
	set medpar2;
	if SRC_IP_ADMSN_CD = '7';
run;


/*************************************************************************/
/*    Process inpatient claims                                           */
/*************************************************************************/
/*start with ip claims dataset with icued indicator added*/
proc sort data=medpar3;
	by bene_id ADMSN_DT DSCHRG_DT;
run;

/*Get count of claims for each BID (39 max) and create death during
claim variable from discharge status code variable*/
data medpar4;
	set medpar3;
	retain i;
	by bene_id;
	if first.bene_id then i = 0;
	i = i + 1;
	death = 0;
	if BENE_DSCHRG_STUS_CD = 'B' then death = 1;
run;

/*crosstab to check death indicator with discharge destination codes
dstn codes 20, 40, 41, 42 should all be listed as death=1*/
proc freq data=medpar4;
     table death*DSCHRG_DSTNTN_CD;
run;

proc freq data=medpar4;
	table i;
run;

/*keep only relevant fields for each inpatient claim, create dataset 1 row per bene_id
resulting dataset is work.medpar5*/
%macro one;
        %do j = 1 %to 39;
                data medpar4_&j;
                set medpar4;
                        if i = &j;
                run;
                data medpar4_2_&j;
                        set medpar4_&j (keep = BENE_ID ADMSN_DT DSCHRG_DT MDCR_PMT_AMT DGNS_1_CD DGNS_2_CD DGNS_3_CD DGNS_4_CD DGNS_5_CD DGNS_6_CD ICUED INTNSV_CARE_DAY_CNT death);
                run;
                proc datasets nolist;
                        delete medpar4_&j;
                run;
                data medpar4_3_&j;
                        set medpar4_2_&j;
                                IP_start&j = ADMSN_DT;
                                IP_end&j = DSCHRG_DT;
								IP_icued&j = ICUED;
								IP_icu_day_cnt&j = INTNSV_CARE_DAY_CNT;
								IP_cost&j = MDCR_PMT_AMT;
								IP_ICD9_1_&j = DGNS_1_CD;
								IP_ICD9_2_&j = DGNS_2_CD;
								IP_ICD9_3_&j = DGNS_3_CD;
								IP_ICD9_4_&j = DGNS_4_CD;
								IP_ICD9_5_&j = DGNS_5_CD;
								IP_ICD9_6_&j = DGNS_6_CD;
								IP_death&j = death;
                                label IP_start&j = "Admission (Stay &j)";
                                label IP_end&j = "Discharge (Stay &j)";
								label IP_icued&j = "ICU/ED/Both? (0 = Neither, 1 = ED only, 2 = ICU only, 3 = Both)";
								label IP_icu_day_cnt&j = "ICU day count (Stay &j)";
                                label IP_cost&j = "Cost during Inpatient Stay (Stay &j)";
								label IP_ICD9_1_&j = "ICD9 Primary Diagnosis (Stay &j)";
								label IP_ICD9_2_&j = "ICD9 Diagnosis Code 2 (Stay &j)";
								label IP_ICD9_3_&j = "ICD9 Diagnosis Code 3 (Stay &j)";
								label IP_ICD9_4_&j = "ICD9 Diagnosis Code 4 (Stay &j)";
								label IP_ICD9_5_&j = "ICD9 Diagnosis Code 5 (Stay &j)";
								label IP_ICD9_6_&j = "ICD9 Diagnosis Code 6 (Stay &j)";
								label IP_death&j = "Death during stay?";
                                format IP_start&j date9. IP_end&j date9.;
                run;
                proc datasets nolist;
                        delete medpar4_2_&j;
                run;
                data medpar4_4_&j;
                        set medpar4_3_&j (keep = BENE_ID IP_start&j IP_end&j IP_icued&j IP_icu_day_cnt&j IP_cost&j IP_ICD9_1_&j IP_ICD9_2_&j IP_ICD9_3_&j IP_ICD9_4_&j IP_ICD9_5_&j IP_ICD9_6_&j IP_death&j);
                run;
                proc datasets nolist;
                        delete medpar4_3_&j;
                run;

                %end;
			%end;
			data medpar5;
				merge medpar4_4_1-medpar4_4_39;
				by bene_id;
			run;
			proc datasets nolist;
				delete medpar4_4_1-medpar4_4_39;
			run;
			quit;
%mend;
%one;        
  

/*check that stay 2 admit day is later than stay 1 end date
For 487 beneficiaries, this is not the case
deal with this later when looking at full patient timelines*/
data test1;
set medpar5;
days_1_2=IP_start2-IP_end1;
run;
proc freq;
table days_1_2;
run;



/*save dataset of ip claims to working folder*/
data ccw.ip_claims_clean;
	set medpar5;
run;

/*************************************************************************/
/*Get count of hospital admissions 12 months prior to first hospice enrollment*/
/*************************************************************************/

/*Get list of IP claims in the 12 months pre-enrollment*/

data admit_pre1;
	set medpar1;
	if ( start-365 <= ADMSN_DT < start);
run;

proc freq; table SS_LS_SNF_IND_CD;
run;

data admit_pre2;
	set admit_pre1;
	if SS_LS_SNF_IND_CD ~= 'N';
run;

proc sort data=admit_pre2;
by bene_id ADMSN_DT;
run;

/*add count variable by beneficiary*/
data admit_pre3;
	set admit_pre2;
	by bene_id;
	retain k;
	k = k + 1;
	if first.bene_id then k = 1;
run;

data admit_pre4;
set admit_pre3;
	by bene_id;
	if last.bene_id;
rename k=admit_pre12m;
label admit_pre12m="Count hospital admissions 12m pre enrollment";
run;

proc freq data=admit_pre4;
table admit_pre12m;
run;

/*************************************************************************/
/*    Process skilled nursing facility (SNF) claims                      */
/*************************************************************************/

/*Create table with just claims that don't have a discharge date, that is
claims that don't cover full stay b/c patient is still a patient at the end
of the claim
Some of these patients have a missing cvrd_lvl_care_thru_dt so this step
is just a check
Result is that we use LOS count from CMS to determine actual stay end date
since LOS count from CMS agrees with CVRD_LVL_CARE_THRU_DT in the cases where
it is available*/
data test;
set snf;
if CVRD_LVL_CARE_THRU_DT ~= .;
los = CVRD_LVL_CARE_THRU_DT - ADMSN_DT + 1; /*LOS calculated from claim thru date*/
los_dis = DSCHRG_DT - ADMSN_DT; /*LOS calculated from admission/disch dates*/
vardiff = LOS_DAY_CNT - los; /*LOS_DAY_CNT calculated by CMS*/
vardiff1 = LOS_DAY_CNT - los_dis; /*this is . for cases where disch date is missing*/
if vardiff1 = .;   /*vardiff1=0 for stays where disch destn code not equal to 30*/
run;


proc freq data = test;
table vardiff;
run;
/*In checking the date of SNF coverage variable lining up with the los day count
the differences of days using those two variables were all positive (meaning the day stayed
in SNF is always greater than what is covered). LOS day count will be added to the admission
date if the discharge date is missing (there were a total of 26% without discharge dates)*/

data snf1;
	set snf (keep = bene_id MEDPAR_ID BENE_DSCHRG_STUS_CD ADMSN_DT MDCR_PMT_AMT
            DSCHRG_DT DSCHRG_DSTNTN_CD DGNS_1_CD DGNS_2_CD DGNS_3_CD DGNS_4_CD DGNS_5_CD 
            DGNS_6_CD LOS_DAY_CNT);
	death = 0;
	if BENE_DSCHRG_STUS_CD = 'B' then death = 1;
	*drop BENE_DSCHRG_STUS_CD;
	/*replace discharge date with calculated date from los if still patient status code*/
	if (DSCHRG_DT = . and BENE_DSCHRG_STUS_CD='C') then DSCHRG_DT = ADMSN_DT + LOS_DAY_CNT;
run;

/*All obs with missing disch date were still patient*/
proc freq;
table DSCHRG_DT /missprint;
run;

proc sort data = snf1 out=snf1a;
by bene_id ADMSN_DT DSCHRG_DT;
run;

/* This is not used because we aren't worried about claims that overlap 
over multiple stays yet...
data snf1b;
set snf1a;
drop BENE_DSCHRG_STUS_CD;
by bene_id;
if ADMSN_DT <= (lag(DSCHRG_DT)+1) and DSCHRG_DSTNTN_CD='30' then indic = 1;
if first.bene_id then indic = 0;
run;
*/
data snf1b;
set snf1a;
drop BENE_DSCHRG_STUS_CD;
by bene_id;
if ADMSN_DT < lag(DSCHRG_DT) then indic = 1;
if first.bene_id then indic = 0;
run;

proc freq;
table indic;
run;
/*one observation where indic = 1*/

/*This bid has two claims with the same start date, different discharge dates
this is the person with indic=1 above
The two claims have the same dx codes but the first claim with the earlier disch date
has destination code = still patient so drop that claim
However, need to merge costs to get total snf stay cost*/
data zztest4;
set snf1b;
if bene_id = 'ZZZZZZZIIk93OO3';
run;

proc sort data=zztest4;
by bene_id admsn_dt dschrg_dt;
run;

data zztest5;
set zztest4;
lag_pmt=lag(MDCR_PMT_AMT);
if DSCHRG_DSTNTN_CD =05 then total_calc_pmt=MDCR_PMT_AMT+lag_pmt;
run;

data zztest6;
set zztest5;
if DSCHRG_DSTNTN_CD = '30' then delete;
MDCR_PMT_AMT=total_calc_pmt;
drop lag_pmt total_calc_pmt;
run;

/*merge the total cost into the claims dataset for the one claim that was merged*/

/*drop the two claims for the bid from the dataset and then merge the single claim 
with total cost back in*/
data snf1c;
set snf1b;
if bene_id = 'ZZZZZZZIIk93OO3' and ADMSN_DT='19JUN2009'd then delete ;
run;

data snf1d;
set snf1c zztest6;
run;
/*delete one of the claims from the "indic = 1" beneficiary.
Took the one with the longest length of stay.
Add costs first so have total stay cost for this stay*/

proc sort data=snf1d;
by bene_id admsn_dt;
run;

data snf2;
	set snf1d;
	by bene_id;
	retain i;
	i = i + 1;
	if first.bene_id then i = 1;
run;

proc freq data=snf2;
	table i;
run;
/*maximum of 12 claims to the SNF*/

proc transpose data=snf2 prefix=snf_start out=start_dates_snf;
by bene_id;
var admsn_dt;
run;
proc transpose data=snf2 prefix=snf_end out = end_dates_snf;
by bene_id;
var dschrg_dt;
run;
proc transpose data=snf2 prefix=snf_prim_icd out = prim_icd_snf;
by bene_id;
var dgns_1_cd;
run;
proc transpose data = snf2 prefix = snf_icd2_ out = sec_icd_snf;
by bene_id;
var dgns_2_cd;
run;
proc transpose data=snf2 prefix = snf_icd3_ out = third_icd_snf;
by bene_id;
var dgns_3_cd;
run;
proc transpose data=snf2 prefix = snf_icd4_ out = four_icd_snf;
by bene_id;
var dgns_4_cd;
run;
proc transpose data=snf2 prefix = snf_icd5_ out = five_icd_snf;
by bene_id;
var dgns_5_cd;
run;
proc transpose data=snf2 prefix = snf_icd6_ out = six_icd_snf;
by bene_id;
var dgns_6_cd;
run;
proc transpose data=snf2 prefix = snf_death out = death_snf;
by bene_id;
var death;
run;
proc transpose data=snf2 prefix = snf_dis_dstn out = dis_dstn_snf;
by bene_id;
var DSCHRG_DSTNTN_CD;
run;
proc transpose data=snf2 prefix = snf_cost out = cost_snf;
by bene_id;
var MDCR_PMT_AMT;
run;



data snf3;
	merge start_dates_snf end_dates_snf prim_icd_snf sec_icd_snf third_icd_snf four_icd_snf 
        five_icd_snf six_icd_snf cost_snf death_snf dis_dstn_snf;
	by bene_id;
	drop _NAME_ _LABEL_;
run;

%macro resort;
	%do i = 1 %to 12;
		data resort&i;
			set snf3 (keep = bene_id snf_start&i snf_end&i snf_prim_icd&i snf_icd2_&i snf_icd3_&i snf_icd4_&i snf_icd5_&i snf_icd6_&i snf_cost&i snf_death&i snf_dis_dstn&i);
			label snf_start&i = "Admission (Stay &i)";
			label snf_end&i = "Discharge (Stay &i)";
			label snf_prim_icd&i = "Primary ICD (Stay &i)";
			label snf_icd2_&i = "ICD9 Diagnosis Code II (Stay &i)";
			label snf_icd3_&i = "ICD9 Diagnosis Code III (Stay &i)";
			label snf_icd4_&i = "ICD9 Diagnosis Code IV (Stay &i)";
			label snf_icd5_&i = "ICD9 Diagnosis Code V (Stay &i)";
			label snf_icd6_&i = "ICD9 Diagnosis Code VI (Stay &i)";
			label snf_cost&i = "Total Cost during Stay (Stay &i)";
			label snf_death&i = "Death during Visit (Stay &i)";
			label snf_dis_dstn&i = "Discharge destination code (Stay &i)";
		run;
	%end;
	data snf4;
		merge resort1-resort12;
		by bene_id;
	run;
	proc datasets nolist;
		delete resort1-resort12;
	run;
	quit;
%mend;
%resort;

data ccw.snf;
	set snf4;
run;


/*************************************************************************/
/*create additional variables for use in data analysis*/
/*************************************************************************/

/*merge ip claims dataset with medpar dataset to get full list of hs sample*/
proc sql;
create table ip_sample as select * from
ccw.for_medpar a
left join ccw.ip_claims_clean b
on a.bene_id=b.bene_id;
quit;

/*merge in 12 month pre-enrollment admissions count into hospice/ip dataset*/
proc sql;
create table ip_sample_a as select
a.*,coalesce(b.admit_pre12m, 0) as admit_pre12m from
ip_sample a
left join
admit_pre4 b
on a.bene_id=b.bene_id;
quit;

proc freq ;
table admit_pre12m;
run;


/*create / initialize variables*/
data ip_sample_1;
set ip_sample_a;
/*hospital ip admission variables*/
hosp_adm_ind=0;                          /*hosp admission indicator*/
if IP_start1~=. then hosp_adm_ind=1;
hosp_adm_days=0;                         /*hospital admission count days*/
hosp_adm_cnt=0;
/*ed visit variables*/
ip_ed_visit_ind=0;                      /*ed visit indicator*/
ip_ed_visit_cnt=0;                      /*number of ed visits*/
/*icu stay variables*/
icu_stay_ind=0;                         /*icu stay indicator*/
icu_stay_days=0;                        /*icu count days*/
icu_stay_cnt=0;                         /*icu stay count*/
/*hospital death variable*/
hosp_death=0;
/*cost variable*/
ip_tot_cost=0;
label hosp_adm_ind="Hospital admission indicator";
label hosp_adm_days="Hospital stays total day count";
label hosp_adm_cnt="Count of hospital admissions";
label ip_ed_visit_ind="ED Visit indicator (from IP claims)";
label ip_ed_visit_cnt="ED Visit count (from IP claims)";
label icu_stay_ind="ICU Stay indicator";
label icu_stay_days="ICU stays total day count";
label icu_stay_cnt="Count of ICU stays";
label hosp_death="Hospital death (from IP claims)";
label ip_tot_cost="Total cost all IP claims";
drop lengthmedi lengthmo allmedistatus1 allhmostatus1 allmedistatus2 allhmostatus2 allmedistatus3 allhmostatus3;
run;

/*macro to run through all ip stays to get count variables*/
%macro ip_vars;
data ip_sample_2;
set ip_sample_1;                          /*hospital admissions count*/
if hosp_adm_ind=1 then do;
   hosp_adm_days=IP_end1-IP_start1 + 1; /*initialize for 1st stay*/
   hosp_adm_cnt=1;
   if IP_icued1=1 or IP_icued1=3 then ip_ed_visit_cnt=1;
   if IP_icued1=2 or IP_icued1=3 then do;
      icu_stay_cnt=1;
      icu_stay_days = IP_icu_day_cnt1;
      end;
   if IP_death1=1 then hosp_death=1;
   ip_tot_cost=IP_cost1;
   %do i=2 %to 39;
         if IP_start&i~=. then hosp_adm_days=hosp_adm_days + (IP_end&i-IP_start&i) + 1;
         if IP_start&i~=. then hosp_adm_cnt=hosp_adm_cnt+1;
         if (IP_icued&i=1 or IP_icued&i=3) then ip_ed_visit_cnt=ip_ed_visit_cnt+1;
         if (IP_icued&i=2 or IP_icued&i=3) then icu_stay_days = icu_stay_days + IP_icu_day_cnt&i;
         if (IP_icued&i=2 or IP_icued&i=3) then icu_stay_cnt+1;
         if IP_death&i=1 then hosp_death=1;
         if IP_cost&i~=. then ip_tot_cost=ip_tot_cost + IP_cost&i;
         %end;
   end;
run;

data ip_sample_3;
set ip_sample_2;
if ip_ed_visit_cnt>0 then ip_ed_visit_ind=1;
if icu_stay_cnt>0 then icu_stay_ind=1;
run;

%mend;

%ip_vars;

data test;
	set ip_sample_3;
	if IP_start39 ~= .;
run;

proc freq data=ip_sample_3;
table hosp_adm_ind*hosp_adm_days
ip_ed_visit_ind*ip_ed_visit_cnt
icu_stay_ind*icu_stay_cnt
hosp_adm_ind*hosp_death
admit_pre12m;
run;

/*save dataset*/
data ccw.ip_sample;
set ip_sample_3;
run;

/*****************************************************************/
/*Output to stata for sum stats*/
/*****************************************************************/
proc export data=ccw.ip_sample
	outfile='J:\Geriatrics\Geri\Hospice Project\Hospice\working\ip_sample.dta'
	replace;
	run;

/*****************************************************************/
/***** Working with merging the SNF data with the sample data*****/
/*****************************************************************/

proc sql;
create table ip_snf as select * from
ccw.ip_sample a
left join ccw.snf b
on a.bene_id=b.bene_id;
quit;

/*initialize variables*/
data ip_snf1;
set ip_snf;
/*snf ip admission variables*/
snf_adm_ind=0;                          /*skilled nursing facility admission indicator*/
if snf_start1~=. then snf_adm_ind=1;
snf_adm_days=0;                        
snf_adm_cnt=0;
/*snf death variable*/
snf_death=0;
/*cost variable*/
snf_cost=0;
label snf_adm_ind="SNF admission indicator";
label snf_adm_days="SNF total day count";
label snf_adm_cnt="Count of SNF admissions";
label snf_death="Death from SNF visit";
label snf_cost="Total cost all SNF claims";
run;

/*macro to run through all snf stays to get count variables*/
%macro snf_vars;
data ip_snf2;
set ip_snf1;
retain snf_adm_days snf_adm_cnt snf_cost; 
if snf_adm_ind=1 then do;
   snf_adm_days=snf_end1-snf_start1 + 1; /*initialize for 1st stay*/
   snf_adm_cnt=1;
   if snf_death1=1 then snf_death=1;
   snf_cost=snf_cost1;
   %do i=2 %to 12;
         if snf_start&i~=. then snf_adm_days=snf_adm_days + (snf_end&i-snf_start&i) + 1;
         if snf_start&i~=. then snf_adm_cnt=snf_adm_cnt+1;
         if snf_death&i=1 then snf_death=1;
         if snf_cost&i~=. then snf_cost=snf_cost + snf_cost&i;
         %end;
   end;
run;
%mend;
%snf_vars;

proc means data=ip_snf2 sum mean median;
var snf_adm_ind snf_adm_days snf_adm_cnt snf_death snf_cost;
run;
proc  means data=ip_snf2 sum mean median;
where snf_adm_ind = 1;
var snf_adm_days snf_adm_cnt snf_death snf_cost;
run;

data ccw.ip_snf;
	set ip_snf2;
drop BENE_ENROLLMT_REF_YR FIVE_PERCENT_FLAG ENHANCED_FIVE_PERCENT_FLAG COVSTART CRNT_BIC_CD 
STATE_CODE BENE_COUNTY_CD BENE_ZIP_CD BENE_AGE_AT_END_REF_YR BENE_BIRTH_DT BENE_DEATH_DT 
NDI_DEATH_DT BENE_SEX_IDENT_CD BENE_RACE_CD BENE_VALID_DEATH_DT_SW start end;
label admit_pre12m = "Number of IP before hospice stay";
run;
ods rtf body = '\\home\users$\leee20\Documents\Downloads\Melissa\ipsnf.rtf';
proc contents data=ccw.ip_snf varnum;
run;
ods rtf close;

data hs_mb;
set ccw.final_hs_mb;
run;

/*this final sample is created using the mbs files in the code MB12mosforward.sas*/
data final_sample;
set ccw.ip_snf;
run;

/*only keep beneficiary ids that are in the final sample list created from mbs criteria*/
proc sql;
create table hs_mb_ip_snf as select * from hs_mb a
left join final_sample b
on a.bene_id = b.bene_id;
quit;

/*save hospice dataset restricted to just the sample*/
data ccw.final_hs_mb_ip_snf;
set hs_mb_ip_snf;
run;
