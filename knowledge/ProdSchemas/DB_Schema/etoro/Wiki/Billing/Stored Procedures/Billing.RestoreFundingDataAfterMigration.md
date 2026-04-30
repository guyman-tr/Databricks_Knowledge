# Billing.RestoreFundingDataAfterMigration

> DBA/maintenance procedure that restores SecuredCardData values into the Billing.Funding XML FundingData field from a backup table, processing in batches of 5000 until all unprocessed records are complete.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; processes all rows with MigrationStatus=0 in Billing.FundingBackup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a one-time or occasional maintenance procedure created for a specific data migration scenario: restoring the `SecuredCardData` value back into the XML `FundingData` field of `Billing.Funding`. `Billing.FundingBackup` holds the original SecuredCardData values (backup from before a migration), and this procedure re-injects them into the FundingData XML using `FundingData.modify()`.

It processes records in batches of 5,000 using a WHILE loop to avoid locking the Funding table for too long in a single transaction. `Billing.CurrentFundingDataMigrated` is a work table used to track the current batch being processed. `MigrationStatus` in FundingBackup tracks progress: 0=pending, 1=done.

The procedure uses `WITH EXECUTE AS OWNER` to run with elevated permissions, and has a commented-out `@ExecutionID` parameter suggesting it was designed for idempotent re-execution tracking. This is a DBA-controlled maintenance procedure, not part of the regular application flow.

---

## 2. Business Logic

### 2.1 Batched XML Update Loop

**What**: Restores SecuredCardData into FundingData XML in 5,000-row batches.

**Columns/Parameters Involved**: `MigrationStatus`, `FundingData`, `SecuredCardData`

**Rules**:
- WHILE loop continues until no rows remain in FundingBackup with MigrationStatus=0.
- Each iteration:
  1. TRUNCATE CurrentFundingDataMigrated (work table).
  2. INSERT TOP 5000 FundingIDs from FundingBackup WHERE MigrationStatus=0.
  3. UPDATE Billing.Funding.FundingData XML: replaces `/Funding/SecuredCardDataAsString/text()` with the value from FundingBackup.SecuredCardData.
  4. UPDATE FundingBackup.MigrationStatus = 1 for the processed batch.
  5. TRUNCATE CurrentFundingDataMigrated.
- No explicit transaction wrapper on the batch - each iteration is auto-committed.

**Diagram**:
```
TRUNCATE CurrentFundingDataMigrated
WHILE (FundingBackup has MigrationStatus=0):
  INSERT TOP 5000 FundingIDs into CurrentFundingDataMigrated
  UPDATE Billing.Funding FundingData XML (replace SecuredCardDataAsString)
  UPDATE FundingBackup MigrationStatus = 1
  TRUNCATE CurrentFundingDataMigrated
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No parameters (none defined in the procedure signature).

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | This procedure takes no input parameters. It processes all pending FundingBackup rows (MigrationStatus=0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingData XML update | Billing.Funding | UPDATE | Restores SecuredCardDataAsString XML node value |
| Source data | Billing.FundingBackup | READ + UPDATE | Source of SecuredCardData; MigrationStatus updated to track progress |
| Work table | Billing.CurrentFundingDataMigrated | TRUNCATE + INSERT | Temporary work table for current batch tracking |

### 5.2 Referenced By (other objects point to this)

No SQL callers. DBA-executed maintenance procedure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RestoreFundingDataAfterMigration (procedure)
├── Billing.Funding (table)
├── Billing.FundingBackup (table)
└── Billing.CurrentFundingDataMigrated (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | UPDATE target: FundingData XML modification |
| Billing.FundingBackup | Table | Source of SecuredCardData values + MigrationStatus tracking |
| Billing.CurrentFundingDataMigrated | Table | Work table for batch tracking (truncated between batches) |

### 6.2 Objects That Depend On This

No SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH EXECUTE AS OWNER | Security | Runs with owner permissions to allow FundingData XML modification. |
| Batch size 5000 | Performance | Limits batch to 5000 rows to avoid long-running locks on Billing.Funding. |
| MigrationStatus=0 filter | Progress tracking | Skips already-processed rows on re-run. |

---

## 8. Sample Queries

### 8.1 Check migration progress before running

```sql
SELECT
    SUM(CASE WHEN MigrationStatus = 0 THEN 1 ELSE 0 END) AS Pending,
    SUM(CASE WHEN MigrationStatus = 1 THEN 1 ELSE 0 END) AS Done,
    COUNT(*) AS Total
FROM Billing.FundingBackup WITH (NOLOCK)
```

### 8.2 Execute the migration (DBA only)

```sql
EXEC Billing.RestoreFundingDataAfterMigration
```

### 8.3 Verify a sample of restored records

```sql
SELECT TOP 10 bf.FundingID, bf.SecuredCardData AS BackupValue,
       bfund.FundingData.value('(Funding/SecuredCardDataAsString)[1]', 'varchar(200)') AS RestoredValue,
       bf.MigrationStatus
FROM Billing.FundingBackup bf WITH (NOLOCK)
JOIN Billing.Funding bfund WITH (NOLOCK) ON bfund.FundingID = bf.FundingID
WHERE bf.MigrationStatus = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RestoreFundingDataAfterMigration | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RestoreFundingDataAfterMigration.sql*
