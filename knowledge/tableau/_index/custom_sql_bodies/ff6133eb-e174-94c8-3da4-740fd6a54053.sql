with main as (
SELECT
    DISTINCT bc.CID,
    cc.GCID,
    cc.Registered,
    bc.VerificationLevelID,

    dc.Name as Country,
    Sum(bd.Amount*bd.ExchangeRate) as TotalDeposits,
    df.Name as Funnel
FROM main.general.bronze_etoro_backoffice_customer bc
join main.general.bronze_etoro_customer_customer_masked cc on cc.CID=bc.CID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc on dc.CountryID=cc.CountryID
left join main.billing.bronze_etoro_billing_deposit bd on bd.CID=bc.CID AND bd.PaymentStatusID=2--approved
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel df on df.FunnelID=cc.FunnelID

WHERE cc.Registered>='2025-01-01'
and dc.Name in ('Cayman Islands','Jamaica','Panama',
'Bulgaria',
'South Africa',
'Vietnam',
'Monaco')
group by
  bc.CID,
    cc.GCID,
    cc.Registered,
    bc.VerificationLevelID,
    dc.Name,
     df.Name
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
,max(case when cd.SuggestedDocumentTypeID IN (7,8) then 1 else 0 end )as SOFUploaded
,max(case when (cdd.DocumentTypeID IN (7)  AND cdd.DocumentClassificationID in (31,43,7,33,30,13,9,17,27,32,36,38,58,60)) or
 cdd.DocumentTypeID IN (8) and cdd.DocumentClassificationID in (7,30,33)then 1 else 0 end )as SOFDefined
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
d.SOFUploaded,
d.SOFDefined,
case when m.TotalDeposits>0 then 1 else 0 end as IsDepositor,
C.Commissions,
case when d.POIDefined=1 and d.POADefined=1 and d.SOFDefined=1 then 1 else 0 end as EDDComplete,
case when d.POIDefined=1 and d.POADefined=1 and d.SOFDefined=0 THEN 1 ELSE 0 END AS EDDIncomplete_withPOIPOA
FROM main m
left join docuements d on d.RealCID=m.CID
LEFT JOIN commissions C ON C.CID=m.CID