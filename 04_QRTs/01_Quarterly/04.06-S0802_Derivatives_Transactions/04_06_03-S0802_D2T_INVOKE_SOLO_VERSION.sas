/*   
	SL No		- 04.06.03
	Name 		- 02_D2T_Report_V1 SOLO - For Invoke.sql
	Description	- Invoke Version of QRT's - S0802 - D2T - SOLO reporting - New Logic
	Frequency 	- Quarterly
	Business 	- IM&T / External Reporting
	Recepient 	- Christina Oikonomou , Thomas Wear , Wayne Chapman	, Peter Jackson , Thomas Curell
*/

		
/* 
	Straight forward extract from Input File - DC184_CLOSED_DERIVATIVE_TRANSACTIONS MMM-YY.xls
	Only One table Involved - X_CLOSED_DRVTS_TRANS
	Extract both Part A and Part B for Solo Invoke Extract
*/

PROC SQL;

/*Create Temp table to load the extracted Data*/

CREATE TABLE WORK.S0802_D2T_INVOKE_SOLO AS 

	SELECT 

	/****************************************** PART 1 START **********************************/ 		 

		 CASE  	
				WHEN DRVT_ID_TYPE = '1' THEN 'ISIN/'
				WHEN DRVT_ID_TYPE = '2' THEN 'CUSIP/'
				WHEN DRVT_ID_TYPE = '3' THEN 'SEDOL/'
				WHEN DRVT_ID_TYPE = '4' THEN 'WKN/'
				WHEN DRVT_ID_TYPE = '5' THEN 'BT/'
				WHEN DRVT_ID_TYPE = '6' THEN 'BBGID/'
				WHEN DRVT_ID_TYPE = '7' THEN 'RIC/'
				WHEN DRVT_ID_TYPE = '8' THEN 'FIGI/'
				WHEN DRVT_ID_TYPE = '9' THEN 'OCANNA/'
				WHEN DRVT_ID_TYPE = '99' THEN 'CAU/INST/'
				ELSE 'CHECK X_EIOPA_CODE'
			END||DRVT_ID AS C0040	

		, CASE WHEN FUND_NUMBER IS NULL OR FUND_NUMBER = '' THEN '' ELSE FUND_NUMBER END  AS C0070	
								
		, CASE  
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '1' THEN 'ISIN/'
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '2' THEN 'CUSIP/'
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '3' THEN 'SEDOL/'
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '4' THEN 'WKN/'
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '5' THEN 'BT/'
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '6' THEN 'BBGID/'
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '7' THEN 'RIC/'
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '8' THEN 'FIGI/'
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '9' THEN 'OCANNA/'
				WHEN ASSET_LIAB_DRVT_ID_TYPE_CD = '99' THEN 'CAU/'
				WHEN ASSET_LIAB_DRVT_ID = 'Multiple assets liabilities' OR ASSET_LIAB_DRVT_ID =  'Multiple assets/liabilities' THEN 'CAU/'
				ELSE 'CHECK X_EIOPA_CODE'
			END||CASE WHEN TRIM(ASSET_LIAB_DRVT_ID) LIKE 'Multiple%' THEN 'MAL' ELSE ASSET_LIAB_DRVT_ID END AS C0090
 
		 , PORTFOLIO_CLASSIFICATION AS C0060

		 , UNIT_INDEX_LINKED  AS C0080

		 , DRVTS_CD AS C0110

		 , NOTIONAL_AMT AS C0120 FORMAT = COMMA21.2

		 , '' AS C0130

		 , CASE 
				WHEN SUBSTR(CIC,3,1) IN ('A' , 'E') THEN ''
		 		WHEN PREMIUM_PAID IS NULL THEN ('0.0')
				ELSE PUT(PREMIUM_PAID,COMMA18.2) 
			END AS C0140

		 , CASE 
				WHEN SUBSTR(CIC,3,1) IN ('A' , 'E') THEN ''
		 		WHEN PREMIUM_RCVD IS NULL THEN ('0.0')
				ELSE PUT(PREMIUM_RCVD,COMMA18.2) 
			END AS C0150

		 , NET_GAIN_LOSS AS C0160 FORMAT = COMMA21.2

	     , NO_OF_CONTRACTS AS C0170 FORMAT = 3.0

	     , CASE 
				WHEN SUBSTR(CIC,3,1) IN ('D','E','F')  THEN ''                                                                                                                            
	            WHEN CONTRACT_DIMENSION IS NULL THEN ''                                                                                                         
	            ELSE PUT(CONTRACT_DIMENSION,?BEST10.) 
	       END AS C0180

		 , CASE 
				WHEN UNWIND_MAX_LOSS IS NULL THEN '' 
				ELSE PUT(UNWIND_MAX_LOSS,COMMA18.2) 
		   END AS C0190

		 , CASE 
				WHEN SUBSTR(CIC,3,1) IN ('D') THEN PUT(PAY_LEG_AMT,COMMA21.2)
	            ELSE  ''        
		   END AS  C0200 

	     , CASE WHEN SUBSTR(CIC,3,1) IN ('D') THEN PUT(REC_LEG_AMT,COMMA21.2)
	            ELSE  ''        
			END AS  C0210

		 , PUT(TRADE_DT,YYMMDD10.) AS  C0220 

		 , NET_MKT AS C0230 FORMAT = COMMA21.2
	                 
	     , '' AS END_PART1

		/****************************************** PART 1 END *************************************/ 

		/****************************************** PART 2 START **********************************/

		 , CASE  	
				WHEN DRVT_ID_TYPE = '1' THEN 'ISIN/'
				WHEN DRVT_ID_TYPE = '2' THEN 'CUSIP/'
				WHEN DRVT_ID_TYPE = '3' THEN 'SEDOL/'
				WHEN DRVT_ID_TYPE = '4' THEN 'WKN/'
				WHEN DRVT_ID_TYPE = '5' THEN 'BT/'
				WHEN DRVT_ID_TYPE = '6' THEN 'BBGID/'
				WHEN DRVT_ID_TYPE = '7' THEN 'RIC/'
				WHEN DRVT_ID_TYPE = '8' THEN 'FIGI/'
				WHEN DRVT_ID_TYPE = '9' THEN 'OCANNA/'
				WHEN DRVT_ID_TYPE = '99' THEN 'CAU/INST/'
				ELSE 'CHECK X_EIOPA_CODE'
			END||DRVT_ID AS P2_C0040

		 , COUNTERPARTY_NM AS C0240

		 , CASE 
				WHEN COUNTERPARTY_LEI_STATUS = '1' THEN 'LEI/'
				ELSE 'None' 
			END||CASE 
					WHEN COUNTERPARTY_LEI_STATUS <> '1' THEN '' 
					ELSE COUNTERPARTY_LEI_CD 
				 END AS C0250

		 , COUNTERPARTY_GRP_NM AS C0270

		 , CASE WHEN COUNTERPARTY_GRP_LEI_STATUS = '1' THEN 'LEI/'
						 ELSE 'None' END||CASE WHEN COUNTERPARTY_GRP_LEI_STATUS <> '1' THEN '' ELSE COUNTERPARTY_GRP_LEI_CD END AS C0280

	     , SHORT_STD_DESC AS C0300 
	 
	     , CURRENCY_CD AS C0310

	     , CIC AS C0320

	     , TRIGGER_VALUE AS C0330

		 , UNWIND_TRIGGER AS C0340

		 , CASE WHEN SUBSTR(CIC,3,2) IN ('D2','D3') THEN SWAP_DLVRD_CURRENCY_CD
				ELSE  '' 		
		   END AS C0350
				  
		 , CASE WHEN SUBSTR(CIC,3,2) IN ('D2','D3') THEN SWAP_RCVD_CURRENCY_CD
				ELSE  '' 		
			END AS C0360

		 ,  PUT(MATURITY_DT,YYMMDD10.) AS C0370  
	 
	FROM 
		test.X_CLOSED_DRVTS_TRANS  D2T
	                
	WHERE                 
		DATEPART(D2T.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
		AND DATEPART(D2T.VALID_TO_DTTM) > &AS_AT_MTH                                                                                                                           
		AND D2T.ASOF_DATE = &AS_AT_MTH
		AND ENTITY_NAME = 'U K Insurance Limited'	

	ORDER BY 
		C0320
		, SUBSTR(DRVT_ID,1,8)
		, C0130;

QUIT;