SELECT [TradeSurveilliance_Trade_Data].[UpdateDate] AS [UpdateDate],
  [TradeSurveilliance_Trade_Data].[EventTimeID] AS [EventTimeID],
  [TradeSurveilliance_Trade_Data].[PositionID] AS [PositionID],
  [TradeSurveilliance_Trade_Data].[CID] AS [CID (TradeSurveilliance_Trade_Data)],
  [TradeSurveilliance_Trade_Data].[InstrumentTypeID] AS [InstrumentTypeID],
  [TradeSurveilliance_Trade_Data].[InstrumentType] AS [InstrumentType],
  [TradeSurveilliance_Trade_Data].[InstrumentID] AS [InstrumentID],
  [TradeSurveilliance_Trade_Data].[InstrumentName] AS [InstrumentName],
  [TradeSurveilliance_Trade_Data].[IsBuy] AS [IsBuy],
  [TradeSurveilliance_Trade_Data].[InvestedAmount] AS [InvestedAmount],
  [TradeSurveilliance_Trade_Data].[Leverage] AS [Leverage],
  [TradeSurveilliance_Trade_Data].[IsCopy] AS [IsCopy],
  [TradeSurveilliance_Trade_Data].[ProfitRatio] AS [ProfitRatio],
  [TradeSurveilliance_Trade_Data].[RealizedProfitUSD] AS [RealizedProfitUSD],
  [TradeSurveilliance_Trade_Data].[PositionOpenDateTime] AS [PositionOpenDateTime],
  [TradeSurveilliance_Trade_Data].[PositionCloseDateTime] AS [PositionCloseDateTime],
  [TradeSurveilliance_Trade_Data].[PositionCloseReasonID] AS [PositionCloseReasonID],
  [TradeSurveilliance_Trade_Data].[PositionCloseReason] AS [PositionCloseReason],
  [TradeSurveilliance_Trade_Data].[OpenedByOrderID] AS [OpenedByOrderID],
  [TradeSurveilliance_Trade_Data].[OpenedByOrder] AS [OpenedByOrder]
FROM [dbo].[TradeSurveilliance_Trade_Data] [TradeSurveilliance_Trade_Data]
where 
[TradeSurveilliance_Trade_Data].[CID]
in (SELECT distinct CID
      FROM [RegReportDB_Prod].[dbo].[TradeSurveilliance_Alert_Log]
  where [AlertCategory]='Trading')