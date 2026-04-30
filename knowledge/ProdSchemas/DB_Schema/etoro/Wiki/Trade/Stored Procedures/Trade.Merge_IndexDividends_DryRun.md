# Trade.Merge_IndexDividends_DryRun

> Seeds Trade.IndexDividends_DryRun from Trade.IndexDividends for all Pending (Status=0) and Correction Pending (Status=4) dividends not yet present, enabling dry-run testing of dividend workflows without affecting production data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - operates on all eligible dividends |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.Merge_IndexDividends_DryRun populates the dry-run staging table (Trade.IndexDividends_DryRun) with dividend records from the production table (Trade.IndexDividends). It copies only dividends that are in an actionable state: Status=0 (Pending - new dividend, not yet in progress) or Status=4 (Correction Pending - a correction to a prior dividend). These are the dividends that the full dividend pipeline would next process.

This procedure exists to support pre-production validation of the dividend workflow. Before running a live dividend payment cycle, the DividendsApp triggers this procedure to populate the dry-run table with the same data it will process in production, then runs the dry-run variants of snapshot and payment procedures against that copy. Any errors surface safely without touching production data.

Data flows: called by the DividendsApp (permissions confirmed). After this call, Trade.GetDividendsForSnapshot_DryRun and related dry-run procedures can execute against the populated staging table. The snapshot timestamp columns (PositionsSnapshotStarted, PositionsSnapshotCompleted, PositionsSnapshotMarketClose) are inserted as NULL to represent the "not yet snapshotted" state.

---

## 2. Business Logic

### 2.1 Idempotent Pending-Dividend Seed

**What**: MERGE inserts only dividends that do not yet exist in the dry-run table, matching on DividendID.

**Columns/Parameters Involved**: `Trade.IndexDividends.Status`, `Trade.IndexDividends.DividendID`, `Trade.IndexDividends_DryRun.DividendID`

**Rules**:
- Match key: targ.DividendID = src.DividendID.
- Only inserts WHEN NOT MATCHED BY TARGET AND src.Status IN (0, 4).
  - Status=0 (Pending): standard new dividend awaiting processing.
  - Status=4 (Correction Pending): correction dividend for a prior dividend; treated as pending.
  - Status=1 (In Progress) and Status=2 (Completed) are excluded - dry-run only tests unprocessed dividends.
- No WHEN MATCHED clause: existing dry-run rows are never updated by this procedure.
- PositionsSnapshotStarted, PositionsSnapshotCompleted, PositionsSnapshotMarketClose: always inserted as NULL (the dry-run workflow sets these via separate procedures).
- Status in the dry-run table is inserted as 0 (regardless of source Status=4) - all copies start from Pending state in the dry run.

**Diagram**:
```
Trade.IndexDividends (production)
    WHERE Status IN (0, 4)
        |
        v MERGE into Trade.IndexDividends_DryRun
        |- DividendID NOT in DryRun -> INSERT (Status=0, snapshots=NULL)
        |- DividendID already in DryRun -> SKIP

Result: DryRun table seeded with all pending/correction dividends
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | This procedure takes no input parameters. It operates on all dividends in Trade.IndexDividends with Status IN (0, 4) at execution time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| src.DividendID, Status IN (0,4) | Trade.IndexDividends | Read | MERGE source; reads all Pending and Correction Pending dividends |
| targ.DividendID | Trade.IndexDividends_DryRun | Write (MERGE) | MERGE target; inserts new dividend rows not already present; skips existing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp (external) | - | Caller | Called before dry-run dividend processing to seed the staging table |
| Trade.GetDividendsForSnapshot_DryRun | - | Downstream | References Trade.IndexDividends_DryRun after this procedure seeds it |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Merge_IndexDividends_DryRun (procedure)
├── Trade.IndexDividends (table)
└── Trade.IndexDividends_DryRun (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | MERGE source; reads DividendID + all columns for Status IN (0,4) |
| Trade.IndexDividends_DryRun | Table | MERGE target; receives new rows for dividends not yet present |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp | External Application | Calls this procedure to seed dry-run table before testing the dividend pipeline |
| Trade.GetDividendsForSnapshot_DryRun | Procedure | Reads from Trade.IndexDividends_DryRun after this procedure runs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No explicit transaction - MERGE is atomic. No TRY/CATCH - errors propagate to caller.

---

## 8. Sample Queries

### 8.1 Check what this procedure would insert on next run

```sql
SELECT src.DividendID, src.InstrumentID, src.Status, src.DividendDate, src.PaymentDate
FROM Trade.IndexDividends AS src WITH (NOLOCK)
WHERE src.Status IN (0, 4)
  AND NOT EXISTS (
      SELECT 1 FROM Trade.IndexDividends_DryRun AS targ WITH (NOLOCK)
      WHERE targ.DividendID = src.DividendID
  );
```

### 8.2 Compare production vs dry-run table for a dividend

```sql
SELECT 'Production' AS Source, ID.DividendID, ID.Status,
       ID.PositionsSnapshotStarted, ID.PositionsSnapshotCompleted
FROM Trade.IndexDividends AS ID WITH (NOLOCK)
WHERE ID.DividendID = <DividendID>
UNION ALL
SELECT 'DryRun', DR.DividendID, DR.Status,
       DR.PositionsSnapshotStarted, DR.PositionsSnapshotCompleted
FROM Trade.IndexDividends_DryRun AS DR WITH (NOLOCK)
WHERE DR.DividendID = <DividendID>;
```

### 8.3 View current dry-run table contents

```sql
SELECT DR.DividendID, DR.InstrumentID, DR.Status, DR.DividendDate, DR.PaymentDate,
       DR.PositionsSnapshotStarted, DR.PositionsSnapshotCompleted
FROM Trade.IndexDividends_DryRun AS DR WITH (NOLOCK)
ORDER BY DR.DividendID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 downstream (GetDividendsForSnapshot_DryRun) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.Merge_IndexDividends_DryRun | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Merge_IndexDividends_DryRun.sql*
