/*Take the Output from BASE and PIVOT */

PROC SQL ;

/*Create Temp table to load the extracted Data*/

OPTIONS MISSING='';

CREATE TABLE WORK.S37_LKTHRU_BASE AS 


	SELECT 

		ASOF_DATE , 

		ENTITY_NAME ,

		C0060,

		C0070,			

		C0010,

		C0020,
																				
		C0030,

		C0040 , 

		CASE 	
			WHEN C0150 < 0 THEN 'Liabilities - others'				
			ELSE C0050 
		END AS C0050,							
			   
		C0080,

		C0090,

		C0100,

		C0110,

		C0120,

		C0130,

		C0140,

		C0150,

		C0160,

		C0170


		FROM 
		

		(	SELECT  
				
				PUT(&AS_AT_MTH,DDMMYY10.) AS ASOF_DATE

				, 'Direct Line Insurance Group plc' AS ENTITY_NAME

				, CASE 
					WHEN LOOKTHROUGH_ID_TYPE =  '1' THEN LOOKTHROUGH_ISIN
					WHEN LOOKTHROUGH_ID_TYPE =  '2' THEN LOOKTHROUGH_CUSIP
					ELSE LOOKTHROUGH_ALTERNATIVE_ID 
				  END AS C0060

				, CASE 
					WHEN LOOKTHROUGH_ID_TYPE =  '1' THEN 'ISIN'
					WHEN LOOKTHROUGH_ID_TYPE =  '2' THEN 'CUSIP'
					WHEN LOOKTHROUGH_ID_TYPE = '99' THEN 'Undertaking'
					ELSE  'Need to Derive' 
				  END  AS C0070

				, UPCASE(ULTMT_COUNTERPARTY_NM)	AS C0010

				, ULTMT_COUNTERPARTY_LEI_CD	AS C0020

				, CASE 
					WHEN ULTMT_COUNTERPARTY_LEI_STATUS = '1' THEN 'LEI'
					WHEN ULTMT_COUNTERPARTY_LEI_STATUS = '2' THEN 'SC'
					ELSE 'None' 
				  END AS C0030

				, LK_THRG.COUNTRY 	AS C0040

				,  CASE 	
					WHEN SUBSTR(LK_THRG.CIC,3,1) IN ('1','2') THEN  'Assets - bonds' 
    				ELSE 'Assets - others' 
				   END AS C0050

				, LK_THRG.SOLII_CREDIT_RTG AS C0080

				, LK_THRG.SOLII_CREDIT_RTG_AGENCY AS C0090

				, CASE 
					WHEN SCRTY_IND_SCTR = 'Treasuries' THEN 'O8411'
   					WHEN SCRTY_IND_SCTR IN  ('Financial Institutions','Supranational','Other','Local Authority','Agency') THEN 'K6419'
   					WHEN SCRTY_IND_SCTR IN ('Industrial') THEN 'K6499'  				   				
   			 		ELSE SCRTY_IND_SCTR 
				  END AS C0100 

				, XIP.ENTITY_NAME AS C0110

				, XIP.ENTITY_LEI_CD AS C0120

				, CASE 
					WHEN XIP.ENTITY_LEI_STATUS = '1' THEN 'LEI'
					WHEN XIP.ENTITY_LEI_STATUS = '2' THEN 'SC'
					ELSE 'None'
				  END AS C0130

				, PUT ( LK_THRG.MATURITY_DT , DDMMYY10.) AS C0140

				, SUM ( ( ( LK_THRG.PCT_OF_FUND*F.X_SOLVENCY_II_VALUE )/100) ) AS C0150

				, LK_THRG.CURRENCY AS C0160

				,  0.00 AS C0170
			
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

			INNER JOIN 																															
				test.FINANCIAL_INSTRUMENT_ISSUE C /* CUSIP */																															
				ON  A.FINANCIAL_INSTRUMENT_RK = C.FINANCIAL_INSTRUMENT_RK																															
				AND DATEPART(C.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
				AND DATEPART(C.VALID_TO_DTTM) > &AS_AT_MTH 																														
				AND C.ISSUE_TYPE_CD = '003'	

			LEFT JOIN 	
				test.COUNTRY CNTRY
					ON  ( LK_THRG.COUNTRY = CNTRY.COUNTRY_CD
					AND PUT(DATEPART(CNTRY.VALID_TO_DTTM),DATE9.) = '31DEC9999')  

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

			GROUP BY 

			 	ASOF_DATE			
			  
			  	, XIP.ENTITY_NAME
							 
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
			    
			    , C0120 
			  
			    , C0130
			    
			    , C0140
			    
			    , C0160
			    
			    , C0170																																									   		
			      																					  
			    HAVING 		
			    SUM ( ((LK_THRG.PCT_OF_FUND*F.X_SOLVENCY_II_VALUE)/100) ) <> 0  	

		) S37_LKTHRU

		ORDER BY 
			C0060
	;

QUIT;



PROC SUMMARY DATA=WORK.S37_LKTHRU_BASE;
VAR C0150 ;
CLASS C0010 ;
OUTPUT OUT=WORK.S37_LKTHRU_BASE_CPRTY_SUM SUM=;
RUN;

PROC SORT DATA=WORK.S37_LKTHRU_BASE_CPRTY_SUM(WHERE=(_TYPE_ = 1)) ;  
BY DESCENDING C0150 ;
RUN;

DATA S37_LKTHRU_BASE_CPRTY_PIVOT ;
KEEP C0010 C0150 ; 
SET WORK.S37_LKTHRU_BASE_CPRTY_SUM;
RUN;