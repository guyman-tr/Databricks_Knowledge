select *
from BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New_DLTSimulation with (nolock)
where DateID  =  CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[Parameter 1 1]> as DATE), 112) AS INT)
AND DidRegulationTransfer = 1