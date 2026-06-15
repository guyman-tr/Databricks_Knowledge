SELECT lp.Date
		,'Apex' AS LP
		,lp.AccountNumber COLLATE Latin1_General_BIN AS Account
		,SUM(CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END) AS PnL
		,SUM(lp.Zero) AS Zero
                ,max(UpdateDate) Last_UpdateDate
FROM Dealing..Dealing_Apex_PnL_Daily lp
GROUP BY lp.AccountNumber, lp.Date

UNION

SELECT lp.Date
		,'JP' AS LP
		,'' COLLATE Latin1_General_BIN AS Account
		,SUM(CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END) 
				+ ISNULL(t.Total_Dividends,0) + ISNULL(t.Total_Rolls,0) AS PnL
		,SUM(lp.Zero) AS Zero
                ,max(lp.UpdateDate) Last_UpdateDate
FROM Dealing..Dealing_JP_PnL_Daily lp
LEFT JOIN Dealing..Dealing_JP_PnL_Totals_Daily t
ON lp.Date = t.Date and t.Currency = 'Total USD'
GROUP BY t.Total_Dividends
		,t.Total_Rolls
		,lp.Date

UNION

SELECT lp.Date
		,'EDF' AS LP
		,lp.Account COLLATE Latin1_General_BIN
		,SUM(lp.PnL) AS PnL
		,NULL AS Zero
                ,max(UpdateDate) Last_UpdateDate
FROM Dealing..Dealing_EDF_PnL_EE_Daily lp
GROUP BY lp.Account, lp.Date

--UNION

--SELECT lp.Date
--		,'IG' AS LP
--		,lp.AccountID
--		,SUM(lp.PnL) AS PnL
--FROM Dealing..Dealing_IG_PnL_EE lp
--GROUP BY lp.AccountID

UNION

SELECT lp.Date
		,'IB' AS LP
		,lp.AccountID COLLATE Latin1_General_BIN
		,SUM(CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END) AS PnL
		,SUM(lp.Zero) AS Zero
                ,max(UpdateDate) Last_UpdateDate
FROM Dealing..Dealing_IB_PnL_Daily lp
GROUP BY lp.AccountID, lp.Date

UNION

SELECT lp.Date
		,'Saxo Real' AS LP
		,lp.AccountNumber COLLATE Latin1_General_BIN
		,SUM(CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END) AS PnL
		,SUM(lp.Zero) AS Zero
                ,max(UpdateDate) Last_UpdateDate
FROM Dealing..Dealing_Saxo_PnL_Real_Daily lp
GROUP BY lp.AccountNumber, lp.Date

UNION

SELECT lp.Date
		,'Saxo CFD' AS LP
		,lp.AccountNumber COLLATE Latin1_General_BIN
		,SUM(lp.PnL) AS PnL
		,SUM(lp.Zero) AS Zero
                ,max(UpdateDate) Last_UpdateDate
FROM Dealing..Dealing_Saxo_PnL_CFD_Daily lp
GROUP BY lp.AccountNumber, lp.Date

UNION 

SELECT lp.Date
		,'Goldman Sachs' AS LP
		,'' COLLATE Latin1_General_BIN AS Account
		,SUM(CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END) AS PnL
		,SUM(lp.Zero) AS Zero
                ,max(UpdateDate) Last_UpdateDate
FROM Dealing..Dealing_GS_PnL_Daily lp
GROUP BY lp.Date