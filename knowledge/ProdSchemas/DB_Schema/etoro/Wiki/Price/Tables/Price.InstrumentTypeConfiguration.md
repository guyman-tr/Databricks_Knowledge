# Price.InstrumentTypeConfiguration

> Per-instrument-type market filter configuration defining the minimum interval (in milliseconds) between consecutive price update publications for each instrument category - controls how frequently the pricing engine propagates new prices downstream for Forex, Stocks, Crypto, etc.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentTypeID (int, CLUSTERED PK, FK to Dictionary.CurrencyType) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Price.InstrumentTypeConfiguration is the instrument-category-level price throttling configuration. It defines how frequently the pricing engine will forward new price updates to downstream consumers for each instrument type (Forex, Commodity, CFD, Indices, Stocks, ETF, Crypto).

The `MarketFilterIntervalMS` column specifies the minimum time between price publications: if two ticks arrive within this interval, the second is held until the interval expires. This prevents downstream systems from being overwhelmed with microsecond-level price changes that clients cannot act on anyway.

The table has 7 rows covering 7 of the 10 instrument types in Dictionary.CurrencyType (Bonds, TrustFunds, and Options are absent - they may not be actively priced or use different configuration).

The market filter values reflect the inherent update characteristics of each asset class:
- **Forex/Commodities/CFDs/Indices** (300ms): Highly liquid, frequently updating markets. 300ms = up to 3.3 updates/sec per instrument - fast enough to track meaningful price moves without saturating clients.
- **Stocks/ETFs** (1000ms): Equities update less frequently in practice; 1 second interval aligns with typical stock quote refresh rates.
- **Crypto** (400ms): More volatile than stocks but less continuously liquid than FX; 400ms balances responsiveness with volume management.

Data lifecycle: rows are inserted at system setup; rarely changed. All changes are audited via ASM triggers and full versions tracked in History.PriceInstrumentTypeConfiguration (note: history table name differs from the live table name).

---

## 2. Business Logic

### 2.1 Market Filter Interval as Throttle Rate

**What**: MarketFilterIntervalMS defines the minimum time gap between price publications per instrument type, implemented as a market filter in the pricing pipeline.

**Columns/Parameters Involved**: `InstrumentTypeID`, `MarketFilterIntervalMS`

**Rules**:
- Lower value = more frequent updates = higher downstream throughput requirement
- Higher value = fewer updates = lower throughput but potentially stale prices for fast-moving markets
- All instruments of the same InstrumentTypeID share the same interval
- Per-instrument overrides available via Price.PricingConfigurations (TopOfBookThrottlingInMs, FeedThrottlingInMs, ClientThrottlingInMs)
- This table represents the type-level default; PricingConfigurations provides instrument-level overrides

**Known values**:
| InstrumentTypeID | Type Name | MarketFilterIntervalMS | Update Rate |
|---|---|---|---|
| 1 | Forex | 300ms | up to 3.3/sec |
| 2 | Commodity | 300ms | up to 3.3/sec |
| 3 | CFD | 300ms | up to 3.3/sec |
| 4 | Indices | 300ms | up to 3.3/sec |
| 5 | Stocks | 1000ms | up to 1/sec |
| 6 | ETF | 1000ms | up to 1/sec |
| 10 | Crypto | 400ms | up to 2.5/sec |

**Diagram**:
```
External Price Feed -> Pricing Engine
  |
  v
Market Filter (per instrument):
  Elapsed since last publish < MarketFilterIntervalMS? -> HOLD tick
  Elapsed >= MarketFilterIntervalMS? -> PUBLISH tick downstream

InstrumentTypeID -> Price.InstrumentTypeConfiguration -> MarketFilterIntervalMS
  OR (if per-instrument override exists)
InstrumentID -> Price.PricingConfigurations -> TopOfBookThrottlingInMs
```

---

## 3. Data Overview

| InstrumentTypeID | Type Name | MarketFilterIntervalMS | Meaning |
|---|---|---|---|
| 1 | Forex | 300 | FX pairs update fast; 300ms provides near-real-time quotes without overwhelming clients |
| 2 | Commodity | 300 | Commodities (Oil, Gold) use same rate as FX |
| 3 | CFD | 300 | CFD instruments (indices, commodities via CFD) at same rate |
| 4 | Indices | 300 | Stock indices update quickly during market hours |
| 5 | Stocks | 1000 | Individual equities: 1/sec update cadence aligns with exchange-driven tick frequency |
| 6 | ETF | 1000 | ETFs trade like stocks; same 1/sec rate |
| 10 | Crypto | 400 | Crypto markets are active 24/7 but slightly less liquid than FX per instrument |

