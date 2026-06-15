select base.*
,(YearMonth / 100) * 100 + 
                 CASE 
                     WHEN (YearMonth % 100) >= 1 AND (YearMonth % 100) <= 3 THEN 1
                     WHEN (YearMonth % 100) >= 4 AND (YearMonth % 100) <= 6 THEN 2
                     WHEN (YearMonth % 100) >= 7 AND (YearMonth % 100) <= 9 THEN 3
                     WHEN (YearMonth % 100) >= 10 AND (YearMonth % 100) <= 12 THEN 4
                 END as YearQuarter
				 
				 ,left(YearMonth,4) as Year

from
(SELECT 
	DISTINCT F.CID, 
	F.YearMonth, 
	case when F.Regulation in (
'eToroUS',
'FinCEN',
'FinCEN+FINRA') then 'FinCEN'
when F.Regulation in (
'ASIC',
'ASIC & GAML') then 'ASIC' else F.Regulation end as [Regulation],
F.Balance,
CASE WHEN F.Balance<0 AND SUM(ABS(F.[CHB/ Refund $ Ammount * (-1)]))>ABS(F.Balance) THEN ABS(F.Balance)
WHEN  F.Balance<0 AND ABS(SUM(F.[CHB/ Refund $ Ammount * (-1)]))<=ABS(F.Balance) THEN ABS(SUM(F.[CHB/ Refund $ Ammount * (-1)]))
ELSE 0 END AS [Final],
	SUM(F.[CHB/ Refund $ Ammount * (-1)]) AS [CHB/ Refund $ Ammount * (-1)],
	F.[Refund / CHB],
	F.[Method Of Payment] FundingType,
	F.[Country By Reg Form]
	,F.[Club Level]
	,F.[CHB Reason]
	,F.[PaymentStatus]
FROM
(

SELECT
DISTINCT a.CID,
a.YearMonth,
a.Regulation,
SUM(a.[CHB/ Refund $ Ammount * (-1)]) AS [CHB/ Refund $ Ammount * (-1)] ,
a.Balance,
--a.Final,
CASE WHEN a.Balance<0 AND ABS(SUM(a.[CHB/ Refund $ Ammount * (-1)]))>ABS(a.Balance) THEN ABS(a.Balance)
WHEN  a.Balance<0 AND ABS(SUM(a.[CHB/ Refund $ Ammount * (-1)]))<=ABS(a.Balance) THEN ABS(SUM(a.[CHB/ Refund $ Ammount * (-1)])) ELSE 0 END AS Final,
ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY a.CID,a.YearMonth DESC) AS RN ,
a.[Refund / CHB],
a.[Method Of Payment],
a.[Country By Reg Form]
,a.[Club Level]
,a.[CHB Reason]
,a.[PaymentStatus]
FROM 
(
SELECT 
DISTINCT bdmcr.CID, 
bdmcr.YearMonth,
bdmcr.Regulation,
SUM( bdmcr.[CHB/ Refund $ Ammount * (-1)]) [CHB/ Refund $ Ammount * (-1)],
vl.Liabilities + vl.ActualNWA  AS Balance,
CASE WHEN (vl.Liabilities + vl.ActualNWA )<0 AND ABS(SUM(bdmcr.[CHB/ Refund $ Ammount * (-1)]))>ABS(vl.Liabilities + vl.ActualNWA ) THEN ABS(vl.Liabilities + vl.ActualNWA)
WHEN  (vl.Liabilities + vl.ActualNWA )<0 AND ABS(SUM(bdmcr.[CHB/ Refund $ Ammount * (-1)]))<=ABS(vl.Liabilities + vl.ActualNWA ) THEN ABS(SUM(bdmcr.[CHB/ Refund $ Ammount * (-1)])) ELSE 0 END AS Final,
bdmcr.[Refund / CHB],
bdmcr.[Method Of Payment],
bdmcr.[Country By Reg Form]
,bdmcr.[Club Level]
,bdmcr.[CHB Reason]
,bdmcr.[PaymentStatus]
FROM BI_DB_dbo.BI_DB_ChargebackReport bdmcr 
left JOIN [DWH_dbo].V_Liabilities vl on vl.CID=bdmcr.CID and vl.DateID = convert(varchar(25),getdate()-1,112)
WHERE bdmcr.YearMonth IS NOT NULL
GROUP BY 
bdmcr.CID, 
bdmcr.YearMonth,
bdmcr.Regulation,
vl.Liabilities + vl.ActualNWA,
bdmcr.[Refund / CHB],
bdmcr.[Method Of Payment],
bdmcr.[Country By Reg Form]
,bdmcr.[Club Level]
,bdmcr.[CHB Reason]
,bdmcr.[PaymentStatus])a 
GROUP BY a.CID, 
a.YearMonth,
a.Regulation,
a.Balance,
a.[Refund / CHB],
a.[Method Of Payment],
a.[Country By Reg Form]
,a.[Club Level]
,a.[CHB Reason]
,a.[PaymentStatus]) F
LEFT OUTER JOIN 
(
SELECT
DISTINCT a.CID,
a.YearMonth,
a.Regulation,
SUM(a.[CHB/ Refund $ Ammount * (-1)]) AS [CHB/ Refund $ Ammount * (-1)],
a.Balance,
CASE WHEN a.Balance<0 AND ABS(SUM(a.[CHB/ Refund $ Ammount * (-1)]))>ABS(a.Balance) THEN ABS(a.Balance)
WHEN  a.Balance<0 AND ABS(SUM(a.[CHB/ Refund $ Ammount * (-1)]))<=ABS(a.Balance) THEN ABS(SUM(a.[CHB/ Refund $ Ammount * (-1)])) ELSE 0 END AS Final,
ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY a.CID,a.YearMonth DESC) AS RN ,
a.[Refund / CHB],
a.[Method Of Payment],
a.[Country By Reg Form]
,a.[Club Level]
,a.[CHB Reason]
,a.[PaymentStatus]
FROM 
(
SELECT 
DISTINCT bdmcr.CID, 
bdmcr.YearMonth,
bdmcr.Regulation,
SUM(bdmcr.[CHB/ Refund $ Ammount * (-1)]) AS [CHB/ Refund $ Ammount * (-1)],
vl.Liabilities + vl.ActualNWA  Balance,
CASE WHEN (vl.Liabilities + vl.ActualNWA)<0 AND ABS(SUM(bdmcr.[CHB/ Refund $ Ammount * (-1)]))>ABS(vl.Liabilities + vl.ActualNWA) THEN ABS(vl.Liabilities + vl.ActualNWA)
WHEN  (vl.Liabilities + vl.ActualNWA)<0 AND ABS(SUM(bdmcr.[CHB/ Refund $ Ammount * (-1)]))<=ABS(vl.Liabilities + vl.ActualNWA) THEN ABS(SUM(bdmcr.[CHB/ Refund $ Ammount * (-1)])) ELSE 0 END AS Final,
bdmcr.[Refund / CHB],
bdmcr.[Method Of Payment],
bdmcr.[Country By Reg Form]
,bdmcr.[Club Level]
,bdmcr.[CHB Reason]
,bdmcr.[PaymentStatus]
FROM BI_DB_dbo. BI_DB_ChargebackReport bdmcr
left JOIN [DWH_dbo].V_Liabilities vl on vl.CID=bdmcr.CID and vl.DateID = convert(varchar(25),getdate()-1,112)
WHERE bdmcr.YearMonth IS NOT NULL
GROUP BY 
bdmcr.CID, 
bdmcr.YearMonth,
bdmcr.Regulation,
vl.Liabilities + vl.ActualNWA ,
bdmcr.[Refund / CHB],
bdmcr.[Method Of Payment],
bdmcr.[Country By Reg Form]
,bdmcr.[Club Level]
,bdmcr.[CHB Reason]
,bdmcr.[PaymentStatus]) a 
GROUP BY 
a.CID, 
a.YearMonth,
a.Regulation,
a.Balance,
a.[Refund / CHB],
a.[Method Of Payment],
a.[Country By Reg Form]
,a.[Club Level]
,a.[CHB Reason]
,a.[PaymentStatus]) 

S ON F.CID=S.CID  AND F.RN=S.RN-1
GROUP BY	
F.CID, 
F.YearMonth,
case when F.Regulation in (
'eToroUS',
'FinCEN',
'FinCEN+FINRA') then 'FinCEN'
when F.Regulation in (
'ASIC',
'ASIC & GAML') then 'ASIC' else F.Regulation end,
F.Balance,
F.[Refund / CHB],
F.[Method Of Payment],
F.[Country By Reg Form]
,F.[Club Level]
,F.[CHB Reason]
,F.[PaymentStatus]
)
base