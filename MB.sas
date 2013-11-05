libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';

data mb_ab;
	set merged.mbsf_ab_summary;
run;
data mb_cc;
	set merged.mbsf_cc_summary;
run;

proc sort data=mb_ab;
	by bene_id BENE_ENROLLMT_REF_YR;
run;
proc sort data=mb_cc;
	by bene_id BENE_ENROLLMT_REF_YR;
run;

/*working getting date of death information*/
proc sort data=mb_ab out=dod;
	by bene_id BENE_ENROLLMT_REF_YR;
run;
data dod1;
	set dod;
	by bene_id BENE_ENROLLMT_REF_YR;
	if last.bene_id then output;
run;
data dod2;
	set dod1 (keep = bene_id BENE_DEATH_DT BENE_VALID_DEATH_DT_SW NDI_DEATH_DT BENE_ENROLLMT_REF_YR);
run;

/*Year in which a patient is terminated*/
proc freq data=mb_ab;
	table BENE_PTA_TRMNTN_CD BENE_PTB_TRMNTN_CD;
run;
/*both part a and b are not coded as binary. 
CODES: 
0= NOT TERMINATED
1 = DEAD
2 = NON-PAYMENT OF PREMIUM
3 = VOLUNTARY WITHDRAWAL
9 = OTHER TERMINATION
all checked. No Date of death for any value that is not 1.
*/

data term;
	set mb_ab;
	if BENE_PTA_TRMNTN_CD = 1 or BENE_PTB_TRMNTN_CD = 1;
run;
data term1;
	set term (keep = bene_id  BENE_DEATH_DT BENE_VALID_DEATH_DT_SW NDI_DEATH_DT BENE_ENROLLMT_REF_YR);
	year_death = BENE_ENROLLMT_REF_YR + 0;
	i = 1;
	drop BENE_ENROLLMT_REF_YR;
run;
proc sql;
	create table death
	as select *
	from dod2 a
	left join term1 b
	on a.bene_id = b.bene_id 
	and a.BENE_DEATH_DT = b.BENE_DEATH_DT;
quit;
data death1;
	set death;
	yrdiff = BENE_ENROLLMT_REF_YR - year_death;
run;
proc freq data=death1;
	table yrdiff;
run;
data death_fin;
	set death1;
	drop i year_death yrdiff;
run;

BENE_AGE_AT_END_REF_YR BENE_BIRTH_DT BENE_SEX_IDENT_CD BENE_RACE_CD STATE_CODE BENE_COUNTY_CD BENE_ZIP_CD
