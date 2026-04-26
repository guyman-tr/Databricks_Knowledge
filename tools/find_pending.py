import json

with open(r'C:\Users\guyman\Documents\github\Databricks_Knowledge\.specify\Configs\opsdb-objects-status.json', 'r', encoding='utf-8-sig') as f:
    opsdb = json.load(f)

bidb = {}
for item in opsdb:
    tname = item.get('TableName','')
    if tname.startswith('BI_DB_dbo.'):
        short = tname.replace('BI_DB_dbo.', '').strip()
        if short not in bidb:
            bidb[short] = item['Priority']

blacklist = {
    'BI_DB_DDR_CID_Level', 'BI_DB_DDR_CID_Level_Auxiliary_Metrics',
    'BI_DB_DDR_Daily_Aggregated', 'BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics',
    'BI_DB_DDR_Process_Monitor', 'BI_DB_DDR_TimeRange_Aggregated_Country_Level',
}
hold_pattern = set(k for k in bidb if k.endswith('_HOLD'))

done = {
    'AML_German_Video_Ident', 'AML_InstrumentMetaData_Daily_Email',
    'AML_InstrumentMetaData_Daily_Email_DayToDay_Changes', 'BI_DB_AMLPeriodicReview',
    'BI_DB_AMLPeriodicReview_PostReview', 'BI_DB_AML_ASIC_Dashboard',
    'BI_DB_AML_BI_Alerts_MultipleAccountseMoney', 'BI_DB_AML_BI_Alerts_New',
    'BI_DB_AML_BI_Alerts_New_Master_SubAccount', 'BI_DB_AML_BI_Alerts_New_Singapore',
    'BI_DB_AML_Documents_Dashboard', 'BI_DB_AML_Documents_Request',
    'BI_DB_AML_FCA_Crypto_Threshold', 'BI_DB_AML_Gatsby_Alerts',
    'BI_DB_AML_High_Risk_Wallet', 'BI_DB_AML_IOB_Report',
    'BI_DB_AML_KYC_Process', 'BI_DB_AML_KYC_SOF', 'BI_DB_AML_PI_Abuse',
    'BI_DB_AML_PI_Abuse_CopierTable', 'BI_DB_AML_PI_Abuse_DeviceID_AS_PI',
    'BI_DB_AML_PI_Abuse_DeviceID_Copiers', 'BI_DB_AML_PI_Abuse_DeviceID_Copy_Side',
    'BI_DB_AML_PI_Abuse_DeviceID_PI_Side', 'BI_DB_AML_PI_Abuse_FID_Copy_Side',
    'BI_DB_AML_PI_Abuse_FID_PI_Side', 'BI_DB_AML_PI_Abuse_FID_Same_Copy',
    'BI_DB_AML_PI_Abuse_FID_Same_as_pi', 'BI_DB_AML_PI_Abuse_SameIP',
    'BI_DB_AML_Periodic_Review_AR', 'BI_DB_AML_Periodic_Review_HR',
    'BI_DB_AML_Periodic_Review_MR', 'BI_DB_AML_PlayerStatus_Changes',
    'BI_DB_AML_SAR_Report_FCA', 'BI_DB_AML_Singapore_Risk_Classification',
    'BI_DB_AML_SubEntity_Categorization', 'BI_DB_AM_Portfolio_Summary',
    'BI_DB_AffiliateCOAbuse', 'BI_DB_AffiliatePayment', 'BI_DB_AM_Contacted',
    'BI_DB_ASIC_ClientBalanceFinance', 'BI_DB_ASIC_CreditLine_At_transfer',
    'BI_DB_ASIC_GAML_Invested_Amount', 'BI_DB_ASIC_Monitoring_CFD_W_Sun',
    'BI_DB_ASIC_Monthly_Positions', 'BI_DB_AccountClosure',
    'BI_DB_AcquisitionFunnel_AGG', 'BI_DB_ActiveAffActualMonthly_Region_GroupAffName',
    'BI_DB_ActiveAffiliatesPlanned_Actual', 'BI_DB_AffiliateFTDsAndURLS',
    'BI_DB_Affiliate_Fraud_Loss', 'BI_DB_Affiliate_Guidlines_Report',
    'BI_DB_Affiliates_FraudMonitoring', 'BI_DB_Affiliates_VerificationSLA',
    'BI_DB_AppFlyer_Geo', 'BI_DB_AppFlyer_Reports', 'BI_DB_AvgHoldingTime',
    'BI_DB_Bing_PBI_Campaign_Dict', 'BI_DB_Bing_PBI_Daily_Perf',
    'BI_DB_Bing_PBI_Goals_Funnels', 'BI_DB_Bing_PBI_Group_Dict',
    'BI_DB_Blocked_Customers', 'BI_DB_CB_CycleGap_Categorization',
    'BI_DB_CIDFirstDates', 'BI_DB_CIDFunnelFlow', 'BI_DB_CIDLevel_Settlement_Report',
    'BI_DB_CID_Daily_AcquisitionFunnel_VBT', 'BI_DB_CID_Daily_NWA',
    'BI_DB_CMR_Phase2_ClientBalance', 'BI_DB_CMR_Phase2_CycleGap',
    'BI_DB_CMR_Phase2_EU_Outliers', 'BI_DB_CMR_Phase2_FinraGap',
    'BI_DB_CMR_Phase2_Finra_NonCash_Comps', 'BI_DB_CMR_Phase2_LiabilityDecomp',
    'BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted',
    'BI_DB_Capital_Adequacy_Daily_Equity', 'BI_DB_Capital_Adequacy_Daily_NOP_KASA',
    'BI_DB_Capital_Adequacy_Monthly_NOP', 'BI_DB_Capital_Guarantee',
    'BI_DB_ChargebackReport', 'BI_DB_Client_Balance_Aggregate_Level_New',
    'BI_DB_Client_Balance_CID_Level_New', 'BI_DB_Client_New_CompensationBreakdown',
    'BI_DB_ClubChangeLogProduct', 'BI_DB_ClusteringDailyPrepData', 'BI_DB_Compliance_Restriction_Lists_CIDs',
    'BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation',
    'BI_DB_FB_Conversion', 'BI_DB_FB_Performance',
    'BI_DB_Finance_Cashout_RollbackDetails', 'BI_DB_Finance_Net_MIMO',
    'BI_DB_FirstTimeFunded',
    'BI_DB_Compliance_Restriction_Lists_Countries',
    'BI_DB_Compliance_Restriction_Lists_Forbidden_Trading',
    'BI_DB_Corporates_SummaryReport', 'BI_DB_Crypto_Airdrop',
    'BI_DB_Crypto_Dashboard', 'BI_DB_Crypto_NOP', 'BI_DB_Crypto_NOP_CID',
    'BI_DB_Crypto_Net_Units_During_Month', 'BI_DB_Crypto_Net_Units_End_Of_Month',
    'BI_DB_Crypto_Zero', 'BI_DB_CycleGap', 'BI_DB_D_HighRedeemsApprovalForManagement',
    'BI_DB_DDR_Customer_Daily_Status', 'BI_DB_DDR_Customer_Periodic_Status',
    'BI_DB_DDR_Fact_AUM', 'BI_DB_DDR_Fact_MIMO_AllPlatforms',
    'BI_DB_DDR_Fact_MIMO_Options_Platform', 'BI_DB_DDR_Fact_MIMO_Trading_Platform',
    'BI_DB_DDR_Fact_MIMO_eMoney_Platform', 'BI_DB_DDR_Fact_Non_Revenue_Generating_Actions',
    'BI_DB_DDR_Fact_PnL', 'BI_DB_DDR_Fact_Revenue_Generating_Actions',
    'BI_DB_DDR_Fact_Trading_Volumes_And_Amounts',
    'BI_DB_DailyCommisionReport', 'BI_DB_DailyCommisionReport_Instrument_Agg',
    'BI_DB_DailyCommisionReport_Last2weeks', 'BI_DB_DailyCommisionReport_LastYear',
    'BI_DB_DailyCommisionReport_MonthlyData', 'BI_DB_DailyCommisionReport_ThisMonth',
    'BI_DB_DailyCommisionReport_ThisYear', 'BI_DB_DailyCommisionReport_Yesterday',
    'BI_DB_DailyCopyRevenue', 'BI_DB_DailyDividendsByPosition',
    'BI_DB_DailyZero_TreeSize_NEW', 'BI_DB_Daily_CB_Gaps_All',
    'BI_DB_Daily_CreditLine', 'BI_DB_Daily_Dividends', 'BI_DB_Daily_TradeData',
    'BI_DB_DepositSnapshots', 'BI_DB_DepositUsersFirstTouchPoints',
    'BI_DB_DepositWithdrawFee', 'BI_DB_eTorian_NetProfit', 'BI_DB_eTorian_PnL',
    'BI_DB_EquitySnapshots', 'BI_DB_FCA_Liabilities', 'BI_DB_IFRS15_Daily_Balance',
    'BI_DB_IFRS_15_Daily_Positions', 'BI_DB_Finance_Audit_Auxillary_Datapoints',
    'BI_DB_Finance_Non_US_Settlement_Report', 'BI_DB_Finance_Panel_Reports',
    'BI_DB_Finance_Panel_Reports_New', 'BI_DB_First5Actions', 'BI_DB_Flare_Eligibility',
    'BI_DB_Futures_Finance_Prep_Data', 'BI_DB_GAML_Real_Positions_Report_Closed',
    'BI_DB_GAML_Real_Positions_Report_Opened_2022', 'BI_DB_HighCOsAndRedeemsWithSF',
    'BI_DB_InactivityFees', 'BI_DB_Index_Dividend_TaxReport',
    'BI_DB_Index_Dividend_TaxReport_CID_Level', 'BI_DB_InterestDaily',
    'BI_DB_InstrumentsAlerts', 'BI_DB_InvestorsDetail', 'BI_DB_InvestorsKPI',
    'BI_DB_Investors_Top10', 'BI_DB_KYC_Panel', 'BI_DB_KYC_eToroMoney_UpgradedClubMembers',
    'BI_DB_LTV_BI_Actual_Daily_Snapshot', 'BI_DB_LTV_Predictions',
    'BI_DB_LTV_Revenue_Multipliers', 'BI_DB_LargeCashoutReport',
    'BI_DB_LimitedAccountsWithReasons', 'BI_DB_LiveAcquisitionDashboard',
    'BI_DB_LiveAcquisitionDashboard_Daily', 'BI_DB_M_AML_Report', 'BI_DB_M_AML_Report_AGG',
    'BI_DB_MarketingDailyRawData', 'BI_DB_MarketingMonthlyRawData',
    'BI_DB_MifidAccountType_Count', 'BI_DB_NOP_Distribution_Crypto',
    'BI_DB_Negative_Market_Monthly_Aggregated', 'BI_DB_Operations_Monthly_KPIs_Affiliates',
    'BI_DB_Outliers_New', 'BI_DB_PositionHoldingTime', 'BI_DB_PositionPnL',
    'BI_DB_PositionPnL_Agg_daily_Staking', 'BI_DB_Publications',
    'BI_DB_Real_Crypto_Loan', 'BI_DB_RealCrypto_Lev2',
    'BI_DB_Reg_UK_Compliance_KYC_Weekly_Export', 'BI_DB_Reg_UK_Compliance_Professional_OptUp',
    'BI_DB_Reg_UK_Compliance_VolumeByInstrument', 'BI_DB_Regulation_Change_Abuse_Categories',
    'BI_DB_Regulation_Change_Abuse_CIDs', 'BI_DB_RejectedDocuments',
    'BI_DB_RollOverFee_ByInstrument', 'BI_DB_RollOverFee_Dividends',
    'BI_DB_STDSnapshots', 'BI_DB_Scored_Appropriateness_Negative_Market',
    'BI_DB_Subsidieries_Realized_Commissions_Adjustments', 'BI_DB_Transactions_Per_Time_Unit',
    'BI_DB_US_Apex_Corporate_CA_Apex', 'BI_DB_US_Apex_Corporate_CA_etoro',
    'BI_DB_US_Apex_Fees_Charge', 'BI_DB_US_Apex_Instrument_Holders',
    'BI_DB_US_Apex_Recon_Cash_To_Clients_Accounts', 'BI_DB_US_Stocks_Apex_PFOF',
    'BI_DB_US_Stocks_MAU_DAU_KPI', 'BI_DB_USA_Equity_Deposits',
    'BI_DB_UK_CommissionReport_byLeverage', 'BI_DB_UsageTracking_SF',
    'BI_DB_User_Segment_Snapshot', 'BI_DB_VarCommission', 'BI_DB_VerificationStatus',
    'Client_Balance_Breakdown_Instrument_Level', 'Dealing_CryptoRebate',
    'Dealing_Unrealized_CryptoRebate',
}

skip = blacklist | hold_pattern | done
pending = [(k, v) for k, v in bidb.items() if k not in skip]
pending_sorted = sorted(pending, key=lambda x: (-x[1], x[0]))
print(f'Pending objects: {len(pending_sorted)}')
print()
print('Top 30 (highest priority first, then alpha):')
for name, prio in pending_sorted[:30]:
    print(f'  Priority {prio}: {name}')
