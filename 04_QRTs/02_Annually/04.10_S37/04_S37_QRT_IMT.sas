/* Set the Threshold in count of Millions , Threshold = 50,000,000.00 (50Million) then set threshold = 50 */

%let Thrshold = 50;


/*Take the Output from S37_QRT and PIVOT */
PROC SQL ;

/*Create Temp table to load the extracted Data*/

OPTIONS MISSING='';

CREATE TABLE WORK.S37_QRT AS 


SELECT 

	C0020
	,C0030
	,C0120	
	,C0130	
	,C0060	
	,C0070	
	,C0010	
	,C0040	
	,C0050
	,DRV_SCR_MIN_NO.ASSESSMENT_GRADE
		
	,CASE 
		WHEN C0090 = 'S_P' THEN 'Standard & Poor'||'’'||'s Credit Market Services Europe Limited (LEI code: 549300363WVTTH0TW460)'
		WHEN C0090 = 'MDY' THEN 'Moody'||'’'||'s Investors Service Ltd (LEI code: 549300SM89WABHDNJ349)' 
		WHEN C0090 = 'FIT' THEN  'Fitch Ratings Limited (LEI code: 2138009F8YAHVC8W3Q52)'
		ELSE ''	END AS C0090 

	,C0091
	,C0100	
	,C0110	
	,PUT(C0140,DDMMYY10.) AS C0140
	,C0150	
	,C0160	
	,C0170

FROM
	
	(
		SELECT 
						
						A.ULT_ISSUER_LEI AS C0020
						
						, CASE 
							WHEN  A.ULT_ISSUER_LEI_TYPE = '1' THEN '1 - LEI'
							WHEN  A.ULT_ISSUER_LEI_TYPE = '2' THEN '2 - SC'
							WHEN  A.ULT_ISSUER_LEI_TYPE = '9' THEN '9 - None'  
							ELSE 'UNKNOWN' 
						  END  AS C0030
									
						, A.ENTITY_GRP_LEI_CD AS C0120
						
						, CASE 
							WHEN  A.ENTITY_GRP_LEI_TYPE = '1' THEN '1 - LEI'
							WHEN  A.ENTITY_GRP_LEI_TYPE = '2' THEN '2 - SC'
							WHEN  A.ENTITY_GRP_LEI_TYPE = '9' THEN '9 - None'  
							ELSE 'UNKNOWN' 
						  END  AS C0130
						
						, A.ID_CODE AS C0060
						
						, CASE 
							WHEN  A.ID_CODE_TYPE = '1'  THEN '1 - ISO/6166 for ISIN' 
							WHEN  A.ID_CODE_TYPE = '2'  THEN '2 - CUSIP '
							WHEN  A.ID_CODE_TYPE = '99' THEN '99 - Code attributed by the undertaking'
							ELSE 'UNKNOWN' 
						  END  AS C0070
						
						, A.ULT_ISSUER_NAME AS C0010
						
						, CASE 
							WHEN A.ULT_ISSUER_NAME = 'EUROPEAN INVESTMENT BANK' AND A.COUNTRY_OF_EXPOSURE = 'SP' THEN 'LU'
							ELSE A.COUNTRY_OF_EXPOSURE 
						  END AS C0040
						
						, CASE 
							WHEN  A.EXPOSURE_TYPE = '1' THEN '1 - Assets - bonds' 
							WHEN  A.EXPOSURE_TYPE = '4' THEN '4 - Assets - others'
							WHEN  A.EXPOSURE_TYPE = '8' THEN '8 - Liabilities - others'
							ELSE 'UNKNOWN' 
						  END  AS C0050
						
						, A.SOLII_CREDIT_RATING_AGENCY  AS C0090
									 
						, A.INTERNAL_RATING AS C0091
						
						, MIN(DRV_SCR_NO.ASSESSMENT_SCORE_NO) AS C0080_SCORE
						
						, A.ISSUER_SECTOR AS C0100
						
						, A.ENTITY_GRP_NAME AS C0110
						
						, A.MATURITY_DT AS C0140
						
						, SUM(A.MKT_VALUE) AS C0150 
						
						, A.CURRENCY_CD AS C0160
						
						, SUM(A.REINSURER_AMT) AS C0170

	FROM 
		test.X_S3701_CONCENTRATION_RISK  A 

		LEFT JOIN 

		(SELECT 
				DISTINCT 
					ARG.ASSESSMENT_AGENCY_CD,
					ARG.ASSESSMENT_GRADE,
					ARG.ASSESSMENT_SCORE_NO

			FROM 
				test.ASSESSMENT_RATING_GRADE ARG

			WHERE 
				PUT(DATEPART(ARG.VALID_TO_DTTM),DATE9.) = '31DEC4747'
				AND ARG.ASSESSMENT_GRADE NOT IN ('Govt','Govt Equiv','Agency')
				AND ARG.MODEL_RK = 555

		)DRV_SCR_NO

			ON 
			DRV_SCR_NO.ASSESSMENT_GRADE = A.SOLII_CREDIT_RATING
			AND DRV_SCR_NO.ASSESSMENT_AGENCY_CD = A.SOLII_CREDIT_RATING_AGENCY			

			WHERE 
				A.ASOF_DATE = &AS_AT_MTH
				AND A.ULT_ISSUER_NAME IN 

									(
										
										SELECT ULT_ISSUER_NAME FROM 
											
											(
											
											SELECT INR_A.ULT_ISSUER_NAME,SUM(INR_A.MKT_VALUE) AS AGG_MKT_VAL
											FROM test.X_S3701_CONCENTRATION_RISK INR_A
											
											WHERE 
											INR_A.ASOF_DATE = &AS_AT_MTH												
																     			
											GROUP BY INR_A.ULT_ISSUER_NAME
											HAVING SUM(INR_A.MKT_VALUE) > &Thrshold*1000000
											
											)FIND_THSLD
									
									)

			GROUP BY 
				C0020 , 
				C0030 , 
				C0120 , 
				C0130 , 
				C0060 ,
				C0070 ,
				C0010 ,
				C0040 ,
				C0050 , 
				C0090 , 
				C0091 ,
				C0100 ,
				C0110 ,
				C0140 ,
				C0160
  )FINAL_CALC

	LEFT JOIN
	(
		SELECT 
			DISTINCT 
				ARG_OUTER.ASSESSMENT_AGENCY_CD,
				ARG_OUTER.ASSESSMENT_GRADE,
				ARG_OUTER.ASSESSMENT_SCORE_NO 
	
		FROM 
			test.ASSESSMENT_RATING_GRADE ARG_OUTER

		WHERE 
			PUT(DATEPART(ARG_OUTER.VALID_TO_DTTM),DATE9.) = '31DEC4747'
			AND ARG_OUTER.MODEL_RK = 555
			AND ASSESSMENT_GRADE NOT IN ('Govt','Govt Equiv','Agency')
			AND ARG_OUTER.SHORTTERM_FLG = '0'
			/*  remove non standard rating*/
			AND ARG_OUTER.ASSESSMENT_GRADE NOT LIKE '%(P)%'
			AND ARG_OUTER.ASSESSMENT_GRADE NOT LIKE '%-mf%'
			AND ARG_OUTER.ASSESSMENT_GRADE NOT LIKE '%#%'
			AND ARG_OUTER.ASSESSMENT_GRADE NOT LIKE '%pre%'
			/* -------------------------- */
	)DRV_SCR_MIN_NO
								ON 
								DRV_SCR_MIN_NO.ASSESSMENT_SCORE_NO = FINAL_CALC.C0080_SCORE
								AND DRV_SCR_MIN_NO.ASSESSMENT_AGENCY_CD = FINAL_CALC.C0090			



UNION 


