
PROC SQL ;

/*Create Temp table to load the extracted Data*/

CREATE TABLE WORK.S0801_D2O_IMT_BASE AS 

	SELECT 

	  COALESCE(XIP.PORTFOLIO_CLASSIFICATION,'-') AS A1

	, COALESCE(RFF.CLIENT_ID,'Not Ring Fenced') AS A2

	, XIP.UNIT_INDEX_LINKED_IND AS A3 

	, COALESCE(B.ISSUE_CD,C.ISSUE_CD) AS A4 LENGTH=50

	, CASE 
		WHEN A.X_RPT_ID_TYPE_OVRD = '99' THEN 'Undertaking'	
		WHEN A.X_RPT_ID_TYPE_OVRD = '1' THEN 'ISIN'	 
		WHEN A.X_RPT_ID_TYPE_OVRD = '2' THEN 'CUSIP'
		ELSE 'DATA QUALITY ISSUE'
	  END AS A5

	, COALESCE(A.X_COUNTERPARTY_NM,'-') AS A6
	, COALESCE(A.X_COUNTERPARTY_LEI_CD,'-') AS A36
	, COALESCE(A.X_COUNTERPARTY_LEI_STATUS,'-') AS A38		
	
	, COALESCE(A.X_COUNTERPARTY_GRP_NM,'-') AS A7
	, COALESCE(A.X_COUNTERPARTY_GRP_LEI_CD,'-') AS A37
	, COALESCE(A.X_COUNTERPARTY_GRP_LEI_STATUS,'-') AS A38GRP		

	, TRIM(CASE 
		WHEN SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('A')
			THEN 'Futures - '||PAM_USE.ACC_SECURITY_DESC_LINE_1

		WHEN SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('D')
			THEN COALESCE(PAM_USE.ACC_SECURITY_DESC_LINE_3,A.FINANCIAL_INSTRUMENT_NM)

		WHEN SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('E')
			THEN TRIM(TRIM(UPCASE(CASE WHEN UPCASE(TRIM(PAM_USE.ACC_GL_GROUP_DESC)) = 'FORWARDS' THEN 'FX '||PAM_USE.ACC_GL_GROUP_DESC ELSE PAM_USE.ACC_GL_GROUP_DESC END))||' - '||TRIM(PAM_USE.ACC_SECURITY_DESC_LINE_1)||' - '||TRIM(CASE
																																																											WHEN A.X_LONG_OR_SHORT_POSITION = '1' THEN 'Long'  
	/*DO NOT REMOVE THIS SPACE*/		/*DO NOT REMOVE THIS SPACE*/		/*DO NOT REMOVE THIS SPACE*/		/*DO NOT REMOVE THIS SPACE*/						/*DO NOT REMOVE THIS SPACE*/											WHEN A.X_LONG_OR_SHORT_POSITION = '2' THEN 'Short' 
																																																											ELSE X_LONG_OR_SHORT_POSITION
																																																									 	END)||' - Currency - '||TRIM(PAM_USE.ACC_SECURITY_DESC_LINE_3))
		ELSE A.FINANCIAL_INSTRUMENT_NM 
      END) AS A8	LENGTH=500
	

	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
	, TRIM(CASE 				
	/*Change for D2o Merge remove the usage of LONG_SHORT POSITION*/		
		WHEN F.SOURCE_SYSTEM_CD = 'BLR' 									
			THEN TRIM(UPCASE(TRIM(CASE WHEN UPCASE(TRIM(PAM_USE.ACC_GL_GROUP_DESC)) = 'FORWARDS' THEN 'FX '||PAM_USE.ACC_GL_GROUP_DESC ELSE PAM_USE.ACC_GL_GROUP_DESC END ))||' - '||TRIM(PAM_USE.ACC_SECURITY_DESC_LINE_1)||' - '||'Long - Currency - '||TRIM(FX.BUY_CURRENCY_CD)||' - Short - Currency - '||TRIM(FX.SELL_CURRENCY_CD))

		 WHEN F.SOURCE_SYSTEM_CD = 'NONBLR'
			THEN TRIM('FX Forwards -'||TRIM(SUBSTR(A.FINANCIAL_INSTRUMENT_NM,15,8))||' - '||'Long - Currency - '||TRIM(FX.BUY_CURRENCY_CD)||' - Short - Currency - '||TRIM(FX.SELL_CURRENCY_CD))
		ELSE A.FINANCIAL_INSTRUMENT_NM 
      END) AS A8_D2O_MERGE LENGTH=500
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

	, COALESCE(A.X_ASSET_LIABILITY_DRVT_CD , '-') AS A9	
																																			
	, F.CURRENCY_CD AS A10	

	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
	/*Change fOr D2o Merge - FP.CURRENCY_CD TP FX.BUY_CURRENCY CD*/
	, FX.BUY_CURRENCY_CD AS A10_D2O_MERGE	
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/	
																																			
	, CIC.ISSUE_CD AS A11 	

	, COALESCE(A.X_DRVTS_CD_OVRD , '-') AS A13

	, CASE 
	    WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('A','D','E','F')  THEN 'Not Applicable - CIC' 																															
	    ELSE COALESCE(PUT(XFPC.X_OPTION_DELTA,5.2) , '-')
  	  END AS A14																								

	, INPUT(( CASE 
			WHEN 
				 ( SUBSTR(CIC.ISSUE_CD,3,1) IN ('D','E')
				 AND F.SOURCE_SYSTEM_CD <> 'NONBLR')
				 THEN 																															
					CASE 
						WHEN PUT(A.X_NOTIONAL_AMT,18.2) = '' THEN '-'
						ELSE PUT( ( ABS(A.X_NOTIONAL_AMT)/EXC.I_T_CURRENCY_RATE ) , 18.2 ) 
					END																														
				ELSE 						
					CASE 
						WHEN 
							(SUBSTR(CIC.ISSUE_CD,3,1) IN ('A')  
							 AND F.SOURCE_SYSTEM_CD <> 'NONBLR')
							THEN 																															
							    CASE 
									WHEN PUT(A.X_NOTIONAL_AMT,18.2) = '' THEN '-' 
									ELSE PUT( ( ABS(A.FACE_VALUE_AMT*(A.X_CONTRACT_DIMENSION ) )  / EXC.I_T_CURRENCY_RATE)  , 18.2 ) 
								END
							ELSE																								
								CASE 
									WHEN PUT(A.X_NOTIONAL_AMT,18.2) = '' THEN '-' 
									ELSE PUT(A.X_NOTIONAL_AMT , 18.2) 
								END 
					END																											
		END),18.2) AS A15	

	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
					/*Change for D2o Merge - Recalculate Notional_amount for LONG (BUY) leg - START */
	, INPUT( (CASE 
			WHEN A.X_LONG_OR_SHORT_POSITION = '1' AND F.SOURCE_SYSTEM_CD <> 'NONBLR' AND SUBSTR(CIC.ISSUE_CD,3,1) IN ('E')
				THEN																															
					CASE 
						WHEN PUT(A.X_NOTIONAL_AMT,18.2) = '' THEN '-'
						ELSE PUT( ( ABS(A.X_NOTIONAL_AMT)/EXC.I_T_CURRENCY_RATE ) , 18.2 ) 
					END	
			WHEN A.X_LONG_OR_SHORT_POSITION = '1' AND F.SOURCE_SYSTEM_CD = 'NONBLR' 	
				THEN 
					CASE 
						WHEN PUT(A.X_NOTIONAL_AMT,18.2) = '' THEN '-' 
						ELSE PUT(A.X_NOTIONAL_AMT , 18.2) 
					END 
			ELSE '0.0' 					
		END),18.2) AS A15_D2o_MERGE
					/*Change for D2o Merge - Recalculate Notional_amount for LONG (BUY) leg - END */
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

	, A.X_LONG_OR_SHORT_POSITION AS A16 LENGTH=50 /*Add length to avoid issues during APPEND such as truncation*/

