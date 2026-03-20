---
schema: DWH_dbo
database: Synapse DWH
total_objects: 379
blacklisted: 245
pending: 0
documented: 130
failed: 0
skipped: 4
last_batch: 15
last_updated: "2026-03-19"
quality_avg: 8.0
revisions: 0
---

## Schema Documentation Progress

| Metric | Value |
|--------|-------|
| **Schema** | DWH_dbo |
| **Total Objects** | 379 |
| **Active (to document)** | 134 (95 tables, 21 views, +17 newly discovered views, +1 table) |
| **Blacklisted** | 245 |
| **Documented** | 92 (69%) |
| **Pending (re-doc)** | 38 |
| **Skipped** | 4 |
| **Last Updated** | 2026-03-19 |
| **Quality Avg** | 8.0 (range 4.5-9.4) |

---

## ALL OBJECTS DOCUMENTED

Schema DWH_dbo documentation is **complete**. 130 objects documented across 15 batches (4 skipped: non-existent or no DDL). Batch 15 refinement pass enriched 38 objects with Atlassian sources and upgraded Tier 4 columns.

---

## Batch 15 (COMPLETE) — Refinement pass: 38 objects enriched with Atlassian context

| # | Object | Type | Before | After | Status |
|---|--------|------|--------|-------|--------|
| 1 | DWH_dbo.Dim_ContactType | Table | 4.5 | 4.5 | Done — confirmed valid (empty table) |
| 2 | DWH_dbo.Fact_Deposit_Fees | Table | 6.2 | 7.4 | Done — fee calc enriched, 6 T4→T4-Atlassian |
| 3 | DWH_dbo.Dim_AffiliateCostType | Table | 6.3 | 7.0 | Done — Atlassian sources |
| 4 | DWH_dbo.Dim_ContractType | Table | 6.4 | 6.8 | Done — Atlassian sources |
| 5 | DWH_dbo.Dim_CalculationType | Table | 6.5 | 6.9 | Done — Atlassian sources |
| 6 | DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal | Table | 6.5 | 6.9 | Done — Atlassian sources |
| 7 | DWH_dbo.Dim_Position_Account_Statement_NetProfit | Table | 6.5 | 6.9 | Done — Atlassian sources |
| 8 | DWH_dbo.Dim_SocialNetwork | Table | 6.5 | 6.9 | Done — Atlassian sources |
| 9 | DWH_dbo.Fact_Reverse_Deposits | Table | 6.5 | 7.0 | Done — 3 T4 upgraded, Atlassian |
| 10 | DWH_dbo.Fact_Withdraw_Fees | Table | 6.5 | 7.0 | Done — 11 T4 upgraded, Atlassian |
| 11 | DWH_dbo.Dim_Product | Table | 6.8 | 7.1 | Done — Atlassian sources |
| 12 | DWH_dbo.Dim_CostConfigurationId | Table | 6.8 | 7.0 | Done — Atlassian sources |
| 13 | DWH_dbo.Dim_CostSubtype | Table | 6.8 | 7.0 | Done — Atlassian sources |
| 14 | DWH_dbo.Dim_CostType | Table | 6.8 | 7.0 | Done — Atlassian sources |
| 15 | DWH_dbo.Dim_DocumentStatus | Table | 6.8 | 7.0 | Done — Atlassian sources |
| 16 | DWH_dbo.CustomerStatic | Table | 6.9 | 6.8 | Done — Atlassian sources |
| 17 | DWH_dbo.Dim_FeeOperationTypes | Table | 7.0 | 7.2 | Done — Atlassian sources |
| 18 | DWH_dbo.Dim_VerificationStatus | Table | 7.0 | 7.2 | Done — Atlassian sources |
| 19 | DWH_dbo.Fact_History_Cost | Table | 7.0 | 7.2 | Done — Atlassian sources |
| 20 | DWH_dbo.Dim_ExchangeInfo | Table | 7.2 | 7.4 | Done — Atlassian sources |
| 21 | DWH_dbo.Fact_CustomerUnrealized_PnL_UserAPI | Table | 7.2 | 7.5 | Done — T4 upgraded, Atlassian |
| 22 | DWH_dbo.History_CurrencyPrice | Table | 7.2 | 7.4 | Done — T4 upgraded, Atlassian |
| 23 | DWH_dbo.V_Dim_Date_For_DWHRep | View | 7.2 | 7.5 | Done — Atlassian sources |
| 24 | DWH_dbo.Dim_Affiliate | Table | 7.5 | 7.8 | Done — Atlassian sources |
| 25 | DWH_dbo.Dim_Channel | Table | 7.5 | 7.7 | Done — Atlassian sources |
| 26 | DWH_dbo.Fact_BillingRedeem | Table | 7.5 | 7.7 | Done — Atlassian sources |
| 27 | DWH_dbo.Fact_Cashout_State | Table | 7.5 | 7.7 | Done — Atlassian sources |
| 28 | DWH_dbo.Fact_Deposit_State | Table | 7.5 | 8.2 | Done — T4 upgraded, Atlassian |
| 29 | DWH_dbo.Fact_FirstCustomerAction | Table | 7.5 | 7.7 | Done — T4 upgraded, Atlassian |
| 30 | DWH_dbo.STS_User_Operations_Data_History | Table | 7.5 | 7.6 | Done — Atlassian sources |
| 31 | DWH_dbo.V_Dim_Instrument_Correlation | View | 7.5 | 7.8 | Done — Atlassian sources |
| 32 | DWH_dbo.V_Dim_Instrument_Correlation_Test_Full | View | 7.5 | 7.8 | Done — Atlassian sources |
| 33 | DWH_dbo.V_Fact_CustomerUnrealized_PnL_For_DWH_Rep | View | 7.5 | 7.8 | Done — Atlassian sources |
| 34 | DWH_dbo.V_Fact_SnapshotEquity_ForDWHRep | View | 7.5 | 7.6 | Done — Atlassian sources |
| 35 | DWH_dbo.VU_FactBilling_ForBigQuery | View | 7.5 | 7.8 | Done — Atlassian sources |
| 36 | DWH_dbo.v_Dim_Mirror | View | 7.5 | 7.8 | Done — Atlassian sources |
| 37 | DWH_dbo.V_Dim_Date | View | 7.8 | 8.0 | Done — Atlassian sources |
| 38 | DWH_dbo.Vw_STS_User_Operations_Data_History | View | 7.8 | 8.0 | Done — Atlassian sources |

---

## Batch 14 (COMPLETE) - 3 objects documented

Completed: 2026-03-19

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Fact_CustomerUnrealized_PnL](Tables/Fact_CustomerUnrealized_PnL.md) | Table | 8.0 | Done |
| 2 | [DWH_dbo.Fact_BillingWithdraw](Tables/Fact_BillingWithdraw.md) | Table | 8.5 | Done |
| 3 | [DWH_dbo.Dim_Customer](Tables/Dim_Customer.md) | Table | 9.0 | Done |

Note: Final batch — 3 high-complexity tables. Fact_CustomerUnrealized_PnL (59 cols) computes portfolio-level unrealized PnL with V0/V1 calculation versions, NOP/Notional metrics, and Markowitz standard deviation. Fact_BillingWithdraw (83 cols) denormalizes 3 production tables with ~40 XML-extracted columns and BIN-code enrichment. Dim_Customer (107 cols) is the master customer dimension consolidating 14+ staging sources with CDC-style change detection and multi-phase post-load enrichment. Synapse MCP unavailable (P2/P3 skipped). V_Fact_SnapshotEquity was also fixed from Pending→Done (already documented in Batch 13).

---

## Batch 13 (COMPLETE) - 14 objects documented

