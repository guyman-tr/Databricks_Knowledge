SELECT 
	sum(FBD.AmountUSD) AS TotalDeposits,
	dc.Name as Country, 
	case when dr.Name in (
'eToroUS',
'FinCEN',
'FinCEN+FINRA') then 'FinCEN'
when dr.Name in ('ASIC','ASIC & GAML') then 'ASIC' else dr.Name end as [Regulation],
LEFT(FBD.ModificationDateID, 6) AS YearMonth , 
ft.Name as FundingType
FROM 
DWH_dbo.Fact_BillingDeposit FBD
JOIN DWH_dbo.Dim_Customer DC ON DC.RealCID=FBD.CID
JOIN DWH_dbo.Dim_Country dc on dc.CountryID =DC.CountryID
join DWH_dbo.Dim_Regulation dr on dr.ID=DC.RegulationID
JOIN DWH_dbo.Dim_FundingType ft on ft.FundingTypeID=FBD.FundingTypeID
WHERE FBD.PaymentStatusID=2
and FBD.ModificationDateID>='20210101'
GROUP BY 
dc.Name , 
	case when dr.Name in (
'eToroUS',
'FinCEN',
'FinCEN+FINRA') then 'FinCEN'
when dr.Name in ('ASIC','ASIC & GAML') then 'ASIC' else dr.Name end ,
LEFT(FBD.ModificationDateID, 6), 
ft.Name