# Billing.EtoroMoneyTransferBusinessConfiguration

> Temporal configuration table defining percentage fees for eToro Money currency transfer flows by player level - controls conversion fees charged when customers transfer between their eToro trading account (USD) and eToro Money wallet (EUR/GBP).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY PK) |
| **Partition** | No (MAIN filegroup) |
| **Indexes** | 1 (PK clustered) |
| **Temporal** | Yes - SYSTEM_VERSIONING (history in Billing.EtoroMoneyTransferBusinessConfigurationHistory) |

---

## 1. Business Meaning

`Billing.EtoroMoneyTransferBusinessConfiguration` defines the percentage-based conversion fees applied to eToro Money currency transfers. eToro Money is eToro's e-money wallet product; customers can move funds between their eToro trading account (USD-denominated) and their eToro Money wallet (EUR or GBP-denominated), incurring a currency conversion fee in the process.

The table configures two transfer directions:
- **Flow 1**: eToro Money wallet to eToro trading account (EUR/GBP -> USD inbound). Customer is topping up their trading account from eToroMoney.
- **Flow 2**: eToro trading account to eToro Money wallet (USD -> EUR/GBP outbound). Customer is moving trading proceeds to eToroMoney.

Fees are tiered by `PlayerLevelID` (1-7), reflecting eToro's loyalty/VIP program where higher-tier customers receive fee discounts. PlayerLevel=4 pays 0% (no fee), likely representing a VIP/premium tier. Level 7 pays the lowest non-zero fee (0.15%).

No stored procedures in the Billing schema reference this table directly - it is consumed by application-layer services (eToro Money API) that call the database dynamically. The temporal history table (`Billing.EtoroMoneyTransferBusinessConfigurationHistory`) retains full fee change history, which is unusual as other temporal tables in this schema use the `History.*` schema.

---

## 2. Business Logic

### 2.1 Fee Configuration by Flow and Player Level

**What**: Each row defines a percentage fee for one transfer flow + player level + currency pair combination.

**Columns/Parameters Involved**: `FlowID`, `PlayerLevelID`, `SourceCurrencyID`, `TargetCurrencyID`, `PercentageFee`

**Rules**:
| FlowID | Direction | SourceCurrencyID | TargetCurrencyID | Description |
|--------|-----------|-----------------|-----------------|-------------|
| 1 | eToroMoney -> Trading | 2 (EUR) or 3 (GBP) | 1 (USD) | Wallet to trading account |
| 2 | Trading -> eToroMoney | 1 (USD) | 2 (EUR) or 3 (GBP) | Trading account to wallet |

**Fee schedule by PlayerLevel**:
| PlayerLevelID | PercentageFee (both flows) |
|--------------|--------------------------|
| 1 | 0.75% |
| 2 | 0.45% |
| 3 | 0.60% |
| 4 | 0.00% (no fee - premium tier) |
| 5 | 0.60% |
| 6 | 0.45% |
| 7 | 0.15% (highest loyalty tier, lowest fee) |

- Fees are symmetric: the same percentage applies for Flow 1 and Flow 2 at each player level.
- Flow 1 (EUR->USD) and Flow 1 (GBP->USD) have the same fee for the same player level.

### 2.2 AssetCurrencyID (Special Case)

**What**: One row (ID=29) has a non-null AssetCurrencyID.

**Rules**:
- ID=29: FlowID=1, PlayerLevel=7, GBP->USD, AssetCurrencyID=123 (Crude Oil Future February 21), PercentageFee=0.15.
- AssetCurrencyID=123 is "Crude Oil Future Feb 21" in Dictionary.Currency - a commodity instrument, not a fiat currency.
- This appears to be a special/test configuration for an asset-linked transfer. The AssetCurrencyID likely refers to the underlying trading asset associated with the transfer in this specific case.
- Only 1 of 29 rows uses this field; its practical relevance is unclear.

---

## 3. Data Overview

| FlowID | Direction | PlayerLevelID | PercentageFee | Source | Target |
|--------|-----------|--------------|--------------|--------|--------|
| 1 | eToroMoney -> Trading | 1 | 0.75% | EUR | USD |
| 1 | eToroMoney -> Trading | 1 | 0.75% | GBP | USD |
| 1 | eToroMoney -> Trading | 2 | 0.45% | EUR | USD |
| 1 | eToroMoney -> Trading | 4 | 0.00% | EUR | USD |
| 1 | eToroMoney -> Trading | 7 | 0.15% | EUR | USD |
| 2 | Trading -> eToroMoney | 1 | 0.75% | USD | EUR |
| 2 | Trading -> eToroMoney | 4 | 0.00% | USD | GBP |
| 2 | Trading -> eToroMoney | 7 | 0.15% | USD | GBP |

