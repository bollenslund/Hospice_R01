libname co 'N:\Documents\Downloads\Melissa\Hospice_Cost_Data\data';

PROC IMPORT OUT= WORK.HospiceCosts20091
            DATAFILE= "N:\Documents\Downloads\Melissa\Hospice_Cost_Data\2009\hospc_2009_RPT.CSV" 
            DBMS=csv REPLACE;
RUN;
PROC IMPORT OUT= WORK.HospiceCosts20092
            DATAFILE= "N:\Documents\Downloads\Melissa\Hospice_Cost_Data\2009\hospc_2009_ALPHA.CSV" 
            DBMS=csv REPLACE;
RUN;
PROC IMPORT OUT= WORK.HospiceCosts20093
            DATAFILE= "N:\Documents\Downloads\Melissa\Hospice_Cost_Data\2009\hospc_2009_NMRC.CSV" 
            DBMS=csv REPLACE;
RUN;
PROC IMPORT OUT= WORK.HospiceCosts20101
            DATAFILE= "N:\Documents\Downloads\Melissa\Hospice_Cost_Data\2010\hospc_2010_RPT.CSV" 
            DBMS=csv REPLACE;
RUN;
PROC IMPORT OUT= WORK.HospiceCosts20102
            DATAFILE= "N:\Documents\Downloads\Melissa\Hospice_Cost_Data\2010\hospc_2010_ALPHA.CSV" 
            DBMS=csv REPLACE;
RUN;
PROC IMPORT OUT= WORK.HospiceCosts20103
            DATAFILE= "N:\Documents\Downloads\Melissa\Hospice_Cost_Data\2010\hospc_2010_NMRC.CSV" 
            DBMS=csv REPLACE;
RUN;

options mprint;
%macro HospiceCosts_sort;
	%do j=2009 %to 2010;
		%do i = 1 %to 3;
			proc sort data=Hospicecosts&j&i;
			by RPT_REC_NUM WKSHT_CD LINE_NUM CLMN_NUM;
			run;
		%end;
	%end;
%mend;
run;
%HospiceCosts_sort;

/*for Worksheet A
data trial_balance_total; 
	set HospiceCosts20093;
		if WKSHT_CD = 'A000000' and LINE_NUM = 10000 and CLMN_NUM = 1000;
run;
data trial_banance_total_1;
	set trial_balance_total;
		total2009 = ITM_VAL_NUM;
		label total2009 = "2009: Total of Reclassification and Adjustment of Trial Balance Expenses";
		drop ITM_VAL_NUM WKSHT_CD LINE_NUM CLMN_NUM;
run;

data trial_balance_total1; 
	set HospiceCosts20103;
		if WKSHT_CD = 'A000000' and LINE_NUM = 10000 and CLMN_NUM = 1000;
run;

data trial_banance_total1_1;
	set trial_balance_total1;
		total2010 = ITM_VAL_NUM;
		label total2010 = "2010: Total of Reclassification and Adjustment of Trial Balance Expenses";
		drop ITM_VAL_NUM WKSHT_CD LINE_NUM CLMN_NUM;
run;
*/
/*for Worksheet A-1 
data salary_total; 
	set HospiceCosts20093;
		if WKSHT_CD = 'A100000' and LINE_NUM = 10000 and CLMN_NUM = 900;
run;
data salary_total_1;
	set salary_total;
		a1total2009 = ITM_VAL_NUM;
		label a1total2009 = "2009: Compensation Analysis Salaries and Wages";
		drop ITM_VAL_NUM WKSHT_CD LINE_NUM CLMN_NUM;
run;

data salary_total1; 
	set HospiceCosts20103;
		if WKSHT_CD = 'A100000' and LINE_NUM = 10000 and CLMN_NUM = 900;
run;

data salary_total1_1;
	set salary_total1;
		a1total2010 = ITM_VAL_NUM;
		label a1total2010 = "2010: Compensation Analysis Salaries and Wages";
		drop ITM_VAL_NUM WKSHT_CD LINE_NUM CLMN_NUM;
run;
*/

data final_2009;
	set Hospicecosts20091 (keep = RPT_REC_NUM);
	year = 2009;
run;
data final_2010;
	set Hospicecosts20101 (keep = RPT_REC_NUM);
	year = 2010;
run;
proc append base=final_2009 data=final_2010;
run;
data final;
	set final_2009;
run;
proc sort data=final;
	 by RPT_REC_NUM;
