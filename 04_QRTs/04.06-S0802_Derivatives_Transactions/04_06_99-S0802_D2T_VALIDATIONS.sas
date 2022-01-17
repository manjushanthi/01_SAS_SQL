
PROC SQL;

/*Create Temp table to load the extracted Data*/

CREATE TABLE WORK.S0802_D2T_IMT_VALID AS 

	SELECT 
	
		DISTINCT

	 		 COUNTERPARTY_NM AS C0240

			 , CASE WHEN COUNTERPARTY_LEI_STATUS = '2' THEN '' ELSE COUNTERPARTY_LEI_CD END AS C0250

		     , CASE WHEN COUNTERPARTY_LEI_STATUS = '1' THEN '1 - LEI' 
		            WHEN COUNTERPARTY_LEI_STATUS = '9' THEN '9 - None'
		            WHEN COUNTERPARTY_LEI_STATUS = '2' THEN '9 - None'
		            ELSE COUNTERPARTY_LEI_STATUS 
			   END AS C0260

			 , COUNTERPARTY_GRP_NM AS C0270

		     , CASE WHEN COUNTERPARTY_GRP_LEI_STATUS = '2' THEN '' ELSE COUNTERPARTY_GRP_LEI_CD END AS C0280

		     , CASE WHEN COUNTERPARTY_GRP_LEI_STATUS = '1' THEN '1 - LEI' 
		            WHEN COUNTERPARTY_GRP_LEI_STATUS = '9' THEN '9 - None'
		            WHEN COUNTERPARTY_GRP_LEI_STATUS = '2' THEN '9 - None'
		            ELSE  COUNTERPARTY_GRP_LEI_STATUS
				END AS C0290

	FROM 
		test.X_CLOSED_DRVTS_TRANS  D2T
	                
	WHERE                 
		DATEPART(D2T.VALID_FROM_DTTM) <= &AS_AT_MTH                                                                                                                    
		AND DATEPART(D2T.VALID_TO_DTTM) > &AS_AT_MTH                                                                                                                           
		AND D2T.ASOF_DATE = &AS_AT_MTH 

	ORDER BY 
		C0240;

QUIT;
		
	
          