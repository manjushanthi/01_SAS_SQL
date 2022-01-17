/*      Get Data from the Individual asset tables - SDW_MART Reconcillations     
     Extract the ABS , BOND , CMBS , CASH , FUND , LOAN , DERIVATIVIES & EQUITY       
  Use the data to compare against the source input data   */

/* TWO OUTPUTS
	TEMP6A - Data from Individual Asset Category tables
	TEMP6B - Data from the Generic Views and Summary Vies
*/

PROC SQL;

/*Create Temp work table*/

CREATE TABLE WORK.TEMP6A AS 

	/* Summary of all the data from the all the CM Mart Table for individual assets */


/*********************************************************************/
/*                          ABS - START                       		*/
/*********************************************************************/

	SELECT 
			'01_ABS_TBL' AS TBL_NM,
			INVSTMT_TYP AS INVSTMT_TYP , 
			CASE 
				WHEN INVSTMT_TYP = '001' THEN 'ABS' 
				WHEN INVSTMT_TYP = '008' THEN 'CMO' 
			ELSE 'NA' END AS INVSTMT_CD, 
			COUNT(*) AS  NO_OF_RECORDS, 
			PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
			PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
			PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
			PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
			, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

	FROM 
			(
				SELECT 
					DISTINCT 
						MBS_CMO_INSTRMT_VK,
						INVSTMT_TYP,
						AS_AT_MTH 

				FROM 
					test.CM_ABS_MBS_CMO_INSTRMT
			) AS INSTR

			INNER JOIN test.CM_ABS_MBS_CMO_PSTN PSTN 
				ON  INSTR.MBS_CMO_INSTRMT_VK = PSTN.MBS_CMO_INSTRMT_VK  

	WHERE 
			INSTR.AS_AT_MTH = &AS_AT_MTH  
			AND INSTR.INVSTMT_TYP <> '006' 
			AND PSTN.AS_AT_MTH = &AS_AT_MTH 
			AND PSTN.PPN_DTTM = 
					(SELECT
						MAX(PPN_DTTM) 
					FROM  
						test.CM_ABS_MBS_CMO_PSTN
					) 

	GROUP BY 
		1,2,3

/*********************************************************************/
/*                          ABS - END                       		*/
/*********************************************************************/

UNION ALL 

/*********************************************************************/
/*                          BOND - START                       		*/
/*********************************************************************/

	SELECT 
			'02_BND_TBL' AS TBL_NM,
			INVSTMT_TYP, 
			CASE WHEN INVSTMT_TYP = '003' THEN 'BOND' 
				ELSE 
				'NA' 
			END AS INVSTMT_CD, 
			COUNT(*) AS  NO_OF_RECORDS, 
			PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
			PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
			PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
			PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL 
			, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

	FROM 
			(
			SELECT 
					DISTINCT 
						BND_INSTRMT_VK,
						INVSTMT_TYP,
						AS_AT_MTH 
			FROM 
					test.CM_BOND_INSTRMT
			) AS INSTR

			INNER JOIN test.CM_BOND_PSTN PSTN 
				ON INSTR.BND_INSTRMT_VK=PSTN.BND_INSTRMT_VK 

			WHERE 
				INSTR.AS_AT_MTH = &AS_AT_MTH  
				AND PSTN.AS_AT_MTH = &AS_AT_MTH  
				AND CM_BOND_PSTN.PPN_DTTM = 
						(
						SELECT 
								MAX(PPN_DTTM) 
						FROM  
								test.CM_BOND_PSTN
						)  
			GROUP BY 
				1,2,3

/*********************************************************************/
/*                          BOND - END                       		*/
/*********************************************************************/

UNION ALL 

/*********************************************************************/
/*                          CASH - START                       		*/
/*********************************************************************/

SELECT 
	'03_CASH_TBL' AS TBL_NM,
	INVSTMT_TYP, 
	CASE WHEN INVSTMT_TYP = '004' THEN 'CASH' ELSE 'NA' END AS INVSTMT_CD, 
	COUNT(*) AS  No_Of_Records, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL 
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	(SELECT DISTINCT CASH_DEP_INSTRMT_VK, INVSTMT_TYP,AS_AT_MTH FROM test.CM_CASH_DEP_INSTRMT) AS INSTR, 
	test.CM_CASH_DEP_PSTN PSTN 

