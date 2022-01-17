/* Fix - 14/01/2021
used (XFPC.X_NET_MKT+COALESCE(PAM_USE.ACC_END_ACCRUED,0))
PREVIOUSLY
(XFPC.X_NET_MKT+PAM_USE.ACC_END_ACCRUED)
*/



PROC SQL;

/*Create Temp work table*/
CREATE TABLE WORK.TEMP4 AS 


SELECT 
/*Create 12 Columns in the correct order from the main sub query*/
	CCAT
	,FINANCIAL_INSTRUMENT_TYPE_CD
	,INSTRUMENT_TYPE_CD		
	,NO_OF_RECORDS	
	,MKT_VAL	
	,FACE_VAL	
	,BOOK_VAL	
	,ACT_SOLII	
	,EXPC_SOLII	
	,DIFF	
	,SRC	
	,CIC_3_4
	,PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH


FROM 

	(

		/*main sub query STARTS*/
		SELECT                 
			 

			CASE 	
				WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '004' AND FX_LEG.X_FX_INSTRUMENT_LEG_RK IS NOT NULL) 
					THEN '012' 
				ELSE  
					FI.FINANCIAL_INSTRUMENT_TYPE_CD 
			END AS FINANCIAL_INSTRUMENT_TYPE_CD , 

			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '001') THEN 'ABS' ELSE  
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '002') THEN 'ARM' ELSE  
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '003') THEN 'BND' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '004' AND FX_LEG.X_FX_INSTRUMENT_LEG_RK IS NOT NULL) THEN 'FX' ELSE  
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '004') THEN 'CASH' ELSE  
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '005') THEN 'CDI' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '006') THEN 'CMBS' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '007') THEN 'CMDTY' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '008') THEN 'CMO' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '009' AND X_PARTICIPATION_CD = 'N') THEN 'EQUITY' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '009' AND X_PARTICIPATION_CD <> 'N') THEN 'EQUITY-PRTCP' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '010') THEN 'FUND' ELSE  
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '011') THEN 'FUTURE' ELSE  
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '012') THEN 'FX' ELSE  
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '013') THEN 'IBND' ELSE  
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '014') THEN 'INDEX' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '015') THEN 'LOAN' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '016') THEN 'MBS' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '017') THEN 'OPTION' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '018') THEN 'PORT' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '019') THEN 'RE' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '020') THEN 'SWAP' ELSE 
			CASE WHEN (FI.FINANCIAL_INSTRUMENT_TYPE_CD = '021') THEN 'SYNTH' 
			ELSE 'N/A' 
			END END END END END END END END END END END END END END END END END END END END END  END END AS INSTRUMENT_TYPE_CD , 

			TRIM(CALCULATED INSTRUMENT_TYPE_CD)||FI.Source_system_CD AS CCAT,

			COUNT(*) AS NO_OF_RECORDS, 

			PUT(SUM(PRESENT_VALUE_AMT),18.5) AS MKT_VAL, 

			PUT(SUM(FACE_VALUE_AMT),18.5) AS FACE_VAL, 

			PUT(SUM(CASE WHEN BOOK_VALUE_AMT IS NULL THEN 0.0 ELSE BOOK_VALUE_AMT END),18.5) AS BOOK_VAL,

			/* Actual Solvency 2 amount populated by the jobs */
			SUM(X_SOLVENCY_II_VALUE) AS ACT_SOLII,

			/* Key logic to arrive as the expected Solvency 2 amount for each category of assets */
			SUM(	CASE 	WHEN ((FI.X_PAM_GL_GRP IN ('TERM NOTES' , 'CRE') AND FP.SOURCE_SYSTEM_CD <> 'NONBLR') OR FP.PORTFOLIO_ID IN ('A_320QUKIM')) THEN (XFPC.X_NET_MKT+COALESCE(PAM_USE.ACC_END_ACCRUED,0))
							ELSE 	CASE	WHEN (FP.PORTFOLIO_ID IN ('DLG-GEPF','DLG-GEFI','DLG-ITCA','DLG-ITBR-N','DLG-ITBR-D','DLG-GECA') OR FP.SOURCE_SYSTEM_CD = 'NONBLR')  THEN FI.PRESENT_VALUE_AMT 
							ELSE	CASE	WHEN (PAM_USE.ACC_GL_GROUP_DESC IN ('','CASHBAL','OPR','FUTURES - BOND') AND PAM_USE.BRSID ^= '') THEN FI.PRESENT_VALUE_AMT  
							ELSE	CASE	WHEN (CALCULATED INSTRUMENT_TYPE_CD IN ('CASH','BND')  AND PAM_USE.BRSID = '') THEN FI.PRESENT_VALUE_AMT 
							ELSE	CASE	WHEN UPCASE(PAM_USE.ACC_GL_GROUP_DESC) IN ('FORWARDS','FX SPOTS') THEN PAM_USE.ACC_MARKET_VALUE  
							ELSE (PAM_USE.ACC_MARKET_VALUE+PAM_USE.ACC_END_ACCRUED) 
					END END END END END) AS EXPC_SOLII,

			/* Arrive at the differences between the Actual solvency 2 amounts and the expected solvency 2 amounts */
			(CALCULATED ACT_SOLII - CALCULATED EXPC_SOLII) AS DIFF ,

			FI.SOURCE_SYSTEM_CD AS SRC,

			SUBSTR(FII.ISSUE_CD,3,1) AS CIC_3_4

			FROM 
				test.FINANCIAL_INSTRUMENT FI                    
			 
			INNER JOIN test.FINANCIAL_POSITION FP                     
				ON FI.FINANCIAL_INSTRUMENT_RK = FP.FINANCIAL_INSTRUMENT_RK 
				AND  PUT(DATEPART(FI.VALID_TO_DTTM),DATE9.) = '31DEC9999' 
				AND  PUT(DATEPART(FP.VALID_TO_DTTM),DATE9.) = '31DEC9999'

			INNER JOIN test.FINANCIAL_INSTRUMENT_ISSUE FII                     
				ON FII.FINANCIAL_INSTRUMENT_RK = FP.FINANCIAL_INSTRUMENT_RK 
				AND  PUT(DATEPART(FII.VALID_TO_DTTM),DATE9.) = '31DEC9999' 
				AND  PUT(DATEPART(FP.VALID_TO_DTTM),DATE9.) = '31DEC9999'
				AND ISSUE_TYPE_CD = '002'

			LEFT JOIN test.X_FINANCIAL_POSITION_CHNG XFPC
				ON FP.FINANCIAL_POSITION_RK = XFPC.FINANCIAL_POSITION_RK 
				AND  PUT(DATEPART(XFPC.VALID_TO_DTTM),DATE9.) = '31DEC9999' 
				AND  PUT(DATEPART(FP.VALID_TO_DTTM),DATE9.) = '31DEC9999' 

			LEFT JOIN test.X_FX_INSTRUMENT_LEG FX_LEG
				ON FX_LEG.FX_LEG_FINANCIAL_INSTR_RK = FI.FINANCIAL_INSTRUMENT_RK
				AND  PUT(DATEPART(FX_LEG.VALID_TO_DTTM),DATE9.) = '31DEC9999' 

			/*Extract data from PAM related tables*/
			LEFT JOIN 
			(
					SELECT
				         TICKER,
				         BRSID,
				         ISIN,
				         FINANCIAL_INSTRUMENT_RK,
				         PHYSICAL_ASSET_RK,
				         ACC_SECURITY_DESC_LINE_1,
				         ACC_SECURITY_DESC_LINE_2,
				         ACC_SECURITY_DESC_LINE_3,
				         ACC_GL_GROUP_DESC,
				         ACC_UNITS,
				         ACC_PRICE,
				         ACC_END_ACCRUED,
				         ACC_ACTUAL_BV,
				         ACC_MARKET_VALUE,
				         ACC_CURRENCY,
				         ACC_COST,
				         ACC_OFV
				         
					FROM 
				          test.X_BLKRK_ACCT

					WHERE 
				          PUT(DATEPART(VALID_TO_DTTM),DATE9.) = '31DEC9999' 
				         
				    UNION ALL 
				         
				    SELECT
				         TICKER,
				         BRSID,
				         ISIN,
				         FINANCIAL_INSTRUMENT_RK,
				         0,
				         ACC_SECURITY_DESC_LINE_1,
				         ACC_SECURITY_DESC_LINE_2,
				         ACC_SECURITY_DESC_LINE_3,
				         ACC_GL_GROUP_DESC,
				         ACC_UNITS,
				         ACC_PRICE,
				         ACC_END_ACCRUED,
				         ACC_ACTUAL_BV,
				         CASE WHEN ACC_SECURITY_DESC_LINE_2 = 'S' THEN -1*ACC_MARKET_VALUE ELSE ACC_MARKET_VALUE END ,
				         ACC_CURRENCY,
				         ACC_COST,
				         ACC_OFV
				         
				  	FROM 
				          test.X_BLKRK_ACCT_FXFWD
				   	WHERE 
				            PUT(DATEPART(VALID_TO_DTTM),DATE9.) = '31DEC9999' 
			) PAM_USE
			      
			      ON  PAM_USE.FINANCIAL_INSTRUMENT_RK = FI.FINANCIAL_INSTRUMENT_RK


		/* group by non aggregated columns */
		GROUP BY 12,11,3,2,1
	)TMP
	/*main sub query Ends*/

/*order by 3_4 character of CIC Codes */
ORDER BY 12 ;

QUIT;	