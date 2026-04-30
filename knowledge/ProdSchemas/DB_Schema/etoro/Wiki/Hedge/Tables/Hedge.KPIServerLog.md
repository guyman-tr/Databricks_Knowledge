# Hedge.KPIServerLog

> Periodic server-level financial KPI log: captures hedge cost, PnL components, HBC execution latency, order success rate, and deposit/withdrawal flows per HedgeServer per time window; written to the primary DB via linked-server synonym by Hedge.InsertKPIData.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ID int IDENTITY (NONCLUSTERED PK + CLUSTERED on ID) |
| **Partition** | No |
| **Indexes** | 3 active (NONCLUSTERED PK on ID, CLUSTERED on ID, NONCLUSTERED on EndTime) |

---

## 1. Business Meaning

Hedge.KPIServerLog stores periodic financial and operational KPI snapshots at the HedgeServer level. For each configured time window, one row is inserted per active HedgeServer, aggregating:
- **Hedge Cost** (computed): The difference between customer zero-cost P&L and account P&L including balances and transactions. Measures the net cost or benefit of hedging.
- **HBC Execution Latency**: Min/Avg/Max execution time for HBC orders in the window.
- **Order Success Rate**: TotalOrderAttempts vs. TotalOrderSuccess.
- **Financial Flows**: Deposits, withdrawals, unrealized PnL start/end snapshots, account balance changes.

The `HedgeCost` computed column formula (from the DDL):
```
HedgeCost = ZeroCustomers - PNLAccount
           where ZeroCustomers = CustomerZeroRealizedPL + (CustomerUnrealizedZeroPL_Last - CustomerUnrealizedZeroPL_First)
           and   PNLAccount = (AccountUnrealizedPNL_Last - AccountUnrealizedPNL_First)
                             + (AccountBalance_Last - AccountBalance_First)
                             - DepositBalance + WithdrawalBalance
```
Negative HedgeCost = hedging is profitable (account PnL > customer zero-cost PnL). Positive = hedging cost.

**Write path**: `Hedge.InsertKPIData` runs on the **secondary database** and inserts into `dbo.RW_KKPIServerLog` (note: double-K typo in synonym name), which points to `[AO-REAL-DB].[etoro].[Hedge].[KPIServerLog]` on the primary. This is why this table is **empty in the current environment** - all writes go to the primary.

**Dedup guard**: InsertKPIData checks `NOT EXISTS (... WHERE KPI.StartTime=T.startTime AND KPI.HedgeServerID=T.HedgeServerID)` and only inserts if at least one metric is non-zero for the period.

Companion to `Hedge.KPIInstrumentLog` (per-instrument volume KPIs for the same time windows).

---

## 2. Business Logic

### 2.1 HedgeCost Computation

**What**: HedgeCost is a computed column measuring net hedging efficiency for the period.

**Columns/Parameters Involved**: `HedgeCost`, `ZeroCustomers`, `PNLAccount`, `CustomerZeroRealizedPL`, `CustomerUnrealizedZeroPL_Last/First`, `AccountUnrealizedPNL_Last/First`, `AccountBalance_Last/First`, `DepositBalance`, `WithdrawalBalance`

**Rules**:
- `ZeroCustomers` (computed) = `CustomerZeroRealizedPL + (CustomerUnrealizedZeroPL_Last - CustomerUnrealizedZeroPL_First)`: The total "zero-cost" P&L for customers in the period. This represents what customers gained (positive) or lost (negative) excluding spread/hedge cost.
- `PNLAccount` (computed) = `(AccountUnrealizedPNL_Last - AccountUnrealizedPNL_First) + (AccountBalance_Last - AccountBalance_First)`: The account's P&L change in the period (unrealized + realized via balance change).
- `HedgeCost` (computed) = `ZeroCustomers - (PNLAccount - DepositBalance + WithdrawalBalance)`: Net hedge cost. Adjusts PNLAccount for deposits (inflows) and withdrawals (outflows).
- Source: `Hedge.GetHedgeCostPerHS(@startTime, @endTime)` function provides the financial aggregates.
- Commission column is read separately from the hedge cost function.

### 2.2 HBC Execution Latency Metrics

**What**: Min/Avg/Max execution time for successful HBC orders in the window.

**Columns/Parameters Involved**: `HBCAvgExecTimeMS`, `HBCMinExecTimeMS`, `HBCMaxExecTimeMS`

**Rules**:
- Source: `AVG/MIN/MAX(DATEDIFF(ms, StartTime, EndTime))` from Hedge.HBCExecutionLog WHERE IsSuccess=1 in the period.
- Units: milliseconds.
- 0 = no successful HBC executions in this period.
- Enables latency trend analysis over time.

### 2.3 Order Success Rate

**What**: Total order attempts vs. successfully filled orders for the period.

**Columns/Parameters Involved**: `TotalOrderAttempts`, `TotalOrderSuccess`

