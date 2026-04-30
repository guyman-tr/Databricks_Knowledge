# Billing.GetMerchantDetailsForOneAccountByDepotOnly

> Scalar function that returns the technical name or back-office label of the merchant account assigned to a given depot+regulation combination, used to identify which eToro entity (eToroEU, eToroUK, etc.) processes a card transaction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(150) - merchant Name or BODescription |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetMerchantDetailsForOneAccountByDepotOnly resolves which eToro legal entity (merchant account) is associated with a depot+regulation routing combination. Back-office dashboards and reports use this to display the merchant name or BODescription alongside deposit and rollback records - answering "which eToro entity processed this transaction?"

The function exists because merchant account routing is many-dimensional (depot, regulation, currency, payment type, country, subtype, mode), but reporting only needs the entity name. This function fixes all dimensions to their "default" values (CurrencyID=0, PaymentTypeID=0, CountryID=0, SubTypeID=0, DepotModeID=1) and returns only the single most-specific merchant account name for the depot/regulation pair.

The returned string is either the **technical protocol name** (e.g., "CheckoutEUROW" - @MerchantAccountDetail=0) or the **back-office display label** (e.g., "eToroEU" - @MerchantAccountDetail=1). Reports use BODescription (1) for human-readable output; technical routing code uses Name (0) for protocol identification.

The regulation fallback pattern (`IN (0, @RegulationID)` with `ORDER BY RegulationID DESC`) ensures that if a regulation-specific routing exists, it takes priority over the global default (RegulationID=0). If no regulation-specific entry exists, the global default is returned.

---

## 2. Business Logic

### 2.1 Merchant Account Lookup (Regulation-Priority Pattern)

**What**: Resolves merchant account name for a depot, preferring regulation-specific entries over the global default.

**Columns/Parameters Involved**: `@DepotID`, `@RegulationID`, `@MerchantAccountDetail`

**Rules**:
- Joins Billing.MerchantAccountRouting to Dictionary.MerchantAccount on MerchantAccountID.
- Applies fixed "default-row" filter: CurrencyID=0, PaymentTypeID=0, CountryID=0, SubTypeID=0, DepotModeID=1 (PRODUCTION only - excludes staging rows where DepotModeID=2).
- Regulation filter: `mar.RegulationID IN (0, @RegulationID)` - includes both the global default (0) and the customer's specific regulation.
- `ORDER BY mar.RegulationID DESC` - specific regulation (e.g., 2=FCA) ranks above 0 (global default). `TOP(1)` returns the most-specific match.
- @MerchantAccountDetail=0 -> returns `ma.Name` (technical, e.g., "CheckoutEUROW").
- @MerchantAccountDetail=1 -> returns `ma.BODescription` (back-office label, e.g., "eToroEU").
- Returns NULL if no matching routing row exists for the given DepotID (no TOP(1) result).

**Diagram**:
```
@DepotID + @RegulationID + @MerchantAccountDetail
    |
SELECT TOP(1) FROM Billing.MerchantAccountRouting mar
JOIN Dictionary.MerchantAccount ma ON MerchantAccountID
WHERE DepotModeID=1 (PRODUCTION)
  AND CurrencyID=0, PaymentTypeID=0, CountryID=0, SubTypeID=0
  AND RegulationID IN (0, @RegulationID)
ORDER BY RegulationID DESC
    |
@MerchantAccountDetail=0: return ma.Name          ("CheckoutEUROW")
@MerchantAccountDetail=1: return ma.BODescription ("eToroEU")
```

---

## 3. Data Overview

N/A for Scalar Function. Dictionary.MerchantAccount sample:

