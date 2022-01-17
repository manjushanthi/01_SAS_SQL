/* Libname to point to the path of the SASDATASETS */
libname test '/sdwmigration/POST_Q3_2021/whd01_sdw/sasdata';

/*
** libname test '/sdwmigration/POST_Q1_2021/whd01_sdw/sasdata';
** libname test '/sdwmigration/POST_Q3_2021/whd01_sdw/sasdata' - Q3

/*
'/sdwmigration/POST_Q1_2021/whd01_sdw/sasdata' 	- Q1
'/sdwmigration/SEP2021/whd01_sdw/sasdata' 		- Q2
'/sdwmigration/POST_Q3_2021/whd01_sdw/sasdata'  - Q3
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
