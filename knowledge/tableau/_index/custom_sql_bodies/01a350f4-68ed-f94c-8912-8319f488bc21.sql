select *
from crm.silver_crm_ai_session_entry__c
where CreatedDate>>=date_trunc('year', current_date - interval '1 year')