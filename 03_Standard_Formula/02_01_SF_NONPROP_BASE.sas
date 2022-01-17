
PROC SQL ;

/*Create Temp table to load the extracted Data*/

OPTIONS MISSING='';

CREATE TABLE WORK.NONPROP AS 

		SELECT	

			CASE 
				WHEN F.SOURCE_SYSTEM_CD = 'BLR' THEN '01 - Blackrock - Without Lookthrough' 
				ELSE '02 - Non Blackrock - Without Lookthrough' 
			END AS DATA_SOURCE

			, CASE 
				WHEN SUBSTR(C.ISSUE_CD ,1,3)='CSH' THEN TRIM(TRIM(C.ISSUE_CD)||TRIM(F.SOURCE_SYSTEM_CD)) 
			  	ELSE C.ISSUE_CD  
			  END AS CUSIP LENGTH=500

			, F.PORTFOLIO_ID AS PORTF_LIST

			, XIP.ENTITY_NAME AS PORTF_NAME

			, CASE 
				WHEN STC.SM_SEC_TYPE IN ('FXFWRD','FXSPOT') 
					THEN
						CASE 
							WHEN A.X_PAM_SEC_ID = ''  AND CIC.ISSUE_CD='XTE2'  
								THEN X_CLIENT_ID 
							ELSE A.X_PAM_SEC_ID   
						END  
					ELSE  
						CASE 
							WHEN STC.SM_SEC_TYPE = 'SWAP' AND C.ISSUE_CD = 'BRSKHCU57' THEN 'BRSKHCU57' 
						END  
			  END AS PARENT_CUSIP LENGTH=32

			, '' AS PARENT_ISIN LENGTH=12

			, COALESCE(PUT(XFPC.X_PXS_DT,DDMMYY10.),PUT(&AS_AT_MTH,DDMMYY10.)) AS PXS_DATE 
		
			, STC.SM_SEC_GROUP LENGTH=20 FORMAT=$20. INFORMAT=$20.

			, STC.SM_SEC_TYPE LENGTH=60 FORMAT=$60. INFORMAT=$60.

			, CASE
				WHEN A.INTEREST_PAYMENT_TYPE_CD = '000' THEN 'ZERO'
				WHEN A.INTEREST_PAYMENT_TYPE_CD = '001' THEN 'FIXED'
				WHEN A.INTEREST_PAYMENT_TYPE_CD = '002' THEN 'FLOAT'
				WHEN A.INTEREST_PAYMENT_TYPE_CD = '003' THEN 'MAT'
				WHEN A.INTEREST_PAYMENT_TYPE_CD = '004' THEN 'N/A'
				WHEN A.INTEREST_PAYMENT_TYPE_CD = '005' THEN 'FIXED TO FLOAT'
				WHEN A.INTEREST_PAYMENT_TYPE_CD = '006' THEN 'FLOAT TO FIXED'
				WHEN A.INTEREST_PAYMENT_TYPE_CD = '099' THEN ''
				ELSE 'UNKNOWN'
		      END AS SM_CPN_TYPE

			 , RF.RISK_FACTOR_ID AS RESET_INDEX

			 , A.X_COUNTRY_OF_ISSUE_CD AS COUNTRY LENGTH=32 INFORMAT=$32. FORMAT = $32.  

			, F.CURRENCY_CD AS CURRENCY LENGTH=32 FORMAT=$32. INFORMAT=$32.  
 
			, F.X_SOLVENCY_II_VALUE AS MKT_VALUE FORMAT=21.2

			, F.X_SOLVENCY_II_VALUE/1000 AS MKT_VALUE_DIV_1000 FORMAT=21.4

			, CASE 
				WHEN UPCASE(A.X_PAM_GL_GRP) = 'CASH EQUIVALENTS' AND F.PORTFOLIO_ID = 'A_320NONBR' AND CIC.ISSUE_CD = 'XT72' THEN F.X_SOLVENCY_II_VALUE
				WHEN UPCASE(A.X_PAM_GL_GRP) IN ('FORWARDS','FX SPOTS') AND A.SOURCE_SYSTEM_CD = 'NONBLR' THEN  A.X_NOTIONAL_AMT
				WHEN UPCASE(A.X_PAM_GL_GRP) = 'SHORT TERM INVESTMENTS' OR A.SOURCE_SYSTEM_CD = 'NONBLR' THEN F.HOLDINGS_NO
				WHEN UPCASE(A.X_PAM_GL_GRP) = 'FUTURES - BOND' AND A.SOURCE_SYSTEM_CD = 'BLR' THEN XFPC.X_MKT_NOTION   
				ELSE A.X_NOTIONAL_AMT/EXC.I_T_CURRENCY_RATE 
			  END AS GBP_CUR_FACE FORMAT=21.4

			, (CASE 
				WHEN UPCASE(A.X_PAM_GL_GRP) = 'CASH EQUIVALENTS' AND F.PORTFOLIO_ID = 'A_320NONBR' AND CIC.ISSUE_CD = 'XT72' THEN F.X_SOLVENCY_II_VALUE
				WHEN UPCASE(A.X_PAM_GL_GRP) IN ('FORWARDS','FX SPOTS') AND A.SOURCE_SYSTEM_CD = 'NONBLR' THEN  A.X_NOTIONAL_AMT
				WHEN UPCASE(A.X_PAM_GL_GRP) = 'SHORT TERM INVESTMENTS' OR A.SOURCE_SYSTEM_CD = 'NONBLR' THEN F.HOLDINGS_NO
				WHEN UPCASE(A.X_PAM_GL_GRP) = 'FUTURES - BOND' AND A.SOURCE_SYSTEM_CD = 'BLR' THEN XFPC.X_MKT_NOTION   
				ELSE A.X_NOTIONAL_AMT/EXC.I_T_CURRENCY_RATE 
			  END)/1000 AS GBP_CUR_FACE_DIV_1000 FORMAT=21.6

			, A.INITIAL_CONTRACT_RT	AS COUPON

			, A.PAYMENT_RESET_FREQ_MONTH_NO AS COUPON_FREQUENCY

			, PUT(A.FIRST_RESET_DT,DDMMYY10.) AS NEXT_COUPON

			, XFPC.X_MOD_DUR AS MOD_DUR FORMAT=15.5

			, XFPC.X_SPREAD_DUR AS SPREAD_DUR  FORMAT=15.5

			, XFPC.X_YIELD_TO_MAT AS YIELD_TO_MAT

			, COALESCE(PUT(A.MATURITY_DT,DDMMYY10.),'00/01/1900') AS MATURITY_DATE
			, COALESCE(PUT(XFPC.X_ZV_MATURITY,DDMMYY10.),'00/01/1900') AS ZV_MATURITY_DATE 

			, A.FINANCIAL_INSTRUMENT_NM AS SHORT_STD_DESC  

			, CASE WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('A','D') THEN '0'
					ELSE D.COUNTERPARTY_ID 
			  END AS ULTIMATE_PARENT_TICKER

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('A','E','D') 
					THEN 
						A.X_COUNTERPARTY_GRP_NM 
					ELSE 
						A.X_ISSUER_GRP_NM 	
			   END AS ULT_ISSUER_NAME LENGTH=255

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('A','E','D') 
						THEN 
							A.X_COUNTERPARTY_NM 
						ELSE 
							A.X_ISSUER_NM
			   END AS ISSUER_NAME LENGTH=255

			, CASE 
				WHEN F.PORTFOLIO_ID ='A_320NONBR' AND  UPCASE(A.X_PAM_GL_GRP) <> 'CASH EQUIVALENTS'
					THEN 
						CASE 
							WHEN SUBSTR(CIC.ISSUE_CD,3,1)  NOT IN ('D','E') 
								THEN COALESCE (INSTR_555_Rating.ASSESSMENT_GRADE,INSTR_999_Rating.ASSESSMENT_GRADE,'NR')
						END
					ELSE
				 		XFPC.X_LEHM_RATING_TX
				END AS  LEHM_RATING_TXT LENGTH=20

			, XFPC.X_LEHM_ISS_RATING_TXT AS LEHM_RATING_ISS

			, CASE 
				WHEN F.PORTFOLIO_ID ='A_320NONBR' AND  UPCASE(A.X_PAM_GL_GRP) <> 'CASH EQUIVALENTS'
					THEN 
						CASE 
							WHEN SUBSTR(CIC.ISSUE_CD,3,1)  NOT IN ('D','E') 
								THEN COALESCE (INSTR_555_Rating.ASSESSMENT_GRADE,INSTR_999_Rating.ASSESSMENT_GRADE,'NR')
						END
					ELSE
				 		XFPC.X_AVE_RATING
				END AS AVE_RATING

			, XFPC.X_BARC_FOUR_PILLAR_SECTOR AS BARCLAYS_FOUR_PILLAR_SECTOR

			, XFPC.X_BARC_FOUR_PILLAR_SUBSECTOR AS  BARCLAYS_FOUR_PILLAR_SUBSECTOR

			, XFPC.X_BARC_FOUR_PILLAR_INDUSTRY AS BARCLAYS_FOUR_PILLAR_INDUSTRY

			, XFPC.X_BARC_FOUR_PILLAR_SUBINDUSTRY AS BARCLAYS_FOUR_PILLAR_SUBINDUSTRY

			, XFPC.X_INFL AS INFL

			, XFPC.X_INTERNAL_RATING AS INTERNAL_RATING 

			, B.ISSUE_CD AS ISIN LENGTH=60 FORMAT=$60. INFORMAT=$60.

			, EMB.EMBEDDED_OPTION_TYPE_CD AS PUT_CALL

			, CIC.ISSUE_CD AS CIC LENGTH=4 FORMAT=$4. INFORMAT=$4.

			, F.X_SOLVENCY_II_VALUE AS PAM_MV FORMAT=21.2

			, CASE 
					WHEN UPCASE(A.X_PAM_GL_GRP) = 'CASH EQUIVALENTS' AND F.PORTFOLIO_ID = 'A_320NONBR' AND CIC.ISSUE_CD = 'XT72' THEN F.X_SOLVENCY_II_VALUE
					WHEN UPCASE(A.X_PAM_GL_GRP) IN ('FORWARDS','FX SPOTS') AND A.SOURCE_SYSTEM_CD = 'NONBLR' THEN  A.X_NOTIONAL_AMT
					WHEN UPCASE(A.X_PAM_GL_GRP) = 'SHORT TERM INVESTMENTS' OR A.SOURCE_SYSTEM_CD = 'NONBLR' THEN F.HOLDINGS_NO
					WHEN UPCASE(A.X_PAM_GL_GRP) = 'FUTURES - BOND' AND A.SOURCE_SYSTEM_CD = 'BLR' THEN XFPC.X_MKT_NOTION   
					ELSE A.X_NOTIONAL_AMT/EXC.I_T_CURRENCY_RATE 
				  END AS GBP_CONV_CUR_FACE FORMAT=21.2

			, TICKER.ISSUE_CD  AS TICKER LENGTH=200 INFORMAT=$200. FORMAT=$200.

			, COALESCE( XFPC.X_MKT_NOTION , F.X_SOLVENCY_II_VALUE) AS MKT_NOTION

			, A.X_PAM_GL_GRP INFORMAT=$100. FORMAT=$100.  LENGTH=100

			, EXC.I_T_CURRENCY_RATE AS I_T_CURRENCY_RATE

			, A.X_I_T_INV_CLS_GROUP_OVRD  AS I_T_CLS_GRP 
			, A.X_I_T_INV_CLS_CATEGORY_OVRD  AS I_T_CLS_CAT  

			, X_EXPERT_JUDGEMENT_FIN_INV_CLS  AS FIN_INV_CLS

