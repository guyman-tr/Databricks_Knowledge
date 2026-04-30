# AffiliateCommission.LoadClosedPositionsAndAggregates_ADF

> ADF (Azure Data Factory) pipeline procedure that loads closed positions from the BI layer, inserts position history, and upserts customer aggregated data in a single atomic transaction.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Loads from BILoad into ADF staging + aggregation tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

LoadClosedPositionsAndAggregates_ADF is a batch ETL procedure called by Azure Data Factory (ADF) to load closed position data from the BI revenue-share calculation layer into the commission system. It performs three operations in a single transaction: (1) inserts new closed positions from BILoad.RevsharePositionSummary into ClosedPositionFromEtoro_ADF, (2) inserts detailed position history into History.ClosedPosition_ADF, and (3) upserts customer aggregated commission data via a MERGE into CustomerAggregatedData_ADF.

This procedure exists as the ADF-based alternative to the real-time Service Broker pipeline. While the real-time pipeline processes individual positions via GetClosedPositionsFromEtoro, this batch procedure processes all positions from a revenue-share calculation run at once. It includes safeguards: it exits if no BILoad data exists or if the LastRunDate is out of sync.

The Commission column is calculated as (Commission + CloseTotalFees) * 100, converting from dollars to cents format. The MERGE on CustomerAggregatedData_ADF incrementally sums commission totals and updates last position dates.

---

## 2. Business Logic

### 2.1 Three-Phase Atomic Load

**What**: Loads positions, history, and aggregated data in one transaction.

**Columns/Parameters Involved**: `@LastRunDate`, `@NextRunTime`

**Rules**:
- Phase 1: INSERT into ClosedPositionFromEtoro_ADF from BILoad.RevsharePositionSummary WHERE LastClosedPosition IS NOT NULL
- Phase 2: INSERT into History.ClosedPosition_ADF by joining BILoad.HistoryClosedPosition with the just-inserted positions (via CID match)
- Phase 3: MERGE into CustomerAggregatedData_ADF - WHEN MATCHED: incrementally add commission totals, update last position dates; WHEN NOT MATCHED: insert new customer row
- After MERGE: UPDATE BILoad.LastRevshareRuntime SET LastRun = @NextRunTime
- Commission formula: CAST(ISNULL(Commission, 0) + ISNULL(CP_CloseTotalFees, 0) AS MONEY) * 100

### 2.2 Sync Safeguards

**What**: Prevents data corruption from out-of-sync or empty runs.

**Columns/Parameters Involved**: `@LastRunDate`, `BILoad.HistoryClosedPosition`, `BILoad.LastRevshareRuntime`

**Rules**:
- If BILoad.HistoryClosedPosition is empty: logs and returns (no data to process)
- If BILoad.LastRevshareRuntime.LastRun != @LastRunDate: logs "not sync" and returns (prevents stale data load)
- Both conditions log via BILoad.UpdateProgress_Log for observability

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LastRunDate | datetime (IN) | NO | - | CODE-BACKED | Expected last run timestamp. Must match BILoad.LastRevshareRuntime.LastRun for the load to proceed. |
| 2 | @NextRunTime | datetime (IN) | NO | - | CODE-BACKED | Timestamp to set as the new LastRun after successful load. Also used as DateModified in CustomerAggregatedData_ADF. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPositionFromEtoro_ADF | WRITE (INSERT) | Loads closed positions from BI layer |
| - | History.ClosedPosition_ADF | WRITE (INSERT) | Loads position history with ClosedPositionID linkage |
| - | AffiliateCommission.CustomerAggregatedData_ADF | WRITE (MERGE) | Upserts customer aggregated commission data |
| - | BILoad.RevsharePositionSummary | READ (SELECT) | Source of closed position and aggregation data |
| - | BILoad.HistoryClosedPosition | READ (SELECT + EXISTS check) | Source of position history; existence check for safeguard |
| - | BILoad.LastRevshareRuntime | READ (SELECT) + WRITE (UPDATE) | Sync check and watermark update |
| - | BILoad.UpdateProgress_Log | EXEC | Logging |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by Azure Data Factory pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.LoadClosedPositionsAndAggregates_ADF (procedure)
+-- AffiliateCommission.ClosedPositionFromEtoro_ADF (table)
+-- AffiliateCommission.CustomerAggregatedData_ADF (table)
+-- History.ClosedPosition_ADF (table, external)
+-- BILoad.RevsharePositionSummary (table/view, external)
+-- BILoad.HistoryClosedPosition (table, external)
+-- BILoad.LastRevshareRuntime (table, external)
+-- BILoad.UpdateProgress_Log (procedure, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionFromEtoro_ADF | Table | INSERT from BI layer |
| AffiliateCommission.CustomerAggregatedData_ADF | Table | MERGE (upsert) |
| History.ClosedPosition_ADF | Table (external) | INSERT position history |
| BILoad.RevsharePositionSummary | Table/View (external) | Source of position and aggregation data |
| BILoad.HistoryClosedPosition | Table (external) | Source of position history |
| BILoad.LastRevshareRuntime | Table (external) | Sync check + watermark update |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Azure Data Factory pipeline) | External | Triggers this procedure for batch loading |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | TRAN | All three phases atomic - INSERT positions + INSERT history + MERGE aggregates |

---

## 8. Sample Queries

### 8.1 Execute the ADF load
```sql
EXEC [AffiliateCommission].[LoadClosedPositionsAndAggregates_ADF]
    @LastRunDate = '2026-04-11 00:00:00',
    @NextRunTime = '2026-04-12 00:00:00'
```

### 8.2 Check sync status
```sql
SELECT LastRun FROM [BILoad].[LastRevshareRuntime] WITH (NOLOCK)
```

### 8.3 View ADF-loaded closed positions
```sql
SELECT TOP 10 ClosedPositionID, CID, CloseOccurred, Commission, ProcessingDate
FROM [AffiliateCommission].[ClosedPositionFromEtoro_ADF] WITH (NOLOCK)
ORDER BY ClosedPositionID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.LoadClosedPositionsAndAggregates_ADF.sql*
