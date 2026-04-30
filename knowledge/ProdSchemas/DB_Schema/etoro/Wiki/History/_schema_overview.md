# History Schema - Overview

> Long-term archive and audit schema for eToro's trading platform. Stores all completed trading events, customer lifecycle snapshots, financial transactions, and system operations after they exit the live Trade/Customer schemas.

| Property | Value |
|----------|-------|
| **Database** | etoro |
| **Schema** | History |
| **Total Objects** | 484 |
| **Tables** | 312 |
| **Views** | 38 |
| **Functions** | 14 |
| **Stored Procedures** | 86 |
| **Synonyms** | 31 |
| **User Defined Types** | 3 |
| **Documentation** | 100% (484/484) - 20 batches |
| **Documented** | 2026-03-21 |

---

## 1. Business Purpose

The History schema is eToro's **write-once, read-many archive layer**. When trading or customer events complete in the live `Trade`, `Customer`, and `Game` schemas, the History schema permanently stores them for:

- **Regulatory compliance** - immutable audit trails for all financial transactions and customer state changes
- **Customer-facing history** - position history, account statements, funding history exposed through HistoryWS
- **Internal analytics** - batch jobs for risk, margin, dividend, and drawdown calculations query History for completed events
- **Operational recovery** - AsyncFailedSteps and PositionFail tables capture failures for retry/investigation
- **Financial reconciliation** - BillingFunding, WithdrawAction, DepositAction provide the ledger for payment reconciliation

---

## 2. Scale

| Table | Total Rows | Domain |
|-------|-----------|--------|
| History.ActiveCustomerToFunding | ~1.54B | Customer-to-funding account linkage snapshots |
| History.BSLCurrencyPriceSnapShots | ~1.08B | Bonus Stop Loss currency price monitoring |
| History.TradonomiToLiquidityProviderContracts | ~441M | LP contract history (Tradonomi) |
| History.BillingFunding | ~225M | Payment/funding transaction history |
| History.BackOfficeCustomer | ~145M | Customer state snapshots for back-office |
| History.Customer | ~49M | Customer profile history |
| History.Deposit | ~45M | Deposit event history |
| History.WithdrawLog | ~41M | Withdrawal log |
| History.DepositAction | ~37M | Deposit processing actions |
| History.ActiveCredit_BIGINT | ~26M | Active credit state history |
| History.AsyncFailedSteps | ~20M | Async background job failures |
| History.AuditHistory | ~7.7M | Admin/compliance audit trail |
| History.BSLPositionsInfo | ~6.5M | BSL position info snapshots |
| History.WithdrawAction | ~6.2M | Withdrawal actions |

---

## 3. Domain Map

The History schema covers 9 major functional domains:

### 3.1 Position Archive

The core reason for the History schema's existence: storing closed trading positions permanently.

| Object | Role |
|--------|------|
| History.Position (view) | Union view over all partition tables - the primary read interface for closed positions |
| History.Position_Active | Partition table: recent closed positions (BIGINT PositionID range) |
| History.Position_Active_BIGINT | Partition table: high-volume BIGINT positions |
| History.Position_Active_New | Partition table: newest positions |
| History.PositionSlim (view) | Lightweight read-optimized view for recent position data |
| History.PositionFail | Async-written table of position open/close failures (ActionID=5) |
| History.PositionFailLocal | Pre-async staging for PositionFail inserts |
| History.PostPositionFail | Async executor procedure: reads PositionFailLocal -> inserts PositionFail |
| History.PositionAirdropFailInfo | Crypto airdrop failure path: wraps PositionFailInfo + updates Trade.PositionAirdropLog |

**Async write pattern**: All History.Position inserts flow through Trade.PostClosePositionActions (or Trade.PostClosePositionActionsBulk) -> History.InsertPosition_Active. Async failures go via Trade.InsertAsyncRecord (ActionID=5) -> Internal.AsyncExecuter -> History.PostPositionFail -> History.PositionFailLocal.

### 3.2 Account and Customer History

| Object | Role |
|--------|------|
| History.Account | Account-level financial state snapshot |
| History.Accounts | Broader customer account history |
| History.AccountStatus | Account status change log |
| History.Customer | Customer profile snapshots |
| History.BackOfficeCustomer | Customer state for back-office consumption |
| History.AuditHistory | Admin action audit trail (compliance) |
| History.ActionsLog | Customer action log (including edit stop loss, etc.) |

### 3.3 Financial Operations (Billing/Payments)

| Object | Role |
|--------|------|
| History.BillingFunding | Funding (deposit/withdrawal) transaction history |
| History.Deposit | Deposit event log |
| History.DepositAction | Deposit processing action log |
| History.WithdrawAction | Withdrawal action log (TBL_WithdrawAction UDT) |
| History.WithdrawLog | Withdrawal processing log |
| History.WithdrawToFundingAction | Cross-reference: withdrawal to funding |
| History.ActiveCustomerToFunding | Snapshot of customer-to-funding-account linkage (1.5B rows - highest volume table) |

### 3.4 Credit and Bonus System

| Object | Role |
|--------|------|
| History.ActiveCredit_BIGINT | Active credit state - high volume snapshot table |
| History.ActiveCreditExtended | Extended credit history |
| History.ActiveCreditOld | Legacy credit snapshot (pre-BIGINT migration) |
| History.ActiveCreditRecentMemoryBucket | Recent credit bucket tracking (UDT: ActiveCreditRecentMemoryBucket_TYPE) |
| History.AccountToBonus | Account-to-bonus assignment history |
| History.BonusCreditChange | Bonus credit change log |

### 3.5 BSL (Bonus Stop Loss) Monitoring

BSL is eToro's system that auto-closes positions when bonus credit is exhausted. The History schema maintains price and position snapshots for BSL calculations.

| Object | Role |
|--------|------|
| History.BSLCurrencyPriceSnapShots | Currency price snapshots for BSL evaluation (1.08B rows, partitioned) |
| History.BSLCurrencyPriceSnapShotsPartition | Partition variant |
| History.BSLPositionsInfo | Position info used for BSL state snapshots |
| History.BSLPositionsInfoPartition | Partition variant |
| History.BSL_MIMOSnapShotsPartition | MIMO (multi-instrument margin offset) snapshots |
| History.BSLDataForAllUsers | BSL data aggregated across all users |
| History.BSLSuspectedWrongResults | Audit log for BSL result anomalies |

### 3.6 Authentication and Session History

| Object | Role |
|--------|------|
| History.LogIn | Session creation procedure - creates History.Customer.Login row; called for all login paths |
| History.LogInIB | Introducing Broker combined register-and-login |
| History.LogOut | Session close procedure |
| History.LogOutByLoginID | Session close by login action ID |
| History.ForexResult | Game session context for historical positions (GameTypeID, ForexGameID) |

### 3.7 Stock Split Processing

When a public company performs a stock split, all closed positions must be retroactively adjusted:

| Object | Role |
|--------|------|
| History.SplitRatio | Split event parameters (InstrumentID, PriceRatioUnAdjusted, AmountRatioUnAdjusted, MinDate) |
| History.SplitClosePositions | Retroactive adjustment processor: updates 10 rate/unit columns in History.Position (2000-row batches) |
| History.PositionSplit | Idempotency audit log: records which positions have been adjusted for which split (via OUTPUT clause) |

### 3.8 Active Customer Maintenance

| Object | Role |
|--------|------|
| History.LastPostionOperationDateByCID | Per-customer lookup: most recent position operation date + OpenPositionExists flag |
| History.UpdateLastPostionOperationDataByCID | Refresh job: MERGE from Trade.PositionTbl + History.PositionSlim (2-day lookback) into LastPostionOperationDateByCID |

This table powers batch jobs (Trade.GetPartitionDrawDownActiveCustomers, Trade.GetRankingGainPartitionActiveCustomers) that filter for recently active trading customers.

### 3.9 HistoryWS Interface

Legacy History Web Service (HistoryWS) read procedures:

| Object | Role |
|--------|------|
| History.PR_GetPosition_For_HistoryWS | Open position data for HistoryWS (queries Trade.GetPosition with date range; divides amounts by 100) |
| History.GetHistoryDataByCID | Customer history data aggregate |
| History.GetClosedPositions | Closed position lookup view |
| History.GetClosedPositionsPerPage | Paginated closed positions |
| History.GetForexResult | Closed game result aggregation |

