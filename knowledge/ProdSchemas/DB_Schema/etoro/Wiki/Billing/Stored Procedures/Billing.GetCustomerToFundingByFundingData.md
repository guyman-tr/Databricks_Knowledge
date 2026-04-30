# Billing.GetCustomerToFundingByFundingData

> Resolves a payment instrument and its customer links by hashing @fundingData XML (via Billing.FundingHash()) and matching against Billing.Funding.FundingHash - returns FundingID, block status, and all customer CIDs linked to it. Used for payment instrument deduplication and fraud/block-status lookup. Created PAYUA-2518.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @fundingTypeID + @fundingData (hashed to FundingHash) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerToFundingByFundingData` answers: "Does this payment instrument already exist in the system, and if so, who uses it and is it blocked?" It takes the raw payment data (card details, bank account info, etc.) as XML text, computes its canonical hash using the `Billing.FundingHash()` scalar function, and looks up any matching Funding records.

This is the primary deduplication check for payment instruments: when a customer adds a payment method, the system uses this procedure to determine if the same card/account already exists (registered by this or another customer), allowing it to either reuse the existing FundingID or detect a suspicious shared instrument.

The procedure returns one row per (FundingID, CID) combination - allowing the caller to see:
- Whether the funding instrument is globally blocked (`IsFundingBlocked`).
- Whether the per-customer link is blocked (`IsCustomerToFundingBlocked`).
- Which customers are linked to this instrument.

Filters `Dictionary.FundingType.IsNewStyle=1 AND IsSingleFunding=0` - only applies to modern multi-customer funding types (not legacy single-customer or TestDeposit types).

Created by Maksym S., 2021-09-09, PAYUA-2518.

---

## 2. Business Logic

### 2.1 Hash-Based Instrument Lookup

**What**: Converts @fundingData XML to a canonical hash using Billing.FundingHash() and finds matching Funding records.

**Columns/Parameters Involved**: `@fundingData`, `@fundingTypeID`, `Billing.Funding.FundingHash`, `Billing.FundingHash()` function

**Rules**:
- `BFUN.FundingHash = Billing.FundingHash(Convert(XML, @fundingData))`: The core comparison - converts the input @fundingData string to XML, then computes the canonical hash using the `Billing.FundingHash()` scalar function. Matches against the pre-computed hash stored on the Billing.Funding row.
- `BFUN.FundingTypeID = @fundingTypeID`: Further constrains to the specific payment method type (e.g., FundingTypeID=1 for credit cards).
- `DFNT.IsNewStyle = 1`: Only "new style" payment types eligible (filters out legacy payment types).
- `DFNT.IsSingleFunding = 0`: Excludes single-funding types (e.g., TestDeposit/FundingTypeID=18 has IsSingleFunding=true). Single-funding types are global/shared instruments not deduplicable per customer.
- `LEFT JOIN Billing.CustomerToFunding BCTF ON BFUN.FundingID = BCTF.FundingID`: Finds all customers linked to the matched funding instrument. LEFT JOIN means a FundingID with no customer links is still returned (CID=NULL in that case).
- `SELECT DISTINCT`: Prevents duplicate rows if the same (FundingID, CID) link is recorded multiple times.

**Diagram**:
```
@fundingData (XML string) + @fundingTypeID
     |
     | Billing.FundingHash(Convert(XML, @fundingData))
     v
Computed hash
     |
Dictionary.FundingType WHERE FundingTypeID=@fundingTypeID AND IsNewStyle=1 AND IsSingleFunding=0
     |
JOIN Billing.Funding WHERE FundingHash = computed_hash AND FundingTypeID = @fundingTypeID
     |
LEFT JOIN Billing.CustomerToFunding ON FundingID
     |
