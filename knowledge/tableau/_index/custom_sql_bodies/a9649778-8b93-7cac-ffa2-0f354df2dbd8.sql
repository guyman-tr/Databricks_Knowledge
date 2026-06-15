SELECT CountryOfResidence, Regulation, VerificationLevel, InstrumentType, Is_Settled,
YearMonth
, p.ExecutionType
,COUNT(DISTINCT CASE WHEN COALESCE(IsPartialCloseChild,0) = 0 AND p.OpenDateID > <[Parameters].[Parameter 1]> AND p.OpenDateID <= <[Parameters].[Parameter 2]> THEN p.PositionID END) AS OpenedPositions 
,ISNULL(SUM(CASE WHEN COALESCE(IsPartialCloseChild,0) = 0 AND p.OpenDateID > <[Parameters].[Parameter 1]>AND p.OpenDateID <= <[Parameters].[Parameter 2]> THEN Buy_Volume END),0) AS BuyVolume
,ISNULL(SUM(CASE WHEN p.OpenDateID > <[Parameters].[Parameter 1]> AND p.OpenDateID <= <[Parameters].[Parameter 2]> AND p.CloseDateID != 0 THEN p.Sell_Volume
WHEN p.CloseDateID > <[Parameters].[Parameter 1]> AND p.CloseDateID <= <[Parameters].[Parameter 2]> AND p.OpenDateID < <[Parameters].[Parameter 1]> THEN p.Sell_Volume END),0) AS SellVolume
,SUM(p.FullCommission) AS TotalCommission
FROM #pos p
JOIN #pop p1 ON p1.CID = p.CID
GROUP BY CountryOfResidence, Regulation, VerificationLevel, InstrumentType, YearMonth, p.ExecutionType, Is_Settled