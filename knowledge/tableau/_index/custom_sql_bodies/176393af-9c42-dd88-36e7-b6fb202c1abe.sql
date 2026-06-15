SELECT bdcmpfd.ActiveDate,
bdcmpfd.Seniority_FundedNew,
bdcmpfd.NewMarketingRegion,
bdcmpfd.EOM_Club,
SUM(bdcmpfd.TotalDeposits) AS 'TotalDeposits',
SUM(bdcmpfd.TotalCashouts) AS 'TotalCashouts',
SUM(bdcmpfd.NetDeposits) AS 'NetDeposits',
SUM(bdcmpfd.CountDeposits) AS 'DepositsCount',
SUM(CASE WHEN bdcmpfd.TotalCashouts>0 THEN 1 ELSE 0 END) AS 'Unique Cashouts',
SUM(CASE WHEN bdcmpfd.TotalDeposits>0 THEN 1 ELSE 0 END) AS 'Unique Depositors'
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd
WHERE bdcmpfd.ActiveDate>=DATEADD(yy,-2,GETDATE()-1)
GROUP BY bdcmpfd.ActiveDate
,bdcmpfd.Seniority_FundedNew
,bdcmpfd.NewMarketingRegion
,bdcmpfd.EOM_Club