WHERE 
	INSTR.AS_AT_MTH =  &AS_AT_MTH  
	AND PSTN.AS_AT_MTH = &AS_AT_MTH  
	AND INSTR.CASH_DEP_INSTRMT_VK=PSTN.CASH_DEP_INSTRMT_VK 
	AND INVSTMT_TYP='004'  
	AND PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM  test.CM_CASH_DEP_PSTN) 

GROUP BY 
	1,2,3 


/*********************************************************************/
/*                          CASH - END                       		*/
/*********************************************************************/

UNION ALL 

/*********************************************************************/
/*                          REPO - START                       		*/
/*********************************************************************/

SELECT 
	'03_CASH_TBL' AS TBL_NM,
	INVSTMT_TYP, 
	CASE WHEN INVSTMT_TYP = '004' THEN 'REPO' ELSE 'NA' END AS INVSTMT_CD, 
	COUNT(*) AS  No_Of_Records, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL  
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	(SELECT DISTINCT REPO_INSTRMT_VK, INVSTMT_TYP,AS_AT_MTH FROM test.CM_REPO_INSTRMT) AS INSTRU, 
	test.CM_REPO_PSTN PSTN 

WHERE 
	INSTRU.AS_AT_MTH = &AS_AT_MTH  
	AND PSTN.AS_AT_MTH = &AS_AT_MTH  
	AND INSTRU.REPO_INSTRMT_VK=PSTN.REPO_INSTRMT_VK 
	AND INVSTMT_TYP='004'  
	AND PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM  test.CM_REPO_PSTN)   

GROUP BY 
	1,2,3

/*********************************************************************/
/*                          REPO - END                       		*/
/*********************************************************************/

UNION ALL

/*********************************************************************/
/*                          CMBS - START                       		*/
/*********************************************************************/

SELECT 
	'04_CMBS_TBL' AS TBL_NM,
	INVSTMT_TYP, 
	CASE WHEN INVSTMT_TYP = '006' THEN 'CMBS' ELSE 'NA' END AS INVSTMT_CD, 
	COUNT(*) AS  No_Of_Records, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PRNCPL_AMT),18.5) as PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL 
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	(SELECT DISTINCT MBS_CMO_INSTRMT_VK,INVSTMT_TYP,AS_AT_MTH FROM test.CM_ABS_MBS_CMO_INSTRMT) AS INSTR, 
	test.CM_ABS_MBS_CMO_PSTN PSTN 

WHERE 
	INSTR.AS_AT_MTH =  &AS_AT_MTH 
	AND PSTN.AS_AT_MTH =  &AS_AT_MTH  
	AND INSTR.MBS_CMO_INSTRMT_VK = PSTN.MBS_CMO_INSTRMT_VK 
	AND INVSTMT_TYP='006'  
	AND PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM  test.CM_ABS_MBS_CMO_PSTN)   

GROUP BY 
	1,2,3	

/*********************************************************************/
/*                          CMBS - END                       		*/
/*********************************************************************/

UNION ALL

/*********************************************************************/
/*                          FUND - START                       		*/
/*********************************************************************/


SELECT 
	'05_FUND_TBL' AS TBL_NM,
	'FUND-MMF' AS INVSTMT_TYP , 
	CASE WHEN INVSTMT_TYP IN ('003','005') THEN 'FUND' ELSE 'NA' END AS INVSTMT_CD, 
	COUNT(*) AS  No_Of_Records, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL 
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	(SELECT DISTINCT FUND_INSTRMT_VK,INVSTMT_TYP,AS_AT_MTH FROM test.CM_FUND_INSTRMT) AS INSTR, 
	test.CM_FUND_PSTN PSTN 

WHERE 
	INSTR.AS_AT_MTH = &AS_AT_MTH 
	AND PSTN.AS_AT_MTH = &AS_AT_MTH 
	AND INSTR.FUND_INSTRMT_VK=PSTN.FUND_INSTRMT_VK 
	AND INVSTMT_TYP IN ('003','005') 
	AND PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM  test.CM_FUND_PSTN)  

