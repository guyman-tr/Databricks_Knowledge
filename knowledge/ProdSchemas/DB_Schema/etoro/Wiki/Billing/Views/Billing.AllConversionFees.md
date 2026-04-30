# Billing.AllConversionFees

> Resolved conversion fee view that flattens the five-level override priority hierarchy into a single effective DepositFee and CashoutFee for every valid (PlayerLevel, Currency, FundingType) combination.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | Effective per (PlayerLevelID, CurrencyID, FundingTypeID) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.AllConversionFees` answers the single question every payment flow needs: "What is the conversion fee for THIS player tier, THIS currency, and THIS payment method?" Without this view, callers would need to implement the five-level rank-based override resolution logic themselves every time a fee is needed.

The view exists because `Billing.ConversionFee` stores base fees and `Billing.ConversionFeeOverride` stores loyalty-tier exceptions, but neither table alone gives the final answer. The fee engine has five override specificity levels (exact match -> by player level -> by currency -> by funding type -> default), and the winning rule must be selected before charging a customer. This view pre-resolves that selection.

Data flows from two sources: `Billing.ConversionFee` (the baseline rate per currency) and `Billing.ConversionFeeOverride` (tier-specific exceptions). The view UNION-combines all possible matching rules, ranks them by specificity using `ROW_NUMBER()`, and returns only `Rnum = 1` (the winner) for each (PlayerLevelID, CurrencyID, FundingTypeID) triple. The result is a flat, query-ready fee schedule covering every supported combination - 8,428 rows as of the last measurement, covering 7 player levels x 28+ currencies x many funding types.

---

## 2. Business Logic

### 2.1 Five-Level Override Priority Resolution

**What**: The view applies a deterministic priority hierarchy to select the single most specific conversion fee rule for each (PlayerLevel, Currency, FundingType) combination.

**Columns/Parameters Involved**: `PlayerLevelID`, `CurrencyID`, `FundingTypeID`, `DepositFee`, `CashoutFee`

**Rules**:
- Rank 150 (most specific): Override row with PlayerLevelID > 0 AND CurrencyID > 0 - exact tier + exact currency match
- Rank 130: Override row with PlayerLevelID > 0 AND CurrencyID = 0 - applies to a tier across ALL currencies for a given FundingType
- Rank 100: Override row with PlayerLevelID = 0 AND CurrencyID > 0 - applies to ALL tiers for a specific currency
- Rank 80: Override row with PlayerLevelID = 0 AND CurrencyID = 0 - applies to ALL tiers and ALL currencies for a FundingType
- Rank 50 (fallback): Base fee from Billing.ConversionFee, cross-joined with all player levels and funding types
- `ROW_NUMBER() OVER (PARTITION BY PlayerLevelID, CurrencyID, FundingTypeID ORDER BY RankNum DESC)` selects the highest-rank match; WHERE Rnum = 1 retains only the winner

**Diagram**:
```
Fee Resolution for (PlayerLevel=7 Diamond, Currency=EUR, FundingType=eToroMoney):
  [Rank 150] ConversionFeeOverride: PlayerLevel=7, Currency=EUR, FundingType=33 -> WINS (DepositFee=0)
  [Rank 130] ConversionFeeOverride: PlayerLevel=7, Currency=0  , FundingType=33 -> skipped (lower rank)
  [Rank 100] ConversionFeeOverride: PlayerLevel=0, Currency=EUR, FundingType=any-> skipped
  [Rank  80] ConversionFeeOverride: PlayerLevel=0, Currency=0  , FundingType=33 -> skipped
  [Rank  50] ConversionFee base:    PlayerLevel=7 (all), Currency=EUR            -> skipped

Fee Resolution for (PlayerLevel=1 Bronze, Currency=EUR, FundingType=CreditCard):
  [No override rows match] -> Rank 50 fallback wins -> DepositFee=150, CashoutFee=150
```

### 2.2 Cartesian Expansion for Default Fees

**What**: The base fee table has one row per currency, but the view must produce a fee for every (PlayerLevel, Currency, FundingType) combination. The `DefaultFees` CTE handles this via implicit CROSS JOINs.

**Columns/Parameters Involved**: `PlayerLevelID`, `FundingTypeID`, `InstrumentID`

**Rules**:
- `AllCurrencies` CTE: reads all (CurrencyID, InstrumentID) pairs from ConversionFee - defines the supported currency universe
- `AllPlayerLevelIDs` CTE: reads all player level IDs from Dictionary.PlayerLevel
- `AllFundingTypes` CTE: reads all funding type IDs from Dictionary.FundingType
- `DefaultFees` CTE: cross-joins ConversionFee x AllPlayerLevels x AllCurrencies x AllFundingTypes to produce a base fee row for every possible combination
- Override CTEs then join subsets of this space to inject higher-ranked exceptions
- Result: every combination gets exactly one row from the UNION, ranked by specificity, with the winner selected

---

## 3. Data Overview

| PlayerLevelID | CurrencyID | FundingTypeID | DepositFee | CashoutFee | Meaning |
|---|---|---|---|---|---|
| 1 (Bronze) | 2 (EUR) | 1 (CreditCard) | 150 | 150 | Bronze customer depositing EUR via credit card pays the standard 150-cent flat conversion fee (fallback to ConversionFee base rate - no override exists for Bronze + EUR + CreditCard). |
| 1 (Bronze) | 6 (CHF) | 1 (CreditCard) | 90 | 90 | Bronze customer depositing CHF via credit card: 90-unit flat fee - lower than the base ConversionFee rate of 140/150, indicating an active override row for CHF/CreditCard. |
| 7 (Diamond) | 2 (EUR) | 33 (eToroMoney) | 0 | 0 | Diamond-tier loyalty benefit: flat conversion fee waived entirely for EUR via eToroMoney. The ConversionFeeOverride rank-150 row wins. Percentage fees (0.75%) still apply separately. |
| 7 (Diamond) | 6 (CHF) | 33 (eToroMoney) | 140 | 150 | Diamond + CHF + eToroMoney: no specific override exists, so the base ConversionFee rate (140 deposit / 150 cashout) applies. Demonstrates that Diamond benefits are currency-selective. |
| 1 (Bronze) | 38 (CNY) | 1 (CreditCard) | 400 | 400 | Bronze depositing CNY via credit card pays 400 CNY subunits (approx. equivalent to EUR 150 flat fee). Base ConversionFee rate applies. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerLevelID | int | NO | - | CODE-BACKED | eToro Club loyalty tier for which this fee row applies. Sourced from Dictionary.PlayerLevel: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Every tier appears in this view for every currency and funding type combination, with the tier-appropriate fee (override if available, base rate otherwise). Inherited from Billing.ConversionFeeOverride.PlayerLevelID and Dictionary.PlayerLevel.PlayerLevelID. |
| 2 | CurrencyID | int | NO | - | CODE-BACKED | Account denomination currency for which this fee applies. Defines the universe of supported non-USD currencies from Billing.ConversionFee. Key values: 2=EUR, 3=GBP, 5=AUD, 6=CHF, 38=CNY, 39=NOK, 40=SEK, 44=PLN, 45=HUF, 46=DKK, 444=BRL, 452=CLP, 453=COP. CurrencyID=1 (USD) is absent because USD is eToro's base currency requiring no conversion. Implicit FK to Dictionary.Currency. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | The forex trading instrument for this currency pair (e.g., EUR/USD=1, GBP/USD=2, AUD/USD=7, CHF/USD=6). Sourced from Billing.ConversionFee.InstrumentID - the instrument used to retrieve the current bid/ask exchange rate during conversion calculation. References Trade.Instrument implicitly. |
| 4 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method for which this fee applies. Sourced from Dictionary.FundingType and propagated through the CTE union. Every funding type appears for every (player level, currency) combination. Representative values active in overrides: 1=CreditCard, 2=WireTransfer, 33=eToroMoney, 35=Trustly, 43=GCCInstantBankTransfer. For base-fee fallback rows (Rank 50), all funding types get the same base ConversionFee rate. |
| 5 | DepositFee | int | NO | - | CODE-BACKED | Effective flat deposit conversion fee in minor currency units (cents, pence, subunits) for this (PlayerLevel, Currency, FundingType) combination, after priority resolution. Value 0 indicates a loyalty tier benefit with flat fee waived (Diamond + eToroMoney rows). For percentage-based payment methods (eToroMoney, Trustly), the percentage fee is stored separately in ConversionFeeOverride.DepositFeePercentage and is NOT surfaced by this view - this view only returns the flat fee component. |
| 6 | CashoutFee | int | NO | - | CODE-BACKED | Effective flat cashout (withdrawal) conversion fee in minor currency units for this (PlayerLevel, Currency, FundingType) combination, after priority resolution. Mirrors DepositFee semantics. May differ from DepositFee (e.g., base ConversionFee for CHF has DepositFee=140 vs CashoutFee=150). Value 0 indicates Diamond tier cashout flat fee waived for supported currencies via eToroMoney. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID, InstrumentID | Billing.ConversionFee | Source (CTE AllCurrencies + DefaultFees) | Base fee source: provides the currency universe and default DepositFee/CashoutFee when no override applies |
| PlayerLevelID, CurrencyID, FundingTypeID, DepositFee, CashoutFee | Billing.ConversionFeeOverride | Source (CTEs SpecificOverRide through OverRidePerFundingTypeID) | Override fee source: provides tier-specific fees at ranks 150, 130, 100, and 80 |
| PlayerLevelID | Dictionary.PlayerLevel | Source (CTE AllPlayerLevelIDs) | Enumerates all player tier IDs to cross-join into the fee matrix |
| FundingTypeID | Dictionary.FundingType | Source (CTE AllFundingTypes) | Enumerates all funding type IDs to cross-join into the fee matrix |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedures reference this view directly | - | - | The view name appears only in GetAllConversionFeesOverride.sql as a partial name match (the SP reads ConversionFeeOverride directly, not this view). Admin/reporting consumers likely query this view interactively. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AllConversionFees (view)
├── Billing.ConversionFee (table)
├── Billing.ConversionFeeOverride (table)
├── Dictionary.PlayerLevel (table)
└── Dictionary.FundingType (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ConversionFee | Table | AllCurrencies CTE + DefaultFees CTE: provides the CurrencyID/InstrumentID universe and base DepositFee/CashoutFee (Rank 50 fallback) |
| Billing.ConversionFeeOverride | Table | SpecificOverRide, OverRidePerPlayerLevelID, OverRidePerCurrencyID, OverRidePerFundingTypeID CTEs: provides override fees at ranks 150, 130, 100, 80 |
| Dictionary.PlayerLevel | Table | AllPlayerLevelIDs CTE: enumerates all tier IDs for Cartesian expansion |
| Dictionary.FundingType | Table | AllFundingTypes CTE: enumerates all funding type IDs for Cartesian expansion |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered in Billing schema | - | View is available for ad-hoc admin queries and external consumers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING, no WITH CHECK OPTION. The view uses CTEs and UNION, which SQL Server does not allow under SCHEMABINDING.

---

## 8. Sample Queries

### 8.1 Get the effective conversion fee for a specific customer scenario

```sql
-- What does a Diamond (PlayerLevelID=7) customer pay to convert EUR via eToroMoney?
SELECT PlayerLevelID, CurrencyID, FundingTypeID, DepositFee, CashoutFee
FROM Billing.AllConversionFees WITH (NOLOCK)
WHERE PlayerLevelID = 7
  AND CurrencyID = 2      -- EUR
  AND FundingTypeID = 33  -- eToroMoney
