# Hedge.ProviderUnitConversionRatio

> Per-provider, per-instrument unit and lot size conversion table translating eToro's internal unit denomination to a liquidity provider's native order quantity system. The central reference for order size translation in the hedge engine.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (LiquidityProviderID, InstrumentID) - composite PK CLUSTERED |
| **Partition** | No (on [PRIMARY] filegroup) |
| **Indexes** | 1 (PK only) |
| **Versioning** | None (ASM audit triggers write to History.AuditHistory) |

---

## 1. Business Meaning

`Hedge.ProviderUnitConversionRatio` bridges eToro's internal unit-based position sizing and the provider-specific lot/quantity systems used by external liquidity providers. When the hedge engine needs to place an order of X eToro units for instrument Y via provider Z, it looks up this table to determine:

1. `UnitConversionRatio`: How many provider-native units correspond to one eToro unit. Applied as a multiplier: `providerQuantity = eToroUnits * UnitConversionRatio`.
2. `LotSize`: The standard lot size for this provider/instrument. Used for lot-rounding and order splitting logic.

**Key naming note**: The column is named `LiquidityProviderID` but the FK references `Trade.LiquidityProviderType(LiquidityProviderTypeID)` - it is a provider *type* ID, not a provider instance ID.

**Current data** (5,739 rows, 10 providers, 5,215 instruments):
- ZBFX (69): 5,213 rows - dominant provider with conversion ratios across essentially all instruments
- GFT (7): 118 rows; GoldmanSachs (9): 92; IB (11): 104; Saxo (23): 103
- Smaller sets: FD (3)=58, Smart/9999=20, IG Execution (12)=17, Marex (84)=2, eToro (0)=12

**Ratio range**: 0.001 to 10,000 - reflects the wide variance between instrument types (Forex contracts vs equity shares vs crypto).
**Lot size range**: 0.00001 to 3,000 - similarly broad.

**Two reader patterns**:
- `GetHSUnitConversionRatio(@HedgeServerID)`: Navigates HedgeServerToLiquidityAccount -> Accounts -> LiquidityProviderType -> this table. Returns (InstrumentID, UnitConversionRatio) for a specific server's provider.
- `GetProviderUnitConversion()`: Broader read, LEFT JOINs from `Trade.LiquidityProviderContracts`. When no ratio exists, defaults UnitConversionRatio=1 and LotSize=1000 (Forex) or 1 (other). Used for bulk loading.

---

## 2. Business Logic

### 2.1 Unit Conversion for Order Sizing

**What**: `UnitConversionRatio` converts an eToro-denominated order size into the provider's native order quantity.

**Columns/Parameters Involved**: `UnitConversionRatio`, `LiquidityProviderID`, `InstrumentID`

**Rules**:
- `providerQuantity = eToroUnits * UnitConversionRatio`
- Range 0.001 to 10,000: A ratio < 1 means eToro units are larger than provider units (e.g., eToro deals in $1 increments, provider trades in $1000 lots). A ratio > 1 means the opposite.
- float type - accepts fractional ratios for precise conversion
- `GetProviderUnitConversion` defaults missing ratios to 1.0 (no conversion) via ISNULL fallback

### 2.2 Lot Size for Order Splitting and Rounding

**What**: `LotSize` defines the standard lot size unit for this provider/instrument - used to round order quantities to valid lot boundaries.

**Columns/Parameters Involved**: `LotSize`

**Rules**:
- DEFAULT 1 = one-to-one lot (no lot-based rounding required)
- Range 0.00001 to 3,000: Small values for fractional instruments, large values for standard exchange lots
- `GetProviderUnitConversion` defaults missing lot sizes to: 1000 for Forex instruments, 1 for all others (Forex convention: 1 standard lot = 100,000 units, but in eToro context 1000 is the working lot)
- decimal(14,6) - fractional lot sizes supported (e.g., 0.001 mini-lots)

### 2.3 Chain Resolution via GetHSUnitConversionRatio

**What**: `GetHSUnitConversionRatio(@HedgeServerID)` resolves the conversion ratio for a given hedge server by traversing the account-to-provider chain.

**Rules**:
- Chain: `HedgeServerToLiquidityAccount` (server -> account) -> `Hedge.Accounts` (account -> provider type) -> `Trade.LiquidityProviderType` (provider type) -> `ProviderUnitConversionRatio` (provider -> ratio)
- Returns only `InstrumentID` + `UnitConversionRatio` (NOT LotSize)
- Excludes AccountTypeID=4 (pricing-only accounts) via `HA.AccountTypeID!=4` filter

---

## 3. Data Overview

| LiquidityProviderID | Provider Name | InstrumentCount | UnitConversionRatio Range | LotSize Range |
|---|---|---|---|---|
| 0 | eToro | 12 | varies | varies |
| 3 | FD | 58 | varies | varies |
| 7 | GFT | 118 | varies | varies |
| 9 | GoldmanSachs | 92 | varies | varies |
| 11 | IB | 104 | varies | varies |
| 12 | IG Execution | 17 | varies | varies |
| 23 | Saxo | 103 | varies | varies |
| 69 | ZBFX | 5,213 | 0.001 - 10000 | 0.00001 - 3000 |
| 84 | Marex | 2 | varies | varies |
| 9999 | Smart | 20 | varies | varies |

