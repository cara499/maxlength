/******************************************************************************/
/* PROD PROGRAM:  /home/public/macros/maxlength.sas
/* WORK PROGRAM:  /home/prinf/programs/development/public/macros/MAXLENGTH/INITIAL/maxlength.sas
/* 
/* PURPOSE:       Take datasets to be combined, find common variables, and for those
/*                variables obtain the maximum length. Returns a length statement as a global
/*                macro variable. 
/* 
/* SOURCE PRGM:   none
/* INPUT:         none
/* OUTPUT:        none
/* MACROS USED:   %dataexst
/* EXEMPTIONS:    none
/* 
/* AUTHOR:        Cara Smith
/* CREATION DATE: 06/14/16
/* 
/* NOTES:         none
/* MODIFICATIONS: none
/* EXEMPTIONS:    none    
/******************************************************************************/

%macro maxlength(DSETS=,DROPS=,KEEPS=,DEBUG=cancel);
   
    /* MAXLEN must be global to use outside of macro */
    %global MAXLENGTH;
    %local NUMDSETS NVARS VARCHK VARLIST;
    
    %let NUMDSETS=%sysfunc(countw(&DSETS, " "));

    /*****************************************************************************/ 
    /* Error Checks
    /*****************************************************************************/
    
    /* Check that at least two datasets were listed as input arguments */
    %if &NUMDSETS < 2 %then %do;
        %put %upcase(error): (CBAR) Parameter DSETS needs at least two datasets.;
        %return;
    %end;

    /* Check that all datasets exist */
    %dataexst(&DSETS);
    
    /* Cannot use DROPS and KEEPS at the same time */
    %if %length(&DROPS) > 0 and %length(&KEEPS) > 0 %then %do;
        %put %upcase(error): (CBAR) Cannot use parameters DROPS and KEEPS at the same time.;
        %return;
    %end;
        
    /*****************************************************************************/ 
    /* Loop through datasets in DSETS and output metadata
    /*****************************************************************************/
    %do i=1 %to &NUMDSETS;
        
        %let dset&i = %scan(&DSETS,&i,' ');
        
        %if %length(&DROPS) > 0 or %length(&KEEPS) > 0 %then %do;
            %let NVARS = %sysfunc(countw(&DROPS, ' '));
            
            /* Loop through &DROPS or &KEEPS variables and build a list of variables that exist in each dataset */
            %let VARLIST=;
            %do k=1 %to &NVARS; 
                %let VAR&k = %scan(&DROPS,&k,' ');
                
                /* check if variable exists in dataset */
                data _null_; 
                    dset=open("&&DSET&i"); 
                    call symput("VARCHK",strip(varnum(dset,"&&VAR&k"))); 
                run;

                /* if variable exists add it to list */
                %if &VARCHK ne 0 %then %do;   
                    %let VARLIST= &VARLIST &&VAR&k;
                %end;
               
            %end;

            /* Make working dataset with select variables kept or dropped */
            data dset&i;
              set &&DSET&i
                  %if %length(&DROPS) > 0 %then %do;
                      (drop=&VARLIST)
                  %end;
                  %else %do;
                      (Keep=&VARLIST)
                  %end;
              ;
            run;

            /* Create a dataset for each dataset listed in &DSETS with metadata for every character variable excluding those in &DROPS*/
            /* or only those in &KEEPS */
            proc contents data = dset&i noprint out=mlout&i (keep=libname memname name type length where=(type=2)); 
            run;          
        %end;

        %else %do;
            /* If no &DROPS or &KEEPS then make dataset with metadata for every character variable */
            proc contents data = &&DSET&i noprint out=mlout&i (keep=libname memname name type length where=(type=2)); 
            run;
        %end; 
        
        proc print data = mlout&i;
        run &DEBUG; 

       
    %end;

    /*****************************************************************************/ 
    /* Use metadata to create &MAXLENGTH
    /*****************************************************************************/
    
    /* Set all mlout# datasets together  */
    data allvars;
        set mlout1-mlout&NUMDSETS;
    run;
 
    /* For variables that exist in more than one dataset, find the max length */
    proc sql;
       create table maxvarlen as 
           select name, max(length) as maxlen 
           from allvars 
           group by name
           having count(name) >= 2 and min(length) ne max(length); 
    quit; 

    /* Create &MAXLENGTH  */
    %let MAXLENGTH =length;
    data _null_;
        set maxvarlen;
        call symput('MAXLENGTH',strip(resolve('&MAXLENGTH'))||' '|| strip(name) || ' $ ' || strip(maxlen));
    run;
    
    %put MAXLENGTH=&MAXLENGTH;
            
%mend maxlength;

