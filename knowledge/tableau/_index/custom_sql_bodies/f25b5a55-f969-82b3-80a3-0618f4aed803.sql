select * from BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New_DLTSimulation with (nolock)
where DateID between 
CAST(CONVERT(VARCHAR(10), CAST(getdate()-8 as DATE), 112) AS INT)
and 
CAST(CONVERT(VARCHAR(10), CAST(getdate()-1 as DATE), 112) AS INT)