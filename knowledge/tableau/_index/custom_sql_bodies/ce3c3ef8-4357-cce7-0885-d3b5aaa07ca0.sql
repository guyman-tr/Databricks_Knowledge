SELECT
COUNT(RealCID) AS Clients,
YEAR(bdcd.VerificationLevel3Date) AS Year,
MONTH(bdcd.VerificationLevel3Date) AS Month,
format(bdcd.VerificationLevel3Date,'yyyyMM') AS YearMonth,
dat.Name as AccountType,
sum(case when dat.Name in ('Affiliate Private Account','Affiliate Corporate Account')  then 1 else 0 end) AS Affiliates

FROM BI_DB_dbo.BI_DB_CIDFirstDates bdcd
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=bdcd.CID
JOIN DWH_dbo.Dim_AccountType dat ON dat.AccountTypeID=dc.AccountTypeID
WHERE VerificationLevel3Date>='20200101'
AND dc.IsValidCustomer=1
AND dc.VerificationLevelID=3

GROUP BY

YEAR(bdcd.VerificationLevel3Date) ,
MONTH(bdcd.VerificationLevel3Date) ,
dat.Name,
format(bdcd.VerificationLevel3Date,'yyyyMM')