# Billing.GetExistingFunding

> Checks whether a funding method with identical data (same hash) already exists in the system for a given funding type, and returns its validity and block status to prevent duplicate funding registrations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @fundingTypeID + @fundingData (hash match) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Before a customer registers a new payment method (credit card, bank account, etc.), the system checks whether that exact payment method has already been registered - either by this customer or by another. This prevents duplicate funding records and enables reuse of existing fundings.

The procedure uses a cryptographic hash (Billing.FundingHash) computed from the XML funding data to find an existing Billing.Funding record with identical details. It then evaluates whether that existing funding can be used for the current customer by checking three independent block conditions: whether the customer-specific link is blocked (CidBlocked), whether the funding is system-wide blocked (SystemBlocked), and whether a third party (another CID) already has an active claim on this funding (IsThirdParty).

Only "IsNewStyle" and non-single-use funding types are searched, reflecting the modern funding registration system (as opposed to legacy single-use payment tokens).

---

## 2. Business Logic

### 2.1 Funding Deduplication via Hash

**What**: Uses a deterministic hash of the XML funding data to detect identical payment methods already registered.

**Columns/Parameters Involved**: `@fundingData`, `@fundingTypeID`

**Rules**:
- `Billing.FundingHash(Convert(XML, @fundingData))` computes a hash over the funding XML
- Matched against `Billing.Funding.FundingHash` to find existing records
- `Dictionary.FundingType.IsNewStyle = 1` - only searches modern (non-legacy) funding types
- `Dictionary.FundingType.IsSingleFunding = 0` - excludes single-use funding tokens; only reusable methods are searched
- The same physical card/account can be registered once per type

### 2.2 Multi-dimensional Validity Assessment

**What**: IsValid combines three independent block conditions to determine whether the found funding can actually be used.

**Columns/Parameters Involved**: `CidBlocked`, `SystemBlocked`, `IsThirdParty`, `IsValid`

**Rules**:
- `CidBlocked` (IsRefundExcluded from CustomerToFunding): The customer's own link to this funding is blocked for refunds/withdrawals
- `SystemBlocked` (IsRefundExcluded from Funding): The funding method is globally blocked system-wide (e.g., fraud, AML)
- `IsThirdParty`: A different CID has a BackOffice.CustomerToThirdPartyFundings claim on this funding for @CID
- `IsValid = 1` only when ALL conditions are absent: CidBlocked=0, SystemBlocked=0, IsThirdParty IS NULL
- IsValid is cast as BIT

**Diagram**:
```
IsValid = 1 (can use) WHEN:
  CidBlocked = 0 (customer not blocked on this funding)
  AND SystemBlocked = 0 (funding not globally blocked)
  AND IsThirdParty IS NULL (no third-party claim exists)

IsValid = 0 (cannot use) WHEN any of:
  CidBlocked = 1  -> Customer's refund access blocked
  SystemBlocked = 1 -> Funding globally suspended
  IsThirdParty IS NOT NULL -> Another CID has this funding locked
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fundingTypeID | INT | NO | - | CODE-BACKED | Payment method type to search within. Lookup: Dictionary.FundingType. Only "IsNewStyle=1, IsSingleFunding=0" types are searched for deduplication. |
| 2 | @fundingData | NVARCHAR(1000) | NO | - | CODE-BACKED | XML string containing the funding details (card number, IBAN, etc.). Converted to XML and hashed via Billing.FundingHash() to match against existing Billing.Funding.FundingHash entries. |
| 3 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used to check the customer-specific CustomerToFunding record (CidBlocked) and to detect third-party claims via BackOffice.CustomerToThirdPartyFundings. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | Primary key of the matched existing Billing.Funding record. NULL if no matching funding was found (empty result set). |
| R2 | CID | INT | YES | NULL | CODE-BACKED | The customer ID from CustomerToFunding for this funding. May differ from @CID if a different customer registered this funding first. |
| R3 | CidBlocked | BIT | YES | NULL | CODE-BACKED | CustomerToFunding.IsRefundExcluded for @CID. 1 = this customer's refund/withdrawal access to this funding is blocked. NULL if @CID has no CustomerToFunding link (funding belongs to another customer). |
| R4 | SystemBlocked | BIT | YES | NULL | CODE-BACKED | Billing.Funding.IsRefundExcluded. 1 = the funding method is globally blocked across all customers (e.g., fraud, compliance). |
| R5 | IsThirdParty | INT | YES | NULL | CODE-BACKED | The CID from BackOffice.CustomerToThirdPartyFundings if a third party has an active claim on this funding for @CID. NOT NULL means another customer has locked this funding. NULL means no third-party restriction. |
| R6 | IsValid | BIT | NO | - | CODE-BACKED | Computed validity: 1 = the existing funding can be used by this customer (no blocks, no third-party claim). 0 = cannot use this funding due to one or more block conditions. CAST(CASE WHEN CidBlocked=1 THEN 0 WHEN SystemBlocked=1 THEN 0 WHEN IsThirdParty IS NOT NULL THEN 0 ELSE 1 END AS BIT). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fundingTypeID | Dictionary.FundingType | JOIN | Validates IsNewStyle=1 and IsSingleFunding=0 |
| FundingHash | Billing.Funding | JOIN | Hash-based match to find existing funding |
| @CID | Billing.CustomerToFunding | LEFT JOIN | Customer-specific block status |
| FundingID + @CID | BackOffice.CustomerToThirdPartyFundings | LEFT JOIN | Third-party claim detection |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment services (funding registration flow) | @fundingData + @fundingTypeID | EXEC | Called before creating a new funding to check for duplicates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExistingFunding (procedure)
├── Dictionary.FundingType (table)
├── Billing.Funding (table)
├── Billing.CustomerToFunding (table)
└── BackOffice.CustomerToThirdPartyFundings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | JOIN - filter IsNewStyle=1, IsSingleFunding=0 |
| Billing.Funding | Table | JOIN on FundingTypeID + FundingHash match |
| Billing.CustomerToFunding | Table | LEFT JOIN - CidBlocked (IsRefundExcluded) for @CID |
| BackOffice.CustomerToThirdPartyFundings | Table | LEFT JOIN - third-party claim detection |
| Billing.FundingHash | Function | Compute hash of @fundingData XML for deduplication |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application funding registration flow. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if a funding already exists before registering

```sql
EXEC Billing.GetExistingFunding
    @fundingTypeID = 1,           -- Credit card
    @fundingData = '<Funding>...</Funding>',
    @CID = 1234567;
-- IsValid=1 means existing funding is reusable
-- Empty result means no duplicate - safe to create new
```

### 8.2 Inspect the FundingHash function output directly

```sql
SELECT Billing.FundingHash(CONVERT(XML, '<Funding><CardNumber>4111111111111111</CardNumber></Funding>'));
```

### 8.3 Check all existing fundings for a type with their block status

```sql
SELECT f.FundingID, f.FundingHash, f.IsRefundExcluded AS SystemBlocked,
       ctf.IsRefundExcluded AS CidBlocked, ctf.CID
FROM Billing.Funding f WITH (NOLOCK)
LEFT JOIN Billing.CustomerToFunding ctf WITH (NOLOCK) ON f.FundingID = ctf.FundingID
WHERE f.FundingTypeID = 1
ORDER BY f.FundingID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetExistingFunding | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExistingFunding.sql*
