SELECT dcr.[Date]
      ,dcr.[DateID]
      ,dcr.[ParentCID]
      ,dcr.[GuruStatusID]
      ,dcr.[CountryID]
      ,dcr.[AccountTypeID]
      ,dcr.[Revenue_Copy]
      ,dcr.[UpdateDate]
	  ,dc.UserName
	  ,FundAccountID
	  ,FundType
	  ,dft.FundTypeName PortfolioType
  FROM [BI_DB_dbo].[BI_DB_DailyCopyRevenue] dcr  with (Nolock)
  JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK)
   ON dcr.ParentCID = dc.RealCID 
   and DateID>=20220101
  LEFT JOIN  DWH_dbo.Dim_Fund tf WITH (NOLOCK)
  ON tf.FundAccountID=dcr.ParentCID
  Left JOIN DWH_dbo.Dim_FundType dft WITH (NOLOCK)
  ON dft.FundTypeID = tf.FundType and IsPublic=1