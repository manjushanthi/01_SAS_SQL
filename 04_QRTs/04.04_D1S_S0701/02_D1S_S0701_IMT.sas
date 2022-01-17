
/* consider S0701_D1S_IMT and PIVOT alone */

PROC SQL ;

OPTIONS MISSING='';

/*Create Temp table to load the extracted Data*/

	CREATE TABLE WORK.S0701_D1S_IMT AS 

		SELECT 

			A4 AS C0040

			, CASE 
				WHEN A5 = 'ISIN' THEN '1 - ISO/6166 for ISIN' 
				ELSE A5 
			  END AS C0050

			, CASE
				WHEN SUBSTR(A15,3,1) = '5' THEN '5 - Structured notes' 
				ELSE '6 - Collateralised Securities' 
			  END AS C0060

			, CASE 
				 WHEN C0070 = '3' THEN  '3 - Asset backed securities'
	 			 WHEN C0070 = '4' THEN '4 - Mortgage backed securities'
	 			 WHEN C0070 = '5' THEN '5 - Commercial mortgage backed securities'
	 			 WHEN C0070 = '6' THEN '6 - Collateralised debt obligations'
	 			 WHEN C0070 = '7' THEN '7 - Collateralised loan obligations'
	 			 WHEN C0070 = '8' THEN '8 - Collateralised mortgage obligations'
	 			 WHEN C0070 = '9' THEN '9 - Interest rate-linked notes and deposits'
	 			 WHEN C0070 = '10' THEN '10 - Equity-linked and Equity Index Linked notes and deposits'
	 			 WHEN C0070 = '99' THEN '99 - Others not covered by the previous options'
			     ELSE C0070
			  END AS C0070

			, CASE
				WHEN C0080 = '1' THEN '1 - Full capital protection'
				WHEN C0080 = '3' THEN '3 - No Capital Protection'			 
				ELSE C0080
			  END AS C0080

			, CASE 
				WHEN C0090 = '6' THEN '6 - Multi'
				WHEN C0090 = '9' THEN '9 - Others not covered by the previous options'
				ELSE C0090
			  END AS C0090

			, CASE 
				WHEN C0100 = '1' THEN '1 - Call by the buyer'
				WHEN C0100 = '2' THEN '2 - Call by the seller'
				ELSE C0100
			  END AS C0100
			  
			, CASE 
				WHEN C0110 = '2' THEN '2 - Structured product with transfer of asset'
				ELSE C0110
			  END AS C0110

			, CASE
				WHEN C0120 = '1' THEN '1 - Prepayment structured product'
				WHEN C0120 = '2' THEN '2 - Not a prepayment structured product'
				ELSE C0120
			  END AS C0120

		 	, COALESCE(PUT(C0130,21.2),'-') AS C0130

			, CASE 	
				WHEN C0140 = '1'  THEN '1 - Collateral calculated on the basis of net positions resulting from a set of contracts'
              	WHEN C0140 = '2'  THEN '2 - Collateral calculated on the basis of a single contract'
				WHEN C0140 = '10' THEN '10 – No collateral'
				ELSE C0140
			  END AS C0140

			, CASE 
				WHEN BRS_CPN = 'FIXED' THEN PUT(C0150,21.2)
				ELSE '-'
			   END AS C0150

			, CASE 
				WHEN BRS_CPN <> 'FIXED' THEN C0160 
				ELSE '-'
			  END AS C0160

			, COALESCE(PUT(C0170,10.5),'-') AS C0170

			, COALESCE(PUT(C0180,10.5),'-') AS C0180

			, COALESCE(PUT(C0190,10.5),'-') AS C0190
   
   			/* GROUP REPORTING COLUMNS */

			, 'Direct Line Insurance Group plc'  AS GRP_NM

			, '213800FF2R23ALJQOP04' AS GRP_LEI

			, '1 - LEI' AS GRP_LEI_CD

			/* INTERNAL COLUMNS */ 

			, INT1

			, A50

			, INT1A

			, BRS_CPN

			, SM_SEC_GROUP

			, SM_SEC_TYPE

			, COALESCE(INT3 , '-') AS INT3

			, A15

			, COALESCE(INT2 , '-') AS INT2

			, SUBSTR(A15,3,2) AS CIC_3_2

			, FIN_SOLII_CLS 

			, INT2A

			, INT2B

			, INT4

			, INT5

			, INT6

			, A26BRS FORMAT = 21.2

			, A26PAM FORMAT = 21.2

			, A26FIN_SDW FORMAT = 21.2

			, INT9 

			, INT10 

			, SOURCE_SYSTEM_CD
	
		FROM 
			WORK.S0701_D1S_BASE

		ORDER BY 
			C0040;
QUIT;

PROC SUMMARY DATA=WORK.S0701_D1S_IMT;
VAR A26FIN_SDW ;
CLASS INT5 FIN_SOLII_CLS INT2 ;
OUTPUT OUT=WORK.S0701_D1S_IMT_SUM SUM= ;
RUN;

DATA S0701_D1S_IMT_PIVOT;
SET WORK.S0701_D1S_IMT_SUM;
DROP _TYPE_ ; 
RENAME INT5=Oracle_GL_Group FIN_SOLII_CLS=Oracle_GL_Category INT2=CIC_Position_3 _FREQ_=COUNT A26FIN_SDW=SOLII_VALUE;
WHERE _TYPE_ = 7;
FORMAT A26FIN_SDW COMMA21.2;
RUN;