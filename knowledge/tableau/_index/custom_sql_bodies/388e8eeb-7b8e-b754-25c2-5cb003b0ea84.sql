select '1: Data source: Positions Credit table' as source, max(Occurred) as GMT_time  from trading.silver_etoro_trade_position
union all
select '2: Data source: Pricing Credit table' as source, max(Occurred) as GMT_time  from trading.bronze_etoro_trade_currencyprice 
union all
select '3: Clients exposure: Credit' as source, max_position_time as GMT_time from risk.risk_output_rm_tables_credit_client_pnl_cfd_instruments_2_updatime_time
union all
select '4: eToro exposure to LPs' as source, etoro_pnl_time as GMT_time from risk.risk_output_rm_tables_diffusion_etoro_pnl_instruments_2_update_time
union all
select '5: Risk Appetite: Indices and Commodities' as source, Date as GMT_time
from 
(
select max (Date) Date  from bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new
where Date in (select Date from (select Date, count(*) cnt from bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new where Date >='2023-01-01' group by Date having cnt >=100 ))
)base2