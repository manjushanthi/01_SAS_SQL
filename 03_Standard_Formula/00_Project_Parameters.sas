/* Libname to point to the path of the SASDATASETS */
libname test '/sdwmigration/POST_Q4_2020/whd01_sdw/sasdata';
libname test_mar '/sdwmigration/POST_Q4_2020/whm01_sdw_mart/sasdata';

** libname test '/sdwmigration/POST_Q1_2021/whd01_sdw/sasdata';

/*
'/sdwmigration/SEP2021/whd01_sdw/sasdata' 		- Q2
'/sdwmigration/POST_Q1_2021/whd01_sdw/sasdata' 	- Q1
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
