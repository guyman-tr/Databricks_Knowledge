SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'BI_DB_dbo'
  AND TABLE_NAME IN ('BI_DB_Vulnerability_Positions','BI_DB_Vulnerable_Customers','BI_DB_W_AML_PEP_Customers','BI_DB_W_AML_PEP_Customers_Trun','BI_DB_W_Mon_Compliance_CDIM_Report','BI_DB_W_Tue_Email_for_KYT','BI_DB_W_Wed_Compliance_Vulnerability_ALL','BI_DB_W8_Users_Status','BI_DB_Watchlist_Tracking_High_Level','BI_DB_Watchlist_Tracking_Item_Level','BI_DB_WatchListsByFunnel','BI_DB_WeeklyCopyBlock','BI_DB_Wire_PIP_Report','BI_DB_YearlyGain','Client_Balance_Breakdown_Instrument_Level','Compliance_BI_Leverage_Dashboard','Crypto_Top_1000_List','Dealing_CryptoRebate','Dealing_Unrealized_CryptoRebate','DWH_CIDs7DaysDeviation','DWH_CIDsDailyRisk','DWH_GainDaily','External_Price_History_LastPriceBeforeClose_Range','IR_Dashboard_Monitor_Checks','LTV_FromDB_ToBigQuery')
  AND COLUMN_NAME IN ('UpdateDate','LastUpdateDate','ModificationDate')
ORDER BY TABLE_NAME, COLUMN_NAME