/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
	/* Not Applicable for fx's in  D2o Merge  */
	, CASE 
			WHEN  SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('E') THEN 'Not Applicable - CIC' 
			ELSE A.X_LONG_OR_SHORT_POSITION 
	   END  AS A16_D2o_MERGE LENGTH=50  /*Add length to avoid issues during APPEND such as truncation*/
/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

	/*BV802 - PREMIUM PAID TO DATE / PREMIUM RECVD TO DATE NOT APPLICABLE FOR 'A' AND 'E' */
	, CASE 
		WHEN  SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('A','E') THEN 'Not Applicable - CIC'
		WHEN  A.X_PREMIUM_PAID IS NULL THEN '-' 
		ELSE  PUT( (A.X_PREMIUM_PAID  / EXC.I_T_CURRENCY_RATE) , 18.2)
	  END AS A17 /*C0150*/

	/*BV802 - PREMIUM PAID TO DATE / PREMIUM RECVD TO DATE NOT APPLICABLE FOR 'A' AND 'E' */
 	, CASE 
		WHEN  SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('A','E') THEN 'Not Applicable - CIC'
		WHEN  A.X_PREMIUM_RCVD IS NULL THEN '-' 
		ELSE  PUT( (A.X_PREMIUM_RCVD  / EXC.I_T_CURRENCY_RATE) , 18.2)
	  END AS C0160

	, CASE 
		WHEN SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('A')  THEN PUT(A.FACE_VALUE_AMT , 18.2)
	  	ELSE COALESCE(PUT(A.X_NO_OF_CONTRACTS,3.),'-')
   	  END AS A19																													

	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('D','E','F')  THEN 'Not Applicable - CIC'																										
		ELSE COALESCE(PUT(A.X_CONTRACT_DIMENSION,3.),'-')
	  END AS A20																							

	/*BV807 - Applicable*/
	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN  ('D3') THEN 'Not Applicable - CIC'
		ELSE COALESCE(X_TRIGGER_VALUE,'-')																										
	  END AS A21

/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
/*The Sell leg of the currency value will be required for the trigger value concatenation specific to FX*/
	  /*BV807 - Applicable*/
	  	, CASE 
			WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN  ('D3') THEN 'Not Applicable - CIC'
			WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN  ('E')  THEN COALESCE(TRIM(FX.SELL_CURRENCY_CD)||'  '||TRIM(X_TRIGGER_VALUE),'-')	 
			ELSE COALESCE(X_TRIGGER_VALUE,'')																										
	  END AS A21_D2O_MERGE

