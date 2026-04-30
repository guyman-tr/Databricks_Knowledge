# Billing.FundingMigrationStatus

> Table-valued parameter type carrying per-funding migration results during PCI card-data rotation, passed in bulk to `Billing.AddFundingDataMigration`.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | FundingID (primary row identifier) |
| **Partition** | N/A |
| **Indexes** | N/A - inline table type, no persistent indexes |

---

## 1. Business Meaning

`Billing.FundingMigrationStatus` is a table-valued parameter (TVP) type that carries a batch of funding record migration outcomes. Each row represents one funding record and its result after being processed by a PCI rotation or card-data migration job: whether it succeeded, failed with an exception, and what version of secured card data it now holds.

This type exists to enable bulk-insert of migration results into `Billing.FundingDataMigration` in a single stored-procedure call. Without it, the migration job would need to issue separate INSERT statements per funding record, which would be impractical at scale for PCI key-rotation batches.

Data flows outward from a migration service: the calling application builds a table of `FundingMigrationStatus` rows (one per processed funding record), then passes the entire batch to `Billing.AddFundingDataMigration`, which inserts all rows into `Billing.FundingDataMigration` via a single bulk INSERT...SELECT.

---

## 2. Business Logic

### 2.1 Migration Execution Tracking

**What**: Records which funding records were processed in a given migration execution run and what happened to each.

**Columns/Parameters Involved**: `FundingID`, `ExecutionID`, `MigrationStatus`, `Exception`

**Rules**:
- `ExecutionID` groups all rows processed in a single migration run, enabling per-run auditing
- `MigrationStatus` indicates success or failure for each funding record (integer code)
- `Exception` captures the error message if the migration for that row failed
- A row is inserted for every attempted funding record, regardless of success or failure

**Diagram**:
```
Migration Job (app)
  -> builds FundingMigrationStatus TVP (one row per FundingID)
  -> calls Billing.AddFundingDataMigration(@tbl READONLY)
  -> rows bulk-inserted into Billing.FundingDataMigration
```

### 2.2 PCI Card-Data Fields

**What**: Carries the new secured card data and BIN metadata resulting from re-encryption or key rotation.

**Columns/Parameters Involved**: `SecuredCardData`, `BinCode`, `BinCountry`, `Version`

**Rules**:
- `SecuredCardData` holds the newly encrypted/tokenized card data after rotation
- `BinCode` is the first 6 digits of the card number, used for BIN-country lookup
- `BinCountry` is resolved from the BIN and stored for routing purposes
- `Version` tracks which encryption schema or algorithm version was applied

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Primary key of the funding record in `Billing.Funding` being migrated. Passed directly to `Billing.FundingDataMigration.FundingID` by `AddFundingDataMigration`. |
| 2 | MigrationStatus | int | NO | - | CODE-BACKED | Result code of the migration attempt for this funding record. Inserted directly into `Billing.FundingDataMigration.MigrationStatus`. Exact values are defined by the calling migration application. |
| 3 | Exception | nvarchar(max) | YES | NULL | CODE-BACKED | Error message or exception text if the migration failed for this row. NULL on success. Collation: Latin1_General_BIN (binary, case-sensitive). Stored in `Billing.FundingDataMigration.Exception`. |
| 4 | ExecutionID | int | NO | - | CODE-BACKED | Identifier for the migration execution batch that processed this record. Groups all rows from a single migration run. References `Billing.FundingDataMigration.ExecutionID`. |
| 5 | Version | varchar(50) | NO | - | CODE-BACKED | Version identifier of the encryption schema or key version applied to this funding record during migration. Collation: Latin1_General_BIN. Stored in `Billing.FundingDataMigration.Version`. |
| 6 | SecuredCardData | varchar(100) | YES | NULL | CODE-BACKED | The newly encrypted or tokenized card data after PCI key rotation. NULL if the record did not involve card data or if rotation was not applicable. Collation: Latin1_General_BIN. Stored in `Billing.FundingDataMigration.SecuredCardData`. |
| 7 | BinCode | varchar(6) | YES | NULL | CODE-BACKED | First 6 digits of the card number (Bank Identification Number). Used for BIN-to-country resolution post-migration. NULL for non-card funding types. Collation: Latin1_General_BIN. |
| 8 | BinCountry | int | YES | NULL | CODE-BACKED | Country ID resolved from the BIN code. References `Dictionary.Country` (implicit). NULL if BinCode is NULL or resolution was not performed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID | Billing.Funding | Implicit | References the funding record being migrated |
| ExecutionID | Billing.FundingDataMigration | Implicit | Groups into a migration execution batch |
| BinCountry | Dictionary.Country | Implicit | BIN-resolved country ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AddFundingDataMigration | @NewMigrationDataTbl | TVP Parameter | Sole consumer - receives this type READONLY and bulk-inserts into Billing.FundingDataMigration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AddFundingDataMigration | Stored Procedure | Receives as READONLY TVP parameter; bulk-inserts all rows into Billing.FundingDataMigration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Inspect type column definitions

```sql
SELECT c.name, t.name AS type_name, c.max_length, c.is_nullable
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name = 'FundingMigrationStatus'
ORDER BY c.column_id
```

### 8.2 View recent migration data in FundingDataMigration

```sql
SELECT TOP 20
    FundingID,
    MigrationStatus,
    ExecutionID,
    Version,
    CASE WHEN Exception IS NOT NULL THEN 'FAILED' ELSE 'OK' END AS Result,
    Exception
FROM Billing.FundingDataMigration WITH (NOLOCK)
ORDER BY ExecutionID DESC
```

### 8.3 Count migration outcomes by status per execution

```sql
SELECT
    ExecutionID,
    Version,
    MigrationStatus,
    COUNT(*) AS RecordCount,
    SUM(CASE WHEN Exception IS NOT NULL THEN 1 ELSE 0 END) AS FailedCount
FROM Billing.FundingDataMigration WITH (NOLOCK)
GROUP BY ExecutionID, Version, MigrationStatus
ORDER BY ExecutionID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingMigrationStatus | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.FundingMigrationStatus.sql*
