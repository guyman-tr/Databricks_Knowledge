With alert as (
SELECT
	h.CID,
	h.Id as AlertID,
	h.ModificationDate,
	d.Name as AlertType,
	h.CreationDate,
	st.Name as StatusType,
	ds.Name as StatusReason,
	dt.Name as TriggerType,
	dc.Name as Category,
	h.Resource,
	h.UnsatisfiedRulesData
FROM
	main.billing.bronze_alertservicedb_alert_alert h
	LEFT JOIN main.billing.bronze_alertservicedb_configuration_alerttemplate a ON h.TemplateID = a.Id
	LEFT JOIN main.billing.bronze_alertservicedb_dictionary_alerttype d ON d.Id = a.AlertTypeID
	LEFT JOIN main.billing.bronze_alertservicedb_dictionary_category dc ON dc.Id = a.CategoryID
	LEFT JOIN main.billing.bronze_alertservicedb_dictionary_triggertype dt ON dt.Id = a.TriggerType
	LEFT JOIN main.billing.bronze_alertservicedb_configuration_alertstatus ca ON h.StatusID = ca.Id
	LEFT JOIN main.billing.bronze_alertservicedb_dictionary_statustype st ON st.Id = ca.StatusTypeID
	LEFT JOIN main.billing.bronze_alertservicedb_dictionary_statusreason ds ON ds.Id = ca.StatusReasonID
)
Select 
	a.AlertType
	,cast(a.CreationDate as date) as CreationDate
	,count(a.AlertID) as TotalAlerts
	,a.Category as CategoryName
	,a.StatusType
	,r.Name as Regulation
from 
	alert a 
LEFT JOIN 
	 main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = a.CID
LEFT JOIN 
	main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID = dc.RegulationID
GROUP BY 
	a.AlertType
	,cast(a.CreationDate as date)
	,a.Category
	,a.StatusType
	,r.Name