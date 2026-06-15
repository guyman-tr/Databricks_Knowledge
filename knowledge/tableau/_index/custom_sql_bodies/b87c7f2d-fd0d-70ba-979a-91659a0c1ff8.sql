select cd.*
      ,dc.RealCID
from  bi_output_stg.v_external_france_wealth_contracts_transactions cd
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on cd.GCID=dc.GCID