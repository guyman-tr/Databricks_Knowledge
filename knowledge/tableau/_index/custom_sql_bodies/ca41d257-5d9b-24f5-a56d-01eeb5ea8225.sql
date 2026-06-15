SELECT fd.CID
      ,fd.Club
	  ,dr.Name Regulation
	  ,fd.NewMarketingRegion Region
FROM [BI_DB_dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
INNER JOIN DWH_dbo.Dim_Regulation dr WITH (NOLOCK)
ON fd.RegulationID = dr.ID