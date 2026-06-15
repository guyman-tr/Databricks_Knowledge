SELECT 
    a.Date, 
    a.CID, 
    a.ISINCode, 
    a.InstrumentDisplayName, 
    a.HedgeServerID, 
    a.InitialUnits, 
    a.InitalAmount, 
    a.[Units to be transferred], 
    a.IsCreditReportValidCB, 
    a.Price,
    a.PositionID, 
    SUM(a.[Units to be transferred] * a.Price* a.InitConversionRate) AS [TotalValueToTransfer], 
	a.InitForexRate,
	a.InitConversionRate,
	InstrumentType
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
    JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID --AND di.InstrumentTypeID IN (5,6)
    JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON dp.CID = fsc.RealCID
    JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID 
        AND dp.OpenDateID BETWEEN dr.FromDateID AND dr.ToDateID
    WHERE CAST(dp.OpenOccurred AS DATE) 
          BETWEEN <[Parameters].[Parameter 1]>
          AND <[Parameters].[Parameter 2]>
          AND dp.OpenPositionReasonID = 13
          --AND dp.IsSettled = 1
          AND fsc.IsValidCustomer = 1
          --AND fsc.IsDepositor = 1
    GROUP BY 
        dp.OpenOccurred, 
        dp.CID, 
        di.ISINCode, 
        di.InstrumentDisplayName, 
        dp.HedgeServerID, 
        dp.InitialUnits, 
        dp.InitialAmountCents, 
        dp.AmountInUnitsDecimal, 
        dp.InitForexRate, 
        dp.InitConversionRate,
        fsc.IsCreditReportValidCB, 
        dp.PositionID,
		di.InstrumentType
) a
GROUP BY 
    a.Date, 
    a.CID, 
    a.ISINCode, 
    a.InstrumentDisplayName, 
    a.HedgeServerID, 
    a.InitialUnits, 
    a.InitalAmount, 
    a.[Units to be transferred], 
    a.IsCreditReportValidCB, 
    a.Price,
    a.PositionID,
	a.InitForexRate,
    a.InitConversionRate,
	a.InstrumentType