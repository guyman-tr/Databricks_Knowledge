SELECT 
    da.AffiliateID,
    da.AffiliatesGroupsName,
    da.Contact, 
    dc1.MarketingRegionManualName, 
    dc1.Name country,
    DATEDIFF(DAY, GETDATE(), EOMONTH(GETDATE())) EOMdays,
    DATEDIFF(DAY, DATEADD(m, DATEDIFF(m, 0, GETDATE()), 0), GETDATE()) SOMdays,
    da.Channel, 
    da.SubChannel,
    -- ספירת רישומים - ללא שינוי כדי לא לפגוע בנתוני ההרשמות
    SUM(CASE WHEN MONTH(dc.RegisteredReal) = MONTH(GETDATE()) AND YEAR(dc.RegisteredReal) <> '1900' THEN 1 ELSE 0 END) RegThisMonth,
    SUM(CASE WHEN MONTH(dc.RegisteredReal) = MONTH(DATEADD(m, -1, GETDATE())) AND YEAR(dc.RegisteredReal) <> '1900' THEN 1 ELSE 0 END) RegLastMonth,
    
    -- ספירת הפקדות עם החרגה של ה-22 במאי 2026 וסכום של 1$
    SUM(CASE 
            WHEN MONTH(dc.FirstDepositDate) = MONTH(GETDATE()) 
            AND YEAR(dc.FirstDepositDate) <> '1900' 
            AND NOT (CAST(dc.FirstDepositDate AS DATE) = '2026-05-22' AND dc.FirstDepositAmount = 1) 
            THEN 1 ELSE 0 END) FTDThisMonth,
            
    SUM(CASE 
            WHEN MONTH(dc.FirstDepositDate) = MONTH(DATEADD(m, -1, GETDATE())) 
            AND YEAR(dc.FirstDepositDate) <> '1900' 
            AND NOT (CAST(dc.FirstDepositDate AS DATE) = '2026-05-22' AND dc.FirstDepositAmount = 1) 
            THEN 1 ELSE 0 END) FTDLastMonth

FROM DWH_dbo.Dim_Affiliate da 
JOIN DWH_dbo.Dim_Customer dc ON da.AffiliateID = dc.AffiliateID
JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
WHERE dc.IsValidCustomer = 1
AND (
    dc.RegisteredReal >= CAST(DATEADD(m, -2, DATEADD(m, DATEDIFF(m, 0, GETDATE()), 0)) AS DATE)
    OR dc.FirstDepositDate >= CAST(DATEADD(m, -2, DATEADD(m, DATEDIFF(m, 0, GETDATE()), 0)) AS DATE)
)
GROUP BY 
    da.AffiliateID,
    da.AffiliatesGroupsName,
    da.Contact, 
    dc1.MarketingRegionManualName, 
    dc1.Name,
    da.Channel, 
    da.SubChannel