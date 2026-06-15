select c.ID as ChatID,OwnerId,Bot_Type__c,CreatedDate,a.* FROM crm.silver_crm_livechattranscript c
left join bi_output.bi_output_customer_customer_support_agent_user a on a.ID=c.OwnerId and YEAR(a.ToDate)=9999
where YEAR(CreatedDate)>=2025