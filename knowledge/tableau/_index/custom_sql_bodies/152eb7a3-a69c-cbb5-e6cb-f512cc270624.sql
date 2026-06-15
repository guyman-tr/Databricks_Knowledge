SELECT [BI_DB_DailyPanel_Copy].[AllowDisplayFullName] AS [AllowDisplayFullName],
  [BI_DB_DailyPanel_Copy].[AvgerageHoldingTime] AS [AvgerageHoldingTime],
  [BI_DB_DailyPanel_Copy].[BIO_Len] AS [BIO_Len],
  [BI_DB_DailyPanel_Copy].[BlockReason] AS [BlockReason],
  [BI_DB_DailyPanel_Copy].[BuyPercent] AS [BuyPercent],
  [Custom SQL Query].[CID] AS [CID (Custom SQL Query)],
  [Gain].[CID] AS [CID (Custom SQL Query1)],
  [BI_DB_DailyPanel_Copy].[CID] AS [CID],
  [BI_DB_DailyPanel_Copy].[Classification] AS [Classification],
  [BI_DB_DailyPanel_Copy].[Club] AS [Club],
  [BI_DB_DailyPanel_Copy].[CopyAUC] AS [CopyAUC],
  [BI_DB_DailyPanel_Copy].[CopyPnL] AS [CopyPnL],
  [BI_DB_DailyPanel_Copy].[CopyType] AS [CopyType],
  [BI_DB_DailyPanel_Copy].[Country] AS [Country],
  [BI_DB_DailyPanel_Copy].[Credit] AS [Credit],
  [BI_DB_DailyPanel_Copy].[DateID] AS [DateID],
  [BI_DB_DailyPanel_Copy].[Date] AS [Date],
  [BI_DB_DailyPanel_Copy].[DaysAsPI] AS [DaysAsPI],
  [BI_DB_DailyPanel_Copy].[Gain_MTD] AS [Gain_MTD],
  [Gain].[Gain_MTD_Today] AS [Gain_MTD_Today],
  [BI_DB_DailyPanel_Copy].[Gain_QTD] AS [Gain_QTD],
  [BI_DB_DailyPanel_Copy].[Gain_YTD] AS [Gain_YTD],
  ISNULL([Gain].[Gain_YTD_Today],0) AS [Gain_YTD_Today],
  [Gain].[Gain_YTD_Yesterday] AS [Gain_YTD_Yesterday],
  [BI_DB_DailyPanel_Copy].[Gender] AS [Gender],
  [BI_DB_DailyPanel_Copy].[GuruStatusID] AS [GuruStatusID],
  [BI_DB_DailyPanel_Copy].[GuruStatus] AS [GuruStatus],
  [BI_DB_DailyPanel_Copy].[HasAvatar] AS [HasAvatar],
  [BI_DB_DailyPanel_Copy].[HighLevHoldingDetail] AS [HighLevHoldingDetail],
  [BI_DB_DailyPanel_Copy].[HoldsHighLevPosition] AS [HoldsHighLevPosition],
  [Custom SQL Query].[InstrumentID] AS [InstrumentID],
  [BI_DB_DailyPanel_Copy].[IsPrivate] AS [IsPrivate],
  [BI_DB_DailyPanel_Copy].[Language] AS [Language],
  [BI_DB_DailyPanel_Copy].[Largest_Asset_Class] AS [Largest_Asset_Class],
  [BI_DB_DailyPanel_Copy].[LastBlockedDate] AS [LastBlockedDate],
  [BI_DB_DailyPanel_Copy].[Last_Day_Performance] AS [Last_Day_Performance],
  [Custom SQL Query].[Lev_weighted_average] AS [Lev_weighted_average (Custom SQL Query)],
  [BI_DB_DailyPanel_Copy].[Lev_weighted_average] AS [Lev_weighted_average],
  [BI_DB_DailyPanel_Copy].[MI] AS [MI],
  [BI_DB_DailyPanel_Copy].[MO] AS [MO],
  [BI_DB_DailyPanel_Copy].[Manager] AS [Manager],
  [BI_DB_DailyPanel_Copy].[MonthsSinceFirstOpen] AS [MonthsSinceFirstOpen],
  [BI_DB_DailyPanel_Copy].[NetMI] AS [NetMI],
  [BI_DB_DailyPanel_Copy].[NumOfCopiers] AS [NumOfCopiers],
  [BI_DB_DailyPanel_Copy].[PlayerStatus] AS [PlayerStatus],
  [BI_DB_DailyPanel_Copy].[PortfolioType] AS [PortfolioType],
  [BI_DB_DailyPanel_Copy].[PositionPnL] AS [PositionPnL],
  [Custom SQL Query].[Position_Value] AS [Position_Value],
  [BI_DB_DailyPanel_Copy].[PreviousGuruStatus] AS [PreviousGuruStatus],
  [BI_DB_DailyPanel_Copy].[RealizedEquity] AS [RealizedEquity],
  [BI_DB_DailyPanel_Copy].[Region] AS [Region],
  [BI_DB_DailyPanel_Copy].[Regulation] AS [Regulation],
  [BI_DB_DailyPanel_Copy].[RiskScore] AS [RiskScore],
  [BI_DB_DailyPanel_Copy].[SellPercent] AS [SellPercent],
  [BI_DB_DailyPanel_Copy].[Seniority] AS [Seniority],
  [Custom SQL Query].[SymbolFull] AS [SymbolFull],
  [BI_DB_DailyPanel_Copy].[Top3TradedIndustries] AS [Top3TradedIndustries],
  [BI_DB_DailyPanel_Copy].[Top_3_Traded_Instruments] AS [Top_3_Traded_Instruments],
  [BI_DB_DailyPanel_Copy].[TotalDaysInCurrentStatus] AS [TotalDaysInCurrentStatus],
  [BI_DB_DailyPanel_Copy].[TotalEquity] AS [TotalEquity],
  [BI_DB_DailyPanel_Copy].[TotalPositionsAmount] AS [TotalPositionsAmount],
  [BI_DB_DailyPanel_Copy].[TraderType] AS [TraderType],
  [BI_DB_DailyPanel_Copy].[Trades] AS [Trades],
  [BI_DB_DailyPanel_Copy].[UpdateDate] AS [UpdateDate],
  [BI_DB_DailyPanel_Copy].[UserName] AS [UserName],
  [Custom SQL Query].[Value_percenet] AS [Value_percenet (Custom SQL Query)],
  [BI_DB_DailyPanel_Copy].[Value_percenet] AS [Value_percenet]
