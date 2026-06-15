SELECT Country
        ,f.Region
        ,CAST(ActionDate AS DATE) ActionDate
		,t.ActionName
		,COUNT(RealCID) NumberOfActions
  FROM 
  (SELECT f.[ActionDateID]
      ,f.ActionDate
      ,f.[Symbol]
	  ,a.RealCID
	  ,a.ActionTypeID
	  ,dc1.Name Country
	  ,dc1.Region
  FROM [BI_DB].[dbo].[BI_DB_Social_Activity_Instrument_Feed] f
  INNER JOIN [BI_DB].[dbo].[BI_DB_Social_Activity] a
  ON f.PostID = a.PostID
  INNER JOIN [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
  ON a.RealCID = dc.RealCID
  INNER JOIN [DWH].[dbo].[Dim_Country] dc1 WITH (NOLOCK)
  ON dc.CountryID = dc1.CountryID
  WHERE f.ActionDateID >=20200101
  ) f
  INNER JOIN BI_DB.[dbo].[BI_DB_Social_Activity_Type] t
  ON f.ActionTypeID = t.ActionID
  GROUP BY Country
        ,CAST(ActionDate AS DATE)
		,t.ActionName
		,f.Region