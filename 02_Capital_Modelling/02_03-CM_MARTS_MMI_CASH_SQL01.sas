/*      
		CM MMI extracts the data from the Blackrock related tables / No lookthrough data used in MMI 
		SOLII Amount is sliced according to Cash_Deposit , Operational_Cash and MMI's
		Cash Deposit - CM Team Rogier claims no Cash Deposits 
		Operational cash - CIC 

		The report is generated at a SNP equivalent rating FACT
		FACTS - PORTFOLIO NAME ,  ISSUER NAME  KEY FACT - SNP EQUIVALENT RATING
		MEASURE - X_MARKET_VALUE 
*/

	
	
/* 
		CM MMI Extracts 
		Earlier generated for PUNIL , now sent to Cliff and Team 

		Old Code unwanted joins - Streamlining the process for On Cloud SAS EG execution
		removed the WTFL calculation logic as this is implemented within the System
*/

PROC SQL ;

CREATE TABLE WORK.MMI_FINAL_01 AS 


	SELECT 

		/*Key Facts for Aggregation*/
		PORTF_NAME
		,ISSUER_NAME
		,SNP_DERIV.ASSESSMENT_GRADE AS SNP_EQUI_RATING
	
		/*Measures*/
		/*Cash Deposits - No Rules provided default to 0*/
		, 0.00 AS CASH_DEPOSIT

		/*Assign 0 to non CASH*/
		, SUM(CASE WHEN FLG_CASH = 1 THEN X_SOLVENCY_II_VALUE ELSE 0 END) AS MKT_VALUE_CASH_OPR

		/*Assign 0 to non MMI's*/
		, SUM(CASE WHEN FLG_MMI = 1 THEN X_SOLVENCY_II_VALUE ELSE 0 END) AS MKT_VALUE_MMI_INST
		

	FROM 
			/*Sub Query Starts*/
			(
				SELECT 
					
					/*Facts required for aggregation*/
					XIP.ENTITY_NAME AS PORTF_NAME
					,A.X_ISSUER_NM AS ISSUER_NAME
					,C.ISSUE_CD AS CUSIP 
					,CIC.ISSUE_CD AS CIC

					/*Key Logic to Decide the CASH's*/
					,CASE WHEN SUBSTR(CIC.ISSUE_CD,3,1)  IN ('7') AND UPCASE(X_I_T_INV_CLS_GROUP_OVRD) <> 'EXCLUDE'
						  THEN 1 
						  ELSE 0 
					 END AS FLG_CASH

					 /*Key Logic to Decide the MMI's*/
					 ,CASE WHEN 
								(
								UPCASE(X_I_T_INV_CLS_GROUP_OVRD) IN ('COMMERCIAL PAPER','DEPOSIT','MMF') 
								AND UPCASE(X_I_T_INV_CLS_CATEGORY_OVRD) IN ('LOANS AND RECEIVABLES','TERM DEPOSIT','MMF') 
								AND SUBSTR(CIC.ISSUE_CD,3,1)  IN ('2') 
								)
							THEN 1
							ELSE 0 
					  END AS FLG_MMI

					 /* get the Business rating if it's populated else use the system calculated rating and rating scores */

					, CASE WHEN BUSS_RATING.ASSESSMENT_GRADE IS NULL THEN CALC_RATING.ASSESSMENT_GRADE  ELSE BUSS_RATING.ASSESSMENT_GRADE END AS WTRFL_RATING_GRADE
					, CASE WHEN BUSS_RATING.ASSESSMENT_SCORE_NO IS NULL THEN CALC_RATING.ASSESSMENT_SCORE_NO ELSE BUSS_RATING.ASSESSMENT_SCORE_NO  END AS WTRFL_RATING_SCORE

					/*Key Measure from the Financial Position Table*/
					,F.X_SOLVENCY_II_VALUE	

				FROM
					/*KEY FINANCIAL_INSTRUMENT TABLE*/
					/*No Lookthrough and Property required for MMI*/
					test.FINANCIAL_INSTRUMENT A
																							      
					INNER JOIN /*MKT VALUE FROM FINANCIAL_POSITION TABLE*/
						test.FINANCIAL_POSITION F
					ON 
						F.FINANCIAL_INSTRUMENT_RK = A.FINANCIAL_INSTRUMENT_RK
						AND A.SOURCE_SYSTEM_CD = F.SOURCE_SYSTEM_CD
						AND DATEPART(F.VALID_FROM_DTTM)	<= &AS_AT_MTH
						AND DATEPART(F.VALID_TO_DTTM)	> &AS_AT_MTH

					INNER JOIN 
						test.FINANCIAL_INSTRUMENT_ISSUE C /* EXTRACT CUSIP ID TO DEBUG ISSUES */
					ON  
						A.FINANCIAL_INSTRUMENT_RK = C.FINANCIAL_INSTRUMENT_RK
						AND DATEPART(C.VALID_FROM_DTTM)	<= &AS_AT_MTH
						AND DATEPART(C.VALID_TO_DTTM)	> &AS_AT_MTH
						AND C.ISSUE_TYPE_CD = '003'

					LEFT JOIN    
						test.X_INVESTMENT_PORTFOLIO XIP /* PORTFOLIO DETAILS */ 
					ON    
						(
						XIP.PORTFOLIO_ID = F.PORTFOLIO_ID   
					    AND PUT(DATEPART(XIP.VALID_TO_DTTM),DATE9.) = '31DEC9999'
						)  

					LEFT JOIN  /* extract CIC codes from Financial_Instrument_Issue*/
						(
								SELECT         
								   A2.FINANCIAL_INSTRUMENT_RK      
								   , A2.VALID_FROM_DTTM       
								   , A2.VALID_TO_DTTM       
								   , A2.ISSUE_CD       
								   , A2.ISSUE_TYPE_CD   
								   , A2.X_SOURCE_BATCH_IDENT       

								FROM         
									(         
										SELECT         
											TICK2.FINANCIAL_INSTRUMENT_RK      
										    , MAX(TICK2.VALID_FROM_DTTM) AS VALID_FROM_DTTM       
											, TICK2.ISSUE_TYPE_CD       

										FROM        
											test.FINANCIAL_INSTRUMENT TICK1      
											,test.FINANCIAL_INSTRUMENT_ISSUE TICK2        

										WHERE         
											TICK1.FINANCIAL_INSTRUMENT_RK = TICK2.FINANCIAL_INSTRUMENT_RK 
											AND DATEPART(TICK2.VALID_FROM_DTTM)	<= &AS_AT_MTH  
											AND DATEPART(TICK2.VALID_TO_DTTM)	> &AS_AT_MTH   
											AND TICK2.ISSUE_TYPE_CD = '002'   

										GROUP BY    

											TICK2.FINANCIAL_INSTRUMENT_RK 
											, TICK2.ISSUE_TYPE_CD  

									) A1      
									,  test.FINANCIAL_INSTRUMENT_ISSUE A2  
				 
							    WHERE     
									A1.FINANCIAL_INSTRUMENT_RK = A2.FINANCIAL_INSTRUMENT_RK
									AND A1.VALID_FROM_DTTM = A2.VALID_FROM_DTTM   
									AND A1.ISSUE_TYPE_CD = A2.ISSUE_TYPE_CD    
						) CIC     
						ON  
							A.FINANCIAL_INSTRUMENT_RK = CIC.FINANCIAL_INSTRUMENT_RK     
							AND CIC.ISSUE_TYPE_CD = '002' 

					LEFT JOIN /* Extract Calculated Rating from FINANCIAL_INST_CREDIT_ASSESS - No Derivatives hence no need rating from Cparty*/
					(
						SELECT

							DISTINCT
								B1.FINANCIAL_INSTRUMENT_RK
								,B2.ASSESSMENT_AGENCY_CD

								,CASE 	WHEN B2.ASSESSMENT_GRADE IN ('Agency','Govt')  
										THEN 'Aaa' 
										ELSE B2.ASSESSMENT_GRADE  
								END AS ASSESSMENT_GRADE

								,B2.ASSESSMENT_SCORE_NO
								,B2.X_SOLII_CREDIT_QUALITY_VAL

						FROM
							(
								SELECT

									CCA1.FINANCIAL_INSTRUMENT_RK
									,CCA1.ASSESSMENT_RATING_GRADE_RK 
									,ASSESSMENT_MODEL_RK

								FROM

									test.FINANCIAL_INST_CREDIT_ASSESS AS CCA1

									, (				
											SELECT 			
												FINANCIAL_INSTRUMENT_RK	
												,MAX(ASSESSMENT_DT) AS ASSESSMENT_DT	

											FROM			
												test.FINANCIAL_INST_CREDIT_ASSESS

											WHERE 				
												DATEPART(ASSESSMENT_DT)	<= &AS_AT_MTH	

											GROUP BY			
												FINANCIAL_INSTRUMENT_RK    
								
										) AS CCA2	
								
								WHERE	
									
									CCA1.FINANCIAL_INSTRUMENT_RK =  CCA2.FINANCIAL_INSTRUMENT_RK				
									AND CCA1.ASSESSMENT_DT =  CCA2.ASSESSMENT_DT				
									AND PUT(DATEPART(CCA1.EFFECTIVE_TO_DTTM),DATE9.) = '31DEC4747' 	
							)  B1 

							,  test.ASSESSMENT_RATING_GRADE B2

						WHERE
						B1.ASSESSMENT_RATING_GRADE_RK = B2.ASSESSMENT_RATING_GRADE_RK
						AND PUT(DATEPART(B2.VALID_TO_DTTM),DATE9.) = '31DEC4747' 	
						AND B1.ASSESSMENT_MODEL_RK IN (999)
						/* 999 - System calculated Rating */
						/* 555 - Business Assigned Rating */


					) CALC_RATING

					ON 
						A.FINANCIAL_INSTRUMENT_RK = CALC_RATING.FINANCIAL_INSTRUMENT_RK

					LEFT JOIN /* Extract Business Assigned Rating FROM FINANCIAL_INST_CREDIT_ASSESS - No Derivatives hence no need rating from Cparty*/
					(
						SELECT

							DISTINCT
								B1.FINANCIAL_INSTRUMENT_RK
								,B2.ASSESSMENT_AGENCY_CD

								,CASE 	WHEN B2.ASSESSMENT_GRADE IN ('Agency','Govt')  
										THEN 'Aaa' 
										ELSE B2.ASSESSMENT_GRADE  
								END AS ASSESSMENT_GRADE

								,B2.ASSESSMENT_SCORE_NO
								,B2.X_SOLII_CREDIT_QUALITY_VAL

						FROM
							(
								SELECT

									CCA1.FINANCIAL_INSTRUMENT_RK
									,CCA1.ASSESSMENT_RATING_GRADE_RK 
									,ASSESSMENT_MODEL_RK

								FROM

									test.FINANCIAL_INST_CREDIT_ASSESS AS CCA1

									, (				
											SELECT 			
												FINANCIAL_INSTRUMENT_RK	
												,MAX(ASSESSMENT_DT) AS ASSESSMENT_DT	

											FROM			
												test.FINANCIAL_INST_CREDIT_ASSESS

											WHERE 				
												DATEPART(ASSESSMENT_DT)	<= &AS_AT_MTH	

											GROUP BY			
												FINANCIAL_INSTRUMENT_RK    
								
										) AS CCA2	
								
								WHERE	
									
									CCA1.FINANCIAL_INSTRUMENT_RK =  CCA2.FINANCIAL_INSTRUMENT_RK				
									AND CCA1.ASSESSMENT_DT =  CCA2.ASSESSMENT_DT				
									AND PUT(DATEPART(CCA1.EFFECTIVE_TO_DTTM),DATE9.) = '31DEC4747' 	
							)  B1 

							,  test.ASSESSMENT_RATING_GRADE B2

						WHERE
						B1.ASSESSMENT_RATING_GRADE_RK = B2.ASSESSMENT_RATING_GRADE_RK
						AND PUT(DATEPART(B2.VALID_TO_DTTM),DATE9.) = '31DEC4747' 	
						AND B1.ASSESSMENT_MODEL_RK IN (555)
						/* 999 - System calculated Rating */
						/* 555 - Business Assigned Rating */


					) BUSS_RATING

					ON 
						A.FINANCIAL_INSTRUMENT_RK = BUSS_RATING.FINANCIAL_INSTRUMENT_RK


				WHERE
					/*Get High end dates from Financial Instruments*/
					DATEPART(A.VALID_FROM_DTTM)	<= &AS_AT_MTH  
				    AND DATEPART(A.VALID_TO_DTTM)	> &AS_AT_MTH  

					/*Scope only for 3rd digit of CIC in 2's and 7's*/
					AND SUBSTR(CIC.ISSUE_CD,3,1) IN ('2','7')

					/*Asset Category set as EXCLUDE and Collateral Held are ignored*/
					AND UPCASE(X_I_T_INV_CLS_GROUP_OVRD) NOT IN ('EXCLUDE','COLLATERAL-HELD','CH','COLLATERAL - HELD')

			) TEMP
			/*Sub Query Ends*/

	/*Get the SNP Equivalent Rating as this is the rating considered for Downstreams*/
	LEFT JOIN 
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
			TEMP.WTRFL_RATING_SCORE = SNP_DERIV.ASSESSMENT_SCORE_NO

	/*Require only CASH and MMI for this report , Exclude others*/
	WHERE 
		(FLG_CASH = 1 OR FLG_MMI = 0)

	/*Group by at the following levels*/
	GROUP BY 
		PORTF_NAME
		,ISSUER_NAME
		,SNP_EQUI_RATING

	HAVING 
	/*Filter all other Zero metrics*/
		SUM(CASE WHEN FLG_CASH = 1 THEN X_SOLVENCY_II_VALUE ELSE 0 END) <> 0.00
		OR SUM(CASE WHEN FLG_MMI = 1 THEN X_SOLVENCY_II_VALUE ELSE 0 END) <> 0.00

	ORDER BY 
	/*Order at the following levels*/
		PORTF_NAME
		,ISSUER_NAME
		,SNP_EQUI_RATING