Completed: 2026-03-19

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Fact_SnapshotEquity](Tables/Fact_SnapshotEquity.md) | Table | 8.5 | Done |
| 2 | [DWH_dbo.V_Fact_SnapshotEquity_FromDateID](Views/V_Fact_SnapshotEquity_FromDateID.md) | View | 8.0 | Done |
| 3 | [DWH_dbo.V_Fact_SnapshotEquity_ForDWHRep](Views/V_Fact_SnapshotEquity_ForDWHRep.md) | View | 7.5 | Done |
| 4 | [DWH_dbo.V_Fact_SnapshotCustomer_FromDateID](Views/V_Fact_SnapshotCustomer_FromDateID.md) | View | 8.0 | Done |
| 5 | [DWH_dbo.V_Fact_SnapshotCustomer](Views/V_Fact_SnapshotCustomer.md) | View | 8.0 | Done |
| 6 | [DWH_dbo.V_Dim_Instrument_Correlation_Test_Full](Views/V_Dim_Instrument_Correlation_Test_Full.md) | View | 7.5 | Done |
| 7 | [DWH_dbo.V_Dim_Instrument_Correlation](Views/V_Dim_Instrument_Correlation.md) | View | 7.5 | Done |
| 8 | [DWH_dbo.V_FCA_NumOfLogins_mean_1q](Views/V_FCA_NumOfLogins_mean_1q.md) | View | 8.0 | Done |
| 9 | [DWH_dbo.V_Fact_CustomerUnrealized_PnL_For_DWH_Rep](Views/V_Fact_CustomerUnrealized_PnL_For_DWH_Rep.md) | View | 7.5 | Done |
| 10 | [DWH_dbo.V_Fact_RegulationTransfer](Views/V_Fact_RegulationTransfer.md) | View | 8.5 | Done |
| 11 | [DWH_dbo.V_Fact_SnapshotEquity](Views/V_Fact_SnapshotEquity.md) | View | 8.5 | Done |
| 12 | [DWH_dbo.V_Liabilities](Views/V_Liabilities.md) | View | 8.0 | Done |
| 13 | [DWH_dbo.V_Dim_Customer](Views/V_Dim_Customer.md) | View | 8.0 | Done |
| 14 | [DWH_dbo.VU_FactBilling_ForBigQuery](Views/VU_FactBilling_ForBigQuery.md) | View | 7.5 | Done |

Note: Synapse MCP unavailable — P2/P3 (live data sampling/distribution analysis) skipped. Batch included 1 table (Fact_SnapshotEquity with full SP analysis) and 13 views. V_Liabilities is the primary liability computation view with 8 computed columns. V_Dim_Customer resolves 7 FK IDs to names across 91 columns. VU_FactBilling_ForBigQuery sanitizes ~70 string columns via RemoveSpecialChars for BigQuery export.

---

## Batch 12 (COMPLETE) - 9 objects documented

Completed: 2026-03-19

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Dim_Channel](Tables/Dim_Channel.md) | Table | 7.5 | Done |
| 2 | [DWH_dbo.Vw_STS_User_Operations_Data_History](Views/Vw_STS_User_Operations_Data_History.md) | View | 7.8 | Done |
| 3 | [DWH_dbo.Dim_Instrument_Correlation](Views/Dim_Instrument_Correlation.md) | View | 8.0 | Done |
| 4 | [DWH_dbo.Dim_Affiliate](Tables/Dim_Affiliate.md) | Table | 7.5 | Done |
| 5 | [DWH_dbo.Fact_FirstCustomerAction](Tables/Fact_FirstCustomerAction.md) | Table | 7.5 | Done |
| 6 | [DWH_dbo.Fact_RegulationTransfer](Tables/Fact_RegulationTransfer.md) | Table | 7.8 | Done |
| 7 | [DWH_dbo.Fact_History_Cost](Tables/Fact_History_Cost.md) | Table | 7.0 | Done |
| 8 | [DWH_dbo.Fact_Position_Futures_Snapshot](Tables/Fact_Position_Futures_Snapshot.md) | Table | 8.0 | Done |
| 9 | [DWH_dbo.Fact_CustomerUnrealized_PnL_UserAPI](Tables/Fact_CustomerUnrealized_PnL_UserAPI.md) | Table | 7.2 | Done |

Note: Synapse MCP unavailable — P2/P3 (live data sampling/distribution analysis) skipped on all objects. 6 high-complexity objects deferred to Batch 13 due to context limits (Dim_Customer 109 cols, Fact_BillingWithdraw 86 cols, Fact_CustomerUnrealized_PnL 59 cols, Fact_SnapshotEquity 34 cols, V_Dim_Customer view, VU_FactBilling_ForBigQuery view).

---

## Batch 11 (COMPLETE) - 10 objects documented

Completed: 2026-03-19

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Fact_CurrencyPriceWithSplit](Tables/Fact_CurrencyPriceWithSplit.md) | Table | 7.7 | Done (Recovery) |
| 2 | [DWH_dbo.Fact_Deposit_State](Tables/Fact_Deposit_State.md) | Table | 7.5 | Done (Recovery) |
| 3 | [DWH_dbo.Fact_Settlement_Prices](Tables/Fact_Settlement_Prices.md) | Table | 7.8 | Done (Recovery) |
| 4 | [DWH_dbo.Fact_SnapshotCustomer](Tables/Fact_SnapshotCustomer.md) | Table | 8.0 | Done (Recovery) |
| 5 | [DWH_dbo.STS_User_Operations_Data_History](Tables/STS_User_Operations_Data_History.md) | Table | 7.5 | Done |
| 6 | [DWH_dbo.V_Dim_Date](Views/V_Dim_Date.md) | View | 7.8 | Done |
| 7 | [DWH_dbo.V_Dim_Date_For_DWHRep](Views/V_Dim_Date_For_DWHRep.md) | View | 7.2 | Done |
| 8 | [DWH_dbo.V_M2M_Date_DateRange](Views/V_M2M_Date_DateRange.md) | View | 8.0 | Done |
| 9 | [DWH_dbo.Fact_Guru_Copiers](Tables/Fact_Guru_Copiers.md) | Table | 8.5 | Done |
| 10 | [DWH_dbo.V_Customers](Views/V_Customers.md) | View | 8.2 | Done |

Note: Items #1-4 were recovery items (files existed from prior session, verified complete, marked Done). STS_User_Operations_Data_History had partial Synapse MCP availability (P2/P3 limited). V_Dim_Date adds ~20 dynamic temporal CASE flags relative to T-1. Fact_Guru_Copiers aggregates AUC per copier using V_M2M_Date_DateRange bridge. V_Customers flattens Fact_SnapshotCustomer with ISNULL defaults and DateKey < TODAY filter.

---

## Batch 10 (COMPLETE) - 11 objects documented

Completed: 2026-03-19

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Dim_Instrument_Correlation_UnionedPartitions](Views/Dim_Instrument_Correlation_UnionedPartitions.md) | View | 8.4 | Done (Recovery) |
| 2 | [DWH_dbo.v_Dim_Mirror](Views/v_Dim_Mirror.md) | View | 7.5 | Done |
| 3 | [DWH_dbo.Dim_State_and_Province](Tables/Dim_State_and_Province.md) | Table | 8.0 | Done |
| 4 | [DWH_dbo.Dim_ThreeDsResponseTypes](Tables/Dim_ThreeDsResponseTypes.md) | Table | 8.5 | Done |
| 5 | [DWH_dbo.Dim_VerificationLevel](Tables/Dim_VerificationLevel.md) | Table | 8.5 | Done |
| 6 | [DWH_dbo.Dim_VerificationStatus](Tables/Dim_VerificationStatus.md) | Table | 7.0 | Done |
| 7 | [DWH_dbo.Dim_WorldCheck](Tables/Dim_WorldCheck.md) | Table | 8.5 | Done |
| 8 | [DWH_dbo.Fact_BillingDeposit](Tables/Fact_BillingDeposit.md) | Table | 8.5 | Done |
| 9 | [DWH_dbo.Fact_BillingRedeem](Tables/Fact_BillingRedeem.md) | Table | 7.5 | Done |
| 10 | [DWH_dbo.Fact_Cashout_State](Tables/Fact_Cashout_State.md) | Table | 7.5 | Done |
| 11 | [DWH_dbo.Fact_CustomerAction](Tables/Fact_CustomerAction.md) | Table | 8.5 | Done (Recovery) |

