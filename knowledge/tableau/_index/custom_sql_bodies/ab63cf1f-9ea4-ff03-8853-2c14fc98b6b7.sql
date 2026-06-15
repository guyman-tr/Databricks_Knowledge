SELECT bdscp.CID_Last
                ,bdscp.CaseNumber
                ,bdscp.TicketStatus
                ,bdscp.CreatedDate
                ,bdscp.CloseDateTime
                ,bdscp.LastStatusDate
                ,bdscp.Country_Last
                ,dc.MarketingRegionManualName [MarketingRegionLast]
                ,bdscp.ServiceDesk_Last
                ,bdscp.ClubTier_Last
                ,bdscp.SubRole_Last
                ,bdscp.SubType_Last
                ,bdscp.SubType2_Last
                ,(dm.FirstName + ' ' +dm.LastName) [AccountManagerLast]
                ,bdsu.FullName [LastAgentName]
                ,bdsu.Desk_CS
                ,bdscp.FirstCSAT
                ,bdscp.LastCSAT
                ,bdscp.PlayerStatus_Last
				,CASE WHEN (bdscp.FirstCSAT BETWEEN 0 AND 3 OR bdscp.LastCSAT BETWEEN 0 AND 3) THEN 'Low CSAT' 
				WHEN (bdscp.FirstCSAT > 3 OR bdscp.LastCSAT > 3) THEN 'Normal CSAT'
				ELSE NULL END AS [CSAT Group]
FROM BI_DB..BI_DB_SF_Cases_Panel bdscp
LEFT JOIN DWH..Dim_Country dc ON bdscp.Country_Last = dc.Name
LEFT JOIN DWH..Dim_Manager dm ON bdscp.AccountManagerID_Last = dm.ManagerID
LEFT JOIN BI_DB..BI_DB_SF_Users bdsu ON bdscp.ActiveAgentID_Last = bdsu.Id
WHERE dc.MarketingRegionManualName IN ('SEA', 'Australia')
AND bdscp.CloseDateTime >= CAST('2022-01-01' AS DATE)