GROUP BY 
	1,2,3	

/*********************************************************************/
/*                          FUND - END                       		*/
/*********************************************************************/
 
UNION ALL 

/*********************************************************************/
/*                         Derivatives - START                       	*/
/*******************************************************************/ 

SELECT 
	'06_DERIVATIVES_TBL' AS TBL_NM,
	INVSTMT_TYP, 
	CASE WHEN INVSTMT_TYP = '011' THEN 'FUTURE' ELSE CASE WHEN INVSTMT_TYP = '004' THEN 'FX' ELSE CASE WHEN INVSTMT_TYP = '020' THEN 'SYNTH' ELSE 'NA' END  END END AS INVSTMT_CD, 
	COUNT(*) AS  No_Of_Records, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(CASE WHEN BOOK_COST IS NULL THEN 0.00 ELSE BOOK_COST END),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL 
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	(SELECT DISTINCT DRVTS_INSTRMT_VK,INVSTMT_TYP,AS_AT_MTH FROM test.CM_DRVTS_INSTRMT) AS INSTR, 
	test.CM_DRVTS_PSTN PSTN 

WHERE 
	INSTR.AS_AT_MTH = &AS_AT_MTH  
	AND PSTN.AS_AT_MTH = &AS_AT_MTH 
	AND INSTR.DRVTS_INSTRMT_VK = PSTN.DRVTS_INSTRMT_VK 
	AND INVSTMT_TYP IN  ('004','011','020') 
	AND PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM  test.CM_DRVTS_PSTN)  

GROUP BY 
	1,2,3

/*********************************************************************/
/*                         Derivatives - END                       	*/
/*******************************************************************/ 

UNION ALL

/*********************************************************************/
/*                         Properties - START                       	*/
/*******************************************************************/ 

	
SELECT 
	'07_PROPERTY_TBL' AS TBL_NM,
	'PROPERTY' AS INVSTMT_TYP, 
	'099' AS INVSTMT_CD,
	COUNT(*) AS No_Of_Records, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PURCHASED_PRICE),18.5) AS PRNCPL_AMT,
	PUT(SUM(PURCHASED_PRICE),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS  SOLII_VAL 
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH 

FROM 
	test.CM_PRPTY_PSTN PSTN

WHERE 
	PSTN.AS_AT_MTH = &AS_AT_MTH 
	AND PSTN.PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM  test.CM_PRPTY_PSTN) 

/*********************************************************************/
/*                         Properties - END                       	*/
/*******************************************************************/ 

	UNION ALL 

/*********************************************************************/
/*                         Loan - START                            	*/
/*******************************************************************/ 

SELECT 
	'08_LOAN_TBL' AS TBL_NM,
	INVSTMT_TYP, 
	CASE WHEN INVSTMT_TYP = '015' THEN 'LOAN' ELSE 'NA' END AS INVSTMT_CD, 
	COUNT(*) AS  No_Of_Records, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL,
	PUT(SUM(PRNCPL_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS  SOLII_VAL  
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 

	(SELECT DISTINCT LOAN_INSTRMT_VK,INVSTMT_TYP,AS_AT_MTH FROM test.CM_LOAN_INSTRMT) AS INSTR, 
	test.CM_LOAN_PSTN PSTN 

WHERE 
	INSTR.AS_AT_MTH = &AS_AT_MTH 
	AND PSTN.AS_AT_MTH = &AS_AT_MTH 
	AND INSTR.LOAN_INSTRMT_VK=PSTN.LOAN_INSTRMT_VK 
	AND INVSTMT_TYP = '015' 
	AND PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM  test.CM_LOAN_PSTN) 

GROUP BY
	1,2,3 

/*********************************************************************/
/*                         Loan - END                             	*/
/*******************************************************************/ 

	UNION ALL 

/*********************************************************************/
/*                         Equity - START                          	*/
/*******************************************************************/ 
	
SELECT 
	'09_EQUITY_TBL' AS TBL_NM,
	INVSTMT_TYP, 
	CASE WHEN INVSTMT_TYP = '001' THEN 'EQUITY' ELSE 'NA' END AS INVSTMT_CD, 
	COUNT(*) AS  No_Of_Records, 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(SUM(PAR_AMT),18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	(SELECT DISTINCT CM_EQTY_INSTRMT_VK, INVSTMT_TYP,AS_AT_MTH FROM test.CM_EQTY_INSTRMT) AS INSTR, 
	test.CM_EQTY_PSTN PSTN 

WHERE 
	INSTR.AS_AT_MTH =  &AS_AT_MTH 
	AND PSTN.AS_AT_MTH =  &AS_AT_MTH 
	AND INSTR.CM_EQTY_INSTRMT_VK=PSTN.CM_EQTY_INSTRMT_VK 
	AND INVSTMT_TYP='001'  
	AND PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM  test.CM_EQTY_PSTN) 

GROUP BY 
	1,2,3

/*********************************************************************/
/*                         Equity - END                          	*/
/*******************************************************************/ 

;

QUIT;



PROC SQL ;

/*Convert . to ''*/
OPTIONS MISSING='';

/*Create Temp work table*/
CREATE TABLE WORK.TEMP6B  AS 



	/* Summary of all the data from  all the Generic Views and the  Summary Views  */


/*********************************************************************/
/*                          GENERIC TBL - START               		*/
/*******************************************************************/


SELECT  
	'01 - GENERIC TBL' AS TBL_NM,
	CASE SM_SEC_TYPE WHEN 'FXFWRD' THEN 'FX' WHEN 'FXSPOT' THEN 'FX' WHEN 'REIT' THEN 'PROPERTY' ELSE SM_SEC_GROUP END AS INVESTMENT_TYPE, 
	COUNT(*) AS  NO_OF_RECORDS, 
	PUT(SUM(X_SOLVENCY_II_VALUE),18.5) AS SOLII_VAL , 
	PUT(SUM(MKT_VAL),18.5) AS MKT_VAL, 
	PUT(CASE WHEN CALCULATED INVESTMENT_TYPE = 'EQUITY' THEN SUM(PAR_AMT) ELSE SUM(PRNCPL_AMT) END,18.5) AS PRNCPL_AMT, 
	PUT(SUM(BOOK_COST),18.5) AS BOOK_VAL
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_INSTRMT 

WHERE 
	AS_AT_MTH = &AS_AT_MTH 
	AND PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM  test.CM_INSTRMT)  

GROUP BY 
	INVESTMENT_TYPE 

/*********************************************************************/
/*                          GENERIC TBL - END               		*/
/*******************************************************************/

	UNION ALL

/*********************************************************************/
/*                          SUMMARY TBL - START               		*/
/*******************************************************************/

SELECT

	'02 - SUMMARY TBL',
	CASE 
		WHEN UPCASE(I_T_INV_CLS_CATEGORY) IN  ('FX FORWARD','EXCLUDE') AND UPCASE(CM_INV_CLASS_2) IN ('DERIVATIVES','') AND UPCASE(X_PAM_GL_GRP) = 'FORWARDS' THEN 'FX' 
		WHEN UPCASE(I_T_INV_CLS_CATEGORY) = 'PROPERTY' THEN 'PROPERTY' 
	ELSE SM_SEC_GROUP END AS INVSTMT_TYP,

	SUM(INVESTMENT_CNT),
	PUT(SUM(SOLVENCY_II_VALUE_AMT),18.5), 
	PUT(SUM(MKT_VALUE_AMT),18.5),
	PUT(SUM(FACE_VALUE_AMT),18.5), 
	PUT(SUM(BOOK_VALUE_AMT),18.5) 
	, PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

FROM 
	test.CM_INSTRMT_SMRY

WHERE 
	AS_AT_MTH = &AS_AT_MTH  
	AND PPN_DTTM = (SELECT MAX(PPN_DTTM) FROM test.CM_INSTRMT_SMRY) 

GROUP BY 
	INVSTMT_TYP	

/*********************************************************************/
/*                          SUMMARY TBL - END               		*/
/*******************************************************************/

;

QUIT;