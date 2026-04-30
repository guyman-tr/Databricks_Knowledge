# History.FuturesMetaData

> SQL Server system-versioned temporal history table for Trade.FuturesMetaData, recording every change to the contract specification parameters for futures instruments including contract size, tick size, expiration dates, and settlement type.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Trade.FuturesMetaData`. SQL Server's system-versioning manages this table transparently: whenever a row in `Trade.FuturesMetaData` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Trade.FuturesMetaData` stores the contract specifications for each futures instrument that eToro offers. These are the standard futures contract parameters that define how the instrument trades, what it represents, and how it settles. This data drives pricing calculations (Multiplier, IndexPointValue, MinimalTick), determines when contracts expire (LastTradingDateTime, ExpirationDateTime), and specifies how settlement occurs (SettlementMethod, SettlementTime, UnitOfMeasure).

2,243 history rows span October 2024 to March 2026 across 250 distinct instruments. The data reflects a diverse futures universe: index futures (UnitOfMeasure=Points/Cash settlement), commodities (oil, gold, natural gas, agricultural), currency futures (EUR, AUD, GBP), and crypto futures (BTC, ETH, SOL, XRP). Frequent updates for InstrumentID=18 (crude oil - 1-minute-interval LastTradingDateTime changes in the DevTradingSTG testing environment) account for the high row count relative to distinct instruments.

---

## 2. Business Logic

### 2.1 Futures Contract Specification

**What**: Each row defines the technical contract parameters for a futures instrument - the building blocks for price calculation and P&L computation.

**Columns/Parameters Involved**: `InstrumentID`, `Multiplier`, `MinimalTick`, `IndexPointValue`, `SettlementMethod`, `UnitOfMeasure`

**Rules**:
- One row per InstrumentID in source (PK is InstrumentID alone)
- Multiplier: contract size (e.g., 100 for crude oil means 1 contract = 100 barrels). Used in P&L calculation: profit = (price change) * Multiplier * IndexPointValue
- MinimalTick: smallest allowed price movement for the instrument (e.g., 0.01 for crude oil = $0.01/barrel)
- IndexPointValue: dollar value per single index point (e.g., 1.0 = $1 per point for crude, 50.0 = $50 per point for E-mini S&P 500)
- SettlementMethod: 0=Cash settlement (no physical delivery, settled in cash at expiration), 1=Physical settlement (actual delivery of underlying)
- UnitOfMeasure: the physical unit of the underlying commodity or asset

**Settlement Method Values** (Dictionary.SettlementMethodValues):
| ID | Value |
|----|-------|
| 0 | Cash |
| 1 | Physical |

**Unit of Measure Values** (Dictionary.UnitOfMeasure):
| ID | Value | Typical Use |
|----|-------|-------------|
| 0 | Points | Index futures (S&P 500, Nasdaq, etc.) |
| 1 | Barrel | Crude oil futures |
| 2 | Troy Ounce | Gold, silver futures |
| 3 | MMBtu | Natural gas futures (million British thermal units) |
| 4 | Pounds | Agricultural commodity futures |
| 5 | Short Tons | Coal/bulk commodity futures |
| 6 | Euros | EUR currency futures |
| 7 | Australian Dollars | AUD currency futures |
| 8 | British Pounds | GBP currency futures |
| 9 | Ether | Ethereum crypto futures |
| 10 | Bitcoin | Bitcoin crypto futures |
| 11 | SOL | Solana crypto futures |
| 12 | XRP | XRP crypto futures |

### 2.2 Contract Expiration Management

**What**: Futures contracts have a defined trading end and settlement date - these must be updated when contracts roll to new expiration months.

**Columns/Parameters Involved**: `LastTradingDateTime`, `ExpirationDateTime`, `SettlementTime`

**Rules**:
- LastTradingDateTime: the last datetime when the contract can be traded (after this, positions must be closed or settled)
- ExpirationDateTime: when the contract formally expires and final settlement is calculated
- SettlementTime: time of day for the settlement price calculation (e.g., 16:00 UTC for InstrumentID=18)
- In the DevTradingSTG environment, InstrumentID=18 shows LastTradingDateTime advancing by ~1 minute per update - this is test automation simulating contract roll cycles
- ExpirationDateTime='2030-01-01' is a sentinel value used for test instruments with no real expiration

