

/*********************** PASS PARAMETERS DURING EXECUTION ************************

-- %let AS_AT_MTH = &AS_AT_MTH - DD/MM/YYYY , PLEASE I/P  THE MONTH END DATE WHILST GENERATING THE REPORT

*********************** PASS PARAMETERS DURING EXECUTION ************************

*********************** 					IGT2                                                    ************************
***********************                     IGT2 - DERIVATIVES - V1    IMT VERSION                  ************************
***********************   		    	    AUTHOR - MANJUNATH BOOMINATH							************************
***********************  					RACF_ID - BMGS											************************
***********************                     EMAIL_ID - MANJUNATH.BOOMINATH@DIRECTLINEGROUP.CO.UK 	************************
***********************                     last Updated DT - 04/01/2022                            ************************/


PROC SQL;


OPTIONS MISSING='';

	CREATE TABLE WORK.IGT2_S3602_IMT AS 


		SELECT 
			 IGT2.IGT_ID AS C0010,

			 IGT2.INVESTOR_BUYER_NM AS C0020,

			 IGT2.INVESTOR_BUYER_LEI_CD AS C0030 ,

			 CASE WHEN IGT2.INVESTOR_BUYER_LEI_STATUS = '1' THEN '1 - LEI' ELSE IGT2.INVESTOR_BUYER_LEI_STATUS END AS C0040,

			 IGT2.ISSUER_SELLER_NM AS C0050,

			 IGT2.ISSUER_SELLER_LEI_CD AS C0060 ,

			 CASE WHEN IGT2.ISSUER_SELLER_LEI_STATUS = '1' THEN '1 - LEI' ELSE IGT2.INVESTOR_BUYER_LEI_STATUS END AS C0070,

			 IGT2.INSTRUMENT_ID AS C0080 ,

			 CASE WHEN IGT2.INSTRUMENT_TYPE_CD = '99' THEN '99 - Code attributed by the undertaking' ELSE IGT2.INSTRUMENT_TYPE_CD END AS C0090,

			 CASE WHEN IGT2.TRANS_TYPE_CD = '2' THEN '2 - Derivatives - forwards' ELSE IGT2.TRANS_TYPE_CD END AS C0100,

			 PUT(IGT2.TRANS_TRADE_DT,DDMMYY10.) AS C0110,

			 PUT(IGT2.MATURITY_DT,DDMMYY10.) AS C0120,

			 IGT2.NOTIONAL_CURRENCY_CD AS C0130,

			 IGT2.NOTIONAL_TRANS_AMT AS C0140,

			 IGT2.NOTIONAL_RPT_AMT AS C0150,

			 COALESCE(PUT(IGT2.COLLATERAL_VALUE,21.2),'-') AS C0160 , 

			 CASE WHEN IGT2.DRVTS_CD = '3' THEN '3 - Matching assets and liabilities cash-flows ' ELSE IGT2.DRVTS_CD END AS C0170 ,

			 IGT2.ASSET_LIAB_DRVT_ID AS C0180 ,

			 CASE WHEN IGT2.ASSET_LIAB_DRVT_ID_CD = '9' THEN '9 - Other code by members of the Association of  National Numbering Agencies' 
			 			WHEN IGT2.ASSET_LIAB_DRVT_ID_CD = '99' THEN '99 - Code attributed by the undertaking' ELSE IGT2.ASSET_LIAB_DRVT_ID_CD END AS C0190 ,

			 COALESCE(IGT2.COUNTERPARTY_NM,'-') AS C0200 , 

			 COALESCE(IGT2.SWAP_DLVRD_INTEREST_RT,'-') AS C0210,

		 	 COALESCE(IGT2.SWAP_RCVD_INTEREST_RT,'-') AS C0220,

		 	 COALESCE(IGT2.SWAP_DLVRD_CURRENCY_CD,'-') AS C0230 ,

			 COALESCE(IGT2.SWAP_RCVD_CURRENCY_CD,'-') AS C0240 ,

		/*--------------------------------------------------------------INTERNAL COLUMNS-------------------------------------------------------------------------*/
			 MONTH(&AS_AT_MTH) AS INT9,

			 YEAR(&AS_AT_MTH)  AS INT10
											  
		FROM 
			test.X_INTER_GRP_TRANS_DRVTS IGT2 

		WHERE 				
			IGT2.ASOF_DATE = &AS_AT_MTH
									
		ORDER BY 
		    C0010
		;
QUIT;