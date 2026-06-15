SELECT DISTINCT
	dc.RealCID, dc.GCID, pc.Regulation, Club, Current_PlayerStatus, Change_Date, PlayerStatusReason, Is_FTD,
	dc.ApexID AS EquitiesApexID, 
	op.OptionsApexID,
	CASE WHEN dc.ApexID IS NULL THEN 'NoEquitiesAccount' ELSE 'HasEquitiesAccount' END AS [EquitiesAccount], 
	CASE WHEN op.OptionsStatusID IS NULL THEN 'NoOptionsAccount' ELSE 'HasOptionsAccount' END AS [OptionsAccount],
	ROW_NUMBER() OVER (PARTITION BY pc.CID order by pc.Change_Date desc) as RN
FROM BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes pc
join DWH_dbo.Dim_Customer dc on dc.RealCID=pc.CID AND dc.CountryID=219 AND dc.RegulationID IN (6,7,8,12) AND dc.DesignatedRegulationID IN (6,7,8,12)
left join [BI_DB_dbo].[External_USABroker_Apex_Options] op ON op.GCID=dc.GCID and op.OptionsStatusID=3--Approved