run;
%macro wksheet(title=, year=, num=, wkst=, line=, col=, totvar=, varname=);
	data &title;
		set HospiceCosts&year&num;
			if WKSHT_CD = &wkst and LINE_NUM = &line and CLMN_NUM = &col;
	run;
	data final_&title;
		set &title;
			&totvar = ITM_VAL_NUM;
			label &totvar = &varname;
			drop ITM_VAL_NUM WKSHT_CD LINE_NUM CLMN_NUM;
	run;
	proc sort data=final_&title;
		by RPT_REC_NUM;
	run;
	data final;
		merge final final_&title;
			by RPT_REC_NUM;
	run;
%mend;

%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=100, col=100, totvar=Hospice_Name, varname="Hospice Name");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=100, col=200, totvar=Hospice_Address, varname="Hospice Address");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=100, col=300, totvar=Hospice_city, varname="Hospice City");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=100, col=400, totvar=Hospice_state, varname="Hospice State");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=100, col=500, totvar=Hospice_zip, varname="Hospice Zip Code");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=200, col=100, totvar=Hospice_County, varname="Hospice County");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=300, col=100, totvar=Op_Begin_Date, varname="Hospice Operation Begin Date");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=400, col=100, totvar=Certification_Date_XVIII, varname="Date Certified (Title XVIII)");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=400, col=200, totvar=Certification_Date_XIX, varname="Date Certified (Title XIX)");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=500, col=100, totvar=Cost_Reporting_Period1, varname="Cost Reporting Period (From)");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=500, col=200, totvar=Cost_Reporting_Period2, varname="Cost Reporting Period (To)");
%wksheet(title=s1pt1, year=2009, num=2, wkst='S100000', line=600, col=100, totvar=Provider_ID, varname="Provider Identification Number");
%wksheet(title=s1pt1, year=2009, num=3, wkst='S100000', line=700, col=100, totvar=Control, varname="Type of Control");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=100, col=100, totvar=Hospice_Name, varname="Hospice Name");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=100, col=200, totvar=Hospice_Address, varname="Hospice Address");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=100, col=300, totvar=Hospice_city, varname="Hospice City");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=100, col=400, totvar=Hospice_state, varname="Hospice State");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=100, col=500, totvar=Hospice_zip, varname="Hospice Zip Code");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=200, col=100, totvar=Hospice_County, varname="Hospice County");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=300, col=100, totvar=Op_Begin_Date, varname="Hospice Operation Begin Date");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=400, col=100, totvar=Certification_Date_XVIII, varname="Date Certified (Title XVIII)");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=400, col=200, totvar=Certification_Date_XIX, varname="Date Certified (Title XIX)");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=500, col=100, totvar=Cost_Reporting_Period1, varname="Cost Reporting Period (From)");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=500, col=200, totvar=Cost_Reporting_Period2, varname="Cost Reporting Period (To)");
%wksheet(title=s1pt1, year=2010, num=2, wkst='S100000', line=600, col=100, totvar=Provider_ID, varname="Provider Identification Number");
%wksheet(title=s1pt1, year=2010, num=3, wkst='S100000', line=700, col=100, totvar=Control, varname="Type of Control");

data s1pt1;
	set final;
run;
data providernum;
	set s1pt1;
	pid = Provider_ID + 0;
	label pid = "Provider Number";
run;
data s1pt1;
	set providernum;
		drop Provider_ID;
run;
data providernum1;
	set providernum (keep = RPT_REC_NUM pid);
run;
data final;
	set final_2009;
run;
proc sort data=final;
	 by RPT_REC_NUM;
run;
data final;
	merge final providernum1;
run;