Total: 29 rows | 2 flows | 7 player levels | 2 currencies each flow + 1 special AssetCurrency row

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. Auto-incremented. No business significance. |
| 2 | FlowID | int | NO | - | CODE-BACKED | Transfer flow direction: 1=eToroMoney wallet to eToro trading account (EUR/GBP -> USD), 2=eToro trading account to eToroMoney wallet (USD -> EUR/GBP). Currently only 2 flows configured. |
| 3 | PlayerLevelID | int | YES | - | CODE-BACKED | Customer loyalty tier for fee differentiation. Values 1-7 observed. NULL-allowed but no NULL rows. Level 4 = 0% fee (premium); Level 7 = 0.15% (highest VIP); Level 1 = 0.75% (standard). |
| 4 | SourceCurrencyID | int | YES | - | CODE-BACKED | Currency the customer is transferring FROM. Implicit FK to Dictionary.Currency. For Flow 1: 2=EUR, 3=GBP. For Flow 2: 1=USD. NULL-allowed but no NULL rows in current data. |
| 5 | TargetCurrencyID | int | YES | - | CODE-BACKED | Currency the customer is transferring TO. Implicit FK to Dictionary.Currency. For Flow 1: 1=USD. For Flow 2: 2=EUR, 3=GBP. NULL-allowed but no NULL rows in current data. |
| 6 | AssetCurrencyID | int | YES | - | CODE-BACKED | Optional underlying asset currency for special transfer types. Implicit FK to Dictionary.Currency. NULL for 28 of 29 rows. One row has CurrencyID=123 (Crude Oil Future February 21) - a commodity asset, not a fiat currency. Purpose of this field is not fully established from code evidence alone. |
| 7 | PercentageFee | decimal(18,2) | NO | - | CODE-BACKED | Percentage conversion fee applied to the transfer amount. Values: 0.00 (level 4, no fee), 0.15 (level 7), 0.45 (levels 2,6), 0.60 (levels 3,5), 0.75 (level 1). Applied by the eToro Money application layer. |
| 8 | Trace | computed | YES | - | CODE-BACKED | Session context JSON at write time: hostname, app name, SQL username, SPID, database, calling object. Not persisted. Same pattern as other temporal Billing tables (AftRouting, DepositTypeConversionFeeOverride, EncryptionKeyManagement). |
| 9 | ValidFrom | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | CODE-BACKED | System-time period start. Maintained automatically by SQL Server temporal versioning. |
| 10 | ValidTo | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | CODE-BACKED | System-time period end. Current rows: 9999-12-31. Historical rows in Billing.EtoroMoneyTransferBusinessConfigurationHistory have actual end timestamps. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SourceCurrencyID | Dictionary.Currency | Implicit FK | Source currency for the transfer. |
| TargetCurrencyID | Dictionary.Currency | Implicit FK | Target currency for the transfer. |
| AssetCurrencyID | Dictionary.Currency | Implicit FK | Optional underlying asset currency. Currently only CurrencyID=123 (Crude Oil Future Feb 21). |
| PlayerLevelID | (Player level lookup) | Implicit FK | Customer tier for fee differentiation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | FlowID, PlayerLevelID, SourceCurrencyID, TargetCurrencyID | READER | eToro Money API/service reads this table to determine applicable conversion fee for a transfer. No stored procedures in Billing schema reference this table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (all FKs implicit, no FK constraints).

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.EtoroMoneyTransferBusinessConfigurationHistory | Table (history) | SYSTEM VERSIONING - receives all row versions on update/delete |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EtoroMoneyTransferBusinessConfiguration | CLUSTERED PK | ID ASC | - | - | Active |

MAIN filegroup. No index on (FlowID, PlayerLevelID) - lookups do a full scan (acceptable given 29 rows).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EtoroMoneyTransferBusinessConfiguration | PRIMARY KEY | ID - unique configuration row |
| PERIOD FOR SYSTEM_TIME | Temporal | ValidFrom/ValidTo maintained by SQL Server |
| SYSTEM_VERSIONING = ON | Temporal | History table: Billing.EtoroMoneyTransferBusinessConfigurationHistory (note: in Billing schema, not History schema) |

---

## 8. Sample Queries

### 8.1 Get fee for a specific transfer

```sql
SELECT PercentageFee
FROM [Billing].[EtoroMoneyTransferBusinessConfiguration] WITH (NOLOCK)
WHERE FlowID = 1  -- eToroMoney to Trading
  AND PlayerLevelID = @PlayerLevelID
  AND SourceCurrencyID = @SourceCurrencyID
  AND TargetCurrencyID = @TargetCurrencyID
  AND AssetCurrencyID IS NULL;
```

### 8.2 View full fee schedule

```sql
SELECT FlowID,
    CASE FlowID WHEN 1 THEN 'eToroMoney->Trading' ELSE 'Trading->eToroMoney' END AS FlowName,
    PlayerLevelID,
    sc.Abbreviation AS SourceCurrency,
    tc.Abbreviation AS TargetCurrency,
    PercentageFee
FROM [Billing].[EtoroMoneyTransferBusinessConfiguration] e WITH (NOLOCK)
LEFT JOIN [Dictionary].[Currency] sc WITH (NOLOCK) ON e.SourceCurrencyID = sc.CurrencyID
LEFT JOIN [Dictionary].[Currency] tc WITH (NOLOCK) ON e.TargetCurrencyID = tc.CurrencyID
WHERE e.AssetCurrencyID IS NULL
ORDER BY FlowID, PlayerLevelID, SourceCurrencyID;
```

### 8.3 View historical fee changes

```sql
SELECT ID, FlowID, PlayerLevelID, SourceCurrencyID, TargetCurrencyID,
    PercentageFee, ValidFrom, ValidTo
FROM [Billing].[EtoroMoneyTransferBusinessConfiguration]
FOR SYSTEM_TIME ALL
ORDER BY ID, ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (app-layer consumer) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.EtoroMoneyTransferBusinessConfiguration | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.EtoroMoneyTransferBusinessConfiguration.sql*
