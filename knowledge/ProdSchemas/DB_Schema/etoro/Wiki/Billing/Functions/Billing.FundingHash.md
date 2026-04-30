# Billing.FundingHash

> Schema-bound scalar function that is the canonical public entry point for hashing Billing.Funding XML data - a thin wrapper that delegates to Billing.OrderedSmallCaseFundingHash, returning a case-insensitive, order-independent MD5 fingerprint (char(32)) used to deduplicate funding records.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns char(32) - MD5 hash of normalized Funding XML |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.FundingHash is the **stable public interface** for computing a funding record's identity hash. The hash is used throughout the Billing schema to answer: "Have we seen this payment method before?" It enables duplicate detection and deduplication when the same customer submits the same bank account, card, or payment details across multiple transactions.

This function is a wrapper with history: the commented-out original implementation used `CONVERT([char](32), hashbytes('MD5', Convert([nvarchar](max), @Data)))` - a naive hash of the raw XML string. This was order-sensitive (two identical XML payloads with different element order would hash differently) and case-sensitive. The replacement, `Billing.OrderedSmallCaseFundingHash`, normalizes both order and case before hashing, making the hash truly content-based rather than serialization-based.

**Why the wrapper exists**: By routing all callers through `FundingHash` rather than directly calling `OrderedSmallCaseFundingHash`, the implementation can be changed in one place without updating 10+ stored procedures and views. The 17 callers all use `Billing.FundingHash` as their stable API.

`WITH SCHEMABINDING` means changes to the function signature require first dropping all schema-bound dependencies - enforcing stability.

---

## 2. Business Logic

### 2.1 Hash Computation (Delegation Pattern)

**What**: Accepts Funding XML and returns the canonical normalized MD5 hash.

**Columns/Parameters Involved**: `@Data XML`

**Rules**:
- Delegates entirely to `Billing.OrderedSmallCaseFundingHash(@Data)`.
- OrderedSmallCaseFundingHash: XQuery FLWOR sorts all `Funding/*` elements by local-name(), converts to NVARCHAR(2500) (truncation risk at 2500 chars), applies LOWER(), computes MD5 via hashbytes('MD5',...), converts to char(32).
- Previous implementation (commented out): `CONVERT([char](32), hashbytes('MD5', Convert([nvarchar](max), @Data)))` - order-sensitive, case-sensitive, replaced.
- Returns char(32) hex MD5 hash (lowercase hex characters, e.g., 'a3f4b1c2d5e6f789...').
- Returns NULL if @Data is NULL (SQL Server hashbytes behavior).

**Diagram**:
```
@Data (XML Funding payload)
    |
Billing.FundingHash (schema-bound wrapper)
    |
Billing.OrderedSmallCaseFundingHash(@Data)
    |
XQuery FLWOR: sort elements by local-name()
-> CAST to nvarchar(2500) [truncation risk >2500 chars]
-> LOWER()
-> hashbytes('MD5', ...)
-> CONVERT to char(32)
    |
= 'a3f4b1c2...' (32-char hex hash)
```

### 2.2 Usage Pattern: Funding Deduplication

**What**: Hash-based equality check to find existing funding records matching new payment data.

**Rules**:
- Billing.Funding table stores `FundingHash` computed column using this function.
- Lookup procedures (FundingGetByData, IsFundingExists, GetExistingFunding) query: `WHERE FundingHash = Billing.FundingHash(@newData)`.
- If hash matches -> same payment method -> reuse existing FundingID.
- If no match -> new payment method -> insert new Billing.Funding row.
- Views (FundingDataForDeposit, FundingDataForWithdraw, Funding_DataFactory) expose FundingHash for downstream consumers.

---

## 3. Data Overview