SELECT DISTINCT FundingID, IsFundingBlocked, CID, IsCustomerToFundingBlocked
(one row per CID for the matched FundingID; CID=NULL if no customers linked)
```

### 2.2 Block Status Reporting

**What**: Returns both the global funding block status and per-customer block status for matched instruments.

**Rules**:
- `BFUN.IsBlocked AS IsFundingBlocked`: True if the funding instrument is globally blocked (for ALL customers). Set by `Billing.FundingBlock`.
- `BCTF.IsBlocked AS IsCustomerToFundingBlocked`: True if the per-customer link is blocked specifically for that CID. Can be blocked independently of the global funding block.
- A non-null CID with both values = false indicates a fully active customer-instrument link.
- A non-null CID with IsFundingBlocked=true: the global instrument is blocked - this CID cannot use it.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fundingTypeID | INT | NO | - | CODE-BACKED | Payment method type to check. Filters Billing.Funding.FundingTypeID AND Dictionary.FundingType (IsNewStyle=1 AND IsSingleFunding=0 required). |
| 2 | @fundingData | NVARCHAR(1000) | NO | - | CODE-BACKED | Payment instrument data as XML string. Passed to Billing.FundingHash(Convert(XML, @fundingData)) to compute the canonical hash for lookup. For credit cards: contains card number, expiry, etc. |

**Returns** (SELECT DISTINCT output):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | FundingID | INT | NO | CODE-BACKED | Primary key of the matched Billing.Funding record. The canonical FundingID for this payment instrument in the system. |
| 2 | IsFundingBlocked | BIT | YES | CODE-BACKED | Global block status of the funding instrument. True if blocked for all customers via Billing.FundingBlock. |
| 3 | CID | INT | YES | CODE-BACKED | Customer ID linked to this FundingID via Billing.CustomerToFunding. NULL if no customers are linked (LEFT JOIN). Multiple rows returned if multiple customers share this instrument. |
| 4 | IsCustomerToFundingBlocked | BIT | YES | CODE-BACKED | Per-customer block status. True if this specific CID's link to the FundingID is blocked. NULL if CID is NULL (no customer link). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID, IsNewStyle, IsSingleFunding | Dictionary.FundingType | JOIN (type validation filter) | Validates that @fundingTypeID is a new-style multi-customer type |
| FundingHash, FundingTypeID, IsBlocked | Billing.Funding | JOIN (hash lookup) | Finds matching funding instrument by computed hash |
| FundingID, CID, IsBlocked | Billing.CustomerToFunding | LEFT JOIN | Finds all customer links for the matched funding instrument |
| (implicit) @fundingData | Billing.FundingHash() | Scalar function call | Computes canonical hash of XML funding data for comparison |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | EXECUTE (implicit) | Runtime caller | No explicit EXECUTE grant found in UsersPermissions; called via service DB user (likely deposit/payment service) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerToFundingByFundingData (procedure)
├── Dictionary.FundingType (table - type validation)
├── Billing.Funding (table - hash match lookup)
├── Billing.CustomerToFunding (table - customer links)
└── Billing.FundingHash() (scalar function - hash computation)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | JOIN to validate IsNewStyle=1 AND IsSingleFunding=0 for @fundingTypeID |
| Billing.Funding | Table | JOIN on FundingHash = Billing.FundingHash(@fundingData) AND FundingTypeID = @fundingTypeID |
| Billing.CustomerToFunding | Table | LEFT JOIN to retrieve CID and IsBlocked for all customer links |
| Billing.FundingHash() | Scalar Function | Called inline to compute hash of XML @fundingData |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo. Called by application services via their own DB users.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| FundingHash lookup | The matching relies on Billing.FundingHash() producing identical hashes for equivalent payment data. Normalization in the hash function is critical for deduplication accuracy. |
| IsNewStyle=1 AND IsSingleFunding=0 | TestDeposit (FundingTypeID=18) has IsSingleFunding=true and would be filtered out. Legacy types with IsNewStyle=false also excluded. |
| NOLOCK on all tables | Dictionary.FundingType, Billing.Funding, and Billing.CustomerToFunding all read with NOLOCK. |
| SELECT DISTINCT | Prevents duplicate rows; necessary if multiple Billing.CustomerToFunding rows exist per (FundingID, CID). |
| XML conversion | `Convert(XML, @fundingData)` converts the NVARCHAR input to XML type before hashing. Malformed XML will cause a conversion error. |

---

## 8. Sample Queries

### 8.1 Check if a credit card already exists in the system

```sql
-- Returns existing FundingID and all linked customers if card already registered
EXEC [Billing].[GetCustomerToFundingByFundingData]
    @fundingTypeID = 1,  -- CreditCard
    @fundingData = N'<Funding><CardNumberAsString>4111111111111111</CardNumberAsString><ExpiryMonth>12</ExpiryMonth><ExpiryYear>2026</ExpiryYear></Funding>'
-- Empty: card not in system (safe to register as new)
-- Non-empty: card exists; check IsFundingBlocked before allowing use
```

### 8.2 Get the hash for a funding instrument directly

```sql
-- See what hash would be computed:
SELECT [Billing].[FundingHash](Convert(XML, N'<Funding>...</Funding>')) AS ComputedHash
```

---

## 9. Atlassian Knowledge Sources

Jira ticket referenced in DDL comment:
- **PAYUA-2518** (2021-09-09, Maksym S.): Initial version - funding data lookup for payment instrument management in Ukraine-related payment flows.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 1 Jira (from DDL comment) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerToFundingByFundingData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerToFundingByFundingData.sql*