/**********************************************************************/
/************************Rating fields - END *************************/		
/********************************************************************/

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)   NOT IN   ('D') 
					THEN INSTR_MDY_Rating.ASSESSMENT_GRADE
					ELSE CPARTY_MDY_Rating.ASSESSMENT_GRADE
			  END AS RTG_MOODYS  LENGTH=32

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)   NOT IN   ('D')  
					THEN COALESCE(INSTR_MDY_Rating.ASSESSMENT_SCORE_NO,0)
					ELSE COALESCE(CPARTY_MDY_Rating.ASSESSMENT_SCORE_NO,0)
			  END AS MDY_SCORE

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)  NOT IN   ('D') 
					THEN INSTR_SP_Rating.ASSESSMENT_GRADE
					ELSE CPARTY_SP_Rating.ASSESSMENT_GRADE
			  END AS RTG_SP LENGTH=32

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)   NOT IN  ('D') 
					THEN COALESCE(INSTR_SP_Rating.ASSESSMENT_SCORE_NO,0)
					ELSE COALESCE(CPARTY_SP_Rating.ASSESSMENT_SCORE_NO,0)
			  END AS SP_SCORE

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)  NOT IN   ('D')  
					THEN INSTR_FIT_Rating.ASSESSMENT_GRADE
					ELSE CPARTY_FIT_Rating.ASSESSMENT_GRADE
			  END AS RTG_FITCH LENGTH=32

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) NOT IN   ('D') 
					THEN COALESCE(INSTR_FIT_Rating.ASSESSMENT_SCORE_NO,0)
					ELSE COALESCE(CPARTY_FIT_Rating.ASSESSMENT_SCORE_NO,0)
			  END AS FIT_SCORE

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('D') 
					THEN COALESCE (CPARTY_555_Rating.ASSESSMENT_SCORE_NO,CPARTY_999_Rating.ASSESSMENT_SCORE_NO,0)
					ELSE COALESCE (INSTR_555_Rating.ASSESSMENT_SCORE_NO,INSTR_999_Rating.ASSESSMENT_SCORE_NO,0)
			  END AS WTFL_SCORE

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('D') 
					THEN COALESCE (CPARTY_555_Rating.ASSESSMENT_GRADE,CPARTY_999_Rating.ASSESSMENT_GRADE,'')
					ELSE COALESCE (INSTR_555_Rating.ASSESSMENT_GRADE,INSTR_999_Rating.ASSESSMENT_GRADE,'')
			  END AS WTFL_GRADE LENGTH=32

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('D') 
					THEN COALESCE (CPARTY_555_Rating.ASSESSMENT_AGENCY_CD,CPARTY_999_Rating.ASSESSMENT_AGENCY_CD,'')
					ELSE COALESCE (INSTR_555_Rating.ASSESSMENT_AGENCY_CD,INSTR_999_Rating.ASSESSMENT_AGENCY_CD,'')
			  END AS WTFL_AGENCY

			, SNP_DERIV.ASSESSMENT_GRADE AS SNP_EQUI_RATING

			, CASE 
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'AA+' THEN 'AA'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'AA-' THEN  'AA'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'A+' THEN 'A'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'A-'  THEN 'A'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'BBB+'  THEN 'BBB'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'BBB-'  THEN 'BBB'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'BB+'  THEN 'BB'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'BB-'  THEN 'BB'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'B+'  THEN 'B'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'B-'  THEN 'B'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'CCC+'  THEN 'CCC'
				WHEN SNP_DERIV.ASSESSMENT_GRADE = 'CCC-'  THEN 'CCC'
				ELSE SNP_DERIV.ASSESSMENT_GRADE
			  END AS GROUPED_RATING

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('D') 
					THEN COALESCE (CPARTY_555_Rating.X_SOLII_CREDIT_QUALITY_VAL,CPARTY_999_Rating.X_SOLII_CREDIT_QUALITY_VAL)
					ELSE COALESCE (INSTR_555_Rating.X_SOLII_CREDIT_QUALITY_VAL,INSTR_999_Rating.X_SOLII_CREDIT_QUALITY_VAL)
		      END AS WTFL_SII_CREDIT_QLTY_VAL

