select *
from crm.silver_crm_case
where CreatedDate>>=date_trunc('year', current_date - interval '1 year')