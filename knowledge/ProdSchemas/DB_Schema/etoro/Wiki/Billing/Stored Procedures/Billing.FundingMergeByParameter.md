# Billing.FundingMergeByParameter

> Atomic find-or-create payment instrument with customer link: checks if a funding record exists by hash, creates it if new, then upserts the customer-to-funding association and returns the result.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns (FundingID, IsBlocked) from CustomerToFunding after link is established |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingMergeByParameter` implements the core "register or reuse a payment method" flow. When a customer adds a payment instrument (card, bank account, etc.), the system needs to: (1) find an existing `Billing.Funding` record if the same payment data was already registered, or create a new one; (2) link the customer to that funding record; and (3) confirm the link is in place.

The procedure is transactional - all three steps succeed together or roll back together. This ensures a customer is never left with a partial registration where the Funding record exists but the CustomerToFunding link does not.

The name "MergeByParameter" is historical. The original implementation matched by the `Parameter` computed column (visible in the commented-out WHERE clause). The current implementation uses hash-based matching (`FundingHash = Billing.FundingHash(@FundingData)`) - a more robust canonical lookup introduced to handle XML attribute ordering variations.

---

## 2. Business Logic

### 2.1 Single-Funding Type Guard

**What**: Prevents registering payment instruments for funding types that do not support multi-instrument registration.

**Columns/Parameters Involved**: `@FundingTypeID`, `Dictionary.FundingType.IsSingleFunding`

**Rules**:
- If `Dictionary.FundingType.IsSingleFunding = 1` for the given @FundingTypeID -> RAISERROR(60025, 16, 1) and RETURN 60025.
- Error 60025 = "cannot add funding of passed type". Callers must handle this error code.
- IsSingleFunding=1 types are one-use instruments that are never shared or looked up by data hash. Examples include internal credit types.
- Only types with IsSingleFunding=0 are processed by this procedure.

### 2.2 Find-or-Create Funding Record (Hash-Based)

**What**: The deduplication logic that avoids creating duplicate payment instrument records.

**Columns/Parameters Involved**: `@FundingData`, `@FundingTypeID`, `Billing.Funding.FundingHash`, `Billing.FundingHash()` function

**Rules**:
- IF NOT EXISTS (hash match for FundingTypeID):
  - For FundingTypeID=1 (CreditCard): DocumentRequired=1 (compliance document required before use)
  - For all other types: DocumentRequired=0
  - INSERT new Billing.Funding row with IsBlocked=0, @FundingData, @DocumentRequired
  - Capture new FundingID via SCOPE_IDENTITY()
- IF EXISTS (matching hash already in Billing.Funding):
  - SELECT TOP(1) FundingID from Billing.Funding WHERE hash matches, ORDER BY FundingID DESC
  - Reuse existing FundingID (most recent if somehow duplicates exist)
  - No update to existing record

**Diagram**:
```
@FundingData (XML) + @FundingTypeID
    |
    IsSingleFunding check (Dictionary.FundingType)
    |-- = 1 --> RAISERROR 60025, RETURN
    |
    Hash match check (Billing.Funding.FundingHash)
    |
    |-- No match --> INSERT new Billing.Funding
    |                   FundingTypeID = @FundingTypeID
    |                   IsBlocked = 0
    |                   FundingData = @FundingData
    |                   DocumentRequired = 1 (if CC) or 0 (others)
    |               SCOPE_IDENTITY() -> @FundingID
    |
    |-- Match found --> SELECT TOP(1) FundingID ORDER BY DESC
    |                   @FundingID = existing FundingID
    |
    EXEC Billing.CustomerToFunding_Upsert(@CID, @FundingID)
    |
    SELECT FundingID, IsBlocked FROM CustomerToFunding
    WHERE CID=@CID AND FundingID=@FundingID
