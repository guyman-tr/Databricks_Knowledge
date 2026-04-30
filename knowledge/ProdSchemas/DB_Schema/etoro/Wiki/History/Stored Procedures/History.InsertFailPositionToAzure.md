# History.InsertFailPositionToAzure

> SQL Agent job procedure that batch-transfers failed position records from the local staging table (PositionFailWrite/PositionFailLocal) to Azure long-term storage (PositionFailInsert), then deletes transferred rows - implementing the async flush of the two-stage PositionFail persistence architecture.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Numrows - batch size for each transfer cycle |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.InsertFailPositionToAzure` is the async flush component of eToro's two-stage position failure persistence architecture. When a position fails (open, close, or any trade operation), it is immediately written to `History.PositionFailLocal` (via the `History.PositionFailWrite` synonym) as a fast local write. This procedure is then executed on a schedule by SQL Agent Job `[tradonomi - Transfer PositionFail to Azure]` to move those local records to the `PositionFailReal` database on Azure - the long-term, high-capacity store - and delete them from the local staging table.

The architecture separates concerns: the trading execution path writes fast to local SQL Server, and the async job handles the cross-database Azure transfer without blocking trades. The batch loop approach prevents large transactions and allows the job to be interrupted and resumed safely.

The procedure reads from `History.PositionFailWrite` (synonym -> `History.PositionFailLocal`) and writes to `History.PositionFailInsert` (synonym -> `[PositionFailRealAzure].[PositionFailReal].[History].[PositionFail]`). The PositionFail records stored on Azure are read back via the `History.PositionFail` synonym pointing to the Azure secondary replica.

---

## 2. Business Logic

### 2.1 Batch Loop Architecture

**What**: Processes records in configurable batches until all pending failures are transferred.

**Columns/Parameters Involved**: `@Numrows`, `@rc`

**Rules**:
- WHILE 1=1 loop continues until no rows are deleted (@rc = 0)
- Each cycle: TRUNCATE #Positionfail -> batch INSERT from PositionFailWrite -> INSERT to PositionFailInsert -> DELETE from PositionFailWrite
- @Numrows (default 100) controls the batch size - prevents large transactions and excessive locking
- @rc = @@ROWCOUNT after DELETE: when 0 rows deleted = no more records to transfer = BREAK
- Error handling: BEGIN CATCH prints ERROR_MESSAGE() but does NOT re-raise or break - the loop continues on error (potential for silent data issues if Azure insert fails but local delete proceeds)

**Diagram**:
```
History.PositionFailWrite (synonym -> PositionFailLocal)
        |
        v
WHILE rows remain:
  1. SELECT TOP @Numrows INTO #Positionfail
  2. INSERT INTO History.PositionFailInsert  <-- Azure primary write
  3. DELETE FROM History.PositionFailWrite   <-- Local cleanup
  4. IF @@ROWCOUNT = 0 BREAK
        |
        v
History.PositionFailInsert (synonym -> Azure PositionFailReal)
```

### 2.2 Temp Table Schema Construction

**What**: Uses a dummy `SELECT TOP 1 ... WHERE 1=0 INTO #Positionfail` pattern to create the temp table schema without reading actual data.

**Columns/Parameters Involved**: PositionFailID (cast to BIGINT), all 71 columns from PositionFailWrite

**Rules**:
- `WHERE 1=0` ensures no rows are inserted - only the DDL is materialized
- PositionFailID is explicitly cast to BIGINT (not the source column type) for the temp table
- The INSERT from PositionFailWrite uses all 71 columns by name (explicit column list)
- The INSERT to PositionFailInsert excludes PositionFailID (the Azure table generates its own IDENTITY)
- Comment "-- DELETE FROM London" is a historical artifact from when the source was a "London" database

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Numrows | INT | YES | 100 | VERIFIED | Batch size - number of records to transfer per loop iteration. Default 100 keeps transactions small. Increase for faster bulk transfer; decrease to reduce lock contention. Controls TOP clause in the batch SELECT from PositionFailWrite. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.PositionFailWrite | Reads + Deletes | SELECT TOP @Numrows for transfer batch; DELETE after successful Azure insert |
| (body) | History.PositionFailInsert | Writes (INSERT) | Azure primary write target; inserts the batch to long-term storage |

### 5.2 Referenced By (other objects point to this)

Executed by SQL Agent Job `[tradonomi - Transfer PositionFail to Azure]`. No SSDT callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InsertFailPositionToAzure (procedure)
├── History.PositionFailWrite (synonym -> History.PositionFailLocal)
│     └── History.PositionFailLocal (table - local staging)
└── History.PositionFailInsert (synonym -> PositionFailRealAzure.PositionFailReal.History.PositionFail)
      └── [PositionFailRealAzure].[PositionFailReal].[History].[PositionFail] (table - Azure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFailWrite | Synonym (-> PositionFailLocal) | SELECT source + DELETE target in batch loop |
| History.PositionFailInsert | Synonym (-> Azure PositionFailReal) | INSERT target - Azure long-term storage write |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Job: tradonomi - Transfer PositionFail to Azure | External | Scheduled caller - executes this procedure to flush local failures to Azure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Error handling**: BEGIN CATCH prints error message only (no RAISERROR/THROW, no BREAK) - the loop continues on error. This means a failed Azure INSERT will be silently swallowed and the loop continues to the next batch. If the DELETE after a failed INSERT succeeds, those records would be lost.

---

## 8. Sample Queries

### 8.1 Execute the Azure transfer job manually (default batch of 100)

```sql
EXEC History.InsertFailPositionToAzure
```

### 8.2 Execute with a larger batch size for faster bulk transfer

```sql
EXEC History.InsertFailPositionToAzure @Numrows = 500
```

### 8.3 Check how many records are pending transfer (still in local staging)

```sql
SELECT COUNT(*) AS PendingTransfer
FROM History.PositionFailWrite WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.InsertFailPositionToAzure | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.InsertFailPositionToAzure.sql*
