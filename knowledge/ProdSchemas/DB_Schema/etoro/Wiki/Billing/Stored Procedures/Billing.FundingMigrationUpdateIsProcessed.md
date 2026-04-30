# Billing.FundingMigrationUpdateIsProcessed

> Marks a credit card funding migration record as processed (or unprocessed) after migration completes or rolls back.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID INT - PK of Billing.FundingMigration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingMigrationUpdateIsProcessed` is the completion callback in the credit card funding migration pipeline. After the migration process transforms a staging record from `Billing.FundingMigration` (the XML snapshot of a CreditCard `Billing.Funding` row), it calls this procedure to flip the `IsProcessed` flag, marking the record as done.

The default value `@IsProcessed = 1` reflects the normal (success) path. The parameter supports `@IsProcessed = 0` as well, which would be used during rollback or retry scenarios to reset a record back to unprocessed state.

All 43,740 migration records were created on December 24, 2023 (a single-day migration event). As of the latest snapshot, 43,538 (99.5%) have `IsProcessed=1`, and 202 remain unprocessed. This procedure was the mechanism that transitioned records from 0 to 1 as the migration progressed.

---

## 2. Business Logic

### 2.1 Migration Progress Tracking

**What**: The core signal that a staged migration record has been successfully processed.

**Columns/Parameters Involved**: `@FundingID`, `@IsProcessed`, `Billing.FundingMigration.IsProcessed`

**Rules**:
- `IsProcessed = 1` (default): migration processing succeeded for this FundingID. Record can be safely ignored in future batch runs.
- `IsProcessed = 0`: resets the record for reprocessing. Used by rollback or retry procedures.
- WHERE clause uses FundingID (PK clustered) - optimal performance.
- No validation: if FundingID does not exist, 0 rows affected (no error raised).

**Diagram**:
```
Migration process per FundingID:
1. GetFundingMigrations() - stages XML snapshot
2. [Migration logic transforms card data]
3. FundingMigrationUpdateIsProcessed(@FundingID, @IsProcessed=1) <- this procedure
   -> UPDATE FundingMigration SET IsProcessed=1 WHERE FundingID=@FundingID
4. [Repeat for next batch]
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | PK of the Billing.FundingMigration record to update. Must correspond to a row in FundingMigration (FundingTypeID=1 CreditCard records from Billing.Funding). No error if not found. |
| 2 | @IsProcessed | BIT | NO | 1 | CODE-BACKED | New processing status. Default 1 = mark as successfully processed (normal migration completion). Pass 0 to reset record for reprocessing (rollback/retry scenario). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.FundingMigration | Modifier | Updates IsProcessed flag by FundingID (PK) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Credit card migration process | External (job) | Caller | Called after each FundingID batch is successfully migrated to mark records complete |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingMigrationUpdateIsProcessed (procedure)
└── Billing.FundingMigration (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingMigration | Table | UPDATE - sets IsProcessed by FundingID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Credit card migration job | External | Calls as post-processing completion signal |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses SET NOCOUNT ON. No TRY/CATCH, no transaction. Simple single-row UPDATE via PK.

---

## 8. Sample Queries

### 8.1 Mark a migration record as processed

```sql
EXEC [Billing].[FundingMigrationUpdateIsProcessed]
    @FundingID = 987654,
    @IsProcessed = 1;
```

### 8.2 Reset a record for reprocessing

```sql
EXEC [Billing].[FundingMigrationUpdateIsProcessed]
    @FundingID = 987654,
    @IsProcessed = 0;
```

### 8.3 Check migration progress summary

```sql
SELECT IsProcessed, COUNT(*) AS Count
FROM [Billing].[FundingMigration] WITH (NOLOCK)
GROUP BY IsProcessed;
-- IsProcessed=1: done; IsProcessed=0: remaining
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingMigrationUpdateIsProcessed | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingMigrationUpdateIsProcessed.sql*
