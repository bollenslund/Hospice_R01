data trunc_table5;
set table5 (keep = bene_id start1 end1 end2 hosp_death dod_clean ed_visit_ind discharge1 disenr IP_start1-IP_start39 IP_end1-IP_end39 IP_icued1-IP_icued39 admit_pre12m hosp_adm_ind hosp_adm_days hosp_adm_cnt ip_ed_visit_ind ip_ed_visit_cnt icu_stay_ind
icu_stay_days icu_stay_cnt hosp_death ip_tot_cost ed_start1-ed_start33 op_ed_count op_ed_ind);
run;
data trunc_table5_1;
retain bene_id start1 end1 discharge1 disenr;
set trunc_table5;
run;

proc freq data=trunc_table5_1;
table discharge1 disenr;
run;

data trunc_table5_2;
set trunc_table5_1;
hospital_during_hosp = 0;
hospital_after_hosp = 0;
ed_during_hosp = 0;
ed_after_hosp = 0;
icu_during_hosp = 0;
icu_after_hosp = 0;
run;

%macro ed;

data trunc_table5_2;
set trunc_table5_2;
%do i = 1 %to 39;
	if hosp_adm_ind = 1 and ip_start&i~= . then do;
		if ip_start&i < end1 then hospital_during_hosp = 1;
		if ip_start&i >= end1 then hospital_after_hosp = 1;
	end;
	if ed_visit_ind = 1 then do;
		if (ip_icued&i = 1|ip_icued&i = 3) and ip_start&i~=. then do;
			if ip_start&i < end1 then ed_during_hosp = 1;
			if ip_start&i >= end1 then ed_after_hosp = 1;
		end;
		if ed_start&i ~= . then do;
			if ed_start&i < end1 then ed_during_hosp = 1;
			if ed_start&i >= end1 then ed_after_hosp = 1;
		end;
	end;
	if icu_stay_ind = 1 and IP_icued&i~=. then do;
		if IP_icued&i = 2 or IP_icued&i = 3 then do;
			if ip_start&i < end1 then icu_during_hosp = 1;
			if ip_start&i >= end1 then icu_after_hosp = 1;
		end;
	end;
%end;
drop ed_start34-ed_start39;
run;
%mend;
%ed;

proc freq data=trunc_table5_2;
table ed_during_hosp ed_after_hosp;
run;

data test;
set trunc_table5_2;
where hospital_during_hosp = 1 and hospital_after_hosp = 1;
run;
data test;
set trunc_table5_2;
if (discharge1 = 40|discharge1=41|discharge1=42) and IP_start1 ~= .;
run;
