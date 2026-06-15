SELECT [DWH_RiskVAR].[DATE] AS [Date],
  [DWH_RiskVAR].[HedgeServerID] AS [HedgeServerID],
  [DWH_RiskVAR].[InstrumentID] AS [InstrumentID],
  [DWH_RiskVAR].[InstrumentName] AS [InstrumentName],
  [DWH_RiskVAR].[OpenPositions] AS [OpenPositions],
  [DWH_RiskVAR].[NOP] AS [NOP],
  [DWH_RiskVAR].[NOP_total] AS [NOP_total],
  [DWH_RiskVAR].[Short_total] AS [Short],
  [DWH_RiskVAR].[Long_total] AS [Long],
  [DWH_RiskVAR].[VAR100] AS [VAR100],
  [DWH_RiskVAR].[VAR99] AS [VAR99],
  [DWH_RiskVAR].[VAR95] AS [VAR95],
  [DWH_RiskVAR].ZeroSinceInception,
  [DWH_RiskVAR].CommissionSinceInception,
  [DWH_RiskVAR].Last_6months_Zero,
  [DWH_RiskVAR].Current_Year_Zero,
  [DWH_RiskVAR].Last_6months_Commission,
  [DWH_RiskVAR].Nop_Units,
  [DWH_RiskVAR].UpdateDate,
  [DWH_RiskVAR].Total_ABook_InstrumentExposure,
  [DWH_RiskVAR].ABook_Short,
  [DWH_RiskVAR].ABook_Long,
  [BBookBudgetLimits].[InstrumentName] AS [BBookBudgetLimits_InstrumentName],
  [BBookBudgetLimits].[HVAR] AS [HVAR],
  [BBookBudgetLimits].[PnL] AS [PnL],
  [BBookBudgetLimits].[NOP] AS [BBookBudgetLimits_NOP],

  case when [BI_DB_RiskReport].BBook_Long_until_TP + [BI_DB_RiskReport].BBook_Short_until_SL > [BI_DB_RiskReport].BBook_Long_until_SL + [BI_DB_RiskReport].BBook_Short_until_TP
       then [BI_DB_RiskReport].BBook_Long_until_TP + [BI_DB_RiskReport].BBook_Short_until_SL else [BI_DB_RiskReport].BBook_Long_until_SL + [BI_DB_RiskReport].BBook_Short_until_TP 
	   end 
    as [VAR99.5],
case when [BI_DB_RiskReport].BBook_Long_until_TP_99 + [BI_DB_RiskReport].BBook_Short_until_SL_99 > [BI_DB_RiskReport].BBook_Long_until_SL_99 + [BI_DB_RiskReport].BBook_Short_until_TP_99
       then [BI_DB_RiskReport].BBook_Long_until_TP_99 + [BI_DB_RiskReport].BBook_Short_until_SL_99 else [BI_DB_RiskReport].BBook_Long_until_SL_99 + [BI_DB_RiskReport].BBook_Short_until_TP_99
	    end 
    as [VAR99_SL/TP]

FROM [dbo].[DWH_RiskVAR] [DWH_RiskVAR] WITH (NOLOCK)
  LEFT JOIN [dbo].[BI_DB_BBookBudgetLimits] [BBookBudgetLimits] WITH (NOLOCK)
  ON ([DWH_RiskVAR].[InstrumentID] =  [BBookBudgetLimits].[InstrumentID])
  OR (case when [DWH_RiskVAR].InstrumentID=999 then HedgeServerID end=case when [BBookBudgetLimits].[InstrumentName]='Bbook - FX' then 5 
                                                                           when [BBookBudgetLimits].[InstrumentName]='Bbook - Non FX' then 24 
									   when [BBookBudgetLimits].[InstrumentName]='Bbook - All' then 0 end)
  LEFT JOIN (SELECT * FROM [dbo].[BI_DB_RiskReport] WITH (NOLOCK) WHERE Gap = 0) [BI_DB_RiskReport]
  ON [DWH_RiskVAR].[InstrumentID] = [BI_DB_RiskReport].[InstrumentID] 
  OR ([DWH_RiskVAR].HedgeServerID = 0 and [DWH_RiskVAR].HedgeServerID = [BI_DB_RiskReport].InstrumentID)