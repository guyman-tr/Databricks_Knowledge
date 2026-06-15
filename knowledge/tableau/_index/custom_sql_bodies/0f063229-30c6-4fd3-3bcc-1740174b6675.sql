SELECT [TR_Audit_VS_BestEx].[Audit_Transaction_Count] AS [Audit_Transaction_Count],
  [TR_Audit_VS_BestEx].[Mismatch] AS [Mismatch],
  [TR_Audit_VS_BestEx].[ReportDate] AS [ReportDate],
  [TR_Audit_VS_BestEx].[Report] AS [Report],
  [TR_Audit_VS_BestEx].[TraNa_Transaction_Count] AS [TraNa_Transaction_Count]
FROM [dbo].[TR_Audit_VS_BestEx] [TR_Audit_VS_BestEx]
Where ReportDate >= cast(getdate () -7 as date)