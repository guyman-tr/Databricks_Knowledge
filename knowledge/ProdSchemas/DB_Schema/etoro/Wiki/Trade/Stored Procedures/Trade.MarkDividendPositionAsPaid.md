# Trade.MarkDividendPositionAsPaid

> Idempotent batch-insert that marks a set of (PositionID, DividendID) pairs in Trade.PositionsProcessedForIndexDividnds, recording that each position has been processed for its dividend payment.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @positiondividendTbl - batch of (PositionID, DividendID) pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MarkDividendPositionAsPaid records that a set of positions have been processed for specific dividend events. It is the "mark as done" step in the dividend payment pipeline: after the DividendsApp calculates and pays dividends to position holders, it calls this procedure to insert tracking rows into Trade.PositionsProcessedForIndexDividnds so the same positions are not paid again for the same dividend.

This procedure exists because dividend processing must be idempotent - if the pipeline runs twice, positions should not receive double payments. The MERGE (INSERT only when NOT MATCHED) ensures no duplicate rows are created for any (DividendID, PositionID) pair that already exists.

Data flows: the DividendsApp (external application, referenced in PROD permissions) builds a batch of processed position/dividend pairs and calls this procedure. PaymentAmount is inserted as 0 - the actual payment amount is presumably updated by a subsequent step or stored elsewhere in the pipeline.

---

## 2. Business Logic

### 2.1 Idempotent MERGE Insert

**What**: Uses MERGE to insert new (DividendID, PositionID) pairs while silently skipping pairs already recorded.

**Columns/Parameters Involved**: `DividendID`, `PositionID`, `PaymentAmount`

**Rules**:
- Match condition: trg.DividendID = src.DividendID AND trg.PositionID = src.PositionID.
- WHEN NOT MATCHED BY TARGET: INSERT (DividendID, PositionID, PaymentAmount) VALUES (src, src, 0).
- No WHEN MATCHED clause: existing rows are never updated by this procedure.
- PaymentAmount is always inserted as 0; the actual credit amount is managed by other parts of the dividend pipeline.
- Result: safe to call multiple times with the same batch - only the first call inserts.

**Diagram**:
```
Input TVP (PositionID, DividendID)
    |
    v MERGE into Trade.PositionsProcessedForIndexDividnds
    |- NOT MATCHED (new) -> INSERT with PaymentAmount=0
    |- ALREADY EXISTS    -> Skip (no WHEN MATCHED clause)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @positiondividendTbl | Trade.PositionAnsDividendTbl (READONLY TVP) | NO | - | CODE-BACKED | Batch of (PositionID BIGINT, DividendID INT) pairs to mark as processed. Each row represents one position that was paid for one dividend event. READONLY TVP - see Trade.PositionAnsDividendTbl UDT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DividendID, PositionID | Trade.PositionsProcessedForIndexDividnds | Write (MERGE) | Inserts new (DividendID, PositionID, PaymentAmount=0) rows when not already present; prevents duplicate dividend payment tracking |
| @positiondividendTbl | Trade.PositionAnsDividendTbl | UDT Reference | TVP type carrying position/dividend pairs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp (external application) | - | Caller | Referenced in PROD_BIadmins permissions - the DividendsApp calls this procedure after processing dividend payments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MarkDividendPositionAsPaid (procedure)
├── Trade.PositionAnsDividendTbl (type - TVP)
└── Trade.PositionsProcessedForIndexDividnds (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionAnsDividendTbl | User Defined Type | TVP parameter type (PositionID, DividendID) |
| Trade.PositionsProcessedForIndexDividnds | Table | MERGE target - inserts new rows; skips existing ones |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp | External Application | Calls this procedure to mark positions as paid after dividend processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: no explicit transaction - MERGE is a single statement and is atomic by default.

---

## 8. Sample Queries

### 8.1 Check recently marked dividend positions

```sql
SELECT TOP 20 PP.PositionID, PP.DividendID, PP.PaymentAmount, PP.ProcessTime, PP.CreditID
FROM Trade.PositionsProcessedForIndexDividnds AS PP WITH (NOLOCK)
ORDER BY PP.ProcessTime DESC;
```

### 8.2 Find positions processed for a specific dividend

```sql
SELECT PP.PositionID, PP.DividendID, PP.PaymentAmount, PP.ProcessTime
FROM Trade.PositionsProcessedForIndexDividnds AS PP WITH (NOLOCK)
WHERE PP.DividendID = <DividendID>
ORDER BY PP.PositionID;
```

### 8.3 Identify pairs that would be inserted vs skipped by a new call

```sql
-- Rows from hypothetical TVP that do NOT yet exist in the tracking table
SELECT src.PositionID, src.DividendID
FROM (VALUES (<PositionID1>, <DividendID1>), (<PositionID2>, <DividendID2>)) AS src(PositionID, DividendID)
LEFT JOIN Trade.PositionsProcessedForIndexDividnds AS trg WITH (NOLOCK)
    ON trg.DividendID = src.DividendID AND trg.PositionID = src.PositionID
WHERE trg.PositionID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers (DividendsApp is external) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MarkDividendPositionAsPaid | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MarkDividendPositionAsPaid.sql*
