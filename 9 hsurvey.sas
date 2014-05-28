/*This file merges the hospice survey with the cleaned claims dataset*/

libname melissa 'J:\Geriatrics\Geri\Hospice Project';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

proc contents data=melissa.hsurvey_r01 out=hsurvey;
run;

proc export data=hsurvey outfile = '\\home\users$\leee20\Documents\Downloads\Melissa\hsurvey_varlist.xls' dbms = excelcs replace;
run;

/*drop unneeded vairables from the survey*/
data hsurvey_r01;
set melissa.hsurvey_r01;
drop Accred_08
Acttype_08
Acutecr_08
Address_08
BFI
BIG50
BIG100
BPI
CBSAstatus
CB_city
CB_rural
CB_suburb
CHAIN
Customtool
D_FPCH
D_FPSA
DateCompleted
Edmonton
Eligcode_08
Email
FIPCNTY
FIPCNTY_08
FIPSTATE
FIPSTATE_08
FMSdate_08
FP
FPBIG50
FPBIG100
FPBIG50_2
FPCH
FPCH2
FPCH2_VNOT
FPNC
FPNH50
FPSmall50
FPSmall100
FPSmall50_2
Fiscyr_08
HRR
HRRname
LOG_total_patient
LSCcomply_08
LastPage
MAtl
MDAnderson
McGillPQ
Memorial
MemorialPA
MemorialSloane
Missoula
NEW10
NEWFP
NEWNP
NH20
NH50
NH66
NPBIG50
NPBIG100
NPNC
NPNH50
NPsmall50_2
OLDFP
OrderNum
Owncount_08
Owndate_08
PAINAD
PHONE
POCcomply_08
PROV0010
PROV0015
PROV0075
PROV0085
PROV0095
PROV0100
PROV0220
PROV0240
PROV0300
PROV0455
PROV0475
PROV0485
PROV0500
PROV0605
PROV0655
PROV0910
PROV0915
PROV0955
PROV0975
PROV1075
PROV1080
PROV1110
PROV1145
PROV1225
PROV1480
PROV1485
PROV1490
PROV1495
PROV1500
PROV1505
PROV1510
PROV1565
PROV1605
PROV1615
PROV1620
PROV1680
PROV1720
PROV1725
PROV1755
PROV2045
PROV2115
PROV2165
PROV2170
PROV2220
PROV2225
PROV2250
PROV2270
PROV2340
PROV2370
PROV2385
PROV2480
PROV2505
PROV2695
PROV2700
PROV2710
PROV2715
PROV2720
PROV2740
PROV2850
PROV2860
PROV2880
PROV2885
PROV2890
PROV2905
PROV3225
PROV3230
PROV4500
PROV4770
Previntmed_08
Prevowndate_08
Progcomply_08
Provcat16_08
Rcrdtype_08
Relprovnum_08
SDS
SMALL20
SSAMSACD
SSAMSACD_08
SSAMSASZ
SSAMSASZ_08
STATE
Skelrec_08
Telnum_08
Termcode_08
Termdate_08
Title
VIANYHH
VIANYHOSPITAL
VIANYNH
VIANYOTH
Vendnum_08
WisconsinBP
black1
black_empl
blackmissing
cnties_serv
f00011
f00012
f0453710
f1434505
fpchain2
hrrcity
hrrmerge
hrrnum
hrrstate
hsacity
hsanum
hsastate
inc_cat
inc_low
inc_med
indian_empl
multrac_empl
n_asian_empl
n_black_empl
n_hisp_empl
n_indian_empl
n_minempl
n_multrac_empl
n_white_empl
nn_asian_empl
nn_black_empl
nn_hisp_empl
nn_indian_empl
nn_multrac_empl
nn_white_empl
pc_board_bus
pc_board_clin
pc_board_fam
pc_enrl_deth
pct_asian_empl
pct_asst_livg
pct_black_empl
pct_hisp_empl
pct_indian_empl
pct_multrac_empl
pct_white_empl
q10comment
q5comment
white_empl
younghos
yrall
yrquart1
yrquart2
yrquart3
yrquart4
zipcode07
zipcode_08
zipcodemerge
;
run;

proc contents data=melissa.hsurvey_r01 varnum;
run;
proc freq data=hsurvey_r01;
table ssastate_08 ssacoun_08 Provnum_08;
run;
/*saves the dataset to the working directory*/
data ccw.hsurvey;
set hsurvey_r01;
run;
proc freq data=ccw.hsurvey;
table ssastate_08 ssacoun_08;
run;

proc contents data=ccw.hsurvey; run;

proc freq data=ccw.hsurvey;
table open_access chemo tpn trnsfusion intracath pall_radiat no_fam_cg tube_feed /missprint;
run;
/*create combined state, county ssa code in the survey dataset
for merging in the county level data from the AHRF*/
proc sql;
create table test as
select cats(SSAstate_08, SSAcoun_08) as SSA_Hospice 
from ccw.hsurvey;
quit;

data hsurvey_r01_1;
set hsurvey_r01;
SSA_Hospice_Code = cat(SSAstate_08, SSAcoun_08);
run;
proc freq data=hsurvey_r01_1;
table SSA_hospice_code Provnum_08;
run;

/*merge in ahrf county level variables*/
proc sql;
create table hsurvey_r01_2
as select a.*, b.county_state, b.beds_2009, b.nursing_beds_2009, b.per_cap_inc_2009, b.Census_Pop_2010, b.urban_cd
from hsurvey_r01_1 a
left join ccw.ahrf b
on b.SSA_stat_County = a.SSA_Hospice_Code;
quit;
proc freq data=hsurvey_r01_2;
table beds_2009 /missprint;
run;

proc sort data=hsurvey_r01_2;
by POS1;
run;

data ccw.hsurvey_r01_1;
set hsurvey_r01_2;
run;
ods rtf body = '\\home\users$\leee20\Documents\Downloads\Melissa\hsurvey.rtf';
proc contents data=ccw.hsurvey_r01_1 varnum;
run;
ods rtf close;
proc sql;
create table ccw.Final_hosp_county
as select *
from ccw.Final_hs_mb_mp_op_dhc_dod_cc_p a
left join ccw.hsurvey_r01_1 b
on a.provider_id = b.pos1;
quit;

proc contents data=ccw.Final_hosp_county; run;

