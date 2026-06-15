select 
    v.* , 
    dr.Name as DesignatedRegulation, 
    dc.IsDepositor,
    case when dc.RegisteredReal>DATEADD(week, -6, DATEADD(week, DATEDIFF(week, 0, getdate()), 0)) then 1 else 0 end as '6WeekIndicator'
,	min(case when hc.VerificationLevelID = 2 then hc.ValidFrom end) VerificationLevel2Date
,	min(case when hc.VerificationLevelID = 3 then hc.ValidFrom end) VerificationLevel3Date
from  BI_DB_dbo.[BI_DB_OPS_VerificationPipeline_OverLevel2] v
join DWH_dbo.Dim_Customer dc on dc.RealCID=v.RealCID
LEFT JOIN DWH_dbo.Dim_Regulation dr on dr.ID=dc.DesignatedRegulationID
join [general].[etoro_History_BackOfficeCustomer] hc on hc.CID=v.RealCID
where dc.RegisteredReal>='2025-01-01'
GROUP BY v.RealCID,
v.EvMatchStatusName,
v.VerificationLevelID,
v.Country,
v.[Uploaded 2 Docs],
v.[Uploaded POI only],
v.[Uploaded POA only],
v.TotalHits,
v.PhoneVerifiedName,
v.IsEmailVerified,
v.IsManual,
v.DDCategoryVL2toVL3,
v.ScreeningStatus,
v.RegisteredReal,
v.Category,
v.Regulation,
v.RiskAlerts,
dr.Name, 
dc.IsDepositor,
v.UpdateDate,
dc.RegisteredReal