SELECT dpd.[CID]
      ,dpd.[EffectiveLev]
  FROM [BI_DB].[dbo].[BI_DB_ClusteringDailyPrepData] dpd WITH (NOLOCK)
  INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
  ON dd.DateKey = dpd.CalculationDateID
  WHERE dd.PartitionID = 202110