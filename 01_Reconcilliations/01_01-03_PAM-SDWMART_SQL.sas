/*      PAM Reconcilliations 03 - SDW_MART Reconcillations         */
/*      Extract the Mart data from the SDW_MART Data sets         */

PROC SQL;

/*Create Temp work table*/
CREATE TABLE WORK.TEMP3 AS 

	/* Summary of all the data from the UNION ALL Sub Query */
	SELECT 
		ACC_GL_GROUP_DESC AS ACC_GL_GROUP_DESC,
		CNT AS CNT ,
		PUT(ACC_UNITS,16.4) AS ACC_UNITS,
		PUT(ACC_PRICE ,16.4) AS ACC_PRICE, 
		PUT(ACC_END_ACCRUED,16.4) AS ACC_END_ACCRUED ,
		PUT(ACC_ACTUAL_BV,16.4) AS ACC_ACTUAL_BV ,
		PUT(ACC_MARKET_VALUE,16.4) AS ACC_MARKET_VALUE ,
		PUT(ACC_COST,16.4) AS ACC_COST  ,
		PUT(ACC_OFV,16.4) AS ACC_OFV,
		PUT(&AS_AT_MTH, DDMMYY10.) AS AT_MTH

	FROM 
		(
			/* Get all the Data excluding FX FWRDS */
			SELECT 
				ACC_GL_GROUP_DESC,
				COUNT(*) AS CNT,
				SUM(ACC_UNITS) AS ACC_UNITS,
				SUM(ACC_PRICE) AS ACC_PRICE , 
				SUM(ACC_END_ACCRUED) AS ACC_END_ACCRUED , 
				SUM(ACC_ACTUAL_BV) AS ACC_ACTUAL_BV , 
				SUM(ACC_MARKET_VALUE) AS ACC_MARKET_VALUE , 
				SUM(ACC_COST) AS ACC_COST , 
				SUM(ACC_OFV) AS ACC_OFV

			FROM 
				test.CM_BLKRK_ACCT_NON_FX 

			WHERE 
				AS_AT_MTH = &AS_AT_MTH 
				/*Extract the AS_AT_MTH dates alone*/ 

				AND PPN_DTTM = 
			   /*Extract the AS_AT_MTH dates and the latest version of the AS_AT_MTH alone*/ 

								(
									SELECT 
										MAX(PPN_DTTM) AS PPN_DTTM 

									FROM 
										test.CM_BLKRK_ACCT_NON_FX 

									WHERE  
										/*Extract the AS_AT_MTH dates alone*/ 
										AS_AT_MTH = &AS_AT_MTH
								)
			GROUP BY 
				1

			UNION ALL 

			SELECT 
					/* Get the FX FWRDS */
					ACC_GL_GROUP_DESC,
					COUNT(*) AS CNT,
					SUM(ACC_UNITS) AS ACC_UNITS,
					SUM(ACC_PRICE) AS ACC_PRICE, 
					SUM(ACC_END_ACCRUED) AS ACC_END_ACCRUED,
					SUM(ACC_ACTUAL_BV) AS ACC_ACTUAL_BV , 
					SUM(ACC_MARKET_VALUE) AS ACC_MARKET_VALUE , 
					SUM(ACC_COST) AS ACC_COST , 
					SUM(ACC_OFV) AS ACC_OFV

			 FROM 
					test.CM_BLKRK_ACCT_FX 

			WHERE 
					AS_AT_MTH = &AS_AT_MTH  
					AND PPN_DTTM = 
									(
										SELECT 
											MAX(PPN_DTTM) AS PPN_DTTM 
												
										FROM 
											test.CM_BLKRK_ACCT_FX 

										WHERE  
											AS_AT_MTH = &AS_AT_MTH
											/*Extract the AS_AT_MTH dates alone*/ 
									)
			GROUP BY 
				1
		)A

	ORDER BY 
		ACC_GL_GROUP_DESC;

QUIT;	