```

### 8.2 Compare fees across loyalty tiers for a given currency and payment method

```sql
-- Compare all tier fees for EUR credit card deposits
SELECT
    acf.PlayerLevelID,
    pl.Name AS PlayerLevel,
    acf.CurrencyID,
    acf.FundingTypeID,
    acf.DepositFee,
    acf.CashoutFee
FROM Billing.AllConversionFees acf WITH (NOLOCK)
INNER JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON acf.PlayerLevelID = pl.PlayerLevelID
WHERE acf.CurrencyID = 2     -- EUR
  AND acf.FundingTypeID = 1  -- CreditCard
ORDER BY acf.PlayerLevelID
```

### 8.3 Find all combinations where an override reduces the base fee

```sql
-- Show cases where the effective fee differs from the base ConversionFee rate
-- (i.e., an override is winning for this combination)
SELECT
    acf.PlayerLevelID,
    pl.Name AS PlayerLevel,
    acf.CurrencyID,
    acf.FundingTypeID,
    ft.Name AS FundingType,
    acf.DepositFee,
    acf.CashoutFee,
    cf.DepositFee AS BaseDepositFee,
    cf.CashoutFee AS BaseCashoutFee
FROM Billing.AllConversionFees acf WITH (NOLOCK)
INNER JOIN Billing.ConversionFee cf WITH (NOLOCK) ON acf.CurrencyID = cf.CurrencyID
INNER JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON acf.PlayerLevelID = pl.PlayerLevelID
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK) ON acf.FundingTypeID = ft.FundingTypeID
WHERE acf.DepositFee <> cf.DepositFee
   OR acf.CashoutFee <> cf.CashoutFee
ORDER BY acf.PlayerLevelID, acf.CurrencyID, acf.FundingTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.AllConversionFees | Type: View | Source: etoro/etoro/Billing/Views/Billing.AllConversionFees.sql*
