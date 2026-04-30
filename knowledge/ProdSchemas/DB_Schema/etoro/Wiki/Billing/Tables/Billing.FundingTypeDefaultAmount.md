# Billing.FundingTypeDefaultAmount

> Configuration table storing the pre-filled default deposit amounts shown to users in the eToro deposit UI, keyed by payment method and account currency.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) - natural key: (FundingTypeID, CurrencyID) |
| **Partition** | No |
| **Indexes** | 3 active (PK clustered + unique NC on FundingTypeID+CurrencyID + NC on CurrencyID) |

---

## 1. Business Meaning

Billing.FundingTypeDefaultAmount stores the suggested deposit amount that is pre-populated in the deposit flow when a customer selects a payment method. When a user opens the deposit screen and chooses, say, CreditCard with a GBP account, the UI shows a pre-filled amount of 1000 GBP. This table is the source of that pre-filled value.

This table exists to provide a sensible starting point for each payment method / currency combination that converts roughly to the same USD-equivalent value (~$1,000), adjusted for local currency exchange rates. Without this configuration, the deposit form would either be blank (poor UX) or show a USD-centric default (wrong for non-USD account holders). The default amounts reduce deposit form abandonment by showing an immediately actionable, reasonable amount.

Data in this table is maintained by the BackOffice team via three dedicated stored procedures: Billing.AddFundingTypeDefaultAmount (insert), Billing.UpdateFundingTypeDefaultAmount (update), and Billing.DeleteDefaultAmount (delete). Reads flow through Billing.GetFundingTypeDefaultAmount (returns all rows), Billing.GetCustomerDepositInfo (customer-specific deposit page context), and Billing.GetDefaultDepositSettingsForUser / GetDefaultDepositSettingsByCountryAndFtd (deposit settings for the UI).

---

## 2. Business Logic

### 2.1 Currency-Equivalent Default Amount

**What**: Each DefaultAmount is the local-currency equivalent of approximately $1,000 USD, adjusted per payment method minimum requirements.

**Columns/Parameters Involved**: `DefaultAmount`, `CurrencyID`, `FundingTypeID`

**Rules**:
- Major currencies (USD, EUR, GBP, CHF, CAD, AUD): DefaultAmount=1000 for most methods. These currencies trade close to USD parity so no adjustment needed.
- High-value currencies (JPY): DefaultAmount=100,000-150,000 (reflecting ~1:100-150 exchange rate vs USD).
- Nordic currencies (NOK=10,925, SEK=10,830, DKK=6,925): Adjusted to approximately $1,000 USD equivalent.
- Emerging market currencies (HUF=342,500, CZK=22,000, MXN=20,000, BRL=5,500): High face-value amounts equivalent to ~$1,000 USD.
- Asian currencies (IDR=3,500,000, VND=600,000, KRW=1,350,000, CLP=800,000, PHP=15,000): Very large nominal amounts reflecting weaker exchange rates.
- Some payment methods (eToroMoney, Trustly, RapidTransfer, OnlineBanking, iDEAL, POLI) have lower defaults (200-1,500) matching their typical minimum deposit or usage pattern.
- PWMB (ID=42) has DefaultAmount=100 - the minimum for that private wealth management product.
- WireTransfer/RUB=50,000 and WireTransfer/CNH=10,000 reflect Russia and China transfer minimums.

### 2.2 Payment Method Coverage

**What**: Not every payment method covers every currency - the table only contains valid (FundingTypeID, CurrencyID) combinations that the payment provider actually supports.

**Columns/Parameters Involved**: `FundingTypeID`, `CurrencyID`

**Rules**:
- CreditCard (FundingTypeID=1): Broadest coverage - 24 currencies including LATAM, GCC, SEA currencies.
- WireTransfer (FundingTypeID=2): 9 currencies including USD, EUR, GBP, JPY, AUD, CHF, CAD, RUB, CNH.
- PayPal (FundingTypeID=3): 7 major currencies (USD, EUR, GBP, JPY, AUD, CHF, CAD).
- Regional methods (Giropay=11, Sofort=15): EUR only. UnionPay=22, AliPay=25, WeChat=26: CNH only. OnlineBanking=28: USD plus SEA currencies (MYR, THB, IDR, VND, PHP).
- eToroMoney (FundingTypeID=33): EUR, GBP, AUD, DKK - the currencies supported by the eToro Money e-wallet.
- GCCInstantBankTransfer (FundingTypeID=43): AEDUSD only - Gulf market specific.

---

## 3. Data Overview

