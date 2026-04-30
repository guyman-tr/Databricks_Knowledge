# Billing.FundingDataMigration

> Migration tracking table for credit card funding data tokenization - records per-funding-record migration status, exceptions, BIN data, and secured card tokens during bulk migration operations. Currently empty (migration complete).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | FundingDataMigrationID (IDENTITY), clustered on FundingID |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR 95) |
| **Indexes** | 2 (clustered on FundingID + NC on MigrationStatus) |

---

## 1. Business Meaning

`Billing.FundingDataMigration` is an operational tracking table that supported batch migration of credit card funding records to a tokenized/secured card format. Each row represents one attempt to migrate a specific `Billing.Funding` record, capturing the migration status (success, failure, etc.), any exception message if it failed, the batch execution context, and the resulting secured card data and BIN information.

The table is currently empty (0 rows) - the migration has been completed and cleaned up via `Billing.FundingDataMigrationCleanData`. The infrastructure remains in place, suggesting the migration pattern may be reused for future card data migrations.

The clustered index is on `FundingID` (not the IDENTITY PK), enabling fast lookups of all migration attempts for a given funding record. The NC index on `MigrationStatus` supports batch processing queries that filter by status (e.g., "get all failed migrations for retry"). The `Billing.FundingMigrationStatus` user-defined type (documented separately) is used as the TVP parameter for bulk inserts via `AddFundingDataMigration`.

---

## 2. Business Logic

### 2.1 Batch Migration Pattern

**What**: Migration runs in batches tracked by ExecutionID, processing FundingIDs sequentially.

**Columns/Parameters Involved**: `FundingID`, `ExecutionID`, `MigrationStatus`, `Exception`, `Version`

**Rules**:
- `AddFundingDataMigration(@NewMigrationDataTbl)` bulk-inserts migration results from a `Billing.FundingMigrationStatus` TVP.
- `GetFundingDataMigrationNextFundingID(@ExecutionID)` returns `MAX(FundingID) + 1` for a given execution batch - used for cursor-style batch progression.
- `GetFundingDataMigrationExecutionID` provides the current execution batch ID.
- `GetCreditCardFundingBulkFirstTime` retrieves the initial set of FundingIDs to migrate.
- `UpdateSecuredCard` updates the resulting secured token back into the funding records.
- `FundingDataMigrationCleanData` purges the migration log after successful completion.

### 2.2 Card Tokenization Context

**What**: The migration captures BIN and secured card data during the transition from raw card data to tokenized storage.

**Columns/Parameters Involved**: `SecuredCardData`, `BinCode`, `BinCountry`

**Rules**:
- `SecuredCardData`: the new tokenized card representation (up to 100 chars).
- `BinCode`: first 6 digits of the card number (Bank Identification Number), varchar(6).
- `BinCountry`: country code of the card issuer's bank, resolved from the BIN.
- These fields capture the card security data during migration - enabling `UpdateSecuredCard` to write the tokenized data back to the source funding records.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 0 (empty - migration complete) |
| Migration status | All data cleaned via FundingDataMigrationCleanData |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingDataMigrationID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate auto-increment key. Not the clustered index (FundingID is clustered). Allows duplicate FundingIDs (for retry attempts). |
| 2 | FundingID | int | NO | - | CODE-BACKED | The Billing.Funding record being migrated. Implicit FK to Billing.Funding.FundingID. Clustered index key - fast lookup of all migration attempts for a funding record. Multiple rows per FundingID possible (retry attempts). |
| 3 | MigrationStatus | int | YES | - | CODE-BACKED | Status of the migration attempt for this FundingID. Lookup table not found in SSDT repo (likely an inline enum). NC indexed for batch processing queries (find all failed/pending records). Values not determinable from empty table. |
| 4 | Exception | varchar(max) | YES | - | CODE-BACKED | Exception or error message captured if migration failed. NULL on success. varchar(max) to accommodate full stack traces. TEXTIMAGE_ON PRIMARY - stored off-row if large. |
| 5 | ExecutionID | int | YES | - | CODE-BACKED | Batch execution identifier grouping related migration rows. Used by GetFundingDataMigrationNextFundingID to determine the next FundingID to process in a batch. Enables parallel or sequential batch processing with isolation between runs. |
| 6 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when this migration attempt occurred. NULL-allowed but would typically be populated at insert time. |
| 7 | Version | varchar(50) | YES | - | CODE-BACKED | Migration script or process version that created this record. Enables tracking which version of the migration logic processed each funding record. |
| 8 | FundingDataUpdateDate | datetime | YES | - | CODE-BACKED | Date when the source funding data was last updated (captured at migration time for audit purposes). May represent the ModificationDate from Billing.Funding at migration time. |
| 9 | SecuredCardData | varchar(100) | YES | - | CODE-BACKED | Tokenized/secured representation of the card data after migration. Written by the migration process, then used by UpdateSecuredCard to push the token back to the source funding record. |
| 10 | BinCode | varchar(6) | YES | - | CODE-BACKED | First 6 digits of the card number (Bank Identification Number) extracted during migration. Enables routing and compliance checks without storing full card data. |
| 11 | BinCountry | int | YES | - | CODE-BACKED | Country code of the card issuer's bank, resolved from the BIN during migration. Implicit FK to Dictionary.Country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID | Billing.Funding | Implicit FK | The funding record being migrated. |
| BinCountry | Dictionary.Country | Implicit FK | Country of the card BIN. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AddFundingDataMigration | FundingID, MigrationStatus, etc. | WRITER | Bulk-inserts migration results via TVP. Primary write path. |
| Billing.GetFundingDataMigrationNextFundingID | FundingID, ExecutionID | READER | Returns next FundingID to process in a batch. |
| Billing.GetFundingDataMigrationExecutionID | ExecutionID | READER | Returns current execution batch ID. |
| Billing.GetCreditCardFundingBulkFirstTime | FundingID | READER | Retrieves initial set of FundingIDs for migration. |
| Billing.UpdateSecuredCard | SecuredCardData, FundingID | READER | Reads secured card data to write back to source funding records. |
| Billing.FundingDataMigrationCleanData | (all rows) | DELETER | Purges migration log after completion. |

