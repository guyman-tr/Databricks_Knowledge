select	v.*, 
		dc1.MarketingRegionManualName,
		dr.Name as DesignatedRegulation,
		dc.IsDepositor,
		case when dc.RegisteredReal>=DATEADD(week, -6, DATEADD(week, DATEDIFF(week, 0, getdate()), 0)) then 1 else 0 end as '6WeekIndicator'
from  BI_DB.dbo.[BI_DB_OPS_VerificationPipeline_OverLevel2] v
join DWH.dbo.Dim_Customer dc on dc.RealCID=v.RealCID
LEFT JOIN DWH.dbo.Dim_Regulation dr on dr.ID=dc.DesignatedRegulationID
LEFT JOIN DWH..Dim_Country dc1 ON v.Country = dc1.Name