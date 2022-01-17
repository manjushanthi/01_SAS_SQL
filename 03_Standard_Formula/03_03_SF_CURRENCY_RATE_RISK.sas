/* RUN FROM Append */

PROC SQL ;

/*Create Temp table to load the extracted Data*/

OPTIONS MISSING='';

CREATE TABLE WORK.SF_CRNCY_RSK_ AS 

	SELECT

		PORTF_NAME

	/*	, DATA_SOURCE */
	/*	, CUSIP  */

		, CURRENCY

		, SUM(CASE WHEN  SUBSTR(CIC,3,1) = ('E')  THEN GBP_CUR_FACE_DIV_1000 ELSE 0 END) AS CURRENCY_HEDGE_AMT_DIV_1000

		, SUM(
				CASE 
					WHEN UPCASE(X_PAM_GL_GRP) NOT IN ('RESIDUALS','CASHBAL','FORWARDS','FX SPOTS')  THEN MKT_VALUE_DIV_1000 
					ELSE 0 
				END 
					+ 
			    CASE 
					WHEN X_PAM_GL_GRP = '' THEN -1*MKT_VALUE_DIV_1000 
					ELSE 0 
				END
 			 ) AS CURRENCY_TOTAL_ASSETS_DIV_1000


		, SUM(
			    CASE WHEN  SUBSTR(CIC,3,1) = ('E')  THEN GBP_CUR_FACE_DIV_1000 ELSE 0 END

				+
				CASE 
					WHEN UPCASE(X_PAM_GL_GRP) NOT IN ('RESIDUALS','CASHBAL','FORWARDS','FX SPOTS')  THEN MKT_VALUE_DIV_1000 
					ELSE 0 
			    END 

				+ 
			    CASE 
					WHEN X_PAM_GL_GRP = '' THEN -1*MKT_VALUE_DIV_1000 
					ELSE 0 
				END
			) AS CURRENCY_RISK_EXPOSURE_DIV_1000

		, (SUM(
			    CASE WHEN  SUBSTR(CIC,3,1) = ('E')  THEN GBP_CUR_FACE ELSE 0 END

				+
				CASE 
					WHEN UPCASE(X_PAM_GL_GRP) NOT IN ('RESIDUALS','CASHBAL','FORWARDS','FX SPOTS')  THEN MKT_VALUE 
					ELSE 0 
			    END 

				+ 
			    CASE 
					WHEN X_PAM_GL_GRP = '' OR X_PAM_GL_GRP = '-' THEN -1*MKT_VALUE 
					ELSE 0 
				END
			) ) AS CURRENCY_RISK_EXPOSURE

	FROM 
		WORK.SF_BASE_APPEND

	WHERE 
		CURRENCY <> 'GBP'

	GROUP BY 
	/*	DATA_SOURCE */
	/*	, CUSIP*/
		 PORTF_NAME
		, CURRENCY

	ORDER BY
		CURRENCY

	;
QUIT;