Note: Dim_Instrument_Correlation_UnionedPartitions and Fact_CustomerAction were recovery items (files existed from prior session, verified complete, marked Done). Dim_VerificationStatus has no upstream wiki (UserApiDB is undocumented). Fact_Cashout_State uses a custom pipeline not in `_generic_pipeline_mapping.json`. Fact_BillingDeposit is the largest documented table (138 columns, 73.9M rows) with 2-pass ETL and ~91 XML-extracted columns.

---

## Batch 9 (COMPLETE) - 10 objects documented

Completed: 2026-03-19

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Dim_Product](Tables/Dim_Product.md) | Table | 6.8 | Done |
| 2 | [DWH_dbo.Dim_Range](Tables/Dim_Range.md) | Table | 8.3 | Done |
| 3 | [DWH_dbo.Dim_RedeemReason](Tables/Dim_RedeemReason.md) | Table | 8.5 | Done |
| 4 | [DWH_dbo.Dim_RedeemStatus](Tables/Dim_RedeemStatus.md) | Table | 8.2 | Done |
| 5 | [DWH_dbo.Dim_Regulation](Tables/Dim_Regulation.md) | Table | 8.0 | Done |
| 6 | [DWH_dbo.Dim_RiskClassification](Tables/Dim_RiskClassification.md) | Table | 8.5 | Done |
| 7 | [DWH_dbo.Dim_RiskManagementStatus](Tables/Dim_RiskManagementStatus.md) | Table | 8.0 | Done |
| 8 | [DWH_dbo.Dim_RiskStatus](Tables/Dim_RiskStatus.md) | Table | 8.0 | Done |
| 9 | [DWH_dbo.Dim_ScreeningStatus](Tables/Dim_ScreeningStatus.md) | Table | 7.5 | Done |
| 10 | [DWH_dbo.Dim_SocialNetwork](Tables/Dim_SocialNetwork.md) | Table | 6.5 | Done |

Note: Dim_SocialNetwork is a frozen legacy table (4 rows, 2013-2014 timestamps, no active ETL SP). Dim_ScreeningStatus sources from ScreeningServiceDB (AML microservice), not the standard etoro Dictionary database.

---

## Batch 8 (COMPLETE) - 10 objects documented

Completed: 2026-03-19

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Dim_PendingClosureStatus](Tables/Dim_PendingClosureStatus.md) | Table | 8.0 | Done |
| 2 | [DWH_dbo.Dim_PhoneVerified](Tables/Dim_PhoneVerified.md) | Table | 8.0 | Done |
| 3 | [DWH_dbo.Dim_Platform](Tables/Dim_Platform.md) | Table | 8.0 | Done |
| 4 | [DWH_dbo.Dim_PlayerLevel](Tables/Dim_PlayerLevel.md) | Table | 8.0 | Done |
| 5 | [DWH_dbo.Dim_PlayerStatus](Tables/Dim_PlayerStatus.md) | Table | 8.0 | Done |
| 6 | [DWH_dbo.Dim_PlayerStatusReasons](Tables/Dim_PlayerStatusReasons.md) | Table | 8.5 | Done |
| 7 | [DWH_dbo.Dim_PlayerStatusSubReasons](Tables/Dim_PlayerStatusSubReasons.md) | Table | 8.5 | Done |
| 8 | [DWH_dbo.Dim_Position](Tables/Dim_Position.md) | Table | 8.0 | Done |
| 9 | [DWH_dbo.Dim_PositionChangeLog](Tables/Dim_PositionChangeLog.md) | Table | 7.5 | Done |
| 10 | [DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot](Tables/Dim_PositionHedgeServerChangeLog_Snapshot.md) | Table | 7.5 | Done (replaced non-existent Dim_PositionHedgeServerChangeLog) |

Note: Dim_PositionHedgeServerChangeLog does not exist in Synapse (invalid object error). The canonical replacement Dim_PositionHedgeServerChangeLog_Snapshot was documented instead. Dim_PositionHedgeServerChangeLog_Snapshot was previously misclassified in blacklist as "backup" -- corrected to active table.

---

## Batch 7 (COMPLETE) - 10 objects documented

Completed: 2026-03-19

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Dim_HistorySplitRatio](Tables/Dim_HistorySplitRatio.md) | Table | 8.2 | Done |
| 2 | [DWH_dbo.Dim_Instrument](Tables/Dim_Instrument.md) | Table | 9.4 | Done |
| 3 | [DWH_dbo.Dim_Instrument_Snapshot](Tables/Dim_Instrument_Snapshot.md) | Table | 8.6 | Done |
| 4 | [DWH_dbo.Dim_Label](Tables/Dim_Label.md) | Table | 8.1 | Done |
| 5 | [DWH_dbo.Dim_Language](Tables/Dim_Language.md) | Table | 8.3 | Done |
| 6 | [DWH_dbo.Dim_Manager](Tables/Dim_Manager.md) | Table | 8.4 | Done |
| 7 | [DWH_dbo.Dim_MifidCategorization](Tables/Dim_MifidCategorization.md) | Table | 8.5 | Done |
| 8 | [DWH_dbo.Dim_MirrorType](Tables/Dim_MirrorType.md) | Table | 8.3 | Done |
| 9 | [DWH_dbo.Dim_Mirror](Tables/Dim_Mirror.md) | Table | 9.0 | Done |
| 10 | [DWH_dbo.Dim_PaymentStatus](Tables/Dim_PaymentStatus.md) | Table | 8.6 | Done |

---

## Batch 6 (COMPLETE) - 10 objects documented

Completed: 2026-03-19

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Dim_EvMatchStatus](Tables/Dim_EvMatchStatus.md) | Table | 7.8 | Done |
| 2 | [DWH_dbo.Dim_ExchangeInfo](Tables/Dim_ExchangeInfo.md) | Table | 7.2 | Done |
| 3 | [DWH_dbo.Dim_ExecutionOperationType](Tables/Dim_ExecutionOperationType.md) | Table | 7.5 | Done |
| 4 | [DWH_dbo.Dim_ExtendedUserField](Tables/Dim_ExtendedUserField.md) | Table | 7.5 | Done |
| 5 | [DWH_dbo.Dim_FeeOperationTypes](Tables/Dim_FeeOperationTypes.md) | Table | 7.0 | Done |
| 6 | [DWH_dbo.Dim_Fund](Tables/Dim_Fund.md) | Table | 7.5 | Done |
| 7 | [DWH_dbo.Dim_FundType](Tables/Dim_FundType.md) | Table | 8.0 | Done |
| 8 | [DWH_dbo.Dim_FundingType](Tables/Dim_FundingType.md) | Table | 8.5 | Done |
| 9 | [DWH_dbo.Dim_Funnel](Tables/Dim_Funnel.md) | Table | 7.5 | Done |
| 10 | [DWH_dbo.Dim_GuruStatus](Tables/Dim_GuruStatus.md) | Table | 8.5 | Done |

---

## Batch 5 (PARTIAL - MCP failure) - 4 objects documented

Planned: 2026-03-19 | Partial completion: 2026-03-19 | Stopped: Synapse MCP token auth failure

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [DWH_dbo.Dim_FTDPlatform](Tables/Dim_FTDPlatform.md) | Table | 7.9 | Done |
| 2 | [DWH_dbo.Dim_PlatformType](Tables/Dim_PlatformType.md) | Table | 7.8 | Done |
| 3 | [DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal](Tables/Dim_Position_Account_Statement_AmountInUnitsDecimal.md) | Table | 6.5 | Done |
| 4 | [DWH_dbo.Dim_Position_Account_Statement_NetProfit](Tables/Dim_Position_Account_Statement_NetProfit.md) | Table | 6.5 | Done |

Note: These 4 objects were completed in a prior interrupted session. Remaining ~70 objects deferred to Batch 6 pending MCP reconnection.

---

## Tables (95)

| Object | Quality | Status |
|--------|---------|--------|
| DWH_dbo.CustomerStatic | 6.9 ★★★☆☆ | Done (Batch 15) |
| DWH_dbo.Dim_AccountStatus | 7.6 ★★★★☆ | Done — [wiki](Tables/Dim_AccountStatus.md) |
| DWH_dbo.Dim_AccountType | 8.0 ★★★★☆ | Done — [wiki](Tables/Dim_AccountType.md) |
| DWH_dbo.Dim_ActionType | 7.7 ★★★★☆ | Done — [wiki](Tables/Dim_ActionType.md) |
| [DWH_dbo.Dim_Affiliate](Tables/Dim_Affiliate.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| DWH_dbo.Dim_AffiliateCostType | 6.3 ★★★☆☆ | Done (Batch 15) |
| DWH_dbo.Dim_BillingDepot | 8.5 ★★★★☆ | Done — [wiki](Tables/Dim_BillingDepot.md) |
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | 8.5 ★★★★☆ | Done — [wiki](Tables/Dim_BillingProtocolMIDSettingsID.md) |
| DWH_dbo.Dim_BonusType | 7.8 ★★★★☆ | Done — [wiki](Tables/Dim_BonusType.md) |
| DWH_dbo.Dim_CalculationType | 6.5 ★★★☆☆ | Done (Batch 15) |
| DWH_dbo.Dim_Campaign | 7.0 ★★★★☆ | Done — [wiki](Tables/Dim_Campaign.md) |
| DWH_dbo.Dim_CardType | 7.9 ★★★★☆ | Done — [wiki](Tables/Dim_CardType.md) |
| DWH_dbo.Dim_CashoutFeeGroup | 8.5 ★★★★☆ | Done — [wiki](Tables/Dim_CashoutFeeGroup.md) |
| DWH_dbo.Dim_CashoutMode | 8.5 ★★★★☆ | Done — [wiki](Tables/Dim_CashoutMode.md) |
| DWH_dbo.Dim_CashoutReason | 9.0 ★★★★★ | Done — [wiki](Tables/Dim_CashoutReason.md) |
| DWH_dbo.Dim_CashoutStatus | 8.7 ★★★★☆ | Done — [wiki](Tables/Dim_CashoutStatus.md) |
| [DWH_dbo.Dim_Channel](Tables/Dim_Channel.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| DWH_dbo.Dim_ClientWithdrawReason | 8.6 ★★★★☆ | Done — [wiki](Tables/Dim_ClientWithdrawReason.md) |
| DWH_dbo.Dim_ClosePositionReason | 9.0 ★★★★★ | Done — [wiki](Tables/Dim_ClosePositionReason.md) |
| DWH_dbo.Dim_CompensationReason | 8.8 ★★★★☆ | Done — [wiki](Tables/Dim_CompensationReason.md) |
| DWH_dbo.Dim_ContactType | 4.5 ★★☆☆☆ | Done (Batch 15) |
| DWH_dbo.Dim_ContractType | 6.4 ★★★☆☆ | Done (Batch 15) |
| DWH_dbo.Dim_CostConfigurationId | 6.8 ★★★☆☆ | Done (Batch 15) |
| DWH_dbo.Dim_CostSubtype | 6.8 ★★★☆☆ | Done (Batch 15) |
| DWH_dbo.Dim_CostType | 6.8 ★★★☆☆ | Done (Batch 15) |
| DWH_dbo.Dim_Country | 8.8 ★★★★☆ | Done — [wiki](Tables/Dim_Country.md) |
| DWH_dbo.Dim_CountryBin | 7.7 ★★★★☆ | Done — [wiki](Tables/Dim_CountryBin.md) |
| DWH_dbo.Dim_CountryIP | 8.0 ★★★★☆ | Done — [wiki](Tables/Dim_CountryIP.md) |
| DWH_dbo.Dim_CountryIPAnonymous | 7.8 ★★★★☆ | Done — [wiki](Tables/Dim_CountryIPAnonymous.md) |
| DWH_dbo.Dim_CountryIPAnonymousProxyType | 7.8 ★★★★☆ | Done — [wiki](Tables/Dim_CountryIPAnonymousProxyType.md) |
| DWH_dbo.Dim_CreditType | 7.2 ★★★★☆ | Done — [wiki](Tables/Dim_CreditType.md) |
| DWH_dbo.Dim_Currency | 8.5 ★★★★☆ | Done — [wiki](Tables/Dim_Currency.md) |
| [DWH_dbo.Dim_Customer](Tables/Dim_Customer.md) | 9.0 ★★★★★ | Done (Batch 14) |
| DWH_dbo.Dim_CustomerChangeType | 7.6 ★★★★☆ | Done — [wiki](Tables/Dim_CustomerChangeType.md) |
| DWH_dbo.Dim_Desk | 7.8 ★★★★☆ | Done — [wiki](Tables/Dim_Desk.md) |
| DWH_dbo.Dim_DocumentStatus | 6.8 ★★★☆☆ | Done (Batch 15) |
| [DWH_dbo.Dim_EvMatchStatus](Tables/Dim_EvMatchStatus.md) | 7.8 ★★★★☆ | Done — [wiki](Tables/Dim_EvMatchStatus.md) |
| [DWH_dbo.Dim_ExchangeInfo](Tables/Dim_ExchangeInfo.md) | 7.2 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.Dim_ExecutionOperationType](Tables/Dim_ExecutionOperationType.md) | 7.5 ★★★★☆ | Done — [wiki](Tables/Dim_ExecutionOperationType.md) |
| [DWH_dbo.Dim_ExtendedUserField](Tables/Dim_ExtendedUserField.md) | 7.5 ★★★★☆ | Done — [wiki](Tables/Dim_ExtendedUserField.md) |
| [DWH_dbo.Dim_FTDPlatform](Tables/Dim_FTDPlatform.md) | 7.9 ★★★★☆ | Done (Batch 5) |
| [DWH_dbo.Dim_FeeOperationTypes](Tables/Dim_FeeOperationTypes.md) | 7.0 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.Dim_Fund](Tables/Dim_Fund.md) | 7.5 ★★★★☆ | Done — [wiki](Tables/Dim_Fund.md) |
| [DWH_dbo.Dim_FundType](Tables/Dim_FundType.md) | 8.0 ★★★★☆ | Done — [wiki](Tables/Dim_FundType.md) |
| [DWH_dbo.Dim_FundingType](Tables/Dim_FundingType.md) | 8.5 ★★★★☆ | Done — [wiki](Tables/Dim_FundingType.md) |
| [DWH_dbo.Dim_Funnel](Tables/Dim_Funnel.md) | 7.5 ★★★★☆ | Done — [wiki](Tables/Dim_Funnel.md) |
| [DWH_dbo.Dim_GuruStatus](Tables/Dim_GuruStatus.md) | 8.5 ★★★★☆ | Done — [wiki](Tables/Dim_GuruStatus.md) |
| [DWH_dbo.Dim_HistorySplitRatio](Tables/Dim_HistorySplitRatio.md) | 8.2 ★★★★☆ | Done (Batch 7) |
| [DWH_dbo.Dim_Instrument](Tables/Dim_Instrument.md) | 9.4 ★★★★★ | Done (Batch 7) |
| [DWH_dbo.Dim_Instrument_Snapshot](Tables/Dim_Instrument_Snapshot.md) | 8.6 ★★★★☆ | Done (Batch 7) |
| [DWH_dbo.Dim_Label](Tables/Dim_Label.md) | 8.1 ★★★★☆ | Done (Batch 7) |
| [DWH_dbo.Dim_Language](Tables/Dim_Language.md) | 8.3 ★★★★☆ | Done (Batch 7) |
| [DWH_dbo.Dim_Manager](Tables/Dim_Manager.md) | 8.4 ★★★★☆ | Done (Batch 7) |
| [DWH_dbo.Dim_MifidCategorization](Tables/Dim_MifidCategorization.md) | 8.5 ★★★★☆ | Done (Batch 7) |
| [DWH_dbo.Dim_Mirror](Tables/Dim_Mirror.md) | 9.0 ★★★★★ | Done (Batch 7) |
| [DWH_dbo.Dim_MirrorType](Tables/Dim_MirrorType.md) | 8.3 ★★★★☆ | Done (Batch 7) |
| DWH_dbo.Dim_MoveMoneyReason | 7.3 ★★★★☆ | Done — [wiki](Tables/Dim_MoveMoneyReason.md) |
| [DWH_dbo.Dim_PaymentStatus](Tables/Dim_PaymentStatus.md) | 8.6 ★★★★☆ | Done (Batch 7) |
| [DWH_dbo.Dim_PendingClosureStatus](Tables/Dim_PendingClosureStatus.md) | 8.0 ★★★★☆ | Done (Batch 8) |
| [DWH_dbo.Dim_PhoneVerified](Tables/Dim_PhoneVerified.md) | 8.0 ★★★★☆ | Done (Batch 8) |
| [DWH_dbo.Dim_Platform](Tables/Dim_Platform.md) | 8.0 ★★★★☆ | Done (Batch 8) |
| [DWH_dbo.Dim_PlatformType](Tables/Dim_PlatformType.md) | 7.8 ★★★★☆ | Done (Batch 5) |
| [DWH_dbo.Dim_PlayerLevel](Tables/Dim_PlayerLevel.md) | 8.0 ★★★★☆ | Done (Batch 8) |
| [DWH_dbo.Dim_PlayerStatus](Tables/Dim_PlayerStatus.md) | 8.0 ★★★★☆ | Done (Batch 8) |
| [DWH_dbo.Dim_PlayerStatusReasons](Tables/Dim_PlayerStatusReasons.md) | 8.5 ★★★★☆ | Done (Batch 8) |
| [DWH_dbo.Dim_PlayerStatusSubReasons](Tables/Dim_PlayerStatusSubReasons.md) | 8.5 ★★★★☆ | Done (Batch 8) |
| [DWH_dbo.Dim_Position](Tables/Dim_Position.md) | 8.0 ★★★★☆ | Done (Batch 8) |
| [DWH_dbo.Dim_PositionChangeLog](Tables/Dim_PositionChangeLog.md) | 7.5 ★★★★☆ | Done (Batch 8) |
| DWH_dbo.Dim_PositionHedgeServerChangeLog | - | Skipped (does not exist in Synapse; see Dim_PositionHedgeServerChangeLog_Snapshot) |
| [DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot](Tables/Dim_PositionHedgeServerChangeLog_Snapshot.md) | 7.5 ★★★★☆ | Done (Batch 8) |
| [DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal](Tables/Dim_Position_Account_Statement_AmountInUnitsDecimal.md) | 6.5 ★★★☆☆ | Done (Batch 15) |
| [DWH_dbo.Dim_Position_Account_Statement_NetProfit](Tables/Dim_Position_Account_Statement_NetProfit.md) | 6.5 ★★★☆☆ | Done (Batch 15) |
| [DWH_dbo.Dim_Product](Tables/Dim_Product.md) | 6.8 ★★★☆☆ | Done (Batch 15) |
| [DWH_dbo.Dim_Range](Tables/Dim_Range.md) | 8.3 ★★★★☆ | Done (Batch 9) |
| [DWH_dbo.Dim_RedeemReason](Tables/Dim_RedeemReason.md) | 8.5 ★★★★☆ | Done (Batch 9) |
| [DWH_dbo.Dim_RedeemStatus](Tables/Dim_RedeemStatus.md) | 8.2 ★★★★☆ | Done (Batch 9) |
| [DWH_dbo.Dim_Regulation](Tables/Dim_Regulation.md) | 8.0 ★★★★☆ | Done (Batch 9) |
| [DWH_dbo.Dim_RiskClassification](Tables/Dim_RiskClassification.md) | 8.5 ★★★★☆ | Done (Batch 9) |
| [DWH_dbo.Dim_RiskManagementStatus](Tables/Dim_RiskManagementStatus.md) | 8.0 ★★★★☆ | Done (Batch 9) |
| [DWH_dbo.Dim_RiskStatus](Tables/Dim_RiskStatus.md) | 8.0 ★★★★☆ | Done (Batch 9) |
| [DWH_dbo.Dim_ScreeningStatus](Tables/Dim_ScreeningStatus.md) | 7.5 ★★★☆☆ | Done (Batch 9) |
| [DWH_dbo.Dim_SocialNetwork](Tables/Dim_SocialNetwork.md) | 6.5 ★★★☆☆ | Done (Batch 15) |
| [DWH_dbo.Dim_State_and_Province](Tables/Dim_State_and_Province.md) | 8.0 ★★★★☆ | Done (Batch 10) |
| [DWH_dbo.Dim_ThreeDsResponseTypes](Tables/Dim_ThreeDsResponseTypes.md) | 8.5 ★★★★☆ | Done (Batch 10) |
| [DWH_dbo.Dim_VerificationLevel](Tables/Dim_VerificationLevel.md) | 8.5 ★★★★☆ | Done (Batch 10) |
| [DWH_dbo.Dim_VerificationStatus](Tables/Dim_VerificationStatus.md) | 7.0 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.Dim_WorldCheck](Tables/Dim_WorldCheck.md) | 8.5 ★★★★☆ | Done (Batch 10) |
| [DWH_dbo.Fact_BillingDeposit](Tables/Fact_BillingDeposit.md) | 8.5 ★★★★☆ | Done (Batch 10) |
| [DWH_dbo.Fact_BillingRedeem](Tables/Fact_BillingRedeem.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.Fact_BillingWithdraw](Tables/Fact_BillingWithdraw.md) | 8.5 ★★★★☆ | Done (Batch 14) |
| DWH_dbo.Fact_Cashout_Rollback | 9.2 ★★★★★ | Done — [wiki](Tables/Fact_Cashout_Rollback.md) |
| [DWH_dbo.Fact_Cashout_State](Tables/Fact_Cashout_State.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.Fact_CurrencyPriceWithSplit](Tables/Fact_CurrencyPriceWithSplit.md) | 7.7 ★★★★☆ | Done (Batch 11) |
| [DWH_dbo.Fact_CustomerAction](Tables/Fact_CustomerAction.md) | 8.5 ★★★★☆ | Done (Batch 10) |
| [DWH_dbo.Fact_CustomerUnrealized_PnL](Tables/Fact_CustomerUnrealized_PnL.md) | 8.0 ★★★★☆ | Done (Batch 14) |
| [DWH_dbo.Fact_CustomerUnrealized_PnL_UserAPI](Tables/Fact_CustomerUnrealized_PnL_UserAPI.md) | 7.2 ★★★★☆ | Done (Batch 15) |
| DWH_dbo.Fact_Deposit_Fees | 6.2 ★★★☆☆ | Done (Batch 15) |
| [DWH_dbo.Fact_Deposit_State](Tables/Fact_Deposit_State.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.Fact_FirstCustomerAction](Tables/Fact_FirstCustomerAction.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.Fact_Guru_Copiers](Tables/Fact_Guru_Copiers.md) | 8.5 ★★★★☆ | Done (Batch 11) |
| [DWH_dbo.Fact_History_Cost](Tables/Fact_History_Cost.md) | 7.0 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.Fact_Position_Futures_Snapshot](Tables/Fact_Position_Futures_Snapshot.md) | 8.0 ★★★★☆ | Done (Batch 12) |
| [DWH_dbo.Fact_RegulationTransfer](Tables/Fact_RegulationTransfer.md) | 7.8 ★★★★☆ | Done (Batch 12) |
| DWH_dbo.Fact_Reverse_Deposits | 6.5 ★★★☆☆ | Done (Batch 15) |
| [DWH_dbo.Fact_Settlement_Prices](Tables/Fact_Settlement_Prices.md) | 7.8 ★★★★☆ | Done (Batch 11) |
| [DWH_dbo.Fact_SnapshotCustomer](Tables/Fact_SnapshotCustomer.md) | 8.0 ★★★★☆ | Done (Batch 11) |
| [DWH_dbo.Fact_SnapshotEquity](Tables/Fact_SnapshotEquity.md) | 8.5 ★★★★☆ | Done (Batch 13) |
| DWH_dbo.Fact_Withdraw_Fees | 6.5 ★★★☆☆ | Done (Batch 15) |
| DWH_dbo.History_CurrencyPrice | 7.2 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.STS_User_Operations_Data_History](Tables/STS_User_Operations_Data_History.md) | 7.5 ★★★★☆ | Done (Batch 15) |

## Views (21)

| Object | Quality | Status |
|--------|---------|--------|
| [DWH_dbo.Dim_Instrument_Correlation](Views/Dim_Instrument_Correlation.md) | 8.0 ★★★★☆ | Done (Batch 12) |
| [DWH_dbo.Dim_Instrument_Correlation_UnionedPartitions](Views/Dim_Instrument_Correlation_UnionedPartitions.md) | 8.4 ★★★★☆ | Done (Batch 10) |
| [DWH_dbo.VU_FactBilling_ForBigQuery](Views/VU_FactBilling_ForBigQuery.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.V_Customers](Views/V_Customers.md) | 8.2 ★★★★☆ | Done (Batch 11) |
| [DWH_dbo.V_Dim_Customer](Views/V_Dim_Customer.md) | 8.0 ★★★★☆ | Done (Batch 13) |
| [DWH_dbo.V_Dim_Date](Views/V_Dim_Date.md) | 7.8 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.V_Dim_Date_For_DWHRep](Views/V_Dim_Date_For_DWHRep.md) | 7.2 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.V_Dim_Instrument_Correlation](Views/V_Dim_Instrument_Correlation.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.V_Dim_Instrument_Correlation_Test_Full](Views/V_Dim_Instrument_Correlation_Test_Full.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.V_FCA_NumOfLogins_mean_1q](Views/V_FCA_NumOfLogins_mean_1q.md) | 8.0 ★★★★☆ | Done (Batch 13) |
| [DWH_dbo.V_Fact_CustomerUnrealized_PnL_For_DWH_Rep](Views/V_Fact_CustomerUnrealized_PnL_For_DWH_Rep.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.V_Fact_RegulationTransfer](Views/V_Fact_RegulationTransfer.md) | 8.5 ★★★★☆ | Done (Batch 13) |
| [DWH_dbo.V_Fact_SnapshotCustomer](Views/V_Fact_SnapshotCustomer.md) | 8.0 ★★★★☆ | Done (Batch 13) |
| [DWH_dbo.V_Fact_SnapshotCustomer_FromDateID](Views/V_Fact_SnapshotCustomer_FromDateID.md) | 8.0 ★★★★☆ | Done (Batch 13) |
| [DWH_dbo.V_Fact_SnapshotEquity](Views/V_Fact_SnapshotEquity.md) | 8.5 ★★★★☆ | Done (Batch 13) |
| [DWH_dbo.V_Fact_SnapshotEquity_ForDWHRep](Views/V_Fact_SnapshotEquity_ForDWHRep.md) | 7.5 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.V_Fact_SnapshotEquity_FromDateID](Views/V_Fact_SnapshotEquity_FromDateID.md) | 8.0 ★★★★☆ | Done (Batch 13) |
| [DWH_dbo.V_Liabilities](Views/V_Liabilities.md) | 8.0 ★★★★☆ | Done (Batch 13) |
| [DWH_dbo.V_M2M_Date_DateRange](Views/V_M2M_Date_DateRange.md) | 8.0 ★★★★☆ | Done (Batch 11) |
| [DWH_dbo.Vw_STS_User_Operations_Data_History](Views/Vw_STS_User_Operations_Data_History.md) | 7.8 ★★★★☆ | Done (Batch 15) |
| [DWH_dbo.v_Dim_Mirror](Views/v_Dim_Mirror.md) | 7.5 ★★★★☆ | Done (Batch 15) |

## Skipped (4)

| Object | Quality | Status |
|--------|---------|--------|
| DWH_dbo.Dim_PEPStatus | - | Skipped (table dropped, ETL commented out) |
| DWH_dbo.Dim_PositionHedgeServerChangeLog | - | Skipped (table does not exist in Synapse; replaced by Dim_PositionHedgeServerChangeLog_Snapshot) |
| DWH_dbo.History_SplitRatio | - | Skipped (no DDL in SSDT) |
| DWH_dbo.Sodreconciliation_apex_SodFiles | - | Skipped (no DDL in SSDT) |

---

<details>
<summary>Blacklisted Objects (246) — click to expand</summary>

> Excluded from documentation. Managed in `_blacklist.json`.

### backup (22) — Dated backup or snapshot copy of another table

| Object |
|--------|
| DWH_dbo.DataSolutionsProcessesStatus_bkp_2023_10_29 |
| DWH_dbo.Dim_Instrument_Snapshot_12022025 |
| DWH_dbo.Dim_PositionChangeLog_bkp_2024_05_05 |
| DWH_dbo.Dim_Position_Backup20240616 |
| DWH_dbo.Dim_Position_Backup_20250705 |
| DWH_dbo.Dim_Position_Backup_20250916 |
| DWH_dbo.Fact_BillingWithdraw_20230531 |
| DWH_dbo.Fact_BillingWithdraw_20230601 |
| DWH_dbo.Fact_Cashout_State_Backup_20250403 |
| DWH_dbo.Fact_Deposit_State_Backup_2025_07_22 |
| DWH_dbo.Fact_Guru_Copiers_Backup_20241014 |
| DWH_dbo.Fact_Guru_Copiers_Backup_20241014_Ver2 |
| DWH_dbo.Fact_Position_Futures_Snapshot_12022025 |
| DWH_dbo.Fact_Position_Futures_Snapshot_20.01.2025 |
| DWH_dbo.Fact_Position_Futures_Snapshot_backup |
| DWH_dbo.Fact_SnapshotCustomer_Backup_20240408 |
| DWH_dbo.Fact_SnapshotCustomer_Backup_20240415 |
| DWH_dbo.Fact_SnapshotCustomer_Backup_20241014 |
| DWH_dbo.Fact_SnapshotCustomer_Backup_20241014_Ver2 |
| DWH_dbo.Fact_SnapshotCustomer_Backup_20241016 |
| DWH_dbo.Fact_SnapshotCustomer_Backup_20250113 |

