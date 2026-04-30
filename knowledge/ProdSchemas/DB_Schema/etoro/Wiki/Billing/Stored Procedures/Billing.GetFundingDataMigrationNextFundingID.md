# Billing.GetFundingDataMigrationNextFundingID

> Returns the next FundingID to process in a migration execution batch - computed as MAX(FundingID) + 1 within the given ExecutionID, enabling sequential pagination through the FundingDataMigration table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExecutionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

The funding data migration process works sequentially through FundingIDs within an ExecutionID. After each batch of fundings is inserted into Billing.FundingDataMigration (by GetFundingMigrations), the migration service needs to know the starting point for the NEXT batch. This procedure provides that next starting FundingID.

By computing MAX(FundingID) + 1 for the given ExecutionID, the migration service can determine the lowest unprocessed FundingID in the next batch window. If no records exist yet for the ExecutionID, COALESCE converts NULL to 0, and 0+1=1 (start from the beginning).

This cursor-based pagination avoids loading all FundingIDs into memory and allows the migration to be interrupted and resumed (the ExecutionID tracks which batch is current).

---

## 2. Business Logic

### 2.1 Cursor-Based Migration Pagination

**What**: Computes the starting FundingID for the next migration batch.

**Columns/Parameters Involved**: `@ExecutionID`, `FundingID`

**Rules**:
- `COALESCE(max(FundingID), 0) + 1` - if no records exist for ExecutionID, returns 1 (start of migration)
- If the last processed FundingID in this execution was 50000, returns 50001 (next batch starts from 50001)
- GetFundingMigrations uses this value to set `FundingID > @LastFundingID` in its WHERE clause
- The migration only inserts FundingTypeID=1 (credit card) fundings - so FundingIDs are not globally sequential

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionID | INTEGER | NO | - | CODE-BACKED | The migration execution batch identifier. Scopes the MAX(FundingID) query to the current migration run only. Obtained from GetFundingDataMigrationExecutionID. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | The next FundingID to start processing. MAX(FundingID) + 1 from Billing.FundingDataMigration for the given ExecutionID. Returns 1 if no records exist yet for this ExecutionID (COALESCE(MAX, 0) + 1). Used by GetFundingMigrations as the lower bound for the next batch query. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionID | Billing.FundingDataMigration | Lookup | Reads MAX(FundingID) to compute next page start |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application migration service | FundingID (as @LastFundingID) | EXEC | Called before each batch to get the next pagination cursor |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingDataMigrationNextFundingID (procedure)
└── Billing.FundingDataMigration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingDataMigration | Table | SELECT COALESCE(MAX(FundingID), 0) + 1 WHERE ExecutionID = @ExecutionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application migration service | FundingID | EXEC - pagination cursor for GetFundingMigrations batches |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get the next FundingID for migration

```sql
EXEC Billing.GetFundingDataMigrationNextFundingID @ExecutionID = 1;
-- Returns the next FundingID to load in the migration batch
```

### 8.2 Check migration progress within an execution

```sql
SELECT MIN(FundingID) AS FirstFunding, MAX(FundingID) AS LastFunding,
       COUNT(*) AS TotalRecords, SUM(CAST(IsProcessed AS INT)) AS Processed
FROM Billing.FundingDataMigration WITH (NOLOCK)
WHERE ExecutionID = 1;
```

### 8.3 Typical migration pagination loop (conceptual)

```sql
-- 1. Get current execution
EXEC Billing.GetFundingDataMigrationExecutionID; -- returns @ExecutionID

-- 2. Get next starting FundingID
EXEC Billing.GetFundingDataMigrationNextFundingID @ExecutionID = @ExecutionID;
-- Returns @NextFundingID

-- 3. Load next batch (GetFundingMigrations uses @LastFundingID internally)
EXEC Billing.GetFundingMigrations @topRecords = 1000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingDataMigrationNextFundingID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingDataMigrationNextFundingID.sql*
