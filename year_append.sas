/*This file processes files in the raw_sas directory into single files 
with claims data from 2007 through 2010
Separate files by claim type and data contents type are saved

All output files are saved to:
J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10

Only processes files we anticipate needing for the project:
Non-instutional claims:
Carrier: claims
DME: claims

Institutional claims:
Hospice: base and revenue center
HHA: Base
Medpar: all_file
Outpatient: base and revenue center

Beneficiay summary file:
ab_summary
cc_summary

Can add files as needed
*/

/*libname for individual year raw sas files*/
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\raw_sas';
/*libname for merged, output files*/
libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';

/*macros for instutitional claims types, excluding medpar:
hospice
hha
outpatient
*/
%macro yr(year=);
	data work.&clm_type._&file._&year.;
		set ccw.&clm_type._&year._&file.;
	run;
	proc append base=&clm_type._&file. data=&clm_type._&file._&year.;
	run;
%mend;

%macro appd(clm_type=,file=);

	/*initialize first year file - 2007*/
	%let yr=2007;
	data work.&clm_type._&file._&yr.;
		set ccw.&clm_type._&yr._&file.;
	run;

	/*create dataset to merge in additional years*/
	data &clm_type._&file.;
		set &clm_type._&file._&yr.;
	run;

	/*invoke macro to process additional years*/
	%yr(year=2008);
	%yr(year=2009);
	%yr(year=2010);

	/*save dataset*/
	data merged.&clm_type._&file.;
	set work.&clm_type._&file.;
	run;
%mend;

/*carrier*/
%appd(clm_type=bcarrier, file=claims_j);
/*dme*/
%appd(clm_type=dme, file=claims_j);
/*hha*/
%appd(clm_type=hha, file=base_claims_j);
/*hospice*/
%appd(clm_type=hospice, file=base_claims_j);
%appd(clm_type=hospice, file=revenue_center_j);
/*mbsf*/
%appd(clm_type=mbsf, file=ab_summary);
%appd(clm_type=mbsf, file=cc_summary);
/*medpar*/
%appd(clm_type=medpar, file=all_file);
/*outpatient*/
%appd(clm_type=outpatient, file=base_claims_j);
%appd(clm_type=outpatient, file=revenue_center_j);

