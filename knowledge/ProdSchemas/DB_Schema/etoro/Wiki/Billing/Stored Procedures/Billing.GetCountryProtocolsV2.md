# Billing.GetCountryProtocolsV2

> Returns the available payment protocols for a credit card's issuing country, resolved via BIN-to-country lookup, with whitelist/blacklist provider flags.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BinCode INT input; returns ProtocolID + provider flags |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCountryProtocolsV2` is the primary routing query for BIN-based protocol selection. When a customer initiates a credit card deposit, the payment routing pipeline needs to know which payment processors (protocols) are eligible for that card's issuing country. This procedure accepts the card's BIN code (the first 6-8 digits of the card number that identify the issuing bank and country) and returns the set of protocols configured for that country along with whitelist/blacklist flags for each provider.

Without this procedure, the routing engine would have no way to filter payment protocols to those legally or technically supported in the customer's card-issuing country. Countries may have restrictions on certain payment processors due to regulatory requirements, network agreements, or local market conditions. The `Billing.ProtocolCountry` table holds this configuration, and this procedure is the query interface into it.

Data flow: The caller (CreditCardServiceUser or RoutingUser service) provides a BIN code. The procedure joins `Dictionary.CountryBin` to translate the BIN to a CountryID, then filters `Billing.ProtocolCountry` to rows matching that country. If the BIN is not in `Dictionary.CountryBin` (unknown issuer), all protocols are returned as a fallback - the routing service then applies its own logic to choose among them. Created 2023-08-18 by Naftali H. (Payil-6998) as a revision of the prior `GetCountryProtocols`.

---

## 2. Business Logic

### 2.1 BIN-to-Country-to-Protocol Resolution

**What**: Translates a raw BIN code into an eligible protocol list via a two-step lookup.

**Columns/Parameters Involved**: `@BinCode`, `Dictionary.CountryBin.BinCode`, `Dictionary.CountryBin.CountryID`, `Billing.ProtocolCountry.CountryID`, `Billing.ProtocolCountry.ProtocolID`

**Rules**:
- Step 1: Join `Dictionary.CountryBin` on `CCB.BinCode = @BinCode` to resolve the card's issuing CountryID. This is the BIN-to-country resolution step.
- Step 2: Filter `Billing.ProtocolCountry` with `ISNULL(CCB.CountryID, 0) IN (BPC.CountryID, 0)`.
- The `IN (BPC.CountryID, 0)` clause evaluates per-row. The literal `0` in the IN list means: if the resolved country is 0 (BIN unknown), the condition is always TRUE - all protocols are returned.
- For a known country (e.g., CountryID=171), only rows in ProtocolCountry where CountryID=171 are matched.
- **No CountryID=0 "universal" rows exist in ProtocolCountry** (all 820 rows have explicit country IDs) - the 0 in the IN list is exclusively for the unknown-BIN fallback case.

**Diagram**:
```
Input: @BinCode (e.g., 411111)
        |
        v
Dictionary.CountryBin
  BinCode = @BinCode
  -> CountryID = 171 (Spain)
        |
        | ISNULL(171, 0) = 171
        v
  171 IN (BPC.CountryID, 0)?
  -> BPC rows where CountryID=171 -> matched (returned)
  -> BPC rows where CountryID=33  -> not matched
  -> BPC rows where CountryID=246 -> not matched

If BIN not found: ISNULL(NULL, 0) = 0
        v
  0 IN (BPC.CountryID, 0)?
  -> TRUE for all rows (0 is always equal to literal 0)
  -> ALL protocols returned (failsafe: unknown country -> allow all)
```

### 2.2 Whitelist/Blacklist Flags

**What**: Each returned protocol row carries provider-level whitelist/blacklist flags for fine-grained routing control.

**Columns/Parameters Involved**: `IsWhitelistedProvider`, `IsBlacklistedProvider`

**Rules**:
- Both columns are currently NULL for all rows in `Billing.ProtocolCountry` (820 rows as of last analysis).
- These columns are structural provisions for future whitelist/blacklist enforcement - not currently active in routing logic.
- The procedure returns them as-is; the routing caller decides how to interpret NULL vs 0 vs 1.

**Diagram**:
```
NULL    = No override (default routing rules apply)
1 (bit) = Explicitly whitelisted / blacklisted
0 (bit) = Explicitly NOT whitelisted / NOT blacklisted
```

### 2.3 V1 vs V2 Distinction

**What**: V2 supersedes the original `GetCountryProtocols` with revised NULL handling.

