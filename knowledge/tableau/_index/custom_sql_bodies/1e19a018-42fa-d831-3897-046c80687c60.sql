select a.ReportDate, DATEADD(DD,-1,a.ReportDate) as TradeDate, a.ActionType, case
  when a.ActionType in ('NEWT','TERM') and right(a.UniqueTransactionID,2)='BA' then 'T'
  when a.ActionType in ('NEWT','TERM') and right(a.UniqueTransactionID,2)='SA' then 'T'
  else 'P'
  end  AS Level, a.UniqueTransactionID AS UTI, b.Status
  from [RTS].[dbo].[ASIC_TradeActivity_Equities_] a
  left join [RTS].[dbo].[ASIC_TradeStatus_Equities] b
  on a.[TechnicalRecordID]=b.[OriginalRecordID]
  
  union all

  select a.ReportDate, DATEADD(DD,-1,a.ReportDate) as TradeDate, a.ActionType, case
  when a.ActionType in ('NEWT','TERM') and right(a.UniqueTransactionID,2)='BA' then 'T'
  when a.ActionType in ('NEWT','TERM') and right(a.UniqueTransactionID,2)='SA' then 'T'
  else 'P'
  end  AS Level, a.UniqueTransactionID AS UTI, b.Status
  from [RTS].[dbo].[ASIC_TradeActivity_Commodities_2] a
  left join [RTS].[dbo].[ASIC_TradeStatus_Commodities] b
  on a.[TechnicalRecordID]=b.[OriginalRecordID]


  union all

  select a.ReportDate, DATEADD(DD,-1,a.ReportDate) as TradeDate, a.ActionType, case
  when a.ActionType in ('NEWT','TERM') and right(a.UniqueTransactionID,2)='BA' then 'T'
  when a.ActionType in ('NEWT','TERM') and right(a.UniqueTransactionID,2)='SA' then 'T'
  else 'P'
  end  AS Level, a.UniqueTransactionID AS UTI, b.Status
  from [RTS].[dbo].[ASIC_TradeActivity_Currencies_3] a
  left join [RTS].[dbo].[ASIC_TradeStatus_Currencies] b
  on a.[TechnicalRecordID]=b.[OriginalRecordID]


  union all

  select a.ReportDate, DATEADD(DD,-1,a.ReportDate) as TradeDate, 'MARU' AS ActionType, 'T' AS Level, a.VariationMarginPortfolioCode AS UTI,b.Status
  from [RTS].[dbo].[ASIC_Margin_Activity_Report_] a
  left join [RTS].[dbo].[ASIC_TradeStatus_Margin] b
  on a.[TechnicalRecordID]=b.[OriginalRecordID]