SELECT 
  dep.Id,
  get_json_object(dep.Resource, '$.SubReason') AS SubReason
FROM 
  main.billing.bronze_alertservicedb_alert_alert dep