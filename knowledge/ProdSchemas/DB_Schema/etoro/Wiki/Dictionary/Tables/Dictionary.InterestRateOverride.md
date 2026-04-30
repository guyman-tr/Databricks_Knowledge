# Dictionary.InterestRateOverride

> System-versioned configuration table defining manual overrides to overnight interest (swap) rates — allowing operations to customize buy/sell rates and markup percentages at the instrument, exchange, or instrument-type level with full temporal audit history.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | InterestRateOverrideID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.InterestRateOverride allows the trading operations team to override the standard overnight interest (swap) rates charged to customers holding leveraged positions overnight. Standard rates are calculated from market benchmark rates in Dictionary.InterestRate, but certain instruments, exchanges, or instrument types may need custom rates due to market conditions, regulatory requirements, or business decisions.

This table exists because a one-size-fits-all interest rate model doesn't work across all trading products. Forex majors may have competitive rates to attract volume, while exotic instruments may need higher markup to compensate for hedging costs. Exchange-specific overrides handle market-specific funding cost differences. The temporal versioning (system-versioned with History.InterestRateOverride) ensures every rate change is auditable — critical for regulatory compliance.

The table is consumed by Trade.CalcOverNightFeeRates (the main overnight fee calculation procedure), Trade.GetInterestRateOverrides (displays current overrides), and Trade.UpdateInterestRateOverride / Trade.DeleteInterestRateOverride (CRUD operations). The override resolution hierarchy is: InstrumentID (most specific) → ExchangeID → InstrumentTypeID (broadest).

---

## 2. Business Logic

### 2.1 Override Resolution Hierarchy

**What**: Overrides target specific instruments, exchanges, or entire instrument types with a specificity hierarchy.

**Columns/Parameters Involved**: `InstrumentID`, `ExchangeID`, `InstrumentTypeID`

**Rules**:
- **Instrument-level** (InstrumentID not NULL): Overrides rates for a specific instrument. Most specific — wins over exchange or type overrides.
- **Exchange-level** (ExchangeID not NULL, InstrumentID NULL): Overrides rates for all instruments on a specific exchange.
- **Type-level** (InstrumentTypeID not NULL, others NULL): Overrides rates for an entire instrument type (e.g., all Stocks, all Forex).
- Exactly one of InstrumentID, ExchangeID, or InstrumentTypeID should be set (with the others NULL). The system applies the most specific match.
- Each override specifies both direction rates (Buy/Sell) and markup percentages (MarkupBuy/MarkupSell).

### 2.2 Rate Components

**What**: Each override defines base rates and markup percentages for buy (long) and sell (short) positions.

**Columns/Parameters Involved**: `InterestRateBuy`, `InterestRateSell`, `MarkupBuy`, `MarkupSell`

**Rules**:
- **InterestRateBuy/Sell**: The base overnight interest rate for long/short positions. Positive = customer pays; negative = customer receives.
- **MarkupBuy/Sell**: The eToro markup percentage applied on top of the base rate. Represents eToro's revenue from overnight fees.
- The final customer-facing rate = base rate + markup. For example: InterestRateBuy=0.001, MarkupBuy=0.001 → customer pays 0.002 overnight.
- The override is combined with OverNightFeePatternID (from Dictionary.OverNightFeePattern) and SettlementTypeID (from Dictionary.SettlementTypes) to determine the complete fee behavior.

### 2.3 Temporal Versioning

**What**: System-versioned table preserving full history of every rate change.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`

**Rules**:
- Every UPDATE to an override row creates a historical version in History.InterestRateOverride
- Current active overrides have EndTime = 9999-12-31 23:59:59.999
- Historical versions have EndTime = the timestamp when the row was next modified
- Enables point-in-time auditing: "What was the override for instrument X on date Y?"

---

## 3. Data Overview

| ID | InstrumentTypeID | ExchangeID | RateBuy | RateSell | SettlementTypeID | Meaning |
|---|---|---|---|---|---|---|
| 346 | 1 (Forex) | - | -0.0155 | 0.9 | 0 | Forex-wide override with negative buy rate (longs receive interest) and high sell rate. Operations-managed rate for all forex instruments. |
| 350 | 5 (Stocks) | - | 0.2 | 0.2 | 5 | Stock-wide override with equal buy/sell rates and OverNightFeePatternID=1. Applied to settlement type 5 (TRS) stock positions. |
| 352 | - | 3 | 0.2 | 0.2 | 3 | Exchange-level override for Exchange 3 with settlement type 3. All instruments on this exchange get these rates regardless of type. |
| 384 | 3 (Indices) | - | 0.001 | 0.001 | 4 | Index-wide override with minimal rates. Applied to settlement type 4 index positions with OverNightFeePatternID=0. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InterestRateOverrideID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. Uniquely identifies each override rule. Referenced by Trade.UpdateInterestRateOverride and Trade.DeleteInterestRateOverride. |
| 2 | InstrumentID | int | YES | - | VERIFIED | Specific instrument to override (most specific level). NULL when override targets an exchange or type. FK to Dictionary.Currency.InstrumentID. |
| 3 | ExchangeID | int | YES | - | VERIFIED | Exchange to override (mid-level specificity). NULL when override targets a specific instrument or type. FK to Dictionary.ExchangeInfo. |
| 4 | InstrumentTypeID | int | YES | - | VERIFIED | Instrument type to override (broadest level). NULL when override targets a specific instrument or exchange. FK to Dictionary.CurrencyType. 1=Forex, 2=Commodities, 3=Indices, 4=Indices, 5=Stocks, 10=Crypto. |
| 5 | UpdatedByUser | varchar(50) | NO | - | VERIFIED | Username of the operations staff member who created or last modified this override. Used for audit trail and accountability. |
| 6 | InterestRateBuy | decimal(16,8) | NO | - | VERIFIED | Base overnight interest rate for long (buy) positions. Positive = customer pays, negative = customer receives. Combined with MarkupBuy for final rate. |
| 7 | InterestRateSell | decimal(16,8) | NO | - | VERIFIED | Base overnight interest rate for short (sell) positions. Positive = customer pays, negative = customer receives. Combined with MarkupSell for final rate. |
| 8 | MarkupBuy | decimal(16,8) | NO | - | VERIFIED | eToro's markup percentage on the buy (long) overnight rate. Added to InterestRateBuy to determine the customer-facing rate. Represents eToro's revenue component. |
| 9 | MarkupSell | decimal(16,8) | NO | - | VERIFIED | eToro's markup percentage on the sell (short) overnight rate. Added to InterestRateSell to determine the customer-facing rate. |
| 10 | BeginTime | datetime2(7) | NO | - | VERIFIED | System-versioned row start time. Generated automatically by SQL Server. Indicates when this version of the override became active. |
| 11 | EndTime | datetime2(7) | NO | - | VERIFIED | System-versioned row end time. Generated automatically. Current rows have 9999-12-31 23:59:59.999. Historical rows have the timestamp of the next modification. |
| 12 | OverNightFeePatternID | tinyint | YES | - | VERIFIED | Fee charging pattern for this override. FK to Dictionary.OverNightFeePattern. Determines on which days/how fees are charged (e.g., daily, triple Wednesday, weekday-only). NULL = use default pattern. |
| 13 | SettlementTypeID | tinyint | NO | 0 | VERIFIED | Settlement model for this override. FK to Dictionary.SettlementTypes. 0=default/any, 1=CFD, 2=Real, 3=DMA, 4=Indices, 5=TRS. Allows different rates per settlement type. Default: 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Dictionary.Currency | Implicit FK | Specific instrument for instrument-level overrides |
| ExchangeID | Dictionary.ExchangeInfo | Implicit FK | Exchange for exchange-level overrides |
| InstrumentTypeID | Dictionary.CurrencyType | Implicit FK | Instrument type for type-level overrides |
| OverNightFeePatternID | Dictionary.OverNightFeePattern | Implicit FK | Fee charging pattern |
| SettlementTypeID | Dictionary.SettlementTypes | Implicit FK | Settlement model filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CalcOverNightFeeRates | - | Reader | Main overnight fee calculation uses overrides |
| Trade.CalcOverNightFeeRates_TRDOPS | - | Reader | Trading ops variant of fee calculation |
| Trade.GetInterestRateOverrides | - | Reader | Returns current overrides for display |
| Trade.GetInterestRateOverrides_TRDOPS | - | Reader | Trading ops variant |
| Trade.UpdateInterestRateOverride | - | Writer | Creates/updates override rules |
| Trade.DeleteInterestRateOverride | - | Deleter | Removes override rules |
| History.InterestRateOverride | - | History | Temporal history table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CalcOverNightFeeRates | Stored Procedure | Reads — applies overrides to fee calculation |
| Trade.GetInterestRateOverrides | Stored Procedure | Reads — displays current overrides |
| Trade.UpdateInterestRateOverride | Stored Procedure | Writes — creates/modifies overrides |
| Trade.DeleteInterestRateOverride | Stored Procedure | Deletes — removes overrides |
| History.InterestRateOverride | Table | Temporal history tracking |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InterestRateOverrideTemporal | CLUSTERED PK | InterestRateOverrideID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InterestRateOverrideTemporal | PRIMARY KEY | Unique override identifier |
| DEFAULT | DEFAULT | SettlementTypeID defaults to 0 (any/default) |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | BeginTime/EndTime for system versioning |
| SYSTEM_VERSIONING | TEMPORAL | History tracked in History.InterestRateOverride |

---

## 8. Sample Queries

### 8.1 List all active overrides
```sql
SELECT  InterestRateOverrideID,
        InstrumentID,
        ExchangeID,
        InstrumentTypeID,
        InterestRateBuy,
        InterestRateSell,
        MarkupBuy,
        MarkupSell,
        SettlementTypeID,
        UpdatedByUser
FROM    [Dictionary].[InterestRateOverride] WITH (NOLOCK)
ORDER BY InterestRateOverrideID;
```

### 8.2 Find override for specific instrument type
```sql
SELECT  iro.InterestRateOverrideID,
        ct.CurrencyTypeName AS InstrumentType,
        iro.InterestRateBuy,
        iro.InterestRateSell,
        st.Name AS SettlementType
FROM    [Dictionary].[InterestRateOverride] iro WITH (NOLOCK)
LEFT JOIN [Dictionary].[CurrencyType] ct WITH (NOLOCK)
        ON iro.InstrumentTypeID = ct.CurrencyTypeID
LEFT JOIN [Dictionary].[SettlementTypes] st WITH (NOLOCK)
        ON iro.SettlementTypeID = st.SettlementTypeID
WHERE   iro.InstrumentTypeID IS NOT NULL
ORDER BY iro.InstrumentTypeID;
```

### 8.3 Query historical override changes
```sql
SELECT  InterestRateOverrideID,
        InterestRateBuy,
        InterestRateSell,
        UpdatedByUser,
        BeginTime,
        EndTime
FROM    [Dictionary].[InterestRateOverride]
FOR SYSTEM_TIME ALL
WHERE   InterestRateOverrideID = 346
ORDER BY BeginTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 13 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.InterestRateOverride | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.InterestRateOverride.sql*
