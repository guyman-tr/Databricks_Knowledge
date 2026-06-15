SELECT  bdduftp.Date
       ,bdduftp.AffiliateID
       ,bdduftp.CID
       ,bdduftp.Channel
       ,bdduftp.SubChannel
       ,bdduftp.SubAffiliateID
       ,bdduftp.Desk
       ,bdduftp.Region
       ,bdduftp.Country
       ,bdduftp.State
       ,bdduftp.Regulation
       ,bdduftp.DesignatedRegulation
       ,bdduftp.FunnelFrom
       ,bdduftp.Platform
       ,bdduftp.Install
       ,bdduftp.Registration
       ,bdduftp.EmailVerification
       ,bdduftp.VerificationLevel1
       ,bdduftp.VerificationLevel2
       ,bdduftp.DepositView
       ,bdduftp.DepositSubmits
       ,bdduftp.DepositSubmitClick
       ,bdduftp.VerificationLevel3
       ,bdduftp.DepositAttDB
       ,bdduftp.FTD AS All_FTD
       -- תיקון: החרגת 1$ רק בתאריך הספציפי
       ,CASE 
            WHEN CAST(bdduftp.Date AS DATE) = '2026-05-22' AND dmc.FirstDepositAmount = 1 THEN 0 
            ELSE bdduftp.FTD 
        END AS FTD
       ,bdduftp.OpenTrade
       ,bdduftp.UpdateDate
       ,bdduftp.Platform_fromAction_Regs
       ,bdduftp.Platform_fromAction_FTD
       ,bdduftp.PhoneVerification
       ,bdduftp.EvMatchStatus
       ,bdduftp.KYCFlow
       ,bdduftp.FirstNewFunded
       ,bdduftp.FirstAction
       ,bdduftp.SecondAction
       ,bdduftp.FirstCross
       ,bdduftp.FirstDemoTrade
       ,bdduftp.FirstActionType,
        kyc.KYCFlow_New,
        dc.MarketingRegionManualName,
        bdcd.Language, 
        bdkscl.Cluster,
        dc.RiskGroupID,
        YEAR(bdcd.registered) AS RegisteredYear,
        CAST(bdcd.FirstDepositAmount AS INT) All_FTDA,
        -- תיקון: החרגת סכום ההפקדה רק בתאריך הספציפי
        CAST(CASE 
            WHEN CAST(bdduftp.Date AS DATE) = '2026-05-22' AND dmc.FirstDepositAmount = 1 THEN 0 
            ELSE dmc.FirstDepositAmount 
        END AS INT) AS FTDA,
        
        CASE WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) <= 24 THEN '18-24'  
             WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 25 AND 34 THEN '25-34'  
             WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 35 AND 44 THEN '35-44'  
             WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 45 AND 54 THEN '45-54'  
             WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) >= 55 THEN '55+'  
             ELSE NULL END AS Age_Group,
        ISNULL(bdcd.Gender,'M') Gender,

        CASE  
             WHEN bdduftp.Channel LIKE '%Affiliate%' THEN 'Affiliate'
             WHEN bdduftp.Channel LIKE '%Direct%' THEN 'Direct'
             WHEN bdduftp.Channel LIKE '%Friend Referral%' THEN 'Friend Referral'
             WHEN bdduftp.Channel LIKE '%Media Performance%' THEN 'Media Performance'
             WHEN bdduftp.Channel LIKE '%Media Programmatic%' THEN 'Media Programmatic'
             WHEN bdduftp.Channel LIKE '%Mobile Acquisition%' THEN 'Mobile Acquisition'
             WHEN bdduftp.Channel LIKE '%SEM%' THEN 'SEM'
             WHEN bdduftp.Channel LIKE '%SEO%' THEN 'SEO'
        ELSE 'Other' END AS Channel_Group ,
        r.Total_FTDA,
        fa.FirstInstrument,
        ftdp.FTDPlatformName,

        MAX(bdduftp.Registration) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS Reg_this_week,
        MAX(bdduftp.VerificationLevel1) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS V1_this_week,
        MAX(bdduftp.VerificationLevel2) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS V2_this_week,
        MAX(bdduftp.VerificationLevel3) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS V3_this_week,
        MAX(bdduftp.DepositAttDB) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS DeppAtt_this_week,
        MAX(bdduftp.FTD) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS All_FTD_this_week,
        -- תיקון ב-Window Function שבועי
        MAX(CASE WHEN CAST(bdduftp.Date AS DATE) = '2026-05-22' AND dmc.FirstDepositAmount = 1 THEN 0 ELSE bdduftp.FTD END) 
            OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS FTD_this_week,
        
        MAX(bdduftp.FirstDemoTrade) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS FirstDemoTrade_this_week,
        MAX(bdduftp.FirstNewFunded) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS FirstNewFunded_this_week,
        MAX(bdduftp.FirstAction) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS FirstAction_this_week,
        MAX(bdduftp.SecondAction) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS SecondAction_this_week,
        MAX(bdduftp.FirstCross) OVER (PARTITION BY bdduftp.CID, DATEPART(WEEK,bdduftp.Date)) AS FirstCross_this_week,

        MAX(bdduftp.Registration) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS Reg_this_MONTH,
        MAX(bdduftp.VerificationLevel1) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS V1_this_MONTH,
        MAX(bdduftp.VerificationLevel2) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS V2_this_MONTH,
        MAX(bdduftp.VerificationLevel3) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS V3_this_MONTH,
        MAX(bdduftp.DepositAttDB) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS DeppAtt_this_MONTH,
        MAX(bdduftp.FTD) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS All_FTD_this_MONTH,
        -- תיקון ב-Window Function חודשי
        MAX(CASE WHEN CAST(bdduftp.Date AS DATE) = '2026-05-22' AND dmc.FirstDepositAmount = 1 THEN 0 ELSE bdduftp.FTD END) 
            OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS FTD_this_MONTH,
        
        MAX(bdduftp.FirstDemoTrade) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS FirstDemoTrade_this_MONTH,
        MAX(bdduftp.FirstNewFunded) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS FirstNewFunded_this_MONTH,
        MAX(bdduftp.FirstAction) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS FirstAction_this_MONTH,
        MAX(bdduftp.SecondAction) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS SecondAction_this_MONTH,
        MAX(bdduftp.FirstCross) OVER (PARTITION BY bdduftp.CID, DATEPART(MONTH,bdduftp.Date)) AS FirstCross_this_MONTH,
        
        bdcd.Verified, 
        CASE WHEN bdcd.VerificationLevel1Date IS NOT NULL THEN 1 ELSE 0 END AS VerificationLevel1_Filter,
        CASE WHEN bdcd.VerificationLevel2Date IS NOT NULL THEN 1 ELSE 0 END AS VerificationLevel2_Filter,
        CASE WHEN bdcd.VerificationLevel3Date IS NOT NULL THEN 1 ELSE 0 END AS VerificationLevel3_Filter,
        opt.ConsentStatusID as OptedIn

