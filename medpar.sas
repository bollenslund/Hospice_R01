libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

data medpar;
	set merged.medpar_all_file;
run;

proc freq data=medpar;
	table BENE_DSCHRG_STUS_CD;
run;		

proc contents data=medpar varnum;
run;
