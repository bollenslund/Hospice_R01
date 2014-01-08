libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';
libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10'; 


data hospice;
set ccw.final1;
run;

data hospice1;
set hospice;
if start2 ~=.;
startdiff = start2 - end;
if startdiff = 1 then diff = 1;
if startdiff = 2 or startdiff = 3 or startdiff = 4 then diff = 2;
if startdiff > 4 then diff = 3;
run;

proc format;
	value label
		1 = '1 day difference'
		2 = '2-4 day difference'
		3 = "more than 4 day difference";
run;
ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\daydiff.rtf";
title "Disenrollment rate after 1st stay";
proc freq data=ccw.final1;
table disenr;
run;
title "Frequency of people with 2-4 day difference between first and second hospice visit";
proc freq data=hospice1;
format diff label.;
table diff;
run;
ods rtf close;

data disenroll;
set ccw.final1;
if disenr = 1;
run;
ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\discrepancy.rtf";
title "Death in other departments if disenrolled";
proc freq data=disenroll;
table hosp_death snf_death;
run;
title "Death in other departments. Everyone";
proc freq data=ccw.final1;
table hosp_death snf_death;
run;
title "Those still discharged as death (40-43). They usually have a second Hospice date";
proc freq data=disenroll;
table discharge;
run;
ods rtf close;
data disenroll;
set disenroll;
i = 1;
if start2 = . then i = 0;
run;
proc freq data=disenroll;
table i*discharge;
run;

data disenroll1;
set disenroll;
if i = 0 and discharge = 30;
run;

proc freq data=disenroll;
table discharge;
run;
data discrep;
set disenroll;
if discharge >= 40 and discharge <50;
run;

data discrepancy;
set ccw.final1;
if disenr = 0 and hosp_death = 1;
run;
data discrepancy1;
set discrepancy;
datedif = .;
if IP_death1 = 1 then do;
datedif = IP_end1 - end;
end;
if IP_death2 = 1 then do;
datedif = IP_end2 - end;
end;
if IP_death3 = 1 then do;
datedif = IP_end3 - end;
end;
if IP_death4 = 1 then do;
datedif = IP_end4 - end;
end;
if IP_death5 = 1 then do;
datedif = IP_end5 - end;
end;
run;
data discrepancy2;
set discrepancy1;
if datedif ~= 0;
if IP_death1 = 1 then do;
datedif1 = end - IP_start1;
end;
if IP_death2 = 1 then do;
datedif1 = end - IP_start2;
end;
if IP_death3 = 1 then do;
datedif1 = end - IP_start3;
end;
if IP_death4 = 1 then do;
datedif1 = end - IP_start4;
end;
if IP_death5 = 1 then do;
datedif1 = end - IP_start5;
end;
run;
data discrepancy3;
set discrepancy2;
if datedif1 < 0;
if IP_death1 = 1 then do;
datedif1 = BENE_DEATH_DT - IP_end1;
datedif2 = BENE_DEATH_DT - end;
end;
if IP_death2 = 1 then do;
datedif1 = BENE_DEATH_DT - IP_end2;
datedif2 = BENE_DEATH_DT - end;
end;
run;

data final;
set ccw.final;
run;

data final1;
set final;
rename start = start1;
rename end = end1;
rename totalcost = totalcost1;
rename provider = provider1;
rename provider_i = provider_i_1;
rename discharge = discharge1;
rename discharge_i = discharge_i_1;
rename icd_1 = icd_1_1;
rename icd_2 = icd_2_1;
rename icd_3 = icd_3_1;
rename icd_4 = icd_4_1;
rename icd_5 = icd_5_1;
drop stay_los primary_icd primary_icd2 primary_icd3 primary_icd4 primary_icd5;
run;

data zzztest;
set merged.Hospice_base_claims_j;
run;
data zzztest1;
set zzztest;
if bene_id = 'ZZZZZZZk3k4uu94' or 
bene_id = 'ZZZZZZZk3k9O34p' or 
bene_id = 'ZZZZZZZk3yO44yI' or 
bene_id = 'ZZZZZZZk4IIky9y' or 
bene_id = 'ZZZZZZZk4OZ9kk4' or 
bene_id = 'ZZZZZZZk39ky4O3' or 
bene_id = 'ZZZZZZZk39k93py' or 
bene_id = 'ZZZZZZZZOOZOpu9';
run;
proc sort data=zzztest1;
by bene_id CLM_FROM_DT;
run;
