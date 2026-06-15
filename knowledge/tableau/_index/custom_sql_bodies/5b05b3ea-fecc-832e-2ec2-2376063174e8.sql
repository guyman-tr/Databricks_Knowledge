SELECT
    y.*,
    COALESCE(x.Amount, 0) AS [Compensation Added],
	y.TotalValueToTransfer - x.Amount AS Difference
FROM (
    SELECT 
        a.Date,
        a.CID,
        
        SUM(a.[Units to be transferred] * a.Price * a.InitConversionRate) AS TotalValueToTransfer
        
    FROM (
        SELECT 
            CAST(dp.OpenOccurred AS DATE) AS Date,
            dp.CID,
            di.ISINCode,
            di.InstrumentDisplayName,
            dp.InitialUnits,
            dp.HedgeServerID,
            di.InstrumentType,
            dp.InitialAmountCents / 100 AS InitalAmount,
            dp.InitForexRate AS Price,
            FLOOR(dp.InitialUnits) AS [Units to be transferred],
            fsc.IsCreditReportValidCB,
            dp.PositionID,
            dp.InitForexRate,
            dp.InitConversionRate
        FROM DWH_dbo.Dim_Position dp
        JOIN DWH_dbo.Dim_Instrument di
            ON dp.InstrumentID = di.InstrumentID
        JOIN DWH_dbo.Fact_SnapshotCustomer fsc
            ON dp.CID = fsc.RealCID
        JOIN DWH_dbo.Dim_Range dr
            ON fsc.DateRangeID = dr.DateRangeID
           AND dp.OpenDateID BETWEEN dr.FromDateID AND dr.ToDateID
        WHERE CAST(dp.OpenOccurred AS DATE)
              BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]>
          AND dp.OpenPositionReasonID = 13
          AND fsc.IsValidCustomer = 1
    ) a
	WHERE a.ISINCode is not null
    GROUP BY
        a.Date,
        a.CID
        
) y
LEFT JOIN (
    SELECT
        CONVERT(date, CONVERT(char(8), fca.DateID)) AS Date,
        fca.RealCID,
        fca.PositionID,
        SUM(fca.Amount) AS Amount
    FROM DWH_dbo.Fact_CustomerAction fca
    JOIN DWH_dbo.Fact_SnapshotCustomer fsc
        ON fca.RealCID = fsc.RealCID
    JOIN DWH_dbo.Dim_Range dr
        ON fsc.DateRangeID = dr.DateRangeID
       AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
    WHERE fca.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') AS INT)
                          AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') AS INT)
      AND fca.Amount >= 0
      AND fca.ActionTypeID = 36
      AND fca.CompensationReasonID = 120
      AND fsc.IsCreditReportValidCB = 1
    GROUP BY
        CONVERT(date, CONVERT(char(8), fca.DateID)),
        fca.RealCID,
        fca.PositionID
) x
on x.RealCID = y.CID
AND x.Date = y.Date