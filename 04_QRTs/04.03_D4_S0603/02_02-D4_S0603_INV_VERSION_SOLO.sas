%LET ENTITY_NAME = 'U K Insurance Limited' ; /*'U K Insurance Limited' , 'Churchill Insurance Company Limited' */

PROC SQL;

	CREATE TABLE WORK.D4_S0603_INV_LKTHRU_SOLO AS 

		SELECT 

			 CASE 
				WHEN LK_THRG.PARENT_ISIN IS NOT NULL THEN 'ISIN/'
				ELSE 'NEED TO DERIVE'
			  END||LK_THRG.PARENT_ISIN AS C0010

			, CASE 
				WHEN ((LK_THRG.PCT_OF_FUND*F.X_MARKET_VALUE)/100) < 0 THEN 'L'
				ELSE
					SUBSTR(TRIM(LK_THRG.CIC),3,1)
			  END AS C0030

			, LK_THRG.COUNTRY AS C0040

			, CASE 
				WHEN LK_THRG.CURRENCY = 'GBP' 
					THEN '1' 
				ELSE 
					'2' 
			  END AS C0050	

			, CASE /* BV797* - C0060 > 0 WHEN C0030 = L */
				WHEN CALCULATED C0030 = 'L' 
					THEN 
						ABS ( SUM ( ( ( LK_THRG.PCT_OF_FUND * F.X_MARKET_VALUE ) / 100 ) ) ) 
					ELSE  
						SUM ( ( ( LK_THRG.PCT_OF_FUND * F.X_MARKET_VALUE ) / 100 ) )  
			  END AS C0060 FORMAT=21.2	

			, XIP.ENTITY_NAME
	
			, MONTH(&AS_AT_MTH) AS MTH

			, YEAR(&AS_AT_MTH) AS YR
	
			, SUM (LK_THRG.PAR_FACE_VALUE) AS PAR_FACE_AMT FORMAT=21.2
																										

		FROM 
				Test.X_FUND_LOOK_THROUGH LK_THRG

				INNER JOIN 																						
					test.FINANCIAL_INSTRUMENT A																						
					ON 																						
						A.FINANCIAL_INSTRUMENT_RK = LK_THRG.FINANCIAL_INSTRUMENT_RK																					
						AND DATEPART(A.VALID_FROM_DTTM)	<= &AS_AT_MTH
						AND DATEPART(A.VALID_TO_DTTM)	> &AS_AT_MTH

				INNER JOIN 																						
					test.FINANCIAL_POSITION F																						
					ON 
						F.FINANCIAL_INSTRUMENT_RK = A.FINANCIAL_INSTRUMENT_RK																						
						AND DATEPART(F.VALID_FROM_DTTM)	<= &AS_AT_MTH	
						AND DATEPART(F.VALID_TO_DTTM) >	&AS_AT_MTH	

				INNER JOIN																						
					test.X_INVESTMENT_PORTFOLIO XIP																							
					ON
						XIP.PORTFOLIO_ID = F.PORTFOLIO_ID 																				
						AND PUT(DATEPART(XIP.VALID_TO_DTTM),DATE9.) = '31DEC9999' 	

				LEFT JOIN 																															
					test.FINANCIAL_INSTRUMENT_ISSUE B /* ISIN */																															
					ON  
						A.FINANCIAL_INSTRUMENT_RK = B.FINANCIAL_INSTRUMENT_RK																															
						AND DATEPART(B.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
						AND DATEPART(B.VALID_TO_DTTM) > &AS_AT_MTH 																														
						AND B.ISSUE_TYPE_CD = '001'

				LEFT JOIN 																															
					test.FINANCIAL_INSTRUMENT_ISSUE C /* CUSIP */																															
					 ON  
						A.FINANCIAL_INSTRUMENT_RK = C.FINANCIAL_INSTRUMENT_RK																															
						AND DATEPART(C.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
						AND DATEPART(C.VALID_TO_DTTM) > &AS_AT_MTH 																														
						AND C.ISSUE_TYPE_CD = '003'	

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
							test.X_RING_FENCED_FUNDS RF
						WHERE			
							DATEPART(RF.VALID_FROM_DTTM) <= &AS_AT_MTH 				
							AND DATEPART(RF.VALID_TO_DTTM) > &AS_AT_MTH
							AND RF.AS_AT_MTH = &AS_AT_MTH 	
				    ) RFF				
					ON 	
						RFF.PORTFOLIO_ID = XIP.PORTFOLIO_ID	
						AND  RFF.ISIN = B.ISSUE_CD 
						AND  RFF.CUSIP = C.ISSUE_CD

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
						test.COUNTRY CNTRY /* COUNTRY */
							ON  LK_THRG.COUNTRY  = CNTRY.COUNTRY_CD																					
								AND DATEPART(CNTRY.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
								AND PUT(DATEPART(CNTRY.VALID_TO_DTTM),DATE9.) = '31DEC9999'

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
						CIC_CAT.X_CIC_CD_LAST_2_CHAR = SUBSTR(TRIM(LK_THRG.CIC),3,2)

				LEFT JOIN 
								(
									SELECT 

									C.ISSUE_CD AS CUSIP,
									SUM(FP.X_SOLVENCY_II_VALUE) AS SOL_VAL

									FROM 

									test.FINANCIAL_INSTRUMENT A			

										INNER JOIN 																						
											test.FINANCIAL_POSITION FP																						
											ON 
											FP.FINANCIAL_INSTRUMENT_RK = A.FINANCIAL_INSTRUMENT_RK																						
											AND DATEPART(FP.VALID_FROM_DTTM)	<= &AS_AT_MTH	
											AND DATEPART(FP.VALID_TO_DTTM) >	&AS_AT_MTH		

										LEFT JOIN 																															
											test.FINANCIAL_INSTRUMENT_ISSUE C /* CUSIP */																															
										  	ON  A.FINANCIAL_INSTRUMENT_RK = C.FINANCIAL_INSTRUMENT_RK																															
											AND DATEPART(C.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
											AND DATEPART(C.VALID_TO_DTTM) > &AS_AT_MTH 																														
											AND C.ISSUE_TYPE_CD = '003'	

									WHERE 																					
										DATEPART(A.VALID_FROM_DTTM) <= &AS_AT_MTH 																						
										AND DATEPART(A.VALID_TO_DTTM) > &AS_AT_MTH 		
										AND A.X_EXPERT_JUDGEMENT_FIN_INV_CLS = 'Investment Funds'					
										AND A.X_I_T_INV_CLS_GROUP_OVRD <> 'Exclude'

								GROUP BY 
								C.ISSUE_CD
							) PRNT_CONS	
							  ON LK_THRG.PARENT_CUSIP  = PRNT_CONS.CUSIP


		WHERE
				LK_THRG.AS_AT_DT = &AS_AT_MTH
				AND DATEPART(LK_THRG.VALID_FROM_DTTM) <= &AS_AT_MTH	
				AND DATEPART(LK_THRG.VALID_TO_DTTM)> &AS_AT_MTH
				AND XIP.ENTITY_NAME = &ENTITY_NAME.
				/** XIP.ENTITY_NAME = 'U K Insurance Limited' 
				 XIP.ENTITY_NAME = 'Churchill Insurance Company Limited' **/

		GROUP BY 
			C0010
			, C0030
			, C0040
			, C0050
			, XIP.ENTITY_NAME
			, MTH
			, YR
		
		ORDER BY 
			C0010
			, C0030
	;
QUIT;