SELECT 
    c.FiscalYearQtr,
    c.EndOfQuarter AS [Date],
    CASE WHEN c.ClubTier='Bronze' THEN 'Non-Club' ELSE 'Club' END AS 'UserType',
    c.ClubTier,
    c.IsEOM_Funded_NEW,
    SUM(fm.NewTrades_Total) AS Trades,
    SUM(fm.TotalDeposits) AS Deposits,
    SUM(fm.CountDeposits) AS NumberOfDeposits,
    COUNT(DISTINCT fm.CID) AS Users,
    ISNULL(r.Revenue, 0) AS Revenue
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData fm WITH (NOLOCK)
JOIN #cid c 
ON fm.CID = c.CID AND fm.ActiveDate >= c.StartOfQuarter AND fm.ActiveDate <= c.StartOfLastMonthInQuarter
LEFT JOIN #revenue r 
ON c.YearQuarter = r.YearQuarter AND c.ClubTier = r.ClubTier AND c.IsEOM_Funded_NEW = r.IsEOM_Funded_NEW
WHERE fm.ActiveDate >= '20220101'
GROUP BY c.FiscalYearQtr, c.EndOfQuarter, c.ClubTier, c.IsEOM_Funded_NEW, r.Revenue,CASE WHEN c.ClubTier='Bronze' THEN 'Non-Club' ELSE 'Club' END