# Billing.DepositTypeConversionFeeOverride

> Temporal configuration table for deposit conversion fee overrides segmented by deposit type - extends ConversionFeeOverride by adding a DepositTypeID dimension, currently configured for RecurringInvestment (DepositTypeID=5) fee overrides across player levels and currencies.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | DepositTypeConversionFeeID (IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (PK clustered) |
| **Temporal** | Yes - SYSTEM_VERSIONING (history in History.BillingDepositTypeConversionFeeOverride) |

---

## 1. Business Meaning

`Billing.DepositTypeConversionFeeOverride` is a configuration table that stores deposit conversion fee overrides with an additional `DepositTypeID` dimension not present in the older `Billing.ConversionFeeOverride` table. Where ConversionFeeOverride configures fees by (PlayerLevel, FundingType, Currency), this table adds deposit type (Regular, RecurringInvestment, etc.) to enable fee differentiation by how the deposit is initiated.

Currently all 210 rows configure CreditCard (FundingTypeID=1) RecurringInvestment (DepositTypeID=5) fees as zero for 7 player levels x 30 currencies. This reflects that recurring investment deposits via credit card carry no conversion fee regardless of player level or account currency.

The `Trace` computed column captures the SQL Server session context (hostname, app name, username, SPID, database, object name) as JSON at write time - same diagnostic pattern as `Billing.AftRouting`. System versioning preserves the full history of fee changes in `History.BillingDepositTypeConversionFeeOverride`.

The table is read by `Billing.GetAllConversionFeesOverride`, which UNIONs it with `Billing.ConversionFeeOverride` to provide a single combined fee override view. It is also consumed by `Billing.GetExchangeRatesForCustomerFunding_v4` in the deposit flow.

---

## 2. Business Logic

### 2.1 Deposit-Type-Specific Fee Override

**What**: Provides conversion fee configuration for specific deposit types, complementing the base ConversionFeeOverride table.

**Columns/Parameters Involved**: `PlayerLevelID`, `FundingTypeID`, `CurrencyID`, `DepositTypeID`, `DepositFee`, `DepositFeePercentage`

**Rules**:
- `GetAllConversionFeesOverride` UNIONs this table with `Billing.ConversionFeeOverride`:
  - From ConversionFeeOverride: PlayerLevelID, FundingTypeID, CurrencyID, DepositFee, CashoutFee, CountryID, DepositFeePercentage, CashoutFeePercentage, NULL AS DepositTypeID
  - From DepositTypeConversionFeeOverride: PlayerLevelID, FundingTypeID, CurrencyID, DepositFee, NULL AS CashoutFee, NULL AS CountryID, DepositFeePercentage, NULL AS CashoutFeePercentage, DepositTypeID
- When DepositTypeID is populated (from this table), the fee applies only to that specific deposit type.
- `DepositFee` (int): flat fee in basis points or cents (depending on calling context).
- `DepositFeePercentage` (decimal 18,2): percentage fee, NULL when not applicable.
- Currently all 210 rows have DepositFee=0 and DepositFeePercentage=0 - no active fee overrides.

### 2.2 Structure (7 PlayerLevels x 1 FundingType x 30 Currencies)

**What**: The current data is a complete grid for RecurringInvestment via CreditCard.

**Rules**:
- 7 PlayerLevels (1-7) x FundingTypeID=1 (CreditCard) x 30 currencies x DepositTypeID=5 (RecurringInvestment) = 210 rows.
- All rows were last modified 2025-02-24 (bulk configuration update).
- The temporal history table captures what fees were in place before February 2025.

---

## 3. Data Overview

| PlayerLevelID | DepositTypeID | FundingType | Row Count | Unique Currencies | DepositFee | DepositFeePercentage |
|--------------|--------------|-------------|-----------|-------------------|------------|---------------------|
| 1 | 5 (RecurringInvestment) | CreditCard | 30 | 30 | 0 | 0 |
| 2 | 5 (RecurringInvestment) | CreditCard | 30 | 30 | 0 | 0 |
| 3 | 5 (RecurringInvestment) | CreditCard | 30 | 30 | 0 | 0 |
| 4 | 5 (RecurringInvestment) | CreditCard | 30 | 30 | 0 | 0 |
| 5 | 5 (RecurringInvestment) | CreditCard | 30 | 30 | 0 | 0 |
| 6 | 5 (RecurringInvestment) | CreditCard | 30 | 30 | 0 | 0 |
| 7 | 5 (RecurringInvestment) | CreditCard | 30 | 30 | 0 | 0 |

Total: 210 rows | All last modified: 2025-02-24 | All fees: zero

Dictionary.DepositType values: 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositTypeConversionFeeID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. Auto-incremented. No business significance. |
| 2 | PlayerLevelID | int | NO | - | CODE-BACKED | Customer player level this fee override applies to. Implicit FK to a player level lookup table. Values 1-7 observed. Used as filter in GetAllConversionFeesOverride: `WHERE PlayerLevelID = @PlayerLevelID OR @PlayerLevelID IS NULL`. |
| 3 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method this fee override applies to. Implicit FK to Dictionary.FundingType. Currently only FundingTypeID=1 (CreditCard) configured. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Account currency this fee override applies to. Implicit FK to Dictionary.Currency. 30 distinct currencies configured. |
| 5 | DepositTypeID | int | NO | - | CODE-BACKED | Type of deposit this fee override applies to. Implicit FK to Dictionary.DepositType. Values: 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment. Currently only DepositTypeID=5 (RecurringInvestment) configured. This is the key differentiator from ConversionFeeOverride which has no deposit type dimension. |
| 6 | DepositFee | int | NO | - | CODE-BACKED | Flat deposit conversion fee for this combination. Unit depends on calling context (basis points or minor currency units). Currently 0 for all rows - no flat fee on recurring investment deposits. |
| 7 | DepositFeePercentage | decimal(18,2) | YES | - | CODE-BACKED | Percentage deposit conversion fee for this combination. NULL when not applicable (percentage fee not used for this deposit type). Currently 0.00 for all rows where populated. |
| 8 | ModificationDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of last modification. All rows show 2025-02-24 - bulk reconfiguration event. DEFAULT getutcdate() auto-populates if not provided. |
| 9 | ValidFrom | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | CODE-BACKED | System-time period start. Automatically maintained by SQL Server temporal versioning. Records when this row version became effective. Not directly queryable in regular queries - used by SYSTEM_VERSIONING. |
| 10 | ValidTo | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | CODE-BACKED | System-time period end. Automatically maintained by SQL Server temporal versioning. Set to 9999-12-31 for current rows; historical rows in History.BillingDepositTypeConversionFeeOverride have actual end timestamps. |
| 11 | Trace | computed | YES | - | CODE-BACKED | Diagnostic JSON capturing the SQL Server session context at write time: hostname, application name, SQL Server user, SPID, database name, and calling object name. Pattern: `{"HostName": "...","AppName": "...","SUserName": "...","SPID": "...","DBName": "...","ObjectName": "..."}`. Not persisted. Same pattern as Billing.AftRouting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit FK | Payment method for this fee override. |
| CurrencyID | Dictionary.Currency | Implicit FK | Account currency for this fee override. |
| DepositTypeID | Dictionary.DepositType | Implicit FK | Type of deposit for this fee override (1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment). |
| PlayerLevelID | (Player level lookup) | Implicit FK | Customer player level for this fee override. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetAllConversionFeesOverride | PlayerLevelID, CurrencyID, FundingTypeID | READER | UNIONs this table with ConversionFeeOverride to return complete fee override set. |
| Billing.GetExchangeRatesForCustomerFunding_v4 | PlayerLevelID, CurrencyID, FundingTypeID | READER | Uses fee overrides in exchange rate calculation for customer deposit flow. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (all FKs implicit, no FK constraints).

---

### 6.1 Objects This Depends On

No hard dependencies (no FK constraints).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetAllConversionFeesOverride | Stored Procedure | READER - UNIONs with ConversionFeeOverride for unified fee view |
| Billing.GetExchangeRatesForCustomerFunding_v4 | Stored Procedure | READER - applies fee overrides in deposit exchange rate calculation |
| History.BillingDepositTypeConversionFeeOverride | Table (history) | SYSTEM VERSIONING - receives deleted/updated row versions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingDepositTypeConversionRate_TPL | CLUSTERED PK | DepositTypeConversionFeeID ASC | - | - | Active |

No covering indexes on (PlayerLevelID, FundingTypeID, CurrencyID) - lookups via GetAllConversionFeesOverride do a full scan (acceptable given 210 rows).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingDepositTypeConversionRate_TPL | PRIMARY KEY | DepositTypeConversionFeeID - unique fee override row |
| DF_DepositTypeConversionFeeOverride_ModificationDate | DEFAULT | getutcdate() - auto-stamps modification time in UTC |
| PERIOD FOR SYSTEM_TIME | Temporal | ValidFrom/ValidTo - maintained by SQL Server for temporal versioning |
| SYSTEM_VERSIONING = ON | Temporal | History table: History.BillingDepositTypeConversionFeeOverride |

---

## 8. Sample Queries

### 8.1 Get fee overrides for a specific player level and payment method

```sql
SELECT d.PlayerLevelID, d.FundingTypeID, d.CurrencyID,
    dt.DepositType, d.DepositFee, d.DepositFeePercentage, d.ModificationDate
FROM [Billing].[DepositTypeConversionFeeOverride] d WITH (NOLOCK)
JOIN [Dictionary].[DepositType] dt WITH (NOLOCK) ON d.DepositTypeID = dt.DepositTypeID
WHERE d.PlayerLevelID = 1 AND d.FundingTypeID = 1
ORDER BY d.CurrencyID;
```

### 8.2 View historical fee changes (temporal query)

```sql
SELECT DepositTypeConversionFeeID, PlayerLevelID, FundingTypeID, CurrencyID,
    DepositFee, DepositFeePercentage, ValidFrom, ValidTo
FROM [Billing].[DepositTypeConversionFeeOverride]
FOR SYSTEM_TIME ALL
WHERE PlayerLevelID = 1 AND FundingTypeID = 1
ORDER BY ValidFrom DESC;
```

### 8.3 Current configuration summary

```sql
SELECT d.DepositTypeID, dt.DepositType, d.FundingTypeID,
    COUNT(*) AS Rows, COUNT(DISTINCT d.PlayerLevelID) AS PlayerLevels,
    COUNT(DISTINCT d.CurrencyID) AS Currencies,
    SUM(d.DepositFee) AS TotalFee
FROM [Billing].[DepositTypeConversionFeeOverride] d WITH (NOLOCK)
JOIN [Dictionary].[DepositType] dt WITH (NOLOCK) ON d.DepositTypeID = dt.DepositTypeID
GROUP BY d.DepositTypeID, dt.DepositType, d.FundingTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositTypeConversionFeeOverride | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.DepositTypeConversionFeeOverride.sql*
