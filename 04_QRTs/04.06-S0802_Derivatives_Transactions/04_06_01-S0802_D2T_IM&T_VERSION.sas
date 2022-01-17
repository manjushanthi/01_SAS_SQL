/*   
SL No		- 04.06.01
Name 		- 01_D2T_Report_V1 - For IM&T - New FX Rules.sql
Description	- Business Version of QRT's - S0802 - D2T - New Logic
Frequency 	- Quarterly
Business 	- IM&T
Recepient 	- Christina Oikonomou , Thomas Wear , Wayne Chapman	
*/

/* 
Straight forward extract from Input File - DC184_CLOSED_DERIVATIVE_TRANSACTIONS MMM-YY.xls
Only One table Involved - X_CLOSED_DRVTS_TRANS
Also Included the Validations Part
*/

PROC SQL;

	OPTIONS MISSING='';
	/*Create Temp table to load the extracted Data*/
	CREATE TABLE WORK.S0802_D2T_IMT AS 

	SELECT 

		/****************************************** PART 1 START **********************************/
		ENTITY_NAME AS C0010
		, ENTITY_LEI_CD AS C0020

		, CASE 
			WHEN ENTITY_LEI_STATUS = '1' THEN ('1 - LEI') 
			ELSE ENTITY_LEI_STATUS 
		  END AS C0030

		, DRVT_ID AS C0040

		, CASE 
			WHEN DRVT_ID_TYPE = '99' THEN '99 - Code attributed by the undertaking' 
			ELSE '1 - ISO/6166 for ISIN'  
		  END AS C0050

		, CASE 
			WHEN PORTFOLIO_CLASSIFICATION = '6' THEN '6 - General ' 
			ELSE PORTFOLIO_CLASSIFICATION 
		END  AS C0060
				
		, CASE 
			WHEN FUND_NUMBER IS NULL OR FUND_NUMBER = '' THEN 'Not Ring Fenced' 
			ELSE FUND_NUMBER 
		END  AS C0070 

		, CASE 
			WHEN UNIT_INDEX_LINKED = '2' THEN '2 - Neither unit-linked nor index-linked' 
			WHEN UNIT_INDEX_LINKED = '1' THEN '1- Unit-linked or index-linked'
			ELSE UNIT_INDEX_LINKED 
		END AS C0080

		, ASSET_LIAB_DRVT_ID AS C0090
		 
		, CASE WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '99' THEN '99 - Code attributed by the undertaking' 
			WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '1'  THEN  '1 - ISO/6166 for ISIN'  
			ELSE '-'
		END AS C0100
		 
		,CASE 
			WHEN DRVTS_CD = '1' THEN '1 - Micro hedge' 
			WHEN DRVTS_CD = '2' THEN '2 - Macro hedge' 
			ELSE '-' 
		END AS C0110

		, NOTIONAL_AMT AS C0120 FORMAT = COMMA21.2

		, 'Not - Applicable - CIC' AS C0130
		 
		,CASE 
			WHEN SUBSTR(CIC,3,1) IN ('A' , 'E') THEN 'Not - Applicable - CIC'
			ELSE PUT(PREMIUM_PAID,COMMA18.2) 
		END AS C0140
		 
		,CASE 
			WHEN SUBSTR(CIC,3,1) IN ('A' , 'E') THEN 'Not - Applicable - CIC'
			ELSE PUT(PREMIUM_RCVD,COMMA18.2) 
			END 
		AS C0150

		, NET_GAIN_LOSS AS C0160 FORMAT = COMMA21.2

		, NO_OF_CONTRACTS AS C0170
		 
		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('D','E','F')  THEN 'NOT APPLICABLE - CIC'                                                                                                                            
			WHEN CONTRACT_DIMENSION IS NULL THEN '-'                                                                                                         
			ELSE PUT(CONTRACT_DIMENSION,?BEST10.) 
		  END AS C0180
		 
		, CASE 
			WHEN UNWIND_MAX_LOSS IS NULL THEN '-' 
			ELSE PUT(UNWIND_MAX_LOSS,COMMA18.2) 
		  END AS C0190
		 
		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('D') THEN PUT(PAY_LEG_AMT,COMMA21.2)
			ELSE  'NOT APPLICABLE - CIC'        
		 END AS  C0200 
		 
		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('D') THEN PUT(REC_LEG_AMT,COMMA21.2)
			ELSE  'NOT APPLICABLE - CIC'        
		  END AS  C0210

		, PUT(TRADE_DT,DDMMYY10.) AS  C0220 

		, NET_MKT AS C0230 FORMAT = COMMA21.2

		, '' AS END_PART1
	/****************************************** PART 1 END *************************************/

	/****************************************** PART 2 START **********************************/

		, DRVT_ID AS P2_C0040

		, CASE 
			WHEN DRVT_ID_TYPE = '99' THEN '99 - Code attributed by the undertaking' 
			ELSE '1 - ISO/6166 for ISIN'  
		  END AS P2_C0050

		, COUNTERPARTY_NM AS C0240

		, CASE 
			WHEN COUNTERPARTY_LEI_STATUS = '2' THEN '' 
			ELSE COUNTERPARTY_LEI_CD 
		  END AS C0250
			
		, CASE
			WHEN COUNTERPARTY_LEI_STATUS = '1' THEN '1 - LEI' 
			WHEN COUNTERPARTY_LEI_STATUS = '9' THEN '9 - None'
				WHEN COUNTERPARTY_LEI_STATUS = '2' THEN '9 - None'
				ELSE COUNTERPARTY_LEI_STATUS 
		  END AS C0260

		, COUNTERPARTY_GRP_NM AS C0270

		, CASE 
			WHEN COUNTERPARTY_GRP_LEI_STATUS = '2' THEN '' 
			ELSE COUNTERPARTY_GRP_LEI_CD 
		  END AS C0280
	 
		, CASE 
			WHEN COUNTERPARTY_GRP_LEI_STATUS = '1' THEN '1 - LEI' 
			WHEN COUNTERPARTY_GRP_LEI_STATUS = '9' THEN '9 - None'
			WHEN COUNTERPARTY_GRP_LEI_STATUS = '2' THEN '9 - None'
			ELSE  COUNTERPARTY_GRP_LEI_STATUS
		  END AS C0290

		, SHORT_STD_DESC AS C0300 
		, CURRENCY_CD AS C0310
		, CIC AS C0320
		, TRIGGER_VALUE AS C0330

		, CASE 
			WHEN UNWIND_TRIGGER = '6' THEN '6 - Other events not covered by the previous options'
			ELSE UNWIND_TRIGGER 
		  END AS C0340

		, 'NOT APPLICABLE - CIC' AS  C0350 
		, 'NOT APPLICABLE - CIC' AS  C0360
		,  PUT(MATURITY_DT,DDMMYY10.) AS C0370  

	/****************************************** PART 2 END **********************************/

	FROM 
		test.X_CLOSED_DRVTS_TRANS  D2T

	WHERE                 
		DATEPART(D2T.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
		AND DATEPART(D2T.VALID_TO_DTTM) > &AS_AT_MTH                                                                                                                           
		AND D2T.ASOF_DATE = &AS_AT_MTH

	ORDER BY 
		C0320
		, SUBSTR(C0040,1,8)
		, C0130;
QUIT;