SELECT dc1.GCID
,dc1.UserName
,dc1.Email
,dc1.RegulationID
,dl.Name AS Language
,dc.UserName as [pi]
,dc.GCID AS PIGCID
,dc1.ID
,fact_sheet.link
,fact_sheet.pi_username
FROM DWH_dbo.Dim_Mirror dm
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=dm.ParentCID
JOIN DWH_dbo.Dim_Customer dc1 ON dc1.RealCID=dm.CID
JOIN DWH_dbo.Dim_Language dl ON dc1.LanguageID = dl.LanguageID
JOIN [BI_DB_dbo].[External_SharePoint_monthly_fact_sheets_update_for_tableau] fact_sheet ON dc.GCID=fact_sheet.gcid
WHERE dc.GuruStatusID >=5
AND dm.CloseDateID=0
AND dc1.IsValidCustomer=1
AND dc1.IsDepositor=1