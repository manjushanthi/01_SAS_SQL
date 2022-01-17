
/* 
Straight forward extract from Input File - DC184_CLOSED_DERIVATIVE_TRANSACTIONS MMM-YY.xls
Only One table Involved - X_CLOSED_DRVTS_TRANS
Also Included the Validations Part
*/

/* Libname to point to the path of the SASDATASETS */
libname test '/sdwmigration/POST_Q4_2020/acs_sdw/sasdata';

/*
/* Libname to point to the path of the SASDATASETS 

libname test '/sdwmigration/SEP2021/whd01_sdw/sasdata';	- Q2
				/sdwmigration/SEP2021/acs_sdw/sasdata
libname test '/sdwmigration/POST_Q1_2021/acs_sdw/sasdata';	- Q1
			 '/sdwmigration/POST_Q1_2021/acs_sdw/sasdata' Q1

*/

/******************************************************************************/
/*                  Parameterize the Input Date  			   				 */
/*  Need to change the below parameter date for each Quarter   				*/
/*  Input the Parameter in line with AS AT Date from the Blackrock file	   */
/*  			FORMAT - DATE9. DDMMMYYYY					              */
/*************************************************************************/
%let AS_AT_MTH = '31DEC2020'd;

/*
Q2 - 30JUN2021
Q1 - 31MAR2021
*/