%LET ENTITY_NAME ='U K Insurance Limited'; /* 'U K Insurance Limited'   'Churchill Insurance Company Limited'   */

PROC SQL ;

	CREATE TABLE WORK.S0602_D1_IMT_CON_SOLO  AS 

		SELECT 

			/****************************************************************************/
			/********************************PART 1 - START*****************************/
			/**************************************************************************/

			A50 AS C0010

			, ENTITY_LEI_CD AS C0020

			, CASE 	
				WHEN ENTITY_LEI_STATUS = '1' THEN '1 - LEI' 
				WHEN ENTITY_LEI_STATUS = '2' THEN '2 - Specific Code'
				ELSE '9 - None' 
			  END AS C0030

			, A4 AS C0040

			, CASE 
				WHEN A5 = 'ISIN' THEN '1 - ISO/6166 for ISIN' 
				WHEN A5 = 'CUSIP' THEN '2 - CUSIP '
				WHEN A5 = 'UNDERTAKING' THEN  '99 - Code attributed by the undertaking' 
				ELSE 'CHECK X_EIOPA_CD'       
			  END AS C0050

			, CASE 
				WHEN A1 = '1' THEN  '1 - Life' 			
				WHEN A1 = '2' THEN  '2 - Non-life' 			
				WHEN A1 = '3' THEN  '3 - Ring fenced funds' 			
				WHEN A1 = '4' THEN  '4 - Other internal fund' 			
				WHEN A1 = '5' THEN  '5 - Shareholders funds' 			
				WHEN A1 = '6' THEN  '6 - General' 				
				ELSE 'CHECK X_EIOPA_CODE'
			  END AS C0060
		
			, A2 AS C0070

			, '' AS C0080

			, CASE 
				WHEN A3='N' THEN '2 - Neither unit-linked nor index-linked'
				ELSE '1 - Unit-linked or index-linked' 
			  END AS C0090

			, CASE 
				WHEN A6 = '9' THEN '9 - Not collateral'
				WHEN A6 = '1' THEN '1 - Assets in the balance sheet that are collateral pledged'
				ELSE 'CHECK X_EIOPA_CODE'
			  END AS C0100

			, A12 AS C0110

			, CUSTODIAN AS C0120

			, SUM (	INPUT( (CASE 
							WHEN  	(
									CASE 
										WHEN A16 = '6' THEN A22BRS
										ELSE COALESCE(A22PAM,A22BRS,'0.00')
						  			END 
									) = 'Not Applicable - CIC'
							THEN ''
							ELSE (
									CASE 
										WHEN A16 = '6' THEN A22BRS
										ELSE COALESCE(A22PAM,A22BRS,'')
						  			END 
								  )
						 END) , 21.2 ) ) AS C0130 FORMAT=21.2 

			
			, SUM( INPUT( (CASE 
							WHEN COALESCE(A22APAM,A22ABRS,'0.00') = 'Not Applicable - CIC'	THEN ''
							ELSE COALESCE(A22APAM,A22ABRS,'')
						  END) , 21.2 ) ) AS C0140 FORMAT=21.2

			, CASE 
				WHEN  A24 = '1' THEN '1 - quoted market price in active markets for the same assets' 
				WHEN  A24 = '2' THEN '2 - quoted market price in active markets for similar assets'
				WHEN  A24 = '3' THEN '3 - alternative valuation methods' 
				WHEN  A24 = '5' THEN '5 - IFRS equity methods' 
				ELSE 'CHECK_EIOPA_CD' END AS C0150

			, INPUT( ( CASE 
						 WHEN PUT(SUM(C0160_CALC*A26FIN_SDW)/SUM(A26FIN_SDW),12.4) = '0.00' THEN ''
						 ELSE PUT(SUM(C0160_CALC*A26FIN_SDW)/SUM(A26FIN_SDW),12.4)
					   END ), 12.4 ) AS C0160 FORMAT 12.4

			, SUM ( A26FIN_SDW ) AS C0170  FORMAT=21.2

			, SUM ( COALESCE(A30PAM,A30BRS) ) AS C0180 FORMAT=18.2

			/****************************************************************************/
			/****************************************************************************/
										, '' AS END_PART1
			/********************************PART 1 - END*******************************/
			/**************************************************************************/

			, A4 AS C0040_P2

			, CASE 
				WHEN A5 = 'ISIN' THEN '1 - ISO/6166 for ISIN' 
				WHEN A5 = 'CUSIP' THEN '2 - CUSIP '
				WHEN A5 = 'UNDERTAKING' THEN  '99 - Code attributed by the undertaking' 
				ELSE 'CHECK X_EIOPA_CD'       
			  END AS C0050_P2

			, A7 AS C0190

			, A8 AS C0200

			, A31 AS C0210

			, CASE 
				WHEN A33 = '1' THEN  '1 - LEI'
				WHEN A33 = '2' THEN  '9 - None' 
				WHEN A33 = '9' OR A33 = '-' OR A33 = '' THEN  '9 - None'
				WHEN A33 = 'Not Applicable - CIC' THEN 'Not Applicable - CIC'
				ELSE  'CHECK X_EIOPA_CD'
			  END AS C0220

			, A9 AS C0230

			, A10 AS C0240

			, A32 AS C0250

			, CASE 
				WHEN A33GROUP = '1' THEN  '1 - LEI'
				WHEN A33GROUP = '2' THEN  '9 - None' 
				WHEN A33GROUP = '9' OR A33 = '-' OR A33 = '' THEN  '9 - None'
				WHEN A33GROUP = 'Not Applicable - CIC' THEN 'Not Applicable - CIC'
				ELSE  'CHECK X_EIOPA_CD'
			  END AS C0260

			, A11 AS C0270

			, A13 AS C0280

			, A15 AS C0290

			, CASE /*Only applicable for Solo , not required for group reporting*/
				WHEN C0292 = '1' THEN '1 - CIUs for which a full look through is Applied'
				WHEN C0292 = 'Not Applicable - CIC' THEN 'Not Applicable - CIC'
				ELSE 'CHECK X_EIOPA_CD'
			  END AS C0292

			, CASE 
				WHEN C0300 = '1'  THEN '1 - Not an infrastructure investment'
				WHEN C0300 = '2'  THEN '2 - Infrastructure non-qualifying: Government Guarantee'
				WHEN C0300 = '3'  THEN '3 - Infrastructure non-qualifying: Government Supported'
				WHEN C0300 = '4'  THEN '4 - Infrastructure non-qualifying: Supranational Guarantee/Supported'
				WHEN C0300 = '9'  THEN '9 - Infrastructure non-qualifying: Other'
				WHEN C0300 = '12' THEN '12 - Infrastructure qualifying: Government Guarantee'
				WHEN C0300 = '13' THEN '13 - Infrastructure qualifying: Government Supported'
				WHEN C0300 = '14' THEN '14 - Infrastructure qualifying: Supranational Guarantee/Supported'
				WHEN C0300 = '19' THEN '19 - Infrastructure qualifying: Other'
				WHEN C0300 = '20' THEN '20 - European Long-Term Investment Fund'
				ELSE 'CHECK X_EIOPA_CD' 
			  END AS C0300

			, CASE 
				WHEN A16 = '1' THEN '1 - Not a participation'
				WHEN A16 IN ( '2' , '6') THEN '2 - Is a participation'
				ELSE  A16
			 END AS C0310 

			, CASE 
				WHEN X_INTERNAL_RATING = '' 					THEN A17
				WHEN X_INTERNAL_RATING = 'Not Applicable - CIC' THEN 'Not Applicable - CIC'
				ELSE ''
			  END AS C0320

			, CASE
				WHEN X_INTERNAL_RATING = '' THEN 
												CASE	
													WHEN A18 =  'S_P' THEN  'S&P Global Ratings Europe Limited (LEI code:5493008B2TU3S6QE1E12)'
													WHEN A18 =  'MDY' THEN  'Moody'||'’'||'s Investors Service Ltd (LEI code: 549300SM89WABHDNJ349)' 
													WHEN A18 =  'FIT' THEN  'Fitch Ratings Limited (LEI code: 2138009F8YAHVC8W3Q52)'		
													ELSE A18
												END
				WHEN  X_INTERNAL_RATING = 'Not Applicable - CIC' THEN 'Not Applicable - CIC'
				ELSE ''
			  END AS C0330

			, CASE 
				WHEN CALCULATED C0320 = '' THEN '9 – No rating available' 
				ELSE
					CASE
						WHEN X_INTERNAL_RATING = '' THEN
														CASE 
															WHEN SOLII_CREDIT_QUALITY = '0' THEN '0 - Credit quality step 0'
															WHEN SOLII_CREDIT_QUALITY = '1' THEN '1 - Credit quality step 1'
															WHEN SOLII_CREDIT_QUALITY = '2' THEN '2 - Credit quality step 2'
															WHEN SOLII_CREDIT_QUALITY = '3' THEN '3 - Credit quality step 3'
															WHEN SOLII_CREDIT_QUALITY = '4' THEN '4 - Credit quality step 4'
															WHEN SOLII_CREDIT_QUALITY = '5' THEN '5 - Credit quality step 5'
															WHEN SOLII_CREDIT_QUALITY = '6' THEN '6 - Credit quality step 6'
															WHEN SOLII_CREDIT_QUALITY = '9' THEN '9 – No rating available'														  
															ELSE SOLII_CREDIT_QUALITY
														END
						WHEN X_INTERNAL_RATING = 'Not Applicable - CIC' THEN 'Not Applicable - CIC'
					 	ELSE ''
					END
			  END AS C0340

			, X_INTERNAL_RATING AS C0350

			, A20 AS C0360

			, COALESCE(A23PAM,A23BRS) AS C0370

			, INPUT( (CASE WHEN  
						( AVG(
						 (CASE 
								WHEN COALESCE(A23APAM,A23ABRS) =  'Not Applicable - CIC' THEN 0 
								ELSE INPUT(COALESCE(A23APAM,A23ABRS),20.16)/100 
						  END))) = 0.000000000000 THEN 'Not Applicable - CIC' 
							ELSE PUT( (AVG(
						 (CASE 
								WHEN COALESCE(A23APAM,A23ABRS) =  'Not Applicable - CIC' THEN 0 
								ELSE INPUT(COALESCE(A23APAM,A23ABRS),20.16)/100 
					  		END))),20.16) 
					END),20.16) AS C0380 FORMAT=20.16

			, A28 AS C0390
			
			/****************************************************************************/
			/****************************************************************************/
										, '' AS END_PART2
			/********************************PART 2 - END*******************************/
			/**************************************************************************/


			/********************************INTERNAL COLUMNS - START********************/
			/**************************************************************************/

			, FIN_SOLII_CLS

			, SUBSTR(A15,3,1) AS INT2

			, SUBSTR(A15,3,2) AS INT21

			, INT2A
									
			, INT2B

			, INT3

			, INT4

			, INT5

			, INT6

			, INT7

			, INT9

			, INT10

			, SOURCE_SYSTEM_CD

		FROM 
			WORK.S0602_D1_BASE

		WHERE
			 A50 IN ('U K Insurance Limited - ROI Branch' , 'U K Insurance Limited')
			/*&ENTITY_NAME
			  A50 = 'Churchill Insurance Company Limited'  
			 'U K Insurance Limited' 'U K Insurance Limited - ROI Branch'*/

		GROUP BY 
			C0010
			, C0020
			, C0030
			, C0040
			, C0050
			, C0060
			, C0070
			, C0080
			, C0090
			, C0100
			, C0110
			, C0120
			, C0150
			, END_PART1
			, C0040_P2
			, C0050_P2
			, C0190
			, C0200
			, C0210
			, C0220
			, C0230
			, C0240
			, C0250
			, C0260
			, C0270
			, C0280
			, C0290
			, C0292
			, C0300
			, C0310 
			, C0320
			, C0330
			, C0340
			, C0350
			, C0360
			, C0370
			, C0390
			, END_PART2
			, FIN_SOLII_CLS
			, INT2
			, INT21
			, INT2A					
			, INT2B
			, INT3
			, INT4
			, INT5
			, INT6
			, INT7
			, INT9
			, INT10
			, SOURCE_SYSTEM_CD

		HAVING 
			SUM(A26FIN_SDW) <> 0 

/* DONT PUT ORDER WHEN THE COLUMN IS NOT IN SELECT */

		ORDER BY 
			INT21
			, C0290
			, C0040 
			, C0010;
QUIT;