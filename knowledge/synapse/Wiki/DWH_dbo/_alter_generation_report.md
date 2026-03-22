# DWH_dbo ALTER Generation Report

**Generated**: 2026-03-22 (updated — views included)
**Command**: `/generate-alter-dwh dwh_dbo`
**Engine**: `_batch_generate_lib.py` v1.0
**Schema**: DWH_dbo (129 wiki objects: 109 Tables + 20 Views)

---

## Summary

| Metric                      | Count |
| --------------------------- | ----- |
| **ALTER scripts generated** | 88    |
| **Tables**                  | 84    |
| **Views**                   | 4     |
| **No UC table exists**      | 40    |
| **Parse failures**          | 1 (V_Liabilities — wiki not finalized) |
| **Total wiki objects**      | 129   |

### Views in UC (4 generated + 1 pending)

| View | UC Target | Status |
|------|-----------|--------|
| v_Dim_Mirror | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror` | ALTER generated |
| V_Fact_SnapshotCustomer | `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer` | ALTER generated (PII Only) |
| V_Fact_SnapshotCustomer_FromDateID | `main.dwh...masked` + `main.pii_data...` | ALTER generated (PII Masked) |
| V_Fact_SnapshotEquity_FromDateID | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid` | ALTER generated |
| **V_Liabilities** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` | **Wiki needs finalization** |


---

## Generated (86) — Ready for `/deploy-alter-dwh`

### Previously Generated (41)


| #   | Object                                    | Type  | Columns | PII Cols | UC Target                                                                 |
| --- | ----------------------------------------- | ----- | ------- | -------- | ------------------------------------------------------------------------- |
| 1   | Dim_AffiliateCostType                     | Table | 4       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype                     |
| 2   | Dim_CashoutReason                         | Table | 3       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason                         |
| 3   | Dim_CashoutStatus                         | Table | 6       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus                         |
| 4   | Dim_ClientWithdrawReason                  | Table | 3       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason                  |
| 5   | Dim_ClosePositionReason                   | Table | 5       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason                   |
| 6   | Dim_CompensationReason                    | Table | 7       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason                    |
| 7   | Dim_ContactType                           | Table | 6       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contacttype                           |
| 8   | Dim_CountryIPAnonymousProxyType           | Table | 4       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymousproxytype           |
| 9   | Dim_CustomerChangeType                    | Table | 3       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype                    |
| 10  | Dim_Desk                                  | Table | 6       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk                                  |
| 11  | Dim_HistorySplitRatio                     | Table | 9       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio                     |
| 12  | Dim_Instrument                            | Table | 47      | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument                            |
| 13  | Dim_Instrument_Snapshot                   | Table | 9       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_snapshot                   |
| 14  | Dim_Label                                 | Table | 6       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label                                 |
| 15  | Dim_Language                              | Table | 8       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language                              |
| 16  | Dim_Manager                               | Table | 13      | 2        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager                               |
| 17  | Dim_MifidCategorization                   | Table | 3       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization                   |
| 18  | Dim_Mirror                                | Table | 26      | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror                                |
| 19  | Dim_MirrorType                            | Table | 3       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype                            |
| 20  | Dim_PaymentStatus                         | Table | 6       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus                         |
| 21  | Dim_PlayerStatusReasons                   | Table | 3       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons                   |
| 22  | Dim_PlayerStatusSubReasons                | Table | 3       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons                |
| 23  | Dim_Position                              | Table | 134     | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position                              |
| 24  | Dim_PositionChangeLog                     | Table | 17      | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog                     |
| 25  | Dim_PositionHedgeServerChangeLog_Snapshot | Table | 5       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot |
| 26  | Dim_Product                               | Table | 6       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_product                               |
| 27  | Dim_Range                                 | Table | 4       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range                                 |
| 28  | Dim_RedeemReason                          | Table | 3       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason                          |
| 29  | Dim_RedeemStatus                          | Table | 6       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus                          |
| 30  | Dim_Regulation                            | Table | 7       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation                            |
| 31  | Dim_RiskClassification                    | Table | 4       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification                    |
| 32  | Dim_RiskManagementStatus                  | Table | 6       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus                  |
| 33  | Dim_RiskStatus                            | Table | 7       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus                            |
| 34  | Dim_ScreeningStatus                       | Table | 3       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus                       |
| 35  | Dim_SocialNetwork                         | Table | 6       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork                         |
| 36  | Fact_CurrencyPriceWithSplit               | Table | 14      | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit               |
| 37  | Fact_CustomerAction                       | Table | 71      | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction                       |
| 38  | Fact_Deposit_State                        | Table | 29      | 0        | (see wiki — non-standard UC target)                                       |
| 39  | Fact_Guru_Copiers                         | Table | 9       | 0        | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers                         |
| 40  | Fact_SnapshotCustomer                     | Table | 52      | 8        | (see wiki — non-standard UC target)                                       |
| 41  | History_CurrencyPrice                     | Table | 26      | 0        | (see wiki — non-standard UC target)                                       |


### Resolved This Run (45) — UC target resolved via `information_schema` bulk query


| #   | Object                      | Type  | Columns | Classification | UC Target                                                                              |
| --- | --------------------------- | ----- | ------- | -------------- | -------------------------------------------------------------------------------------- |
| 1   | Dim_AccountStatus           | Table | 7       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus                                      |
| 2   | Dim_AccountType             | Table | 8       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype                                        |
| 3   | Dim_ActionType              | Table | 13      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype                                         |
| 4   | Dim_Affiliate               | Table | 56      | **PII Masked** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked + pii_data.gold_..._dim_affiliate |
| 5   | Dim_BillingDepot            | Table | 9       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot                                       |
| 6   | Dim_BonusType               | Table | 10      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype                                          |
| 7   | Dim_Campaign                | Table | 14      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_campaign                                           |
| 8   | Dim_CardType                | Table | 11      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype                                           |
| 9   | Dim_CashoutFeeGroup         | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutfeegroup                                    |
| 10  | Dim_CashoutMode             | Table | 6       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode                                        |
| 11  | Dim_Channel                 | Table | 8       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel                                            |
| 12  | Dim_ContractType            | Table | 11      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype                                       |
| 13  | Dim_Country                 | Table | 21      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country                                            |
| 14  | Dim_CountryBin              | Table | 14      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countrybin                                         |
| 15  | Dim_CountryIP               | Table | 7       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_countryip                                          |
| 16  | Dim_CreditType              | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype                                         |
| 17  | Dim_Currency                | Table | 12      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency                                           |
| 18  | Dim_Customer                | Table | 119     | **PII Masked** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked + pii_data.gold_..._dim_customer   |
| 19  | Dim_DocumentStatus          | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_documentstatus                                     |
| 20  | Dim_EvMatchStatus           | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus                                      |
| 21  | Dim_ExchangeInfo            | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo                                       |
| 22  | Dim_ExtendedUserField       | Table | 6       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield                                  |
| 23  | Dim_Fund                    | Table | 11      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund                                               |
| 24  | Dim_FundType                | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundtype                                           |
| 25  | Dim_FundingType             | Table | 11      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype                                        |
| 26  | Dim_Funnel                  | Table | 8       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel                                             |
| 27  | Dim_GuruStatus              | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus                                         |
| 28  | Dim_MoveMoneyReason         | Table | 10      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason                                    |
| 29  | Dim_PendingClosureStatus    | Table | 3       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus                               |
| 30  | Dim_PhoneVerified           | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified                                      |
| 31  | Dim_Platform                | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform                                           |
| 32  | Dim_PlatformType            | Table | 14      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype                                       |
| 33  | Dim_PlayerLevel             | Table | 14      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel                                        |
| 34  | Dim_PlayerStatus            | Table | 17      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus                                       |
| 35  | Dim_State_and_Province      | Table | 7       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province                                 |
| 36  | Dim_ThreeDsResponseTypes    | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes                               |
| 37  | Dim_VerificationLevel       | Table | 8       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel                                  |
| 38  | Dim_VerificationStatus      | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationstatus                                 |
| 39  | Dim_WorldCheck              | Table | 5       | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck                                         |
| 40  | Fact_BillingDeposit         | Table | 61      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit                                    |
| 41  | Fact_BillingRedeem          | Table | 14      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem                                     |
| 42  | Fact_BillingWithdraw        | Table | 84      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw                                   |
| 43  | Fact_CustomerUnrealized_PnL | Table | 58      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl                            |
| 44  | Fact_FirstCustomerAction    | Table | 28      | Standard       | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction                               |
| 45  | Fact_RegulationTransfer     | Table | 31      | Non-standard   | compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer                         |


---

## No UC Table Exists (22) — Table not exported to Unity Catalog

These Synapse tables have wiki documentation but no corresponding UC table was found in `system.information_schema.tables`.


| #   | Object                                              | Type  | Notes                   |
| --- | --------------------------------------------------- | ----- | ----------------------- |
| 1   | CustomerStatic                                      | Table | Not in Generic Pipeline |
| 2   | Dim_BillingProtocolMIDSettingsID                    | Table | Not in Generic Pipeline |
| 3   | Dim_CalculationType                                 | Table | Not in Generic Pipeline |
| 4   | Dim_CostConfigurationId                             | Table | Not in Generic Pipeline |
| 5   | Dim_CostSubtype                                     | Table | Not in Generic Pipeline |
| 6   | Dim_CostType                                        | Table | Not in Generic Pipeline |
| 7   | Dim_CountryIPAnonymous                              | Table | Not in Generic Pipeline |
| 8   | Dim_ExecutionOperationType                          | Table | Not in Generic Pipeline |
| 9   | Dim_FTDPlatform                                     | Table | Not in Generic Pipeline |
| 10  | Dim_FeeOperationTypes                               | Table | Not in Generic Pipeline |
| 11  | Dim_Position_Account_Statement_AmountInUnitsDecimal | Table | Not in Generic Pipeline |
| 12  | Dim_Position_Account_Statement_NetProfit            | Table | Not in Generic Pipeline |
| 13  | Fact_Cashout_Rollback                               | Table | Not in Generic Pipeline |
| 14  | Fact_Cashout_State                                  | Table | Not in Generic Pipeline |
| 15  | Fact_CustomerUnrealized_PnL_UserAPI                 | Table | Not in Generic Pipeline |
| 16  | Fact_Deposit_Fees                                   | Table | Not in Generic Pipeline |
| 17  | Fact_History_Cost                                   | Table | Not in Generic Pipeline |
| 18  | Fact_Position_Futures_Snapshot                      | Table | Not in Generic Pipeline |
| 19  | Fact_Reverse_Deposits                               | Table | Not in Generic Pipeline |
| 20  | Fact_Settlement_Prices                              | Table | Not in Generic Pipeline |
| 21  | Fact_SnapshotEquity                                 | Table | Not in Generic Pipeline |
| 22  | Fact_Withdraw_Fees                                  | Table | Not in Generic Pipeline |


---

## Views (21) — Synapse-only, not exported to UC via Generic Pipeline


| #   | Object                                       | Type |
| --- | -------------------------------------------- | ---- |
| 1   | Dim_Instrument_Correlation                   | View |
| 2   | Dim_Instrument_Correlation_UnionedPartitions | View |
| 3   | VU_FactBilling_ForBigQuery                   | View |
| 4   | V_Customers                                  | View |
| 5   | V_Dim_Customer                               | View |
| 6   | V_Dim_Date                                   | View |
| 7   | V_Dim_Date_For_DWHRep                        | View |
| 8   | V_Dim_Instrument_Correlation                 | View |
| 9   | V_Dim_Instrument_Correlation_Test_Full       | View |
| 10  | V_FCA_NumOfLogins_mean_1q                    | View |
| 11  | V_Fact_CustomerUnrealized_PnL_For_DWH_Rep    | View |
| 12  | V_Fact_RegulationTransfer                    | View |
| 13  | V_Fact_SnapshotCustomer                      | View |
| 14  | V_Fact_SnapshotCustomer_FromDateID           | View |
| 15  | V_Fact_SnapshotEquity                        | View |
| 16  | V_Fact_SnapshotEquity_ForDWHRep              | View |
| 17  | V_Fact_SnapshotEquity_FromDateID             | View |
| 18  | V_Liabilities                                | View |
| 19  | V_M2M_Date_DateRange                         | View |
| 20  | Vw_STS_User_Operations_Data_History          | View |
| 21  | v_Dim_Mirror                                 | View |


---

## Parse Failures (1)


| Object                           | Issue                                             |
| -------------------------------- | ------------------------------------------------- |
| STS_User_Operations_Data_History | No columns found in Section 4 (wiki format issue) |


---

## PII Masked Tables (2)

Tables with `ColumnsToMask` in Generic Pipeline config — dual UC targets generated.


| Object        | Masked Columns                                                                                                                     | Primary (dwh)                            | Secondary (pii_data)                   |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- | -------------------------------------- |
| Dim_Affiliate | Email, City                                                                                                                        | `main.dwh.gold_..._dim_affiliate_masked` | `main.pii_data.gold_..._dim_affiliate` |
| Dim_Customer  | Phone, IP, MiddleName, Email, Zip, Gender, BirthDate, City, LastName, UserName, BuildingNumber, Address, FirstName, UserName_Lower | `main.dwh.gold_..._dim_customer_masked`  | `main.pii_data.gold_..._dim_customer`  |


---

## Next Steps

1. **Deploy**: The 86 generated scripts are ready for `/deploy-alter-dwh dwh_dbo`.
2. **No UC table (22)**: These tables are not exported to Unity Catalog via the Generic Pipeline. No ALTER scripts can be generated. If they are added to the pipeline in the future, re-run `/generate-alter-dwh dwh_dbo` to pick them up.
3. **Parse failure (1)**: Fix `STS_User_Operations_Data_History.md` Section 4 formatting, then re-run.
4. **Views (21)**: Views are Synapse-only objects. If any are exported via separate pipelines, add UC Target to their wiki manually and re-run.

