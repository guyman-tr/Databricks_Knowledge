select 
	a.M,
	a.FundingType,
	a.[Amount in $],
	ISNULL(b.CHBAmount,0) AS CHBAmount, 
	ISNULL(b.TotalCHBloss,0) AS TotalCHBloss,
	b.[Refund / CHB],
	a.[Country (customer)]
from (
SELECT  
	CONVERT(VARCHAR(6),bdad.ModificationDate, 112) as M,
	FundingType,
	SUM(bdad.[Amount in $]) AS [Amount in $],
	bdad.[Country (customer)]

FROM BI_DB.dbo.BI_DB_AllDeposits bdad
WHERE 
	bdad.ModificationDate>= DATEADD(month,-4, DATEADD(month, DATEDIFF(month, 0, cast(getdate()-1 as date)), 0) )
--and bdad.ModificationDate<DATEADD(m,1,DATEADD(month,-1,( DATEADD(month, DATEDIFF(month, 0, cast(getdate()-1 as date)), 0) ))) 
AND bdad.PaymentStatus in ('Approved')
GROUP BY 
	CONVERT(VARCHAR(6),bdad.ModificationDate, 112) ,
	FundingType,
	bdad.[Country (customer)])a 
	left outer join (

SELECT 
		 bdmcr.YearMonth as M,
		SUM(bdmcr.[CHB/Refund $ Amount]) AS CHBAmount,
		SUM(bdmcr.[CHB Loss by Risk USE]) AS TotalCHBloss,
		 bdmcr.[Method Of Payment] AS FundingType,
		 bdmcr.[Refund / CHB],
		 bdmcr.[Country By Reg Form]

		FROM BI_DB.dbo.BI_DB_M_ChargebackReport bdmcr
		group by 
		bdmcr.[Method Of Payment], bdmcr.[Refund / CHB],
		 bdmcr.YearMonth,
		  bdmcr.[Country By Reg Form])b on a.M=b.M AND a.FundingType=b.FundingType AND b.[Country By Reg Form]=a.[Country (customer)]