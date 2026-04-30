# Billing.OrderedSmallCaseFundingHash

> Schema-bound scalar function that computes a case-insensitive MD5 hash of XML funding data by sorting child elements alphabetically and lowercasing the result before hashing - the lowercase variant of OrderedFundingHash, used by Billing.FundingHash.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns char(32) - MD5 hash as lowercase hex string |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.OrderedSmallCaseFundingHash is the case-insensitive variant of `Billing.OrderedFundingHash`. It produces the same order-normalized MD5 fingerprint but applies `LOWER()` to the sorted XML string before hashing, making the hash independent of character case in XML element names or values. This is the variant called by `Billing.FundingHash` - the public-facing hash function used in the funding duplicate detection pipeline.

The lowercase normalization matters when funding XML may arrive with mixed case - for example, `<amount>` vs `<Amount>` would produce the same hash from this function but different hashes from `OrderedFundingHash`. Using the lowercase version as the stored hash column value in `Billing.Funding` ensures robustness against case variations in payment provider XML responses.

The function is WITH SCHEMABINDING (like its case-sensitive counterpart), enabling use in persisted computed columns.

---

## 2. Business Logic

### 2.1 XQuery Sort + Lowercase + Hash Algorithm

**What**: Same as OrderedFundingHash but adds LOWER() before hashing, plus uses nvarchar(2500) cast instead of nvarchar(max).

**Columns/Parameters Involved**: `@Data`

**Rules**:
- Step 1: XQuery sort - `@Data.query('<Funding>{for $fund in Funding/* order by local-name($fund) return $fund}</Funding>')` - identical to OrderedFundingHash.
- Step 2: CAST to nvarchar(2500) then LOWER() - note the 2500-char limit (vs nvarchar(max) in OrderedFundingHash). XML payloads larger than 2500 chars will be truncated before hashing.
- Step 3: MD5 hash + char(32) hex conversion.
- The 2500-char truncation is a potential risk if funding XML can exceed this length - larger payloads would have the same hash as their first 2500 characters.

**Diagram**:
```
Input XML:
  <Funding><CardNumber>1234</CardNumber><Amount>100</Amount></Funding>

After XQuery sort:
  <Funding><Amount>100</Amount><CardNumber>1234</CardNumber></Funding>

After LOWER() + CAST to nvarchar(2500):
  <funding><amount>100</amount><cardnumber>1234</cardnumber></funding>

MD5 hash -> char(32): "d4f2a1b3c8e9f0a12345678901abcdef" (lowercase hex)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Data | xml | NO | - | VERIFIED | Funding payment data as XML. Expected root element: `<Funding>` with direct child elements. Same structure as OrderedFundingHash. Effective payload limit: ~2500 characters after XML serialization (CAST to nvarchar(2500) truncates larger payloads). |
| RETURN | char(32) | - | NO | - | VERIFIED | 32-character MD5 hash of the lowercase, alphabetically-sorted XML. Case-insensitive: `<Amount>100</Amount>` and `<amount>100</amount>` produce the same hash. Order-independent: same elements in any order produce the same hash. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure computation - no table access).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.FundingHash | @Data | Caller | Primary consumer - calls this function to compute the lowercase hash used for funding duplicate detection. |
| Billing.Funding | (computed column) | Caller | Uses this function (via FundingHash) to store a normalized hash of funding XML. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (pure formula function with no table access).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingHash | Function | Calls this as its implementation - FundingHash is the public API, this is the implementation. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | WITH SCHEMABINDING | Schema-bound - enables use in persisted computed columns. |
| nvarchar(2500) limit | Risk | Unlike OrderedFundingHash (uses nvarchar(max)), this function casts to nvarchar(2500) before LOWER(). XML payloads exceeding 2500 characters will be silently truncated, potentially causing hash collisions on distinct-but-long funding records. |
| Case normalization | Note | LOWER() is applied AFTER the XQuery sort - element names are case-normalized before hashing. |

---

## 8. Sample Queries

### 8.1 Compute the lowercase hash for a sample funding XML

```sql
DECLARE @xml XML = '<Funding><Amount>100</Amount><Currency>USD</Currency></Funding>';
SELECT Billing.OrderedSmallCaseFundingHash(@xml) AS LowercaseHash;
```

### 8.2 Verify case-insensitivity

```sql
DECLARE @xml1 XML = '<Funding><Amount>100</Amount></Funding>';
DECLARE @xml2 XML = '<Funding><amount>100</amount></Funding>';
SELECT
    Billing.OrderedSmallCaseFundingHash(@xml1) AS Hash1,
    Billing.OrderedSmallCaseFundingHash(@xml2) AS Hash2;
-- Should produce the same hash (LOWER normalizes tag names)
```

### 8.3 Trace through FundingHash -> this function

```sql
-- FundingHash calls this function internally
DECLARE @xml XML = '<Funding><CardNumber>4111</CardNumber><Amount>500</Amount></Funding>';
SELECT
    Billing.OrderedSmallCaseFundingHash(@xml) AS DirectCall,
    Billing.FundingHash(@xml) AS ViaFundingHash;
-- Should produce identical results
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.OrderedSmallCaseFundingHash | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.OrderedSmallCaseFundingHash.sql*
