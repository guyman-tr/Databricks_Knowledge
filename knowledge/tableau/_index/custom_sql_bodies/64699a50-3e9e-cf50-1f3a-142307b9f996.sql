SELECT distinct bdsce.EventID,
       bdsce.EventName,
       bdsce.CreatedById,
       bdsce.CaseID,
       bdsce.EventType,
       bdsce.OldStatus,
       bdsce.NewStatus,
       bdsce.DoneBy,
       bdsce.DoneByCSDesk,
       bdsce.DoneByRole,
       bdsce.UpdatedByAutomaticProcess,
       bdsce.Occurred as FromDate,
       bdsce.ToDate,
       bdsce.UpdateDate,
       bdsce.EventNumber,
       bdsce.Touches,
       bdsce.IsWorkload,
       CAST(Occurred as Date) as Converteddate,
       bdsce.CaseNumber,
       bdsce.IsReopen,
      convert_timezone('UTC',u.TimeZoneSidKeys,bdsce.Occurred) AS FromDateTimeZone,
       DATEDIFF(SECOND, '2021-01-01', bdsce.Occurred) AS SecondsFrom
FROM main.bi_output.bi_output_customer_customer_support_case_event bdsce
LEFT JOIN (select ID,Case when ReportsTo in ('0050800000EE0zOAAT','0050800000GyOLrAAN','0050800000DArh6AAD') then 'Australia/Sydney' else TimeZoneSidKey end as TimeZoneSidKeys
from bi_output.bi_output_customer_customer_support_agent_user
where YEAR(ToDate)='9999') u   ON bdsce.DoneBy = u.ID 
where     bdsce.Occurred >= DATE_SUB(CURRENT_DATE(), 90)