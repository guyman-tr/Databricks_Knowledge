# Billing.FundingGetByData

> Retrieves existing Billing.Funding records that match a given payment instrument type and data payload - the deduplication lookup for "does this payment method already exist?".

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns full Billing.Funding row(s) matching @FundingTypeID + hash of @FundingData |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingGetByData` is the canonical deduplication lookup for payment instruments. Before registering a new payment method, the application calls this procedure to find out whether a `Billing.Funding` record with identical payment data already exists. It does so by computing the canonical hash of the submitted payment data (`Billing.FundingHash`) and comparing it against the stored `FundingHash` computed column on the `Billing.Funding` table.

The procedure only searches within "new-style, multi-funding" types (`Dictionary.FundingType.IsNewStyle=1 AND IsSingleFunding=0`). This scopes the lookup to modern funding types that support shared payment instruments (e.g., a credit card used by the same customer for multiple deposits). Legacy or single-use funding types are excluded.

Results are ordered `FundingID DESC` (added Dec 2023 per PAYIL-7794) to surface the most recently created matching record first - a production fix applied when duplicate records were discovered in staging. The procedure returns all matching rows; callers typically consume only the first.

---

## 2. Business Logic

### 2.1 Hash-Based Deduplication

**What**: The core deduplication mechanism - converting submitted payment XML into a canonical hash and matching it against indexed stored hashes.

**Columns/Parameters Involved**: `@FundingData`, `Billing.Funding.FundingHash`, `Billing.FundingHash()` function

**Rules**:
- Caller passes `@FundingData` as a VARCHAR(MAX) representing the XML payment data (e.g., card number hash + BIN + expiry for CC).
- The procedure converts it to XML (`CONVERT(XML, @FundingData)`) and calls `Billing.FundingHash()` which internally calls `Billing.OrderedSmallCaseFundingHash()` to produce a 32-char MD5-style hash that is canonical (lowercase, ordered attributes) regardless of XML attribute ordering.
- This hash is matched against the `FundingHash` computed column (stored, indexed) on `Billing.Funding`.
- Result: two payment instruments with the same data always produce the same hash, enabling reliable deduplication without full XML comparison.

**Diagram**:
```
@FundingData (VARCHAR MAX)
    |
    CONVERT(XML, @FundingData)
    |
    Billing.FundingHash(XML)
    |
    Billing.OrderedSmallCaseFundingHash(XML)
    |
    char(32) hash
    |
    WHERE Billing.Funding.FundingHash = <hash>
    (uses NC index on FundingHash column)
    |
    Matching Billing.Funding rows (ordered FundingID DESC)
```

### 2.2 New-Style Multi-Funding Scope Filter

**What**: Restricts search to funding types that are modern and support shared/reusable instruments.

**Columns/Parameters Involved**: `@FundingTypeID`, `Dictionary.FundingType.IsNewStyle`, `Dictionary.FundingType.IsSingleFunding`

**Rules**:
- `IsNewStyle = 1`: Only search within "new-style" funding types introduced post-legacy. Old funding type records are not candidates for deduplication via this procedure.
- `IsSingleFunding = 0`: Exclude single-use funding types (one-time instruments that are never reused). These would never produce a duplicate match.
- `FundingTypeID = @FundingTypeID`: Scope further to the specific type passed - a credit card hash is never compared against bank account hashes even if they somehow match.

### 2.3 Multiple Results and Ordering

**What**: The procedure may return multiple rows when duplicate funding records exist (should be rare but can happen).

**Rules**:
- `ORDER BY BFUN.FundingID DESC` added Dec 2023 (PAYIL-7794) after a staging issue revealed edge cases with duplicate hash matches.
- No `TOP 1` in the query - all matching rows are returned. Application callers should use the first result (highest FundingID = most recent).
- The `FundingHash` column on `Billing.Funding` is computed but not declared UNIQUE - two records can share the same hash (extremely unlikely, but the system handles it gracefully).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | The payment instrument type to search within (e.g., 1=CreditCard, 2=WireTransfer). Filters the lookup to the same type as the incoming payment data. Must correspond to a Dictionary.FundingType with IsNewStyle=1 and IsSingleFunding=0 to return results. |
| 2 | @FundingData | VARCHAR(MAX) | NO | - | CODE-BACKED | The raw payment instrument data as an XML string (matches the schema stored in Billing.Funding.FundingData). Converted to XML internally and hashed via Billing.FundingHash() for comparison. For credit cards, contains card number hash, BIN code, expiry, and other card parameters. |

**Return columns** (from Billing.Funding):

| # | Column | Type | Confidence | Description (inherited from Billing.Funding) |
|---|--------|------|------------|----------------------------------------------|
| R1 | FundingID | int | CODE-BACKED | PK of the matching Billing.Funding record. Result ordered DESC - highest FundingID (most recent) first. |
| R2 | FundingTypeID | int | CODE-BACKED | Payment method type. Will equal @FundingTypeID. See Billing.Funding Section 4. |
| R3 | ManagerID | int | CODE-BACKED | BO manager who created/modified the record; NULL = system/customer-created. |
| R4 | IsBlocked | bit | CODE-BACKED | 1 = payment instrument is blocked from use; 0 = active. Caller should check this before allowing a deposit/withdraw. |
| R5 | BlockedDescription | varchar | CODE-BACKED | Reason for blocking (fraud, KYC, chargeback). NULL if not blocked. |
| R6 | BlockedAt | datetime | CODE-BACKED | UTC timestamp when the instrument was blocked. NULL if not blocked. |
| R7 | FundingData | xml | CODE-BACKED | Full XML payment data (DDM-masked for non-privileged callers - returns 'xxxx'). Schema varies by FundingTypeID. |
| R8 | IsRefundExcluded | bit | CODE-BACKED | 1 = refunds cannot be sent to this instrument; 0 = refunds allowed. |
| R9 | DocumentRequired | bit | CODE-BACKED | 1 = compliance document required before using this instrument; 0 = no document required. |
| R10 | FundingDataCheckSum | int | CODE-BACKED | CHECKSUM of FundingData XML - used for quick change detection. |
| R11 | SecuredCardData | varchar | CODE-BACKED | Extracted secured card token from FundingData (computed column). Card tokenization data for PCI-compliant card reference. |
| R12 | Parameter | varchar | CODE-BACKED | Primary identifying parameter extracted from FundingData (e.g., card hash for CC, account number for wire). |
| R13 | FundingHash | char(32) | CODE-BACKED | Canonical 32-char hash of FundingData. This is the value that was matched by the WHERE clause. |
| R14 | DateCreated | datetime | CODE-BACKED | UTC timestamp when the funding instrument was registered. |
| R15 | PaymentDetails | nvarchar | CODE-BACKED | Pre-computed payment display details (added Nov 2022, PAYIL-5369). Human-readable representation of the payment instrument for display in withdrawal flows. |
| R16 | KeyVersion | int | CODE-BACKED | Encryption key version used for card data (added Jul 2023, PAYIL-6869). Used by PCI key rotation logic to identify which encryption generation secured this record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID | Billing.Funding | Lookup | Filters Billing.Funding by FundingTypeID |
| @FundingTypeID | Dictionary.FundingType | JOIN | JOINed to apply IsNewStyle=1 and IsSingleFunding=0 filters |
| @FundingData | Billing.FundingHash (function) | Function call | Hash of @FundingData compared against stored FundingHash column |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| FundingUser (DB role) | EXECUTE | Permission | Called by the Billing/Funding application service to check for existing payment instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingGetByData (procedure)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
└── Billing.FundingHash (function)
      └── Billing.OrderedSmallCaseFundingHash (function)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Main data source - SELECTed with FundingTypeID + FundingHash filters |
| Dictionary.FundingType | Table | JOINed to filter IsNewStyle=1 AND IsSingleFunding=0 |
| Billing.FundingHash | Scalar Function | Called to compute canonical hash of @FundingData for WHERE clause comparison |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing/Funding application service | External | Calls to find existing payment instrument by data - core deduplication lookup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses SET NOCOUNT ON. WITH (NOLOCK) on both joined tables. No transaction, no DML. Results ordered by FundingID DESC (PAYIL-7794 fix, Dec 2023).

---

## 8. Sample Queries

### 8.1 Find a credit card funding record by XML data

```sql
-- Simulate what the application does to find an existing CC funding
DECLARE @FundingData VARCHAR(MAX) = '<Funding><FundingType>1</FundingType><Hash>abc123</Hash></Funding>';
EXEC [Billing].[FundingGetByData]
    @FundingTypeID = 1,  -- CreditCard
    @FundingData = @FundingData;
```

### 8.2 Inspect the funding type constraints that gate this lookup

```sql
SELECT FundingTypeID, Name, IsNewStyle, IsSingleFunding
FROM [Dictionary].[FundingType] WITH (NOLOCK)
WHERE IsNewStyle = 1 AND IsSingleFunding = 0
ORDER BY FundingTypeID;
-- Only these types are searchable via FundingGetByData
```

### 8.3 Inspect the FundingHash computed column for a funding record

```sql
SELECT TOP 10
    FundingID,
    FundingTypeID,
    FundingHash,
    DateCreated,
    IsBlocked
FROM [Billing].[Funding] WITH (NOLOCK)
WHERE FundingTypeID = 1  -- CreditCard
ORDER BY FundingID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-5369 (Nov 2022) | Jira | Added PaymentDetails column to SELECT list |
| PAYIL-6869 (Jul 2023) | Jira | Added KeyVersion column to SELECT list |
| PAYIL-7794 (Dec 2023) | Jira | Added ORDER BY FundingID DESC to fix staging duplicate issue |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 3 Jira (from code comments) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingGetByData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingGetByData.sql*
