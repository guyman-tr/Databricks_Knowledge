# Price.InstrumentConfiguration

> Per-instrument spread and skew control thresholds for the pricing engine - defines when bid/ask spreads trigger alerts (SpreadAlertThresholdPercentage), when they cause a trading lock (SpreadLockThresholdPercentage), the maximum allowed skew magnitude (SkewLimitThreshold), and eToro's maximum spread enforcement cap (EtoroMaxSpreadPercentage).

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK, FK to Trade.Instrument) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR=90, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

Price.InstrumentConfiguration is the per-instrument safety and quality control configuration for eToro's pricing engine. It defines four threshold values that govern how the pricing engine responds to abnormal spread or skew conditions for each instrument.

These thresholds protect both clients and the firm:
- **Spread alerts** notify the trading desk when spreads widen significantly (market stress, liquidity crisis, data feed issue)
- **Spread locks** automatically halt new position opening when spreads become unacceptably wide (protects clients from executing at terrible prices)
- **Skew limits** cap the maximum price adjustment the skew algorithm can apply (prevents runaway skewing)
- **eToro max spread** enforces eToro's own maximum spread commitment regardless of what the external feed quotes

With 10,014 rows, this table has a configuration entry for virtually every active instrument. The SpreadAlertThresholdPercentage ranges from ~0.05% (tight EUR/USD-class instruments) to over 0.15% (wider-spread instruments). SpreadLockThresholdPercentage is consistently 2-3x the alert threshold.

Data lifecycle: rows are inserted when new instruments are onboarded. Updated by pricing operations when calibrating spread thresholds. Temporal system versioning tracks all configuration changes.

---

## 2. Business Logic

### 2.1 Spread Control - Alert and Lock Cascade

**What**: Two-level spread control: alert first, lock if spread continues widening.

**Columns/Parameters Involved**: `SpreadAlertThresholdPercentage`, `SpreadLockThresholdPercentage`

**Rules**:
- Spread % = (Ask - Bid) / MidPrice * 100
- SpreadAlertThresholdPercentage: when Spread% exceeds this value, generate an alert (notification to trading desk / monitoring). Does NOT block trading.
- SpreadLockThresholdPercentage: when Spread% exceeds this value, lock the instrument - new position openings are rejected until spread normalizes below the threshold
- Typical pattern: Alert at 0.10%, Lock at 0.30% (3x alert threshold)
- SpreadLockThresholdPercentage is nullable: NULL = no lock threshold configured for this instrument (alert only)
- Both are percentage values stored as decimal(10,6) and decimal(12,5) respectively

**Data pattern from sample**:
| InstrumentID | Alert% | Lock% | Type |
|---|---|---|---|
| 1 | 0.0719% | 0.20% | Tight (EUR/USD class) |
| 3 | 0.1583% | 0.40% | Moderate |
| 8 | 0.0977% | 0.60% | Wide lock tolerance |

**Diagram**:
```
Live Spread = (Ask - Bid) / Mid * 100

  < SpreadAlertThresholdPercentage  -> Normal, no action
  >= SpreadAlertThresholdPercentage -> ALERT: notify trading desk
  >= SpreadLockThresholdPercentage  -> LOCK: reject new position openings
  < SpreadLockThresholdPercentage (after lock) -> UNLOCK: resume normal trading
```

### 2.2 Skew Limit Enforcement

**What**: SkewLimitThreshold caps the maximum skew offset the algorithm can apply to protect against excessive price distortion.

**Columns/Parameters Involved**: `SkewLimitThreshold`

**Rules**:
- SkewLimitThreshold = 0 (DEFAULT and observed value for all sampled instruments): no skew limit cap applied; the algorithm can apply any calculated skew
- SkewLimitThreshold > 0: the skew value from Price.BuyRatioThresholds is capped at this maximum
- Prevents a runaway skew scenario where extreme buy/sell imbalance would cause an unreasonably large price distortion
- Applied in price units (same unit as Price.ActiveSkew.SkewBid/SkewAsk)

### 2.3 eToro Maximum Spread Policy

**What**: EtoroMaxSpreadPercentage enforces eToro's commitment to not charge more than a defined maximum spread, overriding what the external feed quotes.

**Columns/Parameters Involved**: `EtoroMaxSpreadPercentage`

**Rules**:
- EtoroMaxSpreadPercentage = 0 (DEFAULT and observed for all sampled instruments): no eToro spread cap enforced; raw feed spread is used
- EtoroMaxSpreadPercentage > 0: if the feed spread exceeds this value, the pricing engine caps the spread at this maximum (adjusting bid/ask to enforce the cap)
- Represents a client-protection commitment: "eToro will never charge more than X% spread on this instrument"
- Percentage stored as decimal(10,6)

---

## 3. Data Overview

| Note | Value |
|------|-------|
| Row count | 10,014 (covers all active instruments) |
| SpreadAlertThresholdPercentage range | ~0.05% to 0.20%+ depending on instrument volatility/liquidity |
| SpreadLockThresholdPercentage | Typically 2-6x the alert threshold; NULL for some instruments |
| SkewLimitThreshold | 0 for all sampled instruments (no cap) |
| EtoroMaxSpreadPercentage | 0 for all sampled instruments |