%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=800, col=100, totvar=cont_home_medicare, varname="Unduplicated Medicare Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=800, col=200, totvar=cont_home_medicaid, varname="Unduplicated Medicaid Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=800, col=300, totvar=cont_home_sknursing, varname="Unduplicated Skilled Nursing Facility Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=800, col=400, totvar=cont_home_nursing, varname="Unduplicated Nursing Facility Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=800, col=500, totvar=cont_home_other, varname="Other Unduplicated Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=800, col=600, totvar=cont_home_tot, varname="Total Unduplicated Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=900, col=100, totvar=rout_home_medicare, varname="Unduplicated Medicare Days in Routine Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=900, col=200, totvar=rout_home_medicaid, varname="Unduplicated Medicaid Days in Routine Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=900, col=300, totvar=rout_home_sknursing, varname="Unduplicated Skilled Nursing Facility Days in Routine Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=900, col=400, totvar=rout_home_nursing, varname="Unduplicated Nursing Facility Days in Routine Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=900, col=500, totvar=rout_home_other, varname="Other Unduplicated Days in Routine Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=900, col=600, totvar=rout_home_tot, varname="Total Unduplicated Days in Routine Home Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1000, col=100, totvar=inpt_respite_medicare, varname="Unduplicated Medicare Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1000, col=200, totvar=inpt_respite_medicaid, varname="Unduplicated Medicaid Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1000, col=300, totvar=inpt_respite_sknursing, varname="Unduplicated Skilled Nursing Facility Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1000, col=400, totvar=inpt_respite_nursing, varname="Unduplicated Nursing Facility Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1000, col=500, totvar=inpt_respite_other, varname="Other Unduplicated Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1000, col=600, totvar=inpt_respite_tot, varname="Total Unduplicated Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1100, col=100, totvar=inpt_general_medicare, varname="Unduplicated Medicare Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1100, col=200, totvar=inpt_general_medicaid, varname="Unduplicated Medicaid Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1100, col=300, totvar=inpt_general_sknursing, varname="Unduplicated Skilled Nursing Facility Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1100, col=400, totvar=inpt_general_nursing, varname="Unduplicated Nursing Facility Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1100, col=500, totvar=inpt_general_other, varname="Other Unduplicated Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1100, col=600, totvar=inpt_general_tot, varname="Total Unduplicated Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1200, col=100, totvar=total_medicare, varname="Total Unduplicated Medicare Days");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1200, col=200, totvar=total_medicaid, varname="Total Unduplicated Medicaid Days");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1200, col=300, totvar=total_sknursing, varname="Total Unduplicated Skilled Nursing Facility Days");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1200, col=400, totvar=total_nursing, varname="Total Unduplicated Nursing Facility Days");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1200, col=500, totvar=total_other, varname="Total Other Unduplicated Days");
%wksheet(title=s1pt2, year=2009, num=3, wkst='S100000', line=1200, col=600, totvar=total_tot, varname="Total Unduplicated Days");

%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=800, col=100, totvar=cont_home_medicare, varname="Unduplicated Medicare Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=800, col=200, totvar=cont_home_medicaid, varname="Unduplicated Medicaid Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=800, col=300, totvar=cont_home_sknursing, varname="Unduplicated Skilled Nursing Facility Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=800, col=400, totvar=cont_home_nursing, varname="Unduplicated Nursing Facility Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=800, col=500, totvar=cont_home_other, varname="Other Unduplicated Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=800, col=600, totvar=cont_home_tot, varname="Total Unduplicated Days in Continuous Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=900, col=100, totvar=rout_home_medicare, varname="Unduplicated Medicare Days in Routine Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=900, col=200, totvar=rout_home_medicaid, varname="Unduplicated Medicaid Days in Routine Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=900, col=300, totvar=rout_home_sknursing, varname="Unduplicated Skilled Nursing Facility Days in Routine Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=900, col=400, totvar=rout_home_nursing, varname="Unduplicated Nursing Facility Days in Routine Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=900, col=500, totvar=rout_home_other, varname="Other Unduplicated Days in Routine Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=900, col=600, totvar=rout_home_tot, varname="Total Unduplicated Days in Routine Home Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1000, col=100, totvar=inpt_respite_medicare, varname="Unduplicated Medicare Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1000, col=200, totvar=inpt_respite_medicaid, varname="Unduplicated Medicaid Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1000, col=300, totvar=inpt_respite_sknursing, varname="Unduplicated Skilled Nursing Facility Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1000, col=400, totvar=inpt_respite_nursing, varname="Unduplicated Nursing Facility Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1000, col=500, totvar=inpt_respite_other, varname="Other Unduplicated Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1000, col=600, totvar=inpt_respite_tot, varname="Total Unduplicated Days in Inpatient Respite Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1100, col=100, totvar=inpt_general_medicare, varname="Unduplicated Medicare Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1100, col=200, totvar=inpt_general_medicaid, varname="Unduplicated Medicaid Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1100, col=300, totvar=inpt_general_sknursing, varname="Unduplicated Skilled Nursing Facility Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1100, col=400, totvar=inpt_general_nursing, varname="Unduplicated Nursing Facility Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1100, col=500, totvar=inpt_general_other, varname="Other Unduplicated Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1100, col=600, totvar=inpt_general_tot, varname="Total Unduplicated Days in Inpatient General Care");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1200, col=100, totvar=total_medicare, varname="Total Unduplicated Medicare Days");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1200, col=200, totvar=total_medicaid, varname="Total Unduplicated Medicaid Days");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1200, col=300, totvar=total_sknursing, varname="Total Unduplicated Skilled Nursing Facility Days");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1200, col=400, totvar=total_nursing, varname="Total Unduplicated Nursing Facility Days");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1200, col=500, totvar=total_other, varname="Total Other Unduplicated Days");
%wksheet(title=s1pt2, year=2010, num=3, wkst='S100000', line=1200, col=600, totvar=total_tot, varname="Total Unduplicated Days");

