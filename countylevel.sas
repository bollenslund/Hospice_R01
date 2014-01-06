libname working 'J:\Geriatrics\Geri\Hospice Project\Hospice\Reference';

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

PROC IMPORT OUT= WORK.HospiceCosts
            DATAFILE= "N:\Documents\Downloads\Melissa\Hospice_Cost_Data\data.xls" 
            DBMS=excelcs REPLACE;
RUN;
