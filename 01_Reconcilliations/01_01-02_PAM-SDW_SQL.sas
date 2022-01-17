

PROC SQL;

/*Create Temp work table*/

CREATE TABLE WORK.TEMP2 AS 

	/* Summary of all the data from the UNION ALL Sub Query */
	SELECT 
		ACC_GL_GROUP_DESC ,
		CASE WHEN ACC_GL_GROUP_DESC IN ('INTEREST RATE SWAPS','SWAPS','INTEREST RATE SWAPS CCS') THEN COUNT(ACC_GL_GROUP_DESC)*2 ELSE 
		COUNT(ACC_GL_GROUP_DESC) END AS CNT ,
		PUT(SUM(ACC_UNITS),16.4) AS ACC_UNITS,
		PUT(SUM(ACC_PRICE),16.4) AS ACC_PRICE,
		PUT(SUM(ACC_END_ACCRUED),16.4) AS ACC_END_ACCRUED ,
		PUT(SUM(ACC_ACTUAL_BV),16.4) AS ACC_ACTUAL_BV,
		PUT(SUM(ACC_MARKET_VALUE),16.4) AS ACC_MARKET_VALUE ,
		PUT(SUM(ACC_COST),16.4) AS ACC_COST,
		PUT(SUM(ACC_OFV),16.4) AS ACC_OFV

	FROM 

		(
			/* Get the Non Property Data excluding FX FWRDS */
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
				/*Extract the High End dates alone*/  
				AND FINANCIAL_INSTRUMENT_RK <> -100 
				/* Extract only the joined and valid . 
				non joined records will be excluded from the downstream flows */
				AND PHYSICAL_ASSET_RK IS NULL
				/* Exclude the Property records in this sub query but include later */

			UNION ALL 

			/* Get the Property Data */
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
				/*Extract the High End dates alone*/   
				AND PHYSICAL_ASSET_RK IS NOT NULL 
				/* Include the Property records in this sub query */


			UNION ALL 

			/* Get the Non Property Data */
			SELECT
				TICKER,
				BRSID,
				ISIN,
				FINANCIAL_INSTRUMENT_RK,
				0 AS PHYSICAL_ASSET_RK,
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
				test.X_BLKRK_ACCT_FXFWD

			WHERE 
				PUT(DATEPART(VALID_TO_DTTM),DATE9.) = '31DEC9999'
				/*Extract the High End dates alone*/ 
				AND FINANCIAL_INSTRUMENT_RK <> -100
				/* Extract only the joined and valid . 
				non joined records will be excluded from the downstream flows */
		  
		) ACC  

	GROUP BY 
	ACC_GL_GROUP_DESC 

	ORDER BY 
	1  ;


QUIT;
