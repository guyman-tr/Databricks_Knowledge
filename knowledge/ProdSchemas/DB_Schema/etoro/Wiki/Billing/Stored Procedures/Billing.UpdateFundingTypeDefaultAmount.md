# Billing.UpdateFundingTypeDefaultAmount

> Updates the pre-filled deposit amount shown in the deposit UI for a specific payment method and currency combination - the Configuration Service's write interface for Billing.FundingTypeDefaultAmount.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeID + @CurrencyID (natural key) - targets Billing.FundingTypeDefaultAmount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateFundingTypeDefaultAmount` is the Configuration Service's write procedure for adjusting the suggested deposit amounts shown in the eToro deposit UI. When a customer opens the deposit screen and selects a payment method, the deposit amount field is pre-populated with a suggested value from `Billing.FundingTypeDefaultAmount`. This procedure updates that suggested amount for a specific (payment method, currency) pair.

The default amounts are approximately USD 1,000 equivalent for most method/currency combinations, with adjustments for currencies with different exchange rates (JPY=100,000-150,000, NOK=10,925, RUB=50,000) and for special products (PWMB/eToroMoney=100-200). Operations teams adjust these defaults via the Configuration Service when market conditions, minimum deposit requirements, or UX optimization needs change.

Called exclusively by `ConfigurationServiceUser` - the Configuration Service that manages payment configuration data.

---

## 2. Business Logic

### 2.1 Default Amount Update by Method and Currency

**What**: Updates the pre-filled deposit amount for a specific (FundingTypeID, CurrencyID) combination, controlling what amount is suggested to customers when they open the deposit UI.

**Columns/Parameters Involved**: `@FundingTypeID`, `@CurrencyID`, `@DefaultAmount`, `Billing.FundingTypeDefaultAmount.DefaultAmount`

**Rules**:
- `UPDATE Billing.FundingTypeDefaultAmount SET DefaultAmount = @DefaultAmount WHERE FundingTypeID = @FundingTypeID AND CurrencyID = @CurrencyID`
- Two-column natural key filter: both FundingTypeID AND CurrencyID must match
- No prior-state validation - unconditional assignment
- If the (FundingTypeID, CurrencyID) combination does not exist, the UPDATE silently affects 0 rows
  (use `Billing.AddFundingTypeDefaultAmount` to insert new combinations)
- `DefaultAmount` is INT (whole currency units; no fractional amounts in UI suggestions)
- Target default amounts are approximately $1,000 USD equivalent per currency:
  - Major parity currencies (USD/EUR/GBP/AUD/CHF/CAD): DefaultAmount=1000
  - High-multiplier currencies (JPY): DefaultAmount=100,000-150,000
  - Nordic currencies (NOK=10,925, SEK=10,830, DKK=6,925)
  - Special products (PWMB=100, eToroMoney/Trustly/RapidTransfer: 200-1,500)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method identifier. Part of the natural key for `Billing.FundingTypeDefaultAmount`. FK (implicit) to `Dictionary.FundingType`. Examples: 1=CreditCard, 2=WireTransfer, 3=PayPal, 42=PWMB. |
| 2 | @CurrencyID | INT | NO | - | CODE-BACKED | Currency identifier. Part of the natural key for `Billing.FundingTypeDefaultAmount`. FK (implicit) to `Dictionary.Currency`. Examples: 1=USD, 2=EUR, 3=GBP, 8=JPY. |
| 3 | @DefaultAmount | INT | NO | - | CODE-BACKED | The new suggested deposit amount for this payment method and currency. Written to `Billing.FundingTypeDefaultAmount.DefaultAmount`. Whole integer (no decimals). Should approximate $1,000 USD equivalent for the target currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE FundingTypeID, CurrencyID | Billing.FundingTypeDefaultAmount | UPDATE | Updates DefaultAmount for the specified payment method / currency combination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Configuration service | @FundingTypeID, @CurrencyID, @DefaultAmount | EXEC (ConfigurationServiceUser role) | Called when operations teams adjust the suggested deposit amount for a payment method/currency pair |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateFundingTypeDefaultAmount (procedure)
`- Billing.FundingTypeDefaultAmount (table) - UPDATE target

Related CRUD procedures for Billing.FundingTypeDefaultAmount:
  Billing.AddFundingTypeDefaultAmount (INSERT)
  Billing.UpdateFundingTypeDefaultAmount (UPDATE) <- this procedure
  Billing.DeleteDefaultAmount (DELETE)
  Billing.GetFundingTypeDefaultAmount (SELECT all)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDefaultAmount | Table | UPDATE - sets DefaultAmount WHERE FundingTypeID=@FundingTypeID AND CurrencyID=@CurrencyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Configuration service (ConfigurationServiceUser role). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Target table has UNIQUE NONCLUSTERED index on `(FundingTypeID, CurrencyID)` - the WHERE clause uses this index for efficient single-row lookup.

### 7.2 Constraints

N/A for stored procedure. The natural key (FundingTypeID, CurrencyID) has a UNIQUE index ensuring at most one DefaultAmount per combination. To add new combinations, use `Billing.AddFundingTypeDefaultAmount`.

---

## 8. Sample Queries

### 8.1 Update default deposit amount for USD credit card deposits
```sql
EXEC Billing.UpdateFundingTypeDefaultAmount
    @FundingTypeID = 1,   -- CreditCard
    @CurrencyID = 1,      -- USD
    @DefaultAmount = 1000;
```

### 8.2 Update default for JPY wire transfers
```sql
EXEC Billing.UpdateFundingTypeDefaultAmount
    @FundingTypeID = 2,       -- WireTransfer
    @CurrencyID = 8,          -- JPY
    @DefaultAmount = 120000;  -- ~$1,000 USD equivalent
```

### 8.3 Verify current default amounts for a payment method
```sql
SELECT ftda.FundingTypeID, ft.Name AS FundingTypeName,
       ftda.CurrencyID, c.CurrencyCode, ftda.DefaultAmount
FROM Billing.FundingTypeDefaultAmount ftda WITH (NOLOCK)
LEFT JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = ftda.FundingTypeID
LEFT JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = ftda.CurrencyID
WHERE ftda.FundingTypeID = 1 -- CreditCard
ORDER BY ftda.CurrencyID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateFundingTypeDefaultAmount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateFundingTypeDefaultAmount.sql*
