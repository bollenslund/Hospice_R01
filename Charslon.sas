/*Create Charlson score based on diagnoses from 12 months 
before beneficiaries first hospice enrollment

Starts with list of diagnoses across all claims ccw.dx_0_12m
created in the chronic_conditions.sas code
*/

libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';
data dx_1;
set ccw.dx_0_12m;
run;

/*first  transpose  dataset so one row per observation with all dx codes
listed as separate columns*/
proc transpose data=dx_1 prefix=dx out=dx_2;
by bene_id;
var diag;
run;

/*max 270 dx per beneficiary*/
proc contents data=dx_2;
run;

/***************************************************/
/************   Charlson Macro         *************/
/***************************************************/

/*
Note: The MCHP SAS macro code is based on information in Quan's "ICD-9-CM Enhanced Charlson Diagnosis-Type SAS code" program, but modified to be more generalized for use with other data sources and to run more efficiently.
http://mchp-appserv.cpe.umanitoba.ca/concept/_CharlsonICD9CM.sas.txt


we don't use dx type since we usualy don't have dx type data,
 Diagnosis are excluded if the diagnosis type (DXTYPE##) = 'C' (a condition arising after
    the beginning of hospital observation or treatment).

*/

/*
/*  This is the Charlson Comorbidity Index macro code using ICD-9-CM.

    This program reads through the diagnosis codes of patient abstract records in a hospital
    file and identifies whether the record belongs to one (or more) of 17 different Charlson
    Comorbidity Index (CCI) groups.  The groups are identified by using the Enhanced ICD-9-CM
    diagnosis codes listed in Quan et al., "Coding Algorithms for Defining Comorbidities
    in ICD-9-CM and ICD-10 Administrative Data", Medical Care:43(11), Nov. 2005 p1130-1139.

    The original SAS code for this program was developed by Hude Quan's group at the U of C
    in Calgary, and modified to work with MCHP data.  This code has not been validated by MCHP.

    Diagnosis codes are assigned using the "IN:" statement at the 3, 4, or 5th digit level.
    Diagnosis are excluded if the diagnosis type (DXTYPE##) = 'C' (a condition arising after
    the beginning of hospital observation or treatment).

    Date:  May 12, 2006, November 28, 2006
    Authors: Ken Turner & Charles Burchill
 
*/

%macro _CharlsonICD9CM (data    =dx_2,          /* input data set */
                        out     =charlson_1,          /* output data set */
                        dx      =dx1-dx270, /* range of diagnosis variables (dx01-dx16) */
                        dxtype  =dxtype01-dxtype16,/* range of diagnosis type variables */
                                                  /* (dxtype01-dxtype16) */
                        type    = off, /** on/off turn on or off use of dxtype ***/
                        debug   = off) ;

        %put Charlson Comorbidity Index Macro - ICD9CM Codes ;
        %put Manitoba Centre for Health Policy, Based on Code from Hude Quan University of Calgary ;
        %put Quan et al., Coding Algorithms for Defining Comorbidities ;
        %put     in ICD-9-CM and ICD-10 Administrative Data, Medical Care:43(11), Nov. 2005 p1130-1139 ;
        %put Version 1.0e February 23, 2007 ;

        %let debug = %lowcase(&debug) ;
        %let type = %lowcase(&type) ;

        %* put default options into &opts variable ;
  %let opts=%sysfunc(getoption(mprint,keyword))
          %sysfunc(getoption(notes,keyword)) ;
  %if &debug=1 | &debug=debug %then %do ;
                options mprint notes ;
                %end ;
        %else %do ;
                options nomprint nonotes ;
                %end ;

        %* Check if previous data step, or procdure had an error and
         stop running the rates macro
        This assumes that the previous step is used in the macro.;
 %if %eval(&SYSERR>0) %then %goto out1 ;

  %* Check if input data exists ;
  %if &data= %str() %then %goto out2 ;

  %* if the output data set is not defined then define it as the input ;
  %if &out=  %then %let out=&data ;

  %if %index(&data,.) %then %do;
     %let libname=%scan(&data,1);
         %let data=%scan(&data,2);
         %end;
 %else %do ;
         %let libname=work ;
         %let data=&data ;
         %end ;

 %if %sysfunc(exist(&libname..&data)) ^= 1 %then %goto out3 ;

        data &out;
                set &libname..&data ;

   /*  set up array for individual CCI group counters. */
   array CC_GRP (17) CC_GRP_1 - CC_GRP_17;

   /*  set up array for each diagnosis code within a record. */
   array DX (*) &dx;

   /*  set up array for each diagnosis type code within a record. */
   %if &type=on %then array DXTYP (*) &dxtype ; ;

   /*  initialize all CCI group counters to zero. */
   do i = 1 to 17;
      CC_GRP(i) = 0;
   end;

   /*  check each set of diagnosis codes for each CCI group. */

    do i = 1 to dim(dx) UNTIL (DX{i}=' ');     /* for each set of diagnoses codes */



 

         /* Myocardial Infarction */
          if   substr(trim(left(DX(i))),1,3) IN: ('410','412') then CC_GRP_1 = 1;
          LABEL CC_GRP_1 = 'Myocardial Infarction';

         /* Congestive Heart Failure */
          if  DX(i) IN: ('39891','40201','40211','40291','40401','40403','40411','40413','40491','40493',
                         '4254','4255','4257','4258','4259','428') or substr(trim(left(DX(i))),1,3) IN: ('428')  or substr(trim(left(DX(i))),1,4) IN: ('4254','4255','4256','4257','4258','4259') then CC_GRP_2 = 1;
          LABEL CC_GRP_2 = 'Congestive Heart Failure';

         /* Periphral Vascular Disease */
          if  DX(i) IN: ('0930','4373','440','441','4431','4432','4438','4439','4471','5571','5579','V434') or substr(trim(left(DX(i))),1,3) IN: ('440','441')
