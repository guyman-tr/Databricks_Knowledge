SELECT
	    DISTINCT f.*
,dr.Name as DesignatedRegulation
,dc1.Name as Country
, CASE WHEN e.CID is not null then 'Yes' else 'No' end as HaseMoneyAccount
		FROM [BI_DB_dbo].[BI_DB_OPS_KYC_Verification] f
join DWH_dbo.Dim_Customer dc on dc.RealCID=f.RealCID
join DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
LEFT JOIN DWH_dbo.Dim_Regulation dr on dr.ID=dc.DesignatedRegulationID
left join (select distinct e.CID FROM eMoney_dbo.eMoney_Dim_Account e) e on e.CID=f.RealCID