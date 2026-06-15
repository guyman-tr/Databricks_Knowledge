SELECT 
    BaseMIMO.Date,
    BaseMIMO.Year_Month,
    BaseMIMO.Deposits,
    BaseMIMO.Withdraw - BaseMIMO.TransferCoins - ISNULL(Compensations.Compensation, 0) AS CashoutsAdjusted,
    CAST(GETDATE() AS DATE) AS LoadDate
FROM (
    SELECT 
        EOMONTH(b.Date) AS Date,
        YEAR(b.Date) * 100 + MONTH(b.Date) AS Year_Month,
        SUM(CASE WHEN b.MIMOAction = 'Deposit' THEN b.AmountUSD ELSE 0 END) AS Deposits,
        SUM(CASE WHEN b.MIMOAction = 'Withdraw' THEN b.AmountUSD ELSE 0 END) AS Withdraw,
        SUM(CASE WHEN b.IsRedeem = 1 THEN b.AmountUSD ELSE 0 END) AS TransferCoins
    FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform b
    INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
        ON b.RealCID = fsc.RealCID
    INNER JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
        ON fsc.DateRangeID = dr.DateRangeID
        AND b.DateID BETWEEN dr.FromDateID AND dr.ToDateID
    WHERE 
        b.DateID BETWEEN 20220101 AND CAST(FORMAT(GETDATE()-1, 'yyyyMMdd') AS INT)
        AND fsc.IsValidCustomer = 1
				AND ISNULL(IsIBANTrade,0) = 0
    GROUP BY 
        EOMONTH(b.Date),
        YEAR(b.Date) * 100 + MONTH(b.Date)
) AS BaseMIMO
LEFT JOIN (
    SELECT 
        EOMONTH(nra.Date) AS Date,
        YEAR(nra.Date) * 100 + MONTH(nra.Date) AS Year_Month,
        SUM(ISNULL(nra.CompensationPIWithCashoutAmount, 0) + ISNULL(nra.CompensationToAffiliateWithCashoutAmount, 0)) AS Compensation
    FROM BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions nra
    INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
        ON nra.RealCID = fsc.RealCID
    INNER JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
        ON fsc.DateRangeID = dr.DateRangeID
        AND nra.DateID BETWEEN dr.FromDateID AND dr.ToDateID
    WHERE 
        nra.DateID BETWEEN 20220101 AND CAST(FORMAT(GETDATE()-1, 'yyyyMMdd') AS INT)
        AND fsc.IsValidCustomer = 1
    GROUP BY 
        EOMONTH(nra.Date),
        YEAR(nra.Date) * 100 + MONTH(nra.Date)
) AS Compensations
ON BaseMIMO.Date = Compensations.Date