/*      Get Data from the Individual asset tables - SDW_MART View Reconcillations     
     Extract the ABS , BOND , CMBS , CASH , FUND , LOAN , DERIVATIVIES & EQUITY       
  Use the data to compare against the source input data   */

/* TWO OUTPUTS
	TEMP7A - Data from Individual Asset Category tables
	TEMP7B - Data from the Generic Views and Summary Vies
*/

PROC SQL;

/*Create Temp work table*/

CREATE TABLE WORK.TEMP7A AS 

	/* Summary of all the data from the all the CM Mart Table for individual assets */


/*********************************************************************/
/*                          ABS - START                       		*/
/*********************************************************************/

SELECT 
	'01_ABS_VW' AS VW_NM,
	TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_MBS_CMO_MKT 

WHERE 
	ASOF_DATE = &AS_AT_MTH 
	AND TYPE_OF_INVESTMENT <> 'CMBS' 
	AND VERSION_NUMBER = 0 

GROUP BY 
	1,2

/*********************************************************************/
/*                          ABS - END                       		*/
/*********************************************************************/

		UNION ALL 

/*********************************************************************/
/*                          BOND - START                       		*/
/*********************************************************************/

SELECT 
	'02_BND_VW' AS VW_NM,
	TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(PRINCIPAL_AMOUNT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5)  AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_BOND_MKT 

WHERE 
	ASOF_DATE = &AS_AT_MTH 
	and VERSION_NUMBER = 0 

GROUP BY 
	1,2	

/*********************************************************************/
/*                           BOND - END	                    		*/
/*********************************************************************/	


	UNION ALL 

/*********************************************************************/
/*                           CASH - START	                    	*/
/*********************************************************************/	

SELECT 
	'03_CASH_VW' AS VW_NM,
	TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MARKET_VALUE),18.5)  AS MKT_VAL, 
	PUT(SUM(PRINCIPAL_AMOUNT),18.5)  AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5)  AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5)   AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_CASH_DEP_MKT 

WHERE 
	ASOF_DATE = &AS_AT_MTH 
	AND TYPE_OF_INVESTMENT = 'CASH' 
	and VERSION_NUMBER = 0 

GROUP BY 
	1,2 
/*********************************************************************/
/*                           CASH - END	                    		*/
/*********************************************************************/	

UNION ALL 

/*********************************************************************/
/*                           REPO - START                   		*/
/*********************************************************************/	

SELECT 
	'03_CASH_VW' AS VW_NM,
	TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MARKET_VALUE),18.5)  AS MKT_VAL, 
	PUT(SUM(PRINCIPAL_AMOUNT),18.5)  AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5)  AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5)   AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_REPO_MKT 

WHERE 
	ASOF_DATE = &AS_AT_MTH  
	AND TYPE_OF_INVESTMENT = 'REPO' 
	and VERSION_NUMBER = 0 

GROUP BY 
	1,2

/*********************************************************************/
/*                           REPO - END                   			*/
/*********************************************************************/	

	UNION ALL 

/*********************************************************************/
/*                           MBS - START                   			*/
/*********************************************************************/	

SELECT 
	'04_CMBS_VW' AS VW_NM,
	TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_MBS_CMO_MKT 

WHERE 
	ASOF_DATE = &AS_AT_MTH
	AND TYPE_OF_INVESTMENT = 'CMBS' 
	and VERSION_NUMBER = 0 

GROUP BY 
	1 , 2 

/*********************************************************************/
/*                           MBS - END                   			*/
/*********************************************************************/	
UNION ALL

/*********************************************************************/
/*                           FUND - START                   		*/
/*********************************************************************/	

SELECT 
	'05_FUND_VW' AS VW_NM,
	CASE WHEN TYPE_OF_INVESTMENT IN  ('OPEN_END','STIF') THEN 'FUND' ELSE 'NA' END AS TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT , 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_FUND_MKT 

WHERE 
	ASOF_DATE = &AS_AT_MTH 
	AND TYPE_OF_INVESTMENT IN  ('OPEN_END','STIF') 
	AND VERSION_NUMBER = 0 

GROUP BY 
	1, 2

/*********************************************************************/
/*                           FUND - END                   		*/
/*********************************************************************/	

UNION ALL 

/*********************************************************************/
/*                         Derivatives - START                       	*/
/*******************************************************************/ 

SELECT 
	'06_DERIVATIVES_VW' AS VW_NM,
	TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(CASE WHEN BOOK_COST IS NULL THEN 0.00 ELSE BOOK_COST END),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_DERIVATIVES_MKT 

WHERE 
	ASOF_DATE = &AS_AT_MTH 
	AND TYPE_OF_INVESTMENT IN ('FUTURE','FX','SWAP','UNKNOWN','CASH') 
	AND VERSION_NUMBER = 0 

GROUP BY 
	1,2 

/*********************************************************************/
/*                         Derivatives - END                       	*/
/*******************************************************************/ 


	UNION ALL 

/*********************************************************************/
/*                         Properties - START                       	*/
/*******************************************************************/ 
	 
SELECT 
	'07_PROPERTY_VW' AS VW_NM,
	'PROPERTY' AS TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PURCHASED_PRICE),18.5) AS PRNCPL_AMT, 
	PUT(SUM(PURCHASED_PRICE),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_PROP_MKT 

WHERE 
	VERSION_NUMBER = 0 
	and ASOF_DATE = &AS_AT_MTH 	

/*********************************************************************/
/*                         Properties - END                       	*/
/*******************************************************************/ 


UNION ALL 

/*********************************************************************/
/*                         Loan - START                            	*/
/*******************************************************************/ 

SELECT 
	'08_LOAN_VW' AS VW_NM,
	TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(PRINCIPAL_AMOUNT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_LOAN_MKT 

WHERE 
	ASOF_DATE = &AS_AT_MTH 	
	AND TYPE_OF_INVESTMENT = 'LOAN' 
	AND VERSION_NUMBER = 0 

GROUP BY 
	1,2	

/*********************************************************************/
/*                         Loan - END                            	*/
/*******************************************************************/ 

;

QUIT;


PROC SQL;

/*Convert . to ''*/
OPTIONS MISSING='';

/*Create Temp work table*/
CREATE TABLE WORK.TEMP7B AS


/*********************************************************************/
/*                          GENERIC VW - START               		*/
/*******************************************************************/
SELECT  
	'01 - GENERIC VIEW' AS VW_NM,
	CASE  
		WHEN SM_SEC_TYPE = 'FXFWRD' THEN 'FX' 
		WHEN SM_SEC_TYPE = 'FXSPOT' THEN 'FX' 
		WHEN SM_SEC_TYPE = 'REIT' THEN 'PROPERTY' 
	ELSE SM_SEC_GROUP END AS TYPE_OF_INVESTMENT, 

	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5)AS SOLII_VAL, 
	PUT(SUM(MKT_VAL),18.5)AS MKT_VAL, 

	PUT(SUM(CASE 
		WHEN CALCULATED TYPE_OF_INVESTMENT = 'EQUITY' THEN BOOK_COST 
	ELSE PRNCPL_AMT END),18.5) AS PRNCPL_AMT , 

	PUT(SUM(BOOK_COST),18.5)
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_INSTRMT 

WHERE 
	AS_AT_MTH=&AS_AT_MTH 

GROUP BY 
	VW_NM,
	TYPE_OF_INVESTMENT 

/*********************************************************************/
/*                          GENERIC VW - END               			*/
/*******************************************************************/

UNION ALL 

/*********************************************************************/
/*                          SUMMARY VW - START               		*/
/*******************************************************************/

SELECT

	'02 - SUMMARY VIEW' AS VW_NM,
	CASE 
		WHEN  UPCASE(I_T_INV_CLS_CATEGORY) IN ('FX FORWARD' ,'EXCLUDE') AND  UPCASE(CM_INV_CLASS_2) IN ('DERIVATIVES','') AND UPCASE(PAM_GL_GRP) = 'FORWARDS' THEN 'FX' 
    	WHEN  UPCASE(I_T_INV_CLS_CATEGORY) = 'PROPERTY' THEN 'PROPERTY' 
     ELSE SM_SEC_GROUP END AS TYPE_OF_INVESTMENT, 
	SUM(COUNT_OF_INVESTMENTS)AS NO_OF_RECORDS,
	PUT(SUM(SUM_OF_SOLVENCY_II_VALUE),18.5)AS SOLII_VAL,
	PUT(SUM(SUM_OF_MKT_VALUE),18.5) AS MKT_VAL,
	PUT(SUM(SUM_OF_CUR_FACE),18.5)AS PRNCPL_AMT,
	PUT(SUM(SUM_OF_BOOK_VALUE),18.5)AS BOOK_VAL 
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_INSTRMT_SMRY

GROUP BY 
	VW_NM,
	TYPE_OF_INVESTMENT

/*********************************************************************/
/*                          SUMMARY VW - END               			*/
/*******************************************************************/

UNION ALL 

/*********************************************************************/
/*                         Equity - START                          	*/
/*******************************************************************/ 

SELECT 

	'09_EQUITY_VW' AS VW_NM,
	TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL ,
	PUT(SUM(MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(PAR_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(CASE WHEN BOOK_COST IS NULL THEN 0.00 ELSE BOOK_COST END),18.5) AS BOOK_VAL  
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_EQTY_MKT 

WHERE 
	ASOF_DATE = &AS_AT_MTH
	AND TYPE_OF_INVESTMENT IN ('EQUITY') 
	AND VERSION_NUMBER = 0 

GROUP BY 
	1,2
 
/*********************************************************************/
/*                         Equity - END                          	*/
/*******************************************************************/ 

;

QUIT;
