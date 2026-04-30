# Billing.GetCreditCardFundingBulkFirstTime

> Retrieves an ordered batch of unprocessed credit card funding records (with decrypted card numbers) for the first pass of the card data tokenization migration, skipping records already successfully migrated or currently claimed by this execution.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MinFundingID (cursor), @BulkSize (batch), @ExecutionID (deduplication) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCreditCardFundingBulkFirstTime` is the batch-reader component of the credit card funding data tokenization migration pipeline. When eToro migrated credit card payment instruments from raw/encrypted card number storage to a tokenized/secured card format (tracked in `Billing.FundingDataMigration`), this procedure retrieved sequential chunks of credit card funding records that had not yet been successfully processed.

The "BulkFirstTime" name distinguishes this from a retry procedure: this reads records that have never been successfully migrated (MigrationStatus IS NULL or <> 1), while a retry variant would specifically re-fetch failed records. The procedure uses a cursor-style pagination pattern (`FundingID >= @MinFundingID`, `TOP @BulkSize`, `ORDER BY FundingID`) to allow the migration job to process the entire `Billing.Funding` table in deterministic order without skipping or double-processing records.

Data flow: The migration service calls this procedure with the last processed FundingID + 1 as `@MinFundingID` to get the next batch. For each record returned, it decrypts the raw card number via the CLR function `CLR.DecryptAll`, processes the tokenization, then calls `AddFundingDataMigration` to record results. After the migration was completed, `FundingDataMigrationCleanData` purged the migration log. As of the last data snapshot, `Billing.FundingDataMigration` is empty - the migration is complete. This procedure is retained as infrastructure for potential future card data re-migration operations.

---

## 2. Business Logic

### 2.1 Cursor-Style Batch Pagination

**What**: Processes Billing.Funding credit card records in FundingID order, chunk by chunk, to avoid memory overload and enable resume after failure.

**Columns/Parameters Involved**: `@MinFundingID`, `@BulkSize`, `FundingID`

**Rules**:
- `TOP (@BulkSize)` + `ORDER BY FundingID` + `WHERE FundingID >= @MinFundingID` = classic keyset pagination.
- The caller advances `@MinFundingID` after each batch (typically sets it to `MAX(returned FundingID) + 1` or uses `GetFundingDataMigrationNextFundingID(@ExecutionID)` for the next call).
- Records are processed in ascending FundingID order - deterministic and resumable after job restart.
- Only `FundingTypeID = 1` (credit cards) are included - other payment types (bank, e-wallet) are excluded.

**Diagram**:
```
Call 1: @MinFundingID=1000, @BulkSize=500
  -> Returns FundingIDs 1000..1499 (first 500 unprocessed CC fundings)

Call 2: @MinFundingID=1500, @BulkSize=500
  -> Returns FundingIDs 1500..1999 (next 500)

...until no rows returned (all records migrated)
```

### 2.2 Exclusion Logic - Skip Already Processed and Currently Claimed

**What**: Prevents re-processing records that are already done or being worked on by the current execution.

**Columns/Parameters Involved**: `@ExecutionID`, `Billing.FundingDataMigration.MigrationStatus`, `Billing.FundingDataMigration.ExecutionID`

**Rules**:
- `LEFT JOIN FundingDataMigration fdm ON fdm.FundingID = f.FundingID`: records with no migration entry have fdm columns as NULL.
- `fdm.MigrationStatus IS NULL OR fdm.MigrationStatus <> 1`: includes records never attempted (NULL) and records that failed or were not fully completed (<> 1). Excludes successfully migrated (MigrationStatus = 1).
- `COALESCE(fdm.ExecutionID, 0) <> @ExecutionID`: excludes records already claimed by the CURRENT execution job. This prevents the same execution from pulling the same record twice in consecutive batch calls.
- Combined: returns records that are (a) not yet successfully migrated AND (b) not currently owned by this execution run.

**Diagram**:
```
Funding record state:
  No fdm row             -> MigrationStatus IS NULL     -> INCLUDE (never attempted)
  fdm.MigrationStatus=0  -> <> 1                        -> INCLUDE (attempted, not done)
  fdm.MigrationStatus=1  -> NOT included                -> EXCLUDE (done)
  fdm.ExecutionID=@ExecutionID -> excluded regardless   -> EXCLUDE (this job already has it)
  fdm.ExecutionID=other  -> included if status <> 1     -> INCLUDE (failed in different job)
