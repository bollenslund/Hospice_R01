libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

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

/*drop medpar claims for beneficiaries with no hospice stay 1 end date*/
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
/*    Identify ICU inpatient claims                                      */
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

/*create indicator for ICU use during stay*/
data medpar3;
	set medpar2;
	if ICU_IND_CD ~= . and ICU_IND_CD ~= 0 then ICU = 1;
	if ICU_IND_CD = . or ICU_IND_CD = 0 then ICU = 0;
	if SS_LS_SNF_IND_CD ~= 'N';
run;

/*~15% of claims have ICU use*/
proc freq;
table ICU /missprint;
run;

/*create dataset of SNF claims*/
data SNF;
	set medpar2;
	if SS_LS_SNF_IND_CD = 'N';
run;
/*no missing subjects (checked by proc freq)*/

/*************************************************************************/
/*    Process inpatient claims                                           */
/*************************************************************************/
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
                        set medpar4_&j (keep = BENE_ID ADMSN_DT DSCHRG_DT MDCR_PMT_AMT 
                        DGNS_1_CD DGNS_2_CD DGNS_3_CD DGNS_4_CD DGNS_5_CD DGNS_6_CD ICU 
                        death DSCHRG_DSTNTN_CD);
                run;
                proc datasets nolist;
                        delete medpar4_&j;
                run;
                data medpar4_3_&j;
                        set medpar4_2_&j;
                                inpatstart&j = ADMSN_DT;
                                inpatend&j = DSCHRG_DT;
								icu&j = ICU;
								cost&j = MDCR_PMT_AMT;
								ICD9_1_&j = DGNS_1_CD;
								ICD9_2_&j = DGNS_2_CD;
								ICD9_3_&j = DGNS_3_CD;
								ICD9_4_&j = DGNS_4_CD;
								ICD9_5_&j = DGNS_5_CD;
								ICD9_6_&j = DGNS_6_CD;
								death&j = death;
                                                                disch_dstn_cd_&j = DSCHRG_DSTNTN_CD;
                                label inpatstart&j = "Admission (Stay &j)";
                                label inpatend&j = "Discharge (Stay &j)";
								label icu&j = "ICU? (1 = yes)";
								label cost&j = "Cost during Inpatient Stay (Stay &j)";
								label ICD9_1_&j = "ICD9 Primary Diagnosis (Stay &j)";
								label ICD9_2_&j = "ICD9 Diagnosis Code 2 (Stay &j)";
								label ICD9_3_&j = "ICD9 Diagnosis Code 3 (Stay &j)";
								label ICD9_4_&j = "ICD9 Diagnosis Code 4 (Stay &j)";
								label ICD9_5_&j = "ICD9 Diagnosis Code 5 (Stay &j)";
								label ICD9_6_&j = "ICD9 Diagnosis Code 6 (Stay &j)";
								label death&j = "Death during stay?";
								label disch_dstn_cd_&j = "Discharge destn code (Stay &j)";
                                format inpatstart&j date9. inpatend&j date9.;
                run;
                proc datasets nolist;
                        delete medpar4_2_&j;
                run;        
                data medpar4_4_&j;
                        set medpar4_3_&j (keep = BENE_ID inpatstart&j inpatend&j icu&j cost&j ICD9_1_&j ICD9_2_&j 
                        ICD9_3_&j ICD9_4_&j ICD9_5_&j ICD9_6_&j death&j disch_dstn_cd_&j);
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
days_1_2=inpatstart2-inpatend1;
run;
proc freq;
table days_1_2;
run;
data test2;
set test1;
if days_1_2<1 and days_1_2~=.;
run;
proc freq;
table disch_dstn_cd_1;
run;

/*save dataset of ip claims to working folder*/
data ccw.ip_claims_clean;
	set medpar5;
run;

/*************************************************************************/
/*    Process skilled nursing facility (SNF) claims                      */
/*************************************************************************/
