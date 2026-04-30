# Billing.ProtocolCountry

> System-versioned temporal table mapping payment protocols to the countries where they are available, with whitelist/blacklist flags for fine-grained provider availability control per country.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table (SYSTEM_VERSIONED temporal - current state) |
| **Key Identifier** | (ProtocolID, CountryID) composite PK CLUSTERED |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered, FILLFACTOR=95) |
| **History Table** | History.ProtocolCountry |

---

## 1. Business Meaning

Billing.ProtocolCountry defines which payment protocols (processors/methods) are available in which countries. When a customer from a specific country attempts a deposit, the system queries this table to determine which protocols are eligible - only protocols mapped to that country (or universally available) are offered. This is the country-level availability matrix for eToro's payment routing.

820 rows cover 5 protocols across 244 countries. The temporal design (HIDDEN ValidFrom/ValidTo + History.ProtocolCountry) enables audit of when country availability was added/removed for any protocol - critical for regulatory compliance documentation.

GetCountryProtocols joins this table with Dictionary.CountryBin (BIN-to-country mapping) to resolve country from a card's BIN number, returning eligible protocols for that card's issuing country. Commented-out code in GetCountryProtocols shows that the original design also included protocols with no country restrictions (NULL country mapping) - this was later removed in PAYIL-3372.

---

## 2. Business Logic

### 2.1 Country-Protocol Availability

**What**: Each (ProtocolID, CountryID) row declares that a protocol is available in that country.

**Columns/Parameters Involved**: `ProtocolID`, `CountryID`, `IsWhitelistedProvider`, `IsBlacklistedProvider`

**Rules**:
- GetCountryProtocols: JOIN Dictionary.CountryBin ON BinCode = @BinCode, then WHERE ISNULL(CCB.CountryID, 0) IN (BPC.CountryID, 0). This means:
  - CountryID=0 (if any rows had it) would match all countries.
  - Otherwise exact country match from the BIN lookup.
- IsWhitelistedProvider/IsBlacklistedProvider: NULL for all 820 current rows. Reserved for fine-grained whitelist/blacklist logic when needed.
- Temporal: adding/removing a country for a protocol creates a history record.

### 2.2 Protocol Country Coverage

| ProtocolID | Protocol | Country Count | Coverage |
|-----------|----------|--------------|---------|
| 18 | (unknown - not in CC routing set) | 226 | Broad coverage |
| 23 | WorldPay | 221 | Global reach |
| 43 | Checkout.com | 175 | Selective coverage |
| 46 | IxopayNuvei | 172 | Selective coverage |
| 31 | (Skrill or similar) | 26 | Limited coverage |

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 820 |
| Distinct protocols | 5 |
| Distinct countries | 244 |
| IsWhitelisted/IsBlacklisted | All NULL (not currently used) |
| History table | History.ProtocolCountry |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProtocolID | int | NO | - | VERIFIED | Payment processor/method identifier. Part of composite PK. FK to Dictionary.Protocol (explicit constraint). 5 distinct protocols: 18, 23 (WorldPay), 31, 43 (Checkout), 46 (IxopayNuvei). |
| 2 | CountryID | int | NO | - | VERIFIED | Country where this protocol is available. Part of composite PK. FK to Dictionary.Country (explicit constraint). 244 distinct countries. |
| 3 | ValidFrom | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | System-versioning temporal column (HIDDEN). UTC timestamp when this country availability was established. Not visible in standard SELECT (requires FOR SYSTEM_TIME or explicit column reference). |
| 4 | ValidTo | datetime2(7) | NO | 9999-12-31 | CODE-BACKED | System-versioning temporal column (HIDDEN). 9999-12-31 for current rows. When a country is removed from a protocol, this is set to the removal timestamp and the row moves to History.ProtocolCountry. |
| 5 | IsWhitelistedProvider | bit | YES | - | CODE-BACKED | When 1: this protocol is explicitly whitelisted for this country combination. NULL for all 820 current rows - field reserved for future use or selective enforcement. |
| 6 | IsBlacklistedProvider | bit | YES | - | CODE-BACKED | When 1: this protocol is explicitly blacklisted from this country. NULL for all 820 current rows. When set, would prevent routing to this protocol for customers from this country regardless of other rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Dictionary.Protocol | FK (FK_BillingProtocolCountry_DictionaryProtocol) | References the payment method. WITH CHECK. |
| CountryID | Dictionary.Country | FK (FK_BillingProtocolCountry_DictionaryCountry) | References the country of availability. WITH CHECK. |
| (table) | History.ProtocolCountry | Temporal History | SQL Server writes old versions here on UPDATE/DELETE. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCountryProtocols | ProtocolID, CountryID | SELECT reader | Returns eligible protocols for a BIN's country. Joins Dictionary.CountryBin. Jira PAYUS-3061. |
| Billing.GetCountryProtocolsV2 | ProtocolID, CountryID | SELECT reader | V2 version of country protocol lookup. |
| Billing.GetCCProcessingBundle | ProtocolID | SELECT reader (indirect) | Uses country protocol availability in routing bundle. |
| Billing.GetCCProcessingBundleByBin | ProtocolID | SELECT reader (indirect) | Uses country protocols for BIN-based routing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ProtocolCountry (table)
  -> Dictionary.Protocol (FK)
  -> Dictionary.Country (FK)
  -> History.ProtocolCountry (temporal history - auto-maintained)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Protocol | Table | FK target for ProtocolID |
| Dictionary.Country | Table | FK target for CountryID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCountryProtocols | Stored Procedure | Country-based protocol availability lookup |
| Billing.GetCountryProtocolsV2 | Stored Procedure | V2 country protocol lookup |
| Billing.GetCCProcessingBundle | Stored Procedure | CC routing bundle (indirect) |
| Billing.GetCCProcessingBundleByBin | Stored Procedure | BIN-based CC routing (indirect) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProtocolCountry | CLUSTERED PK | ProtocolID ASC, CountryID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ProtocolCountry | PRIMARY KEY | (ProtocolID, CountryID) composite clustered |
| FK_BillingProtocolCountry_DictionaryProtocol | FOREIGN KEY | ProtocolID -> Dictionary.Protocol WITH CHECK |
| FK_BillingProtocolCountry_DictionaryCountry | FOREIGN KEY | CountryID -> Dictionary.Country WITH CHECK |
| SYSTEM_VERSIONING = ON | Temporal | History table: History.ProtocolCountry |

---

## 8. Sample Queries

### 8.1 Get all protocols available in a specific country

```sql
SELECT pc.ProtocolID, p.Name AS ProtocolName
FROM Billing.ProtocolCountry pc WITH (NOLOCK)
JOIN Dictionary.Protocol p WITH (NOLOCK) ON pc.ProtocolID = p.ProtocolID
WHERE pc.CountryID = 218  -- United Kingdom
ORDER BY p.Name
```

### 8.2 Get countries where a protocol is available

```sql
SELECT pc.CountryID, c.Name AS Country
FROM Billing.ProtocolCountry pc WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON pc.CountryID = c.CountryID
WHERE pc.ProtocolID = 43  -- Checkout.com
ORDER BY c.Name
```

### 8.3 Use the SP to get protocols for a card's BIN

```sql
EXEC Billing.GetCountryProtocols @BinCode = 411111
-- Returns ProtocolIDs available in the BIN's issuing country
```

---

## 9. Atlassian Knowledge Sources

Code comments reference Jira PAYUS-3061 (Shabtay E., 15/06/2021 - initial BIN routing feature) and PAYIL-3372 (Shuky B., 28/11/2021 - removed access to Dictionary.Protocol in GetCountryProtocols, removing universal protocol fallback).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.ProtocolCountry | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ProtocolCountry.sql*