**Rules**:
- `TotalOrderAttempts`: Count of rows from ExecutionRequestBreakdownLog + ExecutionLog (for the period).
- `TotalOrderSuccess`: Count of ExecutionRequestBreakdownLog entries with a matching ExecutionResponseBreakdownLog.WasOpened=1, UNION ExecutionLog entries with OrderState=4 (Fill).
- Success ratio = TotalOrderSuccess / TotalOrderAttempts.

### 2.4 OccurredInsert DEFAULT Inconsistency

**What**: KPIServerLog uses GETDATE() (local time) for OccurredInsert while KPIInstrumentLog uses GETUTCDATE().

**Columns/Parameters Involved**: `OccurredInsert`

**Rules**:
- `Df_Hedge_KPIServerLog_OccurredInsert DEFAULT (getdate())`: Local server time, NOT UTC.
- This differs from KPIInstrumentLog which uses GETUTCDATE(). May cause confusion in cross-table time comparisons if server timezone is not UTC.

---

## 3. Data Overview

0 rows in this environment (secondary DB - writes go to primary [AO-REAL-DB] via synonym `dbo.RW_KKPIServerLog`)

*Expected row structure (from InsertKPIData SP comments: `Exec Hedge.InsertKPIData '20160829 07:00','20160829 07:05'`):*

| ID | StartTime | EndTime | HedgeServerID | HedgeServerMode | ZeroCustomers | HedgeCost | HBCAvgExecTimeMS | TotalOrderAttempts | TotalOrderSuccess |
|---|---|---|---|---|---|---|---|---|---|
| (auto) | 2016-08-29 07:00 | 2016-08-29 07:05 | 1 | 2 | 1500.25 | -250.75 | 145 | 320 | 310 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | CODE-BACKED | Auto-increment surrogate key. NONCLUSTERED PK + CLUSTERED index on same column. NOT FOR REPLICATION prevents identity increment on replication. |
| 2 | OccurredInsert | datetime | NO | getdate() | CODE-BACKED | Server LOCAL time when inserted. Note: uses getdate() (not GETUTCDATE()) - differs from KPIInstrumentLog. May represent server local time rather than UTC. |
| 3 | StartTime | datetime | NO | - | CODE-BACKED | Start of the KPI measurement period (@startTime). Used for dedup check (StartTime + HedgeServerID must be unique). |
| 4 | EndTime | datetime | NO | - | CODE-BACKED | End of the KPI measurement period (@endTime). NC index on EndTime for time-range queries. |
| 5 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server this KPI row covers. Only active servers (IsActive=1 in Trade.HedgeServer) receive rows. |
| 6 | HedgeServerMode | int | NO | - | CODE-BACKED | HedgeStrategyModeID from Trade.HedgeServer at calculation time. |
| 7 | CustomerZeroRealizedPL | decimal(20,4) | YES | - | CODE-BACKED | Realized P&L for customers at zero-cost (without spread) in the period. From Hedge.GetHedgeCostPerHS. Component of ZeroCustomers computed column. |
| 8 | CustomerUnrealizedZeroPL_Last | decimal(20,4) | YES | - | CODE-BACKED | Unrealized customer zero-cost P&L at END of period. Component of ZeroCustomers. |
| 9 | CustomerUnrealizedZeroPL_First | decimal(20,4) | YES | - | CODE-BACKED | Unrealized customer zero-cost P&L at START of period. Component of ZeroCustomers. |
| 10 | AccountUnrealizedPNL_Last | decimal(20,4) | YES | - | CODE-BACKED | Hedge account unrealized P&L at END of period. Component of PNLAccount. |
| 11 | AccountUnrealizedPNL_First | decimal(20,4) | YES | - | CODE-BACKED | Hedge account unrealized P&L at START of period. Component of PNLAccount. |
| 12 | AccountBalance_Last | decimal(20,4) | YES | - | CODE-BACKED | Hedge account balance at END of period. Component of PNLAccount. |
| 13 | AccountBalance_First | decimal(20,4) | YES | - | CODE-BACKED | Hedge account balance at START of period. Component of PNLAccount. |
| 14 | DepositBalance | decimal(20,4) | YES | - | CODE-BACKED | Total deposits into the hedge account in the period (TransactionTypeID=1 in Hedge.AccountTransactions). Netted out of PNLAccount in HedgeCost calculation. |
| 15 | WithdrawalBalance | decimal(20,4) | YES | - | CODE-BACKED | Total withdrawals from the hedge account in the period (TransactionTypeID=2 in Hedge.AccountTransactions). Added back in HedgeCost calculation. |
| 16 | Commission | decimal(20,4) | YES | - | CODE-BACKED | Commission earned/charged in the period. From Hedge.GetHedgeCostPerHS. Separate from the HedgeCost formula. |
| 17 | HBCAvgExecTimeMS | int | YES | - | CODE-BACKED | Average HBC execution time in milliseconds for successful orders in the period. 0 = no HBC executions. |
| 18 | HBCMinExecTimeMS | int | YES | - | CODE-BACKED | Minimum HBC execution time in the period (fastest execution). |
| 19 | HBCMaxExecTimeMS | int | YES | - | CODE-BACKED | Maximum HBC execution time in the period (slowest execution, indicates outliers). |
| 20 | TotalOrderAttempts | int | YES | - | CODE-BACKED | Total number of hedge order attempts in the period (from ExecutionRequestBreakdownLog + ExecutionLog). |
| 21 | TotalOrderSuccess | int | YES | - | CODE-BACKED | Successful fills in the period: ExecutionResponseBreakdownLog.WasOpened=1 matches + ExecutionLog.OrderState=4. Success rate = TotalOrderSuccess / TotalOrderAttempts. |
| 22 | ZeroCustomers | decimal(computed) | - | - | CODE-BACKED | Computed: CustomerZeroRealizedPL + (CustomerUnrealizedZeroPL_Last - CustomerUnrealizedZeroPL_First). Total customer zero-cost P&L for the period. |
| 23 | HedgeCost | decimal(computed) | - | - | CODE-BACKED | Computed: ZeroCustomers - (PNLAccount - DepositBalance + WithdrawalBalance). Net hedging cost. Negative = profitable hedge; positive = cost. |
| 24 | PNLAccount | decimal(computed) | - | - | CODE-BACKED | Computed: (AccountUnrealizedPNL_Last - AccountUnrealizedPNL_First) + (AccountBalance_Last - AccountBalance_First). Total account P&L change in the period. |
| 25 | TotalCancelledVolume | decimal(20,4) | YES | - | CODE-BACKED | Total units cancelled (HBC cancel executions) in the period. From Hedge.HBCExecutionLog where IsCancelExecution=1. |
| 26 | CancelledVolume | decimal(20,4) | YES | - | CODE-BACKED | Subset of cancelled volume (specific cancellation metric, may differ from TotalCancelledVolume). Inserted from the T CTE's TotalCancelledVolume for current-period cancellations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | Implicit (no DDL FK) | Hedge server this KPI covers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InsertKPIData | StartTime + HedgeServerID | Writer (via synonym) | Writes via dbo.RW_KKPIServerLog synonym -> [AO-REAL-DB]. Checks local table for dedup. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.KPIServerLog (table)
  - Written by: Hedge.InsertKPIData via dbo.RW_KKPIServerLog synonym
  - Synonym target: [AO-REAL-DB].[etoro].[Hedge].[KPIServerLog]
  - Companion: Hedge.KPIInstrumentLog (per-instrument volume KPIs)
```

---

### 6.1 Objects This Depends On

No DDL dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InsertKPIData | Procedure | Writes via synonym; checks local table for dedup |
| dbo.RW_KKPIServerLog | Synonym | Points to [AO-REAL-DB].[etoro].[Hedge].[KPIServerLog] (note double-K typo) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_KPIServerLog | NONCLUSTERED PK | ID ASC | - | - | Active (PAGE compression, MAIN filegroup) |
| Idx_Hedge_KPIServerLog | CLUSTERED | ID ASC | - | - | Active (PAGE compression, MAIN filegroup) |
| Idx_Hedge_KPIServerLog_EndTime | NONCLUSTERED | EndTime ASC | - | - | Active (PAGE compression, MAIN filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_KPIServerLog | PRIMARY KEY (NONCLUSTERED) | ID - unique per KPI row |
| Df_Hedge_KPIServerLog_OccurredInsert | DEFAULT | OccurredInsert = getdate() (local time, not UTC) |

---

## 8. Sample Queries

### 8.1 Hedge cost trend by server (run on primary DB)
```sql
SELECT HedgeServerID, StartTime, EndTime,
       ZeroCustomers, PNLAccount, HedgeCost,
       TotalOrderAttempts, TotalOrderSuccess,
       HBCAvgExecTimeMS
FROM Hedge.KPIServerLog WITH (NOLOCK)
WHERE StartTime >= '2024-01-01'
  AND HedgeServerID = 1
ORDER BY StartTime;
```

### 8.2 Order success rate over time
```sql
SELECT HedgeServerID, StartTime,
       TotalOrderAttempts, TotalOrderSuccess,
       CASE WHEN TotalOrderAttempts > 0
            THEN 100.0 * TotalOrderSuccess / TotalOrderAttempts
            ELSE NULL END AS SuccessRatePct
FROM Hedge.KPIServerLog WITH (NOLOCK)
WHERE EndTime > DATEADD(day, -7, GETUTCDATE())
ORDER BY HedgeServerID, StartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for Hedge.KPIServerLog.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (InsertKPIData) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.KPIServerLog | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.KPIServerLog.sql*
