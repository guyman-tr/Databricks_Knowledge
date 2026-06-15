SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'BI_DB_dbo'
  AND TABLE_NAME IN ('BI_DB_EquitySnapshots','BI_DB_DepositSnapshots ','BI_DB_VerificationStatus','BI_DB_AML_FCA_Crypto_Threshold','BI_DB_PositionPnL_Agg_daily_Staking','BI_DB_Reg_UK_Compliance_VolumeByInstrument','BI_DB_Reg_UK_Compliance_KYC_Weekly_Export','BI_DB_Reg_UK_Compliance_Professional_OptUp','BI_DB_DDR_Customer_Daily_Status','BI_DB_DDR_Customer_Periodic_Status','BI_DB_DDR_Fact_AUM','BI_DB_DDR_Fact_MIMO_AllPlatforms','BI_DB_DDR_Fact_MIMO_eMoney_Platform','BI_DB_DDR_Fact_PnL','BI_DB_DDR_Fact_Revenue_Generating_Actions','BI_DB_DDR_Fact_Trading_Volumes_And_Amounts','BI_DB_UsageTracking_SF','BI_DB_InterestDaily','BI_DB_CIDFirstDates','BI_DB_DDR_CID_Level','BI_DB_DDR_Daily_Aggregated','BI_DB_DDR_TimeRange_Aggregated_Country_Level','BI_DB_DDR_CID_Level_Auxiliary_Metrics','BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics','BI_DB_Futures_Finance_Prep_Data')
  AND COLUMN_NAME IN ('UpdateDate','LastUpdateDate','ModificationDate','ReportDateID','DateID','EOD_Date','EODDate','SnapshotDate','LoadDate','InsertDate','CreateDate','Date')
ORDER BY TABLE_NAME, COLUMN_NAME
