Select [incident_id]
,[reporting_date]
,[reporter]
,[subject]
,[incident_type]
,[description]
,[responsible_party]
,[severity]
,[impact]
,[likelihood]
,[comments] 
,left (cast ([_fivetran_synced] as datetime),19) LastUpdate
From 
[ThirdParty_Fivetran].[Fivetran].[regulation].[regtech_incident_register]
Where [reporting_date] is not Null
and reporting_date > '2023-01-01'