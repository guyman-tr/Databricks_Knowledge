SELECT YEAR(FirstActionDate) * 100 + DATEPART(qq,FirstActionDate) AS YearQuarter 
,EOMONTH(FirstActionDate) Date
,FirstAction
,SecondAction
,COUNT(DISTINCT bdfa.CID)CIDs						
FROM BI_DB_dbo.BI_DB_First5Actions bdfa						
WHERE FirstActionDate>='20220101'						
AND FirstActionDate<CAST(GETDATE()-1 AS DATE)					
GROUP BY YEAR(FirstActionDate) * 100 + DATEPART(qq,FirstActionDate)
,EOMONTH(FirstActionDate)
,FirstAction
,SecondAction