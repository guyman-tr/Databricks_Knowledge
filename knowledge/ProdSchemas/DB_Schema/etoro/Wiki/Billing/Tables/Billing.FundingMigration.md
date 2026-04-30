# Billing.FundingMigration

> Credit card funding migration queue - stores XML snapshots of Billing.Funding records (CreditCard type) staged for migration processing, tracking processing status per funding record. Created in one day (December 24, 2023).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | FundingID (PK clustered) |
| **Partition** | No (MAIN filegroup, FILLFACTOR 100, PAGE compression) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Billing.FundingMigration` is a migration staging table that queues `Billing.Funding` records (specifically CreditCard, FundingTypeID=1) for batch migration processing. Each row stores a complete XML snapshot of the funding record at the time it was staged, along with a processing status flag.

All 43,740 rows were created on December 24, 2023, indicating a single-day migration event. Of these, 43,538 (99.5%) have been marked as processed. 202 records remain with `IsProcessed=0`, either representing genuinely unprocessable records or records that were never reached by the migration process.

The migration pattern: `GetFundingMigrations` reads CreditCard funding records from `Billing.Funding` in batches of up to 1,000 (ordered by FundingID), inserts XML snapshots here, and returns the inserted FundingIDs to the calling migration process. The migration process then transforms/migrates the data and calls `FundingMigrationUpdateIsProcessed` to mark them done. A backpressure mechanism limits to 3,000 unprocessed records at any time. The rollback procedure (`GetFundingMigration_Rollback`) supports recovery from failed migration runs.

PAGE compression is applied to reduce storage for the large XML columns. TEXTIMAGE_ON PRIMARY routes the XML data to the PRIMARY filegroup even though the base table is on MAIN.

---

## 2. Business Logic

### 2.1 Migration Queue (Batch Load and Process)

**What**: Records are batch-inserted from Billing.Funding and marked processed as the migration completes.

**Columns/Parameters Involved**: `FundingID`, `FundingData`, `IsProcessed`, `Created`

**Rules**:
- `GetFundingMigrations(@topRecords=1000)` performs the batch load:
  1. Checks if unprocessed count < 3,000 (backpressure limit). If >= 3,000, returns FundingID=0 (signal to caller to wait).
  2. Finds MAX(FundingID) in this table as the cursor position.
  3. INSERT TOP(1000) from `Billing.Funding WHERE FundingTypeID=1 AND FundingID > @LastFundingID`.
  4. Returns inserted FundingIDs to the caller.
- `FundingMigrationUpdateIsProcessed` marks records as `IsProcessed=1` after migration.
- `GetFundingMigration_Rollback` handles failed migration (resets or removes staging records).
- Deduplication: FundingID is the PK - each funding record can appear at most once in the queue.

### 2.2 XML Snapshot Pattern

**What**: FundingData stores the complete funding record XML at staging time.

**Rules**:
- `FundingData` is populated directly from `Billing.Funding.FundingData` (the XML funding configuration).
- The snapshot is taken at INSERT time, providing a point-in-time copy that the migration process reads even if the source record changes.
- FundingTypeID=1 (CreditCard) records only - wire transfers, PayPal, etc. are not in this migration.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 43,740 |
| IsProcessed = 1 (done) | 43,538 (99.5%) |
| IsProcessed = 0 (pending/stuck) | 202 (0.5%) |
| Created date range | 2023-12-24 only |
| Coverage | CreditCard (FundingTypeID=1) funding records |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Primary key. The Billing.Funding record being migrated. Implicit FK to Billing.Funding.FundingID. One row per funding record (PK prevents duplicates). The migration batch cursor: GetFundingMigrations uses MAX(FundingID) as the watermark for the next batch. |
| 2 | FundingData | xml | NO | - | CODE-BACKED | XML snapshot of Billing.Funding.FundingData at staging time. Contains the complete funding configuration for this credit card record. Stored in TEXTIMAGE_ON PRIMARY filegroup. The migration process reads and transforms this XML. |
| 3 | IsProcessed | int | NO | 0 | CODE-BACKED | Processing status flag. DEFAULT 0 (unprocessed/pending). Set to 1 by FundingMigrationUpdateIsProcessed after successful migration. Acts as a simple boolean despite being int. Backpressure check: if COUNT(*) WHERE IsProcessed=0 >= 3,000, GetFundingMigrations returns 0 (signal to pause loading). |
| 4 | Created | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when the staging record was created. DEFAULT getutcdate() - auto-populated on insert. All rows show 2023-12-24, confirming a single-day migration event. Note: the DEFAULT constraint for this column has no explicit name (unnamed default). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID | Billing.Funding | Implicit FK | The credit card funding record being migrated. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetFundingMigrations | FundingID, FundingData | WRITER + READER | Batch-inserts new staging records and returns IDs for migration. |
| Billing.FundingMigrationUpdateIsProcessed | FundingID, IsProcessed | UPDATER | Marks records as processed after migration completes. |
| Billing.GetFundingMigration_Rollback | FundingID | READER/UPDATER | Rollback procedure for failed migration recovery. |

---

## 6. Dependencies

### 6.0 Dependency Chain

Billing.Funding -> Billing.FundingMigration (FundingID reference)

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Source of FundingID and FundingData at migration staging time |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetFundingMigrations | Stored Procedure | WRITER/READER - batch loads staging records |
| Billing.FundingMigrationUpdateIsProcessed | Stored Procedure | UPDATER - marks records processed |
| Billing.GetFundingMigration_Rollback | Stored Procedure | READER/UPDATER - migration rollback |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | FundingID ASC | - | - | Active |

MAIN filegroup. FILLFACTOR=100 (no page splitting expected - migration table grows sequentially then stops). PAGE compression on both index and table definition.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed PK) | PRIMARY KEY | FundingID - one staging record per funding record |
| DF_FundingMigration_IsProcessed | DEFAULT | 0 - new records start as unprocessed |
| (unnamed DEFAULT) | DEFAULT | getutcdate() - auto-stamp creation time |

---

## 8. Sample Queries

### 8.1 Check migration progress

```sql
SELECT IsProcessed,
    COUNT(*) AS Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS decimal(5,1)) AS Pct
FROM [Billing].[FundingMigration] WITH (NOLOCK)
GROUP BY IsProcessed;
```

### 8.2 View unprocessed records

```sql
SELECT TOP 20 FundingID, IsProcessed, Created
FROM [Billing].[FundingMigration] WITH (NOLOCK)
WHERE IsProcessed = 0
ORDER BY FundingID;
```

### 8.3 Check migration watermark (last processed FundingID)

```sql
SELECT MAX(FundingID) AS LastStagedFundingID,
    MAX(CASE WHEN IsProcessed = 1 THEN FundingID END) AS LastProcessedFundingID
FROM [Billing].[FundingMigration] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingMigration | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FundingMigration.sql*
