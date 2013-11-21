libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

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
	as select a.*, b.end
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
	if ADMSN_DT > end;
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

data icu;
	set medpar2;
	if ICU_IND_CD ~= . and ICU_IND_CD ~= 0;
run;
data inpat;
	set medpar2;
	if ICU_IND_CD = . or ICU_IND_CD = 0;
run;

proc freq data=inpat;
	table icu_ind_cd;
run;

proc sort data=icu;
	by bene_id ADMSN_DT DSCHRG_DT;
run;
proc sort data=inpat;
	by bene_id ADMSN_DT DSCHRG_DT;
run;
data icu1;
	set icu;
	retain i;
	by bene_id;
	if first.bene_id then i = 0;
	i = i + 1;
run;
data inpat1;
	set inpat;
	retain i;
	by bene_id;
	if SS_LS_SNF_IND_CD = 'N' then delete;
	if first.bene_id then i = 0;
	i = i + 1;
run;
data death;
	set inpat (keep = bene_id ADMSN_DT DSCHRG_DT BENE_DSCHRG_STUS_CD);
	if BENE_DSCHRG_STUS_CD = 'B';
	death = 1;
run;

proc freq data=test1;
	table i;
run;
proc freq data=inpat;
	table BENE_DSCHRG_STUS_CD;
run;

data inpat1a;
        set inpat1;
                by bene_id ADMSN_DT DSCHRG_DT;
                daydiff = ADMSN_DT - lag(DSCHRG_DT);
                if first.bene_id then daydiff = 999;
run;

/*merge costs, end dates for claims that are for cont. stays*/
data inpat1b;
        set inpat1a;
                retain totalcost start end;
                by bene_id ADMSN_DT;
                        if daydiff > 1 or daydiff = 999 then do;
                                start = ADMSN_DT;
                                end = DSCHRG_DT;
                                totalcost = MDCR_PMT_AMT;
                                end;
                        if daydiff <= 1 then do;
                                totalcost = MDCR_PMT_AMT + totalcost;
                                end = DSCHRG_DT;
                                end;
        format start date9. end date9.;
run;
data inpat1c;
	set inpat1b;
	retain i;
	by bene_id;
	if first.bene_id then i = 0;
	i = i + 1;
run;

proc freq data=inpat1c;
	table i;
run;

%macro icu;
        %do j = 1 %to 9;
                data icu1_&j;
                set icu1;
                        if i = &j;
                run;
                data icu2_&j;
                        set icu1_&j (keep = BENE_ID ADMSN_DT DSCHRG_DT);
                run;
                proc datasets nolist;
                        delete icu1_&j;
                run;
                data icu3_&j;
                        set icu2_&j;
                                icustart&j = ADMSN_DT;
                                icuend&j = DSCHRG_DT;
                                label icustart&j = "ICU Admission (Stay &j)";
                                label icuend&j = "ICU Discharge (Stay &j)";
                                format icuend&j date9. icustart&j date9.;
                run;
                proc datasets nolist;
                        delete icu2_&j;
                run;        
                data icu4_&j;
                        set icu3_&j (keep = BENE_ID icustart&j icuend&j);
                run;
                proc datasets nolist;
                        delete icu3_&j;
                run;
                                         
                %end;
			%end;
			data icu4;
				merge icu4_1-icu4_9;
				by bene_id;
			run;
			proc datasets;
				delete icu4_1-icu4_9;
			run;
%mend;
%icu;        
%macro inpat;
        %do j = 1 %to 37;
                data inpat1_&j;
                set inpat1;
                        if i = &j;
                run;
                data inpat2_&j;
                        set inpat1_&j (keep = BENE_ID ADMSN_DT DSCHRG_DT MDCR_PMT_AMT DGNS_1_CD DGNS_2_CD DGNS_3_CD DGNS_4_CD DGNS_5_CD DGNS_6_CD);
                run;
                proc datasets nolist;
                        delete inpat1_&j;
                run;
                data inpat3_&j;
                        set inpat2_&j;
                                inpatstart&j = ADMSN_DT;
                                inpatend&j = DSCHRG_DT;
								cost&j = MDCR_PMT_AMT;
								ICD9_1_&j = DGNS_1_CD;
								ICD9_2_&j = DGNS_2_CD;
								ICD9_3_&j = DGNS_3_CD;
								ICD9_4_&j = DGNS_4_CD;
								ICD9_5_&j = DGNS_5_CD;
								ICD9_6_&j = DGNS_6_CD;
                                label inpatstart&j = "ICU Admission (Stay &j)";
                                label inpatend&j = "ICU Discharge (Stay &j)";
								label cost&j = "Cost during Inpatient Stay (Stay &j)";
								label ICD9_1_&j = "ICD9 Primary Diagnosis (Stay &j)";
								label ICD9_2_&j = "ICD9 Diagnosis Code 2 (Stay &j)";
								label ICD9_3_&j = "ICD9 Diagnosis Code 3 (Stay &j)";
								label ICD9_4_&j = "ICD9 Diagnosis Code 4 (Stay &j)";
								label ICD9_5_&j = "ICD9 Diagnosis Code 5 (Stay &j)";
								label ICD9_6_&j = "ICD9 Diagnosis Code 6 (Stay &j)";
                                format inpatstart&j date9. inpatend&j date9.;
                run;
                proc datasets nolist;
                        delete inpat2_&j;
                run;        
                data inpat4_&j;
                        set inpat3_&j (keep = BENE_ID inpatstart&j inpatend&j cost&j ICD9_1_&j ICD9_2_&j ICD9_3_&j ICD9_4_&j ICD9_5_&j ICD9_6_&j);
                run;
                proc datasets nolist;
                        delete inpat3_&j;
                run;
                                         
                %end;
			%end;
			data inpat4;
				merge inpat4_1-inpat4_37;
				by bene_id;
			run;
			proc datasets nolist;
				delete inpat4_1-inpat4_37;
			run;
			quit;
%mend;
%inpat;        

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
