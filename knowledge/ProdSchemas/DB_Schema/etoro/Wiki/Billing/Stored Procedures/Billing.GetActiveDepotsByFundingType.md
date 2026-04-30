# Billing.GetActiveDepotsByFundingType

> Returns the DepotIDs of all active depots for a given payment method type.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeID INTEGER - payment method filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetActiveDepotsByFundingType` is the simplest depot lookup procedure: given a `FundingTypeID`, return all `DepotID`s that are currently active for that payment type.

`Billing.Depot` is the master registry of payment gateway endpoints, with ~163 rows covering 38 funding types. Each depot represents one (FundingType + PaymentType + Protocol) combination through which deposits, cashouts, or refunds are routed. With 114 active rows (70%) and 49 inactive (legacy/decommissioned), callers need a reliable way to enumerate which depots are available for a given payment method.

This procedure is used by payment routing, deposit processing, and administrative tooling to enumerate valid routing targets for a specific funding type - for example, "which depots can I route a PayPal deposit through?" or "how many active Visa card depots exist?"

---

## 2. Business Logic

### 2.1 Active Depot Enumeration by Funding Type

**What**: Returns DepotIDs matching the given FundingTypeID and IsActive=1.

**Columns/Parameters Involved**: `@FundingTypeID`, `Billing.Depot.FundingTypeID`, `Billing.Depot.IsActive`

**Rules**:
- `WHERE FundingTypeID = @FundingTypeID AND IsActive = 1`: exact match on funding type, active rows only.
- Inactive depots (IsActive=0) are never returned - they exist for audit/history purposes only.
- No NOLOCK hint - uses default read committed isolation. Depot is a low-write configuration table; blocking risk is negligible.
- Returns only `DepotID` - callers join to Billing.Depot or other tables for additional context if needed.
- No SET NOCOUNT ON - suppression of row count messages is not applied.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type to filter by. FK to Dictionary.FundingType. Examples: 1=CreditCard, 29=ACH, 35=iDEAL, 43=Crypto. |

**Return columns**:

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | DepotID | INT | CODE-BACKED | PK of Billing.Depot. Each row is one active payment gateway endpoint for the specified funding type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID | Billing.Depot | Reader | SELECT DepotID WHERE FundingTypeID=@FundingTypeID AND IsActive=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment routing engine | External | Caller | Enumerates available depots for a payment method before routing selection |
| Deposit processing service | External | Caller | Validates that eligible depots exist for the chosen funding type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetActiveDepotsByFundingType (procedure)
└── Billing.Depot (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Depot | Table | SELECT DepotID WHERE FundingTypeID=@FundingTypeID AND IsActive=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment routing / deposit services | External | Enumerate active depots for a given payment method |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. SET NOCOUNT ON. No isolation hint (read committed). Single-column result. No RETURN statement. No TRY/CATCH. No transaction.

---

## 8. Sample Queries

### 8.1 Get active depots for iDEAL (FundingTypeID=35)

```sql
EXEC [Billing].[GetActiveDepotsByFundingType]
    @FundingTypeID = 35;
```

### 8.2 Get active depots for Credit Card (FundingTypeID=1)

```sql
EXEC [Billing].[GetActiveDepotsByFundingType]
    @FundingTypeID = 1;
```

### 8.3 Check all active depots with names (ad-hoc)

```sql
SELECT d.DepotID, d.Name, d.FundingTypeID, d.PaymentTypeID, d.ProtocolID
FROM [Billing].[Depot] d WITH (NOLOCK)
WHERE d.FundingTypeID = 35
  AND d.IsActive = 1
ORDER BY d.DepotID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetActiveDepotsByFundingType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetActiveDepotsByFundingType.sql*
