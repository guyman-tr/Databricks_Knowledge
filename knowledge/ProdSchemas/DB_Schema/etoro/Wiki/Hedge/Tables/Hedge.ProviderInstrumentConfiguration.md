# Hedge.ProviderInstrumentConfiguration

> Per-provider, per-instrument order submission configuration defining how hedge orders are sent to each liquidity provider for specific instruments - specifying order type (market vs limit vs GTD), limit price offset percentage, and GTD order validity window. Currently empty (designed but not yet operationally activated).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (LiquidityProviderTypeID, InstrumentID) - composite PK CLUSTERED |
| **Partition** | No (on [DICTIONARY] filegroup) |
| **Indexes** | 3 (PK + idx_InstrumentID + idx_LiquidityProviderTypeID) |
| **Versioning** | SYSTEM_VERSIONING -> History.ProviderInstrumentConfiguration |

---

## 1. Business Meaning

`Hedge.ProviderInstrumentConfiguration` defines how the hedge engine submits orders to a specific liquidity provider for a specific instrument. Different providers support different order types (market, limit, GTD), and individual instruments may have constraints on which order type is acceptable. This table provides the per-provider, per-instrument intersection of those requirements.

The three data columns work together:
- **OrderType** (tinyint): Which order type to use when submitting to this provider/instrument. Determines whether `LimitOffsetPercentage` and `GTDTimeSpanInSeconds` are relevant.
- **LimitOffsetPercentage** (decimal 8,2): For limit orders, the percentage offset from market price used to set the limit price. Positive offset = aggressive (ahead of market); small offset = close to market.
- **GTDTimeSpanInSeconds** (int): For GTD (Good Till Date) orders, the number of seconds the order remains valid before expiring.

**Current data**: 0 rows in both current table and history. The reader procedure (`GetProviderInstrumentConfiguration`) loads the full table on hedge engine startup with no parameters. When empty, the hedge engine uses default order routing for all provider/instrument combinations.

**Relationship to Hedge.OrderTypeConfiguration**: The Hedge schema has a separate `Hedge.OrderTypeConfiguration` table (using string-based `TimeInForce` and `ReferencePriceType` columns) for a different configuration model. `ProviderInstrumentConfiguration.OrderType` is a numeric tinyint representing a provider-side order submission type (distinct from the eToro-side `Dictionary.OrderType` which describes client order request categories).

---

## 2. Business Logic

### 2.1 Provider-Specific Order Type Selection

**What**: Different liquidity providers may require or prefer specific order types for specific instruments. This table overrides the default order submission type per provider/instrument.

**Columns/Parameters Involved**: `OrderType`, `LiquidityProviderTypeID`, `InstrumentID`

**Rules**:
- tinyint - compact numeric enum for provider-side order type
- Likely values (inferred from companion columns):
  - Market order: no offset or validity window required
  - Limit order: requires `LimitOffsetPercentage` to compute the limit price
  - GTD (Good Till Date) order: requires `GTDTimeSpanInSeconds` for expiry
- No FK to any dictionary table - enum managed by application code
- No DEFAULT defined - value must be explicitly set on insert

### 2.2 Limit Order Price Offset

**What**: For limit orders, `LimitOffsetPercentage` defines how far from the current market price the limit is set.

**Columns/Parameters Involved**: `LimitOffsetPercentage`, `OrderType`

**Rules**:
- decimal(8,2) - supports values like 0.01 (1 basis point), 0.05, 0.10 (10 bps)
- Used when `OrderType` indicates a limit order type
- Percentage relative to market price: limit price = market price * (1 + LimitOffsetPercentage/100) for buys
- Allows per-provider, per-instrument fine-tuning of aggressiveness for limit orders
- No DEFAULT - required when inserting a limit-order type row

### 2.3 GTD Order Validity Window

**What**: For GTD (Good Till Date) orders, `GTDTimeSpanInSeconds` specifies how long the order remains active before it expires.

**Columns/Parameters Involved**: `GTDTimeSpanInSeconds`, `OrderType`

**Rules**:
- int, storing seconds (e.g., 30 = 30 seconds, 3600 = 1 hour)
- Used when `OrderType` indicates a GTD order type
- After the validity window expires, the unfilled order is cancelled
- Allows providers that do not support market orders to receive limit orders with a short validity window (effectively market-like behavior)
- No DEFAULT - required when inserting a GTD order type row

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Current rows | 0 |
| History rows | 0 |
| Distinct LiquidityProviderTypeIDs | 0 |
| Distinct InstrumentIDs | 0 |

Table is fully empty - feature designed and implemented but not yet operationally configured. `GetProviderInstrumentConfiguration` returns an empty resultset on the live system; all provider/instrument pairs use default order submission behavior.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderTypeID | int | NO | - | CODE-BACKED | The liquidity provider type this configuration applies to. Part of composite PK. Implicit reference to Trade.LiquidityProviderType (no FK constraint). Indexed via idx_LiquidityProviderTypeID for per-provider lookups. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this configuration applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). Indexed via idx_InstrumentID for per-instrument lookups. |
| 3 | OrderType | tinyint | NO | - (required) | NAME-INFERRED | Numeric enum specifying the order submission type for this provider/instrument pair (e.g., market, limit, GTD). Governs whether LimitOffsetPercentage and GTDTimeSpanInSeconds are used. No FK to dictionary table; enum values defined in application code. No DEFAULT - must be explicitly set. |
| 4 | LimitOffsetPercentage | decimal(8,2) | NO | - (required) | NAME-INFERRED | Percentage offset from market price used to compute the limit price when OrderType is a limit order. E.g., 0.05 = 5 basis point offset. No DEFAULT - required on insert. |
| 5 | GTDTimeSpanInSeconds | int | NO | - (required) | NAME-INFERRED | Validity window in seconds for GTD (Good Till Date) orders. After expiry, unfilled orders are cancelled. Used when OrderType is GTD. No DEFAULT - required on insert. |
| 6 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 7 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 8 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 9 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.ProviderInstrumentConfiguration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. LiquidityProviderTypeID and InstrumentID are application-managed without explicit FK enforcement.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetProviderInstrumentConfiguration | (table ref) | READER | Full table scan - returns all 5 data columns (no parameters); hedge engine loads all overrides on startup |
| History.ProviderInstrumentConfiguration | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ProviderInstrumentConfiguration (table)
  (no FK dependencies - leaf table)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetProviderInstrumentConfiguration | Stored Procedure | READER - bulk-loads all rows into hedge engine on startup |
| History.ProviderInstrumentConfiguration | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_ProviderInstrumentConfiguration | CLUSTERED PK | LiquidityProviderTypeID ASC, InstrumentID ASC | - | - | Active |
| idx_InstrumentID | NONCLUSTERED | InstrumentID ASC | - | - | Active |
| idx_LiquidityProviderTypeID | NONCLUSTERED | LiquidityProviderTypeID ASC | - | - | Active |

Note: Two supporting indexes pre-built for per-instrument and per-provider filtering, indicating expected query patterns.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_ProviderInstrumentConfiguration | PRIMARY KEY | (LiquidityProviderTypeID, InstrumentID) - one configuration row per provider/instrument pair |
| DF_ProviderInstrumentConfiguration_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_ProviderInstrumentConfiguration_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ProviderInstrumentConfiguration |

Note: `OrderType`, `LimitOffsetPercentage`, `GTDTimeSpanInSeconds` have NO DEFAULTs - all must be explicitly set on insert.

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| Tr_T_ProviderInstrumentConfiguration_INSERT | INSERT | No-op self-UPDATE (SET LiquidityProviderTypeID=LiquidityProviderTypeID, InstrumentID=InstrumentID) to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 Match GetProviderInstrumentConfiguration output

```sql
-- Matches Hedge.GetProviderInstrumentConfiguration (no parameters)
SELECT
    LiquidityProviderTypeID,
    InstrumentID,
    OrderType,
    LimitOffsetPercentage,
    GTDTimeSpanInSeconds
FROM Hedge.ProviderInstrumentConfiguration WITH (NOLOCK)
ORDER BY LiquidityProviderTypeID, InstrumentID
-- Currently returns 0 rows
```

### 8.2 When populated - find GTD-configured provider/instrument pairs

```sql
SELECT
    pic.LiquidityProviderTypeID,
    pic.InstrumentID,
    pic.OrderType,
    pic.GTDTimeSpanInSeconds
FROM Hedge.ProviderInstrumentConfiguration pic WITH (NOLOCK)
WHERE pic.GTDTimeSpanInSeconds > 0
ORDER BY pic.LiquidityProviderTypeID, pic.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.ProviderInstrumentConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ProviderInstrumentConfiguration.sql*
