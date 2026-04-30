# Billing.ProtocolToRegulation

> Mapping table linking payment protocols to regulatory frameworks for jurisdiction-specific routing, with provider whitelist/blacklist flags indicating which protocols are permitted under each regulatory regime.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (ProtocolID, RegulationID) composite PK CLUSTERED |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered, FILLFACTOR=95) |

---

## 1. Business Meaning

Billing.ProtocolToRegulation maps payment processor protocols to the regulatory frameworks under which they are authorized to operate. When routing a deposit, the system can query this table to find which protocols are permitted for a customer's regulatory jurisdiction. This is the regulatory-compliance layer of payment routing - certain processors may only be licensed/approved under specific regulations.

The table currently has only 1 row: Checkout.com (ProtocolID=43) mapped to RegulationID=14 (NYDFS+FINRA) with IsWhitelistedProvider=true. This single entry reflects that only one specific protocol-regulation pairing needed explicit DB-level mapping (perhaps US regulatory compliance for New York-regulated customers using Checkout.com). Other protocol-regulation relationships are either implicit (all protocols available for a regulation) or managed at a different layer.

The table is stored on the DICTIONARY filegroup alongside other lookup/configuration tables.

---

## 2. Business Logic

### 2.1 Regulation-to-Protocol Resolution

**What**: GetProtocolIDsByRegulation returns protocols that are mapped to a given regulation.

**Columns/Parameters Involved**: `ProtocolID`, `RegulationID`, `IsWhitelistedProvider`

**Rules**:
- GetProtocolIDsByRegulation: SELECT ProtocolID WHERE RegulationID = @RegulationID.
- Currently only NYDFS+FINRA (RegulationID=14) has an explicit mapping to Checkout.com (43).
- IsWhitelistedProvider=true for the single row: Checkout.com is explicitly whitelisted for NYDFS+FINRA regulation.
- IsBlacklistedProvider=false: Not blacklisted.
- GetProtocolIDsByRegulationV2 provides a V2 lookup (likely with additional logic).

### 2.2 Whitelist/Blacklist Semantics

**What**: The whitelist/blacklist flags allow the routing system to approve or block specific protocols per regulation.

**Columns/Parameters Involved**: `IsWhitelistedProvider`, `IsBlacklistedProvider`

**Rules**:
- IsWhitelistedProvider=1: This protocol is explicitly approved for use under this regulation.
- IsBlacklistedProvider=1: This protocol must not be used for customers under this regulation.
- Current state: only one row with IsWhitelistedProvider=1, IsBlacklistedProvider=0.

---

## 3. Data Overview

| ProtocolID | Protocol | RegulationID | Regulation | IsWhitelisted | IsBlacklisted |
|-----------|----------|-------------|------------|--------------|--------------|
| 43 | Checkout.com | 14 | NYDFS+FINRA | true | false |

Total rows: 1

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProtocolID | int | NO | - | CODE-BACKED | Payment processor protocol. Part of composite PK. No FK constraint declared (unlike ProtocolCountry which has explicit FKs). Observed: 43=Checkout.com. |
| 2 | RegulationID | int | NO | - | CODE-BACKED | Regulatory framework. Part of composite PK. No FK constraint declared. Observed: 14=NYDFS+FINRA (New York Department of Financial Services + Financial Industry Regulatory Authority). |
| 3 | IsWhitelistedProvider | bit | YES | - | CODE-BACKED | When 1: this protocol is explicitly approved/whitelisted for use under this regulation. The single row has IsWhitelistedProvider=1. |
| 4 | IsBlacklistedProvider | bit | YES | - | CODE-BACKED | When 1: this protocol is explicitly prohibited/blacklisted under this regulation. The single row has IsBlacklistedProvider=0 (not blacklisted). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Dictionary.Protocol | Implicit | References the payment method. No FK constraint declared. |
| RegulationID | Dictionary.Regulation | Implicit | References the regulatory framework. No FK constraint declared. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetProtocolIDsByRegulation | ProtocolID, RegulationID | SELECT reader | Returns protocols available for a given regulation. Initial version Jira PAYUS-3061. |
| Billing.GetProtocolIDsByRegulationV2 | ProtocolID, RegulationID | SELECT reader | V2 version with additional logic. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ProtocolToRegulation (table)
  (leaf - tables have no FK constraints)
```

---

### 6.1 Objects This Depends On

No FK constraints declared.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetProtocolIDsByRegulation | Stored Procedure | Regulation-to-protocol lookup |
| Billing.GetProtocolIDsByRegulationV2 | Stored Procedure | V2 regulation-to-protocol lookup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProtocolToRegulation | CLUSTERED PK | ProtocolID ASC, RegulationID ASC | - | - | Active (FILLFACTOR=95, DICTIONARY filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ProtocolToRegulation | PRIMARY KEY | (ProtocolID, RegulationID) composite clustered on DICTIONARY filegroup |

---

## 8. Sample Queries

### 8.1 Get protocols available for a regulation

```sql
EXEC Billing.GetProtocolIDsByRegulation @RegulationID = 14
-- Returns ProtocolID=43 (Checkout.com for NYDFS+FINRA)
```

### 8.2 View all regulation-protocol mappings

```sql
SELECT ptr.ProtocolID, p.Name AS Protocol, ptr.RegulationID, r.Name AS Regulation,
       ptr.IsWhitelistedProvider, ptr.IsBlacklistedProvider
FROM Billing.ProtocolToRegulation ptr WITH (NOLOCK)
LEFT JOIN Dictionary.Protocol p WITH (NOLOCK) ON ptr.ProtocolID = p.ProtocolID
LEFT JOIN Dictionary.Regulation r WITH (NOLOCK) ON ptr.RegulationID = r.ID
ORDER BY ptr.RegulationID
```

---

## 9. Atlassian Knowledge Sources

Code comments in GetProtocolIDsByRegulation reference Jira PAYUS-3061 (Shabtay E., 15/06/2021 - Initial version of regulation-based protocol routing).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Note: Only 1 row currently. Most protocol-regulation relationships managed elsewhere (ProtocolCountry or application logic).*
*Object: Billing.ProtocolToRegulation | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ProtocolToRegulation.sql*
