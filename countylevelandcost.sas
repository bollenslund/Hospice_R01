libname working 'J:\Geriatrics\Geri\Hospice Project\Hospice\Reference';
libname costs 'N:\Documents\Downloads\Melissa\Hospice_Cost_Data\data';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

data ahrf_raw;
set working.ahrf12;
run;

ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\ahrf.rtf";
title "AHRF Contents Table";
proc contents data=ahrf varnum;
run;
ods rtf close;

proc freq data = ahrf_raw;
table f0002003;
run;
proc freq data = ccw.final1;
table urban_cd;
run;

data ahrf_raw1;
set ahrf_raw (keep = f13156 f04437 f0002003 f0892109 f1404909 f0978109 f0453010);
rename f04437 = county_state;
rename f0892109 = beds_2009;
rename f1404909 = nursing_beds_2009;
rename f0978109 = per_cap_inc_2009;
rename f13156 = SSA_stat_County;
rename f0453010 = Census_Pop_2010;
if f0002003 = 1|f0002003 = 2|f0002003 = 3 then urban_cd = 1;
if f0002003 = 4|f0002003 = 5|f0002003 = 6|f0002003 = 7|f0002003 = 8|f0002003 = 9 then urban_cd = 0;
label urban_cd = "Metro/non-Metro based on Rural/Urban Continuum Code 2003";
drop f0002003;
run;

data ccw.ahrf;
set ahrf_raw1;
run;

proc contents data=ccw.final1 varnum;
run;

/******************** COST INFORMATION ***********************/

data s1pt1;
set costs.s1pt1;
run;
data s1pt2;
set costs.s1pt2;
run;
data s1pt3;
set costs.s1pt3;
run;
data s1pt4;
set costs.s1pt4;
run;
data a0;
set costs.a0; 
run;
data d;
set costs.d;
run;
data g2;
set costs.g2;
run;

