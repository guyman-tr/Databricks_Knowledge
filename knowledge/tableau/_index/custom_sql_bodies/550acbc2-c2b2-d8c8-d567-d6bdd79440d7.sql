SELECT [DWH_RiskVAR].[Date] AS [Date],
  [DWH_RiskVAR].[InstrumentType] AS [HedgeServerID],
  [DWH_RiskVAR].[InstrumentID] AS [InstrumentID],
  [DWH_RiskVAR].[InstrumentName] AS [InstrumentName],
  [DWH_RiskVAR].[NOP] AS [NOP],
  [DWH_RiskVAR].[Nop_Units] as NOP_Units,
  [DWH_RiskVAR].[VAR100] AS [VAR100],
  [DWH_RiskVAR].[VAR99] AS [VAR99],
  [DWH_RiskVAR].[VAR95] AS [VAR95],
  [BBookBudgetLimits].[InstrumentName] AS [BBookBudgetLimits_InstrumentName],
  [BBookBudgetLimits].[HVAR] AS [HVAR],
  [BBookBudgetLimits].[PnL] AS [PnL],
  [BBookBudgetLimits].[NOP] AS [BBookBudgetLimits_NOP]
FROM [dbo].[DWH_RiskVAR_Majors] [DWH_RiskVAR]
  LEFT JOIN [dbo].[BI_DB_BBookBudgetLimits] [BBookBudgetLimits] 
  ON ([DWH_RiskVAR].[InstrumentID] =  [BBookBudgetLimits].[InstrumentID])
  or (case when [DWH_RiskVAR].InstrumentID=999 then InstrumentType end=case when [BBookBudgetLimits].[InstrumentName]='Bbook - FX' then 5 
                                                                           when [BBookBudgetLimits].[InstrumentName]='Bbook - Non FX' then 24 
									   when [BBookBudgetLimits].[InstrumentName]='Bbook - All' then 0 end)