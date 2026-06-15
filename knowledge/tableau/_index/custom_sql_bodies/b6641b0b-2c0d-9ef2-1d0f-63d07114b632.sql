select 'FCA' AS DesignatedRegulation
, [mp].[ActiveDate] AS 'Date'

,mp.CID
, mp.IsFunded_New AS 'Funded User End Of Period'
,CASE WHEN [ActiveOpen] = 1 OR Active = 1 THEN 1 else 0 END'Active (Opened or Held a position during Period'
from [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] mp
JOIN [DWH_dbo].[Dim_Customer] dc
	ON mp.CID = dc.RealCID
JOIN DWH_dbo.Dim_Country dc1
	ON dc.CountryID = dc1.CountryID
WHERE dc.IsValidCustomer = 1
AND dc.DesignatedRegulationID = 2
AND mp.[ActiveDate] between cast(<[Parameters].[Parameter 2]> as date)
and cast(<[Parameters].[Parameter 3]> as date)