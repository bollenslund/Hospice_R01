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
hdeath_during_hosp= 0;
hdeath_after_hosp = 0;
if hosp_death = 1 then do;
	if dod_clean <= end1 then hdeath_during_hosp = 1;
	if dod_clean > end1 then hdeath_after_hosp = 1;
end;
run;

proc freq data=trunc_table5_2;
table hosp_death hdeath_during_hosp hdeath_after_hosp;
run;
data test;
set trunc_table5_2;
if hdeath_during_hosp = 1;
run;

%macro ed;

data trunc_table5_2;
set trunc_table5_2;
%do i = 1 %to 39;
	if hosp_adm_ind = 1 and ip_start&i~= . then do;
		if ip_start&i < end1 then hospital_during_hosp = 1;
		ip_los&i = ip_end&i - ip_start&i+1;
		if ip_start&i = end1 and ip_los&i = 1 then hospital_during_hosp = 1;
		if ip_start&i = end1 and ip_los&i > 1 then hospital_after_hosp = 1;
		if ip_start&i > end1 then hospital_after_hosp = 1;
	end;
	if ed_visit_ind = 1 then do;
		if (ip_icued&i = 1|ip_icued&i = 3) and ip_start&i~=. then do;
			if ip_start&i < end1 then ed_during_hosp = 1;
			ip_los&i = ip_end&i - ip_start&i+1;
			if ip_start&i = end1 and ip_los&i = 1 then ed_during_hosp = 1;
			if ip_start&i = end1 and ip_los&i > 1 then ed_after_hosp = 1;
			if ip_start&i > end1 then ed_after_hosp = 1;
		end;
		if ed_start&i ~= . then do;
			if ed_start&i < end1 then ed_during_hosp = 1;
			if ed_start&i >= end1 then ed_after_hosp = 1;
		end;
	end;
	if icu_stay_ind = 1 and IP_icued&i~=. then do;
		if IP_icued&i = 2 or IP_icued&i = 3 then do;
			if ip_start&i < end1 then icu_during_hosp = 1;
			ip_los&i = ip_end&i - ip_start&i+1;
			if ip_start&i = end1 and ip_los&i = 1 then icu_during_hosp = 1;
			if ip_start&i = end1 and ip_los&i > 1 then icu_after_hosp = 1;
			if ip_start&i > end1 then icu_after_hosp = 1;
		end;
	end;
%end;
drop ed_start34-ed_start39;
run;
%mend;
%ed;

ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\beforeafter.rtf";
proc freq data=trunc_table5_2;
table ed_visit_ind ed_during_hosp ed_after_hosp;
run;
proc freq data=trunc_table5_2;
table ed_visit_ind;
where ed_during_hosp = 1 and ed_after_hosp = 1;
run;
proc freq data=trunc_table5_2;
table hosp_adm_ind hospital_during_hosp hospital_after_hosp;
run;
proc freq data=trunc_table5_2;
table hosp_adm_ind;
where hospital_during_hosp = 1 and hospital_after_hosp = 1;
run;
proc freq data=trunc_table5_2;
table icu_stay_ind icu_during_hosp icu_after_hosp;
run;
proc freq data=trunc_table5_2;
table icu_stay_ind;
where icu_during_hosp = 1 and icu_after_hosp = 1;
run;
ods rtf close;


data trunc_table5_3;
set trunc_table5_2;
hosp1wk = 0;
hosp2wk = 0;
ed1wk_ip = 0;
ed2wk_ip = 0;
ed1wk_op = 0;
ed2wk_op = 0;
	if IP_Start1 ~=. and hosp_adm_ind = 1 then do;
		if ip_start1 - start1  <=7 then hosp1wk = 1;
		if ip_start1 - start1 <= 14 then hosp2wk = 1;
	end;
	if ed_visit_ind = 1 then do;
		
		if (ip_icued1 = 1|ip_icued1 = 3) and ip_start1~=. then do;
			if ip_start1 - start1 <= 7 then ed1wk_ip = 1;
			if ip_start1 - start1 <= 14 then ed2wk_ip = 1;
		end;
		if ed_start1 ~= . then do;
			if ed_start1 - start1 <=7 then ed1wk_op = 1;
			if ed_start1 - start1 <=14 then ed2wk_op = 1;
		end;
	end;
ed1wk = 0;
ed2wk = 0;
if ed1wk_ip = 1 or ed1wk_op = 1 then ed1wk = 1;
if ed2wk_ip = 1 or ed2wk_op = 1 then ed2wk = 1;	

run;
proc freq data=trunc_table5_3;
table hosp1wk hosp2wk ed1wk ed2wk;
run;

data test;
set trunc_table5_3;
if ed1wk = 1 and ed_start1 ~= . and ip_start1=.;
run;

data ccw.beforeafterhospice;
set trunc_table5_3 (keep = bene_id hospital_during_hosp hospital_after_hosp ed_during_hosp ed_after_hosp icu_during_hosp icu_after_hosp hdeath_during_hosp hdeath_after_hosp hosp1wk hosp2wk ed1wk ed2wk);
run;

proc sql;
create table ccw.hsp_level_numbers1
as select *
from ccw.hospice_level_numbers a
left join ccw.beforeafterhospice b
on a.bene_id = b.bene_id;
quit;
