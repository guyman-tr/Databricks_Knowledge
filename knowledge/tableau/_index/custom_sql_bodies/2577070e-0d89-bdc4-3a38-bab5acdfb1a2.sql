select *
from bi_output.bi_output_finance_tables_share_lending_aggregate
where etr_ymd between <[Parameters].[Parameter 1]> and <[Parameters].[Parameter 2]>