---

## 6. Dependencies

### 6.0 Dependency Chain

Billing.Funding -> Billing.FundingDataMigration (implicit, FundingID reference)

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | FundingID source - records being migrated |
| Billing.FundingMigrationStatus | User Defined Type | TVP type used for bulk inserts via AddFundingDataMigration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AddFundingDataMigration | Stored Procedure | WRITER - bulk inserts migration records |
| Billing.GetFundingDataMigrationNextFundingID | Stored Procedure | READER - batch cursor logic |
| Billing.GetFundingDataMigrationExecutionID | Stored Procedure | READER - execution ID management |
| Billing.GetCreditCardFundingBulkFirstTime | Stored Procedure | READER - initial funding set selection |
| Billing.UpdateSecuredCard | Stored Procedure | READER/UPDATER - applies secured tokens to source records |
| Billing.FundingDataMigrationCleanData | Stored Procedure | DELETER - cleanup after migration completion |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IDX_FundingDataMigration_FundingID | CLUSTERED | FundingID ASC | - | - | Active |
| IDX_FundingDataMigration_MigrationStatus | NONCLUSTERED | MigrationStatus ASC | - | - | Active |

Note: Clustered index is on FundingID (not the IDENTITY key FundingDataMigrationID). This is intentional - the primary access pattern is by FundingID. TEXTIMAGE_ON PRIMARY for varchar(max) columns.

### 7.2 Constraints

None (no PK, no FK, no DEFAULT, no CHECK). FundingDataMigrationID is IDENTITY but has no PK constraint declared.

---

## 8. Sample Queries

### 8.1 Check migration progress by status

```sql
SELECT MigrationStatus, COUNT(*) AS Count
FROM [Billing].[FundingDataMigration] WITH (NOLOCK)
GROUP BY MigrationStatus
ORDER BY Count DESC;
```

### 8.2 Find failed migrations for retry

```sql
SELECT FundingID, ExecutionID, Exception, Occurred, Version
FROM [Billing].[FundingDataMigration] WITH (NOLOCK)
WHERE MigrationStatus = 2  -- assuming 2 = Failed (verify against actual values)
ORDER BY FundingID;
```

### 8.3 Get migration summary for a specific execution

```sql
SELECT ExecutionID, MigrationStatus, COUNT(*) AS Count,
    MIN(Occurred) AS Started, MAX(Occurred) AS LastActivity
FROM [Billing].[FundingDataMigration] WITH (NOLOCK)
WHERE ExecutionID = @ExecutionID
GROUP BY ExecutionID, MigrationStatus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (6 total) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingDataMigration | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FundingDataMigration.sql*
