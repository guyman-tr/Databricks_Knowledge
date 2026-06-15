-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_case_event
-- Captured: 2026-05-19T14:47:12Z
-- ==========================================================================

SELECT bdsce.EventID,
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
      CASE WHEN LAST(CASE WHEN bdsce.NewStatus != 'Closed' THEN bdsce.NewStatus END) over (partition by CaseID order by bdsce.Occurred ) = 'Solved' THEN 1 else 0 END IsSolved
FROM main.bi_output.bi_output_customer_customer_support_case_event bdsce
LEFT JOIN (select ID,Case when ReportsTo in ('0050800000EE0zOAAT','0050800000GyOLrAAN','0050800000DArh6AAD') then 'Australia/Sydney' else TimeZoneSidKey end as TimeZoneSidKeys
from bi_output.bi_output_customer_customer_support_agent_user
where YEAR(ToDate)='9999') u   ON bdsce.DoneBy = u.ID
