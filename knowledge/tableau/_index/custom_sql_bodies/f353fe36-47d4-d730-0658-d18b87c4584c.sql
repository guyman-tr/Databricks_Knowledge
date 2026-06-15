SELECT  
    a.[Period],
    a.InstrumentType,
    a.IsSettled,
    a.Region,
    a.Club,
    a.[FTD Year],
    a.Metric,
    a.DateID,
    CONVERT(DATE, CONVERT(VARCHAR(8), a.DateID), 112) AS Date,
    SUM(a.Amount) AS Amount
FROM 
(
    SELECT 
        'SameDay8Weeks' AS [Period],
        InstrumentType,
        IsSettled,
        Region,
        Club,
        [FTD Year],
        Metric,
        Amount,
        DateID,
        CONVERT(DATE, CONVERT(VARCHAR(8), DateID), 112) AS Date
    FROM 
    (
        SELECT 
            InstrumentType,
            IsSettled,
            Region,
            Club,
            [FTD Year],
            DateID,
            SUM(Commissions) AS Commissions,
            SUM(FullCommissions) AS FullCommissions,
            SUM(RollOverFee) AS RollOverFee,
            SUM(TicketFee) AS TicketFee,
            SUM(TicketFeeByPercent) AS TicketFeeByPercent,
            SUM(AdminFee) AS AdminFee,
            SUM(SpotAdjustFee) AS SpotAdjustFee,
            SUM(ISNULL(VolumeOnOpen,0) + ISNULL(VolumeOnClose,0)) AS Volume,
            SUM(Filtered.InvestedAmountOpen) AS InvestedAmountOpen
        FROM 
        (
            SELECT ia.*
            FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg ia
            WHERE 
                IsValidCustomer = 1
                AND ((DATEPART(WEEKDAY, ia.FullDate) + @@DATEFIRST - 1) % 7) + 1 
                    = ((DATEPART(WEEKDAY, GETDATE() - 1) + @@DATEFIRST - 1) % 7) + 1
                AND DATEDIFF(WEEK, ia.FullDate, GETDATE() - 1) <= 8
        ) AS Filtered
        GROUP BY 
            InstrumentType,
            IsSettled,
            Region,
            Club,
            [FTD Year],
            Filtered.DateID
    ) AS Aggregated
    UNPIVOT (
        Amount FOR Metric IN (
            Commissions,
            FullCommissions,
            RollOverFee,
            TicketFee,
            TicketFeeByPercent,
            AdminFee,
            SpotAdjustFee,
            Volume,
            Aggregated.InvestedAmountOpen
        )
    ) AS unpvt
) a
GROUP BY 
    a.[Period],  
    a.Metric, 
    a.InstrumentType, 
    a.IsSettled, 
    a.Region, 
    a.Club, 
    a.[FTD Year], 
    a.DateID, 
    CONVERT(DATE, CONVERT(VARCHAR(8), a.DateID), 112)