SELECT 
    a.PositionID,
    a.DateID,
    EOMONTH(a.[Date])        AS EOM,
    a.HedgeServerID,
    a.InstrumentType         AS InstrumentTypeName,
    a.InstrumentID,
    a.InstrumentName,
    a.Amount_OnOpen_USD,
    a.Amount_OnOpen_GBP,
    a.ISINCountryCode,
    a.ISINCode,
    a.Amount_OnOpen_USD * 0.005 AS Total_Stamp_Duty_USD,
    a.Amount_OnOpen_GBP * 0.005 AS Total_Stamp_Duty_GBP,
    -- FX debug
    a.FX_Rate_Used           AS GBP_USD_Bid,
    a.USD_Original,
    a.GBP_Computed
FROM (
    SELECT 
        dp.PositionID,
        dp.OpenDateID                     AS DateID,
        dp.OpenOccurred                   AS [Date],
        dp.HedgeServerID,
        di.ISINCountryCode,
        di.ISINCode,
        di.InstrumentType,
        di.InstrumentDisplayName,
        di.Name                           AS InstrumentName,
        di.InstrumentID,

        SUM(dp.InitialAmountCents/100.0)                                      AS Amount_OnOpen_USD,
        SUM((dp.InitialAmountCents/100.0) / cpws.Bid)                         AS Amount_OnOpen_GBP,
        AVG(cpws.Bid)                                                         AS FX_Rate_Used,
        SUM(dp.InitialAmountCents/100.0)                                      AS USD_Original,
        SUM((dp.InitialAmountCents/100.0) / cpws.Bid)                         AS GBP_Computed,
        dp.IsSettled,
        dr1.Name                                                               AS Regulation_on_open
    FROM DWH_dbo.Dim_Position dp
    JOIN DWH_dbo.Dim_Customer dc
         ON dc.RealCID = dp.CID
        AND dc.IsValidCustomer = 1 
        AND dc.IsDepositor = 1 
        AND dc.VerificationLevelID > 1
    JOIN DWH_dbo.Fact_SnapshotCustomer fsc
         ON fsc.RealCID = dp.CID
        AND fsc.IsValidCustomer = 1 
        AND fsc.VerificationLevelID > 1
    JOIN DWH_dbo.Dim_Regulation dr1
         ON dr1.DWHRegulationID = fsc.RegulationID
    JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK)
         ON di.InstrumentID = dp.InstrumentID
    LEFT JOIN DWH_dbo.Fact_CurrencyPriceWithSplit cpws
         ON cpws.OccurredDateID = dp.OpenDateID
        AND cpws.InstrumentID  = 2  -- GBP/USD

    WHERE 
        
        dp.OpenDateID >= <[Parameters].[Parameter 1]>
AND dp.OpenDateID < <[Parameters].[Parameter 2]>


        AND di.ISINCode IN (
          'BMG702782084','BG9000011163','BMG670131058','DK0060005684','GI000A0F6407',
          'JP3158300008','KYG368851047','KYG7306P1037','KYG9507A1094','KYG5897M2243',
          'KYG5897M1419','IL0010922388','LU0686550053','KYG5897M1179','KYG5897M1740',
          'KYG5897M2326','US00510N1028','US00510N1101','SG9999015747','USU5500L1128',
          'VGG3084F1282','VGG017801082','VGG1472N1179','ZAE000255360','VGG5877D1033',
          'VGG379591065','VGG9520B1004','VGG203461055','USU5500L1045','VGG0697K1066',
          'VGG636111004','VGG5878H1038'
        )
        AND ISNULL(dp.IsPartialCloseChild,0) = 0
        AND cpws.Bid IS NOT NULL
    GROUP BY 
        dp.PositionID,
        dp.OpenDateID,
        dp.OpenOccurred,
        dp.HedgeServerID,
        di.ISINCountryCode,
        di.InstrumentDisplayName,
        di.InstrumentID,
        di.ISINCode,
        dp.IsSettled,
        dr1.Name,
        di.Name,
        di.InstrumentType
) a