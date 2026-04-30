# Billing.OrderedFundingHash

> Schema-bound scalar function that computes an MD5 hash of an XML funding data structure after sorting its child elements alphabetically by tag name, producing an order-independent fingerprint for duplicate detection.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns char(32) - MD5 hash as hex string |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.OrderedFundingHash produces a deterministic 32-character MD5 fingerprint of a funding payment data XML document by first normalizing the XML element order (sorting children alphabetically) before hashing. This normalization ensures that the same funding details produce the same hash regardless of what order the XML elements appear in, enabling reliable duplicate detection across payment transactions.

This function exists to detect duplicate funding requests. Payment data passed to eToro's billing system arrives as XML, and the same payment details might appear with elements in different orders across different calls or systems. Without normalizing the order first, two identical payments would produce different hashes. The sorted hash allows `Billing.Funding` and related tables to compare funding payloads for idempotency.

The function is WITH SCHEMABINDING (unlike most Billing functions) - meaning it can be used in persisted computed columns and indexed views, which is the case: `Billing.Funding` uses it (or the lowercase variant) as a computed hash column.

---

## 2. Business Logic

### 2.1 XQuery Sort-Then-Hash Algorithm

**What**: Normalizes XML element order using XQuery FLWOR expression, then hashes the result as MD5.

**Columns/Parameters Involved**: `@Data`

**Rules**:
- Step 1: XQuery reorder - `@Data.query('<Funding>{for $fund in Funding/* order by local-name($fund) return $fund}</Funding>')` sorts all direct children of `<Funding>` alphabetically by their local tag name. Nested content within each child is preserved as-is.
- Step 2: Convert sorted XML to nvarchar(max) string.
- Step 3: Apply MD5 hash via hashbytes('MD5', ...).
- Step 4: Convert binary hash result to char(32) hex string.
- The resulting hash is case-sensitive (uppercase hex) - use `OrderedSmallCaseFundingHash` for case-insensitive comparison.

**Diagram**:
```
Input XML (elements in any order):
  <Funding><CardNumber>1234</CardNumber><Amount>100</Amount><Currency>USD</Currency></Funding>

After XQuery sort (alphabetical by tag name):
  <Funding><Amount>100</Amount><CardNumber>1234</CardNumber><Currency>USD</Currency></Funding>

MD5 hash -> char(32): e.g., "A3F1D2E8B7C9F0A1234567890ABCDEF1"

Different original order, same data:
  <Funding><Amount>100</Amount><Currency>USD</Currency><CardNumber>1234</CardNumber></Funding>
After sort: same normalized XML -> same hash
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Data | xml | NO | - | VERIFIED | The funding payment data as XML. Expected structure: `<Funding>` root element with direct child elements representing payment fields (CardNumber, Amount, Currency, etc.). The XQuery expression `Funding/*` selects all direct children. |
| RETURN | char(32) | - | NO | - | VERIFIED | 32-character MD5 hash (hex, uppercase) of the XML after alphabetical element sorting. Two funding payloads with the same content but different element order will produce the same hash. Two payloads with different content (even one field) produce different hashes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure computation - no table access).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Funding | (computed column or trigger) | Caller | Uses this function (or the lowercase variant) to store a hash fingerprint of the funding XML for duplicate detection. |
| Billing.FundingHash | Function | Caller | The public-facing FundingHash function that calls OrderedSmallCaseFundingHash (lowercase variant) as its implementation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (pure formula function with no table access).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Uses hash as a computed/stored fingerprint column for duplicate payment detection. |
| Billing.FundingHash | Function | May call this (case-sensitive variant) as part of hash computation. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | WITH SCHEMABINDING | Schema-bound - enables use in persisted computed columns and indexed views. Objects this function depends on cannot be altered without first dropping or altering this function. |
| Hash algorithm | Note | Uses MD5 (128-bit, 32 hex chars). MD5 is not cryptographically secure but is fast and sufficient for duplicate detection / fingerprinting use cases. |
| Case sensitivity | Note | Returns uppercase hex. For case-insensitive comparison, use `OrderedSmallCaseFundingHash` which applies LOWER() before hashing. |

---

## 8. Sample Queries

### 8.1 Compute hash for a sample funding XML

```sql
DECLARE @xml XML = '<Funding><Amount>100</Amount><Currency>USD</Currency><CardNumber>1234</CardNumber></Funding>';
SELECT Billing.OrderedFundingHash(@xml) AS FundingHash;
```

### 8.2 Verify order-independence (two different orderings produce same hash)

```sql
DECLARE @xml1 XML = '<Funding><Amount>100</Amount><CardNumber>1234</CardNumber></Funding>';
DECLARE @xml2 XML = '<Funding><CardNumber>1234</CardNumber><Amount>100</Amount></Funding>';
SELECT
    Billing.OrderedFundingHash(@xml1) AS Hash1,
    Billing.OrderedFundingHash(@xml2) AS Hash2;
-- Hash1 and Hash2 should be identical
```

### 8.3 Compare case-sensitive vs lowercase hash

```sql
DECLARE @xml XML = '<Funding><Amount>100</Amount><Currency>USD</Currency></Funding>';
SELECT
    Billing.OrderedFundingHash(@xml) AS CaseSensitiveHash,
    Billing.OrderedSmallCaseFundingHash(@xml) AS LowercaseHash;
-- Different results due to LOWER() applied in the lowercase variant
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.OrderedFundingHash | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.OrderedFundingHash.sql*
