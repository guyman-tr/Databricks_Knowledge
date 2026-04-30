# Billing.fn_GetCCDepotCountryId

> Inline table-valued function that resolves a CountryID from a card BIN code and customer CID, with American regulation override: US-regulated customers always return CountryID=219 (US) regardless of BIN, while other customers get the BIN's mapped country (or 0 if unmapped).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns single-column table: CountryID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.fn_GetCCDepotCountryId` answers "which country should be used for credit card depot routing for this customer and BIN?" It is a BIN-to-country resolver with a regulatory override: US-regulated customers (identified by `Billing.fn_IsUserFromAmericanRegulation`) always get CountryID=219 (United States) regardless of what country the card BIN maps to. For non-US-regulated customers, the country is derived from `Dictionary.CountryBin` by matching the BIN code.

The function is authored by Shay O. (01/11/2020, PAYUS-1787) and is part of the US payment routing infrastructure. It is consumed by `Billing.GetCCProcessingBundleByBinUS` in an `OUTER APPLY` to determine which depot protocols are eligible based on the card's country, filtering `Billing.ProtocolCountry` by the resolved CountryID.

The American regulation priority reflects a regulatory requirement: for customers under US jurisdiction, the routing must use the US country classification regardless of their card's issuing country. This ensures compliance with US-specific payment processing rules.

---

## 2. Business Logic

### 2.1 American Regulation Override (Priority Rule)

**What**: US-regulated customers always get CountryID=219, overriding the BIN-based lookup.

**Columns/Parameters Involved**: `@CID`, `IsAmerican.flag`, `CountryID`

**Rules**:
- Calls `Billing.fn_IsUserFromAmericanRegulation(@CID)` to check if the customer is under US regulation
- If `IsAmerican.flag = 1`: RETURN CountryID = 219 (United States)
- If `IsAmerican.flag = 0`: RETURN ISNULL(CCB.CountryID, 0)
- The American regulation check is always evaluated (cross-apply semantics in ITVF)
- CountryID=219 is hardcoded as the US country identifier

### 2.2 BIN-to-Country Lookup via Dictionary.CountryBin

**What**: For non-US-regulated customers, the card BIN determines the country.

**Columns/Parameters Involved**: `@BinCode`, `CCB.CountryID`

**Rules**:
- LEFT JOIN Dictionary.CountryBin CCB ON CCB.BinCode = @BinCode
- Dictionary.CountryBin has 16,350,455 rows - a comprehensive BIN database
- If @BinCode matches a record: returns that record's CountryID
- If @BinCode has no match (LEFT JOIN NULL): ISNULL(CCB.CountryID, 0) -> returns 0 (unknown/global)
- CountryID=0 is used as a wildcard in the calling procedure (ProtocolCountry WHERE CountryID IN (GetCountryId.CountryID, 0))

### 2.3 Calling Context - ProtocolCountry Routing Filter

**What**: The resolved CountryID is used to filter eligible payment protocols by country.

**Columns/Parameters Involved**: `CountryID` (returned value)

**Rules**:
- `Billing.GetCCProcessingBundleByBinUS` OUTER APPLYs this function and uses the result in:
  `WHERE GetCountryId.CountryID IN (BPC.CountryID, 0)`
- CountryID=0 matches protocols with no country restriction (wildcard)
- CountryID=219 (US) matches protocols explicitly enabled for the US
- CountryID=N (from BIN) matches protocols enabled for the card's issuing country

---

## 3. Data Overview

N/A for Table-Valued Function. Return examples:

