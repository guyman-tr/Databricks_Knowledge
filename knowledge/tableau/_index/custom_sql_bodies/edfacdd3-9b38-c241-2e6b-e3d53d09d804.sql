SELECT CAST(CreatedDate as DATE) AS cChangeDate,concat(a.FirstName,' ',a.LastName)as ChangedBy,a.SubRole,Field,OldValue,NewValue,c.CaseNumber,c.Goodwill_Gesture__c as GoodWill,c.Technical_Refund__c as TechnicalRefund

FROM crm.silver_crm_casehistory ch
join (select CaseNumber,Case_Id_18__c,Goodwill_Gesture__c,Technical_Refund__c from crm.silver_crm_case )c on c.Case_Id_18__c=ch.CaseId
left join bi_output.bi_output_customer_customer_support_agent_user a on a.ID=ch.CreatedById and YEAR(a.ToDate)=9999
where NewValue = 'Normal' and OldValue='Phase 2'