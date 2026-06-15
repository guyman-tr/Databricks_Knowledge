SELECT 
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
	--F.[Refund / CHB],
	F.[Method Of Payment],
	F.[Country By Reg Form]
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
--a.[Refund / CHB],
a.[Method Of Payment],
a.[Country By Reg Form]
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
--bdmcr.[Refund / CHB],
bdmcr.[Method Of Payment],
bdmcr.[Country By Reg Form]
FROM BI_DB_dbo.BI_DB_ChargebackReport bdmcr 
left JOIN [DWH_dbo].V_Liabilities vl on vl.CID=bdmcr.CID and vl.DateID = <[Parameters].[Parameter 1]>
WHERE bdmcr.YearMonth IS NOT NULL
GROUP BY 
bdmcr.CID, 
bdmcr.YearMonth,
bdmcr.Regulation,
vl.Liabilities + vl.ActualNWA,
--bdmcr.[Refund / CHB],
bdmcr.[Method Of Payment],
bdmcr.[Country By Reg Form])a 
GROUP BY a.CID, 
a.YearMonth,
a.Regulation,
a.Balance,
--a.[Refund / CHB],
a.[Method Of Payment],
a.[Country By Reg Form]) F
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
--a.[Refund / CHB],
a.[Method Of Payment],
a.[Country By Reg Form]
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
--bdmcr.[Refund / CHB],
bdmcr.[Method Of Payment],
bdmcr.[Country By Reg Form]
FROM BI_DB_dbo. BI_DB_ChargebackReport bdmcr
left JOIN [DWH_dbo].V_Liabilities vl on vl.CID=bdmcr.CID and vl.DateID = <[Parameters].[Parameter 1]>
WHERE bdmcr.YearMonth IS NOT NULL
GROUP BY 
bdmcr.CID, 
bdmcr.YearMonth,
bdmcr.Regulation,
vl.Liabilities + vl.ActualNWA ,
--bdmcr.[Refund / CHB],
bdmcr.[Method Of Payment],
bdmcr.[Country By Reg Form]) a 
GROUP BY 
a.CID, 
a.YearMonth,
a.Regulation,
a.Balance,
--a.[Refund / CHB],
a.[Method Of Payment],
a.[Country By Reg Form]) 

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
--F.[Refund / CHB],
F.[Method Of Payment],
F.[Country By Reg Form]