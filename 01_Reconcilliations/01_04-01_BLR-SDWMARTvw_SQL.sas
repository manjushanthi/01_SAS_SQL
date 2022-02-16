/*      Get Data from the Individual asset tables - SDW_MART View Reconcillations     
     Extract the ABS , BOND , CMBS , CASH , FUND , LOAN , DERIVATIVIES & EQUITY       
  Use the data to compare against the source input data   */

/* TWO OUTPUTS
	TEMP7A - Data from Individual Asset Category tables
	TEMP7B - Data from the Generic Views and Summary Vies
*/

PROC SQL;

/*Create Temp work table*/

CREATE TABLE WORK.TEMP7A_1 AS 

	/* Summary of all the data from the all the CM Mart Table for individual assets */


/*********************************************************************/
/*                          ABS - START                       		*/
/*********************************************************************/

SELECT 
	'01_ABS_VW' AS VW_NM LENGTH=25,
	CMO.TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(CMO.MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(CMO.PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(CMO.BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(CMO.X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_MBS_CMO_MKT CMO

WHERE 
	CMO.ASOF_DATE = &AS_AT_MTH 
	AND CMO.TYPE_OF_INVESTMENT <> 'CMBS' 
	AND CMO.VERSION_NUMBER = 0 

GROUP BY 
	1,2 ;

/*********************************************************************/
/*                          ABS - END                       		*/
/*********************************************************************/

	CREATE TABLE WORK.TEMP7A_2 AS 

/*********************************************************************/
/*                          BOND - START                       		*/
/*********************************************************************/

SELECT 
	'02_BND_VW' AS VW_NM  LENGTH=25,
	BOND.TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(BOND.MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(BOND.PRINCIPAL_AMOUNT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOND.BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(BOND.X_SOLVENCY_II_VALUE),18.5)  AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_BOND_MKT BOND

WHERE 
	BOND.ASOF_DATE = &AS_AT_MTH 
	AND BOND.VERSION_NUMBER = 0 

GROUP BY 
	1,2	;

/*********************************************************************/
/*                           BOND - END	                    		*/
/*********************************************************************/	


CREATE TABLE WORK.TEMP7A_3 AS 

/*********************************************************************/
/*                           CASH - START	                    	*/
/*********************************************************************/	

SELECT 
	'03_CASH_VW' AS VW_NM  LENGTH=25,
	TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(CASH.MARKET_VALUE),18.5)  AS MKT_VAL, 
	PUT(SUM(CASH.PRINCIPAL_AMOUNT),18.5)  AS PRNCPL_AMT, 
	PUT(SUM(CASH.BOOK_COST),18.5)  AS BOOK_VAL, 
	PUT(SUM(CASH.X_SOLVENCY_II_VALUE),18.5)   AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_CASH_DEP_MKT CASH

WHERE 
	CASH.ASOF_DATE = &AS_AT_MTH 
	AND CASH.TYPE_OF_INVESTMENT = 'CASH' 
	AND CASH.VERSION_NUMBER = 0 

GROUP BY 
	1,2 ;
/*********************************************************************/
/*                           CASH - END	                    		*/
/*********************************************************************/	

CREATE TABLE WORK.TEMP7A_4 AS 

/*********************************************************************/
/*                           REPO - START                   		*/
/*********************************************************************/	

SELECT 
	'03_CASH_VW' AS VW_NM  LENGTH=25,
	REPO.TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(REPO.MARKET_VALUE),18.5)  AS MKT_VAL, 
	PUT(SUM(REPO.PRINCIPAL_AMOUNT),18.5)  AS PRNCPL_AMT, 
	PUT(SUM(REPO.BOOK_COST),18.5)  AS BOOK_VAL, 
	PUT(SUM(REPO.X_SOLVENCY_II_VALUE),18.5)   AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_REPO_MKT REPO

WHERE 
	REPO.ASOF_DATE = &AS_AT_MTH  
	AND REPO.TYPE_OF_INVESTMENT = 'REPO' 
	AND REPO.VERSION_NUMBER = 0 

GROUP BY 
	1,2;

/*********************************************************************/
/*                           REPO - END                   			*/
/*********************************************************************/	

CREATE TABLE WORK.TEMP7A_5 AS  

/*********************************************************************/
/*                           MBS - START                   			*/
/*********************************************************************/	

SELECT 
	'04_CMBS_VW' AS VW_NM  LENGTH=25,
	MBS.TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(MBS.MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(MBS.PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(MBS.BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(MBS.X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_MBS_CMO_MKT MBS

WHERE 
	MBS.ASOF_DATE = &AS_AT_MTH
	AND MBS.TYPE_OF_INVESTMENT = 'CMBS' 
	AND MBS.VERSION_NUMBER = 0 

GROUP BY 
	1 , 2 ;

/*********************************************************************/
/*                           MBS - END                   			*/
/*********************************************************************/	
CREATE TABLE WORK.TEMP7A_6 AS 

/*********************************************************************/
/*                           FUND - START                   		*/
/*********************************************************************/	

SELECT 
	'05_FUND_VW' AS VW_NM  LENGTH=25,
	CASE WHEN FUND.TYPE_OF_INVESTMENT IN  ('OPEN_END','STIF') THEN 'FUND' ELSE 'NA' END AS TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(FUND.MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(FUND.PRNCPL_AMT),18.5) AS PRNCPL_AMT , 
	PUT(SUM(FUND.BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(FUND.X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_FUND_MKT FUND

WHERE 
	FUND.ASOF_DATE = &AS_AT_MTH 
	AND FUND.TYPE_OF_INVESTMENT IN  ('OPEN_END','STIF') 
	AND FUND.VERSION_NUMBER = 0 

GROUP BY 
	1, 2;

/*********************************************************************/
/*                           FUND - END                   		*/
/*********************************************************************/	

CREATE TABLE WORK.TEMP7A_7 AS 

/*********************************************************************/
/*                         Derivatives - START                       	*/
/*******************************************************************/ 

SELECT 
	'06_DERIVATIVES_VW' AS VW_NM  LENGTH=25,
	DVTS.TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(DVTS.MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(DVTS.PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(CASE WHEN DVTS.BOOK_COST IS NULL THEN 0.00 ELSE DVTS.BOOK_COST END),18.5) AS BOOK_VAL, 
	PUT(SUM(DVTS.X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_DERIVATIVES_MKT DVTS

WHERE 
	DVTS.ASOF_DATE = &AS_AT_MTH 
	AND DVTS.TYPE_OF_INVESTMENT IN ('FUTURE','FX','SWAP','UNKNOWN','CASH') 
	AND DVTS.VERSION_NUMBER = 0 

GROUP BY 
	1,2 ;

/*********************************************************************/
/*                         Derivatives - END                       	*/
/*******************************************************************/ 


CREATE TABLE WORK.TEMP7A_8 AS 

/*********************************************************************/
/*                         Properties - START                       	*/
/*******************************************************************/ 
	 
SELECT 
	'07_PROPERTY_VW' AS VW_NM  LENGTH=25,
	'PROPERTY' AS TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(PROP.MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PROP.PURCHASED_PRICE),18.5) AS PRNCPL_AMT, 
	PUT(SUM(PROP.PURCHASED_PRICE),18.5) AS BOOK_VAL, 
	PUT(SUM(PROP.X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_PROP_MKT PROP

WHERE 
	PROP.VERSION_NUMBER = 0 
	and PROP.ASOF_DATE = &AS_AT_MTH 
GROUP BY 1,2;	

/*********************************************************************/
/*                         Properties - END                       	*/
/*******************************************************************/ 


CREATE TABLE WORK.TEMP7A_9 AS 

/*********************************************************************/
/*                         Loan - START                            	*/
/*******************************************************************/ 

SELECT 
	'08_LOAN_VW' AS VW_NM  LENGTH=25,
	LOAN.TYPE_OF_INVESTMENT, 
	COUNT(*) AS NO_OF_RECORDS, 
	PUT(SUM(LOAN.MARKET_VALUE),18.5) AS MKT_VAL, 
	PUT(SUM(LOAN.PRINCIPAL_AMOUNT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(LOAN.BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(LOAN.X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_VW_LOAN_MKT LOAN

WHERE 
	LOAN.ASOF_DATE = &AS_AT_MTH 	
	AND LOAN.TYPE_OF_INVESTMENT = 'LOAN' 
	AND LOAN.VERSION_NUMBER = 0 

GROUP BY 
	1,2	

/*********************************************************************/
/*                         Loan - END                            	*/
/*******************************************************************/ 

;

/*********************************************************************/
/*                         Equity - START                          	*/
/*******************************************************************/ 

CREATE TABLE WORK.TEMP7A_10 AS 

SELECT 

	'09_EQUITY_VW' AS VW_NM  LENGTH=25,
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

DATA WORK.TEMP7A;
SET TEMP7A_1 TEMP7A_2 TEMP7A_3 TEMP7A_4 TEMP7A_5 TEMP7A_6 TEMP7A_7 TEMP7A_8 TEMP7A_9 TEMP7A_10;
RUN;

PROC DATASETS LIBRARY=WORK NOLIST;
DELETE TEMP7A_1 TEMP7A_2 TEMP7A_3 TEMP7A_4 TEMP7A_5 TEMP7A_6 TEMP7A_7 TEMP7A_8 TEMP7A_9 TEMP7A_10;
RUN;



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



;

QUIT;
