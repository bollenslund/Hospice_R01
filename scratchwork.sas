libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

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
title "Frequency of people with 2-4 day difference between first and second hospice visit";
proc freq data=hospice1;
format diff label.;
table diff;
run;
ods rtf close;

