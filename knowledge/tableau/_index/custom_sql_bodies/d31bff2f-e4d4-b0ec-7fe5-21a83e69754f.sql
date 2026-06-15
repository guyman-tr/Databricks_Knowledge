SELECT 
    ISNULL(cf.YearMonth, ld.YearMonth) AS YearMonth,
    ISNULL(cf.Channel, ld.Channel) AS Channel,
    ISNULL(cf.Region, ld.Region) AS Region,
    ld.FTDs,
    ld.LTV,
    ld.LTV_FTDs,
    cf.Cost,
    ls.LTV_LeadScore,
    ls.Users_LeadScore
FROM (
    -- CostFinanceNormalized
    SELECT 
        [month] AS YearMonth,
        channel COLLATE Latin1_General_CS_AS AS Channel,
        region COLLATE Latin1_General_CS_AS AS Region,
        cost AS Cost
    FROM [BI_DB_dbo].[External_Fivetran_gsheet_costfinance]
) cf
FULL OUTER JOIN (
    -- LTV_Data
    SELECT 
        CONVERT(VARCHAR(7), dc.FirstDepositDate, 126) AS YearMonth,
        CASE 
            WHEN dc1.SubChannel = 'FB' THEN 'Facebook'
            WHEN dc1.SubChannel = 'ASA' THEN 'ASA'
            WHEN dc1.SubChannel = 'Twitter' THEN 'Twitter'
            WHEN dc1.SubChannel = 'Outbrain' THEN 'Outbrain'
            WHEN dc1.SubChannel = 'Taboola' THEN 'Taboola'
            WHEN dc1.SubChannel = 'Media Performance' THEN 'Media Performance'
            WHEN dc1.SubChannel = 'Media Programmatic' THEN 'Media Programmatic'
            WHEN dc1.SubChannel IN ('Mobile Non-CPA', 'Mobile CPA') THEN 'Mobile'
            WHEN dc1.SubChannel IN ('SMM', 'Direct', 'Direct Mobile') THEN 'Direct'
            WHEN dc1.SubChannel IN ('Google Brand', 'Google Search', 'Google UAC', 'YT', 'Discovery') THEN 'Google'
            WHEN dc1.SubChannel IN ('SEM Other', 'Bing Search') THEN 'SEM'
            WHEN dc1.SubChannel IN ('IBs', 'Affiliate') THEN 'Affiliate'
            ELSE dc1.Channel 
        END AS Channel,
        dc2.MarketingRegionManualName AS Region,
        COUNT(dc.RealCID) AS FTDs,
        SUM(ltv.Revenue8Y_LTV_New) AS LTV,
        COUNT(ltv.CID) AS LTV_FTDs
    FROM DWH_dbo.Dim_Customer dc
    INNER JOIN DWH_dbo.Dim_Channel dc1 ON dc.SubChannelID = dc1.SubChannelID
    INNER JOIN DWH_dbo.Dim_Country dc2 ON dc.CountryID = dc2.CountryID
    LEFT JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual ltv 
        ON dc.RealCID = ltv.CID 
        AND dc.IsValidCustomer = 1
    WHERE YEAR(dc.FirstDepositDate) >= 2023
      AND dc.IsValidCustomer = 1
      AND NOT EXISTS (
          SELECT 1 
          FROM DWH_dbo.Dim_Customer dc_excl
          WHERE dc_excl.RealCID = dc.RealCID
            AND dc_excl.FirstDepositDate >= '2025-08-19' 
            AND dc_excl.FirstDepositDate < '2025-08-22'
            AND dc_excl.FirstDepositAmount = 1
      )
    GROUP BY 
        CONVERT(VARCHAR(7), dc.FirstDepositDate, 126),
        CASE 
            WHEN dc1.SubChannel = 'FB' THEN 'Facebook'
            WHEN dc1.SubChannel = 'ASA' THEN 'ASA'
            WHEN dc1.SubChannel = 'Twitter' THEN 'Twitter'
            WHEN dc1.SubChannel = 'Outbrain' THEN 'Outbrain'
            WHEN dc1.SubChannel = 'Taboola' THEN 'Taboola'
            WHEN dc1.SubChannel = 'Media Performance' THEN 'Media Performance'
            WHEN dc1.SubChannel = 'Media Programmatic' THEN 'Media Programmatic'
            WHEN dc1.SubChannel IN ('Mobile Non-CPA', 'Mobile CPA') THEN 'Mobile'
            WHEN dc1.SubChannel IN ('SMM', 'Direct', 'Direct Mobile') THEN 'Direct'
            WHEN dc1.SubChannel IN ('Google Brand', 'Google Search', 'Google UAC', 'YT', 'Discovery') THEN 'Google'
            WHEN dc1.SubChannel IN ('SEM Other', 'Bing Search') THEN 'SEM'
            WHEN dc1.SubChannel IN ('IBs', 'Affiliate') THEN 'Affiliate'
            ELSE dc1.Channel 
        END,
        dc2.MarketingRegionManualName
) ld
    ON cf.YearMonth = ld.YearMonth
    AND cf.Channel = ld.Channel
    AND cf.Region = ld.Region
LEFT JOIN (
    -- LeadScore
    SELECT 
        bdc.NewMarketingRegion AS Region,
        bdc.Channel,
        SUM(bdlp.Revenue8Y_LTV_New) AS LTV_LeadScore,
        COUNT(scl.RealCID) AS Users_LeadScore
    FROM BI_DB_dbo.BI_DB_KYC_Score_CID_Level scl
    INNER JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdc 
        ON scl.RealCID = bdc.CID 
        AND bdc.FirstDepositDate IS NOT NULL
    INNER JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual bdlp 
        ON scl.RealCID = bdlp.CID 
        AND bdlp.Revenue8Y_LTV_New IS NOT NULL
    WHERE bdc.FirstDepositDate >= DATEADD(MONTH, -7, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
      AND scl.Cluster != 'No Cluster'
    GROUP BY bdc.NewMarketingRegion, bdc.Channel
) ls 
    ON ISNULL(cf.Region, ld.Region) = ls.Region 
    AND ISNULL(cf.Channel, ld.Channel) = ls.Channel