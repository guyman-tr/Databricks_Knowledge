# Billing.GetProtocolIDsByRegulation

> Returns all payment protocol IDs configured for a given regulation, used by the routing service, deposit service, and credit card service to determine which payment protocols are available to customers under a specific regulatory jurisdiction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Billing.ProtocolToRegulation.ProtocolID rows WHERE RegulationID=@RegulationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetProtocolIDsByRegulation` answers the question: "Which payment protocols are permitted under this regulation?" Each regulatory jurisdiction (e.g., CySEC, FCA, ASIC, SEC) has a specific set of approved payment methods. The `Billing.ProtocolToRegulation` table is the many-to-many mapping between regulations and protocols; this procedure returns all protocol IDs for a given regulation.

The procedure exists to support deposit routing at eToro. When a customer initiates a deposit, the routing service must first determine which payment protocols are valid for the customer's regulation before applying other routing filters (amount, BIN, country). This procedure is the entry point for that regulation-based protocol set.

Data flows: created PAYUS-3061 (June 2021, same ticket as GetProtocolByBin). Called by RoutingUser (routing service), DepositUser (deposit service), and CreditCardServiceUser (credit card processing service) at deposit initiation time. See also `Billing.GetProtocolIDsByRegulationV2` which extends this with provider whitelist/blacklist flags (PAYIL-6954, Aug 2023).

---

## 2. Business Logic

### 2.1 Regulation-to-Protocol Mapping

**What**: A regulation may allow multiple payment protocols; each protocol may appear in multiple regulations. This is a pure mapping lookup with no filtering beyond RegulationID.

**Rules**:
- `SELECT ProtocolID FROM Billing.ProtocolToRegulation WHERE RegulationID = @RegulationID`
- All protocols mapped to the regulation are returned (no IsActive filter at this level)
- The caller (routing service) applies further filtering after receiving the protocol list
- If a regulation has no protocols mapped, returns empty result set

### 2.2 Usage in Deposit Routing Flow

**What**: This is typically the first call in the deposit routing decision tree.

**Flow**:
```
Customer initiates deposit
        |
        v
Determine customer's RegulationID (from Customer schema)
        |
        v
EXEC Billing.GetProtocolIDsByRegulation @RegulationID = X
        |
        v
For each ProtocolID returned:
  - Check BIN rules (GetProtocolByBin)
  - Check country/amount constraints
  - Apply provider whitelist/blacklist (V2 users)
        |
        v
Route to best matching protocol
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegulationID | INT | NO | - | CODE-BACKED | The regulatory jurisdiction identifier. FK to Dictionary.Regulation. Determines which payment protocols are permitted for customers under this regulation (e.g., CySEC=1, FCA=2, ASIC=3). |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 2 | ProtocolID | Billing.ProtocolToRegulation.ProtocolID | CODE-BACKED | Payment protocol identifier permitted under the given regulation. FK to Billing.Protocol/Billing.ProtocolMIDSettings. Returns one row per permitted protocol. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RegulationID | Billing.ProtocolToRegulation.RegulationID | Filter | Returns all protocols mapped to this regulation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RoutingUser | GRANT EXECUTE | Permission | Routing service queries permitted protocols for a regulation at deposit routing time |
| DepositUser | GRANT EXECUTE | Permission | Deposit service checks available protocols for the customer's regulation |
| CreditCardServiceUser | GRANT EXECUTE | Permission | Credit card service validates which credit card protocols are available under the regulation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetProtocolIDsByRegulation (procedure)
└── Billing.ProtocolToRegulation (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolToRegulation | Table | Filtered SELECT by RegulationID; returns all ProtocolIDs mapped to the regulation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RoutingUser | DB Security Principal | EXECUTE permission - protocol set lookup for deposit routing |
| DepositUser | DB Security Principal | EXECUTE permission - protocol availability check at deposit initiation |
| CreditCardServiceUser | DB Security Principal | EXECUTE permission - credit card protocol validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Versioning**: `Billing.GetProtocolIDsByRegulationV2` (PAYIL-6954, Aug 2023) extends this by adding `IsWhitelistedProvider` and `IsBlacklistedProvider` columns. V1 is retained for callers that don't need provider eligibility context. The simplicity of this V1 procedure (single-table, single-filter SELECT) makes it extremely performant for the hot-path deposit routing use case.

---

## 8. Sample Queries

### 8.1 Get all protocols for a regulation
```sql
EXEC [Billing].[GetProtocolIDsByRegulation] @RegulationID = 1
```

### 8.2 List all regulation-protocol mappings
```sql
SELECT RegulationID, ProtocolID
FROM Billing.ProtocolToRegulation WITH (NOLOCK)
ORDER BY RegulationID, ProtocolID
```

### 8.3 Count protocols per regulation
```sql
SELECT RegulationID, COUNT(*) AS ProtocolCount
FROM Billing.ProtocolToRegulation WITH (NOLOCK)
GROUP BY RegulationID
ORDER BY ProtocolCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-3061 (referenced in DDL comment) | Jira | Initial creation of regulation-based protocol routing feature (June 2021) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (PAYUS-3061 in DDL comment) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetProtocolIDsByRegulation | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetProtocolIDsByRegulation.sql*
