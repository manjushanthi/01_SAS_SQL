/* Libname to point to the path of the SASDATASETS */
libname test '/sdwmigration/POST_Q3_2021/whd01_sdw/sasdata';
libname test_mar '/sdwmigration/POST_Q3_2021/whm01_sdw_mart/sasdata';


%let AS_AT_MTH = '30SEP2021'd;

/******************************************************************************/
/*                  Parameterize the Input Date  			   				 */
/*  Need to change the below parameter date for each Quarter   				*/
/*  Input the Parameter in line with AS AT Date from the Blackrock file	   */
/*  			FORMAT - DATE9. DDMMMYYYY					              */
/*************************************************************************/
%let AS_AT_MTH = '30SEP2021'd;
%let CURR_Q    = '30SEP2021'd; /*should be = AS_AT_MTH*/
%let PREV_Q    = '30JUN2021'd;



/* 999 - System calculated Rating */
/* 555 - Business Assigned Rating */