/**********************************************************************/
/**************************Rating fields - END ***********************/		
/********************************************************************/
/*not used
			, CASE 
				WHEN UPCASE(A.X_PAM_GL_GRP) = 'CASH EQUIVALENTS' AND F.PORTFOLIO_ID = 'A_320NONBR' AND CIC.ISSUE_CD = 'XT72' THEN F.X_SOLVENCY_II_VALUE
				WHEN UPCASE(A.X_PAM_GL_GRP) IN ('FORWARDS','FX SPOTS') AND  A.SOURCE_SYSTEM_CD = 'NONBLR' THEN  A.X_NOTIONAL_AMT
				WHEN UPCASE(A.X_PAM_GL_GRP) = 'SHORT TERM INVESTMENTS' OR A.SOURCE_SYSTEM_CD = 'NONBLR' THEN F.HOLDINGS_NO
				WHEN UPCASE(A.X_PAM_GL_GRP) = 'FUTURES - BOND' AND A.SOURCE_SYSTEM_CD = 'BLR' THEN XFPC.X_MKT_NOTION          
				ELSE A.X_NOTIONAL_AMT 
			  END AS PAR_VAL
***********/
			, X_EEA_MEMBER_FLAG

			, X_OECD_MEMBER_FLAG 

			/* ADD Sec credit type */
			, X_SECURITISED_CREDIT_TYPE INFORMAT=$20. FORMAT=$20. LENGTH=20 

			/*ADD INFRA TYPE*/
			, INFRASTRUCTURE_INV_CD

			, A.X_NACE_CD AS NACE LENGTH=100 INFORMAT=$100. FORMAT=$100.

			, A.X_STRUCTURE

