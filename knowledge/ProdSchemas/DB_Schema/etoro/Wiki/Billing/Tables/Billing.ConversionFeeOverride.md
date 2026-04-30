# Billing.ConversionFeeOverride

> Configuration table storing tier-specific currency conversion fee overrides that supersede the standard Billing.ConversionFee rates for loyalty club members by payment method, account currency, and optionally country.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ConversionFeeID (INT IDENTITY, no explicit PK) - natural key: (PlayerLevelID, FundingTypeID, CurrencyID, CountryID) |
| **Partition** | No |
| **Indexes** | 3 active (IX_Conv_1 unique NC + IX_Conv_2 unique NC duplicate + i_CureenyID NC on CurrencyID) |

---

## 1. Business Meaning

Billing.ConversionFeeOverride stores the exception fee schedule for currency conversion operations (deposits and cashouts) that apply when a customer belongs to a specific eToro Club loyalty tier. When a customer deposits or withdraws funds in a non-USD currency, eToro applies a conversion fee. The baseline schedule lives in Billing.ConversionFee; this table stores overrides that apply for specific combinations of player loyalty tier, payment method (FundingType), and account currency.

This table exists because higher-tier customers (Gold, Platinum, Diamond) receive preferential conversion fee rates as a loyalty benefit. Without this override layer, all customers would pay the same conversion fee regardless of their club tier. A Diamond client converting EUR via eToroMoney gets different fees than a Bronze client performing the same transaction.

Data flows into this table through manual administrative updates (via Billing.GetAllConversionFeesOverride and the BackOffice). The trigger TR_UpdDel_ConversionFeeOverride automatically archives any changed or deleted row to History.ConversionFeeOverride to maintain a full audit trail. Reads flow through Billing.ExchangeRatesByPlayerLevelGet (called by Billing.GetExchangeRatesForCustomer with a @CID parameter) and the view Billing.AllConversionFees, which apply an override priority hierarchy to determine the effective fee for each transaction scenario.

---

## 2. Business Logic

### 2.1 Override Priority Hierarchy

**What**: The system applies the most specific matching override, not just any matching row. Multiple override rows may match a given (PlayerLevel, Currency, FundingType) combination; the highest-specificity rule wins.

**Columns/Parameters Involved**: `PlayerLevelID`, `CurrencyID`, `FundingTypeID`, `CountryID`

**Rules**:
- **Rank 150 - Most specific**: PlayerLevelID > 0 AND CurrencyID > 0 AND FundingTypeID specified (AND optionally CountryID). Exact match for this tier + this currency + this payment method.
- **Rank 130**: PlayerLevelID > 0 AND CurrencyID = 0. Override for this tier across ALL currencies for a given FundingType.
- **Rank 100**: PlayerLevelID = 0 AND CurrencyID > 0. Override for ALL tiers for a specific currency.
- **Rank 80**: PlayerLevelID = 0 AND CurrencyID = 0. Override for ALL tiers and ALL currencies for a given FundingType.
- **Rank 50 - Fallback**: Standard fees from Billing.ConversionFee (no override row matched).
- CountryID = NULL means global (applies to all countries). Non-NULL CountryID adds a further geographic refinement.

**Diagram**:
```
Fee Resolution (highest matching rank wins):
  [Rank 150] PlayerLevel=7 + Currency=EUR + FundingType=eToroMoney + Country=NULL -> fee X
  [Rank 130] PlayerLevel=7 + Currency=ANY + FundingType=eToroMoney              -> fee Y
  [Rank 100] PlayerLevel=ANY + Currency=EUR + FundingType=any                   -> fee Z
  [Rank  80] PlayerLevel=ANY + Currency=ANY + FundingType=eToroMoney            -> fee W
  [Rank  50] Default from Billing.ConversionFee                                 -> fee D
```

### 2.2 Dual Fee Components (Flat + Percentage)

**What**: Each override row stores both a flat minimum fee and a percentage-based fee. The fee engine uses both; for newer payment methods (eToroMoney) the percentage is the operative charge.

**Columns/Parameters Involved**: `DepositFee`, `CashoutFee`, `DepositFeePercentage`, `CashoutFeePercentage`

**Rules**:
- **DepositFee / CashoutFee**: Flat fee amount in minor units (cents). Used for legacy methods (CreditCard=1, WireTransfer=2) where percentage columns are NULL.
- **DepositFeePercentage / CashoutFeePercentage**: Percentage rate (e.g., 0.75 = 0.75%). Used for eToroMoney (FundingTypeID=33) and Trustly (35). NULL when not applicable.
- From live data: eToroMoney rows always have percentage values (0.75%, 1.4%, 1.75%) with flat fee=0; CreditCard/WireTransfer rows always have flat fee values with NULL percentage. GCCInstantBankTransfer (43) uses flat fees only.
- Diamond tier (PlayerLevelID=7) with eToroMoney shows CashoutFee=0 and DepositFee=0 (fee waived) while still carrying DepositFeePercentage=0.75% - indicating tier-level percentage still applies but flat minimum is waived.

