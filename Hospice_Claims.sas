/* Prepares hospice claims for analysis
1. Drops beneficiaries with first claim before Sept 2008
2. Totals revenue code days by revenue code type for each beneficiary
3. Collapses claims data into data for individual hospice stays
4. Restructures dataset so one row per beneficiary with details
about all their hospice stays as separate variables

Final dataset saved as wk_fldr.hs_stays_cleaned */

/*********************************************************************/
/*********************************************************************/
/* Part 1 - Start with merged hospice claims base file 2007-10  */
/*********************************************************************/
/*********************************************************************/

libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\raw_sas';
libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname wk_fldr 'J:\Geriatrics\Geri\Hospice Project\Hospice\working'; 

data work.hospice_base;
        set merged.hospice_base_claims_j;
run;        


/*********************************************************************/
/*********************************************************************/
/* Part 2 - Drop beneficiaries with first claim before Sept 2008     */
/*********************************************************************/
/*********************************************************************/

proc sort data=hospice_base out=hospice_base1;
        by bene_id CLM_FROM_DT;
run;

data hospice_base2; set hospice_base1;
        by bene_id;
        if first.bene_id then indic2=1;
        else indic2 + 1;
run; 


/*identifies beneficiaries with first claim prior to Sept 2008
these beneficiaries should be excluded from the sample*/
data indicator;
        set hospice_base2;
                if indic2 = 1 and clm_from_dt < '01SEP2008'd;
                indic = 1;
run;
data indicator1;
        set indicator (keep = bene_id indic);
run;

/*assigns the date indicator for exclusion to all claims for the bid*/
proc sql;
        create table hospice_base3
          as select *
            from hospice_base2 a
                  left join indicator1 b
                          on a.bene_id = b.bene_id;
quit;
proc freq data=hospice_base3;
        table indic2;
run;
proc freq data=hospice_base3;
        where indic2 = 1;
                table indic;
run;

/*drops beneficiaries with first claim before Sept 2013*/
data hospice_base4;
        set hospice_base3;
                if indic = 1 then delete;
run;                        
proc freq data=hospice_base4;
        table indic2;
RUN;
/*view frequencies of first claim start date by bid*/
proc freq data=hospice_base4;
        where indic2 = 1;
                table clm_from_dt;
run;

proc sort data=hospice_base4;
        by bene_id clm_from_dt;
run;

/*********************************************************************/
/*********************************************************************/
/* Part 3 - Get revenue code day totals by type by bene id           */
/*********************************************************************/
/*********************************************************************/

data hospice_revenue;
        set merged.hospice_revenue_center_j;
run;


/*numerical conversion*/
data hospice_revenue1;
        set hospice_revenue;
        rev_code = REV_CNTR + 0;
run;

/*drop revenue codes that aren't relevant (not hospice level of care)*/
data hospice_revenue2;
        set hospice_revenue1;
                if rev_code > 649 and rev_code < 660;
run;

proc sort data=hospice_revenue2 out=hospice_revenue3;
        by bene_id CLM_ID CLM_THRU_DT;
run;

/*Creates total days for each revenue code by claim id*/
data hospice_revenue4;
        set hospice_revenue3;
                retain tot_650 tot_651 tot_652 tot_655 tot_656 tot_657;
                        by bene_id CLM_id CLM_THRU_DT;
                                if first.CLM_ID then do;
                                        tot_650 = 0;
                                        tot_651 = 0;
                                        tot_652 = 0;
                                        tot_655 = 0;
                                        tot_656 = 0;
                                        tot_657 = 0;
                                        if rev_code = 650 then tot_650 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 651 then tot_651 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 652 then tot_652 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 655 then tot_655 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 656 then tot_656 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 657 then tot_657 = REV_CNTR_UNIT_CNT;
                                        end;
                                else do;
                                        if rev_code = 650 then tot_650 = tot_650 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 651 then tot_651 = tot_651 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 652 then tot_652 = tot_652 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 655 then tot_655 = tot_655 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 656 then tot_656 = tot_656 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 657 then tot_657 = tot_657 + REV_CNTR_UNIT_CNT;
                                        end;
                /*converts hours to days for rev code 652*/
                tot_652_days = floor(tot_652/24);
                drop tot_652;
