select *
from dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] with (nolock)
where DateID = CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT)