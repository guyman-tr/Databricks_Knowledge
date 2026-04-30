# Price.DeleteOMPDThresholdByInstrumentID

> Transactional DELETE procedure that removes all OMPD threshold configuration for a given instrument - atomically deletes from both Price.OMPDActiveThreshold (the active selector) and Price.OMPDThresholdValues (both Pips and Percentage value rows).

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID (identifies the instrument to fully remove from OMPD) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.DeleteOMPDThresholdByInstrumentID fully removes an instrument from the OMPD (Order Management Price Deviation) protection system. It deletes both the active threshold designation (OMPDActiveThreshold) and all stored threshold values (OMPDThresholdValues - both Pips and Percentage rows if both exist).

OMPD is the price deviation protection mechanism that rejects orders when the market price has moved beyond a configured threshold. Deleting all OMPD configuration for an instrument means that instrument will no longer have order-level price protection applied - useful when decommissioning an instrument or during OMPD system maintenance.

The procedure uses an explicit transaction to guarantee atomicity: either both tables are cleared for the instrument or neither is (rolled back on error). The RETURN code (0=success rows deleted, 1=no records found) allows callers to distinguish between a successful removal and a silent no-op.

---

## 2. Business Logic

### 2.1 Atomic Two-Table Delete in Transaction

**What**: Both DELETEs execute inside a single explicit transaction to ensure the OMPDActiveThreshold and OMPDThresholdValues tables remain coherent - no partial state where active type exists without values or vice versa.

**Columns/Parameters Involved**: `@InstrumentID`, `@DeletedFromActiveThreshold`, `@DeletedFromThresholdValues`

**Rules**:
- BEGIN TRANSACTION wraps both DELETE statements
- DELETE Price.OMPDActiveThreshold WHERE InstrumentID = @InstrumentID: removes the active type selector (0 or 1 rows)
- DELETE Price.OMPDThresholdValues WHERE InstrumentID = @InstrumentID: removes all value rows for the instrument (0, 1, or 2 rows - one per ThresholdType)
- @@ROWCOUNT captured after each DELETE into @DeletedFromActiveThreshold and @DeletedFromThresholdValues
- COMMIT on success; ROLLBACK + THROW on any exception via TRY/CATCH
- After COMMIT: RETURN 1 if both counts are 0 (no data existed); RETURN 0 if any rows were deleted (success)

**State transitions**:
```
Before:
  OMPDActiveThreshold:  [InstrumentID=X, ThresholdType=1]
  OMPDThresholdValues:  [InstrumentID=X, ThresholdType=1, Value=40]
                        [InstrumentID=X, ThresholdType=2, Value=50]

After EXEC DeleteOMPDThresholdByInstrumentID @InstrumentID=X:
  OMPDActiveThreshold:  (no rows for X)
  OMPDThresholdValues:  (no rows for X)
  -> RETURN 0 (success, rows were deleted)
```

### 2.2 RETURN Code Semantics

**What**: RETURN code distinguishes success (rows deleted) from no-op (nothing found).

**Columns/Parameters Involved**: `@DeletedFromActiveThreshold`, `@DeletedFromThresholdValues`

**Rules**:
- RETURN 0: At least one row was deleted from either table. Standard success code.
- RETURN 1: Both @@ROWCOUNT captures were 0 - instrument had no OMPD configuration. Caller can treat as "instrument not found in OMPD" without this being an error condition.
- Note: RETURN values must be captured via EXEC @ReturnCode = Price.DeleteOMPDThresholdByInstrumentID ... - a plain EXEC does not expose the return code

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | IN | - | CODE-BACKED | The instrument whose complete OMPD configuration should be removed. Deletes all rows in OMPDActiveThreshold and OMPDThresholdValues where InstrumentID matches. No pre-validation - if the instrument has no OMPD rows, RETURN 1 is returned without error. |

**Return values (via RETURN statement):**

| Value | Meaning |
|-------|---------|
| 0 | Success - one or more rows were deleted from OMPDActiveThreshold and/or OMPDThresholdValues |
| 1 | No records found - both DELETE statements affected 0 rows; the instrument had no OMPD configuration |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Price.OMPDActiveThreshold | DELETE target | Removes the active threshold type selector for this instrument |
| @InstrumentID | Price.OMPDThresholdValues | DELETE target | Removes all threshold value rows (Pips and Percentage) for this instrument |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no SQL callers found within the Price schema (called by external pricing management API).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.DeleteOMPDThresholdByInstrumentID (procedure)
├── Price.OMPDActiveThreshold (table) - DELETE target
└── Price.OMPDThresholdValues (table) - DELETE target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.OMPDActiveThreshold | Table | DELETE target - removes active threshold type selector |
| Price.OMPDThresholdValues | Table | DELETE target - removes all threshold value rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found in Price schema | - | Called by external pricing management API |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Explicit BEGIN TRANSACTION / COMMIT / ROLLBACK. TRY/CATCH with THROW (re-raises the caught error without modifying it). No RAISERROR for the "not found" case - uses RETURN 1 instead. The DDL file ends with `print 'Price.GetActiveOMPDThresholdByInstrumentIds.sql'` - deployment script artifact, not procedure logic.

---

## 8. Sample Queries

### 8.1 Delete all OMPD configuration for an instrument

```sql
DECLARE @ReturnCode INT;
EXEC @ReturnCode = Price.DeleteOMPDThresholdByInstrumentID @InstrumentID = 1;
SELECT CASE @ReturnCode
    WHEN 0 THEN 'Deleted successfully'
    WHEN 1 THEN 'No OMPD configuration found for this instrument'
END AS Result;
```

### 8.2 Verify complete removal

```sql
-- Should return 0 rows for both after successful delete
SELECT 'ActiveThreshold' AS Source, COUNT(*) AS Rows
FROM Price.OMPDActiveThreshold WITH (NOLOCK) WHERE InstrumentID = 1
UNION ALL
SELECT 'ThresholdValues', COUNT(*)
FROM Price.OMPDThresholdValues WITH (NOLOCK) WHERE InstrumentID = 1;
```

### 8.3 Bulk cleanup - delete OMPD for instruments no longer in InstrumentMetaData

```sql
-- Identify orphaned OMPD records (instruments no longer in metadata)
SELECT DISTINCT AT.InstrumentID
FROM Price.OMPDActiveThreshold AT WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Trade.InstrumentMetaData WITH (NOLOCK) WHERE InstrumentID = AT.InstrumentID
);
-- Then call Price.DeleteOMPDThresholdByInstrumentID for each
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.DeleteOMPDThresholdByInstrumentID | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.DeleteOMPDThresholdByInstrumentID.sql*
