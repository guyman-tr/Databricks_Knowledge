select 'Stocks, ETFs' as source, Date
from
(

select max (Date) Date  from bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks
where Date in (select Date from(select Date, count(*) cnt from bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks where Date >='2023-01-01' group by Date having cnt >=100 ))
)base1

union all

select 'Other AssetTypes' as source, Date
from 
(
select max (Date) Date  from bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new
where Date in (select Date from (select Date, count(*) cnt from bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new where Date >='2023-01-01' group by Date having cnt >=100 ))
)base2