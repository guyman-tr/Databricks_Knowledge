SELECT
    dc.RealCID,
    dc.GCID,
    dc.OriginalCID AS DemoCID,
    dc.RegisteredReal,
    dc.FirstDepositDate,
    dc.SubSerialID,
    da.AffiliateID,
    da.Contact AS AffiliateName,
--    dcp.*,
    cm.Credit, 
    cm.BonusCredit,
    cm.RealizedEquity,
    cm.TotalCash,
    cm.etr_y,
    cm.etr_ym,
    cm.etr_ymd
FROM dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked da ON dc.AffiliateID = da.AffiliateID AND da.AffiliateID = 126663
--    LEFT JOIN bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_demo_cid_panel dcp ON dc.RealCID = dcp.CID
    LEFT JOIN main.bi_db.bronze_tradonomi_customer_customermoney cm ON dc.OriginalCID = cm.CID -- join dim cust to demo table using democids