### 2.3 SQL Server Temporal + INSERT Trigger Capture

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `Tr_T_FuturesMetaData_INSERT` fires no-op UPDATE (SET InstrumentID=InstrumentID) on InstrumentID match
- Zero-duration rows (SysStartTime=SysEndTime) are INSERT trigger captures
- DbLoginName: "DevTradingSTG" (direct SQL from the development/staging service, not a managed ops tool)
- AppLoginName: NULL in observed data (DevTradingSTG changes are direct SQL, no context_info set)

---

## 3. Data Overview

| InstrumentID | Multiplier | MinimalTick | IndexPointValue | SettlementMethod | UnitOfMeasure | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|---|---|
| 18 | 100 | 0.01 | 1.0 | 1 (Physical) | 1 (Barrel) | 2026-03-18 18:18 | 2026-03-19 08:57 | Crude oil contract. 1 contract = 100 barrels. Min tick $0.01/bbl. Physical delivery. ~52,770s version. |
| 18 | 100 | 0.01 | 1.0 | 1 (Physical) | 1 (Barrel) | 2026-03-18 18:17 | 2026-03-18 18:18 | Same spec, different LastTradingDateTime (advancing by ~1 min in test). ~53s version. |
| (250 instruments) | varies | varies | varies | 0 or 1 | 0-12 | 2024-10 | 2026-03 | Wide range of contract types: index, commodity, currency, crypto futures. |

Distribution of NULL SettlementMethod/UnitOfMeasure: 1,428 rows (63%) - these are pre-2025 records written before these columns were added.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The futures instrument whose contract specification is recorded. PK in source (not IDENTITY). One row per instrument in the current table. Implicit FK to Trade.Instrument. 250 distinct instruments in history. |
| 2 | Multiplier | decimal(20,10) | NO | - | CODE-BACKED | Contract size multiplier. Defines how many units of the underlying one contract represents. Example: Multiplier=100 for crude oil means 1 contract = 100 barrels. Used in P&L and margin calculations. High precision (20,10) supports small-unit contracts. |
| 3 | MinimalTick | decimal(20,10) | NO | - | CODE-BACKED | Minimum price increment (tick size) for this futures instrument. Example: 0.01 for crude oil = minimum $0.01 per barrel price movement per tick. Determines the minimum P&L change per tick = MinimalTick * Multiplier * IndexPointValue. |
| 4 | LastTradingDateTime | datetime | NO | - | CODE-BACKED | The last datetime when this futures contract can be actively traded. After this time, positions must be closed or they proceed to physical/cash settlement. Frequently updated as contracts roll to new expiration months. |
| 5 | ExpirationDateTime | datetime | NO | - | CODE-BACKED | The datetime when the futures contract formally expires and final settlement pricing is calculated. Indexed in source (IX_ExpirationDateTime) for efficient expiration scans. '2030-01-01' serves as a sentinel for test/synthetic instruments. |
| 6 | SettlementTime | time(7) | NO | - | CODE-BACKED | The time of day at which the settlement price is determined on the settlement date. Example: '16:00:00' (4pm UTC) for InstrumentID=18. The "1970-01-01" date prefix from the MCP query is an artifact of time(7) display. |
| 7 | IndexPointValue | decimal(20,10) | NO | - | CODE-BACKED | Dollar value per single index point (or unit). Example: IndexPointValue=1.0 for crude oil means each $1.00 price move = $1 per unit. For index futures like E-mini S&P 500, IndexPointValue=50 means each index point = $50. |
| 8 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Observed: "DevTradingSTG" (development/staging service account - direct SQL updates, not a managed ops tool). |
| 9 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info(). NULL in observed data - DevTradingSTG updates are made directly via SQL without setting context_info. |
| 10 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this contract specification version became active. For INSERT-trigger-captured rows, equals SysEndTime. |
| 11 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. |
| 12 | SettlementMethod | tinyint | YES | - | CODE-BACKED | How the futures contract settles at expiration. FK to Dictionary.SettlementMethodValues (ID column). 0=Cash settlement (no delivery, cash P&L), 1=Physical settlement (actual asset delivered). NULL for pre-2025 records (column added later). |
| 13 | UnitOfMeasure | tinyint | YES | - | CODE-BACKED | The physical unit of the underlying commodity or asset. FK to Dictionary.UnitOfMeasure (ID column). 0=Points (index), 1=Barrel, 2=Troy Ounce, 3=MMBtu, 4=Pounds, 5=Short Tons, 6=Euros, 7=Australian Dollars, 8=British Pounds, 9=Ether, 10=Bitcoin, 11=SOL, 12=XRP. NULL for pre-2025 records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | History.Instrument | Implicit | The futures instrument whose metadata is tracked. No FK in history table. |
| SettlementMethod | Dictionary.SettlementMethodValues | Implicit | 0=Cash, 1=Physical. FK enforced on source table. |
| UnitOfMeasure | Dictionary.UnitOfMeasure | Implicit | Unit of the underlying: Points, Barrel, Troy Ounce, etc. FK enforced on source table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FuturesMetaData | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here; INSERT trigger captures creations. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FuturesMetaData (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FuturesMetaData | Table | Source temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FuturesMetaData | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [PRIMARY] filegroup) |

Source table additionally has: IX_ExpirationDateTime NONCLUSTERED on ExpirationDateTime - used to scan for expiring contracts.

### 7.2 Constraints

None on history table. Source table has: CLUSTERED PK on InstrumentID (FILLFACTOR=90, DATA_COMPRESSION=PAGE), IX_ExpirationDateTime nonclustered.

---

## 8. Sample Queries

### 8.1 Contract specification for an instrument on a specific date

```sql
SELECT
    fmd.InstrumentID,
    fmd.Multiplier,
    fmd.MinimalTick,
    fmd.IndexPointValue,
    fmd.LastTradingDateTime,
    fmd.ExpirationDateTime,
    fmd.SettlementTime,
    fmd.SettlementMethod,
    smv.Value AS SettlementMethodName,
    fmd.UnitOfMeasure,
    uom.Value AS UnitOfMeasureName
FROM Trade.FuturesMetaData FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' fmd WITH (NOLOCK)
LEFT JOIN Dictionary.SettlementMethodValues smv WITH (NOLOCK) ON smv.ID = fmd.SettlementMethod
LEFT JOIN Dictionary.UnitOfMeasure uom WITH (NOLOCK) ON uom.ID = fmd.UnitOfMeasure
WHERE fmd.InstrumentID = @InstrumentID;
```

### 8.2 Change history for a futures contract's metadata

```sql
SELECT
    h.InstrumentID,
    h.Multiplier,
    h.MinimalTick,
    h.IndexPointValue,
    h.LastTradingDateTime,
    h.ExpirationDateTime,
    h.SettlementMethod,
    h.UnitOfMeasure,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSecs
FROM History.FuturesMetaData h WITH (NOLOCK)
WHERE h.InstrumentID = @InstrumentID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysStartTime;
```

### 8.3 All futures instruments by settlement type (current)

```sql
SELECT
    fmd.InstrumentID,
    fmd.Multiplier,
    fmd.IndexPointValue,
    fmd.ExpirationDateTime,
    smv.Value AS SettlementMethod,
    uom.Value AS UnitOfMeasure
FROM Trade.FuturesMetaData fmd WITH (NOLOCK)
LEFT JOIN Dictionary.SettlementMethodValues smv WITH (NOLOCK) ON smv.ID = fmd.SettlementMethod
LEFT JOIN Dictionary.UnitOfMeasure uom WITH (NOLOCK) ON uom.ID = fmd.UnitOfMeasure
ORDER BY fmd.SettlementMethod, uom.Value, fmd.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 directly analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FuturesMetaData | Type: Table | Source: etoro/etoro/History/Tables/History.FuturesMetaData.sql*
