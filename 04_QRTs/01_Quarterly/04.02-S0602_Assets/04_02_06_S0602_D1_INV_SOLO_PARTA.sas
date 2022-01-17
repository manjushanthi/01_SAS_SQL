%LET ENTITY_NAME ='U K Insurance Limited'; /* 'U K Insurance Limited'   'Churchill Insurance Company Limited'   */

PROC SQL ;

	CREATE TABLE WORK.S0602_D1_INV_SOLO_PARTA  AS 

		SELECT 

			/****************************************************************************/
			/********************************PART 1 - START*****************************/
			/**************************************************************************/

			 CASE 
				WHEN A5 = 'ISIN' THEN 'ISIN/' 
				WHEN A5 = 'CUSIP' THEN 'CUSIP/'
				WHEN A5 = 'UNDERTAKING' THEN  'CAU/INST/' 
				ELSE 'CHECK X_EIOPA_CD'       
			  END||A4 AS C0040

			, CASE 
				WHEN A2 = 'Not Ring Fenced' THEN ''
				ELSE A2 
			  END AS C0070
	
			, '' AS C0080

			, A1 AS C0060
		
			, CASE 
				WHEN A3 = 'N' THEN '2' 
				ELSE '1' 
			  END AS C0090

			, A6 AS C0100

			, CASE 
				WHEN A12 = 'Not Applicable - CIC' THEN '' 
				ELSE A12 
			  END AS C0110

			, CUSTODIAN AS C0120

			, SUM (	INPUT( (CASE 
							WHEN  	(
									CASE 
										WHEN A16 = '6' THEN A22BRS
										ELSE COALESCE(A22PAM,A22BRS,'0.00')
						  			END 
									) = 'Not Applicable - CIC'
							THEN ''
							ELSE (
									CASE 
										WHEN A16 = '6' THEN A22BRS
										ELSE COALESCE(A22PAM,A22BRS,'')
						  			END 
								  )
						 END) , 21.2 ) ) AS C0130 FORMAT=21.2 

			
			, SUM( INPUT( (CASE 
							WHEN COALESCE(A22APAM,A22ABRS,'0.00') = 'Not Applicable - CIC'	THEN ''
							ELSE COALESCE(A22APAM,A22ABRS,'')
						  END) , 21.2 ) ) AS C0140 FORMAT=21.2

			, A24 AS C0150

			, INPUT( ( CASE 
						 WHEN PUT(SUM(C0160_CALC*A26FIN_SDW)/SUM(A26FIN_SDW),12.4) = '0.00' THEN ''
						 ELSE PUT(SUM(C0160_CALC*A26FIN_SDW)/SUM(A26FIN_SDW),12.4)
					   END ), 12.4 ) AS C0160 FORMAT 12.4

			, SUM ( A26FIN_SDW ) AS C0170  FORMAT=21.2

			, SUM ( COALESCE(A30PAM,A30BRS) ) AS C0180 FORMAT=18.2

			/****************************************************************************/
			/****************************************************************************/
										, '' AS END_PART1
			/********************************PART 1 - END*******************************/
			/**************************************************************************/

			, SUBSTR(A15,3,2) AS INT21

			, A15 AS C0290

		FROM 
			WORK.S0602_D1_BASE

		WHERE
			 A50 IN ('U K Insurance Limited - ROI Branch' , 'U K Insurance Limited')
			/*&ENTITY_NAME
			  A50 = 'Churchill Insurance Company Limited'  
			 'U K Insurance Limited' 'U K Insurance Limited - ROI Branch'*/

		GROUP BY 
			C0040
			, C0070
			, C0080
			, C0060
			, C0090
			, C0100
			, C0110
			, C0120
			, C0150
			, END_PART1
			, INT21
			, C0290	

		HAVING 
			SUM(A26FIN_SDW) <> 0 

/* DONT PUT ORDER WHEN THE COLUMN IS NOT IN SELECT */

		ORDER BY 
			INT21
			, C0290
			, C0040 ;

QUIT;