SELECT 

	C0020
	,C0030
	,C0120	
	,C0130	
	,C0060	
	,C0070	
	,C0010	
	,C0040	
	,C0050
	,DRV_SCR_MIN_NO.ASSESSMENT_GRADE
		
	,CASE 
		WHEN C0090 = 'S_P' THEN 'Standard & Poor'||'’'||'s Credit Market Services Europe Limited (LEI code: 549300363WVTTH0TW460)'
		WHEN C0090 = 'MDY' THEN 'Moody'||'’'||'s Investors Service Ltd (LEI code: 549300SM89WABHDNJ349)' 
		WHEN C0090 = 'FIT' THEN  'Fitch Ratings Limited (LEI code: 2138009F8YAHVC8W3Q52)'
		ELSE ''	END AS C0090 

	,C0091
	,C0100	
	,C0110	
	,PUT(C0140,DDMMYY10.) AS C0140
	,C0150	
	,C0160	
	,C0170

FROM
	
	(
		SELECT 
						
						A.ULT_ISSUER_LEI AS C0020
						
						, CASE 
							WHEN  A.ULT_ISSUER_LEI_TYPE = '1' THEN '1 - LEI'
							WHEN  A.ULT_ISSUER_LEI_TYPE = '2' THEN '2 - SC'
							WHEN  A.ULT_ISSUER_LEI_TYPE = '9' THEN '9 - None'  
							ELSE 'UNKNOWN' 
						  END  AS C0030
									
						, A.ENTITY_GRP_LEI_CD AS C0120
						
						, CASE 
							WHEN  A.ENTITY_GRP_LEI_TYPE = '1' THEN '1 - LEI'
							WHEN  A.ENTITY_GRP_LEI_TYPE = '2' THEN '2 - SC'
							WHEN  A.ENTITY_GRP_LEI_TYPE = '9' THEN '9 - None'  
							ELSE 'UNKNOWN' 
						  END  AS C0130
						
						, A.ID_CODE AS C0060
						
						, CASE 
							WHEN  A.ID_CODE_TYPE = '1'  THEN '1 - ISO/6166 for ISIN' 
							WHEN  A.ID_CODE_TYPE = '2'  THEN '2 - CUSIP '
							WHEN  A.ID_CODE_TYPE = '99' THEN '99 - Code attributed by the undertaking'
							ELSE 'UNKNOWN' 
						  END  AS C0070
						
						, A.ULT_ISSUER_NAME AS C0010
						
						, CASE 
							WHEN A.ULT_ISSUER_NAME = 'EUROPEAN INVESTMENT BANK' AND A.COUNTRY_OF_EXPOSURE = 'SP' THEN 'LU'
							ELSE A.COUNTRY_OF_EXPOSURE 
						  END AS C0040
						
						, CASE 
							WHEN  A.EXPOSURE_TYPE = '1' THEN '1 - Assets - bonds' 
							WHEN  A.EXPOSURE_TYPE = '4' THEN '4 - Assets - others'
							WHEN  A.EXPOSURE_TYPE = '8' THEN '8 - Liabilities - others'
							ELSE 'UNKNOWN' 
						  END  AS C0050
						
						, A.SOLII_CREDIT_RATING_AGENCY  AS C0090
									 
						, A.INTERNAL_RATING AS C0091
						
						, MIN(DRV_SCR_NO.ASSESSMENT_SCORE_NO) AS C0080_SCORE
						
						, A.ISSUER_SECTOR AS C0100
						
						, A.ENTITY_GRP_NAME AS C0110
						
						, A.MATURITY_DT AS C0140
						
						, SUM(A.MKT_VALUE) AS C0150 
						
						, A.CURRENCY_CD AS C0160
						
						, SUM(A.REINSURER_AMT) AS C0170

	FROM 
		test.X_S3701_CONCENTRATION_RISK  A 

		LEFT JOIN 

		(SELECT 
				DISTINCT 
					ARG.ASSESSMENT_AGENCY_CD,
					ARG.ASSESSMENT_GRADE,
					ARG.ASSESSMENT_SCORE_NO

			FROM 
				test.ASSESSMENT_RATING_GRADE ARG

			WHERE 
				PUT(DATEPART(ARG.VALID_TO_DTTM),DATE9.) = '31DEC4747'
				AND ARG.ASSESSMENT_GRADE NOT IN ('Govt','Govt Equiv','Agency')
				AND ARG.MODEL_RK = 555

		)DRV_SCR_NO

			ON 
			DRV_SCR_NO.ASSESSMENT_GRADE = A.SOLII_CREDIT_RATING
			AND DRV_SCR_NO.ASSESSMENT_AGENCY_CD = A.SOLII_CREDIT_RATING_AGENCY			

			WHERE 
				A.ASOF_DATE = &AS_AT_MTH
				AND A.ISSUER_SECTOR IN 

									(
										
										SELECT ISSUER_SECTOR FROM 
											
											(
											
											SELECT INR_A.ISSUER_SECTOR,SUM(INR_A.MKT_VALUE) AS AGG_MKT_VAL
											FROM test.X_S3701_CONCENTRATION_RISK INR_A
											
											WHERE 
											INR_A.ASOF_DATE = &AS_AT_MTH												
																     			
											GROUP BY INR_A.ISSUER_SECTOR
											HAVING SUM(INR_A.MKT_VALUE) > &Thrshold*1000000
											
											)FIND_THSLD
									
									)

			GROUP BY 
				C0020 , 
				C0030 , 
				C0120 , 
				C0130 , 
				C0060 ,
				C0070 ,
				C0010 ,
				C0040 ,
				C0050 , 
				C0090 , 
				C0091 ,
				C0100 ,
				C0110 ,
				C0140 ,
				C0160
  )FINAL_CALC

	LEFT JOIN
	(
		SELECT 
			DISTINCT 
				ARG_OUTER.ASSESSMENT_AGENCY_CD,
				ARG_OUTER.ASSESSMENT_GRADE,
				ARG_OUTER.ASSESSMENT_SCORE_NO 
	
		FROM 
			test.ASSESSMENT_RATING_GRADE ARG_OUTER

		WHERE 
			PUT(DATEPART(ARG_OUTER.VALID_TO_DTTM),DATE9.) = '31DEC4747'
			AND ARG_OUTER.MODEL_RK = 555
			AND ARG_OUTER.SHORTTERM_FLG = '0'
		    AND ASSESSMENT_GRADE NOT IN ('Govt','Govt Equiv','Agency')
			/*  remove non standard rating*/
			AND ARG_OUTER.ASSESSMENT_GRADE NOT LIKE '%(P)%'
			AND ARG_OUTER.ASSESSMENT_GRADE NOT LIKE '%-mf%'
			AND ARG_OUTER.ASSESSMENT_GRADE NOT LIKE '%#%'
			AND ARG_OUTER.ASSESSMENT_GRADE NOT LIKE '%pre%'
			/* -------------------------- */
	)DRV_SCR_MIN_NO
								ON 
								DRV_SCR_MIN_NO.ASSESSMENT_SCORE_NO = FINAL_CALC.C0080_SCORE
								AND DRV_SCR_MIN_NO.ASSESSMENT_AGENCY_CD = FINAL_CALC.C0090			

ORDER BY
	C0060
	,C0100


	;

QUIT;




PROC SUMMARY DATA=WORK.S37_QRT;
VAR C0150 ;
CLASS C0010 ;
OUTPUT OUT=WORK.S37_QRT_CPRTY_SUM SUM=;
RUN;


PROC SUMMARY DATA=WORK.S37_QRT;
VAR C0150 ;
CLASS C0100 ;
OUTPUT OUT=WORK.S37_QRT_NACE_SUM SUM=;
RUN;


PROC SORT DATA=WORK.S37_QRT_CPRTY_SUM(WHERE=(_TYPE_ = 1)) ;  
BY DESCENDING C0150 ;
RUN;


PROC SORT DATA=WORK.S37_QRT_NACE_SUM(WHERE=(_TYPE_ = 1)) ;  
BY DESCENDING C0150 ;
RUN;

DATA S37_QRT_CPRTY_PIVOT ;
KEEP C0010 C0150 ; 
SET WORK.S37_QRT_CPRTY_SUM;
RUN;

DATA S37_QRT_NACE_PIVOT ;
KEEP C0100 C0150 ; 
SET WORK.S37_QRT_NACE_SUM;
RUN;