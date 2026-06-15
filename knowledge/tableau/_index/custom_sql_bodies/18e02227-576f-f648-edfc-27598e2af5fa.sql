SELECT bdlad.*,
       CASE WHEN KPI='Registration' THEN dp.SubPlatform 
            WHEN KPI='FTDs' THEN dp2.SubPlatform END SubPlatform
FROM main.bi_output.bi_output_marketing_liveacquisitiondashboard bdlad
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca ON fca.RealCID=bdlad.CID AND KPI='Registration' AND bdlad.Date=fca.Occurred AND fca.ActionTypeID=41
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product dp ON fca.PlatformID=dp.ProductID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca2 ON fca2.RealCID=bdlad.CID AND KPI='FTDs' AND fca2.ActionTypeID=41 
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product dp2 ON fca2.PlatformID=dp2.ProductID
where bdlad.CID not in  (
            select Distinct a.CID
            from  main.general.bronze_etoro_dwh_v_customercustomerhourly_masked a
            join main.general.bronze_etoro_dwh_billingdeposithourly b on 
a.CID = b.CID
            where  (b.Amount * b.ExchangeRate) = 1)
--cast( ModificationDate as date) >= '2025-08-19'
            --and cast (ModificationDate as date) <= '2025-08-21'
           -- and  (b.Amount * b.ExchangeRate) = 1)