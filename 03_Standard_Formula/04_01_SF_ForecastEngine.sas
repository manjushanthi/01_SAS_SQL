
PROC SQL ;

/*Create Temp table to load the extracted Data*/

OPTIONS MISSING='';

CREATE TABLE WORK.SF_FORECAST_ENGINE AS 

	SELECT 

		DATA_SOURCE

		, CUSIP

		, PORTF_LIST

		, PORTF_NAME

		, PARENT_CUSIP

		, PARENT_ISIN	
	
		, COALESCE(PXS_DATE,PUT(&AS_AT_MTH,DDMMYY10.)) AS PXS_DATE

		, SM_SEC_GROUP

		, SM_SEC_TYPE

		, SM_CPN_TYPE

		, RESET_INDEX

		, COUNTRY

		, CURRENCY

		, MKT_VALUE

		, MKT_VALUE_DIV_1000

		, GBP_CUR_FACE

		, GBP_CUR_FACE_DIV_1000

		, COUPON

		, COUPON_FREQUENCY

		, NEXT_COUPON

		, MOD_DUR

		, MOD_DUR_S2

		, SPREAD_DUR

		, YIELD_TO_MAT

		, MATURITY_DATE

		, ZV_MATURITY_DATE

		, SHORT_STD_DESC

		, ULTIMATE_PARENT_TICKER

		, ULT_ISSUER_NAME

		, ISSUER_NAME

		, LEHM_RATING_TXT
		
		, LEHM_RATING_ISS

		, AVE_RATING

		, BARCLAYS_FOUR_PILLAR_SECTOR

		, BARCLAYS_FOUR_PILLAR_SUBSECTOR

		, BARCLAYS_FOUR_PILLAR_INDUSTRY

		, BARCLAYS_FOUR_PILLAR_SUBINDUSTRY

		, INFL

		, INTERNAL_RATING

		, ISIN

		, CASE 
			WHEN PUT_CALL = '001' THEN 'C' 
			WHEN PUT_CALL = '002' THEN 'P' 
			WHEN PUT_CALL = '003' THEN 'S' 
			WHEN PUT_CALL = '004' THEN 'W' 
			WHEN PUT_CALL = '005' THEN 'K' 
			WHEN PUT_CALL = '000' THEN ''
			ELSE PUT_CALL 
		  END  AS PUT_CALL

		, CIC

		, PAM_MV

		, GBP_CONV_CUR_FACE

		, TICKER

		, MKT_NOTION

		, X_PAM_GL_GRP

		, I_T_CURRENCY_RATE

		, I_T_CLS_GRP

		, I_T_CLS_CAT

		, FIN_INV_CLS

		, RTG_MOODYS

		, CASE WHEN MDY_SCORE = 0 THEN . ELSE MDY_SCORE END AS MDY_SCORE

		, RTG_SP

		, CASE WHEN SP_SCORE = 0 THEN . ELSE SP_SCORE END AS SP_SCORE

		, RTG_FITCH

		, CASE WHEN FIT_SCORE = 0 THEN . ELSE FIT_SCORE END AS FIT_SCORE

		, CASE WHEN WTFL_SCORE = 0 THEN . ELSE WTFL_SCORE END AS  WTFL_SCORE

		, WTFL_GRADE

		, WTFL_AGENCY

		, SNP_EQUI_RATING

		, GROUPED_RATING

		, WTFL_SII_CREDIT_QLTY_VAL

/*--------------------------------------------------Risk Categorisation begins------------------------------------------*/

		/*Find  out the assets in Interest Rate risk */
		/***********************************************************/
		/********************** INTEREST RATE RISK *****************/
		/***********************************************************/
		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('1','2','5','6','8') AND PORTF_LIST <> 'A_320UKIDE'  
				THEN 1
			ELSE 
				CASE 
					WHEN DATA_SOURCE = '03 - Lookthrough' AND SUBSTR(CIC,3,1) IN ('4') AND SM_SEC_GROUP = 'BND' 
						THEN 1
					ELSE
						0 
				END 
		  END AS INT_RT_RSK

		 /*Find  out the assets in Interest Rate risk for derivatives */
		  /*************************************************************/
		  /************ INTEREST RATE RISK FOR DERIVATIVES ************/
		  /***********************************************************/
		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('D','A') AND PORTF_LIST <> 'A_320UKIDE' 
				THEN 1
			ELSE 0
		   END AS INT_RT_DRVTS_RSK

 		/*find out the assets in Equity (participations to be modellled as a Equity Risk)*/
		  /*************************************************************/
		  /********************* EQUITY  RISK *************************/
		  /***********************************************************/
		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('3') AND PORTF_LIST <> 'A_320UKIDE' THEN 1 
			ELSE 0 
		  END AS EQTY_RSK

		/* find out the assets in Property */
		  /*************************************************************/
		  /********************* PROPERTY  RISK ***********************/
		  /***********************************************************/
		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('9') AND PORTF_LIST <> 'A_320UKIDE' THEN 1 
			ELSE 0 
		  END AS PRPTY_RSK

		/*all the assets included to calculate the currency risk exposure for USD*/
 		  /*************************************************************/
		  /********************* CURRENCY  RISK ***********************/
		  /***********************************************************/
		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('E') AND CURRENCY = 'USD' THEN GBP_CUR_FACE_DIV_1000 
			ELSE 0 
		  END 
					+ 

		  CASE 
			WHEN UPCASE(X_PAM_GL_GRP) NOT IN ('RESIDUALS','CASHBAL','FORWARDS','FX SPOTS') AND CURRENCY = 'USD' 
				THEN MKT_VALUE_DIV_1000 
			ELSE 0 
		  END 
					+ 

		  CASE 
			WHEN X_PAM_GL_GRP = '' 	AND CURRENCY = 'USD'  THEN -1*MKT_VALUE_DIV_1000 
			ELSE 0 
		  END AS CCY_RSK_EXP

		  	/* find out the assets in currency risk exposure for USD */
		  , CASE 
				WHEN CALCULATED CCY_RSK_EXP = 0 THEN 0 
				ELSE 1 
			END AS CCY_RSK

			/*Find out the asset is used for Spread_Risk for Structured assets */
 		  /*************************************************************/
		  /********************* SPREAD  RISK ***********************/
		  /***********************************************************/

		  , CASE 
				WHEN SUBSTR(CIC,3,1) IN ('5','6') THEN 1 
				ELSE 0 
			END AS SPRD_RSK_STRUC 

/*******************************************************************CALCULATED MEASURES REQUIRED FOR SPRD_RSK_BND START*************************************************/

		  , CASE

				/* --1) CIC code 11 or 15 with Issuer Country being an EU member, and the currency of the bond being the same as the country of address for the 
			  	issuer eg UK Government issuer with a GBP bond would get caught.  A Kingdom of Belgium CIC 11 bond issued in GBP would not,
		  		nor would a US Govt Bond issued in USD as it is not an EU country. */
				WHEN SUBSTR(CIC,3,2)  IN ('11','15') AND X_EEA_MEMBER_FLAG = 'Y' AND (SUBSTR(COUNTRY,1,2) = SUBSTR(CURRENCY,1,2) OR CURRENCY = 'EUR' )
					THEN 1 
				
				/*-- all CIC 19's and Barclays four pillar sub industry = Govt Guaranteed and country = EEA then Zero rated bond*/
				WHEN SUBSTR(CIC,3,2) IN ('13') AND BARCLAYS_FOUR_PILLAR_SUBINDUSTRY = 'Government Guaranteed' AND X_EEA_MEMBER_FLAG = 'Y' 
					THEN 1		 					

				/*-- 2) Supranationals CIC code 12 - there is a list of qualifying supranationals that are determined by the name of the issuer.  
				Because the way supranationals are named by Blackrock in the analytics file might not be exactly the same as the list provided by EIOPA,
				a manual process is required.  You need to have two tables, one for qualifying names (per Blackrock's name) and one for none-qualifying names.  
				As of 30 June all supranationals held were qualifying, so the issuer name can be taken for these and added to the qualifying table.  
				Any new issuers that come through as CIC 12 should be flagged to Eugene so he can advise if they 
				should be added to the qualifying or non-qualifying table.*/
				/* 'EUROPEAN BANK FOR RECONSTRUCTION AND DEVELOPMENT' NEED TO ADD THIS AFTER Q4-2021 */
				WHEN  SUBSTR(CIC,3,2)  IN ('12')  AND TRIM(UPCASE(ULT_ISSUER_NAME)) IN ('NORDIC INVESTMENT BANK'
																						, 'COUNCIL OF EUROPE DEVELOPMENT BANK'
																						, 'EUROPEAN INVESTMENT BANK'
																						, 'INTER-AMERICAN DEVELOPMENT BANK'
																						, 'INTERNATIONAL BANK FOR RECONSTRUCTION AND DEVELOPMENT'																					
																						, 'EUROPEAN INVESTMENT BANK'
																						, 'WORLD BANK GROUP/THE'
																						, 'AFRICAN DEVELOPMENT BANK')
					THEN 1
						 		
				/*-- all CIC 19's and Barclays four pillar sub industry = Govt Guaranteed and country = EEA then Zero rated bond*/
				WHEN SUBSTR(CIC,3,2) IN ('19') AND BARCLAYS_FOUR_PILLAR_SUBINDUSTRY = 'Government Guaranteed' AND X_EEA_MEMBER_FLAG = 'Y' 
					THEN 1			 		
						 		
				/*-- all CIC 21's and Barclays four pillar sub industry = Govt Guaranteed and country = EEA then Zero rated bond*/
				WHEN SUBSTR(CIC,3,2) IN ('21') AND BARCLAYS_FOUR_PILLAR_SUBINDUSTRY = 'Government Guaranteed' AND X_EEA_MEMBER_FLAG = 'Y' 
					THEN 1
					 				 
				/*-- 3) CIC code 13 and 14 - these positions could be identified and individually mapped as qualifying or non qualifying, 
				but you have to determine whether the issuer has revenue raising powers.  
				This would require using bloomberg or other resources to manually research the issuer. 
				There is currently no way of identifying these via existing fields in SDW.*/
				ELSE 0 

			  END AS ZERO_RATED

			, CASE 
				/*-- ALL CIC 26 and 27 issued in the EEA and the ultimate issuer has revenue raising powers are covered bonds */
				WHEN SUBSTR(CIC,3,2)  IN ('26','27')  AND X_EEA_MEMBER_FLAG = 'Y' AND ( ULT_ISSUER_NAME IN  
																							    ( 'BANCO SANTANDER SA'
																							    , 'BARCLAYS PLC'
																							    , 'LLOYDS BANKING GROUP PLC'
																							    , 'YORKSHIRE BUILDING SOCIETY'
																							    , 'DEUTSCHE PFANDBRIEFBANK AG'
																								, 'CYBG PLC' ) 	
	
																				  OR NACE IN ('K6419' ,'K6411') )
					THEN 1 
						
				ELSE 0 
			  END AS NON_ZERO_RATED_COV		

			, CASE 
				WHEN (X_EEA_MEMBER_FLAG = 'Y' AND X_OECD_MEMBER_FLAG = 'Y') THEN 'EEA'
				WHEN (X_EEA_MEMBER_FLAG = 'Y' AND X_OECD_MEMBER_FLAG = 'N') THEN 'EEA'
				WHEN (X_EEA_MEMBER_FLAG = 'N' AND X_OECD_MEMBER_FLAG = 'Y') THEN 'OECD'
				WHEN (X_EEA_MEMBER_FLAG = 'N' AND X_OECD_MEMBER_FLAG = 'N') THEN '3RD'
			  END AS CNTRY_TYP

			, CASE 
				WHEN SUBSTR(CIC,3,1) IN ('1','2','5','6') 
					/*
					 AND NACE IN  ('C3099','C3317','D3511','D3512','D3513','D3522','E3600','E3700','E3821','E3822','F4120','F4211','F4212','F4213','F4221','F4222',
									  'F4299','H4910','H4920','H4931','H4932','H4939','H4941','H4942','H4950','H5010','H5020','H5030','H5040','H5110','H5121','H5122',
			                          'H5221','H5222','H5223','H5229','H5310','H5320','N7734','N7735') 
					*/
					AND CM_NACE.INFRA_CORP_FLAG = 'YES'
					
				  THEN 
				 		CASE  
							WHEN PUT(WTFL_SII_CREDIT_QLTY_VAL,1.) IN ('0', '1', '2', '3', '9' , '') AND CALCULATED CNTRY_TYP IN ('EEA','OECD') 
								    AND X_STRUCTURE  NOT LIKE '%NQ - O%'
							  	THEN 1
							WHEN PUT(WTFL_SII_CREDIT_QLTY_VAL,1.) IN ('0', '1', '2', '3', '9' , '') AND CALCULATED CNTRY_TYP IN ('3RD')
									OR X_STRUCTURE  LIKE '%NQ - O%' 
								THEN 0
							/* Changed after Q4-2020 recs - start */
							WHEN PUT(WTFL_SII_CREDIT_QLTY_VAL,1.) IN  ('4', '5', '6' ) AND X_STRUCTURE  LIKE '%NQ - O%'
							/* 4 , 5, 6 -  S2 cred qual value  is always non qual but still check for business overides */
								THEN 0
							WHEN PUT(WTFL_SII_CREDIT_QLTY_VAL,1.) IN  ('4', '5', '6' ) AND X_STRUCTURE  LIKE '%SENIOR_O%'
							/*Business Overide takes priority even though rules set this to Non Qual*/
								THEN 1
							/* Changed after Q4-2020 recs - end */
							WHEN PUT(WTFL_SII_CREDIT_QLTY_VAL,1.) IN  ('4', '5', '6' ) 
							/* 4 , 5, 6 -  S2 cred qual value is always non qual when no business overides prevail*/
								THEN 0
						END				
				ELSE -1
			  END AS INFRA_CORP
 
			, CASE
				/* -- New Category for Rogier
				--1) CIC code 11 or 15 with Issuer Country being NON EU member, and the currency of the bond being the same as the country of address for the issuer */
				WHEN SUBSTR(CIC,3,2)  IN ('11','15') AND X_EEA_MEMBER_FLAG <> 'Y' AND SUBSTR(COUNTRY,1,2) = SUBSTR(CURRENCY,1,2) AND CALCULATED ZERO_RATED = 0  
					THEN 1 
				ELSE 0
			  END AS CIC_11_15_NON_EU_CUR_MTCH

			, CASE

				/*--3) Bonds with a government guarantee (excluding CIC codes beginning with 5 or 6)- 
				these are identifiable via the Barclays four pillar subindustry = "Government Guaranteed".  
				The government providing the guarantee has to be either a qualifying supranational per point 2 in part 1 above, or an EU member per 
				part 1 above (currency is not a factor).  While it is possible to identify bonds with a government guarantee via SDW, it is not possible to 
				determine in all instances which government is providing the guarantee.  Bloomberg could be used to identify this.  
				There are also specific requirements around the type of guarantee that is attached to the bond per Article 215 of the regulation.  
				Bloomberg or other resources would need to be used to research if these qualify.*/

				WHEN (BARCLAYS_FOUR_PILLAR_SUBINDUSTRY = 'Government Guaranteed' AND SUBSTR(CIC,3,1)  NOT IN ('5','6') 
						 AND (X_EEA_MEMBER_FLAG = 'Y' 
													 OR ULT_ISSUER_NAME IN ('NORDIC INVESTMENT BANK'
																			 ,'COUNCIL OF EUROPE DEVELOPMENT BANK'
																			 ,'EUROPEAN INVESTMENT BANK'
																			 ,'INTER-AMERICAN DEVELOPMENT BANK'
																			 ,'INTERNATIONAL BANK FOR RECONSTRUCTION AND DEVELOPMENT'
				                                                             ,'EUROPEAN INVESTMENT BANK','World Bank Group/The'))      
													AND CALCULATED ZERO_RATED = 0)
					THEN 1


				WHEN ( SUBSTR(CIC,3,1) IN ('8') AND CALCULATED ZERO_RATED = 0 AND I_T_CLS_GRP NOT IN  ( 'Interco Loans' , 'Infrastructure Loan') 
					 	AND  CUSIP NOT LIKE 'INTERCO%' )
					THEN 1

				/*-- 23 AND 24 cic CODES ARE THE SPLIT OF THE 100% PCT PWNED FUNDS --  Confirmation from Carl - 
				These would be Non Zero Rated as they are not covered nor are they guaranteed by an EEA government. */
				WHEN ( SUBSTR(CIC,3,2)  IN ('11','14','13','19','21','23','24','25','28','29') AND BARCLAYS_FOUR_PILLAR_SUBINDUSTRY <> 'Government Guaranteed' 
						 AND  CALCULATED ZERO_RATED = 0 AND CALCULATED CIC_11_15_NON_EU_CUR_MTCH =0 AND ( CALCULATED INFRA_CORP = 0  OR CALCULATED INFRA_CORP = -1) )  
					THEN 1

				/*-- ALL CIC 26 and 27  and the ultimate issuer has no revenue raising powers are covered bonds */
				WHEN SUBSTR(CIC,3,2)  IN ('26','27')  AND CALCULATED NON_ZERO_RATED_COV = 0  
					THEN 1 

				WHEN DATA_SOURCE = '03 - Lookthrough' AND SM_SEC_GROUP <> 'CASH' AND CALCULATED ZERO_RATED = 0 AND CALCULATED NON_ZERO_RATED_COV = 0  
						AND SUBSTR(CIC,3,1) NOT IN ('6','7','A')  
					THEN 1 /*Changed 22/01/2016*/

				ELSE 0

			  END AS NON_ZERO_RATED_NOT_COV
