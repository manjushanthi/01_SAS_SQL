%LET ENTITY_NAME ='U K Insurance Limited'; /* 'U K Insurance Limited'   'Churchill Insurance Company Limited'   */

PROC SQL ;

	CREATE TABLE WORK.S0602_D1_INV_SOLO_PARTB  AS 

		SELECT 

			
			 CASE 
				WHEN A5 = 'ISIN' THEN 'ISIN/' 
				WHEN A5 = 'CUSIP' THEN 'CUSIP/'
				WHEN A5 = 'UNDERTAKING' THEN  'CAU/INST/' 
				ELSE 'CHECK X_EIOPA_CD'       
			  END||A4 AS C0040

			, CASE 
				WHEN A7 = 'Not Applicable - CIC' THEN ''
				ELSE A7 
			  END AS C0190

			, CASE 
				WHEN A8 = 'Not Applicable - CIC' THEN ''
				ELSE A8 
			  END AS C0200

			, CASE 
				WHEN A33 = '1' THEN  'LEI/'||A31
				WHEN A33 = '2' THEN  'None' 
				WHEN A33 = '9' OR A33 = '-' OR A33 = '' THEN  'None'
				WHEN A33 = 'Not Applicable - CIC' THEN '' 
				ELSE  'CHECK X_EIOPA_CD'
			  END AS C0210

			, CASE 
				WHEN A9 = 'Not Applicable - CIC' THEN ''
				ELSE A9 
			  END AS C0230

			, CASE 
				WHEN A10 = 'Not Applicable - CIC' THEN ''
				ELSE A10 
			  END AS C0240

			, CASE 
				WHEN A33GROUP = '1' THEN  'LEI/'||A32
				WHEN A33GROUP = '2' THEN  'None' 
				WHEN A33GROUP = '9' OR A33 = '-' OR A33 = '' THEN  'None'
				WHEN A33GROUP = 'Not Applicable - CIC' THEN ''
				ELSE  'CHECK X_EIOPA_CD'
			  END AS C0250

			, CASE 
				WHEN A11 = 'Not Applicable - CIC' THEN ''
				ELSE A11 
			  END AS C0270

			, CASE 
				WHEN A13 = 'Not Applicable - CIC' THEN ''
				ELSE A13 
			  END AS C0280

			, A15 AS C0290

			, CASE /*Only applicable for Solo , not required for group reporting*/
				WHEN C0292 = 'Not Applicable - CIC' THEN ''
				WHEN C0292 = '1' THEN '1'
				ELSE 'CHECK X_EIOPA_CD'
			  END AS C0292

			, C0300

			, CASE 
				WHEN A16 = '1' THEN '1'
				WHEN A16 IN ( '2' , '6') THEN '2'
				WHEN A16 = 'Not Applicable - CIC' THEN ''
				ELSE A16
			 END AS C0310 

			, CASE 
				WHEN X_INTERNAL_RATING = '' THEN A17
				WHEN X_INTERNAL_RATING = 'Not Applicable - CIC' THEN ''
				ELSE ''
			  END AS C0320

			, CASE
				WHEN X_INTERNAL_RATING = '' THEN 
												CASE	
													WHEN A18 =  'S_P' THEN  'Standard & Poor'||"'"||'s'
													WHEN A18 =  'MDY' THEN  'Moody'||"'"||'s'
													WHEN A18 =  'FIT' THEN  'Fitch'		
													ELSE A18		
												END
				WHEN  X_INTERNAL_RATING = 'Not Applicable - CIC' THEN ''
				ELSE ''
			  END AS C0330

			, CASE
				WHEN SOLII_CREDIT_QUALITY = 'Not Applicable - CIC' THEN ''
				WHEN X_INTERNAL_RATING <> '' AND A18 <> 'Not Applicable - CIC' THEN '9'
				ELSE SOLII_CREDIT_QUALITY
			  END AS C0340

			, CASE
				WHEN X_INTERNAL_RATING = 'Not Applicable - CIC' THEN ''
				ELSE X_INTERNAL_RATING
			  END AS C0350

			,  INPUT(CASE 
				WHEN A20 = 'Not Applicable - CIC' THEN ''
				ELSE A20 
			  END , 10.4) AS C0360 FORMAT = 10.4

			, INPUT( (CASE 
				 WHEN COALESCE(A23PAM,A23BRS) = 'Not Applicable - CIC' THEN ''
				 ELSE COALESCE(A23PAM,A23BRS)
			  END),  20.16)/100 AS C0370 FORMAT=20.16

			, INPUT( (CASE WHEN  
						( AVG(
						 (CASE 
								WHEN COALESCE(A23APAM,A23ABRS) =  'Not Applicable - CIC' THEN 0.0 
								ELSE INPUT(COALESCE(A23APAM,A23ABRS),20.16)/100 
						  END))) = 0.000000000000 THEN '' 
							ELSE PUT( (AVG(
						 (CASE 
								WHEN COALESCE(A23APAM,A23ABRS) =  'Not Applicable - CIC' THEN 0.0 
								ELSE INPUT(COALESCE(A23APAM,A23ABRS),20.16)/100 
					  		END))),20.16) 
					END),20.16) AS C0380 FORMAT=20.16

			, CASE 
				WHEN A28 = 'Not Applicable - CIC' THEN ''
				ELSE A28 
			   END AS C0390

		FROM 
			WORK.S0602_D1_BASE

		WHERE
			 A50 IN ('U K Insurance Limited - ROI Branch' , 'U K Insurance Limited')
			/*&ENTITY_NAME
			  A50 = 'Churchill Insurance Company Limited'  
			 'U K Insurance Limited' 'U K Insurance Limited - ROI Branch'*/

		GROUP BY 
		
			C0040
			, C0190
			, C0200
			, C0210
			, C0230
			, C0240
			, C0250
			, C0270
			, C0280
			, C0290
			, C0292
			, C0300
			, C0310 
			, C0320
			, C0330
			, C0340
			, C0350
			, C0360
			, C0370
			, C0390
		

		HAVING 
			SUM(A26FIN_SDW) <> 0 

/* DONT PUT ORDER WHEN THE COLUMN IS NOT IN SELECT */

		ORDER BY 
			SUBSTR(C0290,3,2)
			, C0290
			, C0040 ;
QUIT;