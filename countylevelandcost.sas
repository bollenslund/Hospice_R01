libname working 'J:\Geriatrics\Geri\Hospice Project\Hospice\Reference';
libname costs 'N:\Documents\Downloads\Melissa\Hospice_Cost_Data\data';

data ahrf;
set working.ahrf12;
run;

ods rtf body = "\\home\users$\leee20\Documents\Downloads\Melissa\ahrf.rtf";
title "AHRF Contents Table";
proc contents data=ahrf varnum;
run;
ods rtf close;

data ahrf1;
set ahrf (keep = f00002 f00005 f00008 f04437 f00011 f00012 f04439 f04440 f00023 f0002003 f0892110 f0892109 f0892108 f0892107 f0892106 f0892105 f0892100 f1404910 f1404909 f1404908 f1404907
f1404906 f1404905 f0978110 f0978109 f0978108 f0978107 f0978106 f0978105  f0978100);
run;

data ccw.ahrf;
set ahrf1;
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

