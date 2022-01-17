PROC SQL ;

OPTIONS MISSING='';

/*Create Temp table to load the extracted Data*/

	CREATE TABLE WORK.S1101_D6_IMT AS 

		SELECT 
				
			A4 AS C0040 LENGTH=50

			, CASE 
				WHEN A5 = 'UNDERTAKING' THEN '99 - Code attributed by the undertaking'	
				WHEN A5 = 'ISIN'  		THEN '1 - ISO/6166 for ISIN'	 
				WHEN A5 = 'CUSIP'  		THEN 'CUSIP'
				ELSE 'DATA QUALITY ISSUE'
			  END AS C0050

			, X_DEBTOR_NM AS C0060

			, X_DEBTOR_GRP_NM AS C0070

			, A12 AS C0080
		
			, COALESCE( A22PAM, A22BRS) AS C0090

			, COALESCE( A22APAM, A22ABRS) AS C0100

			, CASE 			
				WHEN A24 = '1' THEN '1 - quoted market price in active markets for the same assets'
				WHEN A24 = '2' THEN '2 - quoted market price in active markets for similar assets'
				WHEN A24 = '3' THEN '3 - alternative valuation methods'
				WHEN A24 = '5' THEN  '5 - IFRS equity methods'
				ELSE A24
			  END AS C0110

			, A26FIN_SDW AS C0120

			, COALESCE( A30PAM, A30BRS) AS C0130

			, CASE 
				WHEN  X_ASSET_PLEDGED_TYPE = 'X' THEN 'X - Derivatives' 
				ELSE X_ASSET_PLEDGED_TYPE 
			  END AS C0140

			, A7 AS C0150 LENGTH = 500

			, A8 AS C0160 LENGTH=100

			, A31 AS  C0170 LENGTH=50

  				/* 25/12/2021 - CURRENTLY ISSUE IN PROD FINANCIAL INSTRUMENT.X_LEI_CD  AND FINANCIAL INSTRUMENT X_LEI_STATUS
			   Issues in PROD in LEI  were status is set to 9 when the length of the LEI Code is set to 20 and a proper LEI
			   IMPACTING A31--> C0210 , A33 --> C0220 */
			 , CASE 
				WHEN A33 = '1' THEN '1 - LEI' 
				WHEN A33 = '2' THEN '2 - Specific Code'
				ELSE '9 - None' 
				END AS C0180 	LENGTH=50

			, A9 AS C0190 LENGTH=50

			, A10 AS C0200 LENGTH=100

			  /* 25/12/2021 - CURRENTLY ISSUE IN PROD FINANCIAL INSTRUMENT.X_ISSUER_GRP_LEI_CD  AND FINANCIAL INSTRUMENT X_ISSUER_GRP_LEI_STATUS 
			   Issues in PROD in LEI  were status is set to 9 when the length of the LEI Code is set to 20 and a proper LEI
			   IMPACTING A32--> C0250 , A33GROUP --> C0260 */ 
			 , A32 AS C0210 LENGTH=50

			 , CASE 
				WHEN A33GROUP = '1' THEN '1 - LEI' 
				WHEN A33GROUP = '2' THEN '2 - Specific Code'
				ELSE '9 - None'  
			   END AS C0220 LENGTH=50

	 		, A11 AS C0230

			, A13 AS C0240 LENGTH=50

			, A15 AS C0250

			, COALESCE( A23PAM, A23BRS) AS C0260

			, ( INPUT ( COALESCE( A23APAM, A23ABRS) , 10.6 )/100) AS C0270

			, A28 AS C0280

			, 'Direct Line Insurance Group plc'  AS GRP

			, '213800FF2R23ALJQOP04' AS GRP_LEI

			, '1 - LEI' AS GRP_LEI_CD

			,  INT1

			,  INT9

			,  INT10

			, SOURCE_SYSTEM_CD

		FROM 
			WORK.S1101_D6_BASE

		ORDER BY 
			C0250
			, C0040
		;

QUIT;
