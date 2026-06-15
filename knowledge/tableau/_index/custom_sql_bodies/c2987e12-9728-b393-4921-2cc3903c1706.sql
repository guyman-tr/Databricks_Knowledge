SELECT ftd.*,
CASE WHEN exch.MarketingExpenseName='Networks' THEN  'Networks' ELSE ftd.SubChannel END SubChannelUpdate,
CASE WHEN aff.AccountActivated = 1 THEN 'Active' ELSE 'Inactive' END AS Status ,cast(exch.DateCreated as date) as  RegistrationDate
FROM BI_DB_dbo.BI_DB_AffiliateFTDsAndURLS ftd 
LEFT JOIN DWH_dbo.Ext_Dim_Channel exch ON ftd.AffiliateID = exch.AffiliateID 
left join DWH_dbo.Dim_Affiliate aff on aff.AffiliateID=ftd.AffiliateID