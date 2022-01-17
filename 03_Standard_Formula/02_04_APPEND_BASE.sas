/* Append all the 3 Data sources VIA TWO METHODS 
	- NON PROPERTY
	- PROPERTY 
	- LOOKTHROUGH
*/
/*METHOD 1 SET THE DATA */
DATA WORK.SF_BASE_APPEND;
SET WORK.NONPROP WORK.LKTHRU WORK.PROP ;
RUN;

/*METHOD 2 SET THE APPEND PROP INTO NON PROP 
- Dont use FORCE we need to know if there are any incompatible columns during APPEND  */
PROC APPEND BASE=WORK.NONPROP DATA=WORK.PROP;
;
RUN;
/*METHOD 2 SET THE APPEND LOOKTHROUGH INTO NON PROP 
- Dont use FORCE we need to know if there are any incompatible columns during APPEND  */
PROC APPEND BASE=WORK.NONPROP DATA=WORK.LKTHRU;
;
RUN;

/*Compare the two data sets SORT and then Compare - Best Practices else not comparing like for like*/
PROC SORT DATA=WORK.NONPROP ;  by _all_;
;
RUN;
PROC SORT DATA=WORK.SF_BASE_APPEND ;  by _all_;
;
RUN;

/* Both the APPEND data sets should not show any differences */
PROC COMPARE BASE=WORK.SF_BASE_APPEND COMPARE=WORK.NONPROP ;
;
RUN;