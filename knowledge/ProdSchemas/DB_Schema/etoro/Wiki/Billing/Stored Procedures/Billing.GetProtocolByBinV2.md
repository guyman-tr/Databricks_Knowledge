# Billing.GetProtocolByBinV2

> Returns active protocol routing rules for a given BIN (Bank Identification Number), extending V1 with provider whitelist/blacklist flags - enabling the routing and credit card services to filter BIN rules not just by amount limits but also by provider eligibility.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Billing.ProtocolByBin rows where BinNumber=@BinCode AND IsActive=1, plus IsWhitelistedProvider and IsBlacklistedProvider columns |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetProtocolByBinV2` is the second generation of BIN-based protocol routing lookup. It returns the same active routing rules as `Billing.GetProtocolByBin` (V1) but adds two boolean flags per rule: `IsWhitelistedProvider` and `IsBlacklistedProvider`. These flags allow the caller to additionally filter rules based on the payment provider's current eligibility status - not just amount ranges.

The procedure exists to support the routing service and credit card service in making more granular routing decisions. A BIN rule can specify that its protocol should only be used with whitelisted providers, or should never be used with blacklisted providers. This extension was introduced in August 2023 (PAYIL-6954) as provider-level routing control became necessary - likely driven by compliance requirements or payment processor performance differentiation.

Data flows: the routing service and credit card service call this V2 version when they need the full provider whitelist/blacklist context alongside BIN routing rules. V1 (`Billing.GetProtocolByBin`) is retained for callers that don't need the provider flags. Both procedures query the same `Billing.ProtocolByBin` table; V2 returns two additional columns.

---

## 2. Business Logic

### 2.1 BIN-Based Protocol Override (Inherited from V1)

**What**: Active BIN routing rules override standard protocol routing for specific card BINs.

**Rules**:
- `WHERE IsActive = 1 AND BinNumber = @BinCode`
- Only active rules returned - inactive rules are ignored
- A BIN may have multiple active rules (different protocols, different amount ranges)
- MinAmount/MaxAmount used by caller to select the applicable rule for the transaction amount

### 2.2 Provider Whitelist/Blacklist Flags (V2 Extension - PAYIL-6954)

**What**: Each BIN rule carries provider eligibility flags that layer additional routing constraints on top of the protocol assignment.

**Columns Involved**: `IsWhitelistedProvider`, `IsBlacklistedProvider`

**Rules**:
- `IsWhitelistedProvider = 1`: This BIN rule should ONLY be applied when using a whitelisted provider
- `IsBlacklistedProvider = 1`: This BIN rule should NOT be applied when using a blacklisted provider
- Both flags can be 0 (rule applies regardless of provider status)
- The routing service applies its provider filtering logic after receiving these flags
- This allows eToro to route some BINs to premium/preferred providers and block problematic providers for specific BINs

### 2.3 V1 vs V2 Comparison

| Feature | V1 (GetProtocolByBin) | V2 (GetProtocolByBinV2) |
|---------|----------------------|------------------------|
| BIN filter | YES | YES |
| IsActive filter | YES | YES |
| Amount limits (Min/Max) | YES | YES |
| IsWhitelistedProvider | NO | YES |
| IsBlacklistedProvider | NO | YES |
| Introduced | PAYUS-3061 (Jun 2021) | PAYIL-6954 (Aug 2023) |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinCode | INT | NO | - | CODE-BACKED | The 6-digit BIN (Bank Identification Number) - first 6 digits of the credit card number. Identifies the issuing bank and card type. Used to look up protocol routing overrides for this specific BIN. |

**Return columns:**

| # | Column | Confidence | Description |
|---|--------|------------|-------------|
| 2 | ID | CODE-BACKED | PK of the ProtocolByBin rule record. |
| 3 | BinNumber | CODE-BACKED | The BIN code this rule applies to (echoed from the filter). |
| 4 | ProtocolID | CODE-BACKED | The payment protocol to use for cards with this BIN. FK to Billing.Protocol/Billing.ProtocolMIDSettings. |
| 5 | MinAmount | CODE-BACKED | Minimum transaction amount for this rule to apply. Transactions below this amount use standard routing. |
| 6 | MaxAmount | CODE-BACKED | Maximum transaction amount for this rule to apply. Transactions above this use standard routing or another rule. |
| 7 | ModificationDate | CODE-BACKED | Timestamp of the last update to this routing rule. |
| 8 | IsActive | CODE-BACKED | Always 1 in results (filter condition). Rule is active and in effect. |
| 9 | IsWhitelistedProvider | CODE-BACKED | V2 addition. 1 = this BIN rule is only applicable for whitelisted payment providers. 0 = no whitelist restriction. |
| 10 | IsBlacklistedProvider | CODE-BACKED | V2 addition. 1 = this BIN rule should not be applied when using a blacklisted provider. 0 = no blacklist restriction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinCode | Billing.ProtocolByBin.BinNumber | Lookup | Retrieves active routing rules for this BIN including provider flags |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RoutingUser | GRANT EXECUTE | Permission | Routing service reads BIN-based protocol overrides with provider flags at deposit routing time |
| CreditCardServiceUser | GRANT EXECUTE | Permission | Credit card service checks BIN routing with provider eligibility before processing a card deposit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetProtocolByBinV2 (procedure)
└── Billing.ProtocolByBin (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolByBin | Table | Filtered SELECT by BinNumber and IsActive=1; returns all columns including IsWhitelistedProvider and IsBlacklistedProvider |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RoutingUser | DB Security Principal | EXECUTE permission - BIN routing with provider filtering at deposit time |
| CreditCardServiceUser | DB Security Principal | EXECUTE permission - credit card processing with provider eligibility |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Versioning**: This is V2 of `Billing.GetProtocolByBin`. V1 (PAYUS-3061, Jun 2021) introduced BIN-based routing. V2 (PAYIL-6954, Aug 2023) added `IsWhitelistedProvider` and `IsBlacklistedProvider` columns from `Billing.ProtocolByBin`. V1 is retained for backward-compatible callers. V2 callers get the full picture for provider-aware routing decisions.

---

## 8. Sample Queries

### 8.1 Get protocol routing with provider flags for a specific BIN
```sql
EXEC [Billing].[GetProtocolByBinV2] @BinCode = 411111
```

### 8.2 Find BIN rules that restrict to whitelisted providers only
```sql
SELECT BinNumber, ProtocolID, MinAmount, MaxAmount
FROM Billing.ProtocolByBin WITH (NOLOCK)
WHERE IsActive = 1
  AND IsWhitelistedProvider = 1
ORDER BY BinNumber
```

### 8.3 Find BIN rules that blacklist certain providers
```sql
SELECT BinNumber, ProtocolID, IsWhitelistedProvider, IsBlacklistedProvider
FROM Billing.ProtocolByBin WITH (NOLOCK)
WHERE IsActive = 1
  AND (IsWhitelistedProvider = 1 OR IsBlacklistedProvider = 1)
ORDER BY BinNumber, ProtocolID
```

### 8.4 Compare V1 vs V2 results for a BIN
```sql
-- V1 result
EXEC [Billing].[GetProtocolByBin] @BinCode = 411111

-- V2 result (same rows + 2 extra columns)
EXEC [Billing].[GetProtocolByBinV2] @BinCode = 411111
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-6954 (referenced in DDL comment) | Jira | V2 extension adding IsWhitelistedProvider and IsBlacklistedProvider columns (August 2023) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (PAYIL-6954 in DDL comment) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetProtocolByBinV2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetProtocolByBinV2.sql*