---

## 4. Key Architectural Patterns

### 4.1 Partition Table Architecture

The largest objects use partition/union patterns to manage data at scale:

```
History.Position (view) - UNION ALL of:
  +-- History.Position_Active        (primary archive partition)
  +-- History.Position_Active_BIGINT (high-volume BIGINT IDs)
  +-- History.Position_Active_New    (most recent, fastest reads)

History.BSLCurrencyPriceSnapShots (partitioned by filegroup)
History.BSL_MIMOSnapShotsPartition (partitioned)
```

### 4.2 Async Write Pattern

History schema uses a 3-step async pattern to decouple live trade execution from archival I/O:

```
[Trade Execution] -> Trade.InsertAsyncRecord (ActionID=N) -> [queue]
                                                             |
                                                    Internal.AsyncExecuter (background)
                                                             |
                                              History.PostPositionFail / History.InsertPosition_Active / etc.
                                                             |
                                                    History.PositionFail / History.Position_Active / etc.
```

History.AsyncFailedSteps captures jobs that fail in this pipeline for investigation and retry.

### 4.3 Synonyms as Cross-Schema Aliases

31 synonyms in the History schema create local aliases for objects in other schemas (primarily Trade and Customer). This allows HistoryWS and legacy callers to query History.* names while the underlying data lives in the live schema. Key synonyms include aliases for Trade.PositionTbl, Trade.GetInstrument, Customer.Customer.

### 4.4 Unit Convention (Cents)

Most financial amounts in the History schema are stored in **cents** (integer * 100). Callers (HistoryWS procedures, reporting) divide by 100 for display. Example: History.PR_GetPosition_For_HistoryWS divides Amount and NetProfit+Commission by 100.

---

## 5. Cross-Schema Dependencies

| External Schema | How History Uses It |
|----------------|-------------------|
| Trade | Position data (Trade.PositionTbl, Trade.GetPosition), instrument/provider data, async queue (Trade.InsertAsyncRecord) |
| Customer | Customer profiles (Customer.Customer, Customer.RegistrationRequest), registration (Customer.RegisterReal) |
| Dictionary | All lookup tables (GameType, Currency, State, FailType, etc.) |
| Game | Game session context (Game.ForexResult, Game.ForexGame) |
| Internal | Utility functions (Internal.NormalizeString), async executor (Internal.AsyncExecuter) |
| BackOffice | Back-office procedures read History tables for customer closed positions |
| Billing | Billing procedures write to History.BillingFunding; read from History for reconciliation |

---

## 6. Quality Summary

| Metric | Value |
|--------|-------|
| Total objects documented | 484 |
| Documentation sessions (batches) | 20 |
| Average quality score | ~8.9/10 |
| Lowest quality | 6.5 (History.BonusCreditChange - sparse DDL) |
| Highest quality | 9.4 (History.ActiveCreditRecentMemoryBucket) |
| Objects with Phase 12 enrichment | 484 (all, via cross-session inheritance) |
| Glossary concepts added | 3 (Stock Split, Introducing Broker, Crypto Airdrop) |

---

## 7. Navigation

| Domain | Start Here |
|--------|-----------|
| Position history | [History.Position](Views/History.Position.md) |
| Position failures | [History.PositionFail](Tables/History.PositionFail.md) |
| Authentication | [History.LogIn](Stored%20Procedures/History.LogIn.md) |
| Financial operations | [History.BillingFunding](Tables/History.BillingFunding.md) |
| BSL monitoring | [History.BSLCurrencyPriceSnapShots](Tables/History.BSLCurrencyPriceSnapShots.md) |
| Credit system | [History.ActiveCredit_BIGINT](Tables/History.ActiveCredit_BIGINT.md) |
| Stock splits | [History.SplitClosePositions](Stored%20Procedures/History.SplitClosePositions.md) |
| Active customers | [History.LastPostionOperationDateByCID](Tables/History.LastPostionOperationDateByCID.md) |
| All objects | [_index.md](_index.md) |
| Business terms | [_glossary.md](../_glossary.md) |

---

*Generated: 2026-03-21 | Schema: History | Database: etoro | Objects: 484 | Documentation: Complete (20 batches)*
