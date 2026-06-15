select 
	a.M,
	a.FundingType,
	a.[Amount in $],
	a.Regulation,
	b.CHBAmount,
	b.TotalCHBloss,
	b.CHBAmount/a.[Amount in $] AS [% of CHB over TotalDeposits],
	b.TotalCHBloss/a.[Amount in $] AS [% of CHB Loss over TotalDeposits],
	b.[Refund / CHB]
from (
SELECT  
	CONVERT(VARCHAR(6),bdad.ModificationDate, 112) as M,
	FundingType,
	SUM(bdad.[Amount in $]) AS [Amount in $],
	 CASE WHEN bdad.Regulation IN ('ASIC & GAML') THEN 'ASIC'
	WHEN bdad.Regulation IN ('FinCEN+FINRA') THEN 'FinCEN' ELSE bdad.Regulation END AS [Regulation]

FROM BI_DB.dbo.BI_DB_AllDeposits bdad
WHERE 
	bdad.ModificationDate>= DATEADD(month,-4, DATEADD(month, DATEDIFF(month, 0, cast(getdate()-1 as date)), 0) )
--and bdad.ModificationDate<DATEADD(m,1,DATEADD(month,-1,( DATEADD(month, DATEDIFF(month, 0, cast(getdate()-1 as date)), 0) ))) 
AND bdad.PaymentStatus in ('Approved')
GROUP BY 
	CONVERT(VARCHAR(6),bdad.ModificationDate, 112) ,
	FundingType,CASE WHEN bdad.Regulation IN ('ASIC & GAML') THEN 'ASIC'
	WHEN bdad.Regulation IN ('FinCEN+FINRA') THEN 'FinCEN' ELSE bdad.Regulation END)a left outer join (

SELECT 
		 bdmcr.YearMonth as M,
		SUM(bdmcr.[CHB/Refund $ Amount]) AS CHBAmount,
		SUM(bdmcr.[CHB Loss by Risk USE]) AS TotalCHBloss,
		 bdmcr.[Method Of Payment] AS FundingType,
		 bdmcr.[Refund / CHB],
		 CASE WHEN bdmcr.Regulation IN ('ASIC & GAML') THEN 'ASIC'
	WHEN bdmcr.Regulation IN ('FinCEN+FINRA') THEN 'FinCEN' ELSE bdmcr.Regulation END AS [Regulation]

		FROM BI_DB.dbo.BI_DB_M_ChargebackReport bdmcr
		WHERE bdmcr.[Refund / CHB] IN ('CHB') 
		group by 
		bdmcr.[Method Of Payment], bdmcr.[Refund / CHB],
		 bdmcr.YearMonth, CASE WHEN bdmcr.Regulation IN ('ASIC & GAML') THEN 'ASIC'
	WHEN bdmcr.Regulation IN ('FinCEN+FINRA') THEN 'FinCEN' ELSE bdmcr.Regulation END)b on a.M=b.M AND a.FundingType=b.FundingType AND a.Regulation=b.Regulation

		 WHERE a.FundingType IN ('ACH','CreditCard','PayPal')