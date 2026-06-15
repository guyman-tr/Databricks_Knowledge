SELECT
    CAST(dp.etr_ymd AS DATE) AS Date,
    dp.DateID, 
    dp.ActiveDate, 
    pop.*, 
    dp.TotalDeposits, 
    dp.TotalCashouts, 
    dp.NetDeposits, 
    dp.RealizedEquity,
    dp.Revenue_Total, 
    dp.Revenue_CFD_Crypto, 
    dp.Revenue_CFD_Crypto_LevCFD, 
    dp.Revenue_CFD_Stocks, 
    dp.Revenue_CFD_Stocks_LevCFD, 
    dp.Revenue_Real_Crypto, 
    dp.Revenue_Real_Crypto_Lev1, 
    dp.Revenue_Real_Stocks, 
    dp.Revenue_Real_Stocks_Lev1, 
    dp.`Revenue_FX/Comm/Ind`
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata dp
    JOIN main.bi_output.bi_output_customer_compliance_mas_population pop ON dp.CID = pop.CID