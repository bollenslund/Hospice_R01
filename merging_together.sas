data final_hs;
set ccw.final_hs;
run;

data final_mb;
set ccw.mb_final;
run;

data final_inpat;
set ccw.ip_snf;
run;

data final_outpat;
set ccw.outpat_fin;
run;

data final_dmehhacarr;
set ccw.dmehhacarr;
run;