| ID | FundingTypeID | CurrencyID | DefaultAmount | Meaning |
|---|---|---|---|---|
| 1 | 1 (CreditCard) | 1 (USD) | 1000 | Standard credit card deposit starting amount in USD. The baseline from which other currencies are derived. Shown as the pre-filled amount when a USD-account customer selects credit card. |
| 4 | 1 (CreditCard) | 4 (JPY) | 100000 | Credit card default for JPY accounts - equivalent to ~$670 USD at a 150 JPY/USD rate. Higher face-value currencies require proportionally larger numbers to avoid confusing near-zero defaults. |
| 42 | 32 (PWMB) | 1 (USD) | 100 | Private Wealth Management Bridge minimum - significantly lower than other methods, reflecting the regulated entry threshold for this product. |
| 131 | 1 (CreditCard) | 45 (HUF) | 342500 | CreditCard default for Hungarian Forint accounts - ~$1,000 USD equivalent at ~342 HUF/USD. |
| 90 | 33 (eToroMoney) | 2 (EUR) | 1500 | eToroMoney EUR default is 1,500 instead of 1,000 - slightly higher starting amount for the eToro Money wallet, possibly to encourage larger initial transfers. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key, auto-incrementing. Clustered PK. Not used in business logic - natural key is (FundingTypeID, CurrencyID). |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method identifier. Implicit FK to Dictionary.FundingType. Active values in this table cover 24 payment methods from CreditCard (1) and WireTransfer (2) through regional methods (eToroMoney=33, Trustly=35, GCCInstantBankTransfer=43). |
| 3 | CurrencyID | int | NO | - | CODE-BACKED | Account denomination currency for which this default applies. Explicit FK to Dictionary.Currency. In billing context references ISO currency instruments (USD=1, EUR=2, GBP=3, JPY=4, AUD=5, etc.). The unique index on (FundingTypeID, CurrencyID) ensures one default amount per payment method per currency. |
| 4 | DefaultAmount | int | NO | - | CODE-BACKED | Pre-filled deposit amount shown in the deposit UI for this payment method + currency combination. Stored in the local currency's natural units (not cents - e.g., 1000 = 1000 USD/EUR/GBP, 100000 = 100,000 JPY, 342500 = 342,500 HUF). Each value is calibrated to approximately $1,000 USD equivalent, with lower values for payment methods with low minimums (PWMB=100, RapidTransfer=200). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | FK (explicit) | Enforced referential integrity to the instrument/currency registry. |
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method reference. No declared FK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetFundingTypeDefaultAmount | - | SELECT | Returns all rows joined with FundingType.Name and Currency.Abbreviation. Used by BackOffice to view/manage defaults. |
| Billing.AddFundingTypeDefaultAmount | - | INSERT | Adds a new (FundingTypeID, CurrencyID, DefaultAmount) combination. |
| Billing.UpdateFundingTypeDefaultAmount | - | UPDATE | Updates the DefaultAmount for an existing combination. |
| Billing.DeleteDefaultAmount | - | DELETE | Removes a row by ID or by (FundingTypeID, CurrencyID) combination. |
| Billing.GetCustomerDepositInfo | - | JOIN/Reader | Reads default deposit amounts as part of the customer deposit page context. |
| Billing.GetDefaultDepositSettingsForUser | - | Reader | Reads deposit settings for the user-facing deposit UI. |
| Billing.GetDefaultDepositSettingsByCountryAndFtd | - | Reader | Country and first-time-deposit aware deposit settings that include the default amount. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDefaultAmount (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | Explicit FK target for CurrencyID column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetFundingTypeDefaultAmount | Stored Procedure | SELECT - admin view of all defaults |
| Billing.AddFundingTypeDefaultAmount | Stored Procedure | INSERT writer |
| Billing.UpdateFundingTypeDefaultAmount | Stored Procedure | UPDATE writer |
| Billing.DeleteDefaultAmount | Stored Procedure | DELETE writer |
| Billing.GetCustomerDepositInfo | Stored Procedure | Reader - deposit page context |
| Billing.GetDefaultDepositSettingsForUser | Stored Procedure | Reader - user deposit UI |
| Billing.GetDefaultDepositSettingsByCountryAndFtd | Stored Procedure | Reader - country-aware deposit settings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_FundingTypeDefaultAmount | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| Idx_Billing_FundingTypeDefaultAmount_FundingTypeID_CurrencyID | NC UNIQUE | FundingTypeID ASC, CurrencyID ASC | - | - | Active (FILLFACTOR=95) - enforces one default per method+currency |
| i_CureenyID | NC | CurrencyID ASC | - | - | Active - supports lookups by currency (note: index name has typo "Cureeny") |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_FundingTypeDefaultAmount | PRIMARY KEY | ID column - clustered identity PK |
| Idx_Billing_FundingTypeDefaultAmount_FundingTypeID_CurrencyID | UNIQUE | Enforces that each (FundingTypeID, CurrencyID) pair has exactly one DefaultAmount |
| FK_Billing_FundingTypeDefaultAmount_Billing_CurrencyID | FK | CurrencyID -> Dictionary.Currency(CurrencyID) |

---

## 8. Sample Queries

### 8.1 Get all default deposit amounts with human-readable names

```sql
SELECT
    ft.Name AS PaymentMethod,
    c.Abbreviation AS Currency,
    fd.DefaultAmount
FROM Billing.FundingTypeDefaultAmount fd WITH (NOLOCK)
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON fd.FundingTypeID = ft.FundingTypeID
JOIN Dictionary.Currency c WITH (NOLOCK) ON fd.CurrencyID = c.CurrencyID
ORDER BY ft.Name, c.Abbreviation
```

### 8.2 Get the default deposit amount for a specific payment method and currency

```sql
SELECT fd.DefaultAmount
FROM Billing.FundingTypeDefaultAmount fd WITH (NOLOCK)
WHERE fd.FundingTypeID = 1   -- CreditCard
  AND fd.CurrencyID = 2      -- EUR
```

### 8.3 Find currencies where the default amount may need updating (stale FX)

```sql
-- Compare actual defaults against expected ~$1000 USD equivalent
SELECT
    ft.Name AS PaymentMethod,
    c.Abbreviation AS Currency,
    fd.DefaultAmount,
    fd.ModifictionDate  -- N/A - this table has no ModifictionDate; use ID ordering as proxy
FROM Billing.FundingTypeDefaultAmount fd WITH (NOLOCK)
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON fd.FundingTypeID = ft.FundingTypeID
JOIN Dictionary.Currency c WITH (NOLOCK) ON fd.CurrencyID = c.CurrencyID
WHERE c.Abbreviation IN ('JPY','HUF','CZK','NOK','SEK','PLN','MXN','BRL')
ORDER BY c.Abbreviation
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.FundingTypeDefaultAmount | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FundingTypeDefaultAmount.sql*
