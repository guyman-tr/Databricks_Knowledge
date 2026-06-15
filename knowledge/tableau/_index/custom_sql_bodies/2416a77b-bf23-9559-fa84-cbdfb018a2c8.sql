select          bduts.CID
                ,bdsmu.AccountManagerID
		,CONCAT(bdsmu.FirstName, ' ', bdsmu.LastName) Name
		,bdsmu.Team
		,bdsmu.IsActive
		,bdsmu.Position
		,bduts.ActionType
		,bdsmu.ID
                ,bduts.Id CallID
		 ,CAST(trunc(etr_ymd, 'MM') AS DATE) ActiveDate
	  ,etr_ymd Date
      ,bduts.Duration
	,CAST(DATE_FORMAT(bduts.etr_ymd, 'yyyyMMdd') AS INT)   DateID 
from bi_output.BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
left join bi_output.bi_output_customer_customer_facing_agent_engagement bduts
on bduts.CreatedByID = bdsmu.ID
AND etr_ymd>='2024-08-01'
WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'