# History.MirrorCloseSagaExists

> Boolean existence check for completed mirror close sagas - returns a single row if a fully-closed saga (SagaCloseReason=0) exists for the given MirrorID + CID combination in History.MirrorCloseSaga.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID + @CID - the copy relationship to check for completed close saga |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.MirrorCloseSagaExists` is a lightweight boolean existence check used to determine whether a mirror (copy-trading relationship) has a completed close saga recorded in the history archive. When the MSL or copy-stop engine wants to verify that a specific mirror relationship was fully and cleanly closed (not just partially processed), it calls this procedure. A non-empty result means "yes, this mirror was completely closed and the saga is archived."

The procedure queries `History.MirrorCloseSaga` - the completed-saga archive populated when `Trade.ArchiveMirrorCloseSaga` moves finished saga records from `Trade.MirrorCloseSaga`. It specifically filters for `SagaCloseReason=0`, which means the mirror relationship was confirmed to no longer exist in `Trade.Mirror` at the time of archival - the copy relationship was fully dissolved.

The `ISNULL(SagaCloseReason, 1) = 0` pattern means: return rows only where SagaCloseReason is explicitly 0 (treating NULL as 1, which does NOT match). Only rows with a confirmed full close (SagaCloseReason=0) are returned.

---

## 2. Business Logic

### 2.1 Completed Close Saga Detection

**What**: Checks whether a fully-completed (SagaCloseReason=0) close saga exists for the given mirror + customer combination.

**Columns/Parameters Involved**: `@MirrorID`, `@CID`, `History.MirrorCloseSaga.SagaCloseReason`

**Rules**:
- Filters: WHERE MirrorID = @MirrorID AND CID = @CID AND ISNULL(SagaCloseReason, 1) = 0
- ISNULL(SagaCloseReason, 1) = 0 resolves as:
  - SagaCloseReason = 0 -> condition TRUE (row returned) - mirror was fully removed from Trade.Mirror at close time
  - SagaCloseReason = NULL -> ISNULL returns 1, so 1=0 is FALSE (row not returned) - NULL means saga reason not set
  - SagaCloseReason = 1 -> 1=0 is FALSE (row not returned) - mirror still existed in Trade.Mirror at archival time (partial close)
- Returns: SELECT TOP(1) 1 - a single-column, single-row result set with value 1, or empty if no match
- The caller checks: if rows returned -> saga exists (mirror fully closed); if no rows -> saga does not exist
- SET NOCOUNT ON - suppresses row count messages
- No transaction wrapper - pure read operation

**Diagram**:
```
Caller checks: "Was MirrorID=X fully closed for CID=Y?"
        |
        v
History.MirrorCloseSagaExists(@MirrorID=X, @CID=Y)
        |
        v
SELECT TOP 1 FROM History.MirrorCloseSaga
WHERE MirrorID=X AND CID=Y AND ISNULL(SagaCloseReason,1)=0
        |
  Returns 1 row -> YES: mirror fully closed (SagaCloseReason=0 row exists)
        |
  Returns 0 rows -> NO: no completed full-close saga found for this mirror
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The copy-trading mirror relationship to check. Combined with @CID to identify a specific copier-guru pair in History.MirrorCloseSaga. History.MirrorCloseSaga has a CLUSTERED index on MirrorID making this lookup efficient. |
| 2 | @CID | INT | NO | - | CODE-BACKED | The copier customer ID. Combined with @MirrorID to uniquely identify the saga record. Required because multiple saga records can exist for the same MirrorID (if a mirror was stopped and restarted multiple times). |

**Output columns** (SELECT TOP 1 result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (unnamed) | INT | NO | - | CODE-BACKED | Literal value 1. The caller uses the presence or absence of this row as a boolean signal. Returns 1 if a fully-closed saga (SagaCloseReason=0) exists for the given MirrorID + CID. Returns no rows if not found or if only partial-close sagas exist (SagaCloseReason=1 or NULL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.MirrorCloseSaga | Reads | SELECT TOP 1 to check existence of a fully-closed saga (SagaCloseReason=0) for the given MirrorID+CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Mirror close/MSL engine application | - | Caller | Called to verify that a mirror close saga has been fully archived; no callers found in SSDT repository |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MirrorCloseSagaExists (procedure)
+-- History.MirrorCloseSaga (table - completed close saga archive)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.MirrorCloseSaga | Table | SELECT TOP 1 existence check filtered by MirrorID, CID, SagaCloseReason=0 |

### 6.2 Objects That Depend On This

No callers found in the etoro SSDT repository. Called by the mirror close / MSL engine application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- SET NOCOUNT ON applied
- No error handling (no TRY/CATCH, no @@ERROR check) - pure read; failure propagates to caller
- No NOLOCK hint on the SELECT - consistent read on History.MirrorCloseSaga
- `ISNULL(SagaCloseReason, 1) = 0` is a non-SARGable expression on SagaCloseReason - may prevent index seeks on that column; the CLUSTERED index on MirrorID and the WHERE clause filters on MirrorID + CID first which limits the scan
- Returns a result set with one row containing literal 1, not an OUTPUT parameter or RETURN code

---

## 8. Sample Queries

### 8.1 Check if a completed close saga exists for a mirror

```sql
-- Procedure returns 1 row if saga exists, 0 rows if not
EXEC History.MirrorCloseSagaExists
    @MirrorID = 1890557,
    @CID      = 25399609
```

### 8.2 Direct query equivalent (without calling the procedure)

```sql
SELECT TOP 1 1 AS SagaExists
FROM History.MirrorCloseSaga WITH (NOLOCK)
WHERE MirrorID = 1890557
  AND CID = 25399609
  AND ISNULL(SagaCloseReason, 1) = 0
```

### 8.3 View all close sagas for a mirror including their close reasons

```sql
SELECT
    ID,
    MirrorID,
    CID,
    SagaCloseReason,
    LastStepIndex,
    CreateDate,
    CloseDate,
    MirrorCloseActionType
FROM History.MirrorCloseSaga WITH (NOLOCK)
WHERE MirrorID = 1890557
ORDER BY CloseDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.MirrorCloseSagaExists | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.MirrorCloseSagaExists.sql*
