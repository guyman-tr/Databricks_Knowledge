SELECT sum(Deposits) AS TotalDeposits,Country, case when Regulation in (
'eToroUS',
'FinCEN',

'FinCEN+FINRA') then 'FinCEN'
when Regulation in (
'ASIC',
'ASIC & GAML') then 'ASIC' else Regulation end as [Regulation],
YearMonth , 
CASE WHEN LEFT( right(YearMonth,2),1)=0 THEN  right(YearMonth,1)
 ELSE  right(YearMonth,2) END AS Month
FROM 
BI_DB.dbo.BI_DB_Client_Balance_Aggregate_Level_New
WHERE DateID>='20210101'
GROUP BY YearMonth, case when Regulation in (
'eToroUS',
'FinCEN',

'FinCEN+FINRA') then 'FinCEN'
when Regulation in (
'ASIC',
'ASIC & GAML') then 'ASIC' else Regulation END,
Country