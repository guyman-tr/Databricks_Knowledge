# Billing.GetCountryProtocols

> Returns the ProtocolIDs that are eligible for a specific BIN code based on country-protocol restrictions in Billing.ProtocolCountry. Only returns protocols that have a matching country entry for the BIN's issuing country (unrestricted protocols are excluded). Used by the RoutingUser for CC deposit routing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BinCode |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCountryProtocols` returns which payment protocols are explicitly allowed for a given card's BIN code based on country restrictions. It resolves the BIN to a country (via Dictionary.CountryBin) then returns protocol IDs from `Billing.ProtocolCountry` where that country is listed.

**Important**: Unlike `GetCCProcessingBundle` and related procedures, this SP returns ONLY protocols with explicit country restrictions that match - it does NOT include protocols with no country restriction. The original UNION that would have included unrestricted protocols was removed by Shuky B. (PAYIL-3372, Nov 2021), removing access to `Dictionary.Protocol`.

`ISNULL(CCB.CountryID, 0) IN (BPC.CountryID, 0)` - if the BIN is not found in CountryBin (NULL), it uses 0, which matches `ProtocolCountry` entries with `CountryID=0` (universal/any-country entries).

Created by Shabtay E. 15/06/2021 (PAYUS-3061). Granted to `RoutingUser`.

---

## 2. Business Logic

### 2.1 BIN-to-Country-to-Protocol Resolution

**What**: Resolves BIN -> CountryID -> ProtocolIDs eligible for that country.

**Columns/Parameters Involved**: `@BinCode`, `Dictionary.CountryBin.CountryID`, `Billing.ProtocolCountry.ProtocolID`

**Rules**:
- `INNER JOIN Dictionary.CountryBin ON CCB.BinCode = @BinCode` - gets the country for this BIN
- `WHERE ISNULL(CCB.CountryID, 0) IN (BPC.CountryID, 0)` - matches ProtocolCountry entries where:
  - `BPC.CountryID = CCB.CountryID` (protocol restricted to this BIN's country), OR
  - `BPC.CountryID = 0` (protocol has a "universal" entry with CountryID=0)
- If BIN not found in CountryBin: `CCB.CountryID` is NULL, `ISNULL` converts to 0, matches only CountryID=0 entries
- Returns only ProtocolID - no other columns

### 2.2 Scope Change: Removed Unrestricted Protocol Union (PAYIL-3372)

**What**: Original version included protocols with no country restriction; this was removed.

**Rules**:
- Commented-out UNION: `SELECT P.ProtocolID FROM Dictionary.Protocol P LEFT JOIN ProtocolCountry PC ON P.ProtocolID = PC.ProtocolID WHERE PC.ProtocolID IS NULL`
- This union would have returned protocols not in ProtocolCountry at all (no country restriction)
- Its removal means this SP now returns a SUBSET of what GetCCProcessingBundleByBin returns
- Callers who need all eligible protocols (including unrestricted ones) must use the Bundle procedures

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCode | int | NO | - | VERIFIED | First 6 digits of the credit/debit card. Resolved to a country via Dictionary.CountryBin, then used to filter Billing.ProtocolCountry. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProtocolID | int | NO | - | VERIFIED | Payment protocol IDs eligible for the BIN's country. Only protocols with explicit ProtocolCountry entries matching the country are returned. Does NOT include unrestricted protocols. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinCode | Dictionary.CountryBin | Read (INNER JOIN) | Resolves BIN to issuing country. INNER JOIN means if BIN not in table, no rows returned. |
| CountryID filter | Billing.ProtocolCountry | Read | Returns ProtocolIDs where the country matches the BIN's country or CountryID=0. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RoutingUser (role) | EXECUTE permission | Permission | CC deposit routing protocol eligibility check. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCountryProtocols (procedure)
├── Dictionary.CountryBin (table)
└── Billing.ProtocolCountry (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryBin | Table | INNER JOIN on BinCode=@BinCode to get CountryID. |
| Billing.ProtocolCountry | Table | Returns ProtocolID WHERE CountryID matches BIN country. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RoutingUser (role) | Permission | Protocol eligibility for CC routing |

---

## 7. Technical Details

N/A for Stored Procedure.

---

## 8. Sample Queries

```sql
EXEC Billing.GetCountryProtocols @BinCode = 411111
-- Returns: ProtocolIDs explicitly configured for the BIN's country
-- Note: does NOT include protocols with no country restriction

-- Compare with Bundle procedure which includes unrestricted protocols:
-- EXEC Billing.GetCCProcessingBundleByBin @BinCode=411111, @CurrencyID=1, @CardTypeID=1
```

---

## 9. Atlassian Knowledge Sources

PAYUS-3061 (June 2021, creation by Shabtay E.) and PAYIL-3372 (November 2021, removal of unrestricted protocol union by Shuky B.).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCountryProtocols | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCountryProtocols.sql*
