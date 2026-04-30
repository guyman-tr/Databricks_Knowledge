# Billing.UpdateCustomerEDD

> Sets the Enhanced Due Diligence (EDD) flag on a customer's BackOffice record, used by both automated country-based EDD classification and manual compliance operations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - targets BackOffice.Customer.IsEDD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateCustomerEDD` sets or clears the Enhanced Due Diligence flag (`IsEDD`) on a customer's BackOffice profile. EDD is a KYC/AML (Know Your Customer / Anti-Money Laundering) designation that subjects a customer to heightened compliance scrutiny - additional identity verification, source-of-funds checks, and enhanced transaction monitoring.

Created in 2017 (OPS0333 - "EDD flag in BO") as part of the introduction of the EDD compliance workflow in the Back Office. Two usage paths exist:

1. **Automated path** - `Billing.UpdateCustomerEconomicTypeBasedOnFunding` calls this SP to automatically set `IsEDD=1` for customers whose card's BIN country has a non-zero `EconomicTypeID` in `Dictionary.Country` (indicating the country's economic classification requires EDD treatment).

2. **Manual path** - Back Office compliance operators set or clear the EDD flag manually for individual customers, using this SP as the write interface.

The procedure is a single-statement UPDATE with no guard logic. The `IsEDD BIT NOT NULL DEFAULT (0)` column means all customers start with EDD=0 (not subject to EDD) and must be explicitly flagged.

---

## 2. Business Logic

### 2.1 EDD Flag Assignment

**What**: Unconditionally sets the IsEDD flag on the customer record, enabling or disabling Enhanced Due Diligence requirements for that customer.

**Columns/Parameters Involved**: `@CID`, `@IsEDD`, `BackOffice.Customer.IsEDD`

**Rules**:
- `UPDATE BackOffice.Customer SET IsEDD = @IsEDD WHERE CID = @CID`
- `@IsEDD = 1`: customer is subject to Enhanced Due Diligence requirements
- `@IsEDD = 0`: customer is not subject to EDD (standard due diligence applies)
- No prior-state validation - unconditional assignment regardless of current value
- If `@CID` does not exist, the UPDATE silently affects 0 rows

**Diagram**:
```
Automated path (country-based EDD):
  Billing.UpdateCustomerEconomicTypeBasedOnFunding
    -> SELECT EconomicTypeID FROM Dictionary.Country WHERE CountryID = [BIN country]
    -> IF EconomicTypeID <> 0 (country has a non-default economic type -> EDD required)
    -> EXEC Billing.UpdateCustomerEDD @CID=X, @IsEDD=EconomicTypeID
       (non-zero EconomicTypeID implicitly converts to BIT=1 -> EDD enabled)
    -> UPDATE BackOffice.Customer SET IsEDD=1 WHERE CID=X

Manual path (compliance operator):
  BackOffice tool
    -> Compliance decision: customer requires EDD
    -> EXEC Billing.UpdateCustomerEDD @CID=X, @IsEDD=1
    -> UPDATE BackOffice.Customer SET IsEDD=1 WHERE CID=X
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID identifying which customer's EDD status to update. Maps to `BackOffice.Customer.CID`. If the CID does not exist, the UPDATE silently affects 0 rows. |
| 2 | @IsEDD | BIT | NO | - | CODE-BACKED | Enhanced Due Diligence flag value. 1=customer subject to EDD (heightened compliance checks); 0=standard due diligence (EDD not required). Written to `BackOffice.Customer.IsEDD` (BIT NOT NULL DEFAULT 0). When called from `UpdateCustomerEconomicTypeBasedOnFunding`, the EconomicTypeID INT is passed and implicitly converted to BIT (non-zero -> 1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE CID | BackOffice.Customer | UPDATE (cross-schema) | Target table; sets IsEDD flag for the specified customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.UpdateCustomerEconomicTypeBasedOnFunding | @CID, EconomicTypeID (as @IsEDD) | EXEC (SQL caller) | Calls this SP to auto-set EDD=1 for customers whose BIN country has a non-zero EconomicTypeID |
| Back Office compliance tool | @CID, @IsEDD | EXEC (manual) | Compliance operators use this SP to manually flag or clear EDD status for individual customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateCustomerEDD (procedure)
`- BackOffice.Customer (table) - UPDATE target

Billing.UpdateCustomerEconomicTypeBasedOnFunding (procedure)
`- Billing.UpdateCustomerEDD (procedure) - EXEC caller
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE - sets IsEDD=@IsEDD WHERE CID=@CID (cross-schema write) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.UpdateCustomerEconomicTypeBasedOnFunding | Procedure | EXEC caller - automatically sets EDD flag based on country economic type classification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Target column: `BackOffice.Customer.IsEDD BIT NOT NULL CONSTRAINT Df_BackOffice_Customer_IsEDD DEFAULT (0)`. The DEFAULT (0) means new customers are created as non-EDD by default; this procedure is required to explicitly enable EDD.

---

## 8. Sample Queries

### 8.1 Flag a customer as requiring Enhanced Due Diligence
```sql
-- Enable EDD for customer 12345
EXEC Billing.UpdateCustomerEDD @CID = 12345, @IsEDD = 1;
```

### 8.2 Clear EDD status for a customer
```sql
-- Remove EDD requirement for customer 12345
EXEC Billing.UpdateCustomerEDD @CID = 12345, @IsEDD = 0;
```

### 8.3 Check current EDD status for a customer
```sql
SELECT CID, IsEDD
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
-- IsEDD=0: standard due diligence; IsEDD=1: enhanced due diligence required
```

### 8.4 Find all customers currently flagged for EDD
```sql
SELECT CID, IsEDD
FROM BackOffice.Customer WITH (NOLOCK)
WHERE IsEDD = 1
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Internal code comment references ticket OPS0333 (2017) for the original EDD flag introduction in Back Office.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed (UpdateCustomerEconomicTypeBasedOnFunding) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateCustomerEDD | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateCustomerEDD.sql*
