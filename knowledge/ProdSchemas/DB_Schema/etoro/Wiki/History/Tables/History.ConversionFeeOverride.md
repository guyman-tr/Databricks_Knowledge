# History.ConversionFeeOverride

> Application-managed temporal history of conversion fee overrides by player level, funding type, currency, and country - 5,793 rows actively written today (2026-03-19), capturing each override snapshot at the time of modification.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (PlayerLevelID, FundingTypeID, CurrencyID, ModifictionDate) - composite PK CLUSTERED |
| **Partition** | No |
| **Temporal** | Application-managed history (ModifictionDate as PK component) |
| **Indexes** | 1 (PK clustered, FILLFACTOR=95) |

---

## 1. Business Meaning

History.ConversionFeeOverride stores the complete history of conversion fee overrides, one row per override snapshot. It allows specific combinations of player level, funding type, currency, and country to be charged different deposit/cashout fees than the defaults in History.ConversionFee.

Each row captures an override fee configuration at a specific `ModifictionDate` (note: intentional typo inherited from the base table - "Modification" misspelled as "Modifiction"). Because ModifictionDate is part of the composite PK, multiple rows can exist for the same (PlayerLevelID, FundingTypeID, CurrencyID) combination, forming a full point-in-time history.

5,793 rows with **active writes as of today (2026-03-19)** - this table is in production use. 8 distinct player levels, 14 funding types, 34 currencies are represented.

---

## 2. Business Logic

### 2.1 Fee Override Hierarchy

**What**: Overrides the default conversion fee for a specific combination of player level + funding type + currency + (optionally) country.

**Override dimensions**:
- **PlayerLevelID**: Player tier/level (8 distinct values - e.g., Standard, Gold, Platinum, etc.)
- **FundingTypeID**: Payment method (14 types - credit card, wire transfer, PayPal, etc.)
- **CurrencyID**: Currency being converted (34 currencies)
- **CountryID**: Optional country-specific further restriction (NULL = applies to all countries in the player/funding/currency combination)

**Fee columns**:
- DepositFee = 0 frequently (zero deposit fee for certain combinations, likely promotional or regulatory)
- CashoutFee = 0 frequently (zero cashout fee)
- Observed recent rows: mostly DepositFee=0, CashoutFee=0 (fee waivers)

### 2.2 Application-Managed Temporal Pattern

**What**: Each time a fee override is created or updated, a new row is inserted with the current ModifictionDate. This preserves the full history of override changes.

**Rules**:
- PK includes ModifictionDate - no UPDATE to existing rows, only INSERTs
- The "current" override is the row with the MAX(ModifictionDate) for a given (PlayerLevelID, FundingTypeID, CurrencyID, CountryID) key
- FILLFACTOR=95 (high fill factor, suited for append-only insert pattern)

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 5,793 |
| **Date Range** | 2020-05-03 to 2026-03-19 (active today) |
| **Distinct Player Levels** | 8 |
| **Distinct Funding Types** | 14 |
| **Distinct Currencies** | 34 |
| **Status** | Actively written |

Sample rows (most recent):

| PlayerLevelID | FundingTypeID | CurrencyID | CountryID | DepositFee | CashoutFee | ModifictionDate |
|--------------|--------------|-----------|----------|------------|------------|----------------|
| 6 | 2 | 6 | 218 | 0 | 0 | 2026-03-19 00:58:22 |
| 2 | 2 | 3 | 79 | 0 | 0 | 2026-03-19 00:58:21 |
| 6 | 2 | 5 | 218 | 0 | 0 | 2026-03-19 00:58:19 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerLevelID | int | NO | - | VERIFIED | Player tier/level for which this fee override applies. Implicit FK to Dictionary.PlayerLevel. 8 distinct values (e.g., Standard, Silver, Gold, Platinum tiers). PK component. |
| 2 | FundingTypeID | int | NO | - | VERIFIED | Payment method / funding channel for which this override applies. Implicit FK to Dictionary.FundingType. 14 distinct types (e.g., credit card, wire transfer, e-wallet). PK component. |
| 3 | CurrencyID | int | NO | - | VERIFIED | Currency for which this fee override applies. Implicit FK to Dictionary.Currency. 34 currencies observed. PK component. |
| 4 | DepositFee | int | NO | - | VERIFIED | Override deposit fee in minor currency units. 0 = zero-fee deposit (fee waived for this combination). Overrides the default from History.ConversionFee. |
| 5 | CashoutFee | int | NO | - | VERIFIED | Override cashout fee in minor currency units. 0 = zero-fee cashout (fee waived). |
| 6 | ModifictionDate | datetime | NO | - | VERIFIED | Timestamp when this override was created/applied. Part of the composite PK - enables full history. Note: column name has typo ("Modifiction" not "Modification") inherited from base table design. |
| 7 | CountryID | int | YES | - | CODE-BACKED | Optional country restriction. When set, this override applies only to customers from this country. NULL = applies to all countries matching the other dimensions. Implicit FK to Dictionary.Country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerLevelID | Dictionary.PlayerLevel | Implicit | Player tier for which the fee applies. |
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method for which the fee applies. |
| CurrencyID | Dictionary.Currency | Implicit | Currency for the conversion fee. |
| CountryID | Dictionary.Country | Implicit | Optional country scope for the override. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Options |
|-----------|------|-------------|---------|
| PK_HistoryConversionFeeOverride | CLUSTERED PK | PlayerLevelID ASC, FundingTypeID ASC, CurrencyID ASC, ModifictionDate ASC | FILLFACTOR=95 |

High FILLFACTOR=95 is appropriate for an append-only insert pattern (new rows always have the latest ModifictionDate).

---

## 8. Sample Queries

### 8.1 Get the current fee override for a specific combination
```sql
SELECT PlayerLevelID, FundingTypeID, CurrencyID, CountryID, DepositFee, CashoutFee, ModifictionDate
FROM History.ConversionFeeOverride WITH (NOLOCK)
WHERE PlayerLevelID = 6
  AND FundingTypeID = 2
  AND CurrencyID = 6
ORDER BY ModifictionDate DESC;
-- First row = current override
```

### 8.2 All active zero-fee overrides as of today
```sql
SELECT PlayerLevelID, FundingTypeID, CurrencyID, CountryID, DepositFee, CashoutFee
FROM History.ConversionFeeOverride h1 WITH (NOLOCK)
WHERE ModifictionDate = (
    SELECT MAX(h2.ModifictionDate)
    FROM History.ConversionFeeOverride h2 WITH (NOLOCK)
    WHERE h2.PlayerLevelID = h1.PlayerLevelID
      AND h2.FundingTypeID = h1.FundingTypeID
      AND h2.CurrencyID = h1.CurrencyID
)
  AND DepositFee = 0 AND CashoutFee = 0;
```

---

*Generated: 2026-03-19 | Quality: 8.9/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.ConversionFeeOverride | Type: Table | Source: etoro/etoro/History/Tables/History.ConversionFeeOverride.sql*