### test (7) — Developer test, QA, or experiment artifact

| Object |
|--------|
| DWH_dbo.Dim_Affiliate_Test_Nitzan |
| DWH_dbo.Dim_Channel_Test_Nitzan |
| DWH_dbo.ESMAReporting_Cysec_Assaf |
| DWH_dbo.Fact_CustomerAction_PnL_QA_environment |
| DWH_dbo.Fact_SnapshotCustomer_Eyal |
| DWH_dbo.STS_User_Operations_Data_History_test |
| DWH_dbo.v_Dim_Mirror_ofir |

### junk (6) — Explicitly labeled as junk or marked for deletion

| Object |
|--------|
| DWH_dbo.Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK |
| DWH_dbo.Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK_DaysBefore |
| DWH_dbo.Fact_History_Cost_Junk_New |
| DWH_dbo.Fact_SnapshotCustomer_ToDelete |
| DWH_dbo.JUNK_DimPositionIsBuy |
| DWH_dbo.Junk_Dim_Instrument_Correlation_Active |

### switch (6) — SWITCH staging table for partition swap ETL pattern

| Object |
|--------|
| DWH_dbo.Dim_Position_SWITCH_SINGLE |
| DWH_dbo.Dim_Position_SWITCH_SINGLE_Backup_20250916 |
| DWH_dbo.Fact_CustomerAction_SWITCH |
| DWH_dbo.Fact_CustomerAction_SWITCH_SINGLE |
| DWH_dbo.STS_User_Operations_Data_History_SWITCH |
| DWH_dbo.STS_User_Operations_Data_History_SWITCH_SINGLE |

### partition (25) — Numbered partition fragment of a manually partitioned table

| Object |
|--------|
| DWH_dbo.Dim_Instrument_Correlation_Active |
| DWH_dbo.Dim_Instrument_Correlation_Archive |
| DWH_dbo.Dim_Instrument_Correlation_GroupsInstruments |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_ |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_1 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_10 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_11 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_12 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_13 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_14 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_15 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_16 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_17 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_18 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_19 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_2 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_20 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_3 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_4 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_5 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_6 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_7 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_8 |
| DWH_dbo.Dim_Instrument_Correlation_Half_Records_9 |

### replication (6) — Replication check or system monitoring table

| Object |
|--------|
| DWH_dbo.DWH_Status |
| DWH_dbo.ReplCheck_Dim_Instrument_Correlation |
| DWH_dbo.ReplCheck_Dim_Tables |
| DWH_dbo.ReplCheck_Fact_CustomerUnrealized_PnL |
| DWH_dbo.ReplCheck_Fact_Guru_Copiers |
| DWH_dbo.ReplCheck_Fact_SnapshotEquity |

### validation (6) — Intermediate validation or reconciliation results

| Object |
|--------|
| DWH_dbo.Val_FCV_COMovements |
| DWH_dbo.Val_FCV_ClosingBalance |
| DWH_dbo.Val_FCV_MovementSum |
| DWH_dbo.Val_FCV_OpeningBalance |
| DWH_dbo.Val_Match |
| DWH_dbo.Val_Target_FCA |

### utility (3) — Scratch/utility table, not core business data

| Object |
|--------|
| DWH_dbo.Dim_Date |
| DWH_dbo.Util_ResultsLiabilities_Cycle |
| DWH_dbo.Util_ResultsSourceToTarget_Actions |

### poc (3) — Proof-of-concept or one-off data load

| Object |
|--------|
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted_For_CHECK |
| DWH_dbo.Dim_Instrument_POC_BCP |

### staging (142) — ETL staging/external table — intermediate pipe, no independent business value

