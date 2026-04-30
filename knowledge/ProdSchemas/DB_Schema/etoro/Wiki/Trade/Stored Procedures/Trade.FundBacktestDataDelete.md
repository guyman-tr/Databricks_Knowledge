# Trade.FundBacktestDataDelete

> Deletes backtest allocation data for a specific fund by removing FundIntervalAllocation records linked to backtest-type fund intervals.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure removes backtest data for a Smart Portfolio (fund) by deleting allocation records that belong to backtest intervals. When a fund manager creates a new fund, the system generates backtest allocations (FundIntervalType=1) to simulate historical performance. This procedure cleans up those backtest records, typically before regenerating backtests with updated parameters or before publishing the fund.

The two-step approach (collect FundIntervalIDs into a temp table, then delete matching allocations) ensures only backtest allocations are removed while preserving live allocation data.

---

## 2. Business Logic

### 2.1 Backtest Interval Identification

**What**: Identifies fund intervals that are backtests (type 1) for the specified fund.

**Columns/Parameters Involved**: `FundID`, `FundIntervalType`

**Rules**:
- FundIntervalType = 1 identifies backtest intervals (as opposed to live intervals)
- Only allocations linked to these backtest intervals are deleted
- Live allocations (other FundIntervalType values) are preserved

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundID | int | NO | - | CODE-BACKED | Smart Portfolio (fund) identifier whose backtest data should be deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.FundInterval | READER | Reads backtest interval IDs (FundIntervalType=1) for the fund |
| DELETE | Trade.FundIntervalAllocation | DELETER | Removes allocation records for backtest intervals |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FundBacktestDataDelete (procedure)
+-- Trade.FundInterval (table)
+-- Trade.FundIntervalAllocation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FundInterval | Table | SELECT - identifies backtest intervals |
| Trade.FundIntervalAllocation | Table | DELETE - removes backtest allocation records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Temp table: #FundInterval with PRIMARY KEY on FundIntervalID.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Delete Backtest Data for a Fund

```sql
EXEC Trade.FundBacktestDataDelete @FundID = 100
```

### 8.2 Preview Backtest Intervals for a Fund

```sql
SELECT FundIntervalID, FundID, FundIntervalType
  FROM Trade.FundInterval WITH (NOLOCK)
 WHERE FundID = 100 AND FundIntervalType = 1
```

### 8.3 Count Allocations by Interval Type

```sql
SELECT fi.FundIntervalType,
       COUNT(fia.FundIntervalID) AS AllocationCount
  FROM Trade.FundInterval fi WITH (NOLOCK)
  JOIN Trade.FundIntervalAllocation fia WITH (NOLOCK) ON fi.FundIntervalID = fia.FundIntervalID
 WHERE fi.FundID = 100
 GROUP BY fi.FundIntervalType
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FundBacktestDataDelete | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.FundBacktestDataDelete.sql*
