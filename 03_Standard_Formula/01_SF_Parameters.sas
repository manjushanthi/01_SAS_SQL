/*Step 1*/
/* Create Portfolio Table for SF */


PROC SQL ;

/*Create Temp table to load the extracted Data*/

CREATE TABLE WORK.SF_INVSTMT_PORTFOLIO AS 

	SELECT 
		XIP.ENTITY_NAME AS PORTF_NAME
		, XIP.PORTFOLIO_ID AS PORTF_LIST

		, CASE 
			WHEN XIP.ENTITY_NAME IN ('International','Overseas Consolidation / Adjustment Entity - Disposals Group') THEN 'N' 
			ELSE XIP.GROUP_PARTICIPATION_IND 
		  END AS FINANCE_GRP_CLASSIFICATION

		, CASE 
			WHEN XIP.ENTITY_NAME IN ('International','Overseas Consolidation / Adjustment Entity - Disposals Group','DLG Legal Services Limited') 
				THEN 'N'
			WHEN XIP.ENTITY_NAME IN ('U K Insurance Limited','DL Insurance Services Ltd','Direct Line Insurance Group plc','India NewCo','U K Insurance Limited - ROI Branch')  
				THEN 'Y' 
			ELSE 'N' 
		END AS SF_GRP_CLASSIFICATION

	FROM 
		test.X_INVESTMENT_PORTFOLIO XIP

	WHERE 
		 PUT(DATEPART(XIP.VALID_TO_DTTM),DATE9.) = '31DEC9999'

	ORDER BY 
		PORTF_NAME;

QUIT;
 
/*Step 2*/
/* Create valid Asset types - SM_SEC_TYPE AND SM_SEC_GROUP FOR SF */
PROC SQL ;

/*Create Temp table to load the extracted Data*/

CREATE TABLE WORK.SF_VALD_SM_SEC AS 

	SELECT 
		STC.SM_SEC_GROUP,
		STC.SM_SEC_TYPE

	FROM 
		test.X_INVST_CLASS_STC STC

	WHERE 
		 PUT(DATEPART(STC.VALID_TO_DTTM),DATE9.) = '31DEC9999'

 	ORDER BY 
 		STC.SM_SEC_GROUP;

QUIT;



/*Step 3*/
/* EXTRACT Current Quarter exchange rates SF */
PROC SQL ;

/*Create Temp table to load the extracted Data*/

CREATE TABLE WORK.SF_CURRQ_EXC_RATE AS 

	SELECT 
		EXCH.CURRENCY_CD
		,PUT(EXCH.I_T_CURRENCY_DT,DDMMYY10.) AS I_T_CURRENCY_DT
	 	,EXCH.I_T_CURRENCY_RATE

	FROM 
		test.X_I_T_INT_EXC_RATES EXCH

	WHERE 
		 EXCH.I_T_CURRENCY_DT = &AS_AT_MTH;

QUIT;
   

/*Step 4*/
/* EXTRACT Current CIC CATEGORIES FOR  SF */
PROC SQL ;

/*Create Temp table to load the extracted Data*/

CREATE TABLE WORK.SF_VALID_CIC AS 

	 SELECT 
		CIC.X_CIC_CD_LAST_2_CHAR	,	
		CIC.X_CIC_CATEGORY_CD ,	
		CIC.X_CIC_CATEGORY_NM,	
		CIC.X_CIC_SUB_CATEGORY_NM
	FROM 
		test.X_CIC_CATEGORY CIC
	ORDER BY 
		2,1; 
QUIT;
			
					