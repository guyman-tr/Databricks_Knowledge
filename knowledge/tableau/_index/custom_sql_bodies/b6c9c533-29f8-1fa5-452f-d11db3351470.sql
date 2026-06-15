SELECT
       c.[CountryID]
      ,c.[Name] AS Country
      ,c.[Abbreviation]
      ,c.[LongAbbreviation]
      ,c.[Region]  MarketingRegion
      ,c.[RiskGroupID]
      ,c.[RegulationID]
      ,dr.Name AS [Regulation]
      ,Case WHEN   w.IsOpen =0 THEN 'Closed'  WHEN   w.IsOpen =2 THEN 'Open' WHEN  w.IsOpen =3 THEN 'OpenForExistingOnly' END  [Country Open for Wallet]
 --FROM [AZR-WE-DB-02].[etoro_rep].[dbo].[V_Country] c 
FROM DWH.dbo.Dim_Country c
 JOIN DWH.dbo.Dim_Regulation dr ON dr.DWHRegulationID  =c.RegulationID

INNER  join 
 (SELECT DISTINCT  ewe.CountryID	    ,ewe.Country, 	      max( ewe.CountryOpenforWallet) IsOpen
	  		   FROM EXW.dbo.EXW_WalletElligibleCountries ewe
	   GROUP BY  ewe.CountryID	    ,ewe.Country)w 
 ON w.CountryID = c.CountryID