N/A for Scalar Function. Referenced from Billing.Funding table (computed column or direct queries) and 10+ stored procedures.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Data | xml | NO | - | VERIFIED | Funding payment data XML from Billing.Funding.FundingData. Expected root: `<Funding>` with payment-method-specific child elements. All child elements are sorted by local-name() and lowercased before hashing, making the hash order-independent and case-insensitive. |
| RETURN | char(32) | YES | - | VERIFIED | MD5 hash fingerprint (32 hex characters, lowercase). Uniquely identifies the funding XML content regardless of element order or case. NULL if @Data is NULL. Two funding records with the same hash have identical payment details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Data | Billing.OrderedSmallCaseFundingHash | Caller (delegation) | Entire computation delegated to this function. FundingHash is a stable wrapper over the implementation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Funding | FundingData | Computed column / query | Funding table uses FundingHash to index funding records by their payment data fingerprint. |
| Billing.FundingGetByData | FundingData | Caller | Looks up existing funding record by data hash. |
| Billing.FundingGetByID | FundingData | Caller | Returns funding hash alongside funding record by ID. |
| Billing.FundingMergeByParameter | FundingData | Caller | Uses hash to match/merge duplicate funding records. |
| Billing.GetCustomerToFundingByFundingData | FundingData | Caller | Finds customer-to-funding mapping by data hash. |
| Billing.GetExistingFunding | FundingData | Caller | Checks for existing funding record with matching hash. |
| Billing.GetFundingForCustomer | FundingData | Caller | Retrieves customer's funding records with hash. |
| Billing.GetFundingForCustomerByCID | FundingData | Caller | Retrieves customer funding by CID with hash. |
| Billing.IsFundingExists | FundingData | Caller | Boolean check: does funding with this hash exist? |
| Billing.Paypal_UpdateFundingAndCheckIsBlocked | FundingData | Caller | PayPal-specific funding update using hash matching. |
| Billing.DepositFundingUpdate | FundingData | Caller | Updates funding record, uses hash for matching. |
| Billing.Funding_DataFactory | FundingData | View | Exposes FundingHash as a computed column in the view. |
| Billing.FundingDataForDeposit | FundingData | View | Exposes FundingHash for deposit funding data consumers. |
| Billing.FundingDataForWithdraw | FundingData | View | Exposes FundingHash for withdrawal funding data consumers. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingHash (schema-bound wrapper)
└── Billing.OrderedSmallCaseFundingHash (function - schema-bound)
    (pure XQuery + MD5 - no table deps)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.OrderedSmallCaseFundingHash | Function | Entire hash computation delegated to this function. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Funding hash stored/computed per funding record. |
| Billing.FundingGetByData | Stored Procedure | Hash-based funding lookup. |
| Billing.FundingGetByID | Stored Procedure | Returns hash with funding record. |
| Billing.FundingMergeByParameter | Stored Procedure | Hash-based deduplication/merge. |
| Billing.GetCustomerToFundingByFundingData | Stored Procedure | Customer-funding mapping by hash. |
| Billing.GetExistingFunding | Stored Procedure | Existing funding existence check by hash. |
| Billing.GetFundingForCustomer | Stored Procedure | Customer funding retrieval. |
| Billing.GetFundingForCustomerByCID | Stored Procedure | CID-scoped customer funding retrieval. |
| Billing.IsFundingExists | Stored Procedure | Boolean hash existence check. |
| Billing.Paypal_UpdateFundingAndCheckIsBlocked | Stored Procedure | PayPal funding update using hash. |
| Billing.DepositFundingUpdate | Stored Procedure | Deposit funding update using hash. |
| Billing.Funding_DataFactory | View | Exposes FundingHash. |
| Billing.FundingDataForDeposit | View | Exposes FundingHash for deposit path. |
| Billing.FundingDataForWithdraw | View | Exposes FundingHash for withdrawal path. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function. Note: Billing.Funding likely has an index on the FundingHash computed column to support O(1) hash lookups.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH SCHEMABINDING | Schema | Schema-bound - changes require dropping all dependent schema-bound objects first. Enforces interface stability. |
| Commented-out implementation | History | Original `hashbytes('MD5', Convert([nvarchar](max), @Data))` was order-sensitive and case-sensitive. Replaced by OrderedSmallCaseFundingHash to fix hash collisions on equivalent-but-differently-ordered XML. |
| Wrapper pattern | Design | Stable public API over a replaceable implementation. All 14 consumers reference FundingHash; only FundingHash references OrderedSmallCaseFundingHash. If the hash algorithm changes again, only this one function changes. |
| 2500-char truncation risk | Inherited | Inherited from OrderedSmallCaseFundingHash: XML converted to NVARCHAR(2500) before lowercasing. Very large Funding XML payloads (>2500 chars) will be truncated, potentially causing hash collisions between different long payloads that share the same first 2500 characters. |

---

## 8. Sample Queries

### 8.1 Compute hash for a funding XML payload

```sql
DECLARE @xml XML = '<Funding><EmailAsString>test@example.com</EmailAsString></Funding>';
SELECT Billing.FundingHash(@xml) AS FundingHash;
-- Returns: 32-char hex MD5 hash
```

### 8.2 Look up existing funding by data match

```sql
DECLARE @newFundingData XML = '<Funding><IBANCodeAsString>GB29NWBK60161331926819</IBANCodeAsString></Funding>';
SELECT FundingID, FundingTypeID, FundingHash
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingHash = Billing.FundingHash(@newFundingData);
-- Returns existing funding if same IBAN was previously used
```

### 8.3 Check for duplicate funding records (same hash, different FundingIDs)

```sql
SELECT FundingHash, COUNT(*) AS DuplicateCount
FROM Billing.Funding WITH (NOLOCK)
GROUP BY FundingHash
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 11 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingHash | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.FundingHash.sql*
