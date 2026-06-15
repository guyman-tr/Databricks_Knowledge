SELECT o.*,
r.Name AS Regulation,
dpl.Name AS PlayerLevel

FROM BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard o
JOIN DWH_dbo.Dim_Customer c ON c.RealCID=o.CID
JOIN DWH_dbo.Dim_Regulation r ON r.ID=c.RegulationID
JOIN DWH_dbo.Dim_PlayerLevel dpl ON dpl.PlayerLevelID=c.PlayerLevelID
where ExecutionApproval is not null