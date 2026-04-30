# Billing.FundingDataMigrationCleanData

> Purges all rows from the credit card migration staging table after a PCI data rotation migration is complete.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - single TRUNCATE operation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingDataMigrationCleanData` is a cleanup procedure that truncates the `Billing.FundingDataMigration` staging table after a PCI data rotation migration batch has completed. Created in July 2018 for PCI compliance card data tokenization work.

The procedure exists to close the loop on a multi-step migration pattern: (1) migration data is bulk-loaded into `Billing.FundingDataMigration` via `Billing.AddFundingDataMigration`, (2) the migration processes records and writes secured tokens back to source funding records, and (3) this procedure clears the staging table once the migration is confirmed complete. Without cleanup, sensitive card migration data (BIN codes, secured card tokens) would accumulate in the staging table unnecessarily.

`WITH EXECUTE AS OWNER` is declared, meaning the TRUNCATE executes under the table owner's permissions regardless of the caller's role - necessary because PCI rotation jobs may be invoked by lower-privileged accounts that do not have TRUNCATE rights directly. The current `Billing.FundingDataMigration` table is empty (migration complete), meaning the last cleanup was successful.

---

## 2. Business Logic

### 2.1 PCI Data Rotation Cleanup Pattern

**What**: Final step in the credit card data tokenization migration lifecycle.

**Columns/Parameters Involved**: None (no parameters)

**Rules**:
- TRUNCATE (not DELETE) is used - faster and fully logged only as a page deallocation.
- No WHERE clause - all rows are removed unconditionally.
- `WITH EXECUTE AS OWNER` elevates permissions at runtime - the caller does not need TRUNCATE rights on the table.
- This procedure should only be called AFTER migration results have been verified and secured tokens written back to source records via `Billing.UpdateSecuredCard`.

**Diagram**:
```
PCI Rotation Migration Flow:
1. Billing.AddFundingDataMigration    --> Bulk insert to FundingDataMigration
2. Billing.GetCreditCardFundingBulkFirstTime / GetFundingDataMigrationNextFundingID
                                      --> Batch cursor over FundingIDs
3. Billing.UpdateSecuredCard          --> Write secured tokens back to Billing.Funding
4. [verify migration complete]
5. Billing.FundingDataMigrationCleanData  --> TRUNCATE TABLE (this procedure)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|

No parameters. This procedure takes no input and produces no output - it is a side-effect-only operation (TRUNCATE).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (implicit) | Billing.FundingDataMigration | TRUNCATE | Removes all rows from the migration staging table. Final step in the PCI rotation migration lifecycle. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PCI_Rotation (DB role/permission script) | EXECUTE | Permission | Referenced in PCI rotation permission grants - called by the PCI rotation process |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingDataMigrationCleanData (procedure)
└── Billing.FundingDataMigration (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingDataMigration | Table | TRUNCATE target - all rows removed |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PCI rotation process | External (application/job) | Calls as final cleanup step after migration verification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. `WITH EXECUTE AS OWNER` - runs under table owner permissions. No parameters, no NOCOUNT set explicitly, no TRY/CATCH block.

---

## 8. Sample Queries

### 8.1 Verify migration table is empty before/after cleanup

```sql
SELECT COUNT(*) AS RowCount
FROM [Billing].[FundingDataMigration] WITH (NOLOCK);
-- Should be 0 after FundingDataMigrationCleanData completes
```

### 8.2 Check migration status before running cleanup

```sql
SELECT MigrationStatus, COUNT(*) AS Count
FROM [Billing].[FundingDataMigration] WITH (NOLOCK)
GROUP BY MigrationStatus;
-- Verify all rows have a terminal status before truncating
```

### 8.3 Execute cleanup (only after verifying migration is complete)

```sql
-- Only call after UpdateSecuredCard has written all tokens back to Billing.Funding
EXEC [Billing].[FundingDataMigrationCleanData];
-- Verify:
SELECT COUNT(*) FROM [Billing].[FundingDataMigration] WITH (NOLOCK);
-- Expected: 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingDataMigrationCleanData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingDataMigrationCleanData.sql*
