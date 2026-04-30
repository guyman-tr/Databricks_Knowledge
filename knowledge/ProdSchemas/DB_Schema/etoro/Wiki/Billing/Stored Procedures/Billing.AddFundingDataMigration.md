# Billing.AddFundingDataMigration

> Bulk-inserts PCI card data migration results from a TVP (`Billing.FundingMigrationStatus`) into `Billing.FundingDataMigration`, used during batch credit card tokenization migrations to log per-funding-record outcomes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NewMigrationDataTbl TVP input (Billing.FundingMigrationStatus) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AddFundingDataMigration` is the batch writer for the credit card tokenization migration pipeline. During a PCI DSS card data migration - where raw card data in `Billing.Funding.FundingData` is being converted to a tokenized/secured representation - a migration service processes funding records in batches and calls this procedure to bulk-insert the results.

The procedure accepts a table-valued parameter (`Billing.FundingMigrationStatus`) containing one row per migrated funding record, inserting all rows into `Billing.FundingDataMigration` in a single operation. This TVP pattern enables efficient bulk inserts without individual row round-trips to the database.

As of the documentation date, `Billing.FundingDataMigration` is empty - the migration has been completed and data cleaned up via `Billing.FundingDataMigrationCleanData`. The procedure and its infrastructure remain in place for potential future migration operations.

---

## 2. Business Logic

### 2.1 TVP Bulk Insert Pattern

**What**: The entire batch is inserted in a single INSERT...SELECT from the TVP, providing atomic, efficient bulk logging of migration outcomes.

**Parameters/Columns Involved**: `@NewMigrationDataTbl`, all columns of `Billing.FundingDataMigration`

**Rules**:
- The procedure performs a direct INSERT...SELECT from the TVP without any filtering, transformation, or validation - it assumes the caller has already processed and validated the migration results.
- All 8 columns from the TVP are inserted: FundingID, MigrationStatus, Exception, ExecutionID, Version, SecuredCardData, BinCode, BinCountry.
- The IDENTITY column (FundingDataMigrationID) is auto-generated; the clustered index is on FundingID.
- TVP parameter is READONLY - the procedure cannot modify the input data.
- No error handling or rollback logic - if any row violates constraints, the entire batch fails.

**Diagram**:
```
Migration service processes N FundingIDs
         |
         v
Build @NewMigrationDataTbl (Billing.FundingMigrationStatus TVP)
  [FundingID | MigrationStatus | Exception | ExecutionID | Version | SecuredCardData | BinCode | BinCountry]
  [row 1    | ...             | ...       | ...         | ...     | ...             | ...     | ...       ]
  ...
  [row N    | ...             | ...       | ...         | ...     | ...             | ...     | ...       ]
         |
         v
EXEC Billing.AddFundingDataMigration @NewMigrationDataTbl
         |
         v
INSERT INTO Billing.FundingDataMigration ... SELECT FROM TVP (N rows, one operation)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NewMigrationDataTbl | Billing.FundingMigrationStatus READONLY | NO | - | VERIFIED | Table-valued parameter containing one row per funding record migration result. The TVP type is defined in `Billing.FundingMigrationStatus` (documented separately). Contains: FundingID, MigrationStatus, Exception, ExecutionID, Version, SecuredCardData, BinCode, BinCountry. All rows are bulk-inserted into Billing.FundingDataMigration in a single operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @NewMigrationDataTbl (type) | Billing.FundingMigrationStatus | TVP Type | The input parameter type; defines the shape of the batch data. |
| (INSERT target) | Billing.FundingDataMigration | WRITER | All rows from the TVP are bulk-inserted here. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from the card data migration service during PCI DSS migration batches.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AddFundingDataMigration (procedure)
|- Billing.FundingMigrationStatus (type)    [TVP parameter type - defines input shape]
+- Billing.FundingDataMigration (table)     [INSERT - write target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingMigrationStatus | User Defined Type | TVP parameter type - defines the schema of the input batch |
| Billing.FundingDataMigration | Table | INSERT target - receives all rows from the TVP |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from the card data migration service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Insert migration results for a batch (TVP pattern)
```sql
-- Declare and populate the TVP
DECLARE @MigrationBatch AS Billing.FundingMigrationStatus;

INSERT INTO @MigrationBatch (FundingID, MigrationStatus, Exception, ExecutionID, Version, SecuredCardData, BinCode, BinCountry)
VALUES
    (1001, 1, NULL,            42, 3, 'tok_abc123', '411111', 'US'),
    (1002, 2, 'Timeout error', 42, 3, NULL,         '524153', 'GB'),
    (1003, 1, NULL,            42, 3, 'tok_def456', '402400', 'DE');

EXEC Billing.AddFundingDataMigration @NewMigrationDataTbl = @MigrationBatch;
```

### 8.2 Verify inserted migration records
```sql
SELECT  FDM.FundingDataMigrationID,
        FDM.FundingID,
        FDM.MigrationStatus,
        FDM.Exception,
        FDM.ExecutionID,
        FDM.Version,
        FDM.SecuredCardData,
        FDM.BinCode,
        FDM.BinCountry
FROM    Billing.FundingDataMigration FDM WITH (NOLOCK)
WHERE   FDM.ExecutionID = 42
ORDER BY FDM.FundingID;
```

### 8.3 Check migration status distribution for an execution batch
```sql
SELECT  FDM.MigrationStatus,
        COUNT(*)        AS RecordCount,
        SUM(CASE WHEN FDM.Exception IS NOT NULL THEN 1 ELSE 0 END) AS WithExceptions
FROM    Billing.FundingDataMigration FDM WITH (NOLOCK)
WHERE   FDM.ExecutionID = 42
GROUP BY FDM.MigrationStatus
ORDER BY FDM.MigrationStatus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AddFundingDataMigration | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AddFundingDataMigration.sql*
