with main as (
SELECT
    DISTINCT bc.CID,
    cc.GCID,
  cc.City,
    cc.Registered,
    bc.VerificationLevelID,
    eid.EIDStatusName as EIDStatus,
    dc.Name as Country,
    Sum(bd.Amount*bd.ExchangeRate) as TotalDeposits,
    df.Name as Funnel,
    pl.Platform,
    ps.Name as PlayerStatus,
    cifid.LastLoggedIn
FROM main.general.bronze_etoro_backoffice_customer bc
join main.general.bronze_etoro_customer_customer_masked cc on cc.CID=bc.CID
left join main.general.bronze_etoro_dictionary_eidstatus eid on eid.EIDStatusID=bc.EIDStatusID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc on dc.CountryID=cc.CountryID
left join main.billing.bronze_etoro_billing_deposit bd on bd.CID=bc.CID AND bd.PaymentStatusID=2--approved
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel df on df.FunnelID=cc.FunnelID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform pl on pl.PlatformID=cc.PlatformID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on ps.PlayerStatusID=cc.PlayerStatusID
left join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cifid on cifid.CID=bc.CID
WHERE cc.Registered>='2025-04-01'
and dc.Name in ('United Arab Emirates')
group by
  bc.CID,
    cc.GCID,
    cc.Registered,
    bc.VerificationLevelID,
    eid.EIDStatusName ,
    dc.Name,
    cc.City, df.Name,  pl.Platform,
        ps.Name,
    cifid.LastLoggedIn
-- and eid.EIDStatusID IS NOT NULL
-- and cc.GCID in (
--     43706738,
-- 43706675,
-- 43705872,
-- 43703922,
-- 43701306,
-- 43698230
-- )

), 

docuements as (
  Select 
dc.RealCID
,max(case when cdd.DocumentTypeID = 2 then 1 else 0 end )as POIDefined
,max(case when cdd.DocumentTypeID = 1 then 1 else 0 end )as POADefined
,max(case when cd.SuggestedDocumentTypeID = 1 then 1 else 0 end )as POAUploaded
,max(case when cd.SuggestedDocumentTypeID = 2 then 1 else 0 end )as POIUploaded
,max(case when cd.SuggestedDocumentTypeID IN (15,18,23) then 1 else 0 end )as SelfieUploaded
,max(case when cdd.DocumentTypeID IN (15,18,23) then 1 else 0 end )as SelfieDefined
FROM 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked  dc
    join main m on m.CID=dc.RealCID
LEFT JOIN
	main.billing.bronze_etoro_backoffice_customerdocument cd on cd.CID = dc.RealCID
LEFT JOIN
	main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype cdd on cdd.DocumentID = cd.DocumentID
GROUP BY 
    dc.RealCID
),

commissions as (
  select
  m.CID, 
  SUM(fd.Revenue_Total) AS Commissions
  from main m
join   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata fd on fd.CID=m.CID
group by m.CID
)

SELECT
m.*,
d.POADefined,
d.POAUploaded,
d.POIDefined,
d.POIUploaded,
d.SelfieDefined,
d.SelfieUploaded,
case when m.TotalDeposits>0 then 1 else 0 end as IsDepositor,
C.Commissions

FROM main m
left join docuements d on d.RealCID=m.CID
LEFT JOIN commissions C ON C.CID=m.CID