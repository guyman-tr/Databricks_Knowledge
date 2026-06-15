SELECT * ,
--==Commission1124
CASE WHEN Commission1124_temp >= Commission_Capped THEN Commission_Capped 
	 ELSE Commission1124_temp END AS Commission1124,

--==Commission1224
CASE WHEN Commission1124_temp >= Commission_Capped  THEN 0
     WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) >= 100  THEN SUM(Commission_Capped) - SUM(Commission1124_temp)  
	 WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) < 100   THEN SUM(Commission1224_temp)
	 END AS Commission1224,

--==Commission0125
	 CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) >= Commission_Capped THEN 0 

		  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) >= 100 
		  THEN SUM(Commission_Capped) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

		  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) < 100
		  THEN SUM(Commission0125_temp) 

		  END AS Commission0125,

--==Commission0225
	 CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) >= Commission_Capped THEN 0 

	 	  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) >= 100 
		  THEN SUM(Commission_Capped) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

		  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) < 100
		  THEN SUM(Commission0225_temp)

		  END AS Commission0225,



--==Commission0325
	 CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  >= Commission_Capped THEN 0 

	 	  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp)>= 100 
		  THEN SUM(Commission_Capped) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

		  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) < 100
		  THEN SUM(Commission0325_temp)

		  END AS Commission0325,


--==Commission0425
	 CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) >= Commission_Capped THEN 0 

	 	  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp) + SUM(Commission0425_temp)>= 100 
		  THEN SUM(Commission_Capped) - SUM(Commission0325_temp) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

		  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp) < 100
		  THEN SUM(Commission0425_temp)

		  END AS Commission0425,

--==Commission0525

	 CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp)>= Commission_Capped THEN 0 

	 	  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp) + SUM(Commission0425_temp)+ SUM(Commission0525_temp)>= 100 
		  THEN SUM(Commission_Capped) - SUM(Commission0425_temp) - SUM(Commission0325_temp) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

		  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp)  + SUM(Commission0525_temp) < 100
		  THEN SUM(Commission0525_temp)

		  END AS Commission0525,



--==Commission0625

 CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp) + SUM(Commission0525_temp) >= Commission_Capped THEN 0 

	 	  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp) + SUM(Commission0425_temp)+ SUM(Commission0525_temp) + SUM(Commission0625_temp) >= 100 
		  THEN SUM(Commission_Capped) - SUM(Commission0525_temp) - SUM(Commission0425_temp) - SUM(Commission0325_temp) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

		  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp)  + SUM(Commission0525_temp) + SUM(Commission0625_temp) < 100
		  THEN SUM(Commission0625_temp)

		  END AS Commission0625,


--==Commission0725

 CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp) + SUM(Commission0525_temp)  + SUM(Commission0625_temp) >= Commission_Capped THEN 0 

	 	  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp) + SUM(Commission0425_temp)+ SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) >= 100 
		  THEN SUM(Commission_Capped) - SUM(Commission0625_temp)  - SUM(Commission0525_temp) - SUM(Commission0425_temp) - SUM(Commission0325_temp) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

		  WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp)  + SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) < 100
		  THEN SUM(Commission0725_temp)

		  END AS Commission0725,


--==Commission0825

CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp) + SUM(Commission0525_temp)  + SUM(Commission0625_temp) + SUM(Commission0725_temp) >= Commission_Capped THEN 0 

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp) + SUM(Commission0425_temp)+ SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) >= 100 
THEN SUM(Commission_Capped) - SUM(Commission0725_temp) - SUM(Commission0625_temp)  - SUM(Commission0525_temp) - SUM(Commission0425_temp) - SUM(Commission0325_temp) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp)  + SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) < 100
THEN SUM(Commission0825_temp) END AS Commission0825,


--==Commission0925

CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp) + SUM(Commission0525_temp)  + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) >= Commission_Capped THEN 0 

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp) + SUM(Commission0425_temp)+ SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) >= 100 
THEN SUM(Commission_Capped) - SUM(Commission0825_temp) - SUM(Commission0725_temp) - SUM(Commission0625_temp)  - SUM(Commission0525_temp) - SUM(Commission0425_temp) - SUM(Commission0325_temp) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp)  + SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp)< 100
THEN SUM(Commission0925_temp) END AS Commission0925,

--==Commission1025

CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp) + SUM(Commission0525_temp)  + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) >= Commission_Capped THEN 0 

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp) + SUM(Commission0425_temp)+ SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) + SUM(Commission1025_temp) >= 100 
THEN SUM(Commission_Capped) - SUM(Commission0925_temp) - SUM(Commission0825_temp) - SUM(Commission0725_temp) - SUM(Commission0625_temp)  - SUM(Commission0525_temp) - SUM(Commission0425_temp) - SUM(Commission0325_temp) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp)  + SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) + SUM(Commission1025_temp)< 100
THEN SUM(Commission1025_temp) END AS Commission1025,


--==Commission1125
CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp) + SUM(Commission0525_temp)  + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) + SUM(Commission1025_temp)  >= Commission_Capped THEN 0 

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp) + SUM(Commission0425_temp)+ SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) + SUM(Commission1025_temp) + SUM(Commission1125_temp) >= 100 
THEN SUM(Commission_Capped) - SUM(Commission1025_temp) - SUM(Commission0925_temp) - SUM(Commission0825_temp) - SUM(Commission0725_temp) - SUM(Commission0625_temp)  - SUM(Commission0525_temp) - SUM(Commission0425_temp) - SUM(Commission0325_temp) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp)  + SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) + SUM(Commission1025_temp) + SUM(Commission1125_temp)< 100
THEN SUM(Commission1125_temp) END AS Commission1125,


--==Commission1225
CASE WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp) + SUM(Commission0525_temp)  + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) + SUM(Commission1025_temp) + SUM(Commission1125_temp)   >= Commission_Capped THEN 0 

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp)  + SUM(Commission0325_temp) + SUM(Commission0425_temp)+ SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) + SUM(Commission1025_temp) + SUM(Commission1125_temp)  + SUM(Commission1225_temp) >= 100 
THEN SUM(Commission_Capped) - SUM(Commission1125_temp) - SUM(Commission1025_temp) - SUM(Commission0925_temp) - SUM(Commission0825_temp) - SUM(Commission0725_temp) - SUM(Commission0625_temp)  - SUM(Commission0525_temp) - SUM(Commission0425_temp) - SUM(Commission0325_temp) - SUM(Commission0225_temp) - SUM(Commission0125_temp) - SUM(Commission1224_temp)  - SUM(Commission1124_temp)   

WHEN SUM(Commission1124_temp) + SUM(Commission1224_temp) + SUM(Commission0125_temp) + SUM(Commission0225_temp) + SUM(Commission0325_temp) + SUM(Commission0425_temp)  + SUM(Commission0525_temp) + SUM(Commission0625_temp) + SUM(Commission0725_temp) + SUM(Commission0825_temp) + SUM(Commission0925_temp) + SUM(Commission1025_temp) + SUM(Commission1125_temp) + SUM(Commission1225_temp) < 100
THEN SUM(Commission1225_temp) END AS Commission1225

	  FROM #temp 

 

	  GROUP BY 
      CID,
	  GCID,
      BannerID,
      SerialID,
	  Country,
	  Reg_Date,
	  Reg_Date_Plus30,
	  Commission,
      Commission_Capped,
      Commission1124_temp,
      Commission1224_temp,
      Commission0125_temp,
      Commission0225_temp,
      Commission0325_temp,
      Commission0425_temp,
      Commission0525_temp,
      Commission0625_temp,
      Commission0725_temp,
      Commission0825_temp,
      Commission0925_temp,
 Commission1025_temp,
Commission1125_temp,
Commission1225_temp,

Commission0126_temp,
Commission0226_temp,
Commission0326_temp,
Commission0426_temp,
Commission0526_temp