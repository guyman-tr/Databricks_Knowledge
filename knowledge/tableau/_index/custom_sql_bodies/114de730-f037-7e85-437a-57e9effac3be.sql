SELECT b.*,pl.Name as ClubLevel
FROM [BI_DB_dbo].[BI_DB_US_Apex_Instrument_Holders] b
join DWH_dbo.Dim_Customer dc on dc.RealCID=b.[RealCID]
JOIN DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=dc.PlayerLevelID