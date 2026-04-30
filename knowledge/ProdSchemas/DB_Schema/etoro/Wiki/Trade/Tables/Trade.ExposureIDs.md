# Trade.ExposureIDs

> Identity generator table that allocates unique ExposureIDs for hedge exposure query batches, used by GetCESQuery procedures to correlate exposure snapshots.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ExposureID (INT, CLUSTERED PK, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Trade.ExposureIDs is a single-column identity table that generates unique integer IDs for exposure-related operations. Each row represents one allocated ExposureID. The table has no business payload - it exists solely as an ID generator. Historically, position open/close procedures used MAX(ExposureID) to obtain OpenExposureID and CloseExposureID for correlation; as of December 2019 (per Pini's request), those procedures were changed to use 0 instead, and the MAX(ExposureID) logic was commented out.

The table still serves Trade.GetCESQuery and Hedge.GetCESQuery. Both procedures INSERT a row via `INSERT INTO Trade.ExposureIDs DEFAULT VALUES` and return SCOPE_IDENTITY() as the procedure's return value. This ExposureID correlates the exposure query run (CES = exposure data for hedge servers) with downstream consumers that need to reference which snapshot a result came from. Without this table, there would be no stable ID to correlate exposure batches across the hedge and trade systems.

Data flows: Rows are created by Trade.GetCESQuery and Hedge.GetCESQuery. Each call inserts one row and returns the new ExposureID. PositionOpen and PositionClose no longer read from this table (they use 0 for OpenExposureID and CloseExposureID). No UPDATE or DELETE logic was found; rows accumulate over time.

---

## 2. Business Logic

### 2.1 ExposureID Allocation Pattern

**What**: GetCESQuery procedures allocate a new ExposureID per invocation to correlate exposure query results.

**Columns/Parameters Involved**: `ExposureID`

**Rules**:
- INSERT INTO Trade.ExposureIDs DEFAULT VALUES (no column list - uses IDENTITY default)
- SCOPE_IDENTITY() returns the newly allocated ExposureID
- Procedure returns this value to the caller (RETURN (SCOPE_IDENTITY()))
- Each invocation of GetCESQuery allocates exactly one new row
- No reuse or gap-filling - IDs are strictly increasing

**Diagram**:
```
GetCESQuery(@ProviderID)
     |
     +-> SELECT exposure data FROM GetExposuresForAllHedgeServers
     |
     +-> INSERT INTO Trade.ExposureIDs DEFAULT VALUES
     |
     +-> RETURN (SCOPE_IDENTITY())
     |
     v
Caller receives ExposureID for this query run
```

### 2.2 Deprecated Use in Position Lifecycle

**What**: OpenExposureID and CloseExposureID were formerly sourced from this table; now hardcoded to 0.

**Columns/Parameters Involved**: N/A (deprecated)

**Rules**:
- Trade.PositionOpen (comment 17/12/2019): Changed from SELECT @OpenExposureID = MAX(ExposureID) FROM Trade.ExposureIDs to @OpenExposureID = 0
- Trade.PositionClose: SELECT @CloseExposureID = 0; the former MAX(ExposureID) logic is commented out
- No procedures currently read from this table - only GetCESQuery procedures write

---

## 3. Data Overview

| ExposureID | Meaning |
|------------|---------|
| 1 | First allocated ExposureID. Earliest exposure batch correlation from when the table was first used. |
| 100 | Example mid-range ID. Each integer represents one GetCESQuery invocation that inserted a row and returned this ID. |
| 500 | Later batch. IDs grow monotonically with no gaps (unless identity reseed occurred manually). |
| 1000 | Higher ID indicating many exposure query runs over time. |
| 1500 | Recent allocation. Used to correlate the exposure snapshot returned by that GetCESQuery call. |

**Selection criteria for the 5 rows:**
- Table has only one column (ExposureID); sample values illustrate the ID range
- Rows are indistinguishable except by ID value - no other attributes
- Actual row count and value range depend on how often GetCESQuery has been called since creation

**CRITICAL - Rules for the "Meaning" column:**
- Each row = one GetCESQuery (or Hedge.GetCESQuery) invocation that allocated this ID
- The ID correlates exposure query results with the batch that produced them
- Lower IDs = older runs; higher IDs = more recent

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExposureID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing ID allocated per INSERT. Used by Trade.GetCESQuery and Hedge.GetCESQuery as RETURN (SCOPE_IDENTITY()) to correlate exposure query batches. Historically used by PositionOpen/PositionClose for OpenExposureID/CloseExposureID; those now use 0. (Source: GetCESQuery, PositionOpen comment, PositionClose commented code) |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a leaf table with no FKs.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCESQuery | INSERT target, SCOPE_IDENTITY() | Writer | Inserts one row per invocation and returns ExposureID. Provides exposure data for ProviderID and allocates correlation ID. |
| Hedge.GetCESQuery | INSERT target, SCOPE_IDENTITY() | Writer | Same pattern as Trade.GetCESQuery; inserts and returns ExposureID for hedge exposure queries. |
| Trade.PositionOpen | (deprecated) | - | Comment documents former use of MAX(ExposureID); now uses 0. |
| Trade.PositionClose | (deprecated) | - | Commented-out MAX(ExposureID); now uses 0. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExposureIDs (table)
```

This object has no dependencies. It is a leaf table.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCESQuery | Procedure | INSERTs row, returns SCOPE_IDENTITY() |
| Hedge.GetCESQuery | Procedure | INSERTs row, returns SCOPE_IDENTITY() |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-------------------|--------|--------|
| PK_TradeExposureID | CLUSTERED | ExposureID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeExposureID | PRIMARY KEY | Enforces uniqueness on ExposureID; clustered for insert performance |

---

## 8. Sample Queries

### 8.1 Allocate a new ExposureID (mirrors GetCESQuery pattern)
```sql
INSERT INTO Trade.ExposureIDs DEFAULT VALUES;

SELECT SCOPE_IDENTITY() AS NewExposureID;
```

### 8.2 Inspect recent ExposureID allocations
```sql
SELECT TOP 10
    ExposureID
FROM Trade.ExposureIDs WITH (NOLOCK)
ORDER BY ExposureID DESC;
```

### 8.3 Count total allocated ExposureIDs
```sql
SELECT COUNT(*) AS TotalExposureIDs
FROM Trade.ExposureIDs WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| ExposureApiSevrice - HLD | Confluence | May relate to exposure API design; ExposureIDs table not explicitly documented. |
| InstrumentExposureToAvroService - HLD | Confluence | Instrument exposure service; tangential to ExposureIDs. |
| HLD: Unrealized Customer Service | Confluence | Unrealized customer service HLD; no direct ExposureIDs reference. |

No Confluence pages or Jira tickets explicitly document Trade.ExposureIDs. The table's purpose was inferred from procedure code (GetCESQuery, PositionOpen, PositionClose) and comments.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/12*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExposureIDs | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ExposureIDs.sql*
