
PROC SQL;

/*Create Temp work table*/

CREATE TABLE WORK.TEMP5 AS 

	/* Summary of all the data from the LOOKTHROUGH VIEW */


	SELECT 
			PUT(AS_AT_MTH,DDMMYY10.) AS AS_AT_MTH, 
			PRNT_CUSIP, 
			PRTFL_ID AS PORTFOLIO_ID, 
			SUM(BOOK_CST) AS BOOK_COST, 
			SUM(MKT_VAL) AS MKT_VAL 
	FROM 
			/* USE THE CORRECT LIBRARY */
			test.CM_INVSTMNT_LKTHRGH 

	WHERE 
			AS_AT_MTH = &AS_AT_MTH  
			AND PPN_DTTM = 
							(
							SELECT 
								MAX(PPN_DTTM) 
							FROM  
								test.CM_INVSTMNT_LKTHRGH 
							WHERE 
								AS_AT_MTH = &AS_AT_MTH
							)

	GROUP BY 
			1,2,3 

	ORDER BY 
		1,2,3 ;

QUIT;	
