# Trade.DeleteFundAllocationBacktestData

> Removes fund interval allocation rows associated with backtest intervals (FundIntervalType=1) for a specific fund account.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundAccountID (identifies the fund whose backtest data should be deleted) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteFundAllocationBacktestData removes backtest allocation data for a specific fund account from Trade.FundIntervalAllocation. CopyFund (Smart Portfolios) uses interval-based allocation modeling where real intervals drive actual portfolio rebalancing and backtest intervals simulate historical performance. This procedure cleans up the backtest simulation data when it is no longer needed.

This procedure exists to allow fund managers to reset or remove backtest data for a fund without affecting real (production) allocation intervals. Backtest intervals are identified by FundIntervalType=1 in Trade.FundInterval.

Data flow: The procedure joins Trade.FundIntervalAllocation to Trade.FundInterval (for the interval metadata) to Trade.Fund (for the fund-to-account mapping). It deletes allocation rows where the fund's FundAccountID matches and the interval type is backtest (1).

---

## 2. Business Logic

### 2.1 Backtest-Only Deletion

**What**: Only backtest interval allocations are deleted; real/production intervals are preserved.

**Columns/Parameters Involved**: `@FundAccountID`, `FundIntervalType`

**Rules**:
- FundIntervalType = 1 identifies backtest intervals
- Real/production intervals (other FundIntervalType values) are not affected
- Three-table join traverses: FundIntervalAllocation -> FundInterval -> Fund -> WHERE FundAccountID = @FundAccountID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundAccountID | INT | NO | - | CODE-BACKED | The fund account identifier whose backtest allocation data should be deleted. Maps to Trade.Fund.FundAccountID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE) | Trade.FundIntervalAllocation | DELETER | Removes backtest allocation rows |
| (JOIN) | Trade.FundInterval | READ | Joined to identify which intervals are backtest type |
| (JOIN) | Trade.Fund | READ | Joined to filter by FundAccountID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteFundAllocationBacktestData (procedure)
+-- Trade.FundIntervalAllocation (table)
+-- Trade.FundInterval (table)
+-- Trade.Fund (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FundIntervalAllocation | Table | DELETE target for backtest allocations |
| Trade.FundInterval | Table | JOIN to filter by FundIntervalType=1 (backtest) |
| Trade.Fund | Table | JOIN to filter by FundAccountID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Delete backtest data for a fund account

```sql
EXEC Trade.DeleteFundAllocationBacktestData @FundAccountID = 99
```

### 8.2 Preview backtest allocations before deletion

```sql
SELECT  fia.FundIntervalID, fi.FundID, f.FundAccountID, fi.FundIntervalType
FROM    Trade.FundIntervalAllocation fia WITH (NOLOCK)
        INNER JOIN Trade.FundInterval fi WITH (NOLOCK) ON fia.FundIntervalID = fi.FundIntervalID
        INNER JOIN Trade.Fund f WITH (NOLOCK) ON fi.FundID = f.FundID
WHERE   f.FundAccountID = 99 AND fi.FundIntervalType = 1
```

### 8.3 Verify deletion

```sql
SELECT  COUNT(*) AS RemainingBacktest
FROM    Trade.FundIntervalAllocation fia WITH (NOLOCK)
        INNER JOIN Trade.FundInterval fi WITH (NOLOCK) ON fia.FundIntervalID = fi.FundIntervalID
        INNER JOIN Trade.Fund f WITH (NOLOCK) ON fi.FundID = f.FundID
WHERE   f.FundAccountID = 99 AND fi.FundIntervalType = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteFundAllocationBacktestData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteFundAllocationBacktestData.sql*
