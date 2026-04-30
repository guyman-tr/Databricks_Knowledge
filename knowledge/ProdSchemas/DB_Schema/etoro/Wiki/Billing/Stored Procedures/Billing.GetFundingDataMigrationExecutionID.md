# Billing.GetFundingDataMigrationExecutionID

> Returns the maximum ExecutionID from the FundingDataMigration tracking table, or 0 if no migration has been started, used to identify the current migration execution batch.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

The Billing.FundingDataMigration table tracks the progress of a data migration process that transforms or normalizes funding data (specifically FundingTypeID=1 credit card fundings). Each migration run is grouped under an ExecutionID. This procedure provides the current (most recent) ExecutionID so the calling process knows which batch it is working within, or knows to start a new batch if no migration has been run yet (returns 0).

The ExecutionID is used in conjunction with GetFundingDataMigrationNextFundingID to paginate through fundings in a migration run: the caller gets the ExecutionID first, then retrieves the next FundingID to process within that execution.

---

## 2. Business Logic

### 2.1 Current Execution Identification

**What**: Returns the highest (most recent) ExecutionID, defaulting to 0 if no migration records exist.

**Rules**:
- `COALESCE(max(ExecutionID), 0)` - if the table is empty, MAX returns NULL; COALESCE converts to 0
- Callers use 0 to detect "no migration started" and initialize accordingly
- ExecutionID is monotonically increasing; MAX gives the latest active or completed batch ID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*(No input parameters)*

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | ExecutionID | INT | NO | - | CODE-BACKED | Maximum ExecutionID from Billing.FundingDataMigration. Returns 0 if no migration records exist (via COALESCE). Identifies the current migration batch for use with GetFundingDataMigrationNextFundingID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionID | Billing.FundingDataMigration | Lookup | Reads MAX(ExecutionID) to identify current migration batch |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| GetFundingMigrations / migration orchestration service | ExecutionID | EXEC | Called at start of migration run to identify the current batch |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingDataMigrationExecutionID (procedure)
└── Billing.FundingDataMigration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingDataMigration | Table | SELECT COALESCE(max(ExecutionID), 0) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application migration service | ExecutionID | EXEC - called to get current batch ID before paginating migration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get the current migration execution ID

```sql
EXEC Billing.GetFundingDataMigrationExecutionID;
-- Returns 0 if no migration started, or the latest ExecutionID
```

### 8.2 Check the migration table status

```sql
SELECT ExecutionID, COUNT(*) AS RecordCount, SUM(CAST(IsProcessed AS INT)) AS ProcessedCount
FROM Billing.FundingDataMigration WITH (NOLOCK)
GROUP BY ExecutionID
ORDER BY ExecutionID DESC;
```

### 8.3 Verify no unprocessed records remain in current execution

```sql
SELECT COUNT(*) AS UnprocessedCount
FROM Billing.FundingDataMigration WITH (NOLOCK)
WHERE ExecutionID = (SELECT COALESCE(MAX(ExecutionID), 0) FROM Billing.FundingDataMigration WITH (NOLOCK))
  AND IsProcessed = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingDataMigrationExecutionID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingDataMigrationExecutionID.sql*