/*******************************************************************CALCULATED MEASURES REQUIRED FOR SPRD_RSK_BND END*************************************************/

			  /* TO Run SPRD_RSK_BND we need derived 
					a) NON_ZERO_RATED_NOT_COV 						
						i)  CIC_11_15_NON_EU_CUR_MTCH - DONE
			  			ii) INFRA_CORP - done
			  				a)CNTRY_TYP - done
			  			iii) ZERO_RATED - done 

					b) NON_ZERO_RATED_COV - done
										
					c) ZERO_RATED - done*/ 
		  , CASE 
		  		WHEN I_T_CLS_GRP = 'Interco Loans'  OR CUSIP LIKE '%INTERCO1%' 
					THEN 0 
				WHEN (CALCULATED NON_ZERO_RATED_NOT_COV = 1 OR CALCULATED NON_ZERO_RATED_COV = 1) AND CALCULATED SPRD_RSK_STRUC <> 1
					THEN 1 
				WHEN CALCULATED CIC_11_15_NON_EU_CUR_MTCH = 1 
					THEN 1 
				WHEN DATA_SOURCE = '03 - Lookthrough' AND SM_SEC_GROUP = 'BND' AND CALCULATED ZERO_RATED = 0
					THEN 1 
					/*following code introduced to deviate from orignal spread risk SQL for unified Base creation*/
				 WHEN CALCULATED INFRA_CORP = 1 /*Take Corporate Infrastructure*/ 
					THEN 1
				ELSE 0 
			END AS SPRD_RSK_BND /* keep in line with spread risk bonds  - includes Covered , Not Covered , CIC 11 15's , STRUC CREDIT'S , Infra corps */

			/*--Sense check , Same asset should not be in a SPRD_RSK_BND and SPRD_RSK_STRUC*/
		  , CASE 
				WHEN (CALCULATED SPRD_RSK_BND + CALCULATED SPRD_RSK_STRUC) <=1 THEN 'TRUE'
				ELSE 'FALSE' 
			END AS SENSE_CHECK_SPRD_RSK

			/*-- Find out whether the asset is a spread risk*/
		  , CASE 
				WHEN CALCULATED SPRD_RSK_BND = 1 OR CALCULATED SPRD_RSK_STRUC = 1 OR CALCULATED INFRASTRUCTURE_INV_CD_TYPE <> '' 
				/*Include bonds (Including Corporate bonds) + Securitizations + Physical infrastructure*/
					THEN 1 
				ELSE 0 
			END AS SPRD_RSK
			/* keep in line with spread risk  - includes Covered , Not Covered , CIC 11 15's , Securitizations , Infra corps and physical Infra*/

			/*-- Find out the type of bond - used for spread risk */
		  , CASE 
				WHEN BARCLAYS_FOUR_PILLAR_SUBSECTOR = 'Covered' THEN 'Type 1' 
			 	WHEN SM_SEC_GROUP = 'BND' AND SM_SEC_TYPE = 'GOVT' AND X_EEA_MEMBER_FLAG <> 'Y' THEN 'Type 2'
			 	ELSE 'No' 
			 END AS BOND_TYPE

		   /*-- check whether the instrument is a Bond*/
		 , CASE 
				WHEN SM_SEC_GROUP = 'BND' THEN 1
				ELSE 0 
		   END AS IS_BND

		   /*-- Check whether the bond is issued by the Govt*/
		 , CASE
				WHEN SM_SEC_GROUP = 'BND' AND SM_SEC_TYPE = 'GOVT' THEN 1 
				ELSE 0 
			END AS IS_GOVT
		
		  /*-- Check EEA countries*/		
		 , CASE
				WHEN X_EEA_MEMBER_FLAG = 'Y' THEN 1 
				ELSE 0 
			END AS IS_EEA  

		 /*-- Check whether the Bond is issued by Govt from EEA countries*/
		,  CASE 
				WHEN CALCULATED IS_GOVT = 1 AND CALCULATED IS_EEA = 1 
					THEN 1 
				ELSE 0 
			END AS IS_EEA_GOVT 

		/*-- Check whether the Bond is Guaranteed by the EEA*/
		, CASE 
				WHEN CALCULATED IS_BND = 1 AND BARCLAYS_FOUR_PILLAR_INDUSTRY = 'Government Guaranteed' AND CALCULATED IS_EEA = 1 
					THEN 1 
				ELSE 0 
		  END AS IS_GUARN_EEA_GOVT

		/*-- Find out whether the bond is a supranational or not */
		/*--MULTILATERAL DEV BANK / APPROVED INTERNATIONAL ORGANISATION */
		, CASE 
				WHEN CALCULATED IS_BND = 1 AND BARCLAYS_FOUR_PILLAR_SUBSECTOR = 'Supranational' 
					THEN 1 
				ELSE 0
		  END AS IS_SUPRA_BNDS 

		/*--Sense check for Spread risk bonds  - Same bond should not be a EEA issued and EEA Guaranteed and Supra */
		, CASE 
				WHEN (CALCULATED IS_EEA_GOVT + CALCULATED IS_GUARN_EEA_GOVT + CALCULATED IS_SUPRA_BNDS) <=1 
					THEN 'TRUE' 
				ELSE 'FALSE' 
		  END AS SENSE_CHECK_BNDS 

		/*--Exempt from Spread Risk? 
		--(Y = EXCLUDE) EXEMPT FROM SPREAD RISK
		--(N = INCLUDE) INCLUDE IN SPREAD RISK*/
		, CASE 
				WHEN CALCULATED ZERO_RATED = 1 
					THEN 'Y' 
				ELSE 
					CASE 
						WHEN CALCULATED NON_ZERO_RATED_NOT_COV = 1 OR CALCULATED NON_ZERO_RATED_COV = 1 
							 OR CALCULATED SPRD_RSK_STRUC = 1 OR CALCULATED CIC_11_15_NON_EU_CUR_MTCH = 1 
							 OR CALCULATED INFRA_CORP = 1 OR CALCULATED INFRASTRUCTURE_INV_CD_TYPE <> '' 
							THEN 'N' 
						ELSE 'Y'  
					END 
			END AS EXEMPT_SPREAD_RISK

		/*-- For Conc Risk if Ult_parent_ticker is not available then use the Ticker*/
		, CASE 
				WHEN ULTIMATE_PARENT_TICKER = '0' OR ULTIMATE_PARENT_TICKER IS NULL OR ULTIMATE_PARENT_TICKER = '' 
					THEN TICKER 
				ELSE ULTIMATE_PARENT_TICKER 
		   END AS REAL_TICKER_CONC_RSK

		  /*--Find out the exemption for Conc risk 0 = Exempt*/
		, CASE 
				WHEN (CALCULATED IS_EEA_GOVT = 1 OR CALCULATED IS_GUARN_EEA_GOVT = 1 
						OR CALCULATED IS_SUPRA_BNDS = 1) AND CALCULATED NON_ZERO_RATED_NOT_COV <> 1
					THEN 0 
				ELSE 1 
		  END AS EXEMPT_CONC_RISK 

		/*, CASE --Seems to be a old case--
			WHEN  CALCULATED ZERO_RATED = 1 THEN  'EXCLUDE' 
			WHEN PORTF_LIST = 'A_320UKIDE' AND SUBSTR(CIC,3,1) NOT IN ('1','2','5','6','9')  THEN  'EXCLUDE' 
			WHEN I_T_CLS_CAT = 'Exclude'  THEN  'EXCLUDE' 
			WHEN DATA_SOURCE = '03 - Lookthrough' AND SUBSTR(CIC,3,1) IN ('4') AND SM_SEC_GROUP = 'BND' AND CALCULATED ZERO_RATED= 1 THEN 'EXCLUDE' 
			WHEN DATA_SOURCE = '03 - Lookthrough' AND SM_SEC_GROUP = 'CASH' AND SUBSTR(CIC,3,1) NOT IN ('2')  THEN  'EXCLUDE' 
			WHEN SUBSTR(CIC,3,1) NOT IN ('1','2','5','6','9')  AND DATA_SOURCE <> '03 - Lookthrough'	THEN 'EXCLUDE' 
			ELSE 'INCLUDE' 
		  END AS EXEMPT_CONC_RISK	*/

		/*--Find out whether the asset is non EEA but Govt issued , For Conc and Spread Risk*/
		, CASE 
				WHEN CALCULATED IS_GOVT = 1 AND CALCULATED IS_EEA = 0 
					THEN 1 
				ELSE 0 
		  END AS NON_EEA_GOVT 

		/*--Assign scope for Concentration Risk*/
		/* Dont Use this is old 
		, CASE 
				WHEN SM_SEC_TYPE IN ('CORP','ABS','GOVT','LOCAL','SENIOR','MUNITAX','REIT','CLOSED_END','TERM','EQUITY') 
					THEN 1 
				ELSE 0 
		  END AS CONC_RSK */

		/*, CASE DON't use this too old
			WHEN SUBSTR(CIC,3,1) IN ('1','2','5','6','9') AND PUT(CALCULATED ZERO_RATED,1.) = '0'  AND I_T_CLS_CAT <> 'Exclude'  THEN 1 
			 WHEN DATA_SOURCE = '03 - Lookthrough' AND SUBSTR(CIC,3,1) IN ('4') AND SM_SEC_GROUP = 'BND' AND PUT(CALCULATED ZERO_RATED,1.) = '0' THEN 1
			 ELSE 0 
		  END AS CONC_RSK */

		, CASE 
			WHEN SUBSTR(CIC,3,1) NOT IN ('7','3','A','B','C','D','E','F') AND CUSIP NOT LIKE '%INTERCO%'  
				THEN 1
			ELSE 0 
		  END AS CONC_RSK

		/* -- For Concentration Risk Type 0*/
		, CASE 
				WHEN CALCULATED EXEMPT_CONC_RISK = 0  
					THEN 1 
				ELSE 0 
		  END AS TYP_0

		/*-- For Concentration Risk Type 2*/
		, CASE 				
				WHEN CALCULATED CIC_11_15_NON_EU_CUR_MTCH = 1  THEN 1
				ELSE 0 
		  END AS TYP_2 

		/*-- For Concentration Risk Type 3*/
		, CASE 
				WHEN CALCULATED NON_ZERO_RATED_COV = 1 
					THEN 1 
				ELSE 0 
		  END AS TYP_3 

		/*-- For Concentration Risk Type 4*/
		, CASE 
				WHEN SM_SEC_TYPE = 'REIT' 
					THEN 1 
				ELSE 0 
		  END AS TYP_4 

		/*-- For Concentration Risk Type 5*/
		, CASE 
			WHEN ( (LEHM_RATING_TXT = '' OR LEHM_RATING_TXT = '0' OR LEHM_RATING_TXT IS NULL) AND CALCULATED CONC_RSK = 0 AND CALCULATED TYP_4 <> 0 ) 
				THEN 1 
			WHEN PORTF_LIST = 'A_320QUKIM' AND X_PAM_GL_GRP NOT IN ('CASHBAL') THEN 1
			WHEN X_PAM_GL_GRP IN ('TERM NOTES','CRE') AND CUSIP NOT LIKE '%INTERCO%' THEN 1
			ELSE 0 
		  END AS TYP_5

		/* -- For Concentration Risk Type 1 -We required all TYP identfiers*/
		, CASE 
			WHEN CALCULATED CONC_RSK = 1 
					AND CALCULATED TYP_0 = 0  AND CALCULATED TYP_2 = 0 AND CALCULATED TYP_3 = 0 AND CALCULATED TYP_4 = 0 AND CALCULATED TYP_5 = 0 
					AND CUSIP NOT LIKE '%INTERCO%'
				THEN 1 
			ELSE 0 
		  END AS TYP_1

		/*--FOR CONC RISK CHECK DUPLICATES*/
		, CASE 
			WHEN (CALCULATED TYP_0 + CALCULATED TYP_1 + CALCULATED TYP_2 + CALCULATED TYP_3 + CALCULATED TYP_4 + CALCULATED TYP_5) >= 2 
				THEN 1 
			ELSE 0 END AS CHCK_CONC_2_TYP			

		/*--FOR CONC RISK CHECK IF NO TYPES ARE AVAILABLE*/
		, CASE 
			WHEN (CALCULATED TYP_0 + CALCULATED TYP_1 + CALCULATED TYP_2 + CALCULATED TYP_3 + CALCULATED TYP_4 + CALCULATED TYP_5) = 0 
				THEN 1 
			ELSE 0 
		  END AS CHCK_NO_TYP

		/*-- To Populate the exposure type for Conc Risk*/
		, CASE 
			WHEN CALCULATED TYP_0 = 1 OR CALCULATED ZERO_RATED = 1 	THEN 'Type 0'
			WHEN CALCULATED TYP_1 = 1 								THEN 'Type 1'
			WHEN CALCULATED TYP_2 = 1 								THEN 'Type 2'
			WHEN CALCULATED TYP_3 = 1 								THEN 'Type 3'
			WHEN CALCULATED TYP_4 = 1 								THEN 'Type 4'
			WHEN CALCULATED TYP_5 = 1 								THEN 'Type 5'
			ELSE 'Not in Scope'
		  END AS EXP_TYP	

		/*--Check Defaulted Risk.. Check whether the instrument has been used for any risk calculation */
		, CASE 
			WHEN 
				CALCULATED INT_RT_RSK = 0 
				AND CALCULATED INT_RT_DRVTS_RSK = 0 
				AND CALCULATED EQTY_RSK = 0 
				AND CALCULATED PRPTY_RSK = 0 
				AND CALCULATED CCY_RSK = 0 
				AND CALCULATED SPRD_RSK_BND = 0  
				AND CALCULATED SPRD_RSK_STRUC = 0 
				AND CALCULATED CONC_RSK = 0  
					THEN 'Not a part of Risk Calculation' 
			ELSE 
				'Included in atleast one of the Risk Calculation' 
		  END AS DEFAULT_RSK

		, CASE 
			WHEN SM_SEC_TYPE = 'GOVT' THEN 30 
			ELSE LEHM_DERIV.ASSESSMENT_SCORE_NO 
		  END AS LEHM_SCORE

		, CASE 
			WHEN ( CALCULATED CIC_11_15_NON_EU_CUR_MTCH 
					+ CALCULATED NON_ZERO_RATED_COV
					+ CALCULATED NON_ZERO_RATED_NOT_COV
					+ CALCULATED ZERO_RATED ) > 1  
					AND SUBSTR(CIC,3,1) IN ('1','2') 
				THEN 'Duplicate Bond Classification' 
			ELSE '' 
		  END AS SENSE_CHK_CIC_BND_CLASS

		, CASE 
			WHEN ( CALCULATED CIC_11_15_NON_EU_CUR_MTCH
					+ CALCULATED NON_ZERO_RATED_COV
					+ CALCULATED NON_ZERO_RATED_NOT_COV
					+ CALCULATED ZERO_RATED
				   ) = 0 
				AND SUBSTR(CIC,3,1) IN ('1','2')  
				THEN 'Bond Not Classified' 
			ELSE '' 
		  END AS SENSE_CHK_CIC_BND_NT_CLASS

		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('5','6') 
				 AND SUBSTR(CIC,1,2)  IN  ('AT','AU','BE','CA','CH','CL','CZ','DE','DK','EE','ES','FI','FR','GB','GR','HU','IE','IL','IS','IT','JP','KP','LU','MX','NL',
											'NO','NZ','PL','PT','SE','SI','SK','TR','US') 
				THEN 1 
			ELSE 0 
		  END AS SEC_CREDIT_TYP1

		, CASE 
			WHEN SUBSTR(CIC,3,1) IN ('5','6') 
				 AND SUBSTR(CIC,1,2)  NOT IN  ('AT','AU','BE','CA','CH','CL','CZ','DE','DK','EE','ES','FI','FR','GB','GR','HU','IE','IL','IS','IT','JP','KP','LU','MX','NL',
											'NO','NZ','PL','PT','SE','SI','SK','TR','US')  
				THEN 1 
			ELSE 0 
		  END AS SEC_CREDIT_TYP2

		, CASE 
			WHEN ( CALCULATED SEC_CREDIT_TYP1 + CALCULATED SEC_CREDIT_TYP2 ) > 1  AND SUBSTR(CIC,3,1) IN ('5','6') 
				THEN 'Duplicate Sec Credit Classification' 
			ELSE '' 
		  END AS SENSE_CHECK_CIC_SEC_CRED

		, CASE 
			WHEN ( CALCULATED SEC_CREDIT_TYP1 + CALCULATED SEC_CREDIT_TYP2 ) = 0 AND SUBSTR(CIC,3,1) IN ('5','6') 
				THEN 'Sec Credit Not Classified' 
			ELSE '' 
		  END AS SENSE_CHECK_CIC_SEC_CRED_NC

		, CASE 
			WHEN SUBSTR(CIC,3,2) NOT IN ('93','95','96') AND SUBSTR(CIC,3,1) = '9'   THEN 1 
			ELSE 0 
		  END AS INVESTMENT_PROP			 		

		, CASE 
			WHEN SUBSTR(CIC,3,2) IN ('93','95','96') THEN 1 
			ELSE 0 
		  END AS OWNER_OCC_PROP

		, CASE 
			WHEN SUBSTR(CIC,3,1)  IN ('7') AND UPCASE(I_T_CLS_GRP) <> 'EXCLUDE'  THEN 1 
			WHEN DATA_SOURCE = '03 - Lookthrough' AND SM_SEC_GROUP = 'CASH' AND SUBSTR(CIC,3,2) NOT IN ('23','24','E2') THEN 1 /* --22/01/2016 - Changed*/
			ELSE 0 
		  END AS CASH		 		

		, CASE 
			WHEN SUBSTR(CIC,3,1)  IN ('3')  AND UPCASE(I_T_CLS_GRP) <> 'EXCLUDE' AND ( CUSIP LIKE 'FLOOW%' OR CUSIP LIKE 'DLIS_EQ%' ) THEN 1 
			WHEN SUBSTR(CIC,3,1)  IN ('A','E','D')  AND UPCASE(I_T_CLS_GRP) <> 'EXCLUDE' THEN 1
			WHEN ( UPCASE(I_T_CLS_GRP) = 'INTERCO LOANS' OR CUSIP LIKE 'INTERCO%' ) THEN 0
			ELSE 0 
		  END AS OTHER

		, CASE 
			WHEN SUBSTR(CIC,3,1)  IN ('3')  AND UPCASE(I_T_CLS_GRP) <> 'EXCLUDE' AND ( CUSIP LIKE 'FLOOW%' OR CUSIP LIKE '%PART%'  OR CUSIP LIKE 'DLIS_EQ%' ) THEN 1 
			WHEN SUBSTR(CIC,3,1)  IN ('A','E','D')  AND UPCASE(I_T_CLS_GRP) <> 'EXCLUDE' THEN 1
			WHEN ( UPCASE(I_T_CLS_GRP) = 'INTERCO LOANS' OR CUSIP LIKE 'INTERCO%' ) THEN 0
			ELSE 0 
		  END AS OTHER_SOLO

		, CASE 
			WHEN DATA_SOURCE = '03 - Lookthrough'  AND UPCASE(I_T_CLS_GRP) <> 'EXCLUDE' THEN 1 
			ELSE 0 
		  END AS LOOKTHRU

		, SUBSTR(CIC,3,2) AS CIC_3_4_DIGIT

		, CASE 	
			WHEN X_SECURITISED_CREDIT_TYPE IN ('TYPE 1','Tier 1','Tiera')  AND  ( MDY_SCORE = . AND  SP_SCORE  = . AND  FIT_SCORE <> . ) THEN 'TYPE 2'
			WHEN X_SECURITISED_CREDIT_TYPE IN ('TYPE 1','Tier 1','Tiera')  AND  ( MDY_SCORE = . AND  FIT_SCORE = . AND  SP_SCORE  <> . ) THEN 'TYPE 2'
			WHEN X_SECURITISED_CREDIT_TYPE IN ('TYPE 1','Tier 1','Tiera')  AND  ( SP_SCORE 	= . AND  FIT_SCORE = . AND  MDY_SCORE <> . ) THEN 'TYPE 2'		
			ELSE X_SECURITISED_CREDIT_TYPE	
		  END AS X_SECURITISED_CREDIT_TYPE

		, CASE 
			WHEN INFRASTRUCTURE_INV_CD IN ('12','13','14','19') THEN 'TYPE 1'
			WHEN INFRASTRUCTURE_INV_CD IN ('2','3','4','9') 	THEN 'TYPE 2'
			ELSE ''
		  END AS INFRASTRUCTURE_INV_CD_TYPE

		  /*-- ALL CIC 26 and 27 issued in the EEA and the ultimate issuer has revenue raising powers are covered bonds */
		, CASE 
			WHEN 
				SUBSTR(CIC,3,2)  IN ('26','27')  
				AND X_EEA_MEMBER_FLAG = 'Y' 
				AND ULT_ISSUER_NAME IN  ('BANCO SANTANDER SA','BARCLAYS PLC','LLOYDS BANKING GROUP PLC','YORKSHIRE BUILDING SOCIETY') 
					THEN 1 
			ELSE 0 
		  END AS IS_COV_BOND

	FROM 
		WORK.SF_BASE_APPEND

	LEFT JOIN 
 			(SELECT 
				DISTINCT 
					ASSESSMENT_AGENCY_CD,
					ASSESSMENT_GRADE,
					ASSESSMENT_SCORE_NO,
					X_SOLII_CREDIT_QUALITY_VAL
				FROM 
					test.ASSESSMENT_RATING_GRADE 
				WHERE 
					ASSESSMENT_AGENCY_CD = 'S_P' 
					AND SHORTTERM_FLG = '0'
					AND PUT(DATEPART(VALID_TO_DTTM),DATE9.) = '31DEC4747'	
					AND ASSESSMENT_GRADE NOT IN ('Govt','Govt Equiv','Agency')
					AND MODEL_RK = 1
					/*AND ASSESSMENT_GRADE NOT IN ('SD','SD**')*/
			) LEHM_DERIV
		ON SF_BASE_APPEND.LEHM_RATING_TXT = LEHM_DERIV.ASSESSMENT_GRADE	


	LEFT JOIN 
		(
		 SELECT 
			DISTINCT 
				NACE_CD 
				, INFRA_CORP_FLAG 
		 FROM	
			test_mar.CM_NACE_CD_VALID_LIST        
	     WHERE  
					PUT(DATEPART(VALID_TO_TS),DATE9.) = '31DEC9999'
		)CM_NACE
			ON SF_BASE_APPEND.NACE = CM_NACE.NACE_CD
			
	ORDER BY 
		DATA_SOURCE
		, SUBSTR(CIC,3,2)
		, CUSIP
	;	
QUIT;