or 4431<=substr(trim(left(DX(i))),1,4)+0<=4439
                          then CC_GRP_3 = 1;
          LABEL CC_GRP_3 = 'Periphral Vascular Disease';

         /* Cerebrovascular Disease */
          if DX(i) IN: ('36234','430','431','432','433','434','435','436','437','438') or 430<=substr(trim(left(DX(i))),1,3)+0<=438
 then CC_GRP_4 = 1;
          LABEL CC_GRP_4 = 'Cerebrovascular Disease';

         /* Dementia */
          if DX(i) IN: ('290','2941','3312') or substr(trim(left(DX(i))),1,3) IN: ('290') then CC_GRP_5 = 1;
          LABEL CC_GRP_5 = 'Dementia';

         /* Chronic Pulmonary Disease */
          if  DX(i) IN: ('4168','4169','490','491','492','493','494','495','496','500','501','502','503',
                          '504','505','5064','5081','5088') or 490<=substr(trim(left(DX(i))),1,3)+0<=505 then CC_GRP_6 = 1;
          LABEL CC_GRP_6 = 'Chronic Pulmonary Disease';

         /* Connective Tissue Disease-Rheumatic Disease */
          if  DX(i) IN: ('4465','7100','7101','7102','7103','7104','7140','7141','7142','7148','725') or substr(trim(left(DX(i))),1,3) IN: ('725') or 7140<=substr(trim(left(DX(i))),1,4)+0<=7142
                         then CC_GRP_7 = 1;
          LABEL CC_GRP_7 = 'Connective Tissue Disease-Rheumatic Disease';

         /* Peptic Ulcer Disease */
          if   DX(i) IN: ('531','532','533','534')  or 531<=substr(trim(left(DX(i))),1,3)+0<=534 then CC_GRP_8 = 1;
          LABEL CC_GRP_8 = 'Peptic Ulcer Disease';

         /* Mild Liver Disease */
          if  DX(i) IN: ('07022','07023','07032','07033','07044','07054','0706','0709','570','571','5733',
                        '5734','5738','5739','V427') or substr(trim(left(DX(i))),1,3) IN: ('571','570') then CC_GRP_9 = 1;
          LABEL CC_GRP_9 = 'Mild Liver Disease';

         /* Diabetes without complications */
          if  DX(i) IN: ('2500','2501','2502','2503','2508','2509') or 2500<=substr(trim(left(DX(i))),1,4)+0<=2503 then CC_GRP_10 = 1;
          LABEL CC_GRP_10 = 'Diabetes without complications';

         /* Diabetes with complications */
          if   DX(i) IN: ('2504','2505','2506','2507')  or 2504<=substr(trim(left(DX(i))),1,4)+0<=2507  then CC_GRP_11 = 1;
          LABEL CC_GRP_11 = 'Diabetes with complications';

         /* Paraplegia and Hemiplegia */
          if  DX(i) IN: ('3341','342','343','3440','3441','3442','3443','3444','3445','3446','3449') or substr(trim(left(DX(i))),1,3) IN: ('343','342')   or 3440<=substr(trim(left(DX(i))),1,4)+0<=3446
                          then CC_GRP_12 = 1;
          LABEL CC_GRP_12 = 'Paraplegia and Hemiplegia';

         /* Renal Disease */
          if  DX(i) IN: ('40301','40311','40391','40402','40403','40412','40413','40492','40493','582',
                         '5830','5831','5832','5834','5836','5837','585','586','5880','V420','V451','V56')
 or substr(trim(left(DX(i))),1,3) IN: ('582','585','586','V56')   or 5830<=substr(trim(left(DX(i))),1,4)+0<=5837
                         then CC_GRP_13 = 1;
          LABEL CC_GRP_13 = 'Renal Disease';

         /* Cancer */
          if  DX(i) IN: ('140','141','142','143','144','145','146','147','148','149','150','151','152','153',
                         '154','155','156','157','158','159','160','161','162','163','164','165','170','171',
                         '172','174','175','176','179','180','181','182','183','184','185','186','187','188',
                         '189','190','191','192','193','194','195','200','201','202','203','204','205','206',
                         '207','208','2386') 
    or 174<=substr(trim(left(DX(i))),1,3)+0<=195   or 1950<=substr(trim(left(DX(i))),1,4)+0<=1958   or 140<=substr(trim(left(DX(i))),1,3)+0<=172
   or 200<=substr(trim(left(DX(i))),1,3)+0<=208
