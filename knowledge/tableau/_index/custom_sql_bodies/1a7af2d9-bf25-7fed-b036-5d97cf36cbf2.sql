SELECT   dc.GCID
       , dc.RealCID
,case when r.CID is not null then 1 else 0 end IsUK 
       ,o.*
       ,fsc.IsCreditReportValidCB
       , dc.IsValidCustomer
       ,dr.Name Regulation
 FROM main.security_lending.gold_de_security_lending_equilend_daily_settled_balance  o
 JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON o.AccountNo = dc.EquiLendID
 JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON dc.RealCID = fsc.RealCID
 JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
         ON fsc.DateRangeID = dr.DateRangeID 
         AND CAST(DATE_FORMAT(o.etr_ymd, 'yyyyMMdd') AS INT)
         BETWEEN dr.FromDateID AND dr.ToDateID
  LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
ON fsc.RegulationID = dr.DWHRegulationID 
LEFT JOIN (
  Select distinct r.CID,r.etr_ymd
  FROM  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody_resolver r 
  WHERE  r.etr_ymd >=<[Parameters].[Parameter 2]> 
    and r.etr_ymd  <=<[Parameters].[Parameter 3]> ) r
  ON r.CID = dc.RealCID 
  AND  r.etr_ymd=o.etr_ymd
 WHERE  o.etr_ymd >=<[Parameters].[Parameter 2]> 
    and o.etr_ymd  <=<[Parameters].[Parameter 3]>