data s1pt2;
	set final;
run;
data final;
	set final_2009;
run;
proc sort data=final;
	 by RPT_REC_NUM;
run;
data final;
	merge final providernum1;
run;


%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1300, col=100, totvar=pts_hospice_xviii, varname="Number of Patients Receiving Hospice Care (Title XVIII)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1300, col=200, totvar=pts_hospice_xix, varname="Number of Patients Receiving Hospice Care (Title XIX)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1300, col=300, totvar=pts_hospice_sknursing, varname="Number of Patients Receiving Hospice Care (Skill Nursing Facility)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1300, col=400, totvar=pts_hospice_nursing, varname="Number of Patients Receiving Hospice Care (Nursing Facility)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1300, col=500, totvar=pts_hospice_other, varname="Number of Patients Receiving Hospice Care (Other)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1300, col=600, totvar=pts_hospice_total, varname="Number of Patients Receiving Hospice Care (Total)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1400, col=100, totvar=cont_care_xviii, varname="Total Number of Unduplicated Continuous Care Hours Billable to Medicare (Title XVIII)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1400, col=300, totvar=cont_care_sknursing, varname="Total Number of Unduplicated Continuous Care Hours Billable to Medicare (Skill Nursing Facility)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1500, col=100, totvar=los_xviii, varname="Length of Stay (Title XVIII)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1500, col=200, totvar=los_xix, varname="Length of Stay (Title XIX)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1500, col=300, totvar=los_sknursing, varname="Length of Stay (Skill Nursing Facility)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1500, col=400, totvar=los_nursing, varname="Length of Stay (Nursing Facility)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1500, col=500, totvar=los_other, varname="Length of Stay (Other)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1500, col=600, totvar=los_total, varname="Length of Stay (Total)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1600, col=100, totvar=census_xviii, varname="Unduplicated Census Count (Title XVIII)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1600, col=200, totvar=census_xix, varname="Unduplicated Census Count (Title XIX)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1600, col=300, totvar=census_sknursing, varname="Unduplicated Census Count (Skill Nursing Facility)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1600, col=400, totvar=census_nursing, varname="Unduplicated Census Count (Nursing Facility)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1600, col=500, totvar=census_other, varname="Unduplicated Census Count (Other)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1600, col=600, totvar=census_total, varname="Unduplicated Census Count (Total)");
%wksheet(title=s1pt3, year=2009, num=3, wkst='S100000', line=1700, col=100, totvar=componentized, varname="If Hospice Componentized admin and service costs, Option 1 or 2?");
%wksheet(title=s1pt3, year=2009, num=2, wkst='S100000', line=1800, col=100, totvar=related_organizations, varname="Any Related Organization or Home Office Costs (Defined in CMS Pub. 15-I Chapter 10)");


%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1300, col=100, totvar=pts_hospice_xviii, varname="Number of Patients Receiving Hospice Care (Title XVIII)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1300, col=200, totvar=pts_hospice_xix, varname="Number of Patients Receiving Hospice Care (Title XIX)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1300, col=300, totvar=pts_hospice_sknursing, varname="Number of Patients Receiving Hospice Care (Skill Nursing Facility)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1300, col=400, totvar=pts_hospice_nursing, varname="Number of Patients Receiving Hospice Care (Nursing Facility)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1300, col=500, totvar=pts_hospice_other, varname="Number of Patients Receiving Hospice Care (Other)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1300, col=600, totvar=pts_hospice_total, varname="Number of Patients Receiving Hospice Care (Total)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1400, col=100, totvar=cont_care_xviii, varname="Total Number of Unduplicated Continuous Care Hours Billable to Medicare (Title XVIII)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1400, col=300, totvar=cont_care_sknursing, varname="Total Number of Unduplicated Continuous Care Hours Billable to Medicare (Skill Nursing Facility)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1500, col=100, totvar=los_xviii, varname="Length of Stay (Title XVIII)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1500, col=200, totvar=los_xix, varname="Length of Stay (Title XIX)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1500, col=300, totvar=los_sknursing, varname="Length of Stay (Skill Nursing Facility)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1500, col=400, totvar=los_nursing, varname="Length of Stay (Nursing Facility)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1500, col=500, totvar=los_other, varname="Length of Stay (Other)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1500, col=600, totvar=los_total, varname="Length of Stay (Total)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1600, col=100, totvar=census_xviii, varname="Unduplicated Census Count (Title XVIII)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1600, col=200, totvar=census_xix, varname="Unduplicated Census Count (Title XIX)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1600, col=300, totvar=census_sknursing, varname="Unduplicated Census Count (Skill Nursing Facility)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1600, col=400, totvar=census_nursing, varname="Unduplicated Census Count (Nursing Facility)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1600, col=500, totvar=census_other, varname="Unduplicated Census Count (Other)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1600, col=600, totvar=census_total, varname="Unduplicated Census Count (Total)");
%wksheet(title=s1pt3, year=2010, num=3, wkst='S100000', line=1700, col=100, totvar=componentized, varname="If Hospice Componentized admin and service costs, Option 1 or 2?");
%wksheet(title=s1pt3, year=2010, num=2, wkst='S100000', line=1800, col=100, totvar=related_organizations, varname="Any Related Organization or Home Office Costs (Defined in CMS Pub. 15-I Chapter 10)");


