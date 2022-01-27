
PROC SQL ;

/*Create Temp table to load the extracted Data*/

OPTIONS MISSING='';

CREATE TABLE WORK.S37_QRT_INVOKE AS 


SELECT 

	MONOTONIC() AS LINE_ID
	
	, CASE 
		WHEN C0030 = '1 - LEI' THEN 'LEI/'||C0020
		ELSE 'None'
	  END AS C0020

	, CASE 
		WHEN C0130 = '1 - LEI' THEN 'LEI/'||C0120
		WHEN C0130 = '2 - SC'  THEN 'SC/'||C0120
		ELSE 'None'
	  END AS C0120

	, CASE 
		WHEN C0070 = '1 - ISO/6166 for ISIN' THEN 'ISIN/'||C0060
		WHEN C0070 = '2 - CUSIP' THEN 'CUSIP/'||C0060
		WHEN C0070 = '99 - Code attributed by the undertaking' THEN 'CAU/INST/'||C0060
		ELSE 'UNKNOWN - '||C0060
	  END AS C0060

	 , C0010

	 , C0040

	 , SUBSTR(C0050,1,1) AS C0050

	 , ASSESSMENT_GRADE AS C0080

	 , CASE 
		WHEN C0090 = 'Standard & Poor'||"'"||'s'  THEN  'Standard & Poor'||"'"||'s (to be used when the split below is not available)' 
		WHEN C0090 = 'Moody'||"'"||'s'  THEN 'Moody'||"'"||'s (to be used when the split below is not available)' 
		WHEN C0090 = 'Fitch' THEN 'Fitch (to be used when the split below is not available)'
		ELSE ''	END AS C0090 

	 , C0091

	 , C0100

	 , C0110

	 , C0140

	 , C0150

	 , C0160

	 , COALESCE(C0170,0) AS C0170

FROM 

	S37_QRT; 

QUIT;