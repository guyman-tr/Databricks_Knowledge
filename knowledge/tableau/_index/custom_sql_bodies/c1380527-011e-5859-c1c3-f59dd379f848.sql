SELECT lp.Date
		,'Apex' AS LP
		,lp.AccountNumber COLLATE Latin1_General_BIN AS Account
		,lp.InstrumentID
		,lp.InstrumentDisplayName COLLATE Latin1_General_BIN as InstrumentDisplayName
                ,di.InstrumentType
		,lp.Symbol COLLATE Latin1_General_BIN AS LP_InstrumentName
		,CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END AS PnL
		,lp.Zero
FROM Dealing..Dealing_Apex_PnL_Daily lp
left join DWH..Dim_Instrument di
on lp.InstrumentID = di.InstrumentID

UNION

SELECT lp.Date
		,'JP' AS LP
		,'' COLLATE Latin1_General_BIN AS Account
		,lp.InstrumentID
		,lp.InstrumentDisplayName COLLATE Latin1_General_BIN
                ,di.InstrumentType
		,lp.JP_Name COLLATE Latin1_General_BIN
		,CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END PnL
		,lp.Zero
FROM Dealing..Dealing_JP_PnL_Daily lp
left join DWH..Dim_Instrument di
on lp.InstrumentID = di.InstrumentID


--UNION

--SELECT lp.Date
--		,'EDF' AS LP
--		,lp.Account COLLATE Latin1_General_BIN
--		,NULL AS InstrumentID
--		,NULL AS InstrumentDisplayName
--		,NULL AS LP_InstrumentName
--		,lp.PnL AS PnL
--		,NULL AS Zero
--FROM Dealing..Dealing_EDF_PnL_EE_Daily lp
--GROUP BY lp.Account, lp.Date

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
		,lp.InstrumentID
		,lp.InstrumentDisplayName COLLATE Latin1_General_BIN
                ,di.InstrumentType
		,lp.IB_Name COLLATE Latin1_General_BIN
		,CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END AS PnL
		,lp.Zero
FROM Dealing..Dealing_IB_PnL_Daily lp
left join DWH..Dim_Instrument di
on lp.InstrumentID = di.InstrumentID

UNION

SELECT lp.Date
		,'Saxo Real' AS LP
		,lp.AccountNumber COLLATE Latin1_General_BIN
		,lp.InstrumentID
		,lp.InstrumentDisplayName COLLATE Latin1_General_BIN
                ,di.InstrumentType
		,lp.InstrumentName_Saxo COLLATE Latin1_General_BIN
		,CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END AS PnL
		,lp.Zero
FROM Dealing..Dealing_Saxo_PnL_Real_Daily lp
left join DWH..Dim_Instrument di
on lp.InstrumentID = di.InstrumentID

UNION

SELECT lp.Date
		,'Saxo CFD' AS LP
		,lp.AccountNumber COLLATE Latin1_General_BIN
		,lp.InstrumentID
		,lp.InstrumentDisplayName COLLATE Latin1_General_BIN
                ,di.InstrumentType
		,lp.InstrumentName_Saxo COLLATE Latin1_General_BIN
		,lp.PnL
		,lp.Zero
FROM Dealing..Dealing_Saxo_PnL_CFD_Daily lp
left join DWH..Dim_Instrument di
on lp.InstrumentID = di.InstrumentID

UNION 

SELECT lp.Date
		,'Goldman Sachs' AS LP
		,'' COLLATE Latin1_General_BIN AS Account
		,lp.InstrumentID
		,lp.InstrumentDisplayName COLLATE Latin1_General_BIN
                ,di.InstrumentType
		,lp.GS_Name COLLATE Latin1_General_BIN
		,CASE WHEN lp.InstrumentID IS NULL THEN lp.PnL ELSE lp.PnL_DBPrice END AS PnL
		,lp.Zero
FROM Dealing..Dealing_GS_PnL_Daily lp
left join DWH..Dim_Instrument di
on lp.InstrumentID = di.InstrumentID