**Rules**:
- The original `GetCountryProtocols` included a branch for protocols with no country restriction (NULL CountryID in ProtocolCountry). This was removed in PAYIL-3372.
- V2 uses the `IN (BPC.CountryID, 0)` pattern, which handles unknown BINs via the literal `0` fallback rather than relying on NULL rows in ProtocolCountry.
- V2 is granted to both `CreditCardServiceUser` and `RoutingUser`; the original version's grants are separate.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCode | INT | NO | - | CODE-BACKED | The BIN (Bank Identification Number) code of the credit card - typically the first 6-8 digits identifying the issuing bank, card network, and country. Used to look up `Dictionary.CountryBin.CountryID`. If not found in CountryBin, all protocols are returned as fallback. |

**Returns** (SELECT output columns):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | ProtocolID | INT | NO | CODE-BACKED | Identifier of a payment protocol available for the card's issuing country. Joins to `Billing.Protocol` (or equivalent config table). Known values: 18, 23 (WorldPay), 31, 43 (Checkout.com), 46 (IxopayNuvei). Inherited from Billing.ProtocolCountry. |
| 2 | IsWhitelistedProvider | BIT | YES | CODE-BACKED | Provider-level whitelist override flag for this protocol in the matched country. NULL = no override (default routing); 1 = explicitly whitelisted. Currently NULL for all rows - reserved for future fine-grained routing control. Inherited from Billing.ProtocolCountry. |
| 3 | IsBlacklistedProvider | BIT | YES | CODE-BACKED | Provider-level blacklist override flag for this protocol in the matched country. NULL = no override (default routing); 1 = explicitly blacklisted (excluded from routing). Currently NULL for all rows - reserved for future exclusion logic. Inherited from Billing.ProtocolCountry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinCode | Dictionary.CountryBin | Lookup (JOIN) | Resolves BIN code to CountryID - translates card issuer identifier to country |
| ProtocolID (output) | Billing.ProtocolCountry | Direct read (SELECT) | Source of protocol eligibility by country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CreditCardServiceUser | EXECUTE grant | Permission | Credit card processing service calls this to determine eligible protocols before processing a card deposit |
| RoutingUser | EXECUTE grant | Permission | Payment routing service calls this as part of the protocol selection pipeline for card-based deposits |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCountryProtocolsV2 (procedure)
├── Billing.ProtocolCountry (table)
└── Dictionary.CountryBin (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolCountry | Table | Primary source - SELECT ProtocolID, IsWhitelistedProvider, IsBlacklistedProvider WHERE country matches BIN-resolved CountryID |
| Dictionary.CountryBin | Table | Lookup - JOIN on BinCode to resolve input @BinCode to CountryID for country-protocol filtering |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CreditCardServiceUser | DB user/service | Executes this procedure as part of credit card deposit flow |
| RoutingUser | DB user/service | Executes this procedure during payment routing protocol selection |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get protocols for a known BIN code

```sql
-- Returns protocols available for the country of BIN 411111 (Visa USA)
EXEC [Billing].[GetCountryProtocolsV2] @BinCode = 411111
```

### 8.2 Simulate behavior for unknown BIN (fallback case)

```sql
-- Understand the fallback: a BIN not in Dictionary.CountryBin returns all protocols
-- Check if a BIN exists in CountryBin first:
SELECT BinCode, CountryID
FROM [Dictionary].[CountryBin] WITH (NOLOCK)
WHERE BinCode = 999999

-- If no rows: GetCountryProtocolsV2 returns all 820 ProtocolCountry rows (all protocols)
```

### 8.3 Review full protocol-country coverage for a specific country

```sql
-- See all protocols available for a country (e.g., CountryID from Dictionary.Country)
-- to understand what GetCountryProtocolsV2 would return for a card from that country
SELECT bpc.ProtocolID, bpc.CountryID, bpc.IsWhitelistedProvider, bpc.IsBlacklistedProvider,
       cb.BinCode
FROM [Billing].[ProtocolCountry] bpc WITH (NOLOCK)
INNER JOIN [Dictionary].[CountryBin] cb WITH (NOLOCK) ON cb.CountryID = bpc.CountryID
WHERE cb.BinCode = 411111
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-6998 (DDL code comment) | Jira | Initial version created by Naftali H. on 18/08/2023 - introduced the V2 of GetCountryProtocols with revised NULL handling and whitelist/blacklist flag exposure |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 1 Jira (code comment) | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetCountryProtocolsV2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCountryProtocolsV2.sql*
