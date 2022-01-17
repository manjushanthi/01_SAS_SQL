/*      Get Data from the CM Mart tables  / Views
			1) CM_INSTRMT_SMRY 
			2) CM_VW_ABRIDGE
 		Change the Date fields to the DD/MM/YYYY format
*/
		 
	
/* TWO OUTPUTS - SEND TO CM TEAM (HARVEY CLIFF - Main Recepient)
	CM_EXT_CM_INSTRMT_SMRY - Data from Capital Modelling Instrument Summary Table 
	CM_EXT_CM_VW_ABRIDGE - Data from the Capital Modelling Detailed Abridged Views - Contains all the instrument 
*/

PROC SQL;

/*Create Temp work table*/

CREATE TABLE WORK.CM_EXT_CM_INSTRMT_SMRY AS 

	/* CM_EXT_CM_INSTRMT_SMRY - Data from Capital Modelling Instrument Summary Table  */


/*********************************************************************/
/*        CM_EXT_CM_INSTRMT_SMRY - START EXTRACT             		*/
/*********************************************************************/

SELECT 
	* 
FROM  
	test.CM_INSTRMT_SMRY

WHERE 
	AS_AT_MTH = &AS_AT_MTH;


/*********************************************************************/
/*        CM_EXT_CM_INSTRMT_SMRY - END EXTRACT             			*/
/*********************************************************************/

QUIT;


PROC SQL;

/*Create Temp work table*/
OPTIONS MISSING='' ; 
CREATE TABLE WORK.CM_EXT_CM_VW_ABRIDGE AS 

	/* CM_EXT_CM_VW_ABRIDGE - Data from the Capital Modelling Detailed Abridged Views - Contains all the instrument   */


/*********************************************************************/
/*        CM_EXT_CM_VW_ABRIDGE - START EXTRACT             		*/
/*********************************************************************/

SELECT 
	* 
FROM  
	test.CM_VW_ABRIDGE

WHERE 
	ASOF_DATE = &AS_AT_MTH;


/*********************************************************************/
/*        CM_EXT_CM_VW_ABRIDGE - END EXTRACT             			*/
/*********************************************************************/

QUIT;