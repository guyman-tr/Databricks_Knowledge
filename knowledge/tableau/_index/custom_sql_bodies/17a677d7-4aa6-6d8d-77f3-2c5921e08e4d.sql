select *
from BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New with (nolock)
where DateID between 
CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[ToDateID (copy)]> as DATE), 112) AS INT)
and 
CAST(CONVERT(VARCHAR(10), CAST(<[Parameters].[ToDateID (copy 2)]> as DATE), 112) AS INT)