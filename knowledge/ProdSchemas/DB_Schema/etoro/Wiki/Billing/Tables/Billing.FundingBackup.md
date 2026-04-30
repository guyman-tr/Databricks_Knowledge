# Billing.FundingBackup

> Pre-migration snapshot of Billing.Funding records (FundingTypeID=1 / credit cards only) taken before a data migration that updated SecuredCardData into the FundingData XML field; currently empty (migration complete). Works as a pair with Billing.CurrentFundingDataMigrated.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | No primary key |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | None |

---

## 1. Business Meaning

`Billing.FundingBackup` is a rollback-and-staging table for a specific one-time data migration of credit card Funding records (FundingTypeID=1). The migration updated the `SecuredCardData` column value into the XML `FundingData` field of `Billing.Funding`.

The migration workflow involves two paired tables:
1. **Billing.FundingBackup** (this table): Snapshot of all FundingTypeID=1 rows from Billing.Funding before migration, with a `MigrationStatus` bit to track processing progress.
2. **Billing.CurrentFundingDataMigrated** (batch cursor): Scratch table used to process FundingBackup rows in batches of 5,000.

The migration was committed by Shay O. (2021-10-10, DBA-715). Both tables are currently empty - the migration completed successfully and the tables were truncated/cleared.

---

## 2. Business Logic

### 2.1 Migration Backup-and-Restore Pattern

**What**: `BackupFundingBeforeMigration` creates a complete snapshot; `RestoreFundingDataAfterMigration` processes it in batches.

**Procedure: BackupFundingBeforeMigration**:
```sql
TRUNCATE TABLE Billing.FundingBackup
INSERT INTO Billing.FundingBackup (...)
  SELECT all columns from Billing.Funding WHERE FundingTypeID = 1
  -- MigrationStatus hardcoded to 0 (not yet processed)
```

**Procedure: RestoreFundingDataAfterMigration (batch loop)**:
```
WHILE (unprocessed rows in FundingBackup WHERE MigrationStatus = 0):
  1. INSERT TOP 5000 FundingIDs into CurrentFundingDataMigrated
  2. UPDATE Billing.Funding: set FundingData XML SecuredCardDataAsString node
       = FundingBackup.SecuredCardData (for FundingIDs in current batch)
  3. UPDATE FundingBackup SET MigrationStatus = 1 for the same batch
  4. TRUNCATE CurrentFundingDataMigrated (clear for next batch)
```

**Migration goal**: The `FundingData` XML in Billing.Funding contained a `<SecuredCardDataAsString>` element that needed to be updated with the value from the separate `SecuredCardData` column. This migration pushed the column value into the XML structure.

---

## 3. Data Overview

Table is empty (0 rows). Migration was completed and the table was truncated.

When active during migration, rows would have been exact copies of Billing.Funding records for FundingTypeID=1 (credit cards), with MigrationStatus=0 (pending) or =1 (processed).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | VERIFIED | ID of the Billing.Funding record being backed up. No FK constraint. Part of the (implicit) one-row-per-Funding snapshot. |
| 2 | FundingTypeID | int | NO | - | VERIFIED | Payment method type. In practice, BackupFundingBeforeMigration only inserts rows WHERE FundingTypeID=1 (credit cards). No FK constraint. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | Manager (agent/affiliate) associated with this funding record. Implicit FK to BackOffice.Manager. NULL for direct customers. |
| 4 | IsBlocked | bit | NO | - | VERIFIED | Whether this funding instrument is blocked. Copied from Billing.Funding.IsBlocked. |
| 5 | BlockedDescription | varchar(255) | YES | - | CODE-BACKED | Text description of why the funding instrument was blocked. NULL if not blocked. |
| 6 | BlockedAt | datetime | YES | - | CODE-BACKED | When the funding instrument was blocked. NULL if not blocked. |
| 7 | FundingData | xml | YES | - | VERIFIED | XML blob containing card/payment details for this funding instrument. Contains the `<SecuredCardDataAsString>` element that was the target of the migration update. Stored in TEXTIMAGE_ON PRIMARY. |
| 8 | IsRefundExcluded | bit | NO | - | CODE-BACKED | Whether this funding instrument is excluded from refunds. Copied from Billing.Funding. |
| 9 | DocumentRequired | bit | NO | - | CODE-BACKED | Whether supporting documents are required for this funding instrument. Copied from Billing.Funding. |
| 10 | MigrationStatus | bit | YES | - | VERIFIED | Migration processing flag. 0=not yet processed by RestoreFundingDataAfterMigration, 1=this FundingID was processed and FundingData XML was updated. Used as the loop condition in RestoreFundingDataAfterMigration: `WHERE MigrationStatus = 0`. |
| 11 | BackupDate | datetime | YES | GETDATE() | VERIFIED | When this row was inserted into FundingBackup. Auto-populated via DEFAULT (GETDATE()). Set by BackupFundingBeforeMigration INSERT. |
| 12 | SecuredCardData | varchar(100) | NO | - | VERIFIED | The card security token/data that was migrated INTO FundingData XML. RestoreFundingDataAfterMigration uses this value to update `FundingData.modify('replace value of (/Funding/SecuredCardDataAsString/text())[1]...')`. |
| 13 | DateCreated | datetime | YES | - | CODE-BACKED | Original creation date of the Billing.Funding record. Added by Shay O. (2021-10-10, DBA-715) to provide audit context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID | Billing.Funding | Implicit | Funding record being backed up |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BackupFundingBeforeMigration | (all columns) | WRITER (TRUNCATE + INSERT) | Creates the backup snapshot from Billing.Funding WHERE FundingTypeID=1 |
| Billing.RestoreFundingDataAfterMigration | FundingID, MigrationStatus, SecuredCardData | READER+WRITER | Processes backup in 5000-row batches; updates Billing.Funding XML and marks rows as MigrationStatus=1 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingBackup (table)
  (no FK constraints - all relationships implicit)

Used with:
Billing.CurrentFundingDataMigrated (table) - batch cursor scratch table
Billing.Funding (table)                    - source and target of migration
```

### 6.1 Objects This Depends On

No FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BackupFundingBeforeMigration | Stored Procedure | WRITER - creates the snapshot |
| Billing.RestoreFundingDataAfterMigration | Stored Procedure | READER+WRITER - processes migration in batches |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. No PK, no clustered, no nonclustered.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingBackupDate | DEFAULT | BackupDate = GETDATE() at insert time |

### 7.3 Relationship to Billing.CurrentFundingDataMigrated

These two tables work together as a batch migration pair:
- `FundingBackup`: Holds the snapshot and MigrationStatus per row (source of truth)
- `CurrentFundingDataMigrated`: Acts as a temporary batch cursor (truncated after each batch of 5,000)

The MigrationStatus column on FundingBackup allows the migration to be safely interrupted and resumed - processing picks up at the next `WHERE MigrationStatus = 0` batch.

---

## 8. Sample Queries

### 8.1 Check migration progress (while active)
```sql
SELECT  MigrationStatus,
        COUNT(*)    AS RowCount
FROM    Billing.FundingBackup WITH (NOLOCK)
GROUP BY MigrationStatus;
-- MigrationStatus=0: pending; MigrationStatus=1: done
```

### 8.2 Verify the table is empty (post-migration)
```sql
SELECT COUNT(*) AS RowCount FROM Billing.FundingBackup WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

Jira reference: DBA-715 (2021-10-10, Shay O.) - added DateCreated column to FundingBackup as part of migration work.

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingBackup | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FundingBackup.sql*