/********************************EXTRA FIELDS************************************/

			, XFPC.X_MOD_DUR_S2 AS MOD_DUR_S2 /*Added for Interest rate risk*/

			, CASE
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN  ('A','E','D')  THEN 
					CASE 	
						WHEN A.X_COUNTERPARTY_GRP_LEI_STATUS <> '1' THEN 'None'																														
						ELSE TRIM('LEI/')||TRIM(X_COUNTERPARTY_GRP_LEI_CD)
					END
				ELSE 
					CASE 			
						WHEN A.X_ISSUER_GRP_LEI_STATUS <> '1' THEN 'None'
						ELSE TRIM('LEI/')||TRIM(X_ISSUER_GRP_LEI_CD)
				END
			  END AS ULT_ISSUER_LEI LENGTH = 100 /*Added for CPARTY rate risk*/

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN  ('A','E','D')  THEN 
					CASE 	
						WHEN A.X_COUNTERPARTY_LEI_STATUS <> '1' THEN 'None'																														
						ELSE TRIM('LEI/')||TRIM(X_COUNTERPARTY_LEI_CD)
					END 
				ELSE 
					CASE 			
						WHEN A.X_LEI_STATUS<> '1' THEN 'None'
						ELSE TRIM('LEI/')||TRIM(X_LEI_CD)
					END
			   END AS ISSUER_LEI LENGTH = 100 /*Added for CPARTY rate risk*/

		FROM																															
			test.FINANCIAL_INSTRUMENT A	/*FINANCIAL INSTRUMENT */																														

			INNER JOIN 	/*FINANCIAL POSITION */																													
			test.FINANCIAL_POSITION F																															
				ON  F.FINANCIAL_INSTRUMENT_RK = A.FINANCIAL_INSTRUMENT_RK
					AND A.SOURCE_SYSTEM_CD = F.SOURCE_SYSTEM_CD	
					AND DATEPART(F.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(F.VALID_TO_DTTM) > &AS_AT_MTH   

			INNER JOIN 																															
			test.FINANCIAL_INSTRUMENT_ISSUE C /* CUSIP */																															
				ON  A.FINANCIAL_INSTRUMENT_RK = C.FINANCIAL_INSTRUMENT_RK																															
					AND DATEPART(C.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(C.VALID_TO_DTTM) > &AS_AT_MTH 																														
					AND C.ISSUE_TYPE_CD = '003'	

			LEFT JOIN 																															
			test.FINANCIAL_INSTRUMENT_ISSUE B /* ISIN */																															
				ON  A.FINANCIAL_INSTRUMENT_RK = B.FINANCIAL_INSTRUMENT_RK
					AND DATEPART(B.VALID_FROM_DTTM) <= &AS_AT_MTH 	
					AND DATEPART(B.VALID_TO_DTTM) > &AS_AT_MTH																														
					AND B.ISSUE_TYPE_CD = '001'	

			LEFT JOIN																															
			test.COUNTERPARTY D	/*COUNTERPARTY JOIN*/																														
			 	ON  A.ISSUER_COUNTERPARTY_RK = D.COUNTERPARTY_RK																															
					AND DATEPART(D.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(D.VALID_TO_DTTM) > &AS_AT_MTH 	
			 		

			LEFT JOIN /*RISK FACTOR_X_EXPOSURE TO GET THE RISK_ID*/
			test.RISK_FACTOR_X_EXPOSURE RF
				ON  RF.RISK_FACTOR_ID <> ''
					AND A.FINANCIAL_INSTRUMENT_RK = RF.FINANCIAL_INSTRUMENT_RK
					AND DATEPART(RF.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(RF.VALID_TO_DTTM) > &AS_AT_MTH

			LEFT JOIN /*join on X_FINANCIAL_POSITION_CHNG*/
			test.X_FINANCIAL_POSITION_CHNG XFPC																															
				ON  F.FINANCIAL_POSITION_RK = XFPC.FINANCIAL_POSITION_RK
					AND DATEPART(XFPC.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
				  	AND DATEPART(XFPC.VALID_TO_DTTM) > &AS_AT_MTH 

			LEFT JOIN /*join on X_INVESTMENT_PORTFOLIO*/																																
			test.X_INVESTMENT_PORTFOLIO XIP																															
				ON  XIP.PORTFOLIO_ID = F.PORTFOLIO_ID 																													
					AND PUT(DATEPART(XIP.VALID_TO_DTTM),DATE9.) = '31DEC9999'

			INNER JOIN /*EXCHANGE RATES*/
			test.X_I_T_INT_EXC_RATES EXC
				ON  F.CURRENCY_CD = EXC.CURRENCY_CD
					AND DATEPART(EXC.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(EXC.VALID_TO_DTTM) > &AS_AT_MTH  

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

			LEFT JOIN  /* TICKER*/																															
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
								AND TICK2.ISSUE_TYPE_CD = '005'																													
				 GROUP BY																														
				 			TICK2.FINANCIAL_INSTRUMENT_RK																											
				 		  , TICK2.ISSUE_TYPE_CD																												
				  ) A1  																														
				, test.FINANCIAL_INSTRUMENT_ISSUE A2																														
				WHERE 																														
					  A1.FINANCIAL_INSTRUMENT_RK = A2.FINANCIAL_INSTRUMENT_RK																										
					  AND A1.VALID_FROM_DTTM = A2.VALID_FROM_DTTM																													
					  AND A1.ISSUE_TYPE_CD = A2.ISSUE_TYPE_CD	 																												
			) TICKER																															
			  ON  A.FINANCIAL_INSTRUMENT_RK = TICKER.FINANCIAL_INSTRUMENT_RK																															
			  		AND TICKER.ISSUE_TYPE_CD = '005'


			LEFT JOIN /*get the Investment sub class , SM_SEC_GROUP ,SM_SEC_TYPE*/
				test.X_INVST_CLASS_STC STC
					ON A.FINANCIAL_INSTRUMENT_TYPE_CD = STC.SM_SEC_GROUP_CD
					AND A.X_FINANCIAL_INSTR_SUB_TYPE_CD = STC.SM_SEC_TYPE_CD
					AND PUT(DATEPART(STC.VALID_TO_DTTM),DATE9.) = '31DEC9999'

			LEFT JOIN /*join on X_LOAN_INSTRUMENT_TABLE FOR INFRASTRUCTURE RELATED CODES*/				
			(				
				SELECT 				
					DISTINCT 
					FINANCIAL_INSTRUMENT_RK	
					, LOAN_INSTRUMENT_TYPE_CD	
					, INFRASTRUCTURE_INV_CD

				FROM			
					test.X_LOAN_INSTRUMENT  

				WHERE				
					DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                   
					AND DATEPART(VALID_TO_DTTM) > &AS_AT_MTH 					
			 ) LOAN				
			 ON A.FINANCIAL_INSTRUMENT_RK = LOAN.FINANCIAL_INSTRUMENT_RK	

			LEFT JOIN /* TAKE INSTRUMENT TYPE AND CREDIT_TYPE CD FROM STRUCTURED NOTES */				
			(				
				SELECT 				
				  DISTINCT 
					SI.FINANCIAL_INSTRUMENT_RK	
					, SI.SECURITIZ_INSTRUMENT_TYPE_CD	
					, SI.X_SECURITISED_CREDIT_TYPE

				FROM			
					test.SECURITIZATION_INSTRUMENT SI   

				WHERE				
					DATEPART(SI.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                   
					AND DATEPART(SI.VALID_TO_DTTM) > &AS_AT_MTH 				
			) SEC				
					ON A.FINANCIAL_INSTRUMENT_RK = SEC.FINANCIAL_INSTRUMENT_RK

			LEFT JOIN 																						
			test.EMBEDDED_OPTIONS EMB /* EMB */
				ON  A.FINANCIAL_INSTRUMENT_RK = EMB.FINANCIAL_INSTRUMENT_RK																						
					AND DATEPART(EMB.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(EMB.VALID_TO_DTTM) > &AS_AT_MTH

			LEFT JOIN 
			test.COUNTRY CNTRY /* COUNTRY */
				ON  A.X_COUNTRY_OF_ISSUE_CD  = CNTRY.COUNTRY_CD																									                                                                                                               
					AND PUT(DATEPART(CNTRY.VALID_TO_DTTM),DATE9.) = '31DEC9999'


			/*Instrument level  TABLES 5 NOS
				555  Rating - INSTR_555_Rating	Business override rating
				999  Rating	- INSTR_999_Rating System calculated rating - Waterfall model
				SP   Rating - INSTR_SP_Rating
				MDY  Rating - INSTR_MDY_Rating
				FIT  Rating - INSTR_FIT_Rating

			CPARTY level TABLES 5 NOS
				555  Rating - CPARTY_555_Rating
				999  Rating - CPARTY_999_Rating
				SP   Rating - CPARTY_SP_Rating
				MDY  Rating - CPARTY_MDY_Rating
				FIT  Rating - CPARTY_FIT_Rating */

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

				LEFT JOIN /* Cparty level rating S_P , MODEL_RK = 1 */
				(
				SELECT																															
				     DISTINCT																															
					     CP_B1.COUNTERPARTY_RK																															
					    ,CP_B2.ASSESSMENT_AGENCY_CD																															
					    ,CASE WHEN CP_B2.ASSESSMENT_GRADE IN  ('Agency','Govt') THEN 'AAA' ELSE CP_B2.ASSESSMENT_GRADE END AS ASSESSMENT_GRADE    																															
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
								AND ASSESSMENT_MODEL_RK = 1									
																																			
					 )  CP_B1 																															

					, test.ASSESSMENT_RATING_GRADE CP_B2	
	
				WHERE																															

					CP_B1.ASSESSMENT_RATING_GRADE_RK = CP_B2.ASSESSMENT_RATING_GRADE_RK
					AND DATEPART(CP_B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(CP_B2.VALID_TO_DTTM) > &AS_AT_MTH 	
					AND CP_B2.MODEL_RK = 1 
					AND CP_B2.ASSESSMENT_AGENCY_CD = 'S_P'

				) CPARTY_SP_Rating
				ON 
					D.COUNTERPARTY_RK = CPARTY_SP_Rating.COUNTERPARTY_RK


			LEFT JOIN /* Cparty level rating MDY , MODEL_RK = 2 */
				(
				SELECT																															
				     DISTINCT																															
					     CP_B1.COUNTERPARTY_RK																															
					    ,CP_B2.ASSESSMENT_AGENCY_CD																															
					    ,CASE WHEN CP_B2.ASSESSMENT_GRADE IN  ('Agency','Govt') THEN 'Aaa' ELSE CP_B2.ASSESSMENT_GRADE END AS ASSESSMENT_GRADE    																															
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
								AND ASSESSMENT_MODEL_RK = 2									
																																			
					 )  CP_B1 																															

					, test.ASSESSMENT_RATING_GRADE CP_B2	
	
				WHERE																															

					CP_B1.ASSESSMENT_RATING_GRADE_RK = CP_B2.ASSESSMENT_RATING_GRADE_RK
					AND DATEPART(CP_B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(CP_B2.VALID_TO_DTTM) > &AS_AT_MTH 	
					AND CP_B2.MODEL_RK = 2 
					AND CP_B2.ASSESSMENT_AGENCY_CD = 'MDY'

				) CPARTY_MDY_Rating
				ON 
					D.COUNTERPARTY_RK = CPARTY_MDY_Rating.COUNTERPARTY_RK


				LEFT JOIN /* Cparty level rating FIT , MODEL_RK = 3 */
				(
				SELECT																															
				     DISTINCT																															
					     CP_B1.COUNTERPARTY_RK																															
					    ,CP_B2.ASSESSMENT_AGENCY_CD																															
					    ,CASE WHEN CP_B2.ASSESSMENT_GRADE IN  ('Agency','Govt') THEN 'AAA' ELSE CP_B2.ASSESSMENT_GRADE END AS ASSESSMENT_GRADE    																															
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
								AND ASSESSMENT_MODEL_RK = 3									
																																			
					 )  CP_B1 																															

					, test.ASSESSMENT_RATING_GRADE CP_B2	
	
				WHERE																															

					CP_B1.ASSESSMENT_RATING_GRADE_RK = CP_B2.ASSESSMENT_RATING_GRADE_RK
					AND DATEPART(CP_B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(CP_B2.VALID_TO_DTTM) > &AS_AT_MTH 	
					AND CP_B2.MODEL_RK = 3 
					AND CP_B2.ASSESSMENT_AGENCY_CD = 'FIT'

				) CPARTY_FIT_Rating
				ON 
					D.COUNTERPARTY_RK = CPARTY_FIT_Rating.COUNTERPARTY_RK

			LEFT JOIN /* Instrument level rating SP Rating model rk = 1 */																															
			(																															
				SELECT																															
				     DISTINCT																															
				     B1.FINANCIAL_INSTRUMENT_RK																															
				    ,B2.ASSESSMENT_AGENCY_CD																															
				    ,CASE WHEN B2.ASSESSMENT_GRADE IN  ('Agency','Govt') THEN 'AAA' ELSE B2.ASSESSMENT_GRADE END AS ASSESSMENT_GRADE     																															
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
								AND ASSESSMENT_MODEL_RK = 1			
																																			
					 )  B1 																															

					, test.ASSESSMENT_RATING_GRADE B2	
	
				WHERE																															

					B1.ASSESSMENT_RATING_GRADE_RK = B2.ASSESSMENT_RATING_GRADE_RK																															
					AND DATEPART(B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(B2.VALID_TO_DTTM) > &AS_AT_MTH 
					AND B2.MODEL_RK = 1 
					AND B2.ASSESSMENT_AGENCY_CD = 'S_P'

			) INSTR_SP_Rating																															
				ON 
					A.FINANCIAL_INSTRUMENT_RK = INSTR_SP_Rating.FINANCIAL_INSTRUMENT_RK

			LEFT JOIN /* Instrument level rating MDY Rating model rk = 2 */																															
			(																															
				SELECT																															
				     DISTINCT																															
				     B1.FINANCIAL_INSTRUMENT_RK																															
				    ,B2.ASSESSMENT_AGENCY_CD																															
				    ,CASE WHEN B2.ASSESSMENT_GRADE IN  ('Agency','Govt') THEN 'Aaa' ELSE B2.ASSESSMENT_GRADE END AS ASSESSMENT_GRADE    																															
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
								AND ASSESSMENT_MODEL_RK = 2		
																																			
					 )  B1 																															

					, test.ASSESSMENT_RATING_GRADE B2	
	
				WHERE																															

					B1.ASSESSMENT_RATING_GRADE_RK = B2.ASSESSMENT_RATING_GRADE_RK																															
					AND DATEPART(B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(B2.VALID_TO_DTTM) > &AS_AT_MTH 
					AND B2.MODEL_RK = 2
					AND B2.ASSESSMENT_AGENCY_CD = 'MDY'

			) INSTR_MDY_Rating																															
				ON 
					A.FINANCIAL_INSTRUMENT_RK = INSTR_MDY_Rating.FINANCIAL_INSTRUMENT_RK

			LEFT JOIN /* Instrument level rating FIR Rating model rk = 3 */																															
			(																															
				SELECT																															
				     DISTINCT																															
				     B1.FINANCIAL_INSTRUMENT_RK																															
				    ,B2.ASSESSMENT_AGENCY_CD																															
				    ,  CASE WHEN B2.ASSESSMENT_GRADE IN  ('Agency','Govt') THEN 'AAA' ELSE B2.ASSESSMENT_GRADE END AS ASSESSMENT_GRADE     																															
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
								AND ASSESSMENT_MODEL_RK = 3			
																																			
					 )  B1 																															

					, test.ASSESSMENT_RATING_GRADE B2	
	
				WHERE																															

					B1.ASSESSMENT_RATING_GRADE_RK = B2.ASSESSMENT_RATING_GRADE_RK																															
					AND DATEPART(B2.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
					AND DATEPART(B2.VALID_TO_DTTM) > &AS_AT_MTH 
					AND B2.MODEL_RK = 3 
					AND B2.ASSESSMENT_AGENCY_CD = 'FIT'

			) INSTR_FIT_Rating																															
				ON 
					A.FINANCIAL_INSTRUMENT_RK = INSTR_FIT_Rating.FINANCIAL_INSTRUMENT_RK

			LEFT JOIN 
			/*Get the Equivalent SNP rating of the calculated Waterfall Rating 
			if not able to join create all the statement from above into a temp table 
			and then left join */ 
					(
						SELECT 
							DISTINCT 
							ASSESSMENT_AGENCY_CD,
							ASSESSMENT_GRADE,
							ASSESSMENT_SCORE_NO,
							X_SOLII_CREDIT_QUALITY_VAL
						FROM 
							test.ASSESSMENT_RATING_GRADE 
						WHERE 
							ASSESSMENT_AGENCY_CD = 'S_P' 
							AND SHORTTERM_FLG = '0'
							AND PUT(DATEPART(VALID_TO_DTTM),DATE9.) = '31DEC4747'	
							AND UPCASE(ASSESSMENT_GRADE) NOT IN ('GOVT','GOVT EQUIV','AGENCY')
							AND MODEL_RK = 1
					)SNP_DERIV
				ON 
					(
					  CASE 
						WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('D') 
							THEN COALESCE (CPARTY_555_Rating.ASSESSMENT_SCORE_NO,CPARTY_999_Rating.ASSESSMENT_SCORE_NO,0)
						ELSE COALESCE (INSTR_555_Rating.ASSESSMENT_SCORE_NO,INSTR_999_Rating.ASSESSMENT_SCORE_NO,0)
					  END
					) = SNP_DERIV.ASSESSMENT_SCORE_NO


		WHERE 
			DATEPART(A.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
			AND DATEPART(A.VALID_TO_DTTM) > &AS_AT_MTH  
			;

QUIT;
		