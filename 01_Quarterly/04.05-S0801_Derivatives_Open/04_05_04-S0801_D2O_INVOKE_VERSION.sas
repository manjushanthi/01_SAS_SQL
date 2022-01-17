
PROC SQL ;

	CREATE TABLE WORK.S0801_D2o_INVOKE_VERSION AS 

	SELECT 

		/*************************FOR GROUP REPORTING***************************/
		CASE 
			WHEN ENTITY_LEI_STATUS = '1' THEN 'LEI/' 
			ELSE 'SC/' 
		END||ENTITY_LEI_CD AS C0020
		/*************************FOR GROUP REPORTING***************************/


		, CASE  
			 WHEN X_RPT_ID_TYPE_OVRD = '1' THEN 'ISIN/'
			 WHEN X_RPT_ID_TYPE_OVRD = '2' THEN 'CUSIP/'
			 WHEN X_RPT_ID_TYPE_OVRD = '3' THEN 'SEDOL/'
			 WHEN X_RPT_ID_TYPE_OVRD = '4' THEN 'WKN/'
			 WHEN X_RPT_ID_TYPE_OVRD = '5' THEN 'BT/'
			 WHEN X_RPT_ID_TYPE_OVRD = '6' THEN 'BBGID/'
			 WHEN X_RPT_ID_TYPE_OVRD = '7' THEN 'RIC/'
			 WHEN X_RPT_ID_TYPE_OVRD = '8' THEN 'FIGI/'
			 WHEN X_RPT_ID_TYPE_OVRD = '9' THEN 'OCANNA/'
			 WHEN X_RPT_ID_TYPE_OVRD = '99' THEN 'CAU/INST/'
			 ELSE 'CHECK X_EIOPA_CODE'
		 END||CASE 
				WHEN SUBSTR(TRIM(A11),3,1) = 'E' THEN INT14 
				ELSE A4 
		  	  END AS C0040
	
		, CASE 
			 WHEN A2='Not Ring Fenced' THEN '' 
			 ELSE A2 
           END AS C0070

		, CASE  
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '1' THEN 'ISIN/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '2' THEN 'CUSIP/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '3' THEN 'SEDOL/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '4' THEN 'WKN/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '5' THEN 'BT/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '6' THEN 'BBGID/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '7' THEN 'RIC/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '8' THEN 'FIGI/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '9' THEN 'OCANNA/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '99' AND TRIM(A9) NOT LIKE 'Multiple%' THEN 'CAU/INST/'
			 WHEN A9 = 'Multiple assets liabilities' OR A9 =  'Multiple assets/liabilities' THEN 'CAU/'
			 WHEN X_ASSET_LIABILITY_DRVT_ID = '' AND A9 = '-' THEN ''
			 ELSE 'CHECK X_EIOPA_CODE'
		   END||CASE 
				   WHEN TRIM(A9) LIKE 'Multiple%' THEN 'Multiple assets/liabilities' 
				   ELSE 
					   CASE 
						    WHEN A9 ='-' THEN '' 
						    ELSE A9 
				 	   END 
			     END AS C0090	

		/*************************FOR GROUP REPORTING***************************/
		, A50 AS C0010
		/*************************FOR GROUP REPORTING***************************/

		, A1 AS C0060

		, A3 AS C0080

		, A13 AS C0110

		, CASE 
				WHEN A14 = 'Not Applicable - CIC' THEN ''
				ELSE A14 
		  END AS C0120 

/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
		/* Use the d20 merge specific calculation for NOTIONAL AMOUNT   */	
		, SUM(
			  INPUT(
					CASE WHEN SUBSTR(TRIM(A11),3,1) = 'E' THEN PUT(A15_D2o_MERGE,18.2)
						 ELSE PUT(A15,18.2)
					END
				    ,18.2)
			  )AS C0130
/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
		/* Use the d20 merge specific calculation for LONG_SHORT POSITION */
		, CASE 
				WHEN SUBSTR(TRIM(A11),3,1) = 'E' THEN ''
				ELSE A16_D2o_MERGE					
		   END AS C0140
/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

		, CASE WHEN A17 = 'Not Applicable - CIC' THEN ''
			   ELSE A17 
		  END AS C0150 

		, CASE WHEN C0160 = 'Not Applicable - CIC' THEN ''
			   ELSE C0160 
		  END AS C0160 
	
		, A19 AS C0170 
		
		, CASE WHEN A20 = 'Not Applicable - CIC'  THEN ''
				ELSE A20
		  END AS C0180

		, CASE WHEN A32 = 'Not Applicable - CIC'  THEN ''
				ELSE A32
		  END AS C0190

		, CASE WHEN A22 = 'Not Applicable - CIC'  THEN ''
				ELSE A22
		  END AS C0200

		, CASE WHEN A23 = 'Not Applicable - CIC'  THEN ''
				ELSE A23
		  END AS C0210

		, A26 AS C0220

/*************************************** Required for D2o Merge aka D2o new rules - START **********************/ 
	/* Use the d20 merge specific MAPPING FOR MOD DUR , changed from EFF_DUR to MOD_DUR TO BOTH swaps and FX  */
		, INPUT(A33_D2O_MERGE,10.7) AS C0230
/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

		, SUM(A28FIN) AS C0240FIN FORMAT=21.2

		, A29 AS C0250

/**************************************************************************************************************************/
/**************************************************************************************************************************/
													,'' AS END_PART_1
/**************************************************************************************************************************/
/**************************************************************************************************************************/



	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
		  /*USE PARENT_ID FOR FX'S FOR D2O_MERGE*/
		, CASE  
			 WHEN X_RPT_ID_TYPE_OVRD = '1' THEN 'ISIN/'
			 WHEN X_RPT_ID_TYPE_OVRD = '2' THEN 'CUSIP/'
			 WHEN X_RPT_ID_TYPE_OVRD = '3' THEN 'SEDOL/'
			 WHEN X_RPT_ID_TYPE_OVRD = '4' THEN 'WKN/'
			 WHEN X_RPT_ID_TYPE_OVRD = '5' THEN 'BT/'
			 WHEN X_RPT_ID_TYPE_OVRD = '6' THEN 'BBGID/'
			 WHEN X_RPT_ID_TYPE_OVRD = '7' THEN 'RIC/'
			 WHEN X_RPT_ID_TYPE_OVRD = '8' THEN 'FIGI/'
			 WHEN X_RPT_ID_TYPE_OVRD = '9' THEN 'OCANNA/'
			 WHEN X_RPT_ID_TYPE_OVRD = '99' THEN 'CAU/INST/'
			 ELSE 'CHECK X_EIOPA_CODE'
		 END||CASE 
				WHEN SUBSTR(TRIM(A11),3,1) = 'E' THEN INT14 
				ELSE A4 
		  	  END AS C0040_P2
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

		, A6 AS C0260


		, CASE 
		     WHEN A38  =   '1' THEN 'LEI/'||TRIM(A36) 
			 ELSE 'None'
		  END AS C0270

		, A34 AS C0290

		, CASE 	
			WHEN A35 =  'S_P' THEN  'S&P Global Ratings Europe Limited (LEI code:5493008B2TU3S6QE1E12)'
			WHEN A35 =  'MDY' THEN 'Moody'||'’'||'s Investors Service Ltd (LEI code: 549300SM89WABHDNJ349)' 
			WHEN A35 =  'FIT' THEN  'Fitch Ratings Limited (LEI code: 2138009F8YAHVC8W3Q52)'		
			ELSE 'NR'			
		  END AS C0300

		, C0310

		, COALESCE(X_INTERNAL_RATING,'') AS C0320
				 
		, A7 AS C0330
		
		, CASE 
		     WHEN A38GRP  =   '1' THEN 'LEI/'||TRIM(A37) 
			 ELSE 'None'
		  END AS C0340

	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
		/* Use the D2o merge specific asset desc */
		, CASE 
			WHEN SUBSTR(TRIM(A11),3,1) = 'E' THEN A8_D2O_MERGE
			ELSE A8 
		  END AS C0360 LENGTH=500
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
		/* Use the D2o merge specific BUY CURRENCY CD ALONE */
		, CASE 
			WHEN SUBSTR(TRIM(A11),3,1) = 'E' THEN A10_D2O_MERGE
			ELSE A10 
		  END AS C0370
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

		, A11 AS C0380

	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
		/* Use the D2o merge specific TRIGGER VALUE */
		, CASE 	WHEN A21_D2O_MERGE = 'NOT APPLICABLE - CIC' THEN ''
				ELSE A21_D2O_MERGE
		  END AS C0390
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

		, CASE 
	        WHEN A31 = '-' THEN  '6' 
			ELSE 'CHECK X_EIOPA_CODE'
		  END AS C0400


		, CASE 
			WHEN A24 = 'Not Applicable - CIC' THEN ''
			ELSE A24
		  END AS C0410

		,  CASE 
			WHEN A25 = 'Not Applicable - CIC' THEN ''
			ELSE A25
		  END AS C0420

		, A27 AS C0430

/**************************************************************************************************************************/
/**************************************************************************************************************************/
													,'' AS END_PART_2
/**************************************************************************************************************************/
/**************************************************************************************************************************/

		/* ,INT1 - Consolidate at a non portfolio level */
		,INT5
		,INT14

	FROM 
		WORK.S0801_D2O_IMT_BASE

	GROUP BY 
			
			 C0020
			, C0040
			, C0070
			, C0090
			, C0010
			, C0060
			, C0080
			, C0110
			, C0120
			, C0140
			, C0150
			, C0160
			, C0170
			, C0180
			, C0190
			, C0200
			, C0210
			, C0220
			, C0230
			, C0250
			, END_PART_1
			, C0040_P2
			, C0260
			, C0270
			, C0290
			, C0300
			, C0310
			, C0320
			, C0330
			, C0340
			, C0360
			, C0370
			, C0380
			, C0390
			, C0400
			, C0410
			, C0420
			, C0430
			, END_PART_2
			, INT5
			, INT14	

	ORDER BY 																															
			C0380																													
			,C0040 																														
			,C0010   
		;          
QUIT;

