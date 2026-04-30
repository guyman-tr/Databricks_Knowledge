# Billing.UpdateFundingTypeMaxAmount

> Sets the maximum single-deposit amount for a payment method globally (across all currencies) by updating Dictionary.FundingType.MaxDepositAmount.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeID - targets Dictionary.FundingType.MaxDepositAmount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateFundingTypeMaxAmount` is the Configuration Service's procedure for setting the global maximum deposit amount for a payment method. Unlike `Billing.UpdateFundingTypeDefaultAmount` (which sets the suggested amount per currency), this procedure sets a single global ceiling on the maximum allowed deposit amount for a payment method type, stored in `Dictionary.FundingType.MaxDepositAmount`.

`MaxDepositAmount` is a method-level limit (not currency-specific) that represents the maximum amount in a single deposit transaction for that payment type. Operations or compliance teams update this limit when regulatory requirements, payment provider limits, or risk policies change (e.g., lowering the card deposit maximum during a fraud incident, or raising the wire transfer limit for premium customers).

Called exclusively by `ConfigurationServiceUser`. The companion read procedure is `Billing.GetFundingTypeMaxAmount` (also granted to ConfigurationServiceUser).

---

## 2. Business Logic

### 2.1 Global Maximum Deposit Limit Update

**What**: Sets the per-transaction deposit ceiling for a payment method, applied globally across all currencies.

**Columns/Parameters Involved**: `@FundingTypeID`, `@MaxAmount`, `Dictionary.FundingType.MaxDepositAmount`

**Rules**:
- `UPDATE Dictionary.FundingType SET MaxDepositAmount = @MaxAmount WHERE FundingTypeID = @FundingTypeID`
- Single-column UPDATE on a single row (one payment method)
- No prior-state validation - unconditional assignment
- If `@FundingTypeID` does not exist, the UPDATE silently affects 0 rows
- `MaxDepositAmount` is INT (nullable) - passing NULL would clear the limit
- This is a global limit across all currencies; currency-specific amount limits are handled at the deposit routing/validation layer
- The deposit service validates incoming deposit amounts against this limit during the deposit flow

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method identifier. Maps to `Dictionary.FundingType.FundingTypeID` (PK). Examples: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 8=Skrill/MoneyBookers, 42=PWMB. |
| 2 | @MaxAmount | INT | NO | - | CODE-BACKED | Maximum single-deposit amount for this payment method. Written to `Dictionary.FundingType.MaxDepositAmount` (INT NULL). Global limit applied across all currencies. Represents the maximum transaction size in the payment method's base unit. NULL clears the limit (no maximum enforced). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE FundingTypeID | Dictionary.FundingType | UPDATE (cross-schema) | Sets MaxDepositAmount for the specified payment method |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Configuration service | @FundingTypeID, @MaxAmount | EXEC (ConfigurationServiceUser role) | Called when adjusting the maximum deposit limit for a payment method |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateFundingTypeMaxAmount (procedure)
`- Dictionary.FundingType (table) - UPDATE target (cross-schema)

Related Configuration service procedures for funding type limits:
  Billing.GetFundingTypeMaxAmount (SELECT MaxDepositAmount)
  Billing.UpdateFundingTypeMaxAmount (UPDATE MaxDepositAmount) <- this procedure
  Billing.UpdateFundingTypeDefaultAmount (UPDATE per-currency suggested amount)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | UPDATE (cross-schema) - sets MaxDepositAmount WHERE FundingTypeID=@FundingTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Configuration service (ConfigurationServiceUser role). Deposit validation logic reads MaxDepositAmount from Dictionary.FundingType to enforce the limit. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. `Dictionary.FundingType` has PK CLUSTERED on `FundingTypeID` - the WHERE clause uses the PK for an efficient single-row update.

### 7.2 Constraints

N/A for stored procedure. `Dictionary.FundingType.MaxDepositAmount` is INT NULL - passing NULL clears any maximum limit for the payment method. The deposit validation layer reads this value; a NULL MaxDepositAmount typically means no maximum is enforced.

---

## 8. Sample Queries

### 8.1 Set the maximum credit card deposit amount
```sql
EXEC Billing.UpdateFundingTypeMaxAmount @FundingTypeID = 1, @MaxAmount = 10000; -- 1=CreditCard
```

### 8.2 Read the current max amount before updating
```sql
EXEC Billing.GetFundingTypeMaxAmount @FundingTypeID = 1;
-- Returns current MaxDepositAmount for CreditCard
```

### 8.3 Verify the update
```sql
SELECT FundingTypeID, Name, MaxDepositAmount
FROM Dictionary.FundingType WITH (NOLOCK)
WHERE FundingTypeID = 1;
```

### 8.4 View all payment methods and their limits
```sql
SELECT FundingTypeID, Name, MaxDepositAmount, IsFundingTypeActive
FROM Dictionary.FundingType WITH (NOLOCK)
ORDER BY FundingTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (GetFundingTypeMaxAmount - companion read SP) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateFundingTypeMaxAmount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateFundingTypeMaxAmount.sql*
