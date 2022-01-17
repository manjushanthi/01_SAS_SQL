/*Take the Output from BASE and PIVOT */

PROC SQL ;

/*Create Temp table to load the extracted Data*/

OPTIONS MISSING='';

CREATE TABLE WORK.S37_D1_BASE AS 

	SELECT 

		PUT(&AS_AT_MTH,DDMMYY10.) AS ASOF_DATE

		, 'Direct Line Insurance Group plc' AS ENTITY_NAME

		, CASE 
   			WHEN A.X_RPT_ID_TYPE_OVRD <> '1' 
				THEN C.ISSUE_CD
   			ELSE B.ISSUE_CD 
		  END AS C0060

		, CASE 
			WHEN  X_RPT_ID_TYPE_OVRD =  '1'  THEN  'ISIN'
			WHEN  X_RPT_ID_TYPE_OVRD =  '2'  THEN  'CUSIP'
			WHEN  X_RPT_ID_TYPE_OVRD =  '99' THEN  'Undertaking'
			ELSE  'Need to Derive' 
		  END  AS C0070
	
		, UPCASE(X_ISSUER_GRP_NM) AS C0010

		, X_ISSUER_GRP_LEI_CD	AS C0020

		, CASE 
			WHEN X_ISSUER_GRP_LEI_STATUS = '1' THEN 'LEI'
			WHEN X_ISSUER_GRP_LEI_STATUS = '2' THEN 'SC'
			ELSE 'None' 
		  END AS C0030

		, A.X_COUNTRY_OF_ISSUE_CD AS C0040

		, CASE 
			WHEN F.X_SOLVENCY_II_VALUE < 0 THEN 'Liabilities - others' 
			WHEN SUBSTR(CIC.ISSUE_CD,3,1) IN ('1','2')  THEN   'Assets - bonds' 
			ELSE 'Assets - others' 
		  END AS C0050

		, CASE 
			WHEN F.PORTFOLIO_ID IN ('A_320QUKIM','A_320UKJPM') THEN '' 
			ELSE COALESCE(INSTR_999_Rating.ASSESSMENT_GRADE,INSTR_555_Rating.ASSESSMENT_GRADE) 
		  END AS C0080

		, CASE 
			WHEN F.PORTFOLIO_ID IN ('A_320QUKIM','A_320UKJPM') THEN '' 
			ELSE COALESCE(INSTR_999_Rating.ASSESSMENT_AGENCY_CD,INSTR_555_Rating.ASSESSMENT_AGENCY_CD) 
		  END AS C0090

		, A.X_NACE_CD AS C0100
				
		, XIP.ENTITY_NAME AS C0110
				
		, XIP.ENTITY_LEI_CD AS C0120

		, CASE 
			WHEN XIP.ENTITY_LEI_STATUS = '1' THEN 'LEI'
			WHEN XIP.ENTITY_LEI_STATUS = '2' THEN 'SC'
			ELSE 'None' 
  		  END AS C0130 

		, PUT(A.MATURITY_DT,DDMMYY10.) AS C0140

		/*AGGREGATE COLUMNS*/
		, SUM(F.X_SOLVENCY_II_VALUE) AS C0150	

		, F.CURRENCY_CD   AS C0160

		, 0.00 AS C0170

		, SUBSTR(CIC.ISSUE_CD,3,1) AS ISSUE_CDFI

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

			LEFT JOIN /*join on X_INVESTMENT_PORTFOLIO*/																																
			test.X_INVESTMENT_PORTFOLIO XIP																															
				ON  XIP.PORTFOLIO_ID = F.PORTFOLIO_ID 																													
					AND DATEPART(XIP.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
								AND DATEPART(XIP.VALID_TO_DTTM) > &AS_AT_MTH 

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

	WHERE 
		DATEPART(A.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
		AND DATEPART(A.VALID_TO_DTTM) > &AS_AT_MTH 
		AND SUBSTR(TRIM(CIC.ISSUE_CD),3,1)	NOT IN ('A','B','C','D','E','F','4')
		AND A.X_I_T_INV_CLS_CATEGORY_OVRD <> 'Exclude'
		AND (A.X_COLLATERAL_STATUS = '' AND A.X_COLLATERAL_STATUS IS NULL)
 		AND A.FINANCIAL_INSTRUMENT_ID NOT LIKE '%INTERCO%'
 		AND A.X_PARTICIPATION_CD <> '6'	 

	GROUP BY 				
		ASOF_DATE
		, ENTITY_NAME
		, C0060
		, C0070
		, C0010
		, C0020
		, C0030
		, C0040
		, C0050
		, C0080
		, C0090
		, C0100
		, C0110
		, C0120
		, C0130
		, C0140
		, C0160
		, C0170
		, ISSUE_CDFI

				
	ORDER BY 
		ISSUE_CDFI 
		, C0060 
	;
QUIT;


PROC SUMMARY DATA=WORK.S37_D1_BASE;
VAR C0150 ;
CLASS C0010 ;
OUTPUT OUT=WORK.S37_D1_BASE_CPRTY_SUM SUM=;
RUN;


PROC SORT DATA=WORK.S37_D1_BASE_CPRTY_SUM(WHERE=(_TYPE_ = 1)) ;  
BY DESCENDING C0150 ;
RUN;

DATA S37_D1_BASE_CPRTY_PIVOT ;
KEEP C0010 C0150 ; 
SET WORK.S37_D1_BASE_CPRTY_SUM;
RUN;