;

QUIT;


/*Summarise before SORT AND FORMATTING THE REPORT */
PROC SUMMARY DATA=WORK.MMI_FINAL_01;
VAR CASH_DEPOSIT MKT_VALUE_CASH_OPR MKT_VALUE_MMI_INST ;
CLASS  SNP_EQUI_RATING ISSUER_NAME;
OUTPUT OUT=WORK.MMI_FINAL_SUM_02 SUM=;
RUN;

/*SORT BEFORE THE FORMATING THE END REPORT*/

/* 	
	_type_ 3 - GET BOTH COLUMNS POPULATED - SNP_EQUI_RATING & ISSUER_NAME
	_type_0 - GET OVERALL TOTALS
	_type_2 - GET SNP_EQUI_RATING
*/

PROC SORT DATA=WORK.MMI_FINAL_SUM_02(WHERE=(_TYPE_=3 OR _TYPE_=0 OR _TYPE_=2)) ; 
BY SNP_EQUI_RATING ISSUER_NAME;
RUN;


/*FORMAT AS PER REPORTS*/
PROC SQL ;

CREATE TABLE WORK.MMI_FINAL_TRNS_03 AS 

SELECT 
	CASE WHEN SNP_EQUI_RATING IS NULL THEN 'TOTALS' ELSE SNP_EQUI_RATING END AS SNP_EQUI_RATING
	,CASE WHEN ISSUER_NAME IS NULL THEN TRIM(SNP_EQUI_RATING)||'  ||TOTALS' ELSE ISSUER_NAME END  AS ISSUER_NAME

	,CASH_DEPOSIT	
	FORMAT = 18.2
	INFORMAT = 18.5

	,MKT_VALUE_CASH_OPR	
	FORMAT = 18.2
	INFORMAT = 18.5

	,MKT_VALUE_MMI_INST
	FORMAT = 18.2
	INFORMAT = 18.5

FROM 
	WORK.MMI_FINAL_SUM_02

ORDER BY 
	SNP_EQUI_RATING 
	,ISSUER_NAME;

QUIT;
