select *
from crm.silver_crm_messagingsession
where CreatedDate>>=date_trunc('year', current_date - interval '1 year')