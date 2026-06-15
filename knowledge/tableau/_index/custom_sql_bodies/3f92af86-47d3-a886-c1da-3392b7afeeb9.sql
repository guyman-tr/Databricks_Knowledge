SELECT
    CONVERT(date, CAST(v.DateID AS char(8)))                              AS [Date],
    c.Name                                                        AS Country,
    SUM(ISNULL(v.TotalCash, 0))                                           AS TotalCash,
    SUM(
          ISNULL(v.TotalPositionsAmount, 0)
        + ISNULL(v.PositionPnL, 0)
        + ISNULL(v.TotalCash, 0)
    )                                                                     AS [UnrealizedEquity_(Position+PnL+Cash)]
FROM DWH_dbo.V_Liabilities v
INNER JOIN DWH_dbo.Dim_Customer b
    ON v.CID = b.RealCID
INNER JOIN DWH_dbo.Dim_Country c
    ON b.CountryID = c.CountryID
WHERE v.DateID >= 20251101
  AND v.DateID >= CONVERT(int, FORMAT(DATEADD(YEAR, -1, GETDATE()), 'yyyyMMdd'))
  AND v.DateID <= CONVERT(int, FORMAT(GETDATE(), 'yyyyMMdd'))
  AND b.IsValidCustomer = 1
  AND b.AccountTypeID = 17
GROUP BY
    v.DateID,
    c.Name