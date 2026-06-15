select cd.* , dc.RealCID
from main.bi_output.bi_output_wf_view cd
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on cd.GCID=dc.GCID
where left(ClientID, 3) = 'CET'