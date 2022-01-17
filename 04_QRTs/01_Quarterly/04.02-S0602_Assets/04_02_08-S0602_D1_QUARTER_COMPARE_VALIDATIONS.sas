/* INPUT 1 - Previous Month */
/* INPUT 2 - Current Month  */

/* ----------------------------------PREVIOUS QUARTER------------------------------- */

/* Previous Quarter */

PROC SQL;

	CREATE TABLE WORK.D1_VAL_COMP_PREV_QTR AS 


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
							DATEPART(A.VALID_FROM_DTTM)   <= &CURR_Q  
							AND DATEPART(A.VALID_TO_DTTM) > &CURR_Q 	
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

		ORDER BY 	
			A.FINANCIAL_INSTRUMENT_ID	
;

QUIT;	


/* ----------------------------------CURRENT QUARTER------------------------------- */
								  /* CURRENT Quarter */


PROC SQL;

	CREATE TABLE WORK.D1_VAL_COMP_CURR_QTR AS 


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
					AND DATEPART(F.VALID_FROM_DTTM) <= &CURR_Q                                                                                                                    
					AND DATEPART(F.VALID_TO_DTTM) > &CURR_Q   

			LEFT JOIN 																															
				test.FINANCIAL_INSTRUMENT_ISSUE B /* ISIN */																															
			      ON 
					A.FINANCIAL_INSTRUMENT_RK = B.FINANCIAL_INSTRUMENT_RK																															
					AND DATEPART(B.VALID_FROM_DTTM) <= &CURR_Q                                                                                                                    
					AND DATEPART(B.VALID_TO_DTTM) > &CURR_Q 																														
					AND B.ISSUE_TYPE_CD = '001'																															
																																		
			LEFT JOIN 																															
				test.FINANCIAL_INSTRUMENT_ISSUE C /* CUSIP */																															
			  	  ON  
					A.FINANCIAL_INSTRUMENT_RK = C.FINANCIAL_INSTRUMENT_RK																															
					AND DATEPART(C.VALID_FROM_DTTM) <= &CURR_Q                                                                                                                    
					AND DATEPART(C.VALID_TO_DTTM) > &CURR_Q 																														
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
									AND DATEPART(TICK2.VALID_FROM_DTTM) <= &CURR_Q                                                                                                                    
									AND DATEPART(TICK2.VALID_TO_DTTM) > &CURR_Q 																													
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
		DATEPART(A.VALID_FROM_DTTM) <= &CURR_Q                                                                                                                    
		AND DATEPART(A.VALID_TO_DTTM) > &CURR_Q 	
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
							DATEPART(A.VALID_FROM_DTTM)   <= &CURR_Q  
							AND DATEPART(A.VALID_TO_DTTM) > &CURR_Q 	
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

		ORDER BY 	
			A.FINANCIAL_INSTRUMENT_ID	
;

QUIT;	


PROC SORT DATA=WORK.D1_VAL_COMP_CURR_QTR; BY _all_;
RUN;
PROC SORT DATA=WORK.D1_VAL_COMP_PREV_QTR; BY _all_;
RUN;
PROC COMPARE DATA=WORK.D1_VAL_COMP_CURR_QTR COMPARE=WORK.D1_VAL_COMP_PREV_QTR;
ID FINANCIAL_INSTRUMENT_ID;
RUN;
