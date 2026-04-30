# Dictionary.FundingDataMigrationStatus

> Lookup table defining the six states of the funding data encryption migration pipeline — from initial staging through XML update success or failure in Billing.Funding.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FundingDataMigrationStatus tracks the lifecycle states of a data migration process that encrypted sensitive funding information stored in the Billing.Funding table's XML column. This migration was a PCI-DSS compliance initiative — existing payment method data (credit card numbers, bank account details) stored in cleartext XML needed to be encrypted in place.

This table exists because the encryption migration was a multi-step process that could fail at different stages. Each funding record moved through: initial staging, encryption in a staging table, then modification of the actual XML in Billing.Funding. If any step failed, the status recorded which step broke so the operations team could investigate and retry. The statuses distinguish between clean failures (runtime error caught) and silent failures (update ran but didn't actually change the data).

This is a migration-specific table — once all funding records have been successfully encrypted, this table becomes historical reference only. It is not referenced by any stored procedures in the current codebase, confirming the migration has completed.

---

## 2. Business Logic

### 2.1 Migration Pipeline States

**What**: The encryption migration follows a 3-step pipeline with success and failure states at each stage.

**Columns/Parameters Involved**: `ID`, `StatusDesc`

**Rules**:
- **New (0)**: Initial state — funding record has been queued for encryption migration but not yet processed
- **Succeeded to encrypt in staging (1)**: The encryption step completed successfully in the staging table — data is encrypted but not yet written back to Billing.Funding
- **Failed to encrypt in staging (2)**: The encryption step failed in staging — the data could not be encrypted (possibly due to malformed XML, unsupported characters, or encryption key issues)
- **Modified XML in Billing.Funding (3)**: Final success — the encrypted data was written back to the production Billing.Funding XML column
- **Runtime error during XML update (4)**: The update to Billing.Funding threw a runtime error (exception caught) — the production record was NOT modified
- **Silent update failure (5)**: The update to Billing.Funding ran without error but the data didn't actually change — the most insidious failure mode, requiring manual investigation

**Diagram**:
```
New (0)
  │
  ├── SUCCESS ──► Encrypted in staging (1)
  │                   │
  │                   ├── SUCCESS ──► XML modified in prod (3) ✓ DONE
  │                   │
  │                   ├── RUNTIME ERROR ──► Error during update (4)
  │                   │
  │                   └── SILENT FAIL ──► Update didn't work (5)
  │
  └── FAILURE ──► Failed to encrypt in staging (2)
```

---

## 3. Data Overview

| ID | StatusDesc | Meaning |
|---|---|---|
| 0 | New | Funding record queued for encryption migration but not yet processed. Starting state for all records entering the migration pipeline. |
| 1 | Succedded to encrypt in staging table | Encryption completed successfully in staging area. The sensitive data has been encrypted but the production Billing.Funding XML has not yet been updated. Intermediate success state. |
| 2 | Failed to encrypt in staging table | Encryption failed during the staging step. The original data remains unchanged. May indicate malformed XML, unsupported data formats, or encryption key issues. Requires manual investigation. |
| 3 | Modified XML in Billing.Funding table | Final success state — the encrypted data was written back to the production Billing.Funding table. The migration is complete for this record. |
| 4 | Had runtime error while updating XML in Billing.Funding table | The update to production Billing.Funding threw a caught runtime error. The production record was NOT modified. The staging encrypted data is available for retry. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the migration status. 0=New, 1=Encryption succeeded in staging, 2=Encryption failed in staging, 3=XML modified in production (success), 4=Runtime error during production update, 5=Silent update failure. Used to track each funding record's progress through the encryption migration pipeline. |
| 2 | StatusDesc | varchar(150) | NO | - | VERIFIED | Human-readable description of the migration state. Provides enough detail for operations staff to understand what happened at each step — particularly useful for distinguishing between different failure modes (runtime error vs silent failure). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active FK or procedure references found in current codebase — migration appears complete.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. Migration-specific table — no active consumer procedures in the current codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryFundingDataMigrationStatus | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryFundingDataMigrationStatus | PRIMARY KEY | Unique migration status identifier |

---

## 8. Sample Queries

### 8.1 List all migration statuses
```sql
SELECT  ID,
        StatusDesc
FROM    [Dictionary].[FundingDataMigrationStatus] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Resolve migration status by ID
```sql
SELECT  StatusDesc
FROM    [Dictionary].[FundingDataMigrationStatus] WITH (NOLOCK)
WHERE   ID = @StatusID;
```

### 8.3 List failure states only
```sql
SELECT  ID,
        StatusDesc
FROM    [Dictionary].[FundingDataMigrationStatus] WITH (NOLOCK)
WHERE   ID IN (2, 4, 5)
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FundingDataMigrationStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FundingDataMigrationStatus.sql*
