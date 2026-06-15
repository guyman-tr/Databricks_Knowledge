SELECT r.AffiliateID,
	   r.WebSiteURL,
       r.DateCreated,
        r.Contact,
       r.TradingAccount_RealCID,
       r.Country,
       CASE WHEN exch.MarketingExpenseName='Networks' THEN 'Networks' ELSE r.SubChannel END SubChannel,
       CASE WHEN r.AccountActivated = 1 THEN 'Active' ELSE 'Inactive' END AS Status,
       r.AffiliatesGroupsName,
       r.AccountActivated,
       r.VerificationLevelID,
       r.CustomerStatus,
       r.AccountType,
       r.Regulation,
       CASE
           WHEN r.Compensation_Aff = 0 AND r.FTD_Aff = 0 AND r.Trading_Aff = 0 THEN 1
           WHEN r.Compensation_Aff = 1 AND r.FTD_Aff = 0 AND r.Trading_Aff = 0 THEN 2
           WHEN r.Compensation_Aff = 1 AND r.FTD_Aff = 1 AND r.Trading_Aff = 0 THEN 3
           WHEN r.Compensation_Aff = 1 AND r.Trading_Aff = 1 THEN 4
           WHEN r.Compensation_Aff = 0 AND r.FTD_Aff = 0 AND r.Trading_Aff = 1 THEN 5
           WHEN r.Compensation_Aff = 0 AND r.FTD_Aff = 1 THEN 6
           ELSE NULL
       END AS Panos_Group,
       CASE WHEN docs.POI = 1 THEN 'Yes' ELSE 'No' END AS POIOnFile,
       CASE WHEN docs.POA = 1 THEN 'Yes' ELSE 'No' END AS POAOnFile,
       CASE WHEN docs.AffiliateQuestionnaire = 1 THEN 'Yes' ELSE 'No' END AS AffiliateQuestionnaire,
       lastcomp.LastCompensationDate,
       CAST(GETDATE() AS DATE) AS UpdateDate
FROM #Affiliates_Raw r
LEFT JOIN DWH_dbo.Ext_Dim_Channel exch ON r.AffiliateID = exch.AffiliateID
LEFT JOIN #DOCS docs ON docs.CID = r.TradingAccount_RealCID
--LEFT JOIN #usedmargin um ON um.CID = r.TradingAccount_RealCID
LEFT JOIN #lastcomp lastcomp ON lastcomp.CID = r.TradingAccount_RealCID