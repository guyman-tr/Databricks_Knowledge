select dc.RealCID AS CID_Apex,
	AccountNumber AS ApexID_Apex, ProcessDate PayDate_Apex, sum(- Amount) Dividend_Apex
	--sum(- Amount) AS Reversed_amount -- EntryDate, EffectiveDate, InterestEffectiveDate, TradeDate, UserEntryDate,
	--Description, BatchCode, Cusip, SourceProgram,ACATSControlNumber, EnteredBy, PayTypeCode, TerminalID, 

from [BI_DB_dbo].[External_Sodreconciliation_apex_EXT869_CashActivity] ca 
JOIN DWH_dbo.Dim_Customer dc ON ca.AccountNumber=dc.ApexID
WHERE --AccountNumber='3EW41603'
 OfficeCode LIKE '3E%' --AND RegisteredRepCode='ETA'
AND TerminalID IN ('$+DIV','Z$ADR', 'SPDIV', 'DGDIV', 'RGDIV','RGMER', 'Z$DIS', 'REDIV', 'ACJRL', '$+INT','REREV', 'DVCIL', 'DVDIV', 'DVREI', 'DJDIV', 'REJNL')
AND Description LIKE '***%'
AND ProcessDate >= '2024-08-01'--BETWEEN '2024-07-10' AND '2024-07-17'
GROUP BY dc.RealCID, AccountNumber, ProcessDate
--ORDER BY ProcessDate