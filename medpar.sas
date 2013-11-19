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

proc freq data=medpar1;
	table ICU_IND_CD;
run;
