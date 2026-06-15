SELECT *
FROM 
(select distinct
    bdsmu.AccountManagerID,
    concat(bdsmu.FirstName, ' ', bdsmu.LastName) as Name,
    a.etr_ymd,
    a.CID,
    a.Id,
    a.ActionType,
    a.CallSummary,
    b.EngagementTopics,
     b.Status,
a.DateModified,
     ROW_Number() over (partition by a.CID ORDER BY a.etr_ymd DESC ) AS RN
from main.bi_output.bi_output_customer_customer_support_customer_engagement b
join main.bi_output.bi_output_customer_customer_facing_agent_engagement a on a.Id = b.Id
join main.bi_output.BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu on a.CreatedByID = bdsmu.ID
where --b.Status = 'Closed'
   a.ActionType in ('CompletedPhone','ZoomCall')
  and b.etr_ymd >= '2025-07-01'  
  --and bdsmu.ToDate = '9999-12-31T00:00:00.000Z'
)d
where RN =1