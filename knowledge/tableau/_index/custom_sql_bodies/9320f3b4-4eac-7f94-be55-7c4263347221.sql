SELECT DISTINCT AccountNumber AS ApexID_Apex, cast(PayDate AS DATE) PayDate_Apex, DividendInterest as Dividend_Apex
FROM [BI_DB_dbo].[External_Sodreconciliation_apex_EXT922_PendingDividend]
WHERE PayDate >= '2024-08-01'
AND left(AccountNumber,2)='3E'
--GROUP BY AccountNumber, cast(PayDate AS DATE)