| Object |
|--------|
| DWH_dbo.Ext_CustomerFinanceDB_Customer_FirstTimeDeposits |
| DWH_dbo.Ext_Dim_Affiliate |
| DWH_dbo.Ext_Dim_Affiliate_Customer |
| DWH_dbo.Ext_Dim_Affiliate_FTD |
| DWH_dbo.Ext_Dim_Affiliate_FTDe |
| DWH_dbo.Ext_Dim_Affiliate_MasterAffiliate |
| DWH_dbo.Ext_Dim_Affiliate_Registrations |
| DWH_dbo.Ext_Dim_Channel |
| DWH_dbo.Ext_Dim_Channel_Affiliate_UnifyCode |
| DWH_dbo.Ext_Dim_Channel_UnifyCode |
| DWH_dbo.Ext_Dim_Country |
| DWH_dbo.Ext_Dim_Country_20240331 |
| DWH_dbo.Ext_Dim_Country_New |
| DWH_dbo.Ext_Dim_Country_Old_20240305 |
| DWH_dbo.Ext_Dim_Country_Region_Desk |
| DWH_dbo.Ext_Dim_Country_Regulation |
| DWH_dbo.Ext_Dim_Country_Test |
| DWH_dbo.Ext_Dim_CustomerStatic |
| DWH_dbo.Ext_Dim_Customer_2FA |
| DWH_dbo.Ext_Dim_Customer_Affiliate |
| DWH_dbo.Ext_Dim_Customer_Avatars |
| DWH_dbo.Ext_Dim_Customer_BOCustomer |
| DWH_dbo.Ext_Dim_Customer_Customer |
| DWH_dbo.Ext_Dim_Customer_CustomerIdentification |
| DWH_dbo.Ext_Dim_Customer_CustomerIdentification_DLT |
| DWH_dbo.Ext_Dim_Customer_Document |
| DWH_dbo.Ext_Dim_Customer_ExternalID_GCID |
| DWH_dbo.Ext_Dim_Customer_History_Credit |
| DWH_dbo.Ext_Dim_Customer_PEPStatusID |
| DWH_dbo.Ext_Dim_Customer_PhoneCustomer |
| DWH_dbo.Ext_Dim_Customer_PhoneVerificationDetails |
| DWH_dbo.Ext_Dim_Customer_SF_ID |
| DWH_dbo.Ext_Dim_Customer_ScreeningStatusID |
| DWH_dbo.Ext_Dim_Customer_StocksLending |
| DWH_dbo.Ext_Dim_Customer_WorldCheck |
| DWH_dbo.Ext_Dim_Instrument_Classification_Static |
| DWH_dbo.Ext_Dim_Instrument_ReceivedOnPriceServerCurrent |
| DWH_dbo.Ext_Dim_Instrument_ReceivedOnPriceServerStatic |
| DWH_dbo.Ext_Dim_Instrument_StockInfo_InstrumentData |
| DWH_dbo.Ext_Dim_Instrument_StockInfo_InstrumentData_Platform |
| DWH_dbo.Ext_Dim_Manager |
| DWH_dbo.Ext_Dim_Mirror_FundCIDs |
| DWH_dbo.Ext_Dim_Mirror_FundCIDs_Staging |
| DWH_dbo.Ext_Dim_Mirror_History |
| DWH_dbo.Ext_Dim_Mirror_History_Staging |
| DWH_dbo.Ext_Dim_Mirror_Real |
| DWH_dbo.Ext_Dim_Mirror_Real_Staging |
| DWH_dbo.Ext_Dim_Mirror_SessionID |
| DWH_dbo.Ext_Dim_PositionChangeLog |
| DWH_dbo.Ext_Dim_Position_AirDrop |
| DWH_dbo.Ext_Dim_Position_BackOffice_Customer |
| DWH_dbo.Ext_Dim_Position_CurrencyPrice_Active |
| DWH_dbo.Ext_Dim_Position_First_Open |
| DWH_dbo.Ext_Dim_Position_FundCIDs |
| DWH_dbo.Ext_Dim_Position_HBCExecutionLog |
| DWH_dbo.Ext_Dim_Position_HBCExecutionLog_bkp_2023_10_17 |
| DWH_dbo.Ext_Dim_Position_History_Real |
| DWH_dbo.Ext_Dim_Position_Migration |
| DWH_dbo.Ext_Dim_Position_PositionChangeLog |
| DWH_dbo.Ext_Dim_Position_PositionChangeLogAmount |
| DWH_dbo.Ext_Dim_Position_PositionChangeLogAmount_ChangeType12 |
| DWH_dbo.Ext_Dim_Position_PositionHedgeServerChangeLog |
| DWH_dbo.Ext_Dim_Position_Real |
| DWH_dbo.Ext_Dim_Position_Real_20240430 |
| DWH_dbo.Ext_Dim_Position_Real_Backup_20250916 |
| DWH_dbo.Ext_Dim_SubChannel_UnifyCode |
| DWH_dbo.Ext_FBD_Fact_BillingDeposit |
| DWH_dbo.Ext_FBR_Fact_BillingRedeem |
| DWH_dbo.Ext_FBW_Fact_BillingWithdraw |
| DWH_dbo.Ext_FCAFact_CustomerAction |
| DWH_dbo.Ext_FCA_ActionTypeID_14 |
| DWH_dbo.Ext_FCA_BackOffice_Customer |
| DWH_dbo.Ext_FCA_Billing_Deposit |
| DWH_dbo.Ext_FCA_Billing_Withdraw |
| DWH_dbo.Ext_FCA_CountryIP |
| DWH_dbo.Ext_FCA_Customer |
| DWH_dbo.Ext_FCA_Deposit_Attempt |
| DWH_dbo.Ext_FCA_Fact_CustomerAction |
| DWH_dbo.Ext_FCA_Fact_CustomerAction_Junk |
| DWH_dbo.Ext_FCA_History_Position |
| DWH_dbo.Ext_FCA_Mirror_Session |
| DWH_dbo.Ext_FCA_OpenBook_Engagement |
| DWH_dbo.Ext_FCA_PositionChangeLog |
| DWH_dbo.Ext_FCA_Position_AirDrop |
| DWH_dbo.Ext_FCA_Position_Session |
| DWH_dbo.Ext_FCA_PositionsProcessedForIndexDividnds |
| DWH_dbo.Ext_FCA_Real_Audit_Loggin |
| DWH_dbo.Ext_FCA_Real_Cashier_CashoutToFunding |
| DWH_dbo.Ext_FCA_Real_Cashier_Loggin |
| DWH_dbo.Ext_FCA_Real_Customer_Registration |
| DWH_dbo.Ext_FCA_Real_History_Credit_ForFactAction |
| DWH_dbo.Ext_FCA_Real_History_Credit_ForFactAction_All |
| DWH_dbo.Ext_FCA_Real_Position |
| DWH_dbo.Ext_FCA_Real_Trade_Position |
| DWH_dbo.Ext_FCA_STS_User_Operations_Data |
| DWH_dbo.Ext_FCA_Tran_Billing_Withdraw |
| DWH_dbo.Ext_FCPWS_History_SplitRatio |
| DWH_dbo.Ext_FCPWS_Instrument |
| DWH_dbo.Ext_FCUPNL_BackOfficeCustomer |
| DWH_dbo.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit |
| DWH_dbo.Ext_FCUPNL_Dictionary_Instrument |
| DWH_dbo.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted |
| DWH_dbo.Ext_FCUPNL_History_Mirror |
| DWH_dbo.Ext_FCUPNL_History_Position |
| DWH_dbo.Ext_FCUPNL_History_SplitRatio |
| DWH_dbo.Ext_FCUPNL_PositionChangeLog |
| DWH_dbo.Ext_FCUPNL_Trade_Position |
| DWH_dbo.Ext_FGC_Guru_Copiers |
| DWH_dbo.Ext_FRT_BackOffice_RegulationChangeLog |
| DWH_dbo.Ext_FRT_BackOffice_RegulationChangeLog_All |
| DWH_dbo.Ext_FSC_BackOffice_Customer |
| DWH_dbo.Ext_FSC_BackOffice_CustomerCloseYear |
| DWH_dbo.Ext_FSC_BackOffice_RegulationChangeLog |
| DWH_dbo.Ext_FSC_BackOffice_RegulationChangeLog_All |
| DWH_dbo.Ext_FSC_Customer_FirstTimeDeposits |
| DWH_dbo.Ext_FSC_DimCustomerCloseYear |
| DWH_dbo.Ext_FSC_IsDepositorCloseYear |
| DWH_dbo.Ext_FSC_PhoneCustomer |
| DWH_dbo.Ext_FSC_PhoneCustomerCloseYear |
| DWH_dbo.Ext_FSC_PhoneVerificationDetails |
| DWH_dbo.Ext_FSC_PhoneVerificationDetailsCloseYear |
| DWH_dbo.Ext_FSC_Real_Customer_Customer |
| DWH_dbo.Ext_FSC_Real_Customer_CustomerCloseYear |
| DWH_dbo.Ext_FSC_Real_History_Credit |
| DWH_dbo.Ext_FSC_StocksLending |
| DWH_dbo.Ext_FSE_Billing_Withdraw |
| DWH_dbo.Ext_FSE_Billing_WithdrawToFunding |
| DWH_dbo.Ext_FSE_Fact_SnapshotEquity |
| DWH_dbo.Ext_FSE_History_Credit |
| DWH_dbo.Ext_FSE_History_Position |
| DWH_dbo.Ext_FSE_History_WithdrawAction |
| DWH_dbo.Ext_FSE_History_WithdrawToFundingAction |
| DWH_dbo.Ext_FSE_InProcessCashouts |
| DWH_dbo.Ext_FSE_PositionChangeLog |
| DWH_dbo.Ext_FSE_PositionChangeLog_Amount |
| DWH_dbo.Ext_FSE_Real_History_Credit |
| DWH_dbo.Ext_FSE_TotalCashChangeAll |
| DWH_dbo.Ext_FSE_TotalPositionAmount |
| DWH_dbo.Ext_FSE_Trade_Position |
| DWH_dbo.Ext_Fact_CustomerAction_ActionTypeID_30 |
| DWH_dbo.Ext_History_Cost |
| DWH_dbo.Ext_etoro_Billing_vDeposit |

### system (16) — Internal monitoring, orchestration, or metadata tracking table

| Object |
|--------|
| DWH_dbo.AsyncFailedSteps |
| DWH_dbo.ChangesLog |
| DWH_dbo.DWH_Tables_Name |
| DWH_dbo.DataLakeTableStatus |
| DWH_dbo.DataLakeTableStatusLog |
| DWH_dbo.DataLakeTableStatus_ID |
| DWH_dbo.DataSolutionsDWHDatabricks |
| DWH_dbo.DataSolutionsMappingFreshService |
| DWH_dbo.DataSolutionsProcessesStatus |
| DWH_dbo.DataSolutionsTablesDate |
| DWH_dbo.DataSolutionsTablesRunInd |
| DWH_dbo.DimPositionDataLakeExecutionLog |
| DWH_dbo.Log_Main_Full |
| DWH_dbo.Log_Replication |
| DWH_dbo.ParquetMetadata |
| DWH_dbo.TablesUpdatesProcessesStatus |

### etl_source (4) — Data lake external source table — lineage captured in consuming table's docs

| Object |
|--------|
| DWH_dbo.etoro_History_Credit |
| DWH_dbo.etoro_Trade_IndexDividends |
| DWH_dbo.etoro_Trade_PositionsHedgeServerChangeLog |
| DWH_dbo.etoro_Trade_PositionsProcessedForIndexDividnds |

</details>