| InstrumentID | SpreadAlert% | SpreadLock% | SkewLimit | EtoroMaxSpread |
|---|---|---|---|---|
| 1 | 0.0719% | 0.20% | 0 | 0 |
| 2 | 0.1124% | 0.20% | 0 | 0 |
| 3 | 0.1583% | 0.40% | 0 | 0 |
| 5 | 0.0514% | 0.20% | 0 | 0 |
| 8 | 0.0977% | 0.60% | 0 | 0 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. CLUSTERED PK. FK to Trade.Instrument. One row per instrument. |
| 2 | SpreadAlertThresholdPercentage | decimal(10,6) | NOT NULL | - | CODE-BACKED | Alert threshold: when the bid/ask spread as a percentage of mid price exceeds this value, the pricing engine generates an alert. Does not halt trading. Expressed as a percentage (e.g., 0.0719 = 0.0719%). decimal(10,6) provides sub-pip precision for tight FX spreads. |
| 3 | SpreadLockThresholdPercentage | decimal(12,5) | YES | - | CODE-BACKED | Lock threshold: when spread% exceeds this value, new position openings are rejected for this instrument until the spread normalizes. NULL = no lock threshold (alert-only mode). Typically 2-6x the alert threshold. decimal(12,5) has slightly different precision from the alert threshold - supports wider spread values for volatile instruments. |
| 4 | SkewLimitThreshold | decimal(10,6) | NOT NULL | 0 | CODE-BACKED | Maximum skew magnitude cap in price units. DEFAULT=0 means no cap. When > 0: the skew algorithm's output (from Price.BuyRatioThresholds) is capped at this value before being applied. Prevents extreme client-side imbalances from causing disproportionate price distortions. |
| 5 | EtoroMaxSpreadPercentage | decimal(10,6) | NOT NULL | 0 | CODE-BACKED | eToro's maximum spread policy cap as a percentage. DEFAULT=0 means no cap enforced. When > 0: if the external feed spread exceeds this value, the pricing engine adjusts bid/ask to enforce the cap. Represents eToro's commercial commitment to maximum spread on this instrument. |
| 6 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set by SQL Server. |
| 7 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). Populated when calling service sets context_info before DML. |
| 8 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal row validity start. Auto-managed by system versioning. |
| 9 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31...' | CODE-BACKED | Temporal row validity end. Historical versions in History.InstrumentConfiguration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_PriceInstrumentConfiguration_InstrumentID) | Configuration is per-instrument; FK enforces instrument must exist |

### 5.2 Referenced By (other objects point to this)

No SSDT objects explicitly reference this table. Read by the pricing engine application (PCS.PriceProvider) at runtime.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InstrumentConfiguration (table)
  |-- FK -> Trade.Instrument
  |-- Related: Price.BuyRatioThresholds (SkewLimitThreshold caps this table's skew output)
  |-- Read by: pricing engine (application code)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK - instrument must exist |

### 6.2 Objects That Depend On This

No SSDT objects explicitly depend on this table (consumed by pricing engine application code).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PriceInstrumentConfiguration | CLUSTERED PK | InstrumentID ASC | - | - | Active, FILLFACTOR=90, DATA_COMPRESSION=PAGE |

*DATA_COMPRESSION=PAGE reduces storage footprint for this 10K+ row table; the decimal columns compress well.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PriceInstrumentConfiguration_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| DF_InstrumentConfiguration_SkewLimitThreshold | DEFAULT | SkewLimitThreshold = 0 |
| D_EtoroMaxSpreadPercentage | DEFAULT | EtoroMaxSpreadPercentage = 0 |
| DF_InstrumentConfiguration_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstrumentConfiguration_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.InstrumentConfiguration |
| TRG_T_InstrumentConfiguration | TRIGGER (INSERT) | ASM no-op placeholder: self-update on InstrumentID |

---

## 8. Sample Queries

### 8.1 Find instruments with tight spread alert thresholds (FX/major instruments)

```sql
SELECT TOP 20 InstrumentID, SpreadAlertThresholdPercentage, SpreadLockThresholdPercentage
FROM Price.InstrumentConfiguration WITH (NOLOCK)
ORDER BY SpreadAlertThresholdPercentage ASC;
```

### 8.2 Instruments with no spread lock configured

```sql
SELECT InstrumentID, SpreadAlertThresholdPercentage
FROM Price.InstrumentConfiguration WITH (NOLOCK)
WHERE SpreadLockThresholdPercentage IS NULL
ORDER BY InstrumentID;
```

### 8.3 Instruments with active skew limit or eToro max spread policy

```sql
SELECT InstrumentID, SkewLimitThreshold, EtoroMaxSpreadPercentage
FROM Price.InstrumentConfiguration WITH (NOLOCK)
WHERE SkewLimitThreshold > 0 OR EtoroMaxSpreadPercentage > 0
ORDER BY EtoroMaxSpreadPercentage DESC, SkewLimitThreshold DESC;
```

### 8.4 View configuration change history for an instrument (temporal)

```sql
SELECT InstrumentID, SpreadAlertThresholdPercentage, SpreadLockThresholdPercentage,
       SysStartTime, SysEndTime, DbLoginName
FROM Price.InstrumentConfiguration
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1
ORDER BY SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentConfiguration | Type: Table | Source: etoro/etoro/Price/Tables/Price.InstrumentConfiguration.sql*
