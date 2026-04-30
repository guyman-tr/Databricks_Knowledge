# Billing.GetDisabledFundingsFTD

> Returns the funding type IDs that are disabled for first-time deposits (FTD) for a given country and regulation - used by the deposit setup service to exclude ineligible payment methods from new customers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns FundingTypeID rows for country+regulation combos restricted from FTD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDisabledFundingsFTD` answers: "which payment methods are NOT available for first-time depositors from this country under this regulation?" A first-time depositor is a new customer making their first deposit; some payment methods (e.g., wire transfer) are typically not offered as a first deposit method due to compliance, operational, or risk reasons.

Created by Ran Ovadia, November 2019. Called by `Billing.GetCustomerDepositInfo` (which assembles the full deposit setup for a customer), which passes the customer's CountryID and RegulationID to filter out restricted payment methods for new customers.

Relevant Atlassian context: "MOP For FTD" and "Routing Tool Mapping" Confluence pages relate to payment method configuration for first-time deposits.

---

## 2. Business Logic

### 2.1 FTD Payment Method Restriction Lookup

**What**: Returns all payment method types that are blocked for first-time deposits for a specific country + regulation combination.

**Rules**:
- `SELECT FundingTypeID FROM Billing.DisabledFundingTypeForFTD WHERE CountryID = @CountryID AND RegulationID = @RegulationID`
- Returns multiple FundingTypeID rows - one per blocked method
- Returns 0 rows if no restrictions exist for this combination (all funding types are available for FTD)
- Caller (`Billing.GetCustomerDepositInfo`) uses the result to exclude these FundingTypeIDs from the presented payment options

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | INT | NO | - | CODE-BACKED | Customer's country ID. Filters Billing.DisabledFundingTypeForFTD to country-specific restrictions. |
| 2 | @RegulationID | INT | NO | - | CODE-BACKED | Customer's regulatory jurisdiction ID. Combined with CountryID to find applicable restrictions. |
| 3 | FundingTypeID (output) | INT | NO | - | CODE-BACKED | Payment method type that is disabled for FTD in this country+regulation. One row per disabled type. Values: 1=CreditCard, 2=WireTransfer, 3=PayPal, etc. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CountryID + @RegulationID | Billing.DisabledFundingTypeForFTD | Lookup | Retrieves FTD-disabled funding types |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCustomerDepositInfo | EXEC call | Functional | Called to get disabled FTD funding types as part of full deposit setup assembly |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDisabledFundingsFTD (procedure)
└── Billing.DisabledFundingTypeForFTD (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.DisabledFundingTypeForFTD | Table | Primary source - filtered by CountryID and RegulationID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCustomerDepositInfo | Stored Procedure | Calls to get FTD-disabled funding types for deposit setup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Setting | Suppresses row-count messages |
| No NOLOCK | Design | No NOLOCK hint on Billing.DisabledFundingTypeForFTD; committed reads for regulatory configuration |

---

## 8. Sample Queries

### 8.1 Get FTD-disabled funding types for a customer

```sql
EXEC Billing.GetDisabledFundingsFTD @CountryID = 70, @RegulationID = 2;
```

### 8.2 Inline equivalent

```sql
SELECT FundingTypeID
FROM Billing.DisabledFundingTypeForFTD
WHERE CountryID = 70 AND RegulationID = 2;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MOP For FTD (Confluence) | Confluence | Method of payment configuration for first-time deposits - context for why certain funding types are disabled for FTD |
| Routing Tool Mapping (Confluence) | Confluence | Routing rules for payment methods including FTD-specific restrictions |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence (search results) + 0 Jira | Procedures: 1 SQL caller (Billing.GetCustomerDepositInfo) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDisabledFundingsFTD | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDisabledFundingsFTD.sql*