| MerchantAccountID | Name | BODescription |
|-------------------|------|---------------|
| 1 | CheckoutEUROW | eToroEU |
| 2 | CheckoutUKROW | eToroUK |
| 4 | CheckoutEUEEA | eToroEU |
| 5 | CheckoutUKEEA | eToroUK |
| 6 | CheckoutEMUK | EMUK |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepotID | int | NO | - | VERIFIED | Processing depot identifier. Filters Billing.MerchantAccountRouting.DepotID. Represents the credit card processing depot (data center / PSP endpoint) assigned to the transaction. |
| 2 | @RegulationID | int | NO | - | VERIFIED | Customer's regulatory jurisdiction ID (e.g., 1=CySEC, 2=FCA, 3=NFA, 6=eToroUS). Used in `IN (0, @RegulationID)` filter with ORDER BY DESC to prefer regulation-specific routing over global default (0). |
| 3 | @MerchantAccountDetail | int | NO | - | VERIFIED | Selects which field to return: 0=Dictionary.MerchantAccount.Name (technical protocol name, e.g., "CheckoutEUROW"), 1=Dictionary.MerchantAccount.BODescription (back-office label, e.g., "eToroEU"). |
| RETURN | varchar(150) | YES | - | VERIFIED | Merchant account name or BODescription string. NULL if no matching DepotID row exists in Billing.MerchantAccountRouting with DepotModeID=1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepotID + @RegulationID | Billing.MerchantAccountRouting | Lookup (JOIN) | Resolves depot+regulation to MerchantAccountID. Fixed to production mode (DepotModeID=1), default dimensions (CurrencyID=0, etc.). |
| MerchantAccountID | Dictionary.MerchantAccount | Lookup (JOIN) | Resolves MerchantAccountID to Name and BODescription. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetDepositsCustomerCardPCIVersion | @DepotID, @RegulationID | Caller | Retrieves merchant name (BODescription) to include with customer deposit/card data. |
| Billing.GetRollbackedPaymentOrdersReport | @DepotID, @RegulationID | Caller | Retrieves merchant name for rollback order reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMerchantDetailsForOneAccountByDepotOnly (function)
├── Billing.MerchantAccountRouting (table)
└── Dictionary.MerchantAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.MerchantAccountRouting | Table | Resolves @DepotID + @RegulationID to MerchantAccountID, filtered to production/default row. |
| Dictionary.MerchantAccount | Table | Reads Name and BODescription for the resolved MerchantAccountID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetDepositsCustomerCardPCIVersion | Stored Procedure | Calls this to retrieve merchant name for customer card/deposit data endpoint. |
| Billing.GetRollbackedPaymentOrdersReport | Stored Procedure | Calls this to retrieve merchant name for rollback payment orders BI report. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| DepotModeID=1 hardcoded | Design | Always returns PRODUCTION merchant only. Staging routing (DepotModeID=2) is never returned regardless of environment. |
| Zero-dimension defaults | Design | All non-depot/non-regulation dimensions are fixed to 0 (CurrencyID=0, PaymentTypeID=0, CountryID=0, SubTypeID=0). Returns the "universal default" routing for a depot. |
| Regulation fallback | Logic | `IN (0, @RegulationID)` with `ORDER BY RegulationID DESC` ensures regulation-specific entries override global defaults (0). |

---

## 8. Sample Queries

### 8.1 Get merchant BODescription for a depot+regulation

```sql
SELECT Billing.GetMerchantDetailsForOneAccountByDepotOnly(5, 2, 1) AS MerchantLabel;
-- @DepotID=5, @RegulationID=2 (FCA), @MerchantAccountDetail=1 (BODescription)
-- Returns: "eToroUK" (or regulation-specific override if exists)
```

### 8.2 Get technical Name vs BODescription for the same depot

```sql
SELECT
    Billing.GetMerchantDetailsForOneAccountByDepotOnly(5, 2, 0) AS TechnicalName,
    Billing.GetMerchantDetailsForOneAccountByDepotOnly(5, 2, 1) AS BOLabel;
-- TechnicalName: "CheckoutUKROW" | BOLabel: "eToroUK"
```

### 8.3 Check merchant labels across all unique depot+regulation combinations

```sql
SELECT DISTINCT
    mar.DepotID,
    mar.RegulationID,
    Billing.GetMerchantDetailsForOneAccountByDepotOnly(mar.DepotID, mar.RegulationID, 1) AS MerchantLabel
FROM Billing.MerchantAccountRouting mar WITH (NOLOCK)
WHERE mar.DepotModeID = 1
  AND mar.CurrencyID = 0 AND mar.PaymentTypeID = 0
  AND mar.CountryID = 0 AND mar.SubTypeID = 0
ORDER BY mar.DepotID, mar.RegulationID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMerchantDetailsForOneAccountByDepotOnly | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.GetMerchantDetailsForOneAccountByDepotOnly.sql*