then CC_GRP_14 = 1;
          LABEL CC_GRP_14 = 'Cancer';

         /* Moderate or Severe Liver Disease */
          if   DX(i) IN: ('4560','4561','4562','5722','5723','5724','5728')
  or 4560<=substr(trim(left(DX(i))),1,4)+0<=4562     or 5722<=substr(trim(left(DX(i))),1,4)+0<=5728 
                         then CC_GRP_15 = 1;
          LABEL CC_GRP_15 = 'Moderate or Severe Liver Disease';

         /* Metastatic Carcinoma */
          if   DX(i) IN: ('196','197','198','199')  or 196<=substr(trim(left(DX(i))),1,3)+0<=199  then CC_GRP_16 = 1;
          LABEL CC_GRP_16 = 'Metastatic Carcinoma';

         /* AIDS/HIV */
          if   DX(i) IN: ('042','043','044')  or substr(trim(left(DX(i))),1,3) IN: ('042','043','044') then CC_GRP_17 = 1;
          LABEL CC_GRP_17 = 'AIDS/HIV';

    end;

    TOT_GRP = CC_GRP_1  + CC_GRP_2  + CC_GRP_3  + CC_GRP_4  + CC_GRP_5  + CC_GRP_6  + CC_GRP_7  + CC_GRP_8  +
              CC_GRP_9  + CC_GRP_10 + CC_GRP_11 + CC_GRP_12 + CC_GRP_13 + CC_GRP_14 + CC_GRP_15 + CC_GRP_16 +
              CC_GRP_17;
    LABEL TOT_GRP = 'Total CCI groups per record';

        run;

        options notes ;
         %put ;
         %put NOTE: _Charlson Finished &out created ;
     %put ;

        %goto exit ;

    %out1:
                %put ERROR: Prior Step failed with an Error submit a null data step to correct ;
        %goto exit ;

        %out2:
                %put ERROR: Input Data Was Not Defined;
        %goto exit ;

    %out3:
        %put ERROR: Input Data &libname..&data does not exist ;
        %goto exit ;

    %exit:

     %**** Reset the SAS options ;
     options &opts ;


%mend _CharlsonICD9CM;

/***************************************************/
/***  Run Charlson Macro, without dx type option ***/
/***************************************************/

%_CharlsonICD9CM (data    =dx_2,          /* input data set */
                        out     =charlson_1,          /* output data set */
                        dx      =dx1-dx270, /* range of diagnosis variables (dx01-dx16) */
                        dxtype  =dxtype01-dxtype16,/* range of diagnosis type variables */
                                                  /* (dxtype01-dxtype16) */
                        type    = off, /* on/off turn on or off use of dxtype */
                        debug   = off);

/***************************************************/
/***  Create charlson index, drop unneeded vars  ***/
/***************************************************/
data charlson_2;
set charlson_1;
drop dx1-dx270 _NAME_;
rename i=Dx_count;
/*create index with weighting*/
charlson_index = CC_GRP_1 + CC_GRP_2 + CC_GRP_3 + CC_GRP_4 + CC_GRP_5 + CC_GRP_6  +
               CC_GRP_7 + CC_GRP_8 + CC_GRP_9 + CC_GRP_10 + 2*CC_GRP_11 + 2*CC_GRP_12 + 
               2*CC_GRP_13 + 2*CC_GRP_14 + 3*CC_GRP_15 + 6*CC_GRP_16 + 6*CC_GRP_17 ;
label Dx_count="Diagnosis count to create Charlson score";
label charlson_index="Charlson index using severity weighting";
run;

proc freq;
table CC_GRP: ;
run;


/*Save dataset*/
data ccw.charlson;
set charlson_2;
run;



