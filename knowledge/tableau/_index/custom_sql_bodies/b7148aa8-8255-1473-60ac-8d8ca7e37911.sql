SELECT 
 fnld.DateID 
,TO_DATE(CAST(DateID AS STRING), 'yyyyMMdd') AS Date
,fnld.AffiliateID
,fnld.BannerID
,fnld.CountryID
,cntr.Name AS CountryName
,bnrmt.TagName
,bnrmt.BannerName
,bnrmt.BannerTypeName
,bnrmt.LanguageName
,bnrmt.TargetURL
,bnrmt.Width
,bnrmt.Height
,aff.Contact
,aff.ContractName
,aff.Channel
,sum(fnld.Impressions) Impressions
,sum(fnld.Clicks) Clicks
,sum(COALESCE(fnld.Reg, 0)) AS Registrations
,sum(COALESCE(fnld.FTD, 0)) AS FTD
,sum(COALESCE(fnld.RevShare_Comm, 0)) AS RevShare_Comm
,sum(COALESCE(fnld.CPA_Comm, 0)) AS CPA_Comm
,sum(COALESCE(fnld.CPL_Comm, 0)) AS CPL_Comm
,sum(COALESCE(fnld.eCost, 0)) AS eCost

from finaldata as fnld
left join Bannermtrx as bnrmt on bnrmt.BannerID = fnld.BannerID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked AS aff on aff.AffiliateID = fnld.AffiliateID 
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country as cntr on cntr.CountryID = fnld.CountryID

where fnld.DateID >= 20250201
AND aff.Channel in ('Affiliate' ,'Affiliate Branding', 'Media Performance','Content Partnerships','Media CPA','Media Performance')
and TO_DATE(CAST(DateID AS STRING), 'yyyyMMdd') <= CURRENT_DATE - 1

group by 
 fnld.DateID 
,TO_DATE(CAST(DateID AS STRING), 'yyyyMMdd')
,fnld.AffiliateID
,fnld.BannerID
,fnld.CountryID
,bnrmt.LanguageName
,bnrmt.TagName
,bnrmt.BannerName
,bnrmt.BannerTypeName
,bnrmt.TargetURL
,bnrmt.Width
,bnrmt.Height
,aff.Contact
,aff.ContractName
,aff.Channel
,cntr.Name

order by  fnld.DateID