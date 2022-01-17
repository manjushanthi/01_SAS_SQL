PROC SQL ;

	CREATE TABLE WORK.S0801_D2o_IMT_NEWRULES_FINAL AS 

	SELECT 

		A50 AS C0010

		, ENTITY_LEI_CD AS C0020

		, CASE 
			WHEN ENTITY_LEI_STATUS = '1' THEN '1 - LEI' 
			ELSE '9 - None' 
		  END AS C0030

	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
		  /*USE PARENT_ID FOR FX'S FOR D2O_MERGE*/
		, CASE 
			WHEN SUBSTR(TRIM(A11),3,1) = 'E' THEN INT14 
			ELSE A4 
		  END AS C0040 LENGTH=50
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

		, CASE  
			WHEN X_RPT_ID_TYPE_OVRD = '1' THEN '1 - ISO/6166 for ISIN'
			WHEN X_RPT_ID_TYPE_OVRD = '2' THEN '2 - CUSIP'
			WHEN X_RPT_ID_TYPE_OVRD = '3' THEN '3 - SEDOL'
			WHEN X_RPT_ID_TYPE_OVRD = '4' THEN '4 – WKN'
			WHEN X_RPT_ID_TYPE_OVRD = '5' THEN '5 - Bloomberg Ticker'
			WHEN X_RPT_ID_TYPE_OVRD = '6' THEN '6 - BBGID'
			WHEN X_RPT_ID_TYPE_OVRD = '7' THEN '7 - Reuters RIC'
			WHEN X_RPT_ID_TYPE_OVRD = '8' THEN '8 – FIGI'
			WHEN X_RPT_ID_TYPE_OVRD = '9' THEN '9 - Other code'
			WHEN X_RPT_ID_TYPE_OVRD = '99' THEN '99 - Code attributed by the undertaking'
			ELSE 'CHECK X_EIOPA_CODE'
		  END AS C0050  LENGTH = 50

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

		, CASE 
			WHEN A3 = '1' THEN '1 - Unit-linked or index-linked' 
			WHEN A3 = '2' THEN '2 - Neither unit-linked nor index-linked' 
			ELSE 'CHECK X_EIOPA_CODE'		
	      END AS C0080

		, CASE 
			WHEN TRIM(A9) LIKE 'Multiple%' THEN 'Multiple assets/liabilities' 
			ELSE A9 
		  END AS C0090

		, CASE  
			WHEN X_ASSET_LIABILITY_DRVT_ID = '1' THEN '1 - ISO/6166 for ISIN'
			WHEN X_ASSET_LIABILITY_DRVT_ID = '2' THEN '2 - CUSIP'
			WHEN X_ASSET_LIABILITY_DRVT_ID = '3' THEN '3 - SEDOL'
			WHEN X_ASSET_LIABILITY_DRVT_ID = '4' THEN '4 – WKN'
			WHEN X_ASSET_LIABILITY_DRVT_ID = '5' THEN '5 - Bloomberg Ticker'
			WHEN X_ASSET_LIABILITY_DRVT_ID = '6' THEN '6 - BBGID'
			WHEN X_ASSET_LIABILITY_DRVT_ID = '7' THEN '7 - Reuters RIC'
			WHEN X_ASSET_LIABILITY_DRVT_ID = '8' THEN '8 – FIGI'
			WHEN X_ASSET_LIABILITY_DRVT_ID = '9' THEN '9 - Other code'
			WHEN X_ASSET_LIABILITY_DRVT_ID = '99' THEN '99 - Code attributed by the undertaking'
			WHEN CALCULATED C0090 = 'Multiple assets liabilities' OR CALCULATED C0090 =  'Multiple assets/liabilities' THEN ''
			WHEN TRIM(A9) = '-' THEN '-'
			ELSE 'CHECK X_EIOPA_CODE'
		  END  AS C0100

		, CASE 	
			WHEN A13 = '1' THEN '1 - Micro hedge'
			WHEN A13 = '2' THEN '2 - Macro hedge'
			WHEN A13 = '3' THEN '3 - Matching assets and liabilities cash-flows used in the context of matching adjustment portfolios'
			WHEN A13 = '4' THEN '4 - Efficient portfolio management, other than “Matching assets and liabilities cash-flows used in the context of matching adjustment portfolios'
			ELSE 'CHECK X_EIOPA_CODE'			
		  END AS C0110

		, A14 AS C0120 

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
				WHEN SUBSTR(TRIM(A11),3,1) = 'E' THEN A16_D2o_MERGE
				ELSE 
					CASE 
						WHEN A16='3' THEN '3 - FX-FL: Deliver fixed-for-floating'
						WHEN A16='4' THEN '4 - FX-FX: Deliver fixed-for-fixed' 
						WHEN A16='5' THEN '5 - FL-FX: Deliver floating-for-fixed' 
						WHEN A16='6' THEN '6 - FL-FL: Deliver floating-for-floating'
						ELSE 'CHECK X_EIOPA_CODE'	
					END	
			END AS C0140 LENGTH=50 INFORMAT =$50.
