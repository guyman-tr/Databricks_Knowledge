Select cid as 'CID'
,benefit_name as 'Benefit'
,item as 'Description'
,from_date as 'Date issued'
,activation_date as 'Date activated'
,to_date as 'Date cancelled'
,source
,Case when to_date is not null then 'Cancelled' else 'Active' end as Status
FROM [ThirdParty_Fivetran].[Fivetran].[google_sheets].[clubbenefitgift]