### 2.3 Country-Specific Fee Exceptions

**What**: Some player level + currency + funding type combinations have different fees in specific countries.

**Columns/Parameters Involved**: `CountryID`, `PlayerLevelID`, `FundingTypeID`, `CurrencyID`

**Rules**:
- 134 of 148 rows (90.5%) have CountryID=NULL, meaning they apply globally.
- 12 rows target Australia (CountryID=12) with AUD (CurrencyID=5) via eToroMoney (FundingTypeID=33) - higher percentage fees (1.4% and 1.75% vs 0.75% globally).
- 2 rows target United Kingdom (CountryID=218) with GBP via Trustly (FundingTypeID=35) - flat fee overrides.
- The fee lookup in Billing.ExchangeRatesByPlayerLevelGet passes @CountryID from the caller to apply country-specific rules.

### 2.4 Audit Trail via Trigger

**What**: Every modification to fee overrides is captured in the history table for compliance and rollback purposes.

**Columns/Parameters Involved**: Trigger TR_UpdDel_ConversionFeeOverride

**Rules**:
- AFTER UPDATE or DELETE: inserts the DELETED (old) row into History.ConversionFeeOverride with GETUTCDATE() as the archive timestamp.
- INSERT operations are NOT tracked (new rows are not pre-existence, so there is no "before" state to capture).
- ModifictionDate column on the main table (note: misspelled in DDL) records the UTC timestamp of the last change via DEFAULT GETUTCDATE().

---

## 3. Data Overview