/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

		, A17 AS C0150 

		, C0160 AS C0160
	
		, A19 AS C0170 
		
		, A20 AS C0180

		, A32 AS C0190

		, A22 AS C0200

		, A23 AS C0210

		, A26 AS C0220

/*************************************** Required for D2o Merge aka D2o new rules - START **********************/ 
	/* Use the d20 merge specific MAPPING FOR MOD DUR , changed from EFF_DUR to MOD_DUR TO BOTH swaps and FX  */
		, INPUT(A33_D2O_MERGE,10.7) AS C0230
/*************************************** Required for D2o Merge aka D2o new rules - END **********************/
		, SUM(A28FIN) AS C0240FIN FORMAT=21.2

		, CASE 
		    WHEN A29 = '1' THEN '1 - quoted market price in active markets for the same assets or liabilities'
		    WHEN A29 = '2' THEN '2 - quoted market price in active markets for similar assets or liabilities'
		    WHEN A29 = '3' THEN '3 - alternative valuation methods'
		    WHEN A29 = '6' THEN '6 - Market valuation according to article 9(4) of Delegated Regulation 2015/35'
		    ELSE  'CHECK X_EIOPA_CODE'	 
		  END AS C0250

/**************************************************************************************************************************/
/**************************************************************************************************************************/
													,'' AS END_PART_1
/**************************************************************************************************************************/
/**************************************************************************************************************************/



	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
		  /*USE PARENT_ID FOR FX'S FOR D2O_MERGE*/
		, CASE 
			WHEN SUBSTR(TRIM(A11),3,1) = 'E' THEN INT14 
			ELSE A4 
		  END AS C0040_P2 LENGTH=50
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

		, CASE  
			WHEN X_RPT_ID_TYPE_OVRD = '1' THEN '1 - ISO/6166 for ISIN'
			WHEN X_RPT_ID_TYPE_OVRD = '2' THEN '2 - CUSIP'
			WHEN X_RPT_ID_TYPE_OVRD = '3' THEN '3 - SEDOL'
			WHEN X_RPT_ID_TYPE_OVRD = '4' THEN '4 – WKN'
			WHEN X_RPT_ID_TYPE_OVRD = '5' THEN '5 - Bloomberg Ticker'
			WHEN X_RPT_ID_TYPE_OVRD = '6' THEN '6 - BBGID'
			WHEN X_RPT_ID_TYPE_OVRD = '7' THEN '7 - Reuters RIC'
			WHEN X_RPT_ID_TYPE_OVRD = '8' THEN '8 – FIGI'
			WHEN X_RPT_ID_TYPE_OVRD = '9' THEN '9 - Other code'
			WHEN X_RPT_ID_TYPE_OVRD = '99' THEN '99 - Code attributed by the undertaking'
			ELSE 'CHECK X_EIOPA_CODE'
		  END AS C0050_P2 LENGTH = 50

		, A6 AS C0260

		, A36 AS C0270

		, CASE 
			WHEN A38 = '1'  THEN  '1 - LEI' 
			ELSE '9 - None' 
		  END AS C0280

		, A34 AS C0290

		, CASE 	
			WHEN A35 =  'S_P' THEN  'S&P Global Ratings Europe Limited (LEI code:5493008B2TU3S6QE1E12)'
			WHEN A35 =  'MDY' THEN 'Moody'||'’'||'s Investors Service Ltd (LEI code: 549300SM89WABHDNJ349)' 
			WHEN A35 =  'FIT' THEN  'Fitch Ratings Limited (LEI code: 2138009F8YAHVC8W3Q52)'		
			ELSE 'NR'			
		  END AS C0300


		, CASE 	
			WHEN  PUT(C0310,1.0) = '0'  THEN '0 - Credit quality step 0'
			WHEN  PUT(C0310,1.0) = '1'  THEN '1 - Credit quality step 1'
			WHEN  PUT(C0310,1.0) = '2'  THEN '2 - Credit quality step 2'
			WHEN  PUT(C0310,1.0) = '3'  THEN '3 - Credit quality step 3'
			WHEN  PUT(C0310,1.0) = '4'  THEN '4 - Credit quality step 4'
			WHEN  PUT(C0310,1.0) = '5'  THEN '5 - Credit quality step 5'
			WHEN  PUT(C0310,1.0) = '6'  THEN '6 - Credit quality step 6'	
			WHEN  PUT(C0310,1.0) = '9'  THEN '9 - No rating available'	
			ELSE 'NR'
		  END AS C0310

		, COALESCE(X_INTERNAL_RATING,'Not Applicable') AS C0320
				 
		, A7 AS C0330
		
		, A37 AS C0340

		, CASE 
				WHEN A38GRP = '1' THEN '1 - LEI' 
				ELSE '9 - None'
		   END AS C0350

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
		, A21_D2O_MERGE AS C0390
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

		, CASE 
	        WHEN A31 = '-' THEN  '6 - Other events not covered by the previous options' 
			WHEN A31 = '6' THEN  '6 - Other events not covered by the previous options'
			ELSE 'CHECK X_EIOPA_CODE'
		  END AS C0400


		, A24 AS C0410

		, A25 AS C0420

		, A27 AS C0430

