SELECT d.Date
		,'JP' AS LP
		,d.InstrumentID
		,d.InstrumentDisplayName COLLATE Latin1_General_BIN AS InstrumentDisplayName
		,d.JP_Name COLLATE Latin1_General_BIN AS LP_Name
		,d.DivNetCashAmountUSD AS Dividends
FROM Dealing..Dealing_JP_PnL_Daily d
WHERE Date >= '2022-01-01'
	AND d.DivNetCashAmountUSD <> 0

UNION 

SELECT d.Date
		,'GS'
		,d.InstrumentID
		,d.InstrumentDisplayName COLLATE Latin1_General_BIN
		,d.GS_Name COLLATE Latin1_General_BIN AS LP_Name
		,d.Dividends
FROM Dealing..Dealing_GS_PnL_Daily d
WHERE Date >= '2022-01-01'
	AND d.Dividends IS NOT NULL

UNION

SELECT d.Date
		,'Saxo Real'
		,d.InstrumentID
		,d.InstrumentDisplayName COLLATE Latin1_General_BIN
		,d.InstrumentName_Saxo COLLATE Latin1_General_BIN AS LP_Name
		,d.Dividends
FROM Dealing..Dealing_Saxo_PnL_Real_Daily d
WHERE Date >= '2022-01-01'
	AND d.Dividends IS NOT NULL

UNION

SELECT d.Date
		,'Apex'
		,d.InstrumentID
		,d.InstrumentDisplayName COLLATE Latin1_General_BIN
		,d.Symbol COLLATE Latin1_General_BIN
		,d.Dividends
FROM Dealing..Dealing_Apex_PnL_Daily d
WHERE Date >= '2022-01-01'
	AND d.Dividends IS NOT NULL