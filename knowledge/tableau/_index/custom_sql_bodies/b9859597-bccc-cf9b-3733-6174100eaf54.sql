select * 
from main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk
where LedgerClosingDate >=
<[Parameters].[Min Date for Report (copy)_2478668694703943681]>
and 
LedgerClosingDate <=<[Parameters].[MaxDateForReport (copy)_2478668694703898624]>