| @BinCode | @CID | IsAmerican | CCB.CountryID | Returned CountryID | Meaning |
|----------|------|-----------|---------------|-------------------|---------|
| 462252 | 12345 (US regulated) | 1 | (any) | 219 | US customer - always route as US regardless of card BIN |
| 100001 | 67890 (non-US) | 0 | 38 | 38 | Non-US customer, BIN maps to CountryID=38 |
| 999999 | 67890 (non-US) | 0 | NULL (no match) | 0 | Non-US customer, unknown BIN -> CountryID=0 (wildcard) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCode | int | NO | - | CODE-BACKED | Card BIN code (first 4-6 digits of card number). Used to look up the issuing country in Dictionary.CountryBin. 16.35M BIN records available for matching. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID. Passed to Billing.fn_IsUserFromAmericanRegulation to check US regulatory status. The only customer-level input to the routing decision. |
| RETURN CountryID | int | NO | 0 | CODE-BACKED | The resolved country identifier for this BIN+CID combination. 219=United States (for US-regulated customers, hardcoded override). 0=unknown/wildcard (BIN not in Dictionary.CountryBin). Any positive integer=the country mapped to this BIN code in Dictionary.CountryBin. Used as a routing filter key against Billing.ProtocolCountry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID -> IsAmerican.flag | Billing.fn_IsUserFromAmericanRegulation | Delegate (function call) | Checks if customer is under US regulatory jurisdiction |
| @BinCode -> CountryID | Dictionary.CountryBin | Lookup (LEFT JOIN on BinCode) | BIN-to-country mapping (16.35M records) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCCProcessingBundleByBinUS | CountryID | Caller (OUTER APPLY) | Uses returned CountryID to filter eligible payment protocols by country for US routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.fn_GetCCDepotCountryId (inline TVF)
├── Billing.fn_IsUserFromAmericanRegulation (function)
└── Dictionary.CountryBin (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.fn_IsUserFromAmericanRegulation | Scalar/TVF Function | Determines if @CID is under US regulation; returns flag=1 if US-regulated |
| Dictionary.CountryBin | Table (cross-schema) | LEFT JOIN on BinCode: resolves card BIN to CountryID; 16.35M rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCCProcessingBundleByBinUS | Stored Procedure | OUTER APPLY to get CountryID for protocol country filtering in US CC routing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for inline TVF. Dictionary.CountryBin has 16,350,455 rows - the BIN lookup should use an index on BinCode for performance. This function is called via OUTER APPLY per payment routing request; performance of the BIN lookup is critical for deposit processing latency.

### 7.2 Constraints

RETURNS TABLE (inline TVF) - not schema-bound. Always returns exactly one row (the CASE expression with LEFT JOIN always produces one result). CountryID=219 hardcoded for US - any change to the US country ID in Dictionary.Country would require DDL update. CountryID=0 used as wildcard - this convention must be consistent with how callers interpret 0 in Billing.ProtocolCountry.

---

## 8. Sample Queries

### 8.1 Get country for a card BIN and customer

```sql
SELECT CountryID
FROM Billing.fn_GetCCDepotCountryId(@BinCode, @CID)
```

### 8.2 Typical calling context (from GetCCProcessingBundleByBinUS)

```sql
SELECT BPC.ProtocolID
FROM Billing.ProtocolCountry BPC WITH (NOLOCK)
OUTER APPLY Billing.fn_GetCCDepotCountryId(@BinCode, @CID) GetCountryId
WHERE GetCountryId.CountryID IN (BPC.CountryID, 0)
```

### 8.3 Test US regulation override

```sql
-- For a US-regulated customer, result should always be 219
SELECT CountryID FROM Billing.fn_GetCCDepotCountryId(999999, @USRegulatedCID)
-- Expected: 219

-- For a non-US customer with known BIN
SELECT CountryID FROM Billing.fn_GetCCDepotCountryId(100001, @NonUSCID)
-- Expected: 38 (from Dictionary.CountryBin sample data)
```

---

## 9. Atlassian Knowledge Sources

Jira ticket PAYUS-1787 referenced in DDL comment (Shay O. 01/11/2020). No additional Confluence sources found.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira (PAYUS-1787 referenced in DDL) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.fn_GetCCDepotCountryId | Type: Inline TVF | Source: etoro/etoro/Billing/Functions/Billing.fn_GetCCDepotCountryId.sql*
