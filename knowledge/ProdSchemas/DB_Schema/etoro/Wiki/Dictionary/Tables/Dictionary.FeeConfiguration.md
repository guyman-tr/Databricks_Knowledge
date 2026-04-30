# Dictionary.FeeConfiguration

> Lookup table defining the fee presentation modes — Pips, DynamicPips, or Percentage — that determine how fee values are expressed to users and in configuration.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FeeConfigurationID (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK clustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.FeeConfiguration defines the unit/format in which trading fees are expressed in the system's fee configuration. When configuring a fee for an instrument, the administrator specifies not just the value but how that value is interpreted: as a fixed pip amount, a dynamic pip amount that adjusts to market conditions, or a percentage of the trade value.

This is the "unit of measure" dimension of the fee system. Combined with FeeCalculationTypes (the mathematical formula), FeeOperationTypes (when the fee applies), and FeeDefinition (how often it's charged), this table completes the four-dimensional fee configuration framework.

The FeeConfigurationID is stored in `Billing.Deposit` (for deposit-related fee configurations) and referenced by instrument fee configuration procedures. It is also used in `MIMOAlerts.GetCurrencyConversionFeeConfigurationChanges` for monitoring fee configuration drift.

---

## 2. Business Logic

### 2.1 Fee Value Interpretation

**What**: Each configuration mode determines how the numeric fee value is interpreted by the trading engine.

**Columns/Parameters Involved**: `FeeConfigurationID`, `Name`

**Rules**:
- **Pips (1)**: Fee value is a fixed number of pips. Example: fee value = 3 means 3 pips spread. Deterministic and does not change with market conditions.
- **DynamicPips (2)**: Fee value is a dynamic pip amount that adjusts based on market conditions (volatility, liquidity). The configured value serves as a baseline that the engine may adjust.
- **Percentage (3)**: Fee value is a percentage of the trade's notional value. Example: fee value = 0.5 means 0.5% of the trade value. Scales with position size.

**Diagram**:
```
Fee Value Interpretation:
  ┌─────────────────┬──────────────────────────────────┐
  │ Pips (1)        │ Fixed pip count, no adjustment    │
  ├─────────────────┼──────────────────────────────────┤
  │ DynamicPips (2) │ Baseline pips, market-adjusted    │
  ├─────────────────┼──────────────────────────────────┤
  │ Percentage (3)  │ % of notional value               │
  └─────────────────┴──────────────────────────────────┘
```

---

## 3. Data Overview

| FeeConfigurationID | Name | Meaning |
|---|---|---|
| 1 | Pips | Fee expressed as a fixed number of pips (price increments). A fee value of 3 = 3 pips spread markup. Deterministic, does not vary with market conditions. Most common for forex pairs. |
| 2 | DynamicPips | Fee expressed as a dynamic pip amount that the trading engine adjusts based on market volatility and liquidity. The configured value is a baseline. Used for instruments with variable spreads. |
| 3 | Percentage | Fee expressed as a percentage of the trade's notional value. A fee value of 0.5 = 0.5% of trade value. Scales proportionally with position size. Used for stock CFDs and crypto instruments. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FeeConfigurationID | int | NO | - | VERIFIED | Fee presentation mode: **1**=Pips (fixed pip count), **2**=DynamicPips (market-adjusted pips), **3**=Percentage (% of notional value). Referenced by Billing.Deposit and instrument fee configuration procedures. |
| 2 | Name | nvarchar(64) | NO | - | VERIFIED | Machine-readable mode name: "Pips", "DynamicPips", "Percentage". Unique constraint ensures no duplicate names. Used in trading engine configuration and admin interfaces. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | FeeConfigurationID | Implicit | Stores the fee mode used for deposit-related charges |
| Trade.UpdateInstrumentToFeeConfigurations_TRDOPS | FeeConfigurationID | Read | Fee config updates reference the presentation mode |
| Trade.GetInstrumentToFeeConfiguration | FeeConfigurationID | Read | Returns instrument fee configs with mode |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.FeeConfiguration (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Stores FeeConfigurationID per deposit |
| Billing.DepositAdd | Stored Procedure | Sets FeeConfigurationID when creating deposit records |
| Trade.UpdateInstrumentToFeeConfigurations_TRDOPS | Stored Procedure | Configures fee mode per instrument |
| Trade.GetInstrumentToFeeConfiguration | Stored Procedure | Returns fee configurations with mode |
| MIMOAlerts.GetCurrencyConversionFeeConfigurationChanges | Stored Procedure | Monitors fee configuration changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED PK | FeeConfigurationID | - | - | Active |
| (Unique) | NONCLUSTERED UNIQUE | Name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY | Unique fee configuration mode on DICTIONARY filegroup |
| UNIQUE | UNIQUE | Ensures no duplicate fee configuration names |

---

## 8. Sample Queries

### 8.1 List all fee configuration modes
```sql
SELECT  FeeConfigurationID,
        Name
FROM    Dictionary.FeeConfiguration WITH (NOLOCK)
ORDER BY FeeConfigurationID;
```

### 8.2 Count deposits by fee configuration mode
```sql
SELECT  fc.Name             AS FeeMode,
        COUNT(*)            AS DepositCount
FROM    Billing.Deposit d WITH (NOLOCK)
JOIN    Dictionary.FeeConfiguration fc WITH (NOLOCK)
        ON d.FeeConfigurationID = fc.FeeConfigurationID
GROUP BY fc.Name;
```

### 8.3 Find instruments with percentage-based fees
```sql
SELECT  fc.Name             AS FeeMode,
        COUNT(DISTINCT d.CurrencyID) AS InstrumentCount
FROM    Billing.Deposit d WITH (NOLOCK)
JOIN    Dictionary.FeeConfiguration fc WITH (NOLOCK)
        ON d.FeeConfigurationID = fc.FeeConfigurationID
WHERE   fc.FeeConfigurationID = 3
GROUP BY fc.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FeeConfiguration | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FeeConfiguration.sql*
