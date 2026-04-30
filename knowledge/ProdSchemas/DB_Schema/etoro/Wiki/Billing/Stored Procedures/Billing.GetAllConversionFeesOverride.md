# Billing.GetAllConversionFeesOverride

> Returns the combined conversion fee override configuration from both ConversionFeeOverride (player-tier fees) and DepositTypeConversionFeeOverride (deposit-type fees) as a unified UNION ALL result set, optionally filtered by player level, currency, and/or funding type.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlayerLevelID + @CurrencyID + @FundingTypeID - all optional, all default NULL |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetAllConversionFeesOverride` is the administrative read path for the complete currency conversion fee override configuration. It unifies two complementary override tables into a single result set:

1. **`Billing.ConversionFeeOverride`**: Stores standard conversion fee overrides for loyalty club tiers (PlayerLevelID), payment methods (FundingTypeID), currencies (CurrencyID), and optionally countries (CountryID). Supports both deposit and cashout fee components. This is the primary override table used by the fee calculation engine.

2. **`Billing.DepositTypeConversionFeeOverride`**: Stores deposit-type-specific overrides (e.g., fees for RecurringInvestment deposits). Extends ConversionFeeOverride by adding a `DepositTypeID` dimension. No cashout fees or country dimension. Currently configured for CreditCard RecurringInvestment (all fees = 0).

The UNION ALL with nullable filters allows the calling tool to load all overrides (`@PlayerLevelID=NULL, @CurrencyID=NULL, @FundingTypeID=NULL`) or drill into a specific subset. Back-office fee management interfaces and the `Billing.AllConversionFees` view depend on this data to display the fee configuration for payment operations.

**Technical note**: The `ModifictionDate` column name in `Billing.ConversionFeeOverride` has a typo (missing 'a'). This procedure aliases it as `ModificationDate` in both result sets, normalizing the output. The `Billing.DepositTypeConversionFeeOverride` table has the correctly spelled `ModificationDate` column.

---

## 2. Business Logic

### 2.1 Optional-Filter UNION ALL Pattern

**What**: Returns all matching override rows from both tables based on up to three optional criteria.

**Columns/Parameters Involved**: `@PlayerLevelID`, `@CurrencyID`, `@FundingTypeID`

**Rules**:
- `(@Param = column OR @Param IS NULL)` pattern: each filter is applied only when the parameter is non-NULL. Passing all three as NULL returns the complete combined override configuration.
- Filters apply identically to both tables in the UNION ALL - the same three parameters filter both result sets.
- `UNION ALL` (not UNION): preserves duplicates and preserves the source identity of each row. The `DepositTypeID` column distinguishes rows from the two sources: NULL for ConversionFeeOverride rows, non-NULL for DepositTypeConversionFeeOverride rows.

### 2.2 Source Table Differences in Result Schema

**What**: The two source tables have different columns; NULLs are used to normalize the schema for UNION ALL.

**Rules**:
- ConversionFeeOverride rows: `DepositTypeID = NULL`, `CashoutFee` from table, `CashoutFeePercentage` from table, `CountryID` from table.
- DepositTypeConversionFeeOverride rows: `DepositTypeID` from table (distinguishes these rows), `CashoutFee = NULL`, `CashoutFeePercentage = NULL`, `CountryID = NULL`.
- Both sources return: `PlayerLevelID`, `FundingTypeID`, `CurrencyID`, `DepositFee`, `ModificationDate`, `DepositFeePercentage`.
- No isolation hints. No SET NOCOUNT ON. No RETURN statement.

### 2.3 Fee Structure Context

**What**: The returned fee columns follow the override priority hierarchy from ConversionFeeOverride.

**Rules**:
- `DepositFee` / `CashoutFee`: flat fee in minor units (cents). Used for legacy methods (CreditCard, WireTransfer). May be NULL for DepositTypeConversionFeeOverride rows.
- `DepositFeePercentage` / `CashoutFeePercentage`: percentage rate (e.g., 0.75 = 0.75%). Used for eToroMoney, Trustly. NULL when not applicable.
- `PlayerLevelID=0` = applies to ALL player tiers. PlayerLevelID>0 = specific loyalty club tier (1=Bronze ... 7=Diamond).
- `CountryID=NULL` = global override; non-NULL = country-specific fee (ConversionFeeOverride rows only).
- See `Billing.ConversionFeeOverride` Section 2.1 for the full override priority hierarchy (Ranks 50-150).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlayerLevelID | INT | YES | NULL | CODE-BACKED | Optional filter for loyalty tier. 0=all tiers, 1-7=specific tier. NULL returns all player levels. |
| 2 | @CurrencyID | INT | YES | NULL | CODE-BACKED | Optional filter for account currency. NULL returns all currencies. |
| 3 | @FundingTypeID | INT | YES | NULL | CODE-BACKED | Optional filter for payment method type. NULL returns all funding types. |

**Return columns** (UNION ALL of both tables):

| # | Column | Type | Source | Confidence | Description |
|---|--------|------|--------|------------|-------------|
| R1 | PlayerLevelID | INT | Both | CODE-BACKED | Loyalty club tier. 0=all tiers, 1-7=specific. FK to Customer.PlayerLevel. |
| R2 | FundingTypeID | INT | Both | CODE-BACKED | Payment method type. FK to Dictionary.FundingType. |
| R3 | CurrencyID | INT | Both | CODE-BACKED | Account currency. 0=all currencies. FK to Dictionary.Currency. |
| R4 | DepositFee | INT | Both | CODE-BACKED | Flat deposit fee in minor units (cents). 0 = no flat fee (percentage-based). |
| R5 | CashoutFee | INT | ConversionFeeOverride only | CODE-BACKED | Flat cashout fee in minor units. NULL for DepositTypeConversionFeeOverride rows. |
| R6 | ModificationDate | DATETIME | Both | CODE-BACKED | Last modification timestamp. Aliased from `ModifictionDate` (typo) in ConversionFeeOverride; correctly named in DepositTypeConversionFeeOverride. |
| R7 | CountryID | INT | ConversionFeeOverride only | CODE-BACKED | Country for geographic override. NULL = global. NULL for all DepositTypeConversionFeeOverride rows. |
| R8 | DepositFeePercentage | DECIMAL | Both | CODE-BACKED | Percentage deposit fee (e.g., 0.75 = 0.75%). NULL when flat fee applies instead. |
| R9 | CashoutFeePercentage | DECIMAL | ConversionFeeOverride only | CODE-BACKED | Percentage cashout fee. NULL for DepositTypeConversionFeeOverride rows. |
| R10 | DepositTypeID | INT | DepositTypeConversionFeeOverride only | CODE-BACKED | Deposit type this override applies to (e.g., 5=RecurringInvestment). NULL for all ConversionFeeOverride rows. Distinguishes the two data sources. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Part 1 of UNION | Billing.ConversionFeeOverride | Reader | Standard conversion fee overrides by tier/currency/funding-type/country |
| Part 2 of UNION | Billing.DepositTypeConversionFeeOverride | Reader | Deposit-type-specific conversion fee overrides |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice fee management | External | Caller | Reads and displays the combined conversion fee override configuration |
| Admin tooling | External | Caller | Fee audit and configuration review |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetAllConversionFeesOverride (procedure)
├── Billing.ConversionFeeOverride (table)
└── Billing.DepositTypeConversionFeeOverride (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ConversionFeeOverride | Table | First UNION branch: standard conversion fee overrides |
| Billing.DepositTypeConversionFeeOverride | Table | Second UNION branch: deposit-type-specific fee overrides |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice / admin fee tools | External | Reads combined override configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. No SET NOCOUNT ON. No isolation hints (read committed). No RETURN. No TRY/CATCH. UNION ALL - row count = sum of matching rows from both tables. Column `ModifictionDate` (typo in ConversionFeeOverride) aliased to `ModificationDate`. DepositTypeID=NULL identifies ConversionFeeOverride rows; DepositTypeID IS NOT NULL identifies DepositTypeConversionFeeOverride rows.

---

## 8. Sample Queries

### 8.1 Get all conversion fee overrides (no filter)

```sql
EXEC [Billing].[GetAllConversionFeesOverride];
-- Returns all rows from both tables
```

### 8.2 Get overrides for a specific funding type

```sql
EXEC [Billing].[GetAllConversionFeesOverride]
    @FundingTypeID = 33;  -- eToroMoney
```

### 8.3 Get overrides for Diamond tier (PlayerLevelID=7) in EUR (CurrencyID=2)

```sql
EXEC [Billing].[GetAllConversionFeesOverride]
    @PlayerLevelID = 7,
    @CurrencyID = 2;
```

### 8.4 Find deposit-type-specific overrides (DepositTypeConversionFeeOverride rows)

```sql
EXEC [Billing].[GetAllConversionFeesOverride]
    @FundingTypeID = 1;  -- CreditCard
-- Look for rows where DepositTypeID IS NOT NULL - these come from DepositTypeConversionFeeOverride
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetAllConversionFeesOverride | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetAllConversionFeesOverride.sql*