data s1pt3;
	set final;
run;
data final;
	set final_2009;
run;
proc sort data=final;
	 by RPT_REC_NUM;
run;
data final;
	merge final providernum1;
run;

%wksheet(title=s1pt4, year=2009, num=3, wkst='S100000', line=1900, col=100, totvar=drugcost, varname="Drug Costs");
%wksheet(title=s1pt4, year=2009, num=3, wkst='S100000', line=1900, col=200, totvar=equip, varname="Durable Medical Equipment/Oxygen Costs");
%wksheet(title=s1pt4, year=2009, num=3, wkst='S100000', line=1900, col=300, totvar=supply, varname="Medical Supply Costs");
%wksheet(title=s1pt4, year=2010, num=3, wkst='S100000', line=1900, col=100, totvar=drugcost, varname="Drug Costs");
%wksheet(title=s1pt4, year=2010, num=3, wkst='S100000', line=1900, col=200, totvar=equip, varname="Durable Medical Equipment/Oxygen Costs");
%wksheet(title=s1pt4, year=2010, num=3, wkst='S100000', line=1900, col=300, totvar=supply, varname="Medical Supply Costs");

data s1pt4;
	set final;
run;		
data final;
	set final_2009;
run;
proc sort data=final;
	 by RPT_REC_NUM;
run;
data final;
	merge final providernum1;
run;

%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=100, col=1000, totvar=bldg_equip, varname="Building and Fixtures");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=200, col=1000, totvar=move_equip, varname="Moveable Equipment");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=300, col=1000, totvar=plant, varname="Plant Operation and Maintenance");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=400, col=1000, totvar=transportation, varname="Transportation");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=500, col=1000, totvar=volunteer, varname="Volunteer Service Coordination");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=600, col=1000, totvar=Admin, varname="Administration and General");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=1000, col=1000, totvar=Gen_Inpatient, varname="Inpatient - General Care");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=1100, col=1000, totvar=Res_Inpatient, varname="Inpatient - Respite Care");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=1500, col=1000, totvar=physician, varname="Physician Services");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=1600, col=1000, totvar=nursing, varname="Nursing Care");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=1620, col=1000, totvar=nursing_cont, varname="Nursing Care -- Continuous Home Care");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=1700, col=1000, totvar=physical, varname="Physical Therapy");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=1800, col=1000, totvar=occupation, varname="Occupational Therapy");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=1900, col=1000, totvar=speech_lang, varname="Speech/Language Pathology");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=2000, col=1000, totvar=social, varname="Medical Social Services");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=2100, col=1000, totvar=spritual, varname="Spiritual Counseling");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=2200, col=1000, totvar=diet, varname="Dietary Counseling");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=2300, col=1000, totvar=other_coun, varname="Other Counseling");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=2400, col=1000, totvar=HHA, varname="Home Health Aide and Homemaker");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=2420, col=1000, totvar=HHA_cont, varname="Home Health Aide and Homemaker - Cont Home Care");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=2500, col=1000, totvar=other_visiting, varname="Other Visiting Expenses");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3000, col=1000, totvar=drugs, varname="Drugs, Biological and Infusion Therapy");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3030, col=1000, totvar=analgesics, varname="Analgesics");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3031, col=1000, totvar=Sedatives, varname="Sedatives/Hypnotics");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3032, col=1000, totvar=other_drugs, varname="Other Drugs");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3100, col=1000, totvar=durable, varname="Durable Medical Equipment/Oxygen");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3200, col=1000, totvar=patient_transport, varname="Patient Transportation");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3300, col=1000, totvar=imaging, varname="Imaging Services");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3400, col=1000, totvar=labs, varname="Labs and Diagnostics");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3500, col=1000, totvar=Medical, varname="medical");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3600, col=1000, totvar=outpatient, varname="Outpatient Services");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3700, col=1000, totvar=Radiation, varname="Radiation Therapy");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3800, col=1000, totvar=Chemotherapy, varname="Chemotherapy");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=3900, col=1000, totvar=other_service, varname="Other Service Costs");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=5000, col=1000, totvar=Bereavement, varname="Bereavement Program Costs");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=5100, col=1000, totvar=Volunteer_Program, varname="Volunteer Program Costs");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=5200, col=1000, totvar=Fundraising, varname="Fundraising Costs");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=5300, col=1000, totvar=other_program, varname="Other Program Costs");
%wksheet(title=a0, year=2009, num=3, wkst='A000000', line=10000, col=1000, totvar=total, varname="Total");

