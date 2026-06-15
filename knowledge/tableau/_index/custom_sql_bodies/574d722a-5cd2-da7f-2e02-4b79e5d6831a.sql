select ch.CaseId
      ,ch.NewValue
      ,MIN(ch.CreatedDate) CreatedDate
from main.crm.silver_crm_casehistory ch
left join main.bi_output.bi_output_customer_customer_support_agent_user au
on ch.NewValue = au.ID
where ch.Field = 'Owner'
--and (au.ReportsTo ='0051p000009Zj3lAAC' OR au.Id= '0050800000DiIFyAAN')
  GROUP BY ch.CaseId   
      ,ch.NewValue