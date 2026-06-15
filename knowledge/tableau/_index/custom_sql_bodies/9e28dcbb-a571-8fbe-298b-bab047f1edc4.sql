SELECT 
pc.*,
CASE WHEN op.OptionsStatusID=3 THEN 'HasOptionsAccount' 
ELSE 'NoOptionsAccount' END AS [OptionsAccount],
ROW_NUMBER() OVER (PARTITION BY pc.CID order by pc.Change_Date desc) as RN

FROM BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes pc
join DWH_dbo.Dim_Customer dc on dc.RealCID=pc.CID
LEFT JOIN BI_DB_dbo.BI_DB_AllDeposits bdad ON pc.CID = bdad.CID
left join [BI_DB_dbo].[External_USABroker_Options] op ON op.GCID=dc.GCID and op.OptionsStatusID=3--Approved