%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=100, col=1000, totvar=bldg_equip, varname="Building and Fixtures");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=200, col=1000, totvar=move_equip, varname="Moveable Equipment");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=300, col=1000, totvar=plant, varname="Plant Operation and Maintenance");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=400, col=1000, totvar=transportation, varname="Transportation");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=500, col=1000, totvar=volunteer, varname="Volunteer Service Coordination");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=600, col=1000, totvar=Admin, varname="Administration and General");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=1000, col=1000, totvar=Gen_Inpatient, varname="Inpatient - General Care");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=1100, col=1000, totvar=Res_Inpatient, varname="Inpatient - Respite Care");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=1500, col=1000, totvar=physician, varname="Physician Services");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=1600, col=1000, totvar=nursing, varname="Nursing Care");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=1620, col=1000, totvar=nursing_cont, varname="Nursing Care -- Continuous Home Care");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=1700, col=1000, totvar=physical, varname="Physical Therapy");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=1800, col=1000, totvar=occupation, varname="Occupational Therapy");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=1900, col=1000, totvar=speech_lang, varname="Speech/Language Pathology");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=2000, col=1000, totvar=social, varname="Medical Social Services");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=2100, col=1000, totvar=spritual, varname="Spiritual Counseling");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=2200, col=1000, totvar=diet, varname="Dietary Counseling");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=2300, col=1000, totvar=other_coun, varname="Other Counseling");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=2400, col=1000, totvar=HHA, varname="Home Health Aide and Homemaker");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=2420, col=1000, totvar=HHA_cont, varname="Home Health Aide and Homemaker - Cont Home Care");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=2500, col=1000, totvar=other_visiting, varname="Other Visiting Expenses");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3000, col=1000, totvar=drugs, varname="Drugs, Biological and Infusion Therapy");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3030, col=1000, totvar=analgesics, varname="Analgesics");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3031, col=1000, totvar=Sedatives, varname="Sedatives/Hypnotics");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3032, col=1000, totvar=other_drugs, varname="Other Drugs");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3100, col=1000, totvar=durable, varname="Durable Medical Equipment/Oxygen");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3200, col=1000, totvar=patient_transport, varname="Patient Transportation");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3300, col=1000, totvar=imaging, varname="Imaging Services");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3400, col=1000, totvar=labs, varname="Labs and Diagnostics");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3500, col=1000, totvar=Medical, varname="medical");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3600, col=1000, totvar=outpatient, varname="Outpatient Services");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3700, col=1000, totvar=Radiation, varname="Radiation Therapy");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3800, col=1000, totvar=Chemotherapy, varname="Chemotherapy");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=3900, col=1000, totvar=other_service, varname="Other Service Costs");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=5000, col=1000, totvar=Bereavement, varname="Bereavement Program Costs");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=5100, col=1000, totvar=Volunteer_Program, varname="Volunteer Program Costs");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=5200, col=1000, totvar=Fundraising, varname="Fundraising Costs");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=5300, col=1000, totvar=other_program, varname="Other Program Costs");
%wksheet(title=a0, year=2010, num=3, wkst='A000000', line=10000, col=1000, totvar=total, varname="Total");

data a0;
	set final;
run;
data final;
	set final_2009;
run;
proc sort data=final;
	 by RPT_REC_NUM;
run;
data final;
	merge final providernum1;
run;

%wksheet(title=d, year=2009, num=3, wkst='D000000', line=100, col=400, totvar=total_cost, varname="Total Cost");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=200, col=400, totvar=total_undup, varname="Total Unduplicated Days");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=300, col=400, totvar=avg_cost, varname="Average Costs per Diem");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=400, col=100, totvar=undup_medicare, varname="Unduplicated Medicare Days");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=500, col=100, totvar=avg_medicare, varname="Average Medicare Costs");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=600, col=200, totvar=undup_medicaid, varname="Unduplicated Medicaid Days");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=700, col=200, totvar=avg_medicaid, varname="Average Medicaid Costs");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=800, col=100, totvar=undup_snf, varname="Unduplicated SNF Days");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=900, col=100, totvar=avg_snf, varname="Average SNF costs");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=1000, col=200, totvar=undup_nf, varname="Unduplicated NF Days");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=1100, col=200, totvar=avg_nf, varname="Average NF costs");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=1200, col=300, totvar=undup_other, varname="Other Unduplicated Days");
%wksheet(title=d, year=2009, num=3, wkst='D000000', line=1300, col=300, totvar=avg_other, varname="Average cost for other days");

