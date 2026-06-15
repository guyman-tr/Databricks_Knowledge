SELECT *
FROM crm.silver_crm_livechattranscript
WHERE CreatedDate>>=date_trunc('year', current_date - interval '1 year')