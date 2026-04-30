# Billing.GetFundingMigrations

> Loads the next batch of FundingTypeID=1 (credit card) fundings into Billing.FundingMigration for processing, with a backlog safety cap of 3,000 unprocessed records. Returns the inserted FundingIDs, or [0] if the backlog limit is exceeded.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @topRecords |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

The FundingMigration subsystem migrates FundingData for credit card fundings (FundingTypeID=1) by staging them in Billing.FundingMigration for external processing. This procedure is the "feeder" step: it populates the staging table with the next batch of unprocessed fundings, advancing sequentially through FundingIDs.

The cursor position is maintained implicitly: the procedure reads MAX(FundingID) from FundingMigration to know where the last batch ended, then inserts the next @topRecords fundings with higher FundingIDs. This means the migration always advances forward through the credit card funding population.

A backlog safety cap of 3,000 unprocessed records prevents the staging table from growing unbounded if the downstream processor falls behind. When the backlog exceeds 3,000, no new fundings are inserted and FundingID=0 is returned as a signal to the caller. The caller can detect this sentinel value and pause or alert.

Note: This uses `Billing.FundingMigration`, which is distinct from `Billing.FundingDataMigration` used by the GetFundingDataMigration* procedures (GetFundingDataMigrationExecutionID, GetFundingDataMigrationNextFundingID). These are two separate migration systems.

---

## 2. Business Logic

### 2.1 Sequential Cursor Advance

**What**: Determines the next FundingID range to insert by reading MAX(FundingID) from the staging table.

**Rules**:
- If FundingMigration is empty: `@LastFundingID = 0` (start from the beginning)
- If FundingMigration has records: `@LastFundingID = MAX(FundingID)` (continue from last batch)
- Insert condition: `FundingTypeID = 1 AND FundingID > @LastFundingID`
- Batch size: TOP(@topRecords), default 1000

### 2.2 Backlog Safety Cap

**What**: Prevents the staging table from accumulating more than 3,000 unprocessed records.

**Rules**:
- `@UnProcessedLimit = 3000`
- `@UnProcessed = COUNT(*) FROM FundingMigration WHERE IsProcessed = 0`
- If `@UnProcessedLimit >= @UnProcessed`: proceed with INSERT
- If `@UnProcessedLimit < @UnProcessed`: INSERT `VALUES(0)` into output table only (signal: backlog exceeded)
- The comment in the code explicitly states: "If FundingID = 0 this means that there are more than 3000 unprocessed fundings"

### 2.3 OUTPUT Clause Return

**What**: Returns the FundingIDs of records just inserted (or [0] if backlogged).

**Rules**:
- Uses `OUTPUT INSERTED.FundingID INTO @InsertedFundingIDs` to capture inserted IDs atomically
- Final SELECT returns all captured FundingIDs as a result set
- Caller uses these IDs to track which fundings were queued in this batch

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @topRecords | INT | YES | 1000 | CODE-BACKED | Maximum number of funding records to insert into Billing.FundingMigration per call. Default 1000. Controls batch size. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | FundingID of each record inserted into Billing.FundingMigration this call. Returns FundingID=0 as a sentinel value when the unprocessed backlog exceeds 3,000 records (no insertion performed). Multiple rows when batch inserted successfully. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID=1, FundingID | Billing.Funding | SELECT | Source of credit card fundings to be migrated |
| FundingID, IsProcessed | Billing.FundingMigration | INSERT + READ | Staging table for migration; read for cursor position and backlog count |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application migration service | @topRecords | EXEC | Called repeatedly to advance the credit card funding migration batch by batch |
| Billing.GetFundingMigration_Rollback | Billing.FundingMigration | Sibling | Rollback counterpart - resets IsProcessed=0 and restores FundingData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingMigrations (procedure)
├── Billing.Funding (table) [READ - credit card fundings source]
└── Billing.FundingMigration (table) [READ cursor + INSERT batches]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | SELECT TOP(@topRecords) FundingTypeID=1 WHERE FundingID > @LastFundingID |
| Billing.FundingMigration | Table | MAX(FundingID) for cursor; COUNT IsProcessed=0 for backlog check; INSERT new batch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application migration service | FundingID result set | EXEC - drives iterative batching of credit card funding migration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No explicit error handling.

---

## 8. Sample Queries

### 8.1 Load the next 1,000 credit card fundings into migration

```sql
EXEC Billing.GetFundingMigrations @topRecords = 1000;
-- Returns: inserted FundingIDs, or single row with FundingID=0 if backlog > 3000
```

### 8.2 Load a smaller batch for testing

```sql
EXEC Billing.GetFundingMigrations @topRecords = 100;
```

### 8.3 Check migration state before running

```sql
SELECT
    MAX(FundingID) AS LastMigratedFundingID,
    SUM(CASE WHEN IsProcessed = 0 THEN 1 ELSE 0 END) AS UnprocessedBacklog,
    COUNT(*) AS TotalQueued
FROM Billing.FundingMigration WITH (NOLOCK);
-- If UnprocessedBacklog >= 3000, GetFundingMigrations will return 0 without inserting
```

### 8.4 Check how many credit card fundings remain to be migrated

```sql
SELECT COUNT(*) AS RemainingCreditCardFundings
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingTypeID = 1
  AND FundingID > (SELECT ISNULL(MAX(FundingID), 0) FROM Billing.FundingMigration WITH (NOLOCK));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingMigrations | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingMigrations.sql*
