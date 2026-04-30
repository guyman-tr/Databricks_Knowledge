# Billing.AddFundingTypeDefaultAmount

> Inserts a new default deposit amount configuration for a payment method and currency combination into `Billing.FundingTypeDefaultAmount`, used by BackOffice to set the pre-filled deposit amount shown in the eToro deposit UI.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@FundingTypeID, @CurrencyID) - natural unique key of the inserted row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AddFundingTypeDefaultAmount` is the INSERT half of the CRUD operations for `Billing.FundingTypeDefaultAmount` - the configuration table that stores the pre-filled deposit amounts shown in the eToro deposit UI. When a customer opens the deposit form and selects a payment method, the UI shows a suggested amount (e.g., "1000 GBP" for a GBP credit card deposit). This procedure is called by BackOffice administrators to add a new payment method / currency combination to that configuration.

The procedure exists as a simple dedicated writer to provide a clean interface for BackOffice tooling without requiring direct table access. Its counterparts are `Billing.UpdateFundingTypeDefaultAmount` (for editing) and `Billing.DeleteDefaultAmount` (for removal).

Data flows: BackOffice operations call this proc when adding support for a new currency or payment method combination to the deposit flow configuration. The inserted configuration is read at deposit time by `Billing.GetFundingTypeDefaultAmount` and related deposit-settings procedures.

---

## 2. Business Logic

### 2.1 Simple Configuration Insert

**What**: A direct INSERT with no validation, duplicate-checking, or business rules beyond the database constraints.

**Parameters/Columns Involved**: `@FundingTypeID`, `@CurrencyID`, `@DefaultAmount`

**Rules**:
- The table has a UNIQUE index on (FundingTypeID, CurrencyID) - attempting to insert a duplicate will raise a constraint violation.
- No duplicate-check or MERGE logic is in the procedure - the caller is responsible for ensuring the combination does not already exist.
- `@DefaultAmount` is INT (whole numbers only) - fractional default amounts are not supported.
- The procedure does not validate that FundingTypeID or CurrencyID exist in their respective lookup tables - referential integrity is enforced at the application layer.
- DefaultAmount values are typically set to local-currency equivalents of ~$1,000 USD; special cases: PWMB (ID=42)=100, wire transfers in some currencies=50,000. See `Billing.FundingTypeDefaultAmount` for the full business rationale.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | VERIFIED | ID of the payment method (funding type) this default applies to. Implicit FK to Dictionary.FundingType. Examples: 1=CreditCard, 4=PayPal, 5=WireTransfer. Inserted into Billing.FundingTypeDefaultAmount.FundingTypeID. |
| 2 | @CurrencyID | INT | NO | - | VERIFIED | ID of the account currency this default applies to. Implicit FK to Dictionary.Currency. Common values: 1=USD, 2=EUR, 3=GBP. Inserted into Billing.FundingTypeDefaultAmount.CurrencyID. |
| 3 | @DefaultAmount | INT | NO | - | VERIFIED | The pre-filled deposit amount (in the currency identified by @CurrencyID) shown to customers in the deposit UI. Typically the local-currency equivalent of ~$1,000 USD. Must be a whole number (INT). Inserted into Billing.FundingTypeDefaultAmount.DefaultAmount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT target) | Billing.FundingTypeDefaultAmount | WRITER | Inserts one row per call defining a new default deposit amount for a payment method / currency pair. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from BackOffice administration tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AddFundingTypeDefaultAmount (procedure)
+- Billing.FundingTypeDefaultAmount (table)   [INSERT - write target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDefaultAmount | Table | INSERT target - adds one new default deposit amount configuration row |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from BackOffice tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Add a default deposit amount for a new currency (e.g., SGD CreditCard = 1350)
```sql
EXEC Billing.AddFundingTypeDefaultAmount
    @FundingTypeID = 1,     -- CreditCard
    @CurrencyID    = 99,    -- SGD (example ID)
    @DefaultAmount = 1350;  -- ~$1,000 USD equivalent
```

### 8.2 Verify the inserted configuration
```sql
SELECT  FTDA.ID,
        FTDA.FundingTypeID,
        FTDA.CurrencyID,
        FTDA.DefaultAmount
FROM    Billing.FundingTypeDefaultAmount FTDA WITH (NOLOCK)
WHERE   FTDA.FundingTypeID = 1
  AND   FTDA.CurrencyID    = 99;
```

### 8.3 View all default amounts for a funding type
```sql
SELECT  FTDA.FundingTypeID,
        FTDA.CurrencyID,
        FTDA.DefaultAmount
FROM    Billing.FundingTypeDefaultAmount FTDA WITH (NOLOCK)
WHERE   FTDA.FundingTypeID = 1     -- CreditCard
ORDER BY FTDA.CurrencyID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AddFundingTypeDefaultAmount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AddFundingTypeDefaultAmount.sql*
