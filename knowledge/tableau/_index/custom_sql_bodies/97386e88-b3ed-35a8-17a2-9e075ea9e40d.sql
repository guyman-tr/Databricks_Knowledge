With alert as (
select
  h.CID,
  d.Name AlertType,
  h.CreationDate,
  st.Name StatusType,
  ds.Name StatusReason,
  r.RiskClassificationName
  ,re.Name as Regulation
from main.billing.bronze_alertservicedb_alert_alert h
left join main.billing.bronze_alertservicedb_configuration_alerttemplate a on h.TemplateID=a.Id
left join main.billing.bronze_alertservicedb_dictionary_alerttype d on d.Id=a.AlertTypeID
left join main.billing.bronze_alertservicedb_dictionary_category dc on dc.Id=a.CategoryID
left join main.billing.bronze_alertservicedb_dictionary_triggertype dt on dt.Id=a.TriggerType
LEFT join main.billing.bronze_alertservicedb_configuration_alertstatus ca on h.StatusID=ca.Id
LEFT join main.billing.bronze_alertservicedb_dictionary_statustype st on st.Id=ca.StatusTypeID
LEFT join main.billing.bronze_alertservicedb_dictionary_statusreason ds on ds.Id=ca.StatusReasonID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = h.CID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification r on r.RiskClassificationID = dc.RiskClassificationID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation re on re.ID = dc.RegulationID
WHERE 
  d.Name = 'LifetimeDeposits'
  and cast(h.CreationDate as date) >= '2025-07-21'
  and dc.RiskClassificationID = 0 -- High
  and dc.RegulationID in (4,10) -- ASIC,ASIC & GAML
)

,deposits as (
Select d.CID, sum(d.AmountUSD) as TotalDepositAmount
From alert c
JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit d on d.CID = c.CID
where d.PaymentStatusID = 2
group by d.CID
)

,details as (

select
  dc.RealCID
  ,bc.AMLComment
  ,bc.RiskComment
  ,max(case when cd.SuggestedDocumentTypeID = 7 then 1 else 0 end )as ProofofIncomeUploaded
  ,max(case when cd.SuggestedDocumentTypeID = 7 then cd.DateAdded end )as LatestDateProofofIncomeUploaded
from
  alert a
JOIN
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = a.CID
JOIN 
  main.general.bronze_etoro_backoffice_customer bc on bc.CID = dc.RealCID
LEFT JOIN
	main.billing.bronze_etoro_backoffice_customerdocument cd on cd.CID = dc.RealCID
LEFT JOIN
	main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype cdd on cdd.DocumentID = cd.DocumentID
GROUP BY 
    dc.RealCID
   ,bc.AMLComment
  ,bc.RiskComment
)

,SFtickets as (
SELECT DISTINCT 
  c.CID
  ,c.Type
  ,c.Status
  ,c.CaseNumber
from
  bi_output.bi_output_customer_customer_support_case c
JOIN 
alert a on a.CID = c.CID
where
  Status in ('In Routing','Open','On-hold') 
   and c.Type like '%AML%'
  )

,SFticketsfinal as (
Select 
  s.CID
  ,concat_ws(', ', collect_list(concat(s.Type, ' - ', s.Status,' - ',s.CaseNumber))) AS Type_Status_CaseNumber
FROM 
  SFtickets s
GROUP BY
  s.CID
)


select
a.alerttype
,a.cid
,cast(a.creationdate as date) as creationdate
,a.regulation
,a.riskclassificationname
,a.statusreason
,a.statustype
,d.totaldepositamount
,e.proofofincomeuploaded
,e.latestdateproofofincomeuploaded
,e.amlcomment
,e.riskcomment
,s.Type_Status_CaseNumber
FROM 
  alert a 
JOIN 
  deposits d on d.CID = a.CID
LEFT JOIN 
  details e on e.RealCID = a.CID
LEFT JOIN 
  SFticketsfinal s on s.CID = a.CID
WHERE 
  d.totaldepositamount >= 200000