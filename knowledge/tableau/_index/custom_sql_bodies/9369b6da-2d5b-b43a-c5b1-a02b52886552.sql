SELECT [ReportDate]
      ,[Underlying identification]
      ,[ISINs_RegTech]
      ,[ISINs_Regis]
      ,[Mismatch]
      ,[UpdateDate]
  FROM [RegReportDB_Prod].[dbo].[TR_EMIR_ISINs_Reconciliation]
  where Mismatch <> '0'
or Mismatch is Null