run;
/*keeps just one entry per claim id with the total days 
for each rev code*/
data hospice_revenue5;
        set hospice_revenue4;
                by bene_id CLM_id CLM_THRU_DT;
                tot_652 = tot_652_days;
                if last.clm_id then output;
run;

/*Creates total days for each revenue code by beneficiary (across
all claims in the revenue code files*/
data hospice_revenue6;
        set hospice_revenue5;
                retain total_650 total_651 total_652 total_655 total_656 total_657;
                        by bene_id;
                                if first.bene_id then do;
                                        total_650 = 0;
                                        total_651 = 0;
                                        total_652 = 0;
                                        total_655 = 0;
                                        total_656 = 0;
                                        total_657 = 0;
                                        total_650 = tot_650;
                                        total_651 = tot_651;
                                        total_652 = tot_652;
                                        total_655 = tot_655;
                                        total_656 = tot_656;
                                        total_657 = tot_657;
                                        end;
                                else do;
                                        total_650 = total_650 + tot_650;
                                        total_651 = total_651 + tot_651;
                                        total_652 = total_652 + tot_652;
                                        total_655 = total_655 + tot_655;
                                        total_656 = total_656 + tot_656;
                                        total_657 = total_657 + tot_657;
                                        end;
run;

/*keeps just the final observation with the totals*/
data hospice_revenue7;
        set hospice_revenue6;
                by bene_id CLM_id CLM_THRU_DT;
                if last.bene_id then output;
run;

/*creates dataset with just the beneficiary ID and revenue code day totals*/
data total_rev_center;
        set hospice_revenue7 (keep = bene_id total_650 total_651 total_652 total_655 total_656 total_657);
run;


/*********************************************************************/
/*********************************************************************/
/* Part 4 - Check claims for multiple claims spanning continuous
hospice stays, merge total costs and start/end dates to get a list 
of unique hospice stays       */
/*********************************************************************/
/*********************************************************************/

proc sort data=hospice_base4 out=hospice_base5;
        by bene_id clm_from_dt clm_thru_dt;
run;


/*create daydiff variable = start date of current claim to end date of
previous claim - if 0 or 1, then continous stay*/
data hospice_base6;
        set hospice_base5;
                by bene_id clm_from_dt clm_thru_dt;
                daydiff = CLM_FROM_DT - LAG(CLM_THRU_DT);
                if first.bene_id then daydiff = 999;
run;

/*merge costs, end dates for claims that are for cont. stays*/
data hospice_base7;
        set hospice_base6;
                retain totalcost start end;
                by bene_id clm_from_dt;
                        if daydiff > 1 or daydiff = 999 then do;
                                start = clm_from_dt;
                                end = clm_thru_dt;
                                totalcost = CLM_PMT_AMT;
                                end;
                        if daydiff <= 1 then do;
                                totalcost = CLM_PMT_AMT + totalcost;
                                end = clm_thru_dt;
                                end;
        format start date9. end date9.;
run;

/*assign indicator for final claim for the stay*/
data hospice_base9;
        set hospice_base7;
                retain j ;
                        by bene_id start;
                                j = 0;
                                if last.start then j = j + 1;
run;

proc sort data=hospice_base9 out=hospice_base10;
by bene_id end;
run;


/**************************************************************/
/**************************************************************/
/***********************ICD 9 CODE*****************************/
/**************************************************************/
/**************************************************************/

/*just keep first 5 diagnosis codes for the first claim for a hospice stay*/
proc sort data=hospice_base10 out=icd; by bene_id start; run;
data ICD1;
        set icd (keep = bene_id PRNCPAL_DGNS_CD start ICD_DGNS_CD1 ICD_DGNS_CD2 ICD_DGNS_CD3 ICD_DGNS_CD4 ICD_DGNS_CD5);
                by bene_id start;
                        if first.start;
run;
data icd_final;
        set icd1;
                primary_icd = PRNCPAL_DGNS_CD;
                icd_1 = ICD_DGNS_CD1;
                icd_2 = ICD_DGNS_CD2;
                icd_3 = ICD_DGNS_CD3;
                icd_4 = ICD_DGNS_CD4;
                icd_5 = ICD_DGNS_CD5;
                drop ICD_DGNS_CD1 ICD_DGNS_CD2 ICD_DGNS_CD3 ICD_DGNS_CD4 ICD_DGNS_CD5 PRNCPAL_DGNS_CD;
run;


/**************************************************************/
/**************************************************************/
/***********************Provider Code**************************/
/**************************************************************/
/**************************************************************/

/*check to see if provider changes during a continuous stay
that spans multiple claims
provider_i is count of number of different providers for that stay
assigns first provider id recorded for that hospice stay as the provider
of record for the analysis*/
proc sort data=hospice_base10 out=provider; by bene_id start; run;
data provider1;
        set provider (keep = bene_id start PRVDR_NUM);
                by bene_id start;
                retain i;
                        provider_num = PRVDR_NUM + 0;
                        prov_diff = provider_num - lag(provider_num);
                        if first.start then do;
                        i = 1;
                        provider = provider_num;
                        prov_diff = 0;
                        end;
                        if prov_diff ~= 0 then i = i + 1;
                        drop PRVDR_NUM;
                        provider_i = i;
                        drop i prov_diff provider_num;
run;
/*keeps list of provider count provider_i for each stay*/
data provider2a;
        set provider1;
        by bene_id start;
                if last.start;
                drop provider;
run;
/*keeps first provider id for the stay*/
data provider2b;
        set provider1;
        by bene_id start;
                if first.start;
                drop provider_i;
run;
/*table of first provider id to assign to stay and count of number of providers for reference*/
proc sql;
        create table provider3
        as select *
        from provider2a a
        left join provider2b b
        on a.bene_id = b.bene_id and a.start = b.start;
quit;
proc freq data=provider3;
        table provider_i;
run;

/*************************************************************/
/*************************************************************/
/*********************Discharge Codes*************************/
/*************************************************************/
/*************************************************************/

/*create indicator for change in discharge code for claims that span
a continuous hospice stay*/
data discharge;
        set hospice_base10 (keep = bene_id start PTNT_DSCHRG_STUS_CD j);
                by bene_id start;
                retain i;
                        discharge_num = PTNT_DSCHRG_STUS_CD + 0;
                        discharge_diff = discharge_num - lag(discharge_num);
                        if first.start then do;
                        i = 1;
                        discharge_diff = 0;
                        end;
                        if last.start then do;
                        discharge = PTNT_DSCHRG_STUS_CD + 0;
                        end;
                        if discharge_diff ~=0 then i = i + 1;
                        drop PTNT_DSCHRG_STUS_CD;
                        discharge_i= i;
run;
/*just keep discharge code for last claim and assign it to the whole stay*/
data discharge1;
        set discharge;
        if j = 1;
        drop discharge_num discharge_diff i j;
run;

<<<<<<< HEAD
=======

>>>>>>> c99df7dbf835fe49cbdf1d41f4dd2be422e98414
/**********************************************************************************/
/* Bring in overall stay details */
/**********************************************************************************/

/*First - create dataset that is a list of stays, not claims */
data hospice_base11;
set hospice_base10;
if j=1;
drop CLM_ID  CLM_FROM_DT CLM_THRU_DT NCH_WKLY_PROC_DT FI_CLM_PROC_DT CLM_FREQ_CD
                 CLM_MDCR_NON_PMT_RSN_CD CLM_PMT_AMT NCH_PRMRY_PYR_CLM_PD_AMT NCH_PRMRY_PYR_CD   
                PTNT_DSCHRG_STUS_CD CLM_TOT_CHRG_AMT NCH_PTNT_STATUS_IND_CD CLM_UTLZTN_DAY_CNT NCH_BENE_DSCHRG_DT PRNCPAL_DGNS_CD PRNCPAL_DGNS_VRSN_CD
                ICD_DGNS_CD1-ICD_DGNS_CD25 ICD_DGNS_VRSN_CD1-ICD_DGNS_VRSN_CD25 CLM_HOSPC_START_DT_ID BENE_HOSPC_PRD_CNT  CLM_LINE_NUM REV_CNTR REV_CNTR_DT 
                 REV_CNTR_UNIT_CNT REV_CNTR_RATE_AMT REV_CNTR_PRVDR_PMT_AMT REV_CNTR_BENE_PMT_AMT REV_CNTR_PMT_AMT_AMT REV_CNTR_TOT_CHRG_AMT REV_CNTR_NCVRD_CHRG_AMT REV_CNTR_DDCTBL_COINSRNC_CD
                REV_CNTR_NDC_QTY REV_CNTR_NDC_QTY_QLFR_CD 
                FST_DGNS_E_CD FST_DGNS_E_VRSN_CD ICD_DGNS_E_CD1-ICD_DGNS_E_CD12 ICD_DGNS_E_VRSN_CD1-ICD_DGNS_E_VRSN_CD12; 
run;

/*bring in discharge destination code to base hospice stays dataset
this hospice base dataset still has multiple lines per stay based on claims*/
proc sql;
        create table hospice_base12a
        as select a.*,b.discharge,b.discharge_i
        from hospice_base11 a
        left join discharge1 b
        on a.bene_id = b.bene_id and a.start = b.start;
quit;

/*bring in the provider id and count to  base hospice dataset*/
proc sql;
        create table hospice_base12b
        as select a.*,b.provider,b.provider_i
        from hospice_base12a a
        left join provider3 b
        on a.bene_id = b.bene_id and a.start= b.start;
quit;

/*bring in first 5 diagnoses for each stay*/
proc sql;
        create table hospice_base12c
        as select *
        from hospice_base12b a
        left join icd_final b
        on a.bene_id = b.bene_id and a.start=b.start;
quit;

/********************************************************************************/
/********************************************************************************/
/* Restructure dataset so one observation per bene id, with details
on each claim as separate variables    */
/********************************************************************************/
/********************************************************************************/
/*create count variable of each stay by bene id*/
data hospice_base13; set hospice_base12c;
        by bene_id;
        if first.bene_id then indic3 = 1;
        else indic3 + 1;
        drop indic2 indic;
run; 

proc freq data=hospice_base13;
        table indic3;
run;

/*get table of count of stays for each beneficary id*/
proc sort data=hospice_base13 out=hs_stay_ct1;
by bene_id indic3;
<<<<<<< HEAD
run;

data hs_stay_ct2;
set hs_stay_ct1;
by bene_id;
if last.bene_id then k=1;
keep bene_id indic3 k;
run;

data hs_stay_ct3;
set hs_stay_ct2(rename=(indic3=count_hs_stays));
if k=1;
drop k;
run;

proc freq data=hs_stay_ct3;
table count_hs_stays;
run;

/*get table of count of stays for each beneficary id*/
proc sort data=hospice_base13 out=hs_stay_ct1;
by bene_id indic3;
run;

data hs_stay_ct2;
set hs_stay_ct1;
by bene_id;
if last.bene_id then k=1;
keep bene_id indic3 k;
run;

data hs_stay_ct3;
set hs_stay_ct2(rename=(indic3=count_hs_stays));
if k=1;
drop k;
run;

proc freq data=hs_stay_ct3;
table count_hs_stays;
run;
=======
run;

data hs_stay_ct2;
set hs_stay_ct1;
by bene_id;
if last.bene_id then k=1;
keep bene_id indic3 k;
run;

data hs_stay_ct3;
set hs_stay_ct2(rename=(indic3=count_hs_stays));
if k=1;
drop k;
run;

proc freq data=hs_stay_ct3;
table count_hs_stays;
run;

>>>>>>> c99df7dbf835fe49cbdf1d41f4dd2be422e98414

/*macro to create set of variables for each hospice stay, up to max of 21 stays
keep detailed information for first 3 stays, then limited information for any
remaining stays
Resulting dataset = macro1
Has 1 row per beneficiar ID with details on multiple hospice stays*/
option nospool;
%macro test;
        %do j = 1 %to 21;
                data macro&j;
                set hospice_base13;
                        if indic3 = &j;
                run;
                %if &j > 1 and &j < 4 %then %do;
                        option nospool;
                        data macro1_&j;
                                set macro&j (keep = BENE_ID start end totalcost provider provider_i discharge discharge_i primary_icd icd_1 icd_2 icd_3 icd_4 icd_5);
                        run;
                        proc datasets nolist;
                                delete macro&j;
                        run;
                        data macro2_&j;
                                set macro1_&j;
                                        start&j = start;
                                        end&j = end;
                                        totalcost&j = totalcost;
                                        provider&j = provider;
                                        provider_i_&j = provider_i;
                                        discharge&j = discharge;
                                        discharge_i_&j = discharge_i;
                                        primary_icd&j = primary_icd;
                                        icd_1_&j = icd_1;
                                        icd_2_&j = icd_2;
                                        icd_3_&j = icd_3;
                                        icd_4_&j = icd_4;
                                        icd_5_&j = icd_5;
                                        label start&j = "Start Date (Stay &j)";
                                        label end&j = "End Date (Stay &j)";
                                        label totalcost&j = "Total Cost Spent (Stay &j)";
                                        label provider&j = "Provider ID during Stay (Stay &j)";
                                        label provider_i_&j = "If Greater Than 1, Provider Changes within Stay (Stay &j)";
                                        label discharge&j = "Discharge Code (Stay &j)";
                                        label discharge_i_&j = "If Greater than 1, Discharge Codes changes with Stay (Stay &j)";
                                        label primary_icd&j = "Primary Diagnosis Code (Stay &j)";
                                        label icd_1_&j = "Diagnosis Code I (Stay &j)";
                                        label icd_2_&j = "Diagnosis Code II (Stay &j)";
                                        label icd_3_&j = "Diagnosis Code III (Stay &j)";
                                        label icd_4_&j = "Diagnosis Code IV (Stay &j)";
                                        label icd_5_&j = "Diagnosis Code V (Stay &j)";
                                        format start&j date9. end&j date9.;
                        run;
                        proc datasets nolist;
                                delete macro1_&j;
                        run;        
                        data macro3_&j;
                                set macro2_&j (keep = BENE_ID start&j end&j totalcost&j discharge&j provider&j primary_icd&j provider_i_&j discharge_i_&j icd_1_&j icd_2_&j icd_3_&j icd_4_&j icd_5_&j);
                        run;
                        proc datasets nolist;
                                delete macro2_&j;
                        run;
                                         
                %end;
                %if &j >= 4 %then %do;
                        option nospool;
                        data macro1_&j;
                                set macro&j (keep = BENE_ID start end totalcost discharge);
                        run;
                        proc datasets nolist;
                                delete macro&j;
                        run;
                        data macro2_&j;
                                set macro1_&j;
                                        start&j = start;
                                        end&j = end;
                                        totalcost&j = totalcost;
                                        discharge&j = discharge;
                                        label start&j = "Start Date (Stay &j)";
                                        label end&j = "End Date (Stay &j)";
                                        label totalcost&j = "Total Cost Spent (Stay &j)";
                                        label discharge&j = "Discharge Code (Stay &j)";
                                        format start&j date9. end&j date9.;
                        run;
                        proc datasets nolist;
                                delete macro1_&j;
                        run;        
                        data macro3_&j;
                                set macro2_&j (keep = BENE_ID start&j end&j totalcost&j discharge&j);
                        run;
                        proc datasets nolist;
                                delete macro2_&j;
                        run;
                        %end;

                        proc sql;
                        create table macro1
                         as select *
                         from macro1 a
                                  left join macro3_&j b
                                          on a.bene_id = b.bene_id;
                        quit;
                        proc datasets nolist;
                                delete macro3_&j;
                        run;
                        quit;
        %end;
%mend;
%test;        
proc contents data=macro1 varnum;
run;
proc sort data=macro1 out=macro2;
        by bene_id;
run;
proc sort data = Total_rev_center;
        by bene_id;
run;

/*bring in total revenue center days by type for each beneficiary*/
proc sql;
        create table macro3
        as select *
        from macro2 a
        left join total_rev_center b
        on a.bene_id = b.bene_id;
quit;

/*bring in count of hosipce stays for each beneficiary*/
proc sort data=macro3;
by bene_id;
run;
proc sort data=hs_stay_ct3;
by bene_id;
run;

proc sql;
create table macro3a
as select a.*,b.count_hs_stays
from macro3 a
left join hs_stay_ct3 b
on a.bene_id = b.bene_id;
quit; 

/*cleans up final dataset by dropping unneeded variables*/
data macro4;
        set macro3a;
        drop NCH_NEAR_LINE_REC_IDENT_CD NCH_CLM_TYPE_CD FI_NUM PRVDR_STATE_CD AT_PHYSN_UPIN AT_PHYSN_NPI
          CLM_MDCL_REC daydiff j indic3 PRVDR_NUM;
                label start = "Start Date (Stay 1)";
                label end = "End Date (Stay 1)";
                label totalcost = "Total Cost Spent (Stay 1)";
                label provider = "Provider ID during Stay (Stay 1)";
                label provider_i = "If Greater Than 1, Provider Changes within Stay (Stay 1)";
                label discharge = "Discharge Code (Stay 1)";
                label discharge_i = "If Greater than 1, Discharge Codes changes with Stay (Stay 1)";
                label primary_icd = "Primary Diagnosis Code (Stay 1)";
                label icd_1 = "Diagnosis Code I (Stay 1)";
                label icd_2 = "Diagnosis Code II (Stay 1)";
                label icd_3 = "Diagnosis Code III (Stay 1)";
                label icd_4 = "Diagnosis Code IV (Stay 1)";
                label icd_5 = "Diagnosis Code V (Stay 1)";
				label hs_stay_ct3 = "Count of hospice stays";
run;
data macro5;
        retain BENE_ID CLM_FAC_TYPE_CD CLM_SRVC_CLSFCTN_TYPE_CD ORG_NPI_NUM DOB_DT GNDR_CD BENE_RACE_CD BENE_CNTY_CD BENE_STATE_CD BENE_MLG_CNTCT_ZIP_CD start end totalcost provider provider_i discharge discharge_i icd_1 icd_2 icd_3 icd_4 icd_5;
        set macro4;
        label total_650 = "Total Days in Hospice General Services";
        label total_651 = "Total Days in Routine Home Care";
        label total_652 = "Total Days in Continuous Home Care";
        label total_655 = "Total Days in Inpatient Hospice Care";
        label total_656 = "Total Days in General Inpatient Care under Hospice services (non-Respite)";
        label total_657 = "Total Number of Procedures in Hospice Physician Services";
run;
data wk_fldr.hs_stays_cleaned;
        set macro5;        
run;

/*Check - drops all but the one observation with 21 stays*/
data test;
        set macro5;
                if totalcost21=. then delete;
run;

/*Check to confirm one row per beneficiary id - no observations dropped*/
data unique;
	set macro5;
	by bene_id;
	if first.bene_id;
run;

/*****************************************************************/
/*create additional variables for hospice outcomes*/
/*****************************************************************/
data hs_los;
  set wk_fldr.hs_stays_cleaned;
	rename start = start1;
    rename end = end1;
    rename totalcost = totalcost1;
    rename discharge = discharge1;        
run;

data hs_los2;
set hs_los;
s=1;
%do s=1 %to 21;
	los_&s. = end&s. - start&s. ;
    s = &s. + 1;
end;
run;

/*add hospice length of stay, total and first stay, variables*/
array stays{21};
 





/*****************************************************************/
/*create output file to review with Melissa*/
/*****************************************************************/

data hs_output_1;
set wk_fldr.hs_stays_cleaned;
run;
<<<<<<< HEAD
=======

>>>>>>> c99df7dbf835fe49cbdf1d41f4dd2be422e98414
