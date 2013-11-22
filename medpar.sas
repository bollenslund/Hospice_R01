
data medpar;
	set merged.medpar_all_file;
run;

proc freq data=medpar;
	table ss_ls_SNF_IND_CD;
run;		

proc contents data=medpar;
run;

PROC sort data=medpar; by bene_id;
run;

proc sql;
	create table medpar1
	as select a.*, b.start, b.end
	from medpar a
	left join ccw.for_medpar b
	on a.bene_id = b.bene_id;
quit;

data medpar1;
	set medpar1;
	if end = . then delete;
run;

data medpar2;
	set medpar1;
	if ADMSN_DT > start;
run;

/*This field is derived by checking for the presence of icu 
3 = Pediatric (revenue center 0203) 
1 = Surgical (revenue center 0201) 
CODES: 
charge amount is used. 
claims, the code with the highest revenue center total 
revenue center codes listed below are included on these 
4 = Psychiatric (revenue center 0204) 
revenue center codes (listed below) on any of the claim 
2 = Medical (revenue center 0202) 
DERIVATION: 
STANDARD ALIAS: MEDPAR_ICU_IND_CD 
SAS ALIAS: ICUINDCD 
The code indicating that the beneficiary has spent time 
under intensive care during the stay. It also specifies 
thetype of ICU. 
COMMON ALIAS: INTENSIVE_CARE_INDICATOR 
DB2 ALIAS: MEDPAR_ICU_IND_CD 
records included in the stay. If more than one of the 
There is approximately a 20% error rate in the revenue 
as 'intermediate ICU'. 
10/1/96 (12/96 MEDPAR update). 0206 Is now defined 
revenue center code 0206 description, effective 
version of an ICU. 'Post' was removed from the 
stay rather than just days in a step-down/lower case 
0 = General (revenue center 0200) 
center code category 0206 due to coders misunderstanding 
6 = Intermediate ICU (revenue center 0206) 
LIMITATIONS: 
NCH 
SOURCE: 
BLANK = No intensive care indication 
9 = Other intensive care (revenue code 0209) 
8 = Trauma (revenue center 0208) 
7 = Burn care (revenue center 0207) 
prior to 12/96 update was 'post ICU' 
the term 'post ICU' as including any day after an ICU
*/

data medpar3;
	set medpar2;
	if ICU_IND_CD ~= . and ICU_IND_CD ~= 0 then ICU = 1;
	if ICU_IND_CD = . or ICU_IND_CD = 0 then ICU = 0;
	if SS_LS_SNF_IND_CD ~= 'N';
run;
data SNF;
	set medpar2;
	if SS_LS_SNF_IND_CD = 'N';
run;
/*no missing subjects (checked by proc freq)*/

proc sort data=medpar3;
	by bene_id ADMSN_DT DSCHRG_DT;
run;

data medpar4;
	set medpar3;
	retain i;
	by bene_id;
	if first.bene_id then i = 0;
	i = i + 1;
	death = 0;
	if BENE_DSCHRG_STUS_CD = 'B' then death = 1;
run;

proc freq data=medpar4;
	table i;
run;

%macro one;
        %do j = 1 %to 39;
                data medpar4_&j;
                set medpar4;
                        if i = &j;
                run;
                data medpar4_2_&j;
                        set medpar4_&j (keep = BENE_ID ADMSN_DT DSCHRG_DT MDCR_PMT_AMT DGNS_1_CD DGNS_2_CD DGNS_3_CD DGNS_4_CD DGNS_5_CD DGNS_6_CD ICU death);
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
                                format inpatstart&j date9. inpatend&j date9.;
                run;
                proc datasets nolist;
                        delete medpar4_2_&j;
                run;        
                data medpar4_4_&j;
                        set medpar4_3_&j (keep = BENE_ID inpatstart&j inpatend&j icu&j cost&j ICD9_1_&j ICD9_2_&j ICD9_3_&j ICD9_4_&j ICD9_5_&j ICD9_6_&j death&j);
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

proc sql;
	create table inpat5
	as select *
	from inpat4 a
	left join death b
	on a.bene_id = b.bene_id;
run;

data inpat5;
	set inpat5;
	drop BENE_DSCHRG_STUS_CD ADMSN_DT DSCHRG_DT;
	if death = . then death = 0;
run;