```

### 2.3 CLR Decryption for Card Data

**What**: Decrypts the card number stored in the XML FundingData column as part of extracting data needed for tokenization.

**Columns/Parameters Involved**: `FundingData` (XML), `CardNumber` (output)

**Rules**:
- `FundingData.value('Funding[1]/CardNumberAsString[1]','VARCHAR(MAX)')`: XQuery to extract the CardNumberAsString element from the XML.
- `CLR.DecryptAll(...)`: CLR (Common Language Runtime) function that decrypts the extracted value. The decrypted card number is then used by the calling service to generate the tokenized/secured card data.
- The decrypted card number is NOT stored - it is an output column used transiently by the migration process.
- This decryption step is the reason the procedure exists as a separate DB proc (not a set-based migration) - CLR decryption happens row by row at the DB layer before the application processes each batch.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinFundingID | INTEGER | NO | - | CODE-BACKED | Minimum FundingID to include in the batch (keyset cursor). Set to 1000 (identity start) for first call; set to last processed FundingID + 1 for subsequent calls. Controls which records are fetched in each batch iteration. |
| 2 | @BulkSize | INTEGER | NO | - | CODE-BACKED | Number of records to return per batch call (TOP clause). Controls memory and processing load for the migration job. Typical values determined by the calling migration service. |
| 3 | @ExecutionID | INT | NO | - | CODE-BACKED | Identifier of the current migration execution job. Records with `FundingDataMigration.ExecutionID = @ExecutionID` are skipped to prevent the same execution from reclaiming its own records. Provided by `GetFundingDataMigrationExecutionID`. |

**Returns** (SELECT output columns):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | FundingID | INT | NO | CODE-BACKED | Primary key of the Billing.Funding record. Used by the caller to track which records have been processed and to advance the @MinFundingID cursor. |
| 2 | FundingData | XML | NO | CODE-BACKED | Full XML payment data for the credit card funding record. Contains card details under the Funding[1] element including CardNumberAsString, SecuredCardDataAsString, BinCodeAsString, BinCountryIDAsInteger, expiry, etc. DDM-masked for non-privileged users; this procedure bypasses masking via CLR decryption of the specific field needed. |
| 3 | CardNumber | VARCHAR(MAX) | YES | CODE-BACKED | Decrypted card number extracted from FundingData XML via CLR.DecryptAll(FundingData.value('Funding[1]/CardNumberAsString[1]','VARCHAR(MAX)')). Contains the raw card number used by the migration service to generate the new tokenized/secured card data. NULL if the XML element is absent or decryption fails. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID | Billing.Funding | Direct read (SELECT) | Source of credit card funding records; filtered to FundingTypeID=1 |
| FundingID | Billing.FundingDataMigration | LEFT JOIN | Migration tracking table; used to determine which records have been migrated or claimed by current execution |
| CardNumberAsString | CLR.DecryptAll | CLR function call | Decrypts the card number stored in FundingData XML for migration processing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE grant | Permission | BI admin SQL user granted execute - used for monitoring or manual re-run of migration |
| PROD_SQL_Billing | EXECUTE grant | Permission | Billing service SQL user - the primary migration service caller |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCreditCardFundingBulkFirstTime (procedure)
├── Billing.Funding (table)
├── Billing.FundingDataMigration (table)
└── CLR.DecryptAll (CLR function - external assembly)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Primary read - SELECT TOP with WHERE FundingTypeID=1 and FundingID >= @MinFundingID |
| Billing.FundingDataMigration | Table | LEFT JOIN - filters out already-migrated and currently-claimed records |
| CLR.DecryptAll | CLR Function | Decrypts CardNumberAsString from FundingData XML for each returned row |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called directly by migration service application (PROD_SQL_Billing); no stored procedures call this procedure. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Simulate the first batch call

```sql
-- Get first 100 unprocessed CC fundings starting from the beginning
EXEC [Billing].[GetCreditCardFundingBulkFirstTime]
    @MinFundingID = 1000,
    @BulkSize = 100,
    @ExecutionID = 0  -- ExecutionID 0 = no active execution; nothing excluded
```

### 8.2 Check how many credit card fundings remain unmigrated

```sql
-- Count CC fundings not yet successfully migrated
SELECT COUNT(*) AS UnmigratedCount
FROM [Billing].[Funding] f WITH (NOLOCK)
LEFT JOIN [Billing].[FundingDataMigration] fdm WITH (NOLOCK) ON fdm.FundingID = f.FundingID
WHERE f.FundingTypeID = 1
  AND (fdm.MigrationStatus IS NULL OR fdm.MigrationStatus <> 1)
```

### 8.3 Review migration state for a specific execution

```sql
-- Check how many records a given execution ID has claimed
SELECT ExecutionID,
       MigrationStatus,
       COUNT(*) AS RecordCount
FROM [Billing].[FundingDataMigration] WITH (NOLOCK)
GROUP BY ExecutionID, MigrationStatus
ORDER BY ExecutionID, MigrationStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped - no repos; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCreditCardFundingBulkFirstTime | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCreditCardFundingBulkFirstTime.sql*
