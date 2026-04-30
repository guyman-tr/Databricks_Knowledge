# Trade.ExposuresForAllHedgeServers_Check

> Reconciles the materialized hedge exposure table against live position data, logs discrepancies, and corrects drift by updating, zeroing, or inserting exposure records.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Reconciles Trade.ExposuresForAllHedgeServers vs Trade.Position |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a data integrity reconciliation job for the hedge exposure tracking system. The `Trade.ExposuresForAllHedgeServers` table maintains a materialized summary of open buy/sell lot counts per customer, provider, instrument, and hedge server. This table is updated incrementally by `Trade.ExposuresForAllHedgeServers_Update` during position opens and closes. Over time, these incremental updates can drift from the true position state (due to edge cases, failures, or timing issues).

This procedure recalculates the true exposures from scratch by aggregating `Trade.Position` data (positions where `IsComputeForHedge = 1`), then identifies three types of discrepancies: value differences (exposure table has wrong buy/sell totals), orphaned records (in the exposure table but no matching positions), and missing records (positions exist but no exposure record). It logs all discrepancies to `Trade.ExposuresForAllHedgeServers_Log` and then applies corrections: updates incorrect values, zeros out orphaned records, and inserts missing records.

The entire operation runs under SERIALIZABLE isolation level within a transaction to prevent concurrent modifications during the reconciliation window.

---

## 2. Business Logic

### 2.1 Three-Way Discrepancy Detection

**What**: Identifies all forms of drift between the materialized exposure table and the live position truth.

**Columns/Parameters Involved**: `OpenedBuy`, `OpenedSell`, `OpenedBuyQuery`, `OpenedSellQuery`

**Rules**:
- Type 1 - "Records With Differences": Exposure and position data both exist but buy/sell totals don't match
- Type 2 - "Records in New Table and Not Old View": Exposure record exists with non-zero values but no matching position group (orphaned exposures)
- Type 3 - "Records in Old View and not New Table": Position group exists but no matching exposure record (missing exposures)
- All discrepancies are logged to ExposuresForAllHedgeServers_Log with timestamp and description before corrections are applied

### 2.2 Correction Application

**What**: Fixes all detected discrepancies in a single transaction.

**Columns/Parameters Involved**: `OpenedBuy`, `OpenedSell`

**Rules**:
- Value differences: UPDATE exposure record with correct position-derived values
- Orphaned records: UPDATE to zero (OpenedBuy=0, OpenedSell=0) rather than DELETE
- Missing records: INSERT new exposure records from position data
- All corrections happen within the SERIALIZABLE transaction

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No parameters. Operates on all data in Trade.ExposuresForAllHedgeServers and Trade.Position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.Position (view) | READER | Aggregates position data for true exposure calculation (IsComputeForHedge=1) |
| SELECT/UPDATE/INSERT | Trade.ExposuresForAllHedgeServers | MIXED | Reads current exposures, updates incorrect values, zeros orphans, inserts missing |
| INSERT | Trade.ExposuresForAllHedgeServers_Log | WRITER | Logs all discrepancies found during reconciliation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | Scheduled | Job | Periodic reconciliation job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExposuresForAllHedgeServers_Check (procedure)
+-- Trade.Position (view)
+-- Trade.ExposuresForAllHedgeServers (table)
+-- Trade.ExposuresForAllHedgeServers_Log (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT with GROUP BY - calculates true exposures |
| Trade.ExposuresForAllHedgeServers | Table | SELECT, UPDATE, INSERT - reads, corrects, and adds exposure records |
| Trade.ExposuresForAllHedgeServers_Log | Table | INSERT - logs all discrepancies |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

Temp table indexes: CLUSTERED INDEX on (CID, ProviderID, InstrumentID, HedgeServerID)

### 7.2 Constraints

None.

**Isolation Level**: Uses `SET TRANSACTION ISOLATION LEVEL SERIALIZABLE` with explicit transaction to prevent concurrent position changes during reconciliation. Resets to `READ UNCOMMITTED` after commit.

**Deadlock Priority**: `SET DEADLOCK_PRIORITY LOW` - yields to other transactions in deadlock scenarios since reconciliation can be retried.

---

## 8. Sample Queries

### 8.1 Run Exposure Reconciliation

```sql
EXEC Trade.ExposuresForAllHedgeServers_Check
```

### 8.2 View Recent Reconciliation Discrepancies

```sql
SELECT TOP 100
       DateChecked,
       ErrorDescription,
       CID,
       InstrumentID,
       HedgeServerID,
       OpenedBuy,
       OpenedBuyQuery,
       OpenedSell,
       OpenedSellQuery
  FROM Trade.ExposuresForAllHedgeServers_Log WITH (NOLOCK)
 ORDER BY DateChecked DESC
```

### 8.3 Compare Current Exposures vs Live Positions

```sql
SELECT TP.CID,
       TP.ProviderID,
       TP.InstrumentID,
       TP.HedgeServerID,
       SUM(CASE WHEN TP.IsBuy = 1 THEN ISNULL(TP.LotCountDecimal, 0) ELSE 0 END) AS CalcBuy,
       SUM(CASE WHEN TP.IsBuy = 0 THEN ISNULL(TP.LotCountDecimal, 0) ELSE 0 END) AS CalcSell,
       E.OpenedBuy AS TableBuy,
       E.OpenedSell AS TableSell
  FROM Trade.Position TP WITH (NOLOCK)
  LEFT JOIN Trade.ExposuresForAllHedgeServers E WITH (NOLOCK)
    ON TP.CID = E.CID AND TP.ProviderID = E.ProviderID
   AND TP.InstrumentID = E.InstrumentID AND TP.HedgeServerID = E.HedgeServerID
 WHERE TP.IsComputeForHedge = 1
 GROUP BY TP.CID, TP.ProviderID, TP.InstrumentID, TP.HedgeServerID, E.OpenedBuy, E.OpenedSell
HAVING SUM(CASE WHEN TP.IsBuy = 1 THEN ISNULL(TP.LotCountDecimal, 0) ELSE 0 END) <> ISNULL(E.OpenedBuy, 0)
    OR SUM(CASE WHEN TP.IsBuy = 0 THEN ISNULL(TP.LotCountDecimal, 0) ELSE 0 END) <> ISNULL(E.OpenedSell, 0)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExposuresForAllHedgeServers_Check | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ExposuresForAllHedgeServers_Check.sql*