%wksheet(title=d, year=2010, num=3, wkst='D000000', line=100, col=400, totvar=total_cost, varname="Total Cost");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=200, col=400, totvar=total_undup, varname="Total Unduplicated Days");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=300, col=400, totvar=avg_cost, varname="Average Costs per Diem");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=400, col=100, totvar=undup_medicare, varname="Unduplicated Medicare Days");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=500, col=100, totvar=avg_medicare, varname="Average Medicare Costs");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=600, col=200, totvar=undup_medicaid, varname="Unduplicated Medicaid Days");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=700, col=200, totvar=avg_medicaid, varname="Average Medicaid Costs");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=800, col=100, totvar=undup_snf, varname="Unduplicated SNF Days");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=900, col=100, totvar=avg_snf, varname="Average SNF costs");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=1000, col=200, totvar=undup_nf, varname="Unduplicated NF Days");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=1100, col=200, totvar=avg_nf, varname="Average NF costs");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=1200, col=300, totvar=undup_other, varname="Other Unduplicated Days");
%wksheet(title=d, year=2010, num=3, wkst='D000000', line=1300, col=300, totvar=avg_other, varname="Average cost for other days");

data d;
	set final;
run;
data final;
	set final_2009;
run;
proc sort data=final;
	 by RPT_REC_NUM;
run;
data final;
	merge final providernum1;
run;

%wksheet(title=g2, year=2009, num=3, wkst='G200001', line=100, col=100, totvar=sk_nurse_facility, varname="Skilled Nursing Facility Based");
%wksheet(title=g2, year=2009, num=3, wkst='G200001', line=200, col=100, totvar=nurse_facility, varname="Nursing Facility Based");
%wksheet(title=g2, year=2009, num=3, wkst='G200001', line=300, col=100, totvar=home_care, varname="Home Care");
%wksheet(title=g2, year=2009, num=3, wkst='G200001', line=400, col=100, totvar=Other, varname="Other");
%wksheet(title=g2, year=2009, num=3, wkst='G200001', line=500, col=100, totvar=medicaid, varname="State Medicaid Room & Board");
%wksheet(title=g2, year=2009, num=3, wkst='G200001', line=600, col=100, totvar=Total_gen_inpatient, varname="Total General Inpatient Revenues");
%wksheet(title=g2, year=2009, num=3, wkst='G200002', line=1500, col=200, totvar=total_op, varname="Total Operating Expenses");
%wksheet(title=g2, year=2009, num=3, wkst='G200002', line=1600, col=200, totvar=undup_snf, varname="Net Income for the Period");


%wksheet(title=g2, year=2010, num=3, wkst='G200001', line=100, col=100, totvar=sk_nurse_facility, varname="Skilled Nursing Facility Based");
%wksheet(title=g2, year=2010, num=3, wkst='G200001', line=200, col=100, totvar=nurse_facility, varname="Nursing Facility Based");
%wksheet(title=g2, year=2010, num=3, wkst='G200001', line=300, col=100, totvar=home_care, varname="Home Care");
%wksheet(title=g2, year=2010, num=3, wkst='G200001', line=400, col=100, totvar=Other, varname="Other");
%wksheet(title=g2, year=2010, num=3, wkst='G200001', line=500, col=100, totvar=medicaid, varname="State Medicaid Room & Board");
%wksheet(title=g2, year=2010, num=3, wkst='G200001', line=600, col=100, totvar=Total_gen_inpatient, varname="Total General Inpatient Revenues");
%wksheet(title=g2, year=2010, num=3, wkst='G200002', line=1500, col=200, totvar=total_op, varname="Total Operating Expenses");
%wksheet(title=g2, year=2010, num=3, wkst='G200002', line=1600, col=200, totvar=undup_snf, varname="Net Income for the Period");

data g2;
	set final;
run;
proc sort data=s1pt1 out = s1pt1_1;
	by pid year;
run;
proc sort data=s1pt2 out = s1pt2_1;
	by pid year;
run;
proc sort data=s1pt2 out = s1pt2_1;
	by pid year;
run;
proc sort data=s1pt3 out = s1pt3_1;
	by pid year;
run;
proc sort data=s1pt4 out = s1pt4_1;
	by pid year;
run;
proc sort data=a0 out=a0_1;
	by pid year;
run;
proc sort data=d out = d_1;
	by pid year;
run;
proc sort data=g2 out = g2_1;
	by pid  year;
run;

data costs.a0;
set a0_1;
run;
data costs.d;
set d_1;
run;
data costs.g2;
set g2_1;
run;
data costs.s1pt1;
set s1pt1_1;
run;
data costs.s1pt2;
set s1pt2_1;
run;
data costs.s1pt3;
set s1pt3_1;
run;
data costs.s1pt4;
set s1pt4_1;
run;

proc export data=s1pt1_1 outfile="\\home\users$\leee20\Documents\Downloads\Melissa\Hospice_Cost_Data\data\Hospice Identification Data Part I (s1pt1).xls" label dbms = excelcs replace; run;
proc export data=s1pt2_1 outfile="\\home\users$\leee20\Documents\Downloads\Melissa\Hospice_Cost_Data\data\Hospice Identification Data Part II (s1pt2).xls" label dbms = excelcs replace; run;
proc export data=s1pt3_1 outfile="\\home\users$\leee20\Documents\Downloads\Melissa\Hospice_Cost_Data\data\Hospice Identification Data Part III (s1pt3).csv" label dbms = csv replace; run;
proc export data=s1pt4_1 outfile="\\home\users$\leee20\Documents\Downloads\Melissa\Hospice_Cost_Data\data\s1pt4.xls" label dbms = excelcs replace; run;
proc export data=a0 outfile="\\home\users$\leee20\Documents\Downloads\Melissa\Hospice_Cost_Data\data\Reclassification and Adjustment of Trial Balance Expenses.xls" label dbms = excelcs replace; run;
proc export data=d outfile="\\home\users$\leee20\Documents\Downloads\Melissa\Hospice_Cost_Data\data\Calculation of Per Diem Cost.xls" label dbms = excelcs replace; run;
proc export data=g2 outfile="\\home\users$\leee20\Documents\Downloads\Melissa\Hospice_Cost_Data\data\Statement of Patient Revenues and Net Income (G2).xls" label dbms = excelcs replace; run;

data final;
	set final;
		drop control;
run;
data test_alpha;
	set Hospicecosts20102;
		if WKSHT_CD = 'S100000' and LINE_NUM = 1900 and CLMN_NUM = 200;
run;
data test_num;
	set Hospicecosts20103;
		if WKSHT_CD = 'S100000' and LINE_NUM = 1900 and CLMN_NUM = 200;
run;
data test;
	set Hospicecosts20093;
		if RPT_REC_NUM = 23385;
run;
data test_1;
	set final;
		if RPT_REC_NUM = 23385;
run;

/***************************** MERGING WITH THE MAIN HOSPICE DATA SET*********************************/

proc sort data=costs.a0 out= a0;
by pid year;
run;
proc sort data=costs.d out= d;
by pid year;
run;
proc sort data=costs.g2 out=g2;
by pid year;
run;
proc sort data=costs.s1pt1 out=s1pt1;
by pid year;
run;
proc sort data=costs.s1pt2 out=s1pt2;
by pid year;
run;
proc sort data=costs.s1pt3 out=s1pt3;
by pid year;
run;
proc sort data=costs.s1pt4 out=s1pt4;
by pid year;
run;
proc sort data=a0 out= a0_1 nodupkey;
by pid;
run;
proc sort data=d out = d_1 nodupkey;
by pid;
run;
proc sort data=g2 out=g2_1 nodupkey;
by pid;
run;
proc sort data=s1pt1 out=s1pt1_1 nodupkey;
by pid;
run;
proc sort data=s1pt2 out=s1pt2_1 nodupkey;
by pid;
run;
proc sort data=s1pt3 out=s1pt3_1 nodupkey;
by pid;
run;
proc sort data=s1pt4 out=s1pt4_1 nodupkey;
by pid;
run;

proc sql;
create table costs 
as select *
from a0_1 a
left join d_1 b
on a.pid = b.pid
left join g2_1 c
on a.pid = c.pid
left join s1pt1_1 d
on a.pid = d.pid
left join s1pt2_1 e
on a.pid = e.pid
left join s1pt3_1 f
on a.pid = f.pid
left join s1pt4_1 g
on a.pid = g.pid
;
quit;
data ccw.costs;
set costs;
run;

proc sql;
create table ccw.Final_hosp_county_cost
as select *
from ccw.Final_hosp_county a
left join ccw.costs b
on a.pos1 = b.pid;
quit;

proc freq data=ccw.final_hosp_county_cost;
table year;
run;
