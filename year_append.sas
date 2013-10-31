/*This file processes files in the raw_sas directory into single files 
with claims data from 2007 through 2010
Separate files by claim type and data contents type are saved

All output files are saved to:
J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10
*/

/*libname for individual year raw sas files*/
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\raw_sas';
/*libname for merged, output files*/
libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';


%macro base(clm_type=);

/*initialize first year file - 2007*/
%let yr=2007;
data work.&clm_type._base_&yr.;
	set ccw.&clm_type._&yr._base_claims_j;
run;

/*create empty dataset*/
data &clm_type._base;
set &clm_type._base_&yr.;
	if bene_id=. then delete;
run;

/*repeat for 2008, appending to _base dataset*/
%let yr=2008;
data work.&clm_type._base_&yr.;
	set ccw.&clm_type._&yr._base_claims_j;
run;
proc append base=&clm_type._base data=&clm_type._base_&yr.;
run;


%let yr=2009;
data work.&clm_type._base_&yr.;
	set ccw.&clm_type._&yr._base_claims_j;
run;
proc append base=&clm_type._base data=&clm_type._base_&yr.;
run;

%let yr=2010;
data work.&clm_type._base_&yr.;
	set work.&clm_type._base_&yr.;
run;
proc append base=&clm_type._base data=&clm_type._base_&yr.;
run;

/*save dataset*/
data merged.&clm_type._base;
set work.&clm_type._base;
run;


%mend;

%base(clm_type='hospice');
