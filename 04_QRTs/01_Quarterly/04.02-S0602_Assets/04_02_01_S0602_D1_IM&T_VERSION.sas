
PROC SQL ;

	CREATE TABLE WORK.S0602_D1_IMT  AS 

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

			, '-' AS C0080

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

			, CASE 
				WHEN A16 = '6' THEN A22BRS
				ELSE COALESCE(A22PAM,A22BRS,'0.00')
			  END AS C0130

			, COALESCE(A22APAM,A22ABRS,'0.00') AS C0140

			, CASE 
				WHEN  A24 = '1' THEN '1 - quoted market price in active markets for the same assets' 
				WHEN  A24 = '2' THEN '2 - quoted market price in active markets for similar assets'
				WHEN  A24 = '3' THEN '3 - alternative valuation methods' 
				WHEN  A24 = '5' THEN '5 - IFRS equity methods' 
				ELSE 'CHECK_EIOPA_CD' END AS C0150

			, COALESCE(A25PAM,A25BRS,'0.00') AS C0160

			, A26FIN_SDW AS C0170 FORMAT=21.2 

			, COALESCE(A30PAM,A30BRS) AS C0180 FORMAT=18.2
		
			/****************************************************************************/
			/****************************************************************************/
										, '' AS END_PART1
			/********************************PART 1 - END*******************************/
			/**************************************************************************/

			/****************************************************************************/
			/********************************PART 2 - START*****************************/
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

			, CASE 
				WHEN C0292 = '1' THEN '1 - CIUs for which a full look through'
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
				WHEN A16 = '2' THEN '2 - Non-controlled participation in a related insurance and reinsurance undertaking under method 1 :NCP1'
				WHEN A16 = '6' THEN '6 - Participation in other strategic related undertaking under method 1 : YGS' 
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
													WHEN A18 =  'S_P' THEN  'Standard & Poor'||"'"||'s'
													WHEN A18 =  'MDY' THEN  'Moody'||"'"||'s'
													WHEN A18 =  'FIT' THEN  'Fitch'		
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

			, COALESCE(A23APAM,A23ABRS) AS C0380
	
			, A28 AS C0390

		
			/****************************************************************************/
			/****************************************************************************/
										, '' AS END_PART2
			/********************************PART 2 - END*******************************/
			/**************************************************************************/


			/********************************INTERNAL COLUMNS - START********************/
			/**************************************************************************/
			, INT1

			, INT1A

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

			, SM_SEC_TYPE

			, INT9

			, INT10

			, SOURCE_SYSTEM_CD

			, A31_TRUE AS A31

			, CASE 
				WHEN A33_TRUE = '1' THEN  'LEI'
				WHEN A33_TRUE = '2' THEN  'SC' 
				WHEN A33_TRUE = '9' OR A33 = '-' OR A33 = '' THEN  'None'
				WHEN A33_TRUE = 'Not Applicable - CIC' THEN 'Not Applicable - CIC'
				ELSE  'CHECK X_EIOPA_CD'
			  END AS A33

			, A32_TRUE AS A32

			, CASE 
				WHEN A33GROUP_TRUE = '1' THEN  'LEI'
				WHEN A33GROUP_TRUE = '2' THEN  'SC' 
				WHEN A33GROUP_TRUE = '9' OR A33 = '-' OR A33 = '' THEN  'None'
				WHEN A33GROUP_TRUE = 'Not Applicable - CIC' THEN 'Not Applicable - CIC'
				ELSE  'CHECK X_EIOPA_CD'
			  END AS A33GROUP

			, CUSIP

			, SM_SEC_GROUP
			/********************************INTERNAL COLUMNS - END********************/
			/**************************************************************************/

			, CASE 
					WHEN SUBSTR(A15, 3, 1) IN ('1','2','5','6','7','8') 
							THEN ( ( ( INPUT (CALCULATED C0380 ,  21.4 ) / 100 ) * INPUT ( CALCULATED C0140 ,  21.2) ) +  CALCULATED C0180 ) - C0170 
					WHEN SUBSTR(A15, 3, 1) IN ('3','4') 
							THEN ( ( INPUT ( CALCULATED C0130 ,  21.4 ) * ( INPUT (CALCULATED C0370 ,   21.2) / 100 ) ) +  CALCULATED C0180 ) - C0170 
					ELSE 0.00
			  END AS INTERNAL_CHECK_DIFF FORMAT =  21.4
								

		FROM 
			WORK.S0602_D1_BASE

		ORDER BY 
			INT21
			,C0290
			,C0040 
			,C0010

		; 

QUIT;