/**************************************************************************************************************************/
/**************************************************************************************************************************/
													,'' AS END_PART_2
/**************************************************************************************************************************/
/**************************************************************************************************************************/

		,INT1
		,INT2
		,INT3
		,INT4
		,INT5
		,INT6
		,INT7
		,INT8
		,INT9
		,INT10
		,INT11
		,INT12
		,INT13
		,INT14
		,INT15
		,INT16
		,INT17

		,CASE 
			WHEN A38 = '1'  THEN  'LEI' 
			WHEN A38 = '2'  THEN 'SC'
			ELSE 'None' 
		 END ||'/'|| A36 AS INT18							

		,CASE 
			WHEN A38GRP = '1' THEN 'LEI' 
			WHEN A38GRP = '2' THEN 'SC'
			ELSE 'None' 
         END ||'/'|| A37 AS IN19

	FROM WORK.S0801_D2O_IMT_BASE

	GROUP BY 
			
			C0010	,
			C0020	,
			C0030	,
			C0040	,
			C0050	,
			C0060	,
			C0070	,
			C0080	,
			C0090	,
			C0100	,
			C0110	,
			C0120   ,
			C0140	,
			C0150	,
			C0160   ,
			C0170   ,
			C0180	,
			C0190	,
			C0200	,
			C0210	,
			C0220	,
			C0230   ,
			C0250	,
			END_PART_1,	
			C0040_P2	,
			C0050_P2	,
			C0260	,
			C0270	,
			C0280	,
			C0290	,
			C0300	,
			C0310	,
			C0320	,
			C0330	,
			C0340	,
			C0350	,
			C0360	,
			C0370	,
			C0380	,
			C0390	,
			C0400	,
			C0410	,
			C0420	,
			C0430	,
			END_PART_2	,
			INT1	,
			INT2	,
			INT3	,
			INT4	,
			INT5	,
			INT6	,
			INT7	,
			INT8	,
			INT9	,
			INT10	,
			INT11	,
			INT12	,
			INT13	,
			INT14	,
			INT15	,
			INT16	,
			INT17	,
			INT18	,
			IN19

	ORDER BY 																															
			C0380																													
			,INT5 																														
			,INT14																													
			,C0140   ;          
QUIT;

