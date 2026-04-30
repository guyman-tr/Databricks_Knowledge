# Billing.GetAllDepots

> Returns the complete list of all payment gateway depot configurations (active and inactive), providing callers with the full routing registry for deposits, cashouts, and refunds.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DepotID (payment gateway endpoint identifier) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetAllDepots` is a simple read-only procedure that exposes the full `Billing.Depot` configuration table to authorized callers. It returns every depot row - both active and inactive - with the key routing dimensions: which payment method (FundingTypeID), which transaction direction (PaymentTypeID), which gateway/processor (ProtocolID), the human-readable name, activity status, and payout generation capability.

A "depot" in eToro's billing system is a named endpoint that combines a payment method, a direction (deposit/cashout/refund), and a processing protocol into a single routable unit. The routing engine selects a depot for each incoming transaction; this procedure provides the full depot catalog to upstream systems that need to understand the routing configuration.

This procedure is granted to the `SQL_SecurePay` database role (as per the permissions grant in `UsersPermissions/SQL_SecurePay.sql`), indicating it is called by the payment processing service layer with that role. No internal SQL callers exist - consumption is entirely from the application tier.

---

## 2. Business Logic

### 2.1 Full Catalog Exposure (Active + Inactive)

**What**: Unlike filtering procedures that restrict to active depots, this procedure returns ALL depots regardless of `IsActive` status, giving callers a complete configuration view.

**Columns/Parameters Involved**: `IsActive`, `DepotID`

**Rules**:
- Returns all 163 configured depots (IDs 1-174 with gaps)
- Includes 114 active depots (70%) and 49 inactive/legacy depots (30%)
- Callers are responsible for filtering by `IsActive=1` if they want only routable depots
- Inactive depots are preserved for historical reference and potential reactivation

### 2.2 Payout Generation Capability

**What**: Exposes the `PayoutGeneration` flag so callers can identify which depots support automated batch payment file generation.

**Columns/Parameters Involved**: `PayoutGeneration`

**Rules**:
- `PayoutGeneration=1`: depot supports automated payout file generation (batch instructions)
- `PayoutGeneration=0`: manual processing or provider-managed batching
- Only a small subset (e.g., MoneyBookers USD=1, Neteller=1) have this enabled

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters. Returns all columns from `Billing.Depot`:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepotID | int | NO | - | CODE-BACKED | Primary key of the depot. Manually assigned (no IDENTITY). Stable identifier referenced by deposits, MID settings, and routing tables. 163 rows in total. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type for this depot (e.g., 1=CreditCard, 2=Wire, 6=Neteller, 8=MoneyBookers/Skrill). Implicit reference to Dictionary.FundingType. 38 distinct values across 163 depots. |
| 3 | PaymentTypeID | int | NO | - | CODE-BACKED | Direction of payment: 1=Deposit, 2=Cashout, 3=Refund. FK to Dictionary.PaymentType. One depot can only serve one direction. |
| 4 | ProtocolID | int | NO | - | CODE-BACKED | Payment processing gateway/protocol. FK to Dictionary.Protocol. Identifies the specific API used (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). |
| 5 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. |
| 6 | IsActive | bit | YES | NULL | CODE-BACKED | Whether this depot is currently eligible for routing: 1=Active, 0 or NULL=Inactive. 114 of 163 depots are active. Callers filter by IsActive=1 to get the routable subset. |
| 7 | PayoutGeneration | int | NO | 0 | CODE-BACKED | Automated payout file generation capability: 1=enabled (system generates batch payment files); 0=disabled (default). Only a small subset of depots (e.g., MoneyBookers USD, Neteller) have this enabled. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Billing.Depot | Read | Full SELECT from Billing.Depot with no filter - exposes entire depot routing registry. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay role | EXECUTE permission | Permission | Payment processing service layer calls this procedure via the SQL_SecurePay role to retrieve depot configuration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetAllDepots (procedure)
└── Billing.Depot (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Depot | Table | Full SELECT returning DepotID, FundingTypeID, PaymentTypeID, ProtocolID, Name, IsActive, PayoutGeneration. No WHERE clause - returns all rows. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay (role) | Permission | Application-tier payment service consumes this procedure to load the depot catalog. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all active depots eligible for routing
```sql
-- Call the procedure and filter client-side, or query directly:
SELECT DepotID, Name, FundingTypeID, PaymentTypeID, ProtocolID, IsActive, PayoutGeneration
FROM Billing.Depot WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY FundingTypeID, PaymentTypeID
```

### 8.2 Find depots with automated payout generation enabled
```sql
SELECT DepotID, Name, FundingTypeID, PaymentTypeID
FROM Billing.Depot WITH (NOLOCK)
WHERE PayoutGeneration = 1
ORDER BY DepotID
```

### 8.3 Get depot catalog with payment method and direction labels
```sql
SELECT d.DepotID, d.Name,
       ft.Name AS FundingTypeName,
       pt.Name AS PaymentTypeName,
       pr.Name AS ProtocolName,
       d.IsActive, d.PayoutGeneration
FROM Billing.Depot d WITH (NOLOCK)
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = d.FundingTypeID
JOIN Dictionary.PaymentType pt WITH (NOLOCK) ON pt.PaymentTypeID = d.PaymentTypeID
JOIN Dictionary.Protocol pr WITH (NOLOCK) ON pr.ProtocolID = d.ProtocolID
ORDER BY d.FundingTypeID, d.PaymentTypeID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Payout Service Gen 2.0 - Changes](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1218937110/Payout+Service+Gen+2.0+-+Changes) | Confluence | References depot configuration and payout generation capability in the context of the Payout Service redesign. MEDIUM confidence - not directly describing this SP. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetAllDepots | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetAllDepots.sql*
