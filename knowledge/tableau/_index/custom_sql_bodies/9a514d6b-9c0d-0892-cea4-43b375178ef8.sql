select * from bi_output.bi_output_customer_customer_support_case
where YEAR(CreatedDate)>='2024'
and EscalationDate is not null