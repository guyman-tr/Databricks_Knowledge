select bd.*, dpl.Name as Club, dc1.EU, dc1.IsEuropeanCountry


from BI_DB_dbo.BI_DB_AllDeposits bd
join DWH_dbo.Dim_Customer dc on dc.RealCID=bd.CID
join DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl on dpl.PlayerLevelID=dc.PlayerLevelID
where bd.ModificationDate>= dateadd(month,DATEDIFF(MONTH,0,getdate())-6,0)