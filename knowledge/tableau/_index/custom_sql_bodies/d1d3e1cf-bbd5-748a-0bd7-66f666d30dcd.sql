SELECT EntryAppears, eomonth(efrr.[etoro - ModificationDate]) 'Month',
di.InstrumentDisplayName,
di.Name AS 'InstrumentName',
SUM(efrr.[eToro - AmountOnCloseUSD]) AS 'AmountOnCloseUSD',
SUM(efrr.[etoro - RedeemAmount]) AS 'Units',
SUM(efrr.[etoro - Amount]) AS 'Net Amount',
SUM(efrr.[eToro - AmountOnCloseUSD]-efrr.[etoro - Amount]) AS 'TransferCoin Fee'
FROM [EXW_dbo].[EXW_RedeemReconciliation] efrr
INNER JOIN DWH_dbo.Dim_Instrument di ON di.InstrumentID=efrr.[etoro - InstrumentID]
WHERE efrr.[etoro - ModificationDateID]>=20220101
AND  efrr.[etoro - RedeemStatus]='TransactionDone'
--AND efrr.PositionID = 834457495
GROUP BY EntryAppears, eomonth(efrr.[etoro - ModificationDate]),
di.InstrumentDisplayName,
di.Name