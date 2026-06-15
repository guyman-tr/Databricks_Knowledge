SELECT bdcd.CID    
        ,bdcd.FirstNewFundedDate
        ,bdfa.Revenue14days
        ,bdfa.Deposit14days
        ,bdcd.FirstDepositAmount
        ,bdfa.Equity14days
        ,CASE WHEN bdfa.Equity14days = 0 THEN 0 ELSE 1 END AS Funded14days
        ,CASE WHEN bdfa.FirstCrossDate <= DATEADD(DAY,14,bdcd.FirstNewFundedDate) THEN 1 ELSE 0 END AS Cross14days
        ,CASE WHEN bdfa.SecondActionDate <= DATEADD(DAY,14,bdcd.FirstNewFundedDate) THEN 1 ELSE 0 END AS SecondAction14days
        ,bdfa.SecondActionDate
        ,bdfa.FirstAction
        ,bdcd.NewMarketingRegion
        ,bdcd.Gender
        ,bdcd.Channel
        ,bdcd.SubChannel
FROM BI_DB_dbo.BI_DB_First5Actions bdfa
JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd
ON bdfa.CID = bdcd.CID
WHERE CAST(bdcd.FirstNewFundedDate AS DATE) >= CAST(DATEADD(MONTH,-12,GETDATE()) AS DATE)
AND bdcd.Region <> 'Unknown'
AND bdcd.Channel NOT IN ('Club', 'Events', 'Sponsorships', 'Productions', 'OOH', 'PR', 'TV', 'systems', 'Social Organic')