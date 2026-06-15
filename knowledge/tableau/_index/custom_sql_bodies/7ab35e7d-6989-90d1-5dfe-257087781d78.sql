select l.*
    , fsc.RegulationID
    , dr.Name as Regulation
from bi_output.bi_output_finance_tables_bi_db_sharelending_loansandcollateralmain l
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
  on l.RealCID = fsc.RealCID
  and cast(date_format(l.ReportDate, 'yyyyMMdd') as int) between fsc.FromDateID and fsc.ToDateID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
  on fsc.RegulationID = dr.DWHRegulationID
where ReportDate >=<[Parameters].[Min Date for Report (copy)_109212307915939841]>
and ReportDate <=<[Parameters].[Max Date For Report (copy)_109212307915907072]>