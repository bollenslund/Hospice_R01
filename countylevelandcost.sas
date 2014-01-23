libname working 'J:\Geriatrics\Geri\Hospice Project\Hospice\Reference';
libname costs 'N:\Documents\Downloads\Melissa\Hospice_Cost_Data\data';

data ahrf_raw;
set working.ahrf12;
run;

ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\ahrf.rtf";
title "AHRF Contents Table";
proc contents data=ahrf varnum;
run;
ods rtf close;

data ahrf_raw1;
set ahrf_raw (keep = f00002 f00008 f13156 f04437 f04439 f04440 f00023 f0002003 f0892109 f1404909 f0978109);
rename f00002 = fips_stat_county;
rename f00008 = state;
rename f04437 = county_state;
rename f04439 = cens_reg_cd;
rename f04440 = cens_div_cd;
rename f00023 = fed_reg_cd;
rename f0002003 = urban_cd;
rename f0892109 = beds_2009;
rename f1404909 = nursing_beds_2009;
rename f0978109 = per_cap_inc_2009;
rename f13156 = SSA_stat_County;
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

