-- =============================================================================
-- Databricks Deep Lineage Column Comment Propagation: DWH_dbo.Fact_CustomerAction
-- Generated: 2026-03-16 | dwh-semantic-doc pipeline (deep lineage)
--
-- Source (UC): main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
-- Source (Synapse): DWH_dbo.Fact_CustomerAction
--
-- Target tables (60):
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy  (TABLE, 1 cols)
--   main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level  (TABLE, 4 cols)
--   main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport  (TABLE, 9 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata  (TABLE, 1 cols)
--   main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries  (TABLE, 1 cols)
--   main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips  (TABLE, 3 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly  (TABLE, 1 cols)
--   main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit  (TABLE, 8 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals  (TABLE, 6 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition  (TABLE, 8 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new  (TABLE, 1 cols)
--   main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment_history  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee  (TABLE, 6 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard  (TABLE, 3 cols)
--   main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg  (TABLE, 8 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions  (TABLE, 7 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution  (TABLE, 17 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms  (TABLE, 4 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends  (TABLE, 5 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts  (TABLE, 7 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance  (TABLE, 2 cols)
--   main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates  (TABLE, 1 cols)
--   main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown  (TABLE, 6 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients  (TABLE, 5 cols)
--   main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment  (TABLE, 1 cols)
--   main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level  (TABLE, 6 cols)
--   main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized  (TABLE, 1 cols)
--   main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips  (TABLE, 3 cols)
--   main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction  (TABLE, 24 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status  (TABLE, 2 cols)
--   main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned  (TABLE, 64 cols)
-- Target views (2):
--   main.bi_output_stg.v_semantic_fact_customeraction  (VIEW, 70 cols)
--   main.data_rooms.vw_fact_customeraction  (VIEW, 37 cols)
-- =============================================================================

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints (TABLE, 2 columns)
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level (TABLE, 4 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level ALTER COLUMN `PositionID` COMMENT 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level ALTER COLUMN `ActionTypeID` COMMENT 'Event type classifier. References Dim_ActionType.ActionTypeID — JOIN for Name, Category, CategoryID. Key filter: determines which other columns are populated. 1-3,39=position opens, 4-6,28,40=closes, 7=deposit, 8=cashout, 9=bonus, 14=login, 35=fees, 41=registration.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.';

-- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport (TABLE, 9 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `CommissionOnClose` COMMENT 'eToro markup (spread) at position close. 0 for opens and non-position events. For reopened positions: adjusted = new - original. Same meaning as Dim_Position.CommissionOnClose.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `FullCommissionOnClose` COMMENT 'Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as Dim_Position.FullCommissionOnClose.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `IsBuy` COMMENT 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport ALTER COLUMN `SettlementTypeID` COMMENT 'Settlement mechanism: 0=CFD, 1=Real asset, 2=TRS, 3=CMT (crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL for non-position events. Same meaning as Dim_Position.SettlementTypeID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis ALTER COLUMN `IsFTD` COMMENT 'First-Time Deposit flag: 1=this is the customer''s first deposit. NULL for non-deposit events.';

-- main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata (TABLE, 1 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingdailyrawdata ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ops_fraud_alert_analysis ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips (TABLE, 3 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `Occurred` COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit (TABLE, 8 columns)
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN `Commission` COMMENT 'eToro markup (spread) at position open in USD. 0 for non-position events. Same meaning as Dim_Position.Commission.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN `DepositID` COMMENT 'Deposit transaction identifier. NULL for non-deposit events.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN `PaymentStatusID` COMMENT 'Payment processing status for deposit/cashout events. NULL for non-payment events. References Dim_PaymentStatus.PaymentStatusID — JOIN for Name.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN `IsFTD` COMMENT 'First-Time Deposit flag: 1=this is the customer''s first deposit. NULL for non-deposit events.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN `FundingTypeID` COMMENT 'Payment method for deposits/withdrawals. 0 for non-deposit events. References Dim_FundingType.FundingTypeID — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN `SessionID` COMMENT 'STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN `PlatformID` COMMENT 'Product/platform identifier — badly named, actually references Dim_Product.ProductID (not a standalone platform enum). JOIN to Dim_Product for Product, Platform, SubPlatform. Only populated for ActionTypeID=14 (logins) and 41 (registrations).';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals (TABLE, 6 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `Occurred` COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `DepositID` COMMENT 'Deposit transaction identifier. NULL for non-deposit events.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `WithdrawPaymentID` COMMENT 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `CreditID` COMMENT 'Reference to source History.Credit.CreditID. Enables join back to credit history for audit.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition (TABLE, 8 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `PositionID` COMMENT 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `IsBuy` COMMENT 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailydividendsbyposition ALTER COLUMN `DividendID` COMMENT 'Dividend event identifier for dividend-related fees. NULL for non-dividend events.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment_history (TABLE, 1 columns)
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment_history ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee (TABLE, 6 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `Occurred` COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `DepositID` COMMENT 'Deposit transaction identifier. NULL for non-deposit events.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `WithdrawPaymentID` COMMENT 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `CreditID` COMMENT 'Reference to source History.Credit.CreditID. Enables join back to credit history for audit.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard (TABLE, 3 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `DepositID` COMMENT 'Deposit transaction identifier. NULL for non-deposit events.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `PaymentStatusID` COMMENT 'Payment processing status for deposit/cashout events. NULL for non-payment events. References Dim_PaymentStatus.PaymentStatusID — JOIN for Name.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `IsFTD` COMMENT 'First-Time Deposit flag: 1=this is the customer''s first deposit. NULL for non-deposit events.';

-- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg (TABLE, 8 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `CommissionOnClose` COMMENT 'eToro markup (spread) at position close. 0 for opens and non-position events. For reopened positions: adjusted = new - original. Same meaning as Dim_Position.CommissionOnClose.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `FullCommissionOnClose` COMMENT 'Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as Dim_Position.FullCommissionOnClose.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `IsBuy` COMMENT 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `SettlementTypeID` COMMENT 'Settlement mechanism: 0=CFD, 1=Real asset, 2=TRS, 3=CMT (crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL for non-position events. Same meaning as Dim_Position.SettlementTypeID.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions (TABLE, 7 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `ActionTypeID` COMMENT 'Event type classifier. References Dim_ActionType.ActionTypeID — JOIN for Name, Category, CategoryID. Key filter: determines which other columns are populated. 1-3,39=position opens, 4-6,28,40=closes, 7=deposit, 8=cashout, 9=bonus, 14=login, 35=fees, 41=registration.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `IsBuy` COMMENT 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution (TABLE, 17 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `PositionID` COMMENT 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier for position events. 0=non-position event. 1=no leverage (real ownership). Same meaning as Dim_Position.Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `IsBuy` COMMENT 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `ActionTypeID` COMMENT 'Event type classifier. References Dim_ActionType.ActionTypeID — JOIN for Name, Category, CategoryID. Key filter: determines which other columns are populated. 1-3,39=position opens, 4-6,28,40=closes, 7=deposit, 8=cashout, 9=bonus, 14=login, 35=fees, 41=registration.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `CompensationReasonID` COMMENT 'Compensation reason for compensation events (ActionTypeID=36) and position opens (airdrop identification). References BackOffice.CompensationReason. 0 for non-compensation events.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `IsFeeDividend` COMMENT 'Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See DSM-1463.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `Occurred` COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `Description` COMMENT 'Human-readable description. Mainly for ActionTypeID=35 (fees): "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". Also for deposits, stop-loss edits.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution ALTER COLUMN `SettlementTypeID` COMMENT 'Settlement mechanism: 0=CFD, 1=Real asset, 2=TRS, 3=CMT (crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL for non-position events. Same meaning as Dim_Position.SettlementTypeID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms (TABLE, 4 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN `FundingTypeID` COMMENT 'Payment method for deposits/withdrawals. 0 for non-deposit events. References Dim_FundingType.FundingTypeID — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN `IsRedeem` COMMENT 'Redeem flag: 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as Dim_Position.IsRedeem.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_copydailydata ALTER COLUMN `commission` COMMENT 'eToro markup (spread) at position open in USD. 0 for non-position events. Same meaning as Dim_Position.Commission.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_asic_clientbalancefinance ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends (TABLE, 5 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rolloverfee_dividends ALTER COLUMN `DividendID` COMMENT 'Dividend event identifier for dividend-related fees. NULL for non-dividend events.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_new_compensationbreakdown ALTER COLUMN `CompensationReasonID` COMMENT 'Compensation reason for compensation events (ActionTypeID=36) and position opens (airdrop identification). References BackOffice.CompensationReason. 0 for non-compensation events.';

-- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts (TABLE, 7 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `PositionID` COMMENT 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier for position events. 0=non-position event. 1=no leverage (real ownership). Same meaning as Dim_Position.Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `Occurred` COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';

-- main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_usersettingswalletallowance ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';

-- main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates (TABLE, 1 columns)
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown (TABLE, 6 columns)
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `IsBuy` COMMENT 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier for position events. 0=non-position event. 1=no leverage (real ownership). Same meaning as Dim_Position.Leverage.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `FullCommission` COMMENT 'Full spread at position open = market spread + eToro markup. NULL for non-position events. Same meaning as Dim_Position.FullCommission.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN `CountryIDByIP` COMMENT 'Country determined by IP geolocation. Populated for logins and registrations. References Dim_Country.CountryID — JOIN for country name.';

-- main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients (TABLE, 5 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier for position events. 0=non-position event. 1=no leverage (real ownership). Same meaning as Dim_Position.Leverage.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `FullCommission` COMMENT 'Full spread at position open = market spread + eToro markup. NULL for non-position events. Same meaning as Dim_Position.FullCommission.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients ALTER COLUMN `FullCommissionOnClose` COMMENT 'Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as Dim_Position.FullCommissionOnClose.';

-- main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment (TABLE, 1 columns)
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level (TABLE, 6 columns)
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `SettlementTypeID` COMMENT 'Settlement mechanism: 0=CFD, 1=Real asset, 2=TRS, 3=CMT (crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL for non-position events. Same meaning as Dim_Position.SettlementTypeID.';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level ALTER COLUMN `IsBuy` COMMENT 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.';

-- main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_getprovideruseridnormalized ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';

-- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips (TABLE, 3 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `Occurred` COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';

-- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction (TABLE, 24 columns)
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `DemoCID` COMMENT 'Demo-account Customer ID. Always 0 in this table (real accounts only).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `IPNumber` COMMENT 'IP address as numeric value. Populated for logins and registrations.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `IsReal` COMMENT 'Account type flag. Always 1 in this table (real accounts only).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `ActionTypeID` COMMENT 'Event type classifier. References Dim_ActionType.ActionTypeID — JOIN for Name, Category, CategoryID. Key filter: determines which other columns are populated. 1-3,39=position opens, 4-6,28,40=closes, 7=deposit, 8=cashout, 9=bonus, 14=login, 35=fees, 41=registration.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `PlatformTypeID` COMMENT 'Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `PositionID` COMMENT 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `CampaignID` COMMENT 'Marketing campaign identifier. 0 if not campaign-related. References Dim_Campaign.CampaignID — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `BonusTypeID` COMMENT 'Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus. References Dim_BonusType.BonusTypeID — JOIN for Name, IsWithdrawable, IsActive.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `FundingTypeID` COMMENT 'Payment method for deposits/withdrawals. 0 for non-deposit events. References Dim_FundingType.FundingTypeID — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `LoginID` COMMENT 'Login session identifier from Billing.Login. 0 for non-login events.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `WithdrawID` COMMENT 'Withdrawal request ID for cashout events. 0 for non-cashout events.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `PostID` COMMENT 'Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. Dead data — no longer updated.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `CaseID` COMMENT 'CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `TimeID` COMMENT 'Hour of action (0-23). Derived from DATEPART(HOUR, Occurred).';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `CompensationReasonID` COMMENT 'Compensation reason for compensation events (ActionTypeID=36) and position opens (airdrop identification). References BackOffice.CompensationReason. 0 for non-compensation events.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `WithdrawPaymentID` COMMENT 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `DepositID` COMMENT 'Deposit transaction identifier. NULL for non-deposit events.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction ALTER COLUMN `HistoryID` COMMENT 'Intended as unique key but contains duplicates — NOT reliable. Never use for JOINs, deduplication, or row identification.';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';

-- main.bi_output_stg.v_semantic_fact_customeraction (VIEW, 70 columns)
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`HistoryID` IS 'Intended as unique key but contains duplicates — NOT reliable. Never use for JOINs, deduplication, or row identification.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`GCID` IS 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`RealCID` IS 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`DemoCID` IS 'Demo-account Customer ID. Always 0 in this table (real accounts only).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`Occurred` IS 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IPNumber` IS 'IP address as numeric value. Populated for logins and registrations.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsReal` IS 'Account type flag. Always 1 in this table (real accounts only).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`ActionTypeID` IS 'Event type classifier. References Dim_ActionType.ActionTypeID — JOIN for Name, Category, CategoryID. Key filter: determines which other columns are populated. 1-3,39=position opens, 4-6,28,40=closes, 7=deposit, 8=cashout, 9=bonus, 14=login, 35=fees, 41=registration.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`PlatformTypeID` IS 'Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`InstrumentID` IS 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`Amount` IS 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`Leverage` IS 'Leverage multiplier for position events. 0=non-position event. 1=no leverage (real ownership). Same meaning as Dim_Position.Leverage.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`NetProfit` IS 'Realized P&L for position closes in USD. 0 for opens and non-position events. Same meaning as Dim_Position.NetProfit.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`Commission` IS 'eToro markup (spread) at position open in USD. 0 for non-position events. Same meaning as Dim_Position.Commission.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`PositionID` IS 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`CampaignID` IS 'Marketing campaign identifier. 0 if not campaign-related. References Dim_Campaign.CampaignID — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`BonusTypeID` IS 'Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus. References Dim_BonusType.BonusTypeID — JOIN for Name, IsWithdrawable, IsActive.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`FundingTypeID` IS 'Payment method for deposits/withdrawals. 0 for non-deposit events. References Dim_FundingType.FundingTypeID — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`LoginID` IS 'Login session identifier from Billing.Login. 0 for non-login events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`MirrorID` IS 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`WithdrawID` IS 'Withdrawal request ID for cashout events. 0 for non-cashout events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`DurationInSeconds` IS 'Login session duration in seconds. NULL for non-login events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`PostID` IS 'Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. Dead data — no longer updated.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`CaseID` IS 'CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`DateID` IS 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`TimeID` IS 'Hour of action (0-23). Derived from DATEPART(HOUR, Occurred).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`StatusID` IS 'Row status. Nearly always 1 (active). NULL for ~2M rows.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`PreviousOccurred` IS 'Deprecated/unused column. NULL for most rows — not reliably populated. Do not use.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`CompensationReasonID` IS 'Compensation reason for compensation events (ActionTypeID=36) and position opens (airdrop identification). References BackOffice.CompensationReason. 0 for non-compensation events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`WithdrawPaymentID` IS 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`CommissionOnClose` IS 'eToro markup (spread) at position close. 0 for opens and non-position events. For reopened positions: adjusted = new - original. Same meaning as Dim_Position.CommissionOnClose.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsPlug` IS 'Deprecated/unused column. Always NULL.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`DepositID` IS 'Deposit transaction identifier. NULL for non-deposit events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`PostRootID` IS 'Root post ID for social engagement events. NULL for non-social events. Dead data — no longer updated.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`FullCommission` IS 'Full spread at position open = market spread + eToro markup. NULL for non-position events. Same meaning as Dim_Position.FullCommission.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`FullCommissionOnClose` IS 'Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as Dim_Position.FullCommissionOnClose.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`RedeemID` IS 'Crypto redemption transaction reference. NULL when not a redeem. Same meaning as Dim_Position.RedeemID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`RedeemStatus` IS 'Crypto redemption status: 0=N/A, 1=Pending, 6=Closed by redeem, 20=Terminated, 21=FailedToCancel. Same meaning as Dim_Position.RedeemStatus.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`SessionID` IS 'STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsRedeem` IS 'Redeem flag: 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as Dim_Position.IsRedeem.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`RegulationIDOnOpen` IS 'Regulatory jurisdiction at position open. 0=None, 1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 9=FSA Seychelles. NULL for non-position events. Same meaning as Dim_Position.RegulationIDOnOpen. Refs Dim_Regulation.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`PlatformID` IS 'Product/platform identifier — badly named, actually references Dim_Product.ProductID (not a standalone platform enum). JOIN to Dim_Product for Product, Platform, SubPlatform. Only populated for ActionTypeID=14 (logins) and 41 (registrations).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`ReopenForPositionID` IS 'For reopened positions: the PositionID of the original closed position. Same meaning as Dim_Position.ReopenForPositionID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsReOpen` IS 'Reopen flag: 1=position created by reopening a previously closed position. Same meaning as Dim_Position.IsReOpen.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`CommissionOnCloseOrig` IS 'Original CommissionOnClose before reopen adjustment. Same meaning as Dim_Position.CommissionOnCloseOrig.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`FullCommissionOnCloseOrig` IS 'Original FullCommissionOnClose before reopen adjustment. Same meaning as Dim_Position.FullCommissionOnCloseOrig.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`OriginalPositionID` IS 'For partial-close children: parent PositionID. When OriginalPositionID != PositionID, this is a partial-close child. Same meaning as Dim_Position.OriginalPositionID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsPartialCloseParent` IS 'Flag: 1=has had partial-close children. Set by SP_Fact_CustomerAction_IsParitalCloseParent. Same meaning as Dim_Position.IsPartialCloseParent.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsPartialCloseChild` IS 'Flag: 1=created by partial close. Filter out (ISNULL(IsPartialCloseChild,0)=0) when counting positions. Same meaning as Dim_Position.IsPartialCloseChild.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`InitialUnits` IS 'Original unit count at position open. Never updated on partial close. Same meaning as Dim_Position.InitialUnits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`PaymentStatusID` IS 'Payment processing status for deposit/cashout events. NULL for non-payment events. References Dim_PaymentStatus.PaymentStatusID — JOIN for Name.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsDiscounted` IS 'Discounted pricing flag: 0=standard, 1=discounted (VIP/partner). Same meaning as Dim_Position.IsDiscounted.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsSettled` IS 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`CommissionByUnits` IS 'Commission prorated by units: (AmountInUnitsDecimal/InitialUnits)*Commission. Same meaning as Dim_Position.CommissionByUnits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`FullCommissionByUnits` IS 'Full spread prorated by units: (AmountInUnitsDecimal/InitialUnits)*FullCommission. Same meaning as Dim_Position.FullCommissionByUnits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsFTD` IS 'First-Time Deposit flag: 1=this is the customer''s first deposit. NULL for non-deposit events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`CountryIDByIP` IS 'Country determined by IP geolocation. Populated for logins and registrations. References Dim_Country.CountryID — JOIN for country name.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsAnonymousIP` IS 'Anonymous IP flag: 1=connection via anonymous proxy/VPN. NULL for most rows.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`ProxyType` IS 'Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsFeeDividend` IS 'Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See DSM-1463.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsAirDrop` IS 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`DividendID` IS 'Dividend event identifier for dividend-related fees. NULL for non-dividend events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`MoveMoneyReasonID` IS 'Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. Refs Dictionary.MoveMoneyReason.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`SettlementTypeID` IS 'Settlement mechanism: 0=CFD, 1=Real asset, 2=TRS, 3=CMT (crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL for non-position events. Same meaning as Dim_Position.SettlementTypeID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`DLTOpen` IS 'DLT (German crypto broker) flag at open: 1=opened on DLT platform, 0/NULL=not DLT. Same meaning as Dim_Position.DLTOpen.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`DLTClose` IS 'DLT (German crypto broker) flag at close: 1=closed on DLT platform. Same meaning as Dim_Position.DLTClose.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`OpenMarkupByUnits` IS 'Open markup prorated by units: OpenMarkup * AmountInUnitsDecimal / InitialUnits. Same meaning as Dim_Position.OpenMarkupByUnits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`Description` IS 'Human-readable description. Mainly for ActionTypeID=35 (fees): "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". Also for deposits, stop-loss edits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`IsBuy` IS 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.`CreditID` IS 'Reference to source History.Credit.CreditID. Enables join back to credit history for audit.';

-- main.data_rooms.vw_fact_customeraction (VIEW, 37 columns)
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`ActionTypeID` IS 'Event type classifier. References Dim_ActionType.ActionTypeID — JOIN for Name, Category, CategoryID. Key filter: determines which other columns are populated. 1-3,39=position opens, 4-6,28,40=closes, 7=deposit, 8=cashout, 9=bonus, 14=login, 35=fees, 41=registration.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`HistoryID` IS 'Intended as unique key but contains duplicates — NOT reliable. Never use for JOINs, deduplication, or row identification.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`GCID` IS 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`RealCID` IS 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`Occurred` IS 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`IsReal` IS 'Account type flag. Always 1 in this table (real accounts only).';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`PlatformTypeID` IS 'Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`InstrumentID` IS 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`Amount` IS 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`Leverage` IS 'Leverage multiplier for position events. 0=non-position event. 1=no leverage (real ownership). Same meaning as Dim_Position.Leverage.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`NetProfit` IS 'Realized P&L for position closes in USD. 0 for opens and non-position events. Same meaning as Dim_Position.NetProfit.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`Commission` IS 'eToro markup (spread) at position open in USD. 0 for non-position events. Same meaning as Dim_Position.Commission.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`PositionID` IS 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`MirrorID` IS 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`WithdrawID` IS 'Withdrawal request ID for cashout events. 0 for non-cashout events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`DurationInSeconds` IS 'Login session duration in seconds. NULL for non-login events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`DateID` IS 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`TimeID` IS 'Hour of action (0-23). Derived from DATEPART(HOUR, Occurred).';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`CompensationReasonID` IS 'Compensation reason for compensation events (ActionTypeID=36) and position opens (airdrop identification). References BackOffice.CompensationReason. 0 for non-compensation events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`WithdrawPaymentID` IS 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`CommissionOnClose` IS 'eToro markup (spread) at position close. 0 for opens and non-position events. For reopened positions: adjusted = new - original. Same meaning as Dim_Position.CommissionOnClose.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`DepositID` IS 'Deposit transaction identifier. NULL for non-deposit events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`FullCommission` IS 'Full spread at position open = market spread + eToro markup. NULL for non-position events. Same meaning as Dim_Position.FullCommission.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`FullCommissionOnClose` IS 'Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as Dim_Position.FullCommissionOnClose.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`RedeemID` IS 'Crypto redemption transaction reference. NULL when not a redeem. Same meaning as Dim_Position.RedeemID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`RedeemStatus` IS 'Crypto redemption status: 0=N/A, 1=Pending, 6=Closed by redeem, 20=Terminated, 21=FailedToCancel. Same meaning as Dim_Position.RedeemStatus.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`SessionID` IS 'STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`IsRedeem` IS 'Redeem flag: 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as Dim_Position.IsRedeem.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`RegulationIDOnOpen` IS 'Regulatory jurisdiction at position open. 0=None, 1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 9=FSA Seychelles. NULL for non-position events. Same meaning as Dim_Position.RegulationIDOnOpen. Refs Dim_Regulation.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`PlatformID` IS 'Product/platform identifier — badly named, actually references Dim_Product.ProductID (not a standalone platform enum). JOIN to Dim_Product for Product, Platform, SubPlatform. Only populated for ActionTypeID=14 (logins) and 41 (registrations).';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`ReopenForPositionID` IS 'For reopened positions: the PositionID of the original closed position. Same meaning as Dim_Position.ReopenForPositionID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`IsReOpen` IS 'Reopen flag: 1=position created by reopening a previously closed position. Same meaning as Dim_Position.IsReOpen.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`IsSettled` IS 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`IsFTD` IS 'First-Time Deposit flag: 1=this is the customer''s first deposit. NULL for non-deposit events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`IsFeeDividend` IS 'Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See DSM-1463.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`IsAirDrop` IS 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.`MoveMoneyReasonID` IS 'Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. Refs Dictionary.MoveMoneyReason.';

-- main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned (TABLE, 64 columns)
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `HistoryID` COMMENT 'Intended as unique key but contains duplicates — NOT reliable. Never use for JOINs, deduplication, or row identification.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `GCID` COMMENT 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `RealCID` COMMENT 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `DemoCID` COMMENT 'Demo-account Customer ID. Always 0 in this table (real accounts only).';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `Occurred` COMMENT 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IPNumber` COMMENT 'IP address as numeric value. Populated for logins and registrations.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsReal` COMMENT 'Account type flag. Always 1 in this table (real accounts only).';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `ActionTypeID` COMMENT 'Event type classifier. References Dim_ActionType.ActionTypeID — JOIN for Name, Category, CategoryID. Key filter: determines which other columns are populated. 1-3,39=position opens, 4-6,28,40=closes, 7=deposit, 8=cashout, 9=bonus, 14=login, 35=fees, 41=registration.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `PlatformTypeID` COMMENT 'Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `InstrumentID` COMMENT 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `Amount` COMMENT 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `Leverage` COMMENT 'Leverage multiplier for position events. 0=non-position event. 1=no leverage (real ownership). Same meaning as Dim_Position.Leverage.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `NetProfit` COMMENT 'Realized P&L for position closes in USD. 0 for opens and non-position events. Same meaning as Dim_Position.NetProfit.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `Commission` COMMENT 'eToro markup (spread) at position open in USD. 0 for non-position events. Same meaning as Dim_Position.Commission.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `PositionID` COMMENT 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `CampaignID` COMMENT 'Marketing campaign identifier. 0 if not campaign-related. References Dim_Campaign.CampaignID — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `BonusTypeID` COMMENT 'Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus. References Dim_BonusType.BonusTypeID — JOIN for Name, IsWithdrawable, IsActive.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `FundingTypeID` COMMENT 'Payment method for deposits/withdrawals. 0 for non-deposit events. References Dim_FundingType.FundingTypeID — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `LoginID` COMMENT 'Login session identifier from Billing.Login. 0 for non-login events.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `MirrorID` COMMENT 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `WithdrawID` COMMENT 'Withdrawal request ID for cashout events. 0 for non-cashout events.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `DurationInSeconds` COMMENT 'Login session duration in seconds. NULL for non-login events.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `PostID` COMMENT 'Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. Dead data — no longer updated.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `CaseID` COMMENT 'CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `DateID` COMMENT 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `TimeID` COMMENT 'Hour of action (0-23). Derived from DATEPART(HOUR, Occurred).';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `StatusID` COMMENT 'Row status. Nearly always 1 (active). NULL for ~2M rows.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `PreviousOccurred` COMMENT 'Deprecated/unused column. NULL for most rows — not reliably populated. Do not use.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `CompensationReasonID` COMMENT 'Compensation reason for compensation events (ActionTypeID=36) and position opens (airdrop identification). References BackOffice.CompensationReason. 0 for non-compensation events.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `WithdrawPaymentID` COMMENT 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `CommissionOnClose` COMMENT 'eToro markup (spread) at position close. 0 for opens and non-position events. For reopened positions: adjusted = new - original. Same meaning as Dim_Position.CommissionOnClose.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsPlug` COMMENT 'Deprecated/unused column. Always NULL.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `DepositID` COMMENT 'Deposit transaction identifier. NULL for non-deposit events.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `PostRootID` COMMENT 'Root post ID for social engagement events. NULL for non-social events. Dead data — no longer updated.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `FullCommission` COMMENT 'Full spread at position open = market spread + eToro markup. NULL for non-position events. Same meaning as Dim_Position.FullCommission.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `FullCommissionOnClose` COMMENT 'Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as Dim_Position.FullCommissionOnClose.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `RedeemID` COMMENT 'Crypto redemption transaction reference. NULL when not a redeem. Same meaning as Dim_Position.RedeemID.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `RedeemStatus` COMMENT 'Crypto redemption status: 0=N/A, 1=Pending, 6=Closed by redeem, 20=Terminated, 21=FailedToCancel. Same meaning as Dim_Position.RedeemStatus.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `SessionID` COMMENT 'STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsRedeem` COMMENT 'Redeem flag: 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as Dim_Position.IsRedeem.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `RegulationIDOnOpen` COMMENT 'Regulatory jurisdiction at position open. 0=None, 1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 9=FSA Seychelles. NULL for non-position events. Same meaning as Dim_Position.RegulationIDOnOpen. Refs Dim_Regulation.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `PlatformID` COMMENT 'Product/platform identifier — badly named, actually references Dim_Product.ProductID (not a standalone platform enum). JOIN to Dim_Product for Product, Platform, SubPlatform. Only populated for ActionTypeID=14 (logins) and 41 (registrations).';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `ReopenForPositionID` COMMENT 'For reopened positions: the PositionID of the original closed position. Same meaning as Dim_Position.ReopenForPositionID.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsReOpen` COMMENT 'Reopen flag: 1=position created by reopening a previously closed position. Same meaning as Dim_Position.IsReOpen.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `CommissionOnCloseOrig` COMMENT 'Original CommissionOnClose before reopen adjustment. Same meaning as Dim_Position.CommissionOnCloseOrig.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `FullCommissionOnCloseOrig` COMMENT 'Original FullCommissionOnClose before reopen adjustment. Same meaning as Dim_Position.FullCommissionOnCloseOrig.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `OriginalPositionID` COMMENT 'For partial-close children: parent PositionID. When OriginalPositionID != PositionID, this is a partial-close child. Same meaning as Dim_Position.OriginalPositionID.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsPartialCloseParent` COMMENT 'Flag: 1=has had partial-close children. Set by SP_Fact_CustomerAction_IsParitalCloseParent. Same meaning as Dim_Position.IsPartialCloseParent.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsPartialCloseChild` COMMENT 'Flag: 1=created by partial close. Filter out (ISNULL(IsPartialCloseChild,0)=0) when counting positions. Same meaning as Dim_Position.IsPartialCloseChild.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `InitialUnits` COMMENT 'Original unit count at position open. Never updated on partial close. Same meaning as Dim_Position.InitialUnits.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `PaymentStatusID` COMMENT 'Payment processing status for deposit/cashout events. NULL for non-payment events. References Dim_PaymentStatus.PaymentStatusID — JOIN for Name.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsDiscounted` COMMENT 'Discounted pricing flag: 0=standard, 1=discounted (VIP/partner). Same meaning as Dim_Position.IsDiscounted.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsSettled` COMMENT 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `CommissionByUnits` COMMENT 'Commission prorated by units: (AmountInUnitsDecimal/InitialUnits)*Commission. Same meaning as Dim_Position.CommissionByUnits.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `FullCommissionByUnits` COMMENT 'Full spread prorated by units: (AmountInUnitsDecimal/InitialUnits)*FullCommission. Same meaning as Dim_Position.FullCommissionByUnits.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsFTD` COMMENT 'First-Time Deposit flag: 1=this is the customer''s first deposit. NULL for non-deposit events.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `CountryIDByIP` COMMENT 'Country determined by IP geolocation. Populated for logins and registrations. References Dim_Country.CountryID — JOIN for country name.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsAnonymousIP` COMMENT 'Anonymous IP flag: 1=connection via anonymous proxy/VPN. NULL for most rows.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `ProxyType` COMMENT 'Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsFeeDividend` COMMENT 'Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See DSM-1463.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `IsAirDrop` COMMENT 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `DividendID` COMMENT 'Dividend event identifier for dividend-related fees. NULL for non-dividend events.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `MoveMoneyReasonID` COMMENT 'Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. Refs Dictionary.MoveMoneyReason.';
ALTER TABLE main.compliance_stg.rnd_output_gold_sql_dp_prod_we_dwh_dbo_fact_customeraction_delta_partitionioned ALTER COLUMN `SettlementTypeID` COMMENT 'Settlement mechanism: 0=CFD, 1=Real asset, 2=TRS, 3=CMT (crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL for non-position events. Same meaning as Dim_Position.SettlementTypeID.';
