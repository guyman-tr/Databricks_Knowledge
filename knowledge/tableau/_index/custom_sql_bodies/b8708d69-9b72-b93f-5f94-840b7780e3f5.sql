SELECT
    x.Traded_Instrument,
    x.Opened_Position_Amount,
    x.Number_Positions,
    ROW_NUMBER() OVER (ORDER BY x.Opened_Position_Amount DESC) AS rnk
FROM (
    SELECT
        i.InstrumentDisplayName        AS Traded_Instrument,
        SUM(p.Amount)                  AS Opened_Position_Amount,
        COUNT(p.PositionID)            AS Number_Positions
    FROM DWH_dbo.Dim_Position p
    JOIN DWH_dbo.Dim_Customer c
        ON p.CID = c.RealCID
    JOIN DWH_dbo.Dim_Instrument i
        ON p.InstrumentID = i.InstrumentID
    WHERE c.IsValidCustomer = 1
      AND c.AccountTypeID = 17
      AND (p.IsPartialCloseChild = 0 OR p.IsPartialCloseChild IS NULL)
      AND p.OpenDateID >= 20251101
    GROUP BY i.InstrumentDisplayName
) x