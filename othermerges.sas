libname costs 'J:\Geriatrics\Geri\Hospice Project\Hospice\Costs\data';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';
libname ref 'J:\Geriatrics\Geri\Hospice Project\Hospice\Reference';

data pid_county;
set costs.s1pt1 (keep = RPT_REC_NUM year Hospice_Address Hospice_city Hospice_Name Hospice_state Hospice_zip Hospice_County pid);
zipcode = input(substr(Hospice_zip, 1, 5), 5.);
drop Hospice_zip;
run;
/*
proc sort data=pid_county out=ziptest;
by zipcode;
run;
*/
data pid_county1;
set pid_county;
if Hospice_Address = '5440 HIGHWAY 15' and Hospice_city = 'WINNSBORO' and Hospice_state = 'LA' then zipcode = 71295;
if Hospice_Address = 'URB. VILLA DEL REY 4TA SECC.' and Hospice_city = '4G-15 CALLE 2' and Hospice_state = 'PR' then do; zipcode = 726;  Hospice_County = 'CAGUAS'; end;
if Hospice_Address = '421 S MAIN ST' and Hospice_city = 'BIG SPRING' and Hospice_state = 'TX' then zipcode = 79720 ;
drop Hospice_Address Hospice_city;
run;
/*
proc sort data=pid_county1 out=ziptest;
by zipcode;
run;
*/
proc sort data=pid_county out=pid_county1 nodupkey;
by Hospice_state Hospice_county;
run;

data pid_county2;
set pid_county1;
county_state = catx(', ', Hospice_county, Hospice_state);
run;

proc sort data=pid_county2;
by county_state;
run;
data zip;
set zip1; 
statenum = .;
if zipcode = 1;
run;
%macro zip;
%do j = 1 %to 10;
data zip&j;
infile "J:\Geriatrics\Geri\Hospice Project\Hospice\Reference\zipcty&j..txt";
input zipcode 1-5 updatekey 6-15 zipaddlowsec 16-17 zipaddlowseg 18-19 zipaddhighsec 20-21 zipaddhighseg 22-23 state $ 24-25 countynum 26-28 countyname $ 29-53;
run;

data zip&j;
set zip&j;
if zipcode = . then delete;
if state = 'AK' then statenum =	02; if state = 'AL'	then statenum =	01; if state = 'AR'	then statenum =	05; if state = 'AS' then statenum = 60;
if state = 'AZ' then statenum = 04; if state = 'CA' then statenum = 06; if state = 'CO' then statenum = 08; if state = 'CT' then statenum = 09;
if state = 'DC' then statenum = 11; if state = 'DE' then statenum = 10; if state = 'FL' then statenum = 12; if state = 'GA' then statenum = 13;
if state = 'GU' then statenum = 66; if state = 'HI' then statenum = 15; if state = 'IA' then statenum = 19; if state = 'ID' then statenum = 16;
if state = 'IL' then statenum = 17; if state = 'IN' then statenum = 18; if state = 'KS' then statenum = 20; if state = 'KY' then statenum = 21;
if state = 'LA' then statenum = 22; if state = 'MA' then statenum = 25; if state = 'MD' then statenum = 24; if state = 'ME' then statenum = 23;
if state = 'MI' then statenum = 26; if state = 'MN' then statenum = 27; if state = 'MO' then statenum = 29; if state = 'MS' then statenum = 28;
if state = 'MT' then statenum = 30; if state = 'NC' then statenum = 37; if state = 'ND' then statenum = 38; if state = 'NE' then statenum = 31;
if state = 'NH' then statenum = 33; if state = 'NJ' then statenum = 34; if state = 'NM' then statenum = 35; if state = 'NV' then statenum = 32;
if state = 'NY' then statenum = 36; if state = 'OH' then statenum = 39; if state = 'OK' then statenum = 40; if state = 'OR' then statenum = 41;
if state = 'PA' then statenum = 42; if state = 'PR' then statenum = 72; if state = 'RI' then statenum = 44; if state = 'SC' then statenum = 45;
if state = 'SD' then statenum = 46; if state = 'TN' then statenum = 47; if state = 'TX' then statenum = 48; if state = 'UT' then statenum = 49;
if state = 'VA' then statenum = 51; if state = 'VI' then statenum = 78; if state = 'VT' then statenum = 50; if state = 'WA' then statenum = 53;
if state = 'WI' then statenum = 55; if state = 'WV' then statenum = 54; if state = 'WY' then statenum = 56;
run;
proc append base=zip data=zip&j;
run;
%end;
%mend;
%zip;

/*REBECCA - I MADE SOME ASSUMPTIONS HERE. COME TO ME IF YOU SEE THIS (also if you know things about +4 zipcode numbers)*/
proc sort data=zip out=ziplist nodupkey;
by zipcode countynum countyname statenum;
run;

proc sort data=ziplist out=ziplist1;
by zipcode zipaddlowsec;
run;
data test;
set zip;
if zipcode = 77117;
run;
proc sort data=ziplist2 out=ziplist3 nodupkey;
by zipcode;
run;
data ziplist4;
set ziplist3;
if statenum = . then delete;
drop zipaddlowsec zipaddlowseg zipaddhighsec zipaddhighseg updatekey;
run;

proc sql;
create table pid_county3
as select *
from pid_county2 a
left join ziplist4 b
on a.zipcode = b.zipcode;
quit;
proc freq data=pid_county3;
table statenum;
run;

data missing_county;
set pid_county3;
if countynum = .;
run;

data ahrf;
set ccw.ahrf;
statenum = input(f00011,2.);
countynum = input(f00012,3.);
run;

proc sql;
create table pid_county4
as select *
from pid_county3 a
left join ahrf b
on a.countynum = b.countynum
and a.statenum =  b.statenum;
quit;

proc sql;
create table hospice_add
as select *
from ccw.final1 a
left join pid_county4 b
on a.provider = b.pid;
;
quit;
proc freq data=hospice_add;
table RPT_REC_NUM;
run;
/*only 49% of the people in the hospice files match the people from the ahrf/cost files*/

data test;
set Hospicecosts20101;
if PRVDR_NUM = 101539 or PRVDR_NUM = 451705;
run;
/*a value exists here. May be something wrong with the original coding*/
data test;
set Hospicecosts20103;
if RPT_REC_NUM = 25548;
run;