*Note: InstrumentTypeIDs 7 (Bonds), 8 (TrustFunds), 9 (Options) are absent - these types may not be actively priced or use different mechanisms.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NOT NULL | - | CODE-BACKED | Instrument type identifier. CLUSTERED PK. FK to Dictionary.CurrencyType(CurrencyTypeID). Values: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. One row per active instrument type in the pricing engine. |
| 2 | MarketFilterIntervalMS | int | NOT NULL | - | CODE-BACKED | Minimum time in milliseconds between consecutive price update publications for all instruments of this type. 300=Forex/Commodity/CFD/Indices (fast), 400=Crypto (medium-fast), 1000=Stocks/ETFs (standard). Lower values allow more frequent updates at higher system cost; higher values reduce throughput but may cause slightly stale quotes on volatile instruments. |
| 3 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set by SQL Server. |
| 4 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). |
| 5 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal row validity start. Auto-managed by system versioning. |
| 6 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31...' | CODE-BACKED | Temporal row validity end. Historical versions in History.PriceInstrumentTypeConfiguration (note: different naming from live table). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Dictionary.CurrencyType | FK (FK_PriceInstrumentConfig_CurrencyType) | MarketFilter is configured per instrument type from the central type registry |

### 5.2 Referenced By (other objects point to this)

No SSDT objects explicitly reference this table. Read by the PCS.PriceProvider pricing engine at runtime.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InstrumentTypeConfiguration (table)
  |-- FK -> Dictionary.CurrencyType
  ^-- Read by: PCS.PriceProvider market filter (application code)
  |-- Related: Price.PricingConfigurations (per-instrument overrides for the same throttling behavior)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CurrencyType | Table | FK - instrument type must exist in the central type registry |

### 6.2 Objects That Depend On This

No SSDT objects depend on this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Price_InstrumentTypeConfiguration | CLUSTERED PK | InstrumentTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PriceInstrumentConfig_CurrencyType | FK | InstrumentTypeID -> Dictionary.CurrencyType(CurrencyTypeID) |
| DF_InstrumentTypeConfiguration_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstrumentTypeConfiguration_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | History in History.PriceInstrumentTypeConfiguration |
| AuditDelete_Price_InstrumentTypeConfiguration | TRIGGER (DELETE) | Logs InstrumentTypeID and MarketFilterIntervalMS to History.AuditHistory |
| AuditInsert_Price_InstrumentTypeConfiguration | TRIGGER (INSERT) | Logs new InstrumentTypeID and MarketFilterIntervalMS |
| AuditUpdate_Price_InstrumentTypeConfiguration | TRIGGER (UPDATE) | Logs old/new values when changed |
| TRG_T_InstrumentTypeConfiguration | TRIGGER (INSERT) | ASM no-op placeholder: self-update on InstrumentTypeID |

---

## 8. Sample Queries

### 8.1 View all market filter intervals with instrument type names

```sql
SELECT ITC.InstrumentTypeID, CT.Name AS InstrumentType,
       ITC.MarketFilterIntervalMS,
       1000.0 / ITC.MarketFilterIntervalMS AS MaxUpdatesPerSec
FROM Price.InstrumentTypeConfiguration ITC WITH (NOLOCK)
JOIN Dictionary.CurrencyType CT WITH (NOLOCK)
    ON ITC.InstrumentTypeID = CT.CurrencyTypeID
ORDER BY ITC.MarketFilterIntervalMS ASC;
```

### 8.2 View change history (temporal)

```sql
SELECT InstrumentTypeID, MarketFilterIntervalMS, SysStartTime, SysEndTime, DbLoginName
FROM Price.InstrumentTypeConfiguration
FOR SYSTEM_TIME ALL
ORDER BY InstrumentTypeID, SysStartTime;
```

### 8.3 Identify instrument types without market filter configuration

```sql
SELECT CT.CurrencyTypeID, CT.Name
FROM Dictionary.CurrencyType CT WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Price.InstrumentTypeConfiguration ITC WITH (NOLOCK)
    WHERE ITC.InstrumentTypeID = CT.CurrencyTypeID
);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentTypeConfiguration | Type: Table | Source: etoro/etoro/Price/Tables/Price.InstrumentTypeConfiguration.sql*