Total: 5,739 rows, 10 providers. No temporal history - changes tracked via AuditHistory only.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderID | int | NO | - | VERIFIED | FK to Trade.LiquidityProviderType(LiquidityProviderTypeID). Named "LiquidityProviderID" but references the provider type table. Part of composite PK. 10 distinct providers configured. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this ratio applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint in DDL). 5,215 distinct instruments. |
| 3 | UnitConversionRatio | float | NO | - (required) | VERIFIED | Multiplier converting eToro internal units to provider-native order quantity. providerQty = eToroUnits * UnitConversionRatio. Range 0.001-10,000 in current data. ISNULL defaults to 1.0 in GetProviderUnitConversion. |
| 4 | LotSize | decimal(14,6) | NO | 1 | VERIFIED | Standard lot size for this provider/instrument, used for lot-boundary rounding. DEFAULT 1 = no lot rounding. Range 0.00001-3,000. ISNULL defaults to 1000 (Forex) or 1 (other) in GetProviderUnitConversion. Not tracked by ASM audit triggers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderID | Trade.LiquidityProviderType | FK (FK_ProviderUnitConversionRatio_LiquidityProviderTypeID) | Provider type must exist; note column named LiquidityProviderID despite FK to LiquidityProviderTypeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetHSUnitConversionRatio | LiquidityProviderID | READER (server-scoped) | Resolves conversion ratio for a hedge server via account -> provider chain |
| Hedge.GetProviderUnitConversion | LiquidityProviderID | READER (full table, LEFT JOIN) | Full load with defaults; used for bulk ratio loading |
| History.AuditHistory | (trigger) | Audit Log | ASM DML triggers track LiquidityProviderID, InstrumentID, UnitConversionRatio changes (LotSize not tracked) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ProviderUnitConversionRatio (table)
  └── Trade.LiquidityProviderType (table) [FK - LiquidityProviderID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderType | Table | FK_ProviderUnitConversionRatio_LiquidityProviderTypeID - provider must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetHSUnitConversionRatio | Stored Procedure | READER - resolves (InstrumentID, UnitConversionRatio) for a hedge server |
| Hedge.GetProviderUnitConversion | Stored Procedure | READER - full load from LiquidityProviderContracts with ISNULL defaults |
| History.AuditHistory | Table | Audit log via 3 ASM DML triggers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProviderUnitConversionRatio | CLUSTERED PK | LiquidityProviderID ASC, InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ProviderUnitConversionRatio | PRIMARY KEY | (LiquidityProviderID, InstrumentID) - one ratio per provider/instrument pair |
| FK_ProviderUnitConversionRatio_LiquidityProviderTypeID | FOREIGN KEY | LiquidityProviderID must reference Trade.LiquidityProviderType |
| DF_ProviderUnitConversionRatio_LotSize | DEFAULT | LotSize = 1 |

Note: No temporal SYSTEM_VERSIONING. Changes tracked only via ASM audit triggers to History.AuditHistory.

### 7.3 Triggers

| Trigger Name | Event | Columns Tracked |
|-------------|-------|-----------------|
| AuditDelete_Hedge_ProviderUnitConversionRatio | DELETE | LiquidityProviderID, InstrumentID, UnitConversionRatio |
| AuditInsert_Hedge_ProviderUnitConversionRatio | INSERT | LiquidityProviderID, InstrumentID, UnitConversionRatio |
| AuditUpdate_Hedge_ProviderUnitConversionRatio | UPDATE | LiquidityProviderID, InstrumentID, UnitConversionRatio (conditional on change) |

Note: `LotSize` is NOT tracked by audit triggers despite being a data column.

---

## 8. Sample Queries

### 8.1 View conversion ratios for a specific provider

```sql
SELECT
    pcr.LiquidityProviderID,
    pcr.InstrumentID,
    pcr.UnitConversionRatio,
    pcr.LotSize
FROM Hedge.ProviderUnitConversionRatio pcr WITH (NOLOCK)
WHERE pcr.LiquidityProviderID = 69  -- ZBFX
ORDER BY pcr.InstrumentID
```

### 8.2 Find instruments with non-standard conversion ratios (not 1:1)

```sql
SELECT
    pcr.LiquidityProviderID,
    lpt.Name AS ProviderName,
    pcr.InstrumentID,
    pcr.UnitConversionRatio,
    pcr.LotSize
FROM Hedge.ProviderUnitConversionRatio pcr WITH (NOLOCK)
JOIN Trade.LiquidityProviderType lpt WITH (NOLOCK)
    ON pcr.LiquidityProviderID = lpt.LiquidityProviderTypeID
WHERE pcr.UnitConversionRatio != 1.0
ORDER BY pcr.LiquidityProviderID, pcr.InstrumentID
```

### 8.3 Simulate GetHSUnitConversionRatio for hedge server 1

```sql
SELECT HPUCR.InstrumentID, HPUCR.UnitConversionRatio
FROM Hedge.Accounts HA WITH (NOLOCK)
JOIN Trade.LiquidityProviderType TLPT WITH (NOLOCK)
    ON HA.LiquidityProviderTypeID = TLPT.LiquidityProviderTypeID
JOIN Hedge.HedgeServerToLiquidityAccount HHSLA WITH (NOLOCK)
    ON HHSLA.LiquidityAccountID = HA.ID
JOIN Hedge.ProviderUnitConversionRatio HPUCR WITH (NOLOCK)
    ON HPUCR.LiquidityProviderID = TLPT.LiquidityProviderTypeID
WHERE HHSLA.HedgeServerID = 1  -- ZBFX primary server
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.ProviderUnitConversionRatio | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ProviderUnitConversionRatio.sql*
