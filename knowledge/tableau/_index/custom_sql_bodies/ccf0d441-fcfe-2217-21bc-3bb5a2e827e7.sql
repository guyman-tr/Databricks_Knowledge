Select * FROM
(Select distinct cast(HL.ExecutionTime as date)[Trade Date], HL.LiquidityAccountID, LA.LiquidityAccountName, Count (1) [Total Trades]
FROM [AZR-W-REAL-DB-2-BIDBUser].[etoro].[Hedge].[ExecutionLog] HL
LEFT JOIN Reg_Instruments_SCD RIS  on HL.InstrumentID = RIS.InstrumentID
LEFT JOIN [RegReportDB_Prod].[dbo].[Reg_LiquidtyAcount_Ext] LA ON HL.LiquidityAccountID = LA.LiquidityAccountID
LEFT JOIN [Reg_Ext_DictionaryCurrencyType] DC on RIS.InstrumentTypeID = DC.CurrencyTypeID
Where cast(ExecutionTime as DATE) >= cast(getdate()-3 as date) AND HL.[Success] = 1 
AND RIS.InstrumentTypeID = '10'
GROUP By cast(HL.ExecutionTime as date), HL.LiquidityAccountID, LA.LiquidityAccountName)f

Union

(Select distinct cast(HL.ExecutionTime as date)[Trade Date],  '-' AS 'LiquidityAccountID', 'Total'AS 'LiquidityAccountName',
Count (1) [Total Trades]
FROM [AZR-W-REAL-DB-2-BIDBUser].[etoro].[Hedge].[ExecutionLog] HL
LEFT JOIN Reg_Instruments_SCD RIS  on HL.InstrumentID = RIS.InstrumentID
LEFT JOIN [RegReportDB_Prod].[dbo].[Reg_LiquidtyAcount_Ext] LA ON HL.LiquidityAccountID = LA.LiquidityAccountID
LEFT JOIN [Reg_Ext_DictionaryCurrencyType] DC on RIS.InstrumentTypeID = DC.CurrencyTypeID
Where cast(ExecutionTime as DATE) >= cast(getdate()-3 as date) AND HL.[Success] = 1 
AND RIS.InstrumentTypeID = '10'
GROUP By cast(HL.ExecutionTime as date)
)