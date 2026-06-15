SELECT
    CAST(a.[Date] AS DATE) AS Occurred_Date,
    c.Name                  AS CountryName,
    SUM(CASE WHEN a.MIMOAction = 'Deposit'  THEN a.AmountUSD ELSE 0 END) AS Deposit_From_External_USD,
    SUM(CASE WHEN a.MIMOAction = 'Withdraw' THEN a.AmountUSD ELSE 0 END) AS Withdraw_To_External_USD
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms a
INNER JOIN DWH_dbo.Dim_Customer dc
    ON a.RealCID = dc.RealCID
INNER JOIN DWH_dbo.Dim_Country c
    ON dc.CountryID = c.CountryID
WHERE dc.AccountTypeID = 17
  AND dc.IsValidCustomer = 1
  AND a.MIMOAction IN ('Deposit', 'Withdraw')
  AND a.IsInternalTransfer = 0
  AND a.IsIBANQuickTransfer = 0
  AND a.IsTradeFromIBAN = 0
  AND a.IsCryptoToFiat = 0
  AND a.MIMOPlatform IN ('eMoney', 'TradingPlatform')
  AND CAST(a.[Date] AS DATE) >=
        CASE
            WHEN DATEADD(YEAR, -1, CAST(GETDATE() AS DATE)) < '2025-11-01'
                THEN '2025-11-01'
            ELSE DATEADD(YEAR, -1, CAST(GETDATE() AS DATE))
        END
GROUP BY
    CAST(a.[Date] AS DATE),
    c.Name