```

### 2.3 Customer-Funding Link (Upsert)

**What**: Establishes or refreshes the customer's link to the payment instrument.

**Columns/Parameters Involved**: `@CID`, `@FundingID`, `Billing.CustomerToFunding`

**Rules**:
- Delegates to `Billing.CustomerToFunding_Upsert(@CID, @FundingID)` which uses a MERGE pattern:
  - If (CID, FundingID) not in CustomerToFunding -> INSERT (CustomerFundingStatusID=0, DepositTypeID=1, ReasonID=6 ByUser)
  - If exists -> UPDATE LastUsedDate = GETUTCDATE()
- After upsert, returns `(FundingID, IsBlocked)` from CustomerToFunding for this customer-funding pair.
- Return value confirms: (a) FundingID is now linked to this customer, (b) IsBlocked=0/1 tells caller if the instrument is currently blocked.

### 2.4 Transaction and Error Handling

**What**: Full ACID transaction with nested transaction awareness.

**Rules**:
- `BEGIN TRAN / COMMIT TRAN` wraps all three steps - single-funding guard, find-or-create, and upsert.
- CATCH block:
  - `IF @@TRANCOUNT = 1`: this is the outermost transaction -> ROLLBACK
  - `IF @@TRANCOUNT > 1`: called within a caller's transaction -> COMMIT (releases savepoint, lets caller handle rollback)
  - After transaction handling: THROW (re-raises original exception to caller)

### 2.5 Unused @Parameter

**What**: The @Parameter parameter is declared but no longer used in procedure logic.

**Rules**:
- Historical artifact from the original implementation that matched by `Billing.Funding.Parameter` column.
- The WHERE clause `WHERE Parameter=@Parameter AND FundingTypeID=@FundingTypeID` is commented out in the code.
- Current logic uses hash-based matching (FundingHash) for deduplication.
- The parameter is kept for backward compatibility with existing callers.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | int | NO | - | CODE-BACKED | Payment instrument type (e.g., 1=CreditCard). Must correspond to a Dictionary.FundingType with IsSingleFunding=0 or RAISERROR 60025 is returned. Controls DocumentRequired logic (=1 for CreditCard type). |
| 2 | @FundingData | XML | NO | - | CODE-BACKED | Full XML payment instrument data. Used to compute FundingHash for existence check and stored as FundingData in new Billing.Funding records. Schema varies by FundingTypeID (e.g., card number hash + BIN for CC). |
| 3 | @Parameter | varchar(100) | NO | - | CODE-BACKED | Legacy parameter, no longer used in procedure logic (commented-out WHERE clause replaced with hash matching). Kept for backward API compatibility. The @Parameter value is ignored by the current implementation. |
| 4 | @CID | int | NO | - | CODE-BACKED | Customer ID. Used to create or update the Billing.CustomerToFunding link after the funding record is found or created. |

**Return columns** (from Billing.CustomerToFunding):

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | FundingID | int | CODE-BACKED | The FundingID that was found or created. Callers store this to reference the payment instrument in future deposit/withdrawal calls. |
| R2 | IsBlocked | bit | CODE-BACKED | Per-customer blocking state for this instrument. 1 = instrument is blocked for this customer; 0 = active. Caller should check this before proceeding with a transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID | Dictionary.FundingType | Lookup | Checks IsSingleFunding to validate type is allowed |
| @FundingData | Billing.Funding | Read + optional Write | Reads to find existing record by hash; inserts if not found |
| @FundingData | Billing.FundingHash (function) | Function call | Computes canonical hash of @FundingData for deduplication check |
| @CID, @FundingID | Billing.CustomerToFunding_Upsert | EXEC | Creates or updates the customer-funding link |
| @CID, @FundingID | Billing.CustomerToFunding | Lookup | Final SELECT to confirm link and return IsBlocked |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing/Funding application service | External | Caller | Called when a customer registers or reuses a payment instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingMergeByParameter (procedure)
├── Dictionary.FundingType (table)
├── Billing.Funding (table)
├── Billing.FundingHash (function)
│     └── Billing.OrderedSmallCaseFundingHash (function)
├── Billing.CustomerToFunding_Upsert (procedure)
│     └── Billing.CustomerToFunding (table)
└── Billing.CustomerToFunding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | Checks IsSingleFunding for validation |
| Billing.Funding | Table | Existence check + optional INSERT |
| Billing.FundingHash | Scalar Function | Computes hash of @FundingData for WHERE clause |
| Billing.CustomerToFunding_Upsert | Stored Procedure | EXEC to create/update customer-funding link |
| Billing.CustomerToFunding | Table | Final SELECT for return values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing/Funding application service | External | Calls for payment instrument registration flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses SET NOCOUNT ON. Full BEGIN TRY/CATCH with nested-transaction-aware rollback logic. RAISERROR 60025 for single-funding type violation. THROW in CATCH block re-raises original exception.

---

## 8. Sample Queries

### 8.1 Register or reuse a credit card for a customer

```sql
DECLARE @FundingData XML = '<Funding><FundingType>1</FundingType><Hash>abc</Hash></Funding>';
EXEC [Billing].[FundingMergeByParameter]
    @FundingTypeID = 1,
    @FundingData = @FundingData,
    @Parameter = '',  -- Legacy - not used
    @CID = 12345;
-- Returns: FundingID, IsBlocked (from CustomerToFunding)
```

### 8.2 Check single-funding type restriction

```sql
SELECT FundingTypeID, Name, IsSingleFunding
FROM [Dictionary].[FundingType] WITH (NOLOCK)
WHERE IsSingleFunding = 1
ORDER BY FundingTypeID;
-- These types will trigger RAISERROR 60025 in FundingMergeByParameter
```

### 8.3 Verify customer-funding link after merge

```sql
SELECT ctf.CID, ctf.FundingID, ctf.IsBlocked,
    ctf.CustomerFundingStatusID, ctf.LastUsedDate,
    f.FundingTypeID
FROM [Billing].[CustomerToFunding] ctf WITH (NOLOCK)
JOIN [Billing].[Funding] f WITH (NOLOCK)
    ON f.FundingID = ctf.FundingID
WHERE ctf.CID = 12345
ORDER BY ctf.LastUsedDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (CustomerToFunding_Upsert) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingMergeByParameter | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingMergeByParameter.sql*
