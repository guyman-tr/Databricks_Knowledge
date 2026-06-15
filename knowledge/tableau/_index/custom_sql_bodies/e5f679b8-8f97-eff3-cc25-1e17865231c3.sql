SELECT  a.*
      ,CASE WHEN (a.RealizedEquity_BOM>=20000
	  AND a.Is_Closed_Positions=1
	  AND a.IsEOM_Funded_NEW=1
	  AND a.Club<>'Bronze'
	  AND a.Is_CO_Active=1
	  AND a.RealizedEquity_BOM_Ratio IN ('30-60%','60-80%','80% +'))THEN 1 ELSE 0 END AS Traget_Clients_Club
	        ,CASE WHEN (a.RealizedEquity_BOM>=20000
	  AND a.Is_Closed_Positions=1
	  AND a.IsEOM_Funded_NEW=1
	  AND a.Club<>'Bronze'
	  AND a.RealizedEquity_BOM_Ratio IN ('30-60%','60-80%','80% +'))THEN 1 ELSE 0 END AS Traget_Clients_Club_All
	  ,CASE WHEN a.RealizedEquity_BOM<=100 THEN '0-0.1K'
	        WHEN a.RealizedEquity_BOM<=300 THEN '0.1-0.3K'
			WHEN a.RealizedEquity_BOM<=500 THEN '0.3-0.5K'
			WHEN a.RealizedEquity_BOM<=1000 THEN '0.5-1K'
			WHEN a.RealizedEquity_BOM<=3000 THEN '1-3K'
	        WHEN a.RealizedEquity_BOM<=5000 THEN '3-5K'
	   ELSE '5K+' END AS RealizedEquity_BOM_Tier_Detailed
FROM  BI_DB_dbo.CO_Alert_Panel_3 a