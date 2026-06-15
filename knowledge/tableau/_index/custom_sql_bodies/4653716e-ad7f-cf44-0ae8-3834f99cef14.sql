select bd.*, dpl.Name as Club, dc1.EU, dc1.IsEuropeanCountry,
ft.Name AS MOP,
dr.Name as Regulation,
dc1.Name as Country


from DWH_dbo.Fact_BillingWithdraw bd
join DWH_dbo.Dim_Customer dc on dc.RealCID=bd.CID
join DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl on dpl.PlayerLevelID=dc.PlayerLevelID
JOIN DWH_dbo.Dim_FundingType ft on ft.FundingTypeID=bd.FundingTypeID_Funding
JOIN DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
where bd.ModificationDate>= dateadd(month,DATEDIFF(MONTH,0,getdate())-6,0)
AND bd.CashoutStatusID_Funding=3 and bd.CashoutStatusID_Funding=3