FROM (
  SELECT *
    FROM BI_DB_dbo.BI_DB_DailyPanel_Copy bddpc
    WHERE bddpc.Date=cast(GETDATE()-1 AS DATE)
) [BI_DB_DailyPanel_Copy]
  LEFT JOIN (
  SELECT TOP 1 WITH TIES
  		CID
  	  ,InstrumentID
  	  ,SymbolFull
  	  ,Position_Value
  	  ,Value_percenet
  	  ,Lev_weighted_average
  from
  	  (
  SELECT ps.CID
     ,ps.InstrumentID
     ,ps.SymbolFull
     ,ps.Position_Value
     ,ps.Lev_weighted_average
   ,ps.Position_Value/NULLIF((SUM(ps.Position_Value) OVER(PARTITION BY ps.CID)+vl.Credit),0) AS Value_percenet
  FROM (SELECT pp.CID
  ,pp.InstrumentID 
  ,di.SymbolFull
  ,SUM(pp.Amount) AS Amount
  ,COALESCE(SUM(pp.Leverage*pp.Amount)/NULLIF(SUM(pp.Amount),0),0)  AS Lev_weighted_average
  ,SUM(pp.Amount+pp.PositionPnL) AS Position_Value
  FROM BI_DB_dbo.BI_DB_PositionPnL pp WITH (NOLOCK)
  JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK)
  ON di.InstrumentID=pp.InstrumentID
  WHERE pp.DateID=CAST(CONVERT(VARCHAR(8), GETDATE() - 1, 112) AS INT)
  GROUP BY pp.CID,pp.InstrumentID,di.SymbolFull
  ) ps
  LEFT JOIN DWH_dbo.V_Liabilities vl  WITH (NOLOCK)
  ON ps.CID = vl.CID  
  AND vl.DateID=CAST(CONVERT(VARCHAR(8), GETDATE() - 1, 112) AS INT)  
  ) final
  order by row_number() over (partition by CID order by Value_percenet DESC)
) [Custom SQL Query] ON ([BI_DB_DailyPanel_Copy].[CID] = [Custom SQL Query].[CID])
  LEFT JOIN (
  SELECT e.CID, 
          max(CASE WHEN e.MaxDate=cast(GETDATE() as DATE) THEN e.Gain_MTD END) Gain_MTD_Today,
  		max(CASE WHEN e.MaxDate=cast(GETDATE() as DATE) THEN e.Gain_YTD END) Gain_YTD_Today,
  		max(CASE WHEN e.MaxDate=cast(GETDATE()-1 as DATE) THEN e.Gain_YTD END) Gain_YTD_Yesterday
  		--max(CASE WHEN e.MaxDate=cast(GETDATE() as DATE) THEN (1+e.Gain_YTD) END)*1.0/max(CASE WHEN e.MaxDate=cast(GETDATE()-1 as DATE) THEN (1+e.Gain_YTD) END)-1 Daily_Gain
   FROM ( 
  select  
      g.MaxDate MaxDate  
        ,g.CID  
     ,MAX (CASE WHEN  g.IntervalTypeID=101 THEN g.Gain END) AS  Gain_MTD  
     ,MAX (CASE WHEN  g.IntervalTypeID=103 THEN g.Gain END) AS  Gain_YTD  
    ,g.ExecutionID
  FROM  [BI_DB_dbo].[External_TradeGain_Ranking_Compound_Gain_Completed] g  
  INNER JOIN [BI_DB_dbo].[External_TradeGain_Ranking_Execution] re  
  ON g.ExecutionID = re.ExecutionID  
  where g.IntervalTypeID in (1,101,102,103,106,108,109,110,7) 
    and re.ObjectID=4  
    and g.ExecutionID >=(SELECT MAX(ExecutionID) 
                          FROM [BI_DB_dbo].[External_TradeGain_Ranking_Execution] 
  						WHERE Completed = 1 and  ObjectID=4 and MaxDate<=DATEADD(DAY,-1,cast(GETDATE() as date)))
    and g.Gain<>0  
  group by   
      g.CID, g.[MaxDate]  ,g.ExecutionID) e
   GROUP BY e.CID
) [Gain] ON ([BI_DB_DailyPanel_Copy].[CID] = [Gain].[CID])