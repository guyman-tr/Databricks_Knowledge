SELECT
	c.*
   ,dc1.Name AS Country,bd.IsFTD,
case when Regulation in ('ASIC & GAML') THEN 'ASIC' 
when Regulation in ('eToroUS', 'FinCEN+FINRA') THEN 'FinCEN' ELSE Regulation end as Regulation1
FROM
BI_DB_Operations_Monthly_KPIs_Wires  c
	JOIN DWH..Dim_Customer dc
		ON c.CID = dc.RealCID
	JOIN DWH..Dim_Country dc1
		ON dc.CountryID = dc1.CountryID
join DWH.dbo.Fact_BillingDeposit bd on bd.DepositID=c.DepositID
where FundingTypeName in ('WireTransfer')