# Billing.GetProtocolIDsByRegulationV2

> Returns all payment protocol IDs configured for a given regulation, extending V1 with provider whitelist/blacklist flags - enabling routing services to filter protocol candidates by both regulation and provider eligibility in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Billing.ProtocolToRegulation rows WHERE RegulationID=@RegulationID, including ProtocolID, IsWhitelistedProvider, IsBlacklistedProvider |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetProtocolIDsByRegulationV2` is the second generation of regulation-based protocol lookup. It returns the same regulation-to-protocol mappings as `Billing.GetProtocolIDsByRegulation` (V1) but adds `IsWhitelistedProvider` and `IsBlacklistedProvider` flags per protocol rule. This allows the caller to immediately filter protocols based on provider eligibility without needing a separate lookup.

The procedure exists to give the routing service, deposit service, and credit card service a richer picture of which protocols are available under a regulation. In V1, all protocols for a regulation were returned equally - the caller had to separately determine provider status. In V2, the provider flags are embedded in the result, enabling a single-call determination of "which protocols are available AND use eligible providers for this regulation?"

Data flows: added PAYIL-6954 (August 2023) as part of a broader provider whitelist/blacklist routing enhancement. The same callers that use V1 can choose to use V2 for the extended context. See also `Billing.GetProtocolByBinV2` which applies the same V2 pattern at the BIN level.

---

## 2. Business Logic

### 2.1 Regulation-to-Protocol Mapping (Inherited from V1)

**What**: Returns all protocols permitted under a regulation.

**Rules**:
- `SELECT ProtocolID FROM Billing.ProtocolToRegulation WHERE RegulationID = @RegulationID`
- All protocols mapped to the regulation are returned
- The caller applies further filtering using the returned flags

### 2.2 Provider Whitelist/Blacklist Flags (V2 Extension - PAYIL-6954)

**What**: Each protocol-regulation mapping carries provider eligibility flags.

**Columns Involved**: `IsWhitelistedProvider`, `IsBlacklistedProvider`

**Rules**:
- `IsWhitelistedProvider = 1`: Protocol rule applies only when using whitelisted providers
- `IsBlacklistedProvider = 1`: Protocol rule should not be applied when using blacklisted providers
- Both flags at 0: Protocol applies regardless of provider status
- These flags are stored at the ProtocolToRegulation mapping level, not globally on the protocol

### 2.3 V1 vs V2 Comparison

| Feature | V1 (GetProtocolIDsByRegulation) | V2 (GetProtocolIDsByRegulationV2) |
|---------|---------------------------------|----------------------------------|
| Regulation filter | YES | YES |
| Returns ProtocolID | YES | YES |
| IsWhitelistedProvider | NO | YES |
| IsBlacklistedProvider | NO | YES |
| Introduced | PAYUS-3061 (Jun 2021) | PAYIL-6954 (Aug 2023) |
| Callers | RoutingUser, DepositUser, CreditCardServiceUser | RoutingUser, DepositUser, CreditCardServiceUser |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegulationID | INT | NO | - | CODE-BACKED | The regulatory jurisdiction identifier. FK to Dictionary.Regulation. Determines which payment protocols are permitted for customers under this regulation. |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 2 | ProtocolID | Billing.ProtocolToRegulation.ProtocolID | CODE-BACKED | Payment protocol identifier permitted under the given regulation. FK to Billing.Protocol/Billing.ProtocolMIDSettings. |
| 3 | IsWhitelistedProvider | Billing.ProtocolToRegulation.IsWhitelistedProvider | CODE-BACKED | V2 addition. 1 = this protocol-regulation mapping is only applicable for whitelisted payment providers. 0 = no whitelist restriction. |
| 4 | IsBlacklistedProvider | Billing.ProtocolToRegulation.IsBlacklistedProvider | CODE-BACKED | V2 addition. 1 = this protocol-regulation mapping should not be applied when using a blacklisted provider. 0 = no blacklist restriction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RegulationID | Billing.ProtocolToRegulation.RegulationID | Filter | Returns all protocols mapped to this regulation with provider eligibility flags |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RoutingUser | GRANT EXECUTE | Permission | Routing service queries permitted protocols with provider flags for a regulation |
| DepositUser | GRANT EXECUTE | Permission | Deposit service checks available protocols with provider eligibility for the customer's regulation |
| CreditCardServiceUser | GRANT EXECUTE | Permission | Credit card service validates credit card protocols with provider context under the regulation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetProtocolIDsByRegulationV2 (procedure)
└── Billing.ProtocolToRegulation (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolToRegulation | Table | Filtered SELECT by RegulationID; returns ProtocolID + IsWhitelistedProvider + IsBlacklistedProvider |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RoutingUser | DB Security Principal | EXECUTE permission - protocol set lookup with provider flags for deposit routing |
| DepositUser | DB Security Principal | EXECUTE permission - protocol availability with provider eligibility at deposit initiation |
| CreditCardServiceUser | DB Security Principal | EXECUTE permission - credit card protocol validation with provider context |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Versioning**: This is V2 of `Billing.GetProtocolIDsByRegulation`. Both V1 and V2 are still active. The PAYIL-6954 pattern (adding IsWhitelistedProvider + IsBlacklistedProvider) was applied consistently across the protocol routing procedure family: `GetProtocolByBin` -> `GetProtocolByBinV2`, `GetProtocolIDsByRegulation` -> `GetProtocolIDsByRegulationV2`. Callers that need provider-aware routing use V2; legacy callers continue using V1.

---

## 8. Sample Queries

### 8.1 Get all protocols with provider flags for a regulation
```sql
EXEC [Billing].[GetProtocolIDsByRegulationV2] @RegulationID = 1
```

### 8.2 Find protocols available without provider restrictions
```sql
SELECT ProtocolID
FROM Billing.ProtocolToRegulation WITH (NOLOCK)
WHERE RegulationID = 1
  AND IsWhitelistedProvider = 0
  AND IsBlacklistedProvider = 0
```

### 8.3 Find protocols requiring whitelisted providers per regulation
```sql
SELECT RegulationID, ProtocolID
FROM Billing.ProtocolToRegulation WITH (NOLOCK)
WHERE IsWhitelistedProvider = 1
ORDER BY RegulationID, ProtocolID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-6954 (referenced in DDL comment) | Jira | V2 extension adding IsWhitelistedProvider and IsBlacklistedProvider to regulation-protocol mapping (August 2023) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (PAYIL-6954 in DDL comment) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetProtocolIDsByRegulationV2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetProtocolIDsByRegulationV2.sql*
