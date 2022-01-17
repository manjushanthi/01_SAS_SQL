PROC SQL ;

OPTIONS MISSING='';

/*Create Temp table to load the extracted Data*/

	CREATE TABLE WORK.S1101_D6_BASE AS 

		SELECT 
			XIP.PORTFOLIO_CLASSIFICATION  AS A1
			, COALESCE (RFF.CLIENT_ID,'Not Ring Fenced') AS A2 LENGTH=50
			, COALESCE (UNT_INDX.UNIT_INDEX_LINKED_FLAG,'N') AS A3 
			, COALESCE (TRIM(B.ISSUE_CD),TRIM(C.ISSUE_CD)) AS A4 LENGTH=50

			, CASE 
				WHEN A.X_RPT_ID_TYPE_OVRD = '99' THEN 'UNDERTAKING'	
				WHEN A.X_RPT_ID_TYPE_OVRD = '1'  THEN 'ISIN'	 
				WHEN A.X_RPT_ID_TYPE_OVRD = '2'  THEN 'CUSIP'
				ELSE 'DATA QUALITY ISSUE'
			  END AS A5
 
			, CASE 
				WHEN (SUBSTR(CALCULATED A4,1,5) IN ('EURCC','USDCC','GBPCC') 
					 OR SUBSTR(CALCULATED A4,1,7) IN ('USD_Col','GBP_Col','EUR_Col')) THEN '1' 
				WHEN (TRIM(STC.SM_SEC_GROUP) = 'CASH' AND TRIM(STC.SM_SEC_TYPE) = 'COLLATERAL') THEN '1'
				ELSE COALESCE(A.X_COLLATERAL_STATUS,'9')
			  END AS A6

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN ('71','75') 
					THEN 'Not Applicable - CIC' 

				WHEN PAM_USE.PAM_CUSIP IS NOT NULL AND UPCASE(ACC_GL_GROUP_DESC) <> 'CASH EQUIVALENTS' 
					/*CORRECT DATA QUALITY IN PAM FOR XS0276103156 WHERE THE SECOND LINE IS DIFFERENT*/
					THEN TRIM(PAM_USE.ACC_SECURITY_DESC_LINE_1)||' - '||CASE WHEN B.ISSUE_CD IN ('XS0276103156','XS0731849831') THEN 'SENIOR CORP BND' ELSE TRIM(COALESCE(PAM_USE.ACC_SECURITY_DESC_LINE_2,'')) END||' - '||TRIM(COALESCE(PAM_USE.ACC_SECURITY_DESC_LINE_3,''))
	
				WHEN PAM_USE.PAM_CUSIP IS NOT NULL AND UPCASE(ACC_GL_GROUP_DESC) = 'CASH EQUIVALENTS' 
					THEN TRIM(PAM_USE.ACC_SECURITY_DESC_LINE_1)||' - '||TRIM(PAM_USE.ACC_SECURITY_DESC_LINE_2)

				WHEN PAM_USE.PAM_CUSIP IS NULL AND SUBSTR(CIC.ISSUE_CD,3,2) = '72' AND CALCULATED A6 NOT IN ('1') 
					THEN TRIM(A.FINANCIAL_INSTRUMENT_NM)||' - Cash deposits with '||TRIM(A.X_ISSUER_NM)

				WHEN PAM_USE.PAM_CUSIP IS NULL AND SUBSTR(CIC.ISSUE_CD,3,2) = '72' AND CALCULATED A6 IN ('1') 
					THEN TRIM(A.FINANCIAL_INSTRUMENT_NM)||' - Pledged cash with '||TRIM(A.X_ISSUER_NM)

				WHEN PAM_USE.PAM_CUSIP IS NULL AND TRIM(STC.SM_SEC_GROUP) = 'BND' 
					THEN TRIM(STC.SM_SEC_TYPE)||' BOND - '||A.FINANCIAL_INSTRUMENT_NM 

				ELSE A.FINANCIAL_INSTRUMENT_NM 
			 END AS A7 LENGTH = 500

			 , COALESCE(A.X_ISSUER_NM,'-') AS A8 LENGTH=100

			   /* 25/12/2021 - CURRENTLY ISSUE IN PROD FINANCIAL INSTRUMENT.X_LEI_CD  AND FINANCIAL INSTRUMENT X_LEI_STATUS
			   Issues in PROD in LEI  were status is set to 9 when the length of the LEI Code is set to 20 and a proper LEI
			   IMPACTING A31--> C0210 , A33 --> C0220 */
			 , CASE 
				 WHEN A.X_LEI_STATUS = '1' OR LENGTH(TRIM(A.X_LEI_CD)) = 20 THEN COALESCE(A.X_LEI_CD,'-') 
				 ELSE '-' 
			   END AS A31 LENGTH=50

			 , CASE WHEN LENGTH(TRIM(A.X_LEI_CD)) = 20 THEN '1' 
					ELSE COALESCE(A.X_LEI_STATUS,'-') 
				END AS A33 	LENGTH=50

			 , COALESCE(A.X_NACE_CD,'-') AS A9 LENGTH=50

			 , CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN ('71','75') THEN 'Not Applicable - CIC'  	
				ELSE UPCASE(TRIM(COALESCE(A.X_ISSUER_GRP_NM,'-'))) 
			   END AS A10 LENGTH=100

			   /* 25/12/2021 - CURRENTLY ISSUE IN PROD FINANCIAL INSTRUMENT.X_ISSUER_GRP_LEI_CD  AND FINANCIAL INSTRUMENT X_ISSUER_GRP_LEI_STATUS 
			   Issues in PROD in LEI  were status is set to 9 when the length of the LEI Code is set to 20 and a proper LEI
			   IMPACTING A32--> C0250 , A33GROUP --> C0260 */ 
			 , CASE 
				 WHEN  A.X_ISSUER_GRP_LEI_STATUS = '1'  OR LENGTH(A.X_ISSUER_GRP_LEI_CD) = 20 THEN COALESCE(A.X_ISSUER_GRP_LEI_CD,'-') 
				 ELSE '-'
			   END AS A32 LENGTH=50

			 , CASE 
					WHEN LENGTH(TRIM(A.X_ISSUER_GRP_LEI_CD)) = 20 THEN '1' 
					ELSE COALESCE(A.X_ISSUER_GRP_LEI_STATUS,'-') 
			 	END AS A33GROUP LENGTH=50

			 , CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN ('71','75') THEN 'Not Applicable - CIC' 
				ELSE 
					CASE 
					 WHEN  A.X_COUNTRY_OF_ISSUE_CD = 'SP' THEN 'XA' 
					 ELSE  A.X_COUNTRY_OF_ISSUE_CD 
					END
			   END AS A11

			 , CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('8') THEN  'Not Applicable - CIC'   
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN ('71','75') THEN  'Not Applicable - CIC' 
				ELSE COALESCE(A.X_COUNTRY_OF_CUSTODY,XIP.COUNTRY_OF_CUSTODY)
			   END AS A12

			   /*BV237 , BV982*/
			 , CASE WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN ('75') THEN  'Not Applicable - CIC' 
					ELSE F.CURRENCY_CD 
			   END AS A13 LENGTH=50

			 , CIC.ISSUE_CD AS A15
			 , CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) NOT IN ('3','4') THEN 'Not Applicable - CIC'
				ELSE COALESCE(A.X_PARTICIPATION_CD,PRTCP.PARTICIPATION_CD ,'CHECK_EIOPA_CD')
			   END AS A16

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('3','4','7') THEN 'Not Applicable - CIC' 
				ELSE COALESCE (INSTR_555_Rating.ASSESSMENT_GRADE,INSTR_999_Rating.ASSESSMENT_GRADE,'NR')
			  END AS A17

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('3','4','7') THEN 'Not Applicable - CIC' 
				ELSE COALESCE (INSTR_555_Rating.ASSESSMENT_AGENCY_CD,INSTR_999_Rating.ASSESSMENT_AGENCY_CD,'NR')
			  END AS A18 LENGTH = 20

			, CASE /*BV789 & BV984*/
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '3','7','8') THEN 'Not Applicable - CIC' 
				ELSE COALESCE(PUT(XFPC.X_MOD_DUR,10.2),'-') 
			  END AS A20	

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '1','2','5','6','7','8') THEN 'Not Applicable - CIC' 
				  ELSE 
				    CASE 
					  WHEN PUT(A.PRESENT_VALUE_AMT,18.2) <> '0.00'  AND PUT(XFPC.X_LOCAL_MKT_VALUE,18.2) <> '0.00' 
						THEN PUT((F.HOLDINGS_NO / EXC.I_T_CURRENCY_RATE),18.2)
					  ELSE 
						PUT(F.HOLDINGS_NO,18.2) 
					END 
			   END AS A22BRS

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '1','2','5','6','7','8') THEN 'Not Applicable - CIC' 
				  ELSE 
					CASE 
					  WHEN PUT(PAM_USE.ACC_UNITS,18.2) = '' 
						THEN '' 
					  ELSE 
						CASE 
							WHEN PUT(A.PRESENT_VALUE_AMT,18.2) <> '0.00'  AND PUT(XFPC.X_LOCAL_MKT_VALUE,18.2) <> '0.00' 
							   THEN PUT( ( PAM_USE.ACC_UNITS / EXC.I_T_CURRENCY_RATE ), 18.2 )  
							ELSE 
								PUT( PAM_USE.ACC_UNITS , 18.2 ) 
						END
					END 
				END AS A22PAM

			, CASE 
				 WHEN (F.SOURCE_SYSTEM_CD  = 'NONBLR' 
					  AND ( SUBSTR(CIC.ISSUE_CD,3,1)  IN ('1', '2','5','6','8') OR SUBSTR(CIC.ISSUE_CD,3,2)  IN ( '72','73','74')))
				    THEN 
					
								 PUT(F.HOLDINGS_NO,18.2) 
						
				ELSE 
					CASE 
						WHEN (F.SOURCE_SYSTEM_CD  <>  'NONBLR' 
						     AND (SUBSTR(CIC.ISSUE_CD,3,1)  IN ('1', '2','5','6','8') OR SUBSTR(CIC.ISSUE_CD,3,2)  IN ( '72','73','74')))
						   THEN CASE 
								   WHEN PUT(A.X_ORIG_FACE,18.2) = ''
								THEN 
									'' 
								ELSE 
									PUT( ( A.X_ORIG_FACE / EXC.I_T_CURRENCY_RATE  ) , 18.2 )    
					 			END
						ELSE 
							'Not Applicable - CIC'
					END
			    END AS A22ABRS

			, CASE 
				WHEN (SUBSTR(CIC.ISSUE_CD,3,1) IN ('1', '2','5','6','8') OR SUBSTR(CIC.ISSUE_CD,3,2)  IN ( '72','73','74')) 
					THEN  
						CASE 
							WHEN UPCASE(PAM_USE.ACC_GL_GROUP_DESC) IN ('BONDS BACKED BY GOVT NON US'
																		, 'GLOBAL CORPORATES'
																		, 'GLOBAL GOVT AGENCIES'
																		, 'GLOBAL GOVT BONDS'
																		, 'HYBRIDS'
																		, 'OTHER TAXABLE BONDS'
																		, 'SUPRANATIONALS'
																		, 'UK GOVT BONDS'
																		, 'US CORPORATES'
																		, 'TERM NOTES'
																		, 'SHORT TERM INVESTMENTS'
																		, 'RESIDUALS'
																		, 'ASSET BACKED SECURITIES'
																		, 'RMBS'
																		, 'AGENCY CMBS'
																		, 'CMBS'
																		, 'US GOVT BONDS'
																		, 'CP'
																		, 'CD - CASH BALANCE LT'
																		, 'CASH EQUIVALENTS'
																		, 'CRE') 
							THEN 
								CASE 
									WHEN PUT(PAM_USE.ACC_UNITS,18.2) = ''
										THEN 
											'' 
									ELSE 
										PUT ( ( PAM_USE.ACC_UNITS  / EXC.I_T_CURRENCY_RATE  ), 18.2 )  
								END
							ELSE 
								CASE 
									WHEN PUT(PAM_USE.ACC_OFV,18.2) = ''
										THEN 
											'' 
									ELSE 
										PUT( ( PAM_USE.ACC_OFV  / EXC.I_T_CURRENCY_RATE  ) , 18.2)
								END

							END	

				ELSE 
					'Not Applicable - CIC'
			  END AS A22APAM

			, CASE
				WHEN F.SOURCE_SYSTEM_CD  = 'NONBLR' 
					THEN 
						CASE 
							WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '1','2','5','6','7','8') 
								THEN 'Not Applicable - CIC' 
							ELSE   		
								CASE 
									WHEN SUBSTR(CIC.ISSUE_CD,3,2)  IN ( '39')
										THEN  
											PUT  ( ( ( A.PRESENT_VALUE_AMT  /  A.FACE_VALUE_AMT ) *100 ) , 18.5)
									ELSE		
										PUT ( ( ( ( A.PRESENT_VALUE_AMT  - XFPC.X_ACC_INT )  / F.HOLDINGS_NO) *100) , 18.5)
								END
						END 				
					ELSE
						CASE 
							WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN  ( '1','2','5','6','7','8') 
								THEN 'Not Applicable - CIC'  
							ELSE 
								CASE 
									WHEN PUT(XFPC.X_PXS_DEC_ONLY,18.5) ^= '' AND STC.SM_SEC_TYPE IN ('OPEN_END','STIF') 
										THEN 
											PUT ( (100*XFPC.X_PXS_DEC_ONLY) , 18.5 )  
									ELSE 
										PUT( XFPC.X_PXS_DEC_ONLY , 18.5 )		
								END	
						END 						   
			END	AS A23BRS

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ('1','2','5','6','7','8') 
					THEN 'Not Applicable - CIC' 
				ELSE  						
					CASE 
						WHEN PUT(PAM_USE.ACC_PRICE,18.5) = '' 
							THEN ''  
						ELSE 
							CASE 
								WHEN STC.SM_SEC_TYPE IN ('OPEN_END','STIF') 
									THEN PUT( ( (100*PAM_USE.ACC_PRICE) *  EXC.I_T_CURRENCY_RATE ), 18.5 )
								ELSE
									PUT( (PAM_USE.ACC_PRICE * EXC.I_T_CURRENCY_RATE ) , 18.5 )
							END 
					END 
			 END AS A23PAM

			, CASE 
				WHEN F.SOURCE_SYSTEM_CD  = 'NONBLR'  
					THEN 
						CASE 
							WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '3','4') 
								THEN  'Not Applicable - CIC'
							ELSE 
								PUT ( ( ( ( A.PRESENT_VALUE_AMT -   XFPC.X_ACC_INT  )  / F.HOLDINGS_NO ) *100) , 20.16)
						END

					ELSE 
						CASE 
							WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '3','4') 
								THEN PUT(0.000000000000,20.16)
							ELSE 
								CASE 
									WHEN (PUT(F.HOLDINGS_NO,25.13) ^='' AND PUT(F.HOLDINGS_NO,25.13) ^='0.00')
										THEN 
											PUT  ( ( ( (XFPC.X_LOCAL_MKT_VALUE -  XFPC.X_LOCAL_ACC_INT)    /   F.HOLDINGS_NO)  * 100) , 20.16)  
										ELSE 
											PUT(0.00000000000000,20.16) 		
								END				
						END  
			END AS A23ABRS


			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '3','4') 
					THEN 'Not Applicable - CIC'
				ELSE  
					CASE
						WHEN F.PORTFOLIO_ID IN ('A_320QUKIM','A_320UKJPM','A_320VUKRL')
							THEN 
								PUT( ( ( (F.X_SOLVENCY_II_VALUE - PAM_USE.ACC_END_ACCRUED) / ( PAM_USE.ACC_UNITS  / EXC.I_T_CURRENCY_RATE )) * 100) ,20.16) 
						ELSE 	
							PUT  ( ( ( (  PAM_USE.ACC_MARKET_VALUE  *  EXC.I_T_CURRENCY_RATE  )     / PAM_USE.ACC_UNITS )   * 100	),20.16)
					END
			END   AS A23APAM

			, COALESCE(A.X_VALUATION_METHOD_SII,XIP.VALUATION_METHOD_SII) AS A24


			, CASE WHEN F.SOURCE_SYSTEM_CD  = 'NONBLR'  
					THEN 
						CASE WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '7','8')  
								THEN 
									'Not Applicable - CIC' 
								ELSE 
									CASE 
										WHEN SUBSTR(CIC.ISSUE_CD,3,2) IN  ( '39' , '31' ) /*Include all the Equities*/
											THEN PUT ( ((A.BOOK_VALUE_AMT/A.FACE_VALUE_AMT)*100) , 18.10) 
										ELSE PUT (( A.BOOK_VALUE_AMT*100 ) , 18.10 ) 
									END
						END
				    ELSE		
						CASE WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '7','8')  
								THEN 
									'Not Applicable - CIC' 
								ELSE 
									PUT ((((A.BOOK_VALUE_AMT/F.HOLDINGS_NO)*100) * EXC.I_T_CURRENCY_RATE ) , 18.10) 
						END	
				END AS A25BRS
		 
			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ( '7','8')  
					THEN 'Not Applicable - CIC' 
				ELSE PUT((((PAM_USE.ACC_Actual_BV/PAM_USE.ACC_UNITS)*100) * EXC.I_T_CURRENCY_RATE ) , 18.10) 
			   END AS A25PAM

			, A.PRESENT_VALUE_AMT	AS	A26BRS
			
			, (COALESCE(PAM_USE.ACC_MARKET_VALUE,0.00)+COALESCE(PAM_USE.ACC_END_ACCRUED,0.00)) AS A26PAM 

			, F.X_SOLVENCY_II_VALUE AS A26FIN_SDW

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ('3','4', '7')   
					THEN 'Not Applicable - CIC' 
				ELSE 
					PUT(A.MATURITY_DT,DDMMYY10.)  
			   END 	AS A28
	
			 , XFPC.X_ACC_INT AS A30BRS FORMAT=18.2

			 , PAM_USE.ACC_END_ACCRUED AS A30PAM FORMAT=18.2

			 ,  XIP.ENTITY_NAME AS A50

			 ,  F.PORTFOLIO_ID AS INT1

			 , XIP.INTERNAL_ORG_REFERENCE_NO AS INT1A

			 , SUBSTR(TRIM(CIC.ISSUE_CD),3,1) AS INT2

			 , CIC_CAT.X_CIC_CATEGORY_NM AS INT2A
						
			 , CIC_CAT.X_CIC_SUB_CATEGORY_NM AS INT2B

			 , COALESCE(A.X_PAM_GL_GRP,'-') AS INT3

			 , COALESCE(PAM_USE.ACC_GL_GROUP_DESC,'-') AS INT4

			 , A.X_I_T_INV_CLS_GROUP_OVRD AS INT5

			 , A.X_I_T_INV_CLS_CATEGORY_OVRD AS INT6

			 , COALESCE(A.X_LEH_SUBSECTOR_CD , '-') AS INT7	

			 , STC.SM_SEC_TYPE AS SM_SEC_TYPE

			 , MONTH(&AS_AT_MTH) AS INT9

			, YEAR(&AS_AT_MTH) AS INT10

			, A.SOURCE_SYSTEM_CD AS SOURCE_SYSTEM_CD

			, XIP.ENTITY_LEI_CD 

			, XIP.ENTITY_LEI_STATUS

			, A.X_CUSTODIAN_OVRD AS CUSTODIAN	

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) NOT IN  ('1','2','5','6','8') 
					THEN 'Not Applicable - CIC'
				ELSE XFPC.X_INTERNAL_RATING 
			   END AS X_INTERNAL_RATING

			, INFRASTRUCTURE_INV_CD

			, C.ISSUE_CD AS CUSIP

			, STC.SM_SEC_GROUP AS SM_SEC_GROUP								

			, A.INFRA_CORP_BONDS
											
			, A.INFRA_CORP_BONDS_OVRD 
											
			, A.X_STRUCTURE

	/****************EXTRA COLUMNS**********************************/	

			, CASE
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) <> '85' AND  UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'YES' AND CALCULATED SOLII_CREDIT_QUALITY  IN ('0', '1', '2', '3','','9') AND TRIM(ISS_CNTRY.CNTRY_TYP) IN ('EEA','OECD') AND A.X_STRUCTURE NOT LIKE '%NQ - O%'   THEN '19'
				WHEN (SUBSTR(CIC.ISSUE_CD,3,2)<> '85' AND  UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'YES' AND CALCULATED SOLII_CREDIT_QUALITY  IN ('0', '1', '2', '3','','9') AND TRIM(ISS_CNTRY.CNTRY_TYP) IN ('3RD') OR A.X_STRUCTURE LIKE '%NQ - O%')   THEN '9'
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) <> '85' AND  UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'YES' AND CALCULATED SOLII_CREDIT_QUALITY  IN ('4', '5', '6') THEN '9'
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) <> '85' AND  UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'NO'		THEN '1'
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) =  '85' AND  XIP.PORTFOLIO_ID = 'A_320VUKRL' THEN  '1'
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) =  '85' AND  (INFRASTRUCTURE_INV_CD = '' OR INFRASTRUCTURE_INV_CD ='9') THEN  '9'
				WHEN SUBSTR(CIC.ISSUE_CD,3,2) =  '85' AND  INFRASTRUCTURE_INV_CD <> ''	THEN  INFRASTRUCTURE_INV_CD
				ELSE 'CHECK X_EIOPA_CD' 
			END AS C0300

			, CASE 
				WHEN SUBSTR(CIC.ISSUE_CD,3,1) = '4' THEN '1' 
			    ELSE 'Not Applicable - CIC' 
			  END AS C0292

			, CASE 
					WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('3','4','7') THEN '' 
					ELSE PUT(COALESCE (INSTR_555_Rating.X_SOLII_CREDIT_QUALITY_VAL,INSTR_999_Rating.X_SOLII_CREDIT_QUALITY_VAL,9),1.0)
			  END AS SOLII_CREDIT_QUALITY LENGTH = 20

			, A.X_EXPERT_JUDGEMENT_FIN_INV_CLS AS FIN_SOLII_CLS LENGTH = 50

			, A.X_LEI_CD AS A31_TRUE LENGTH=50

			, X_ISSUER_GRP_LEI_CD AS A32_TRUE LENGTH=50

			, A.X_LEI_STATUS AS A33_TRUE  LENGTH=50

			, A.X_ISSUER_GRP_LEI_STATUS AS A33GROUP_TRUE  LENGTH=50

			, INPUT( (CASE 
					WHEN COALESCE(CALCULATED A25PAM, CALCULATED A25BRS,'0.00') = 'Not Applicable - CIC'	THEN ''
					ELSE COALESCE(CALCULATED A25PAM, CALCULATED A25BRS,'0.00')
			  END) , 12.4)  AS C0160_CALC

			, COALESCE(A.X_DEBTOR_NM,'-') AS X_DEBTOR_NM

			, COALESCE(A.X_DEBTOR_GRP_NM,'-') AS X_DEBTOR_GRP_NM

			, X_ASSET_PLEDGED_TYPE AS X_ASSET_PLEDGED_TYPE


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


			/*join on X_RING_FENCED_FUNDS*/
			LEFT JOIN 				
				(				
					SELECT 			
						DISTINCT
							PORTFOLIO_ID
							,CUSIP
							,ISIN
							,CLIENT_ID
					FROM 			
						test.X_RING_FENCED_FUNDS
					WHERE			
						DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH 				
						AND DATEPART(VALID_TO_DTTM) > &AS_AT_MTH
						AND AS_AT_MTH = &AS_AT_MTH 	
				) RFF				
			ON 	
				RFF.PORTFOLIO_ID  = XIP.PORTFOLIO_ID	
				AND  RFF.ISIN = B.ISSUE_CD 
				AND RFF.CUSIP = C.ISSUE_CD

			/*join on X_ASSETS_LINKED_FUNDS*/
			LEFT JOIN 				
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
						AND AS_AT_MTH = &AS_AT_MTH 
				) UNT_INDX				
			ON 	
				UNT_INDX.PORTFOLIO_ID  = XIP.PORTFOLIO_ID	
				AND (UNT_INDX.ISIN = B.ISSUE_CD = UNT_INDX.CUSIP = C.ISSUE_CD )
				
			
			/*join on X_ASSETS_COLLATERAL*/
			LEFT JOIN 				
				(
					SELECT 				
						DISTINCT
							PORTFOLIO_ID,
							CUSIP,
							ISIN,
							CLIENT_ID,
							COLLATERAL_CLASSIFICATION
					FROM 			
						test.X_ASSETS_COLLATERAL
					WHERE			
						DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH 				
						AND DATEPART(VALID_TO_DTTM) > &AS_AT_MTH
						AND AS_AT_MTH = &AS_AT_MTH	
				) ASTS_CLTRL				
			ON 
				ASTS_CLTRL.PORTFOLIO_ID  = XIP.PORTFOLIO_ID	
			    AND (ASTS_CLTRL.ISIN = B.ISSUE_CD = ASTS_CLTRL.CUSIP = C.ISSUE_CD )

			/*join on X_PARTICIPATIONS*/
			LEFT JOIN 				
				(				
					SELECT 			
						DISTINCT
							PORTFOLIO_ID,
							CUSIP,
							ISIN,
							CLIENT_ID,
							PARTICIPATION_CD
					FROM 			
						test.X_PARTICIPATIONS
					WHERE			
						DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH 				
						AND DATEPART(VALID_TO_DTTM) > &AS_AT_MTH
						AND AS_AT_MTH = &AS_AT_MTH
				) PRTCP				
			ON 				
				PRTCP.PORTFOLIO_ID  = XIP.PORTFOLIO_ID	
				AND (PRTCP.ISIN = B.ISSUE_CD = PRTCP.CUSIP = C.ISSUE_CD )


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
						, ACC_COST
						, ACC_OFV 

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
							, ACC_COST
							, ACC_OFV 
																																					
					  FROM																																
						test.X_BLKRK_ACCT																															

					  WHERE																																
						 DATEPART(VALID_FROM_DTTM) <= &AS_AT_MTH 																													
						  AND DATEPART(VALID_TO_DTTM) > &AS_AT_MTH 
	
						) PAM																															
							ON A_FIN.FINANCIAL_INSTRUMENT_RK = PAM.FINANCIAL_INSTRUMENT_RK																															
							AND TICKER = PORTFOLIO_ID																															
							AND (C_FIN.ISSUE_CD =  PAM.BRSID OR X_PAM_SEC_ID = ACC_PRIMARY_SEC_ID)																															
							AND UPCASE(TRIM(ACC_GL_GROUP_DESC)) NOT IN ('FUTURES','FUTURES - BOND','INTEREST RATE SWAPS','SWAPS','FORWARDS','INTEREST RATE SWAPS CCS','FX SPOTS')
							AND DATEPART(A_FIN.VALID_FROM_DTTM) <= &AS_AT_MTH 	
							AND DATEPART(A_FIN.VALID_TO_DTTM) > &AS_AT_MTH 	
								
				)PAM_USE																															
																																			
				ON 	  																														
					PAM_USE.PAM_SEC_ID = A.X_PAM_SEC_ID																																																											
					AND PAM_USE.PAM_PORTFOLIO = F.PORTFOLIO_ID																															
					AND PAM_USE.FINANCIAL_INSTRUMENT_RK = A.FINANCIAL_INSTRUMENT_RK		

				LEFT JOIN 
				(
					SELECT 
						DISTINCT 
						  COUNTRY_CD
						  , X_EEA_MEMBER_FLAG
						  , X_OECD_MEMBER_FLAG
						  , CASE
								WHEN (X_EEA_MEMBER_FLAG = 'Y' AND X_OECD_MEMBER_FLAG = 'Y') THEN 'EEA'
								WHEN (X_EEA_MEMBER_FLAG = 'Y' AND X_OECD_MEMBER_FLAG = 'N') THEN 'EEA'
								WHEN (X_EEA_MEMBER_FLAG = 'N' AND X_OECD_MEMBER_FLAG = 'Y') THEN 'OECD'
								WHEN (X_EEA_MEMBER_FLAG = 'N' AND X_OECD_MEMBER_FLAG = 'N') THEN '3RD'
							END AS CNTRY_TYP
					FROM 
						test.COUNTRY 

					WHERE 
						PUT(DATEPART(VALID_TO_DTTM),DATE9.) = '31DEC9999'	

				)ISS_CNTRY
				ON ISS_CNTRY.COUNTRY_CD = A.X_COUNTRY_OF_ISSUE_CD

				
		LEFT JOIN
		test_mar.CM_NACE_CD_VALID_LIST  NC
			ON A.X_NACE_CD = 	NC.NACE_CD
																				
		WHERE 
			DATEPART(A.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
			AND DATEPART(A.VALID_TO_DTTM) > &AS_AT_MTH 
			AND SUBSTR(TRIM(CIC.ISSUE_CD),3,1) IN ('0','1','2','3','4','5','6','7','8')
			AND A.X_COLLATERAL_STATUS =  '55'
			AND UPCASE(A.X_I_T_INV_CLS_CATEGORY_OVRD) <> 'EXCLUDE'
			AND UPCASE(A.X_I_T_INV_CLS_CATEGORY_OVRD) = 'COLLATERAL-HELD'

ORDER BY 
			SUBSTR(TRIM(CIC.ISSUE_CD),3,2)
			, STC.SM_SEC_GROUP
			, STC.SM_SEC_TYPE
			
	;
QUIT;