# Billing.BackupFundingBeforeMigration

> Migration utility that TRUNCATES Billing.FundingBackup and repopulates it with a fresh snapshot of all CreditCard funding records (FundingTypeID=1) from Billing.Funding, hardcoding MigrationStatus=0 (not yet migrated) to prepare for a payment instrument migration run.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No return value; side effect is complete replacement of Billing.FundingBackup contents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BackupFundingBeforeMigration` is a pre-migration utility procedure for the credit card funding instrument migration workflow. Before a payment instrument migration runs (e.g., migrating card data between payment providers or vaulting systems), this procedure creates a clean point-in-time snapshot of all credit card funding records into `Billing.FundingBackup`.

The procedure always starts with a TRUNCATE - there is no incremental update or merge. Each call produces a full replacement of the backup table. MigrationStatus is hardcoded to 0 (not yet migrated) for all backed-up records, indicating that the snapshot represents the pre-migration state and the actual migration processing has not yet occurred for any record.

The procedure runs `WITH EXECUTE AS OWNER`, elevating privileges to owner level for the TRUNCATE and INSERT operations.

Note: The commented-out `@ExecutionID` parameter in the header suggests the procedure was originally designed to be called as part of a tracked execution context, but the parameter was removed. The procedure is currently parameterless.

---

## 2. Business Logic

### 2.1 Full Replace via TRUNCATE then INSERT

**What**: The backup table is cleared entirely and repopulated from the current state of Billing.Funding.

**Parameters/Columns Involved**: `Billing.FundingBackup`, `Billing.Funding`

**Rules**:
- `TRUNCATE TABLE Billing.FundingBackup` - removes all existing backup rows (faster than DELETE, no row logging).
- INSERT selects all columns from Billing.Funding WHERE FundingTypeID=1 (CreditCard records only).
- No other FundingTypeIDs (PayPal, WireTransfer, etc.) are included.
- `Convert(BIT, 0)` hardcodes MigrationStatus=0 for all inserted rows (ignoring the actual MigrationStatus on Billing.Funding if it has one).
- DateCreated is copied from the source Billing.Funding record.

### 2.2 Scope: CreditCard Only (FundingTypeID=1)

**What**: Only credit card payment instruments are backed up.

**Rules**:
- `WHERE FundingTypeID = 1` - FundingTypeID=1 is CreditCard.
- The migration this backup supports is specifically a card data migration (e.g., card tokenization migration, vault transfer).
- Non-card payment methods (PayPal, wire transfer, etc.) are excluded.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters. No output parameters.

**Side effects**:
- TRUNCATE: clears all rows from Billing.FundingBackup
- INSERT: populates Billing.FundingBackup with current CreditCard records from Billing.Funding

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (TRUNCATE target) | Billing.FundingBackup | WRITER | Truncates all existing backup rows to start fresh. |
| (INSERT target) | Billing.FundingBackup | WRITER (INSERT) | Inserts fresh snapshot of CreditCard funding records with MigrationStatus=0. |
| (SELECT source) | Billing.Funding | READER | Source of CreditCard funding records (FundingTypeID=1). |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called as a pre-step in migration execution scripts.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BackupFundingBeforeMigration (procedure)
|- Billing.FundingBackup (table)   [TRUNCATE + INSERT target]
+- Billing.Funding (table)         [SELECT source - CreditCard records]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingBackup | Table | TRUNCATE and INSERT target for the migration snapshot |
| Billing.Funding | Table | SELECT source for CreditCard funding records (FundingTypeID=1) |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from migration execution contexts.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **WITH EXECUTE AS OWNER**: The procedure runs with owner-level permissions. This is required for TRUNCATE (which needs ALTER TABLE permission) in contexts where the caller has limited schema access.
- **TRUNCATE vs DELETE**: TRUNCATE is used instead of DELETE for performance and minimal logging. This means the operation is not easily reversible in mid-execution; it must complete or the backup table is empty.
- **MigrationStatus hardcoded to 0**: The INSERT uses `Convert(BIT, 0)` for MigrationStatus rather than copying from Billing.Funding. This is intentional - the backup represents the pre-migration state where no records have been processed yet.
- **No transaction wrapper**: The procedure has no explicit transaction. The TRUNCATE and INSERT are not atomic from the caller's perspective. If the INSERT fails mid-way, the backup table will be in a partial state. Callers should validate the backup row count after execution.

---

## 8. Sample Queries

### 8.1 Execute the backup (pre-migration step)
```sql
EXEC Billing.BackupFundingBeforeMigration;
```

### 8.2 Verify the backup completed
```sql
SELECT  COUNT(*) AS BackupRowCount,
        SUM(CASE WHEN MigrationStatus = 0 THEN 1 ELSE 0 END) AS NotMigrated,
        MAX(DateCreated) AS MostRecentFundingDate
FROM    Billing.FundingBackup WITH (NOLOCK);

-- Compare with source:
SELECT  COUNT(*) AS SourceRowCount
FROM    Billing.Funding WITH (NOLOCK)
WHERE   FundingTypeID = 1;
```

### 8.3 Inspect the backup content
```sql
SELECT TOP 10
    FB.FundingID,
    FB.FundingTypeID,
    FB.IsBlocked,
    FB.MigrationStatus,
    FB.DateCreated
FROM    Billing.FundingBackup FB WITH (NOLOCK)
ORDER BY FB.FundingID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BackupFundingBeforeMigration | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BackupFundingBeforeMigration.sql*
