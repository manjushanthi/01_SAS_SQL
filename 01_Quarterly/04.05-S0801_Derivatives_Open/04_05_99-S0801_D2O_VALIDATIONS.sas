
PROC SQL ;


	/* D2o Validations on Issuer names , Issuer Group names , Rating and Deriv's categories */
	/* The Issuer / Issuer group  should not have multiple ratings for */
    /* Even though the Issuer is same across the derivative categories , The same rating should be populated */
	CREATE TABLE WORK.S0801_D2o_IMT_VALIDATIONS AS 

	SELECT 

	  DISTINCT 
		A6 AS C0260

		, A36 AS C0270

		, CASE 
			WHEN A38 = '1'  THEN  '1 - LEI' 
			ELSE '9 - None' 
		  END AS C0280

		, A34 AS C0290

		, CASE 	
			WHEN A35 =  'S_P' THEN  'S&P Global Ratings Europe Limited (LEI code:5493008B2TU3S6QE1E12)'
			WHEN A35 =  'MDY' THEN 'Moody'||'’'||'s Investors Service Ltd (LEI code: 549300SM89WABHDNJ349)' 
			WHEN A35 =  'FIT' THEN  'Fitch Ratings Limited (LEI code: 2138009F8YAHVC8W3Q52)'		
			ELSE 'NR'			
		  END AS C0300


		, CASE 	
			WHEN  PUT(C0310,1.0) = '0'  THEN '0 - Credit quality step 0'
			WHEN  PUT(C0310,1.0) = '1'  THEN '1 - Credit quality step 1'
			WHEN  PUT(C0310,1.0) = '2'  THEN '2 - Credit quality step 2'
			WHEN  PUT(C0310,1.0) = '3'  THEN '3 - Credit quality step 3'
			WHEN  PUT(C0310,1.0) = '4'  THEN '4 - Credit quality step 4'
			WHEN  PUT(C0310,1.0) = '5'  THEN '5 - Credit quality step 5'
			WHEN  PUT(C0310,1.0) = '6'  THEN '6 - Credit quality step 6'	
			WHEN  PUT(C0310,1.0) = '9'  THEN '9 - No rating available'	
			ELSE 'NR'
		  END AS C0310

		, COALESCE(X_INTERNAL_RATING,'Not Applicable') AS C0320
				 
		, A7 AS C0330
		
		, A37 AS C0340

		, CASE 
				WHEN A38GRP = '1' THEN '1 - LEI' 
				ELSE '9 - None'
		   END AS C0350

		,INT11

	FROM WORK.S0801_D2O_IMT_BASE

	ORDER BY 																															
		C0260
		, INT11 ;          
QUIT;