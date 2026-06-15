SELECT
  dp.[AllowDisplayFullName],
  dp.[AvgerageHoldingTime],
  dp.[BIO_Len],
  dp.[BlockReason],
  dp.[BuyPercent],
  pos.[CID]                    AS [CID (Custom SQL Query)],
  g.[CID]                     AS [CID (Custom SQL Query1)],
  dp.[CID],
  dp.[Classification],
  dp.[Club],
  dp.[CopyAUC],
  dp.[CopyPnL],
  dp.[CopyType],
  dp.[Country],
  dp.[Credit],
  dp.[DateID],
  dp.[Date],
  dp.[DaysAsPI],
  dp.[Gain_MTD],
  g.[Gain_MTD_Today],
  dp.[Gain_QTD],
  dp.[Gain_YTD],
  ISNULL(g.[Gain_YTD_Today], 0) AS [Gain_YTD_Today],
  g.[Gain_YTD_Yesterday],
  dp.[Gender],
  dp.[GuruStatusID],
  dp.[GuruStatus],
  dp.[HasAvatar],
  dp.[HighLevHoldingDetail],
  dp.[HoldsHighLevPosition],
  pos.[InstrumentID],
  dp.[IsPrivate],
  dp.[Language],
  dp.[Largest_Asset_Class],
  dp.[LastBlockedDate],
  dp.[Last_Day_Performance],
  pos.[Lev_weighted_average]   AS [Lev_weighted_average (Custom SQL Query)],
  dp.[Lev_weighted_average],
  dp.[MI],
  dp.[MO],
  dp.[Manager],
  dp.[MonthsSinceFirstOpen],
  dp.[NetMI],
  dp.[NumOfCopiers],
  dp.[PlayerStatus],
  dp.[PortfolioType],
  dp.[PositionPnL],
  pos.[Position_Value],
  dp.[PreviousGuruStatus],
  dp.[RealizedEquity],
  dp.[Region],
  dp.[Regulation],
  dp.[RiskScore],
  dp.[SellPercent],
  dp.[Seniority],
  pos.[SymbolFull],
  dp.[Top3TradedIndustries],
  dp.[Top_3_Traded_Instruments],
  dp.[TotalDaysInCurrentStatus],
  dp.[TotalEquity],
  dp.[TotalPositionsAmount],
  dp.[TraderType],
  dp.[Trades],
  dp.[UpdateDate],
  dp.[UserName],
  pos.[Value_percenet]         AS [Value_percenet (Custom SQL Query)],
  dp.[Value_percenet]

FROM BI_DB_dbo.BI_DB_DailyPanel_Copy dp

LEFT JOIN (
  SELECT
      CID,
      InstrumentID,
      SymbolFull,
      Position_Value,
      Value_percenet,
      Lev_weighted_average
  FROM (
    SELECT
        ps.CID,
        ps.InstrumentID,
        ps.SymbolFull,
        ps.Position_Value,
        ps.Lev_weighted_average,
        ps.Position_Value / NULLIF(SUM(ps.Position_Value) OVER (PARTITION BY ps.CID) + vl.Credit, 0) AS Value_percenet,
        ROW_NUMBER() OVER (PARTITION BY ps.CID ORDER BY ps.Position_Value DESC) AS rn
    FROM (
      SELECT
          pp.CID,
          pp.InstrumentID,
          di.SymbolFull,
          SUM(pp.Amount + pp.PositionPnL)                                           AS Position_Value,
          COALESCE(SUM(pp.Leverage * pp.Amount) / NULLIF(SUM(pp.Amount), 0), 0)     AS Lev_weighted_average
      FROM BI_DB_dbo.BI_DB_PositionPnL pp WITH (NOLOCK)
      JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK)
        ON di.InstrumentID = pp.InstrumentID
      WHERE pp.DateID = CAST(CONVERT(VARCHAR(8), GETDATE() - 1, 112) AS INT)
      GROUP BY pp.CID, pp.InstrumentID, di.SymbolFull
    ) ps
    LEFT JOIN DWH_dbo.V_Liabilities vl WITH (NOLOCK)
      ON ps.CID = vl.CID
     AND vl.DateID = CAST(CONVERT(VARCHAR(8), GETDATE() - 1, 112) AS INT)
  ) ranked
  WHERE rn = 1
) pos ON dp.[CID] = pos.[CID]

LEFT JOIN (
  SELECT
      g.CID,
      MAX(CASE WHEN g.MaxDate = CAST(GETDATE() AS DATE) AND g.IntervalTypeID = 101 THEN g.Gain END) AS Gain_MTD_Today,
      MAX(CASE WHEN g.MaxDate = CAST(GETDATE() AS DATE) AND g.IntervalTypeID = 103 THEN g.Gain END) AS Gain_YTD_Today,
      MAX(CASE WHEN g.MaxDate = CAST(GETDATE() - 1 AS DATE) AND g.IntervalTypeID = 103 THEN g.Gain END) AS Gain_YTD_Yesterday
  FROM [BI_DB_dbo].[External_TradeGain_Ranking_Compound_Gain_Completed] g
  INNER JOIN [BI_DB_dbo].[External_TradeGain_Ranking_Execution] re
    ON g.ExecutionID = re.ExecutionID
  WHERE g.IntervalTypeID IN (101, 103)
    AND re.ObjectID = 4
    AND g.ExecutionID >= (
        SELECT MAX(ExecutionID)
        FROM [BI_DB_dbo].[External_TradeGain_Ranking_Execution]
        WHERE Completed = 1
          AND ObjectID = 4
          AND MaxDate <= DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
    )
    AND g.Gain <> 0
    AND g.MaxDate >= CAST(GETDATE() - 1 AS DATE)
  GROUP BY g.CID
) g ON dp.[CID] = g.[CID]

WHERE dp.[Date] = CAST(GETDATE() - 1 AS DATE)