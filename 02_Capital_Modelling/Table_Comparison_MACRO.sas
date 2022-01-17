libname teralib teradata user=BHYC password=Welcome12345 schema=ACS_SDW server='172.30.228.109';


%let server ='172.30.228.109';

%let Schema =ACS_SDW;
%let user=BHYC ;
%let password=Welcome12345;

%macro SAS_Teradata_Comp(tbl);
proc sql noprint;
   connect to &var_dbname.(SERVER=&server.  SCHEMA=&schema.  USER=&user.   PASSWORD="&password");
      create table work.&tbl._TD as 
SELECT  * from  
connection to &var_dbname.
(
   select * from &schema..&tbl.
);
disconnect from &var_dbname;
quit;


libname test_SAS BASE '/sdwmigration/POST_Q4_2020/acs_sdw/sasdata';
PROC SQL;
options missing='';
CREATE TABLE WORK.&tbl._S AS
SELECT * FROM test_SAS.&tbl.
;
QUIT;

proc sort data=&tbl._TD; by _all_;
run;
proc sort data=&tbl._S; by _all_;
run;

proc compare data=&tbl._TD compare=&tbl._S;
run;
%mend;

%SAS_Teradata_Comp(CM_INSTRMT_SMRY);
%SAS_Teradata_Comp(CM_VW_ABRIDGE);       