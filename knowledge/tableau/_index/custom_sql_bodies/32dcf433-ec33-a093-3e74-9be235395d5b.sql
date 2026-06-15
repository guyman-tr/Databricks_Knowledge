SELECT ai.Date, 
	ai.DateID, 
	ai.AffiliateID,  
	da.DateCreated, 
	da.Channel, 
	da.SubChannel, 
	dc1.[Organic/Paid], 
	da.Contact, 
	da.ContractName, 
	da.ContractType, 
	da.AffiliatesGroupsName, 
	da.AccountActivated
FROM 
(
SELECT 
    Date,  
    DateID,  
    CASE 
        WHEN lower([Campaign]) = '2018_engagement' THEN 23994  
        WHEN a.Campaign = '' THEN 
            CASE 
                WHEN [Platform] = 'android' THEN 56663  
                WHEN [Platform] = 'ios' THEN 56662 
            END  
        ELSE ISNULL(
            TRY_CAST(
                CASE 
                    WHEN PATINDEX('%AFFID_%', [Campaign]) = 0 THEN NULL
                    ELSE SUBSTRING([Campaign], 
                                    PATINDEX('%AFFID_%', [Campaign]) + LEN('AFFID_'),
                                    CASE 
                                        WHEN PATINDEX('%[^0-9]%', SUBSTRING([Campaign], PATINDEX('%AFFID_%', [Campaign]) + LEN('AFFID_'), LEN([Campaign]))) = 0 THEN LEN([Campaign]) - PATINDEX('%AFFID_%', [Campaign]) - LEN('AFFID_') + 1
                                        ELSE PATINDEX('%[^0-9]%', SUBSTRING([Campaign], PATINDEX('%AFFID_%', [Campaign]) + LEN('AFFID_'), LEN([Campaign]))) - 1
                                    END
                    )
                END AS INT
            ),
            CASE 
                WHEN [Platform] = 'android' THEN 56663  
                WHEN [Platform] = 'ios' THEN 56662
            END
        )
    END AS [AffiliateID]
FROM BI_DB_dbo.BI_DB_AppFlyer_Reports  a WITH (NOLOCK)
LEFT JOIN DWH_dbo.Dim_Country  DC WITH (NOLOCK)
    ON DC.Abbreviation = a.CountryCode  
--LEFT JOIN #connection b
--    ON a.AppsFlyerID = b.TrackingValue COLLATE Latin1_General_Bin    
WHERE 
    Date >= GETDATE() -20    
   -- AND Date < @Date1  
    AND (EventName = 'install')   
GROUP BY 
	Date,  
    DateID,  
    CASE 
        WHEN lower([Campaign]) = '2018_engagement' THEN 23994  
        WHEN a.Campaign = '' THEN 
            CASE 
                WHEN [Platform] = 'android' THEN 56663  
                WHEN [Platform] = 'ios' THEN 56662 
            END  
        ELSE ISNULL(
            TRY_CAST(
                CASE 
                    WHEN PATINDEX('%AFFID_%', [Campaign]) = 0 THEN NULL
                    ELSE SUBSTRING([Campaign], 
                                    PATINDEX('%AFFID_%', [Campaign]) + LEN('AFFID_'),
                                    CASE 
                                        WHEN PATINDEX('%[^0-9]%', SUBSTRING([Campaign], PATINDEX('%AFFID_%', [Campaign]) + LEN('AFFID_'), LEN([Campaign]))) = 0 THEN LEN([Campaign]) - PATINDEX('%AFFID_%', [Campaign]) - LEN('AFFID_') + 1
                                        ELSE PATINDEX('%[^0-9]%', SUBSTRING([Campaign], PATINDEX('%AFFID_%', [Campaign]) + LEN('AFFID_'), LEN([Campaign]))) - 1
                                    END
                    )
                END AS INT
            ),
            CASE 
                WHEN [Platform] = 'android' THEN 56663  
                WHEN [Platform] = 'ios' THEN 56662
            END
        )
		END
		) ai 	 LEFT JOIN DWH_dbo.Dim_Affiliate  da ON ai.AffiliateID = da.AffiliateID
	left JOIN DWH_dbo.Dim_Channel dc1 ON da.SubChannelID = dc1.SubChannelID  
	WHERE ai.AffiliateID <> 0  
	AND da.DateCreated IS NULL