/*************************************** Required for D2o Merge aka D2o new rules - END **********************/
	/*BV1022*/ /*BV1092*/
	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,2) NOT IN  ('D1','D2','D3','D9','F3','F4')  THEN 'Not Applicable - CIC' 																															
		ELSE  
			CASE 
				WHEN A.X_PAY_LEG_AMT IS NULL THEN '-' 
				ELSE PUT (A.X_PAY_LEG_AMT / EXC.I_T_CURRENCY_RATE ,18.2)  
			END 
	   END AS A22 /*C0200*/

	/*BV1023*/ /*BV1092*/
	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,2) NOT IN  ('D1','D2','D3','D9','F3','F4')  THEN 'Not Applicable - CIC' 																															
		ELSE  
			CASE 
				WHEN A.X_REC_LEG_AMT IS NULL THEN '-' 
				ELSE PUT (A.X_REC_LEG_AMT / EXC.I_T_CURRENCY_RATE ,18.2)  
			END 
	   END AS A23	/*C0210*/

	  /*BV808 , BV994 applicable*/
	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN  ('D2','D3') THEN COALESCE(A.X_SWAP_DLVRD_CURRENCY,'-') 																															
		ELSE 'Not Applicable - CIC'
	  END AS A24 																								
		
	/*BV809 , BV995 applicable*/	
	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN  ('D2','D3') THEN COALESCE(A.X_SWAP_RCVD_CURRENCY,'-')
		ELSE  'Not Applicable - CIC' 
	  END AS A25	

	, CASE 
		WHEN F.SOURCE_SYSTEM_CD = 'NONBLR' THEN PUT(A.X_TRADE_DT,DDMMYY10.)
		ELSE 
			 CASE 
				WHEN SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('A') THEN PUT(A.X_TRADE_DT,DDMMYY10.) 
				ELSE COALESCE (PUT(A.EFFECTIVE_FROM_DT,DDMMYY10.),'-')
			 END 
	   END AS A26 																															
																											
	, PUT(A.MATURITY_DT,DDMMYY10.) AS A27 	

	, F.X_SOLVENCY_II_VALUE AS A28FIN FORMAT=21.2

	, COALESCE (A.X_VALUATION_METHOD_DRVTS, XIP.VALUATION_METHOD_DRVTS) AS A29

	, COALESCE (A.X_UNWIND_TRIGGER, '-') AS A31

	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,1) = 'F' 
		THEN COALESCE(PUT(A.X_UNWIND_MAX_LOSS,18.2),'-')  
		ELSE 'Not Applicable - CIC'
	  END  AS A32	

	, COALESCE (PUT(XFPC.X_EFF_DUR,10.7), '-') AS A33

	/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
		/*change for D2o Merge EFF ----> TO MOD to get the Identical MOD Dur for both the legs*/ 
	, COALESCE (PUT(XFPC.X_MOD_DUR,10.7), '-') AS A33_D2O_MERGE
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/

	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('D') THEN COALESCE (CPARTY_555_Rating.ASSESSMENT_GRADE,CPARTY_999_Rating.ASSESSMENT_GRADE,'NR')
		WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('E') THEN COALESCE (INSTR_555_Rating.ASSESSMENT_GRADE,INSTR_999_Rating.ASSESSMENT_GRADE,'NR')
	  	ELSE 'NR'
	  END AS A34

	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('D') THEN COALESCE (CPARTY_555_Rating.ASSESSMENT_AGENCY_CD,CPARTY_999_Rating.ASSESSMENT_AGENCY_CD,'NR')
		WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('E') THEN COALESCE (INSTR_555_Rating.ASSESSMENT_AGENCY_CD,INSTR_999_Rating.ASSESSMENT_AGENCY_CD,'NR')
	  	ELSE 'NR'
	  END AS A35

	, CASE 
		WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('D') THEN COALESCE (CPARTY_555_Rating.X_SOLII_CREDIT_QUALITY_VAL,CPARTY_999_Rating.X_SOLII_CREDIT_QUALITY_VAL,9)
		WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('E') THEN COALESCE (INSTR_555_Rating.X_SOLII_CREDIT_QUALITY_VAL,INSTR_999_Rating.X_SOLII_CREDIT_QUALITY_VAL,9)
	  	ELSE 9
	  END AS C0310

	, XIP.ENTITY_NAME AS A50																								
																																		
	, F.PORTFOLIO_ID AS INT1						
			
	, XIP.INTERNAL_ORG_REFERENCE_NO	 AS INT2					
			
	, A.X_EXPERT_JUDGEMENT_FIN_INV_CLS AS INT3																																																																								
																																		
	, SUBSTR(TRIM(CIC.ISSUE_CD),3,1) AS INT4

	, SUBSTR(TRIM(CIC.ISSUE_CD),3,2) AS INT5							  
			
	, CIC_CAT.X_CIC_CATEGORY_NM AS INT6
						
	, CIC_CAT.X_CIC_SUB_CATEGORY_NM AS INT7																							
			  																															
	, COALESCE(A.X_PAM_GL_GRP,'-') AS INT8																														
																																		
	, COALESCE(PAM_USE.ACC_GL_GROUP_DESC, '-') AS INT9	

	, A.X_I_T_INV_CLS_GROUP_OVRD AS INT10	

	,  A.X_I_T_INV_CLS_CATEGORY_OVRD AS INT11	

	, COALESCE(A.X_LEH_SUBSECTOR_CD,'-') AS INT12	

	, STC.SM_SEC_TYPE AS INT13

	, CASE 
		WHEN F.SOURCE_SYSTEM_CD = 'NONBLR' THEN A.X_CLIENT_ID 
		ELSE COALESCE(PAM_USE.PAM_CUSIP,A.X_PAM_SEC_ID)
	  END AS INT14 LENGTH=50

	, MONTH(&AS_AT_MTH) AS INT15

	, YEAR(&AS_AT_MTH) AS INT16

	, F.SOURCE_SYSTEM_CD AS INT17	

	, XIP.ENTITY_LEI_CD 

	, XIP.ENTITY_LEI_STATUS

	, A.X_RPT_ID_TYPE_OVRD

	, A.X_ASSET_LIABILITY_DRVT_ID		

	, XFPC.X_INTERNAL_RATING	

	FROM																															
			test.FINANCIAL_INSTRUMENT A		/*FINANCIAL INSTRUMENT */																														
																																		
			INNER JOIN 	/*FINANCIAL POSITION */																													
			test.FINANCIAL_POSITION F																															
			ON F.FINANCIAL_INSTRUMENT_RK = A.FINANCIAL_INSTRUMENT_RK																															
			AND DATEPART(F.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
			AND DATEPART(F.VALID_TO_DTTM) > &AS_AT_MTH           
			
			INNER JOIN /*EXCHANGE RATES*/
			test.X_I_T_INT_EXC_RATES EXC
			ON F.CURRENCY_CD = EXC.CURRENCY_CD
			AND DATEPART(EXC.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
			AND DATEPART(EXC.VALID_TO_DTTM) > &AS_AT_MTH   		 
																																																										
			LEFT JOIN 																															
			test.FINANCIAL_INSTRUMENT_ISSUE B /* ISIN */																															
			  ON  A.FINANCIAL_INSTRUMENT_RK = B.FINANCIAL_INSTRUMENT_RK																															
			AND DATEPART(B.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
			AND DATEPART(B.VALID_TO_DTTM) > &AS_AT_MTH 																														
			AND B.ISSUE_TYPE_CD = '001'																															
																																		
			LEFT JOIN 																															
			test.FINANCIAL_INSTRUMENT_ISSUE C /* CUSIP */																															
			  ON  A.FINANCIAL_INSTRUMENT_RK = C.FINANCIAL_INSTRUMENT_RK																															
			AND DATEPART(C.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
			AND DATEPART(C.VALID_TO_DTTM) > &AS_AT_MTH 																														
			AND C.ISSUE_TYPE_CD = '003'																															
																																		
			LEFT JOIN  /* CIC*/																															
			(																															
				SELECT																														
					 		A2.FINANCIAL_INSTRUMENT_RK																											
				 		  , A2.VALID_FROM_DTTM																												
				 		  , A2.VALID_TO_DTTM																												
				 		  , A2.ISSUE_CD																												
				 		  , A2.ISSUE_TYPE_CD					 		  																					
				FROM																														
				(																														
				 SELECT																														
				 			TICK2.FINANCIAL_INSTRUMENT_RK																											
				 		  , MAX(TICK2.VALID_FROM_DTTM) AS VALID_FROM_DTTM																												
				 		  , TICK2.ISSUE_TYPE_CD																												
					FROM																													
							 test.FINANCIAL_INSTRUMENT TICK1																											
					       , test.FINANCIAL_INSTRUMENT_ISSUE TICK2																													
				  WHERE																														
				  			  TICK1.FINANCIAL_INSTRUMENT_RK = TICK2.FINANCIAL_INSTRUMENT_RK																											
								AND DATEPART(TICK2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
								AND DATEPART(TICK2.VALID_TO_DTTM) > &AS_AT_MTH 																													
								AND TICK2.ISSUE_TYPE_CD = '002'																													
				 GROUP BY																														
				 			TICK2.FINANCIAL_INSTRUMENT_RK																											
				 		  , TICK2.ISSUE_TYPE_CD																												
				  ) A1  																														
				, test.FINANCIAL_INSTRUMENT_ISSUE A2																														
				WHERE 																														
					  A1.FINANCIAL_INSTRUMENT_RK = A2.FINANCIAL_INSTRUMENT_RK																										
					  AND A1.VALID_FROM_DTTM = A2.VALID_FROM_DTTM																													
					  AND A1.ISSUE_TYPE_CD = A2.ISSUE_TYPE_CD	 																												
			) CIC																															
			  ON  A.FINANCIAL_INSTRUMENT_RK = CIC.FINANCIAL_INSTRUMENT_RK																															
			AND CIC.ISSUE_TYPE_CD = '002'																															
																																		
			LEFT JOIN																															
			test.COUNTERPARTY D	/*Counterparty Join*/																														
			  ON  A.ISSUER_COUNTERPARTY_RK = D.COUNTERPARTY_RK																															
				AND DATEPART(D.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
				AND DATEPART(D.VALID_TO_DTTM) > &AS_AT_MTH 	
			 	AND D.X_LEH_SECTOR_CD <> 'ABS'

			LEFT JOIN /* Instrument level rating 999 system calculated*/																															
			(																															
				SELECT																															
				     DISTINCT																															
				     B1.FINANCIAL_INSTRUMENT_RK																															
				    ,B2.ASSESSMENT_AGENCY_CD																															
				    ,B2.ASSESSMENT_GRADE    																															
				    ,B2.ASSESSMENT_SCORE_NO	
					,B2.X_SOLII_CREDIT_QUALITY_VAL	 	

				FROM																															
					 (																															
						  SELECT																															
						      	CCA1.FINANCIAL_INSTRUMENT_RK																															
						     	,CCA1.ASSESSMENT_RATING_GRADE_RK																															
						  FROM																															
						    	test.FINANCIAL_INST_CREDIT_ASSESS AS CCA1

								, (
									 SELECT 																														
									     FINANCIAL_INSTRUMENT_RK	
									   	,MAX(ASSESSMENT_DT) AS ASSESSMENT_DT																												
									 FROM																														
									  	test.FINANCIAL_INST_CREDIT_ASSESS																												
									 WHERE 				
									 	ASSESSMENT_DT <= &AS_AT_MTH	
											
									 GROUP BY																														
									      		 FINANCIAL_INSTRUMENT_RK    																												
								   ) AS CCA2																															
						  WHERE																															
						        CCA1.FINANCIAL_INSTRUMENT_RK =  CCA2.FINANCIAL_INSTRUMENT_RK																															
						   		AND CCA1.ASSESSMENT_DT =  CCA2.ASSESSMENT_DT
								AND PUT(DATEPART(CCA1.EFFECTIVE_TO_DTTM),DATE9.) = '31DEC4747'		
								AND ASSESSMENT_MODEL_RK = 999			
																																			
					 )  B1 																															

					, test.ASSESSMENT_RATING_GRADE B2	
	
				WHERE																															

					B1.ASSESSMENT_RATING_GRADE_RK = B2.ASSESSMENT_RATING_GRADE_RK
					AND DATEPART(B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(B2.VALID_TO_DTTM) > &AS_AT_MTH 	
					AND B2.MODEL_RK = 999 																															

			) INSTR_999_Rating																															
				ON 
					A.FINANCIAL_INSTRUMENT_RK = INSTR_999_Rating.FINANCIAL_INSTRUMENT_RK	



			LEFT JOIN /* Instrument level rating 555 Business Override */																															
			(																															
				SELECT																															
				     DISTINCT																															
				     B1.FINANCIAL_INSTRUMENT_RK																															
				    ,B2.ASSESSMENT_AGENCY_CD																															
				    ,B2.ASSESSMENT_GRADE    																															
				    ,B2.ASSESSMENT_SCORE_NO
					,B2.X_SOLII_CREDIT_QUALITY_VAL	

				FROM																															
					 (																															
						  SELECT																															
						      	CCA1.FINANCIAL_INSTRUMENT_RK																															
						     	,CCA1.ASSESSMENT_RATING_GRADE_RK																															
						  FROM																															
						    	test.FINANCIAL_INST_CREDIT_ASSESS AS CCA1

								, (
									 SELECT 																														
									     FINANCIAL_INSTRUMENT_RK	
									   	,MAX(ASSESSMENT_DT) AS ASSESSMENT_DT																												
									 FROM																														
									  	test.FINANCIAL_INST_CREDIT_ASSESS																												
									 WHERE 				
									 	ASSESSMENT_DT <= &AS_AT_MTH	
											
									 GROUP BY																														
									      		 FINANCIAL_INSTRUMENT_RK    																												
								   ) AS CCA2																															
						  WHERE																															
						        CCA1.FINANCIAL_INSTRUMENT_RK =  CCA2.FINANCIAL_INSTRUMENT_RK																															
						   		AND CCA1.ASSESSMENT_DT =  CCA2.ASSESSMENT_DT
								AND PUT(DATEPART(CCA1.EFFECTIVE_TO_DTTM),DATE9.) = '31DEC4747'		
								AND ASSESSMENT_MODEL_RK = 555			
																																			
					 )  B1 																															

					, test.ASSESSMENT_RATING_GRADE B2	
	
				WHERE																															

					B1.ASSESSMENT_RATING_GRADE_RK = B2.ASSESSMENT_RATING_GRADE_RK																															
					AND DATEPART(B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(B2.VALID_TO_DTTM) > &AS_AT_MTH 
					AND B2.MODEL_RK = 555 																															

			) INSTR_555_Rating																															
				ON 
					A.FINANCIAL_INSTRUMENT_RK = INSTR_555_Rating.FINANCIAL_INSTRUMENT_RK


			LEFT JOIN /* Cparty level rating 999 system calculated*/
				(
				SELECT																															
				     DISTINCT																															
					     CP_B1.COUNTERPARTY_RK																															
					    ,CP_B2.ASSESSMENT_AGENCY_CD																															
					    ,CP_B2.ASSESSMENT_GRADE    																															
					    ,CP_B2.ASSESSMENT_SCORE_NO
						,CP_B2.X_SOLII_CREDIT_QUALITY_VAL	

				FROM																															
					 (																															
						  SELECT																															
						      	CP_CCA1.COUNTERPARTY_RK																															
						     	,CP_CCA1.ASSESSMENT_RATING_GRADE_RK																															
						  FROM																															
						    	test.COUNTERPARTY_CREDIT_ASSESSMENT AS CP_CCA1

								, (
									 SELECT 																														
									     COUNTERPARTY_RK	
									   	,MAX(ASSESSMENT_DT) AS ASSESSMENT_DT																												
									 FROM																														
									  	test.COUNTERPARTY_CREDIT_ASSESSMENT																												
									 WHERE 				
									 	ASSESSMENT_DT <= &AS_AT_MTH	
											
									 GROUP BY																														
									    COUNTERPARTY_RK    																												
								   ) AS CP_CCA2																															
						  WHERE																															
						        CP_CCA1.COUNTERPARTY_RK =  CP_CCA2.COUNTERPARTY_RK																															
						   		AND CP_CCA1.ASSESSMENT_DT = CP_CCA2.ASSESSMENT_DT
								AND PUT(DATEPART(CP_CCA1.EFFECTIVE_TO_DTTM),DATE9.) = '31DEC4747'		
								AND ASSESSMENT_MODEL_RK = 999			
																																			
					 )  CP_B1 																															

					, test.ASSESSMENT_RATING_GRADE CP_B2	
	
				WHERE																															

					CP_B1.ASSESSMENT_RATING_GRADE_RK = CP_B2.ASSESSMENT_RATING_GRADE_RK	
					AND DATEPART(CP_B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(CP_B2.VALID_TO_DTTM) > &AS_AT_MTH 	
					AND CP_B2.MODEL_RK = 999 

				) CPARTY_999_Rating
				ON 
					D.COUNTERPARTY_RK = CPARTY_999_Rating.COUNTERPARTY_RK	


				LEFT JOIN /* Cparty level rating 555 Business override */
				(
				SELECT																															
				     DISTINCT																															
					     CP_B1.COUNTERPARTY_RK																															
					    ,CP_B2.ASSESSMENT_AGENCY_CD																															
					    ,CP_B2.ASSESSMENT_GRADE    																															
					    ,CP_B2.ASSESSMENT_SCORE_NO
						,CP_B2.X_SOLII_CREDIT_QUALITY_VAL		

				FROM																															
					 (																															
						  SELECT																															
						      	CP_CCA1.COUNTERPARTY_RK																															
						     	,CP_CCA1.ASSESSMENT_RATING_GRADE_RK																															
						  FROM																															
						    	test.COUNTERPARTY_CREDIT_ASSESSMENT AS CP_CCA1

								, (
									 SELECT 																														
									     COUNTERPARTY_RK	
									   	,MAX(ASSESSMENT_DT) AS ASSESSMENT_DT																												
									 FROM																														
									  	test.COUNTERPARTY_CREDIT_ASSESSMENT																												
									 WHERE 				
									 	ASSESSMENT_DT <= &AS_AT_MTH	
											
									 GROUP BY																														
									    COUNTERPARTY_RK    																												
								   ) AS CP_CCA2																															
						  WHERE																															
						        CP_CCA1.COUNTERPARTY_RK =  CP_CCA2.COUNTERPARTY_RK																															
						   		AND CP_CCA1.ASSESSMENT_DT = CP_CCA2.ASSESSMENT_DT
								AND PUT(DATEPART(CP_CCA1.EFFECTIVE_TO_DTTM),DATE9.) = '31DEC4747'		
								AND ASSESSMENT_MODEL_RK = 555			
																																			
					 )  CP_B1 																															

					, test.ASSESSMENT_RATING_GRADE CP_B2	
	
				WHERE																															

					CP_B1.ASSESSMENT_RATING_GRADE_RK = CP_B2.ASSESSMENT_RATING_GRADE_RK
					AND DATEPART(CP_B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(CP_B2.VALID_TO_DTTM) > &AS_AT_MTH 	
					AND CP_B2.MODEL_RK = 555 

				) CPARTY_555_Rating
				ON 
					D.COUNTERPARTY_RK = CPARTY_555_Rating.COUNTERPARTY_RK	


			LEFT JOIN /*join on X_FINANCIAL_POSITION_CHNG*/
				test.X_FINANCIAL_POSITION_CHNG XFPC																															
					ON																															
			         	F.FINANCIAL_POSITION_RK = XFPC.FINANCIAL_POSITION_RK
						AND DATEPART(XFPC.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
				  		AND DATEPART(XFPC.VALID_TO_DTTM) > &AS_AT_MTH 																																		
																																		
			LEFT JOIN /*join on X_INVESTMENT_PORTFOLIO*/																																
				test.X_INVESTMENT_PORTFOLIO XIP																															
					ON																															
					 	XIP.PORTFOLIO_ID = F.PORTFOLIO_ID 																													
						AND PUT(DATEPART(XIP.VALID_TO_DTTM),DATE9.) = '31DEC9999'

			LEFT JOIN /* Join for Ring fenced Funds */																															
			(																															
				SELECT 																														
							DISTINCT																											
							PORTFOLIO_ID,																											
							CUSIP,																											
							ISIN,																											
							CLIENT_ID																											
				FROM 																														
					test.X_RING_FENCED_FUNDS																											
				WHERE																														
					DATEPART(VALID_TO_DTTM) > &AS_AT_MTH 					
			 		AND DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH 	
																											
			) RFF																															
			ON 																															
			  RFF.PORTFOLIO_ID  = XIP.PORTFOLIO_ID																												
			  AND (RFF.CUSIP = C.ISSUE_CD OR  RFF.ISIN = B.ISSUE_CD)							

			LEFT JOIN 	/* Join for Assets linked Funds */																														
			(																															
				SELECT 																														
					DISTINCT																											
						PORTFOLIO_ID,																											
						CUSIP,																											
						ISIN,																											
						CLIENT_ID,																											
						UNIT_INDEX_LINKED_FLAG																											
				FROM 																														
					test.X_ASSETS_LINKED_FUNDS																											
				WHERE																														
					DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH 			
			     	AND DATEPART(VALID_TO_DTTM) > &AS_AT_MTH 																							
			) UNT_INDX																															
																																		
			ON 																															
				UNT_INDX.PORTFOLIO_ID  = XIP.PORTFOLIO_ID																												
		 	    AND (UNT_INDX.CUSIP = C.ISSUE_CD OR UNT_INDX.ISIN = B.ISSUE_CD)	


			LEFT JOIN 	/*Use of Derivative*/																															
			(																															
				SELECT																															
				  DISTINCT 																											
						PORTFOLIO_ID,																					
						CUSIP,																											
						ISIN,																			
						CLIENT_ID,																											
						DRVTS_CD																											
					FROM																														
						test.X_USE_OF_DERIVATIVE																											
					WHERE																														
						DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH 			
			     		AND DATEPART(VALID_TO_DTTM) > &AS_AT_MTH 																												
			) UOD	
	
			ON																															
				  UOD.PORTFOLIO_ID =  XIP.PORTFOLIO_ID																											
				  AND (UOD.CUSIP = C.ISSUE_CD OR UOD.ISIN = B.ISSUE_CD)	


			LEFT JOIN /*get Category subname and names*/
			(
				 SELECT	
					DISTINCT 
						X_CIC_CATEGORY_CD ,
						X_CIC_CATEGORY_NM , 
						X_CIC_CD_LAST_2_CHAR,
						X_CIC_SUB_CATEGORY_NM
				 FROM	
					test.X_CIC_CATEGORY
			) CIC_CAT

			ON 
				CIC_CAT.X_CIC_CD_LAST_2_CHAR = SUBSTR(TRIM(CIC.ISSUE_CD),3,2)

			LEFT JOIN /*get the Investment sub class , SM_SEC_GROUP ,SM_SEC_TYPE*/
				test.X_INVST_CLASS_STC STC
					ON A.FINANCIAL_INSTRUMENT_TYPE_CD = STC.SM_SEC_GROUP_CD
					AND A.X_FINANCIAL_INSTR_SUB_TYPE_CD = STC.SM_SEC_TYPE_CD
					AND PUT(DATEPART(STC.VALID_TO_DTTM),DATE9.) = '31DEC9999'

			LEFT JOIN /* Join to Use the PAM related Data */
				(
					SELECT

						B_FIN.ISSUE_CD AS BRS_ISIN
						, C_FIN.ISSUE_CD AS BRS_CUSIP
						, PORTFOLIO_ID AS BRS_PORTFOLIO
						, X_PAM_GL_GRP AS BRS_GRP
						, PRESENT_VALUE_AMT AS BRS_MKT_VAL
						, A_FIN.FINANCIAL_INSTRUMENT_RK
						, BRSID AS PAM_CUSIP
						, ACC_PRIMARY_SEC_ID AS PAM_SEC_ID
						, ISIN AS PAM_ISIN
						, PAM.TICKER AS PAM_PORTFOLIO
						, ACC_SECURITY_DESC_LINE_1
						, ACC_SECURITY_DESC_LINE_2
						, ACC_SECURITY_DESC_LINE_3
						, ACC_GL_GROUP_DESC
						, ACC_UNITS
						, ACC_PRICE
						, ACC_END_ACCRUED
						, ACC_ACTUAL_BV	
						, ACC_MARKET_VALUE
						, ACC_CURRENCY

					FROM																															
						test.FINANCIAL_INSTRUMENT A_FIN																															
																																				
					INNER JOIN 																															
						test.FINANCIAL_POSITION F_FIN																															
						   ON F_FIN.FINANCIAL_INSTRUMENT_RK = A_FIN.FINANCIAL_INSTRUMENT_RK																															
							AND DATEPART(F_FIN.VALID_FROM_DTTM) <= &AS_AT_MTH 	
							AND DATEPART(F_FIN.VALID_TO_DTTM) > &AS_AT_MTH																														
																																																																
					LEFT JOIN 																															
						test.FINANCIAL_INSTRUMENT_ISSUE B_FIN /* ISIN */																															
						  ON  
							A_FIN.FINANCIAL_INSTRUMENT_RK = B_FIN.FINANCIAL_INSTRUMENT_RK
							AND DATEPART(B_FIN.VALID_FROM_DTTM) <= &AS_AT_MTH 	
							AND DATEPART(B_FIN.VALID_TO_DTTM) > &AS_AT_MTH																														
							AND B_FIN.ISSUE_TYPE_CD = '001'																															
																																				
					LEFT JOIN 																															
						test.FINANCIAL_INSTRUMENT_ISSUE C_FIN /* CUSIP */																															
						  ON  
							A_FIN.FINANCIAL_INSTRUMENT_RK = C_FIN.FINANCIAL_INSTRUMENT_RK																															
							AND DATEPART(C_FIN.VALID_FROM_DTTM) <= &AS_AT_MTH 	
							AND DATEPART(C_FIN.VALID_TO_DTTM) > &AS_AT_MTH
							AND C_FIN.ISSUE_TYPE_CD = '003'																															
																																				
					INNER JOIN																																			
					( 
						SELECT																															
							TICKER
							, BRSID
							, ISIN
							, ACC_PRIMARY_SEC_ID																																		
							, FINANCIAL_INSTRUMENT_RK
							, PHYSICAL_ASSET_RK																																			
							, ACC_SECURITY_DESC_LINE_1
							, ACC_SECURITY_DESC_LINE_2
							, ACC_SECURITY_DESC_LINE_3
							, ACC_GL_GROUP_DESC																																			
							, ACC_UNITS
							, ACC_PRICE
							, ACC_END_ACCRUED
							, ACC_ACTUAL_BV																																			
							, ACC_MARKET_VALUE
							, ACC_CURRENCY
																																					
					  FROM																																
						test.X_BLKRK_ACCT																															

					  WHERE																																
						 DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH 																													
						  AND DATEPART(VALID_TO_DTTM) > &AS_AT_MTH 																													

					UNION ALL 																															
																																					
						SELECT																															
							TICKER
							, BRSID
							, ISIN
							, ACC_PRIMARY_SEC_ID																																		
							, FINANCIAL_INSTRUMENT_RK																															
							, 0 AS PHYSICAL_ASSET_RK
							, ACC_SECURITY_DESC_LINE_1
							, ACC_SECURITY_DESC_LINE_2
							, ACC_SECURITY_DESC_LINE_3
							, ACC_GL_GROUP_DESC																																			
							, ACC_UNITS
							, ACC_PRICE
							, ACC_END_ACCRUED																															
							, ACC_ACTUAL_BV
							, CASE 
								WHEN ACC_SECURITY_DESC_LINE_2 = 'S' THEN (-1*ACC_MARKET_VALUE) 
								ELSE ACC_MARKET_VALUE 
							  END AS ACC_MARKET_VALUE
							, ACC_CURRENCY																															
																																					
						FROM																																
						  test.X_BLKRK_ACCT_FXFWD
	
						WHERE
						  DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH 																													
						  AND DATEPART(VALID_TO_DTTM) > &AS_AT_MTH 																													
						) PAM																															
							ON A_FIN.FINANCIAL_INSTRUMENT_RK = PAM.FINANCIAL_INSTRUMENT_RK																															
							AND TICKER = PORTFOLIO_ID																															
							AND (C_FIN.ISSUE_CD =  PAM.BRSID OR X_PAM_SEC_ID = BRSID)																															
							AND UPCASE(TRIM(ACC_GL_GROUP_DESC)) IN ('FUTURES','FUTURES - BOND','INTEREST RATE SWAPS','SWAPS','FORWARDS','INTEREST RATE SWAPS CCS','FX SPOTS')
							AND DATEPART(A_FIN.VALID_FROM_DTTM) <= &AS_AT_MTH 	
							AND DATEPART(A_FIN.VALID_TO_DTTM) > &AS_AT_MTH 	
								
				)PAM_USE																															
																																			
				ON 	  																														
																																																																
					PAM_USE.PAM_PORTFOLIO = F.PORTFOLIO_ID																															
					AND PAM_USE.FINANCIAL_INSTRUMENT_RK = A.FINANCIAL_INSTRUMENT_RK		

		/*************************************** Required for D2o Merge aka D2o new rules - START **********************/
				LEFT JOIN /* Join to Use the FX related Data which is required for the D20 Merge aka D2O new rules */
					(
						SELECT 																															
						  	DISTINCT 		
						  		B.FINANCIAL_INSTRUMENT_RK																									
						  		, B.FX_LEG_FINANCIAL_INSTR_RK																														
						  		, A.BUY_CURRENCY_CD
						  		, A.SELL_CURRENCY_CD																									

						FROM																														
							    test.X_FX_INSTRUMENT A           																														
								, test.X_FX_INSTRUMENT_LEG B																												
						WHERE				 	
							 DATEPART(A.VALID_FROM_DTTM) <= &AS_AT_MTH 				    
							 AND DATEPART(A.VALID_TO_DTTM) > &AS_AT_MTH 	
							 AND DATEPART(B.VALID_FROM_DTTM) <= &AS_AT_MTH																														
						     AND DATEPART(B.VALID_TO_DTTM) > &AS_AT_MTH 																															
						     AND A.FINANCIAL_INSTRUMENT_RK = B.FINANCIAL_INSTRUMENT_RK			  																															
					) FX	
				 ON 
					A.FINANCIAL_INSTRUMENT_RK = FX.FX_LEG_FINANCIAL_INSTR_RK
	/*************************************** Required for D2o Merge aka D2o new rules - END **********************/



	WHERE

				  DATEPART(A.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
				  AND DATEPART(A.VALID_TO_DTTM) > &AS_AT_MTH 																															
			      AND A.FINANCIAL_INSTRUMENT_TYPE_CD IN ( '011', '012', '020', '021', '004')																															
			      AND SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('A','B','C','D','E','F')				

	ORDER BY 

		SUBSTR(TRIM(CIC.ISSUE_CD),3,1) ,   A.X_PAM_SEC_ID ,   A.X_LONG_OR_SHORT_POSITION

	;

	QUIT;
