# Billing.GetSecuredCreditCardFundingBulk

> Bulk-paged fetch of credit card Funding records that have SecuredCardData set: returns FundingID, FundingData XML, and extracted SecuredCardNumber for batch processing during card data key rotation or tokenization migration pipelines.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MinFundingID (page cursor) + @BulkSize (batch cap); ordered by FundingID ascending |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetSecuredCreditCardFundingBulk is a bulk-paging procedure used by migration or rotation pipelines that need to process credit card (FundingTypeID=1) Funding records containing secured card data. It supports cursor-style pagination: the caller passes @MinFundingID as the starting point and receives the next @BulkSize records, then advances @MinFundingID to `MAX(FundingID) + 1` for the next batch.

The procedure targets records where `Billing.Funding.SecuredCardData` is not null and not '0' - meaning the record has had its card data encrypted/tokenized/secured. The caller receives the raw `FundingData` XML and the extracted `SecuredCardNumber` (read from `FundingData/Funding[1]/SecuredCardDataAsString[1]`) to perform downstream processing such as re-encryption with a new key or validation.

`@ExecutionID` is accepted as a parameter but is not referenced in the query body - it is likely used by the calling pipeline for batch correlation, logging, or idempotency tracking on the caller side.

Created 10 Jul 2018 (Ran Ovadia, FB 52134 - added `SecuredCardData <> 0` filter). Referenced by the CC Key Rotation Confluence space (MG).

---

## 2. Business Logic

### 2.1 Paged Cursor Pattern

**What**: Returns the next batch of qualifying Funding records, ordered by FundingID, starting from @MinFundingID.

**Columns/Parameters Involved**: `@MinFundingID`, `@BulkSize`, `Billing.Funding.FundingID`

**Rules**:
- `SELECT TOP (@BulkSize) ... WHERE FundingID >= @MinFundingID ORDER BY FundingID`
- Caller advances `@MinFundingID = MAX(returned FundingID) + 1` on each iteration
- Processing stops when the procedure returns 0 rows (no more qualifying records at or above @MinFundingID)
- Ascending FundingID order ensures deterministic, non-overlapping page windows

### 2.2 SecuredCardData Filter

**What**: Only Funding records with a meaningful (non-null, non-zero) SecuredCardData value are returned.

**Columns/Parameters Involved**: `Billing.Funding.SecuredCardData`

**Rules**:
- `ISNULL(f.SecuredCardData, '0') <> '0'`
- NULL SecuredCardData is treated as '0' (not set) and excluded
- '0' SecuredCardData is also excluded (sentinel for "no secured data")
- Only records where SecuredCardData contains an actual encrypted/tokenized value are returned
- Added per FB 52134 to skip unprocessed / unsecured card records

### 2.3 Credit Card Type Filter

**What**: Restricts to FundingTypeID=1 (Credit Card) only.

**Columns/Parameters Involved**: `Billing.Funding.FundingTypeID`

**Rules**:
- `WHERE f.FundingTypeID = 1` - hard-coded credit card type
- Other funding types (PayPal=3, Wire Transfer, UnionPay=22, etc.) are excluded
- Aligns with SecuredCardData being a credit-card-specific field

### 2.4 SecuredCardNumber Extraction

**What**: Extracts the secured/tokenized card number from the FundingData XML payload.

**Columns/Parameters Involved**: `Billing.Funding.FundingData`, `SecuredCardNumber`

**Rules**:
- `f.FundingData.value('Funding[1]/SecuredCardDataAsString[1]', 'VARCHAR(MAX)')` AS SecuredCardNumber
- Returns the secured card data as a string from the XML node
- Raw `FundingData` XML is also returned to the caller for full-context processing

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinFundingID | INTEGER | NO | - | CODE-BACKED | Page cursor. The minimum FundingID to include in the result (inclusive). Caller advances this to MAX(returned FundingID)+1 after each batch to walk forward through the table. |
| 2 | @BulkSize | INTEGER | NO | - | CODE-BACKED | Batch size cap. Controls TOP clause - maximum number of rows returned per call. |
| 3 | @ExecutionID | INT | NO | - | CODE-BACKED | Batch execution identifier passed by the caller. Not used in the query - reserved for caller-side logging, correlation, or idempotency tracking. |
| - | FundingID | INT | NO | - | CODE-BACKED | Primary key of the Billing.Funding record. Returned to allow the caller to advance the page cursor. |
| - | FundingData | XML | YES | - | CODE-BACKED | Full FundingData XML from Billing.Funding. Contains the complete card record including SecuredCardDataAsString and other card attributes. Returned for full-context processing by the caller. |
| - | SecuredCardNumber | VARCHAR(MAX) | YES | - | CODE-BACKED | Extracted value of FundingData/Funding[1]/SecuredCardDataAsString[1] from the FundingData XML. The tokenized or encrypted card number. NULL if the XML node is absent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID=1, SecuredCardData filter | Billing.Funding | SELECT | Source of all returned data; filtered to credit card records with secure card data set |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CC Key Rotation pipeline | @MinFundingID, @BulkSize, @ExecutionID | EXEC | Called iteratively to batch-process all secured credit card records (CC Key Rotation, Confluence MG space) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetSecuredCreditCardFundingBulk (procedure)
+-- Billing.Funding (table) [FundingTypeID=1, SecuredCardData filter, FundingData XML]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | SELECT with TOP; filtered by FundingTypeID=1 and SecuredCardData not null/zero; returns FundingID, FundingData, extracted SecuredCardNumber |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CC Key Rotation pipeline | External | Iterative batch-fetch for credit card key rotation or re-tokenization processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingTypeID=1 hardcoded | Design | Only credit card Funding records; other payment types excluded |
| SecuredCardData filter added FB 52134 | Change history | Pre-52134 version would have returned records without SecuredCardData set; filter added 10 Jul 2018 to skip those |
| @ExecutionID unused in SQL | Design | Parameter is accepted but not referenced in the query; caller uses it for external tracking |
| NOLOCK | Concurrency | Uses WITH (NOLOCK) - dirty reads acceptable for bulk migration; avoids blocking on large Funding table |
| No SecuredCardData update | Side-effect-free | Read-only procedure; does not modify any data |

---

## 8. Sample Queries

### 8.1 Fetch first batch of secured credit card records

```sql
EXEC [Billing].[GetSecuredCreditCardFundingBulk]
    @MinFundingID = 0,
    @BulkSize = 1000,
    @ExecutionID = 1
-- Returns up to 1000 credit card Funding records with SecuredCardData set
-- Advance @MinFundingID to MAX(FundingID)+1 for next batch
```

### 8.2 Count eligible records for migration planning

```sql
SELECT COUNT(*) AS EligibleRecords
FROM [Billing].[Funding] WITH (NOLOCK)
WHERE FundingTypeID = 1
  AND ISNULL(SecuredCardData, '0') <> '0'
```

### 8.3 Inspect a sample of secured card records directly

```sql
SELECT TOP 10
    f.FundingID,
    f.FundingTypeID,
    f.SecuredCardData,
    f.FundingData.value('Funding[1]/SecuredCardDataAsString[1]', 'VARCHAR(MAX)') AS SecuredCardNumber,
    f.Created
FROM [Billing].[Funding] f WITH (NOLOCK)
WHERE f.FundingTypeID = 1
  AND ISNULL(f.SecuredCardData, '0') <> '0'
ORDER BY f.FundingID
```

---

## 9. Atlassian Knowledge Sources

**Confluence**: CC Key Rotation (/spaces/MG) - references this procedure as part of the credit card key rotation pipeline.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 1 Confluence (CC Key Rotation) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetSecuredCreditCardFundingBulk | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetSecuredCreditCardFundingBulk.sql*
