libname ccw "J:\Geriatrics\Geri\Hospice Project\Hospice\working";

data hospice;
set ccw.Final_hosp_county;
run;

data hospice1;
set hospice;
drop CLM_FAC_TYPE_CD CLM_SRVC_CLSFCTN_TYPE_CD ORG_NPI_NUM GNDR_CD totalcost start end discharge discharge_i primary_icd
icd_1 icd_2 icd_3 icd_4 icd_5 stay_los CLM_ID;
label total_los = "Total Length of Stay";
label hs1_death = "Death in the first hospice stay";
label disenr = "Disenrollment after first Hospice Stay";
label dod_clean = "Death Date from Hospice, MBS, Medpar";
label BENE_DEATH_DATE = "Death Date from Master Beneficiary File";
label provider_id = "Provider ID";
label pos_change = "Indicator: Person switched providers";
run;

data hospice2;
set hospice1;
death = 0;
if dod_clean ~= . then death = 1;
label death = "Death at some point during Claim dates";
run;

proc freq data=hospice2;
table CC_GRP_1*death CC_GRP_2*death CC_GRP_3*death CC_GRP_4*death CC_GRP_5*death CC_GRP_6*death CC_GRP_7*death CC_GRP_8*death CC_GRP_9*death
CC_GRP_10*death CC_GRP_11*death CC_GRP_12*death CC_GRP_13*death CC_GRP_14*death CC_GRP_15*death CC_GRP_16*death CC_GRP_17*death / chisq cmh;
run;

proc freq data=hospice2;
table death*female / chisq cmh;
run;

proc logistic data=hospice2;
model CC_GRP_1 = death female;
run;
