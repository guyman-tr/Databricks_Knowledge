# Billing.GetFundingMigration_Rollback

> Reverses a completed funding data migration by restoring original FundingData values from Billing.FundingMigration back to Billing.Funding and resetting all processed records to unprocessed, enabling a full re-run of the migration.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

The FundingMigration subsystem migrates FundingData values for FundingTypeID=1 (credit card) fundings, using Billing.FundingMigration as a staging/snapshot table (distinct from Billing.FundingDataMigration used by the GetFundingDataMigration* family). When a migration needs to be rolled back - due to data errors, failed validation, or the need to re-run the migration from scratch - this procedure restores every Funding record to its pre-migration state.

The rollback process works in batches of 1,000 records to avoid locking large tables. For each batch it:
1. Restores the saved FundingData from FundingMigration back to Billing.Funding
2. Resets IsProcessed to 0 (marks records as unprocessed / ready for re-processing)

This loops until ALL processed records have been rolled back, leaving FundingMigration fully reset and Billing.Funding restored to its pre-migration state.

---

## 2. Business Logic

### 2.1 Batch Loop Rollback

**What**: Processes IsProcessed=1 records from Billing.FundingMigration in batches of 1,000, restoring FundingData and resetting IsProcessed.

**Rules**:
- Count check: `SELECT COUNT(*) FROM Billing.FundingMigration WHERE IsProcessed = 1` - loop runs until count reaches 0
- Batch size: TOP(1000) per iteration - prevents long-held locks and transaction bloat
- Restore: `UPDATE Billing.Funding SET FundingData = FM.FundingData` - overwrites current FundingData with the snapshot saved during migration
- Reset: `UPDATE Billing.FundingMigration SET IsProcessed = 0` - marks these records as unprocessed so they can be re-migrated
- Each batch is wrapped in an explicit BEGIN TRAN / COMMIT TRAN
- Temp table `#FundingIDList` is used within each iteration to identify the batch scope

### 2.2 Transactional Safety

**What**: Each 1,000-record batch is committed atomically.

**Rules**:
- If a COMMIT succeeds, those 1,000 records are rolled back and reset
- The while loop re-queries IsProcessed count after each commit
- No partial rollbacks - either the full batch restores and resets, or neither
- Does NOT use NOLOCK on the UPDATE targets (reads FundingMigration WITH NOLOCK for count but updates are committed-read)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

**Internal variables**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CntIsProcessed | INT | NO | - | CODE-BACKED | Count of IsProcessed=1 records in Billing.FundingMigration. Loop condition - runs while > 0. Re-queried after each batch commit. |

**Implicit output**: Modifies Billing.Funding (FundingData restored) and Billing.FundingMigration (IsProcessed reset to 0).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingMigration.FundingData | Billing.FundingMigration | READ + UPDATE | Source of restored FundingData values; IsProcessed reset to 0 |
| Billing.Funding.FundingData | Billing.Funding | UPDATE | Target of restore - FundingData overwritten with pre-migration snapshot |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DBA / operations team | (no params) | Manual EXEC | Called manually when a funding data migration must be reversed or re-run |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingMigration_Rollback (procedure)
├── Billing.FundingMigration (table) [READ + UPDATE]
└── Billing.Funding (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingMigration | Table | SELECT IsProcessed=1 records (batch); UPDATE IsProcessed=0 (reset); READ FundingData (restore source) |
| Billing.Funding | Table | UPDATE FundingData = FundingMigration.FundingData (restore target) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Invoked manually by operations/DBA. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None defined. No explicit error handling or ROLLBACK logic - if an error occurs mid-batch, the transaction will be left uncommitted.

---

## 8. Sample Queries

### 8.1 Execute the rollback

```sql
-- Run with caution - modifies Billing.Funding and Billing.FundingMigration
EXEC Billing.GetFundingMigration_Rollback;
```

### 8.2 Check rollback progress before running

```sql
SELECT
    SUM(CASE WHEN IsProcessed = 1 THEN 1 ELSE 0 END) AS ProcessedCount,
    SUM(CASE WHEN IsProcessed = 0 THEN 1 ELSE 0 END) AS UnprocessedCount,
    COUNT(*) AS Total
FROM Billing.FundingMigration WITH (NOLOCK);
```

### 8.3 Verify rollback completed

```sql
-- After rollback: all records should have IsProcessed=0
SELECT COUNT(*) AS RemainingProcessed
FROM Billing.FundingMigration WITH (NOLOCK)
WHERE IsProcessed = 1;
-- Expected: 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 7/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingMigration_Rollback | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingMigration_Rollback.sql*
