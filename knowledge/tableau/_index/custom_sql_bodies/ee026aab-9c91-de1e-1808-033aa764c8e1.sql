SELECT bdafm.*,ps.Name as PlayerStatus,
CAST(CONVERT(VARCHAR(6), registered , 112) AS INT) as RegisteredYearMonth 
,
CASE WHEN dc.PlayerStatusID in (2,4) then 1 else 0 end Blocked
FROM BI_DB_dbo.BI_DB_Affiliates_FraudMonitoring bdafm
join DWH_dbo.Dim_Customer dc on dc.RealCID=bdafm.CID
JOIN DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=dc.PlayerStatusID
--where CAST(CONVERT(VARCHAR(6), registered , 112) AS INT)=FTDYearMonth