FROM BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints bdduftp
JOIN BI_DB_dbo.BI_DB_CIDFirstDates  bdcd ON bdduftp.CID = bdcd.CID
JOIN DWH_dbo.Dim_Customer as dmc ON dmc.RealCID = bdcd.CID AND dmc.IsValidCustomer =1 AND PlayerStatusID IN (1,5,13)
LEFT JOIN DWH_dbo.Dim_Country  dc ON dc.Name=bdduftp.Country
LEFT JOIN BI_DB_dbo.BI_DB_KYC_Score_CID_Level bdkscl ON bdkscl.RealCID = bdduftp.CID
LEFT JOIN #kyc as kyc on kyc.CID = bdduftp.CID 
LEFT JOIN #optin as opt on bdduftp.CID = opt.CID
LEFT JOIN DWH_dbo.Dim_FTDPlatform AS ftdp ON dmc.FTDPlatformID = ftdp.FTDPlatformID

----Add unique FTDA----
LEFT JOIN (
SELECT bdcd.CID
      ,CAST(bdcd.FirstDepositDate AS DATE) AS FirstDepositDate
      ,bdcd.FirstDepositAmount AS Total_FTDA
      ,CASE WHEN bdcd.FirstDepositDate IS NOT NULL THEN 1 ELSE 0 END AS FTD_this_week
FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
) r
    ON bdduftp.CID = r.CID AND r.FirstDepositDate=bdduftp.Date
------------------------

----Add unique FirstInstrument----
LEFT JOIN (
SELECT f5ac.CID
      ,CAST(f5ac.FirstActionDate AS DATE) AS FirstActionDate
      ,f5ac.FirstInstrument AS FirstInstrument
FROM [BI_DB_dbo].[BI_DB_First5Actions] f5ac 
) fa
    ON bdduftp.CID = fa.CID 
------------------------

WHERE bdduftp.Date>=CAST(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -6,GETDATE())), 0) AS DATE)
AND bdcd.Region <> 'Unknown'