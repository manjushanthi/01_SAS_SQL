/* 999 - System calculated Rating */
/* 555 - Business Assigned Rating */

PROC SQL ;
	/*Create Temp table to load the extracted Data*/
	CREATE TABLE WORK.S0801_D1_VALD15_INFRA AS 

	SELECT 
		
		PUT(&AS_AT_MTH,DDMMYY10.) AS ASOF_Date
		, XIP.ENTITY_NAME
		, XIP.INTERNAL_ORG_REFERENCE_NO
		, XIP.PORTFOLIO_ID
		, C1.ISSUE_CD AS CUSIP
		, B1.ISSUE_CD AS ISIN
		, SM_SEC.SM_SEC_GROUP
		, SM_SEC.SM_SEC_TYPE
		, A1.X_ISSUER_NM AS ISSUER_NM
		, A1.X_NACE_CD AS ISSUER_SECTOR
		, PREV_Q.ISSUER_SECTOR AS ISSUER_SECTOR_PREV
		, CIC1.ISSUE_CD AS CIC
		, A1.X_ISSUER_GRP_NM AS ISSUER_GRP_NM
		, CASE 
				WHEN SUBSTR(CIC1.ISSUE_CD,3,1) IN ('3','4','7','8') THEN '' 
				ELSE COALESCE (INSTR_555_Rating.ASSESSMENT_GRADE,INSTR_999_Rating.ASSESSMENT_GRADE,'NR')
		  END AS A17
		, CASE 
				WHEN SUBSTR(CIC1.ISSUE_CD,3,1) IN ('3','4','7','8') THEN '' 
				ELSE COALESCE (INSTR_555_Rating.ASSESSMENT_AGENCY_CD,INSTR_999_Rating.ASSESSMENT_AGENCY_CD,'NR')
		  END AS A18
		, CASE 
				WHEN SUBSTR(CIC1.ISSUE_CD,3,1) IN ('3','4','7','8') THEN '' 
				ELSE PUT(COALESCE (INSTR_555_Rating.X_SOLII_CREDIT_QUALITY_VAL,INSTR_999_Rating.X_SOLII_CREDIT_QUALITY_VAL,9),1.0)
		  END AS SOLII_CREDIT_QUALITY
		 , X_COUNTRY_OF_ISSUE_CD
		 , ISS_CNTRY.CNTRY_TYP

		 , CASE
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2)  <> '85' AND  UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'YES' AND CALCULATED SOLII_CREDIT_QUALITY  IN ('0', '1', '2', '3','','9') AND TRIM(ISS_CNTRY.CNTRY_TYP) IN ('EEA','OECD') AND A1.X_STRUCTURE NOT LIKE '%NQ - O%'   THEN '19 - Infrastructure qualifying: Other'
				WHEN (SUBSTR(CIC1.ISSUE_CD,3,2) <> '85' AND UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'YES' AND CALCULATED SOLII_CREDIT_QUALITY  IN ('0', '1', '2', '3','','9') AND TRIM(ISS_CNTRY.CNTRY_TYP) IN ('3RD') OR A1.X_STRUCTURE LIKE '%NQ - O%')   THEN '9 - Infrastructure non-qualifying: Other'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2)<> '85' AND UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'YES' AND CALCULATED SOLII_CREDIT_QUALITY  IN ('4', '5', '6') AND A1.X_STRUCTURE LIKE '%NQ - O%' THEN '9 - Infrastructure non-qualifying: Other'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2)<> '85' AND UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'YES' AND CALCULATED SOLII_CREDIT_QUALITY  IN ('4', '5', '6') AND A1.X_STRUCTURE LIKE '%SENIOR_O%' THEN '19 - Infrastructure qualifying: Other'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2)<> '85' AND UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'YES' AND CALCULATED SOLII_CREDIT_QUALITY  IN ('4', '5', '6') THEN '9 - Infrastructure non-qualifying: Other'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2)<> '85' AND UPCASE(TRIM(NC.INFRA_CORP_FLAG)) = 'NO'		THEN '1 - Not an infrastructure investment '
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND XIP.PORTFOLIO_ID = 'A_320VUKRL' THEN  '1 - Not an infrastructure investment '
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND (INFRASTRUCTURE_INV_CD = '' OR INFRASTRUCTURE_INV_CD ='9') THEN  '9 - Infrastructure non-qualifying: Other'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND INFRASTRUCTURE_INV_CD ='19' 	THEN  '19 - Infrastructure qualifying: Other'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND INFRASTRUCTURE_INV_CD = '1' 	THEN  '1 - Not an infrastructure investment'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND INFRASTRUCTURE_INV_CD = '2' 	THEN  '2 - Infrastructure non-qualifying: Government Guarantee'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND INFRASTRUCTURE_INV_CD = '12' 	THEN '12 - Infrastructure qualifying: Government Guarantee'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND INFRASTRUCTURE_INV_CD = '3' 	THEN  '3 - Infrastructure non-qualifying: Government Supported'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND INFRASTRUCTURE_INV_CD = '13' 	THEN  '13 - Infrastructure qualifying: Government Supported'
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND INFRASTRUCTURE_INV_CD = '4' 	THEN  '4 - Infrastructure non-qualifying: Supranational Guarantee/Supported'					
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND INFRASTRUCTURE_INV_CD = '14' 	THEN  '14 - Infrastructure qualifying: Supranational Guarantee/Supported'		
				WHEN SUBSTR(CIC1.ISSUE_CD,3,2) = '85' AND INFRASTRUCTURE_INV_CD = '20' 	THEN  '20 - European Long-Term Investment Fund'		
				ELSE 'CHECK X_EIOPA_CD' 
			END AS C0300 

		, CASE 
				WHEN SUBSTR(CIC,3,1) = '8' THEN 'PHYSICAL INFRASTRUCTURE' 
				ELSE 'CORPORATE INFRASTRUCTURE' 
		   END AS TYP
				
		, F1.X_SOLVENCY_II_VALUE

		, CASE 
			WHEN CALCULATED C0300 LIKE '%non-qualifying%' THEN 'Non-Qualifying S2 Infra'  
			ELSE 'Qualifying S2 Infra' 
		  END AS QUAL_TYP

	FROM 
		test.FINANCIAL_INSTRUMENT A1

		INNER JOIN 	/*FINANCIAL POSITION */
		test.FINANCIAL_POSITION F1																															
			ON F1.FINANCIAL_INSTRUMENT_RK = A1.FINANCIAL_INSTRUMENT_RK																															
			AND DATEPART(F1.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
			AND DATEPART(F1.VALID_TO_DTTM) > &AS_AT_MTH


		LEFT JOIN 																															
		test.FINANCIAL_INSTRUMENT_ISSUE B1 /* ISIN */
			ON  A1.FINANCIAL_INSTRUMENT_RK = B1.FINANCIAL_INSTRUMENT_RK																															
			AND DATEPART(B1.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
			AND DATEPART(B1.VALID_TO_DTTM) > &AS_AT_MTH 																														
			AND B1.ISSUE_TYPE_CD = '001'																															

		LEFT JOIN 																															
		test.FINANCIAL_INSTRUMENT_ISSUE C1 /* CUSIP */
			ON  A1.FINANCIAL_INSTRUMENT_RK = C1.FINANCIAL_INSTRUMENT_RK																															
			AND DATEPART(C1.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
			AND DATEPART(C1.VALID_TO_DTTM) > &AS_AT_MTH 																														
			AND C1.ISSUE_TYPE_CD = '003'

		LEFT JOIN /*join on X_INVESTMENT_PORTFOLIO*/
		test.X_INVESTMENT_PORTFOLIO XIP																															
			ON  XIP.PORTFOLIO_ID = F1.PORTFOLIO_ID 																													
			AND PUT(DATEPART(XIP.VALID_TO_DTTM),DATE9.) = '31DEC9999'

		LEFT JOIN 
		test.X_INVST_CLASS_STC SM_SEC								  	
			ON (SM_SEC.SM_SEC_GROUP_CD = A1.FINANCIAL_INSTRUMENT_TYPE_CD
			AND SM_SEC.SM_SEC_TYPE_CD = A1.X_FINANCIAL_INSTR_SUB_TYPE_CD)

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
		) CIC1																															
			ON  A1.FINANCIAL_INSTRUMENT_RK = CIC1.FINANCIAL_INSTRUMENT_RK																															
			AND CIC1.ISSUE_TYPE_CD = '002'

		LEFT JOIN
		test_mar.CM_NACE_CD_VALID_LIST  NC
			ON A1.X_NACE_CD = 	NC.NACE_CD

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
		ON ISS_CNTRY.COUNTRY_CD = X_COUNTRY_OF_ISSUE_CD

		LEFT JOIN				
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
		 ON A1.FINANCIAL_INSTRUMENT_RK = LOAN.FINANCIAL_INSTRUMENT_RK

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
					A1.FINANCIAL_INSTRUMENT_RK = INSTR_999_Rating.FINANCIAL_INSTRUMENT_RK	

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
					A1.FINANCIAL_INSTRUMENT_RK = INSTR_555_Rating.FINANCIAL_INSTRUMENT_RK

			LEFT JOIN
			(
				SELECT 	
					XIP.ENTITY_NAME 
					, XIP.INTERNAL_ORG_REFERENCE_NO 
					, XIP.PORTFOLIO_ID 
					, A.FINANCIAL_INSTRUMENT_ID 
					, C.ISSUE_CD AS CUSIP
					, B.ISSUE_CD AS ISIN 
					, A.X_CLIENT_ID AS CLIENT_ID 
					, SM_SEC.SM_SEC_GROUP 
					, SM_SEC.SM_SEC_TYPE 
					, CIC.ISSUE_CD AS CIC 
					, X_ISSUER_NM AS ISSUER_NAME
					, X_LEI_CD AS ISSUER_LEI 
					, CASE 
							WHEN X_LEI_STATUS = '1' OR LENGTH(TRIM(X_LEI_CD))=20 THEN 'LEI' 
							WHEN X_LEI_STATUS = '2' THEN 'SC' 
							ELSE 'None' 
					  END AS ISSUER_LEI_TYPE  
					, X_ISSUER_GRP_NM AS ULT_ISSUER_NAME
					, X_ISSUER_GRP_LEI_CD AS ULT_ISSUER_LEI 
					, CASE 
							WHEN X_ISSUER_GRP_LEI_STATUS = '1'  OR LENGTH(TRIM(X_ISSUER_GRP_LEI_CD))=20 THEN 'LEI' 
							WHEN X_ISSUER_GRP_LEI_STATUS = '2' THEN 'SC' 
							ELSE 'None' 
					   END AS ULT_ISSUER_LEI_TYPE , 
					   X_NACE_CD AS ISSUER_SECTOR

				FROM 
					test.FINANCIAL_INSTRUMENT A

					INNER JOIN 	/*FINANCIAL POSITION */																													
						test.FINANCIAL_POSITION F																															
						  ON 
							F.FINANCIAL_INSTRUMENT_RK = A.FINANCIAL_INSTRUMENT_RK																															
							AND DATEPART(F.VALID_FROM_DTTM) <= &PREV_Q                                                                                                                    
							AND DATEPART(F.VALID_TO_DTTM) > &PREV_Q   

					LEFT JOIN 																															
						test.FINANCIAL_INSTRUMENT_ISSUE B /* ISIN */																															
					      ON 
							A.FINANCIAL_INSTRUMENT_RK = B.FINANCIAL_INSTRUMENT_RK																															
							AND DATEPART(B.VALID_FROM_DTTM) <= &PREV_Q                                                                                                                    
							AND DATEPART(B.VALID_TO_DTTM) > &PREV_Q 																														
							AND B.ISSUE_TYPE_CD = '001'																															
																																				
					LEFT JOIN 																															
						test.FINANCIAL_INSTRUMENT_ISSUE C /* CUSIP */																															
					  	  ON  
							A.FINANCIAL_INSTRUMENT_RK = C.FINANCIAL_INSTRUMENT_RK																															
							AND DATEPART(C.VALID_FROM_DTTM) <= &PREV_Q                                                                                                                    
							AND DATEPART(C.VALID_TO_DTTM) > &PREV_Q 																														
							AND C.ISSUE_TYPE_CD = '003'	

					LEFT JOIN /*join on X_INVESTMENT_PORTFOLIO*/																																
						test.X_INVESTMENT_PORTFOLIO XIP																															
							ON																															
							 	XIP.PORTFOLIO_ID = F.PORTFOLIO_ID 																													
								AND PUT(DATEPART(XIP.VALID_TO_DTTM),DATE9.) = '31DEC9999'

					LEFT JOIN /*get the Investment sub class , SM_SEC_GROUP ,SM_SEC_TYPE*/
						test.X_INVST_CLASS_STC SM_SEC
							ON A.FINANCIAL_INSTRUMENT_TYPE_CD = SM_SEC.SM_SEC_GROUP_CD
							AND A.X_FINANCIAL_INSTR_SUB_TYPE_CD = SM_SEC.SM_SEC_TYPE_CD
							AND PUT(DATEPART(SM_SEC.VALID_TO_DTTM),DATE9.) = '31DEC9999'

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
											AND DATEPART(TICK2.VALID_FROM_DTTM) <= &PREV_Q                                                                                                                    
											AND DATEPART(TICK2.VALID_TO_DTTM) > &PREV_Q 																													
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
					  		ON  
								A.FINANCIAL_INSTRUMENT_RK = CIC.FINANCIAL_INSTRUMENT_RK																															
								AND CIC.ISSUE_TYPE_CD = '002'

			WHERE
				DATEPART(A.VALID_FROM_DTTM) <= &PREV_Q                                                                                                                    
				AND DATEPART(A.VALID_TO_DTTM) > &PREV_Q 	
				AND A.FINANCIAL_INSTRUMENT_ID IN 
					(
						SELECT 
							FINANCIAL_INSTRUMENT_ID

						FROM 
							(
							  	SELECT 
									FINANCIAL_INSTRUMENT_ID 

								FROM 
									test.FINANCIAL_INSTRUMENT A

								WHERE 
									DATEPART(A.VALID_FROM_DTTM)   <= &PREV_Q  
									AND DATEPART(A.VALID_TO_DTTM) > &PREV_Q 	
									AND UPCASE(X_EXPERT_JUDGEMENT_FIN_INV_CLS) NOT IN 
															(
															'BOND COLLATERAL - HELD'
															 , 'CASH COLLATERAL - HELD'
															 , 'COLLATERAL-HELD'
															 , 'FORWARDS'
															 , 'FUTURES'
															 , 'SWAPS'
															 , ''
															)
									AND  UPCASE(X_I_T_INV_CLS_CATEGORY_OVRD) NOT IN ('','EXCLUDE')


							UNION ALL 

								SELECT 
									FINANCIAL_INSTRUMENT_ID 

								FROM 
									test.FINANCIAL_INSTRUMENT A

								WHERE 
									DATEPART(A.VALID_FROM_DTTM)   <= &AS_AT_MTH  
									AND DATEPART(A.VALID_TO_DTTM) > &AS_AT_MTH 	
									AND UPCASE(X_EXPERT_JUDGEMENT_FIN_INV_CLS) NOT IN 
																(
																'BOND COLLATERAL - HELD'
																 , 'CASH COLLATERAL - HELD'
																 , 'COLLATERAL-HELD'
																 , 'FORWARDS'
																 , 'FUTURES'
																 , 'SWAPS'
																 , ''
																)
									AND  UPCASE(X_I_T_INV_CLS_CATEGORY_OVRD) NOT IN ('','EXCLUDE')
								)B

							GROUP BY 	
								FINANCIAL_INSTRUMENT_ID

							HAVING 
								COUNT(FINANCIAL_INSTRUMENT_ID)>1	
						)
				)Prev_q
		        ON 
				Prev_q.CUSIP = C1.ISSUE_CD
				AND XIP.PORTFOLIO_ID = Prev_q.PORTFOLIO_ID


	WHERE
		DATEPART(A1.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
		AND DATEPART(A1.VALID_TO_DTTM) > &AS_AT_MTH 																															
		AND UPCASE(A1.X_PAM_GL_GRP) NOT IN ('FUTURES','INTEREST RATE SWAPS','SWAPS','FORWARDS','FUTURES - BOND')																															
		AND SUBSTR(CIC1.ISSUE_CD,3,1) NOT IN ('9','A','B','C','D','E','F')
		AND UPCASE(A1.X_I_T_INV_CLS_GROUP_OVRD) ^= 'EXCLUDE'
		AND ( NC.INFRA_CORP_FLAG = 'YES' OR A1.INFRA_CORP_BONDS_OVRD = 'YES' OR SUBSTR(CIC1.ISSUE_CD,3,1) = '8' ) 
		AND XIP.PORTFOLIO_ID NOT IN ('A_320VUKRL')

	ORDER BY 
		CIC
		, ISIN
;
QUIT;