| ConversionFeeID | PlayerLevelID | FundingTypeID | CurrencyID | DepositFee | CashoutFee | DepositFeePercentage | CountryID | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1 | 2 (Platinum) | 33 (eToroMoney) | 2 (EUR) | 0 | 75 | 0.75% | NULL | Platinum-tier customers converting EUR via eToroMoney pay 0.75% conversion but no flat deposit fee. Cashout minimum flat fee is 75 minor units. Global (no country restriction). |
| 3 | 7 (Diamond) | 33 (eToroMoney) | 2 (EUR) | 0 | 0 | 0.75% | NULL | Diamond-tier EUR/eToroMoney override waives the flat cashout fee (vs 75 for Platinum). Diamond loyalty benefit: no minimum flat fee but same 0.75% percentage rate applies. |
| 7 | 7 (Diamond) | 35 (Trustly) | 2 (EUR) | 123 | 123 | NULL | 218 (UK) | Country-specific rule: Diamond clients in the United Kingdom using Trustly for EUR transactions pay a 123-unit flat fee for both deposits and cashouts. No percentage fee - Trustly uses flat fee model. |
| 14 | 2 (Platinum) | 2 (WireTransfer) | 5 (AUD) | 75 | 75 | NULL | NULL | Wire transfer in AUD for Platinum tier: 75-unit flat fee for both directions. Percentage columns are NULL - WireTransfer uses flat fee model only. |
| 19 | 1 (Bronze) | 33 (eToroMoney) | 5 (AUD) | 0 | 0 | 1.75% | 12 (Australia) | Bronze customers in Australia converting AUD via eToroMoney pay 1.75% - the highest rate in the table. Australia-specific regulation or higher processing cost for AUD conversion in AU market. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerLevelID | int | NO | - | VERIFIED | eToro Club loyalty tier for which this override applies. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Value 0 means "all tiers" (global override). Implicit FK to Dictionary.PlayerLevel. See [Player Level](_glossary.md#player-level). |
| 2 | FundingTypeID | int | NO | - | VERIFIED | Payment method for which this override applies. Active values in this table: 1=CreditCard, 2=WireTransfer, 33=eToroMoney, 35=Trustly, 43=GCCInstantBankTransfer. Implicit FK to Dictionary.FundingType. |
| 3 | CurrencyID | int | NO | - | VERIFIED | Account denomination currency for which this override applies. References Dictionary.Currency (which is the universal instrument registry; in billing context, CurrencyID refers to actual ISO currencies like EUR=2, GBP=3, AUD=5, CHF=6, NOK=39, SEK=40, PLN=44, HUF=45, DKK=46, CZK=82, RON=521, AEDUSD=349). Value 0 means "any currency". Explicit FK to Dictionary.Currency. |
| 4 | DepositFee | int | NO | - | CODE-BACKED | Flat minimum deposit conversion fee in minor currency units (e.g., cents). Used for flat-fee payment methods (CreditCard, WireTransfer). For eToroMoney rows this is 0, meaning no flat minimum - the percentage (DepositFeePercentage) is the operative charge. |
| 5 | CashoutFee | int | NO | - | CODE-BACKED | Flat minimum cashout (withdrawal) conversion fee in minor currency units. Same model as DepositFee: used for flat-fee methods; 0 for percentage-based methods. Diamond tier rows show CashoutFee=0 (flat minimum waived as loyalty benefit). |
| 6 | ModifictionDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of the last INSERT or UPDATE on this row. Note: column name is intentionally misspelled in DDL ("Modification" -> "Modifiction"). DEFAULT is GETUTCDATE() so new rows auto-populate. The trigger archives the old value to History.ConversionFeeOverride on UPDATE/DELETE. |
| 7 | CountryID | int | YES | - | CODE-BACKED | Optional country scope for this override. NULL=applies globally to all countries. Non-NULL values: 12=Australia (AUD/eToroMoney rows with higher rates), 218=United Kingdom (GBP/Trustly flat fee rows). Passed to Billing.ExchangeRatesByPlayerLevelGet as @CountryID for country-aware fee lookup. Implicit FK to Dictionary.Country. |
| 8 | DepositFeePercentage | decimal(18,2) | YES | - | CODE-BACKED | Percentage-based deposit conversion fee rate (e.g., 0.75 = 0.75%). Used for newer payment methods (eToroMoney=0.75% globally, Trustly). NULL for flat-fee methods (CreditCard, WireTransfer, GCCInstantBankTransfer). Added in PAYIL-8694 (Aug 2024) to support percentage-based fee model. |
| 9 | CashoutFeePercentage | decimal(18,2) | YES | - | CODE-BACKED | Percentage-based cashout conversion fee rate. Mirrors DepositFeePercentage for withdrawal direction. Same values as DepositFeePercentage for symmetric pricing; NULL for flat-fee payment methods. |
| 10 | ConversionFeeID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate identity column. NOT declared as PRIMARY KEY in DDL - uniqueness is enforced via IX_Conv_1 unique index on (PlayerLevelID, FundingTypeID, CurrencyID, CountryID). Used as a stable row reference. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | FK (explicit) | References the instrument/currency registry by currency ID. In billing context, CurrencyID represents the account denomination currency (EUR, GBP, AUD, etc.). |
| PlayerLevelID | Dictionary.PlayerLevel | Implicit | References the loyalty tier lookup. All 7 tier IDs (1-7) plus 0 (global) are valid. Not a declared FK constraint. |
| FundingTypeID | Dictionary.FundingType | Implicit | References the payment method lookup. Not a declared FK constraint. |
| CountryID | Dictionary.Country | Implicit | References the country lookup for geographic fee overrides. Not a declared FK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.ExchangeRatesByPlayerLevelGet | ConversionFeeOverride | CROSS JOIN + filter | Primary reader. JOINs this table with Billing.ConversionFee using a CROSS JOIN filtered by @PlayerLevelID to build the effective fee schedule. Applies the 5-level override priority hierarchy. |
| Billing.GetExchangeRatesForCustomer | ConversionFeeOverride | via EXEC | Looks up customer's PlayerLevelID from Customer.CustomerStatic, then delegates to ExchangeRatesByPlayerLevelGet which reads this table. |
| Billing.GetExchangeRatesForCustomerFunding | ConversionFeeOverride | JOIN/Reader | Customer-facing fee lookup for the funding flow (multiple versions: v2, v3, v4). |
| Billing.GetAllConversionFeesOverride | ConversionFeeOverride | SELECT | Admin/reporting SP. Returns all rows with optional filters by PlayerLevelID, CurrencyID, FundingTypeID. Also UNIONs with Billing.DepositTypeConversionFeeOverride. |
| Billing.AllConversionFees | ConversionFeeOverride | View JOIN | View that flattens the override hierarchy into a ranked result set showing the effective fee per (PlayerLevel, Currency, FundingType) combination. |
| History.ConversionFeeOverride | (trigger target) | Trigger | Receives archived rows from TR_UpdDel_ConversionFeeOverride on UPDATE/DELETE. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ConversionFeeOverride (table)
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
| Billing.ExchangeRatesByPlayerLevelGet | Stored Procedure | CROSS JOIN reader - primary fee resolution engine |
| Billing.GetExchangeRatesForCustomer | Stored Procedure | Indirect reader via ExchangeRatesByPlayerLevelGet |
| Billing.GetExchangeRatesForCustomerFunding | Stored Procedure | Reader (multiple versions v2/v3/v4) |
| Billing.GetAllConversionFeesOverride | Stored Procedure | SELECT reader for admin/reporting |
| Billing.AllConversionFees | View | Part of the ranked fee hierarchy union |
| History.ConversionFeeOverride | Table | Trigger-written audit archive (TR_UpdDel_ConversionFeeOverride) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_Conv_1 | NC UNIQUE | PlayerLevelID ASC, FundingTypeID ASC, CurrencyID ASC, CountryID ASC | - | - | Active (DICTIONARY filegroup) |
| IX_Conv_2 | NC UNIQUE | PlayerLevelID ASC, FundingTypeID ASC, CurrencyID ASC, CountryID ASC | - | - | Active (DICTIONARY filegroup) - **DUPLICATE of IX_Conv_1** |
| i_CureenyID | NC | CurrencyID ASC | - | - | Active (PRIMARY filegroup) - note: index name has typo ("Cureeny" instead of "Currency") |

> Note: IX_Conv_1 and IX_Conv_2 are **identical** (same key columns, same options, same filegroup). This is a DDL defect - one of them is redundant and wastes storage and maintenance overhead.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BillingConversionFeeOverride_ModificationDate | DEFAULT | getutcdate() for ModifictionDate - auto-populates UTC timestamp on INSERT |
| FK_ConversionFeeOverride_DictionaryCurrency | FK | CurrencyID -> Dictionary.Currency(CurrencyID) - enforces referential integrity to the instrument/currency registry |
| TR_UpdDel_ConversionFeeOverride | TRIGGER | AFTER UPDATE, DELETE - archives DELETED rows to History.ConversionFeeOverride |

---

## 8. Sample Queries

### 8.1 Get all active conversion fee overrides for a specific loyalty tier

```sql
SELECT
    cfo.ConversionFeeID,
    pl.Name AS PlayerLevel,
    ft.Name AS FundingType,
    c.Abbreviation AS Currency,
    co.Name AS Country,
    cfo.DepositFee,
    cfo.CashoutFee,
    cfo.DepositFeePercentage,
    cfo.CashoutFeePercentage,
    cfo.ModifictionDate
FROM Billing.ConversionFeeOverride cfo WITH (NOLOCK)
LEFT JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON cfo.PlayerLevelID = pl.PlayerLevelID
LEFT JOIN Dictionary.FundingType ft WITH (NOLOCK) ON cfo.FundingTypeID = ft.FundingTypeID
LEFT JOIN Dictionary.Currency c WITH (NOLOCK) ON cfo.CurrencyID = c.CurrencyID
LEFT JOIN Dictionary.Country co WITH (NOLOCK) ON cfo.CountryID = co.CountryID
WHERE cfo.PlayerLevelID = 7  -- Diamond
ORDER BY ft.Name, c.Abbreviation
```

### 8.2 Get effective conversion fees for a specific customer (by CID)

```sql
-- Uses the authoritative stored procedure that applies the full override priority hierarchy
EXEC Billing.GetExchangeRatesForCustomer
    @CID = 12345,
    @CountryID = NULL  -- NULL = use customer's registration country from CustomerStatic
```

### 8.3 Find country-specific fee exceptions

```sql
SELECT
    pl.Name AS PlayerLevel,
    ft.Name AS FundingType,
    c.Abbreviation AS Currency,
    co.Name AS Country,
    cfo.DepositFee,
    cfo.CashoutFee,
    cfo.DepositFeePercentage,
    cfo.CashoutFeePercentage
FROM Billing.ConversionFeeOverride cfo WITH (NOLOCK)
INNER JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON cfo.PlayerLevelID = pl.PlayerLevelID
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK) ON cfo.FundingTypeID = ft.FundingTypeID
INNER JOIN Dictionary.Currency c WITH (NOLOCK) ON cfo.CurrencyID = c.CurrencyID
INNER JOIN Dictionary.Country co WITH (NOLOCK) ON cfo.CountryID = co.CountryID
WHERE cfo.CountryID IS NOT NULL
ORDER BY co.Name, pl.Name
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-4807 | Jira | Initial implementation of Billing.ExchangeRatesByPlayerLevelGet (Aug 2022) - established the CROSS JOIN pattern between ConversionFee and ConversionFeeOverride with the multi-level priority hierarchy |
| PAYIL-5173 | Jira | Performance revision (Oct 2022) - refactored GetExchangeRatesForCustomer to delegate to ExchangeRatesByPlayerLevelGet |
| PAYSOLB-1018 | Jira | Jul 2022 - added CountryID filter to GetExchangeRatesForCustomer, enabling country-specific fee overrides |
| PAYIL-8694 | Jira | Aug 2024 - added DepositFeePercentage and CashoutFeePercentage columns to support percentage-based fee model alongside existing flat fees |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED (3 columns), 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 4 Jira (from SP comments) | Procedures: 3 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.ConversionFeeOverride | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ConversionFeeOverride.sql*
