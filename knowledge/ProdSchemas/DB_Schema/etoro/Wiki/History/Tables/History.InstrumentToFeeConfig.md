# History.InstrumentToFeeConfig

> Temporal history table capturing all changes to the legacy per-instrument overnight and end-of-week fee configuration, recording the complete audit trail of fee rates charged on leveraged and non-leveraged positions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (EndTime, BeginTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on EndTime, BeginTime, PAGE compressed) |

---

## 1. Business Meaning

History.InstrumentToFeeConfig is the SQL Server system-versioning history table for `Trade.InstrumentToFeeConfig`, the legacy (V1) per-instrument fee configuration table that stores overnight and end-of-week holding fee rates for each trading instrument. These fee rates are applied to open positions that are held past the daily close (overnight fees) or over the weekend (end-of-week fees), and they directly affect customer profitability on leveraged and non-leveraged positions.

This table answers audit questions such as "what were the overnight fee rates for instrument X when that position was held in September 2025?" and "when did the fee rates for this stock change?". These answers are required for customer dispute resolution, regulatory audit, and financial reconciliation when overnight fees charged on past positions need to be verified against the configuration that was active at the time.

Data flows in automatically via SQL Server SYSTEM_VERSIONING from `Trade.InstrumentToFeeConfig`. The live table uses InstrumentID as the sole PK (one fee config row per instrument, independent of settlement type). This is the V1 design; `Trade.InstrumentToFeeConfigV2` (and its history in `History.InstrumentToFeeConfigV2`) supersedes this table by adding per-settlement-type fee differentiation. BeginTime/EndTime replace the standard SysStartTime/SysEndTime naming but serve the same temporal function.

---

## 2. Business Logic

### 2.1 Fee Rate Matrix per Instrument

**What**: Eight fee rates per instrument covering all combinations of leveraged/non-leveraged and buy/sell for two time periods.

**Columns/Parameters Involved**: `LeveragedBuyOverNightFee`, `LeveragedSellOverNightFee`, `NonLeveragedBuyOverNightFee`, `NonLeveragedSellOverNightFee`, `LeveragedBuyEndOfWeekFee`, `LeveragedSellEndOfWeekFee`, `NonLeveragedBuyEndOfWeekFee`, `NonLeveragedSellEndOfWeekFee`

**Rules**:
- OverNight fees: charged per day the position is held past the trading session close
- EndOfWeek fees: charged when a position is held over the weekend (typically Friday close to Monday open), representing 3 days of holding cost in one charge
- Leveraged: position uses leverage (borrowed capital) - typically higher fees than non-leveraged
- NonLeveraged: customer owns the position outright (real stock, no leverage) - typically zero buy fee since no borrowing occurs
- Live data pattern: NonLeveragedBuyOverNightFee = 0 (no overnight cost for long real positions), NonLeveragedSellOverNightFee > 0 (short-selling non-leveraged has a borrowing cost)

**Diagram**:
```
Fee Matrix:
                  | OverNight    | EndOfWeek
------------------+--------------+----------
Leveraged Buy     | ~0.09 daily  | ~0.38 weekly
Leveraged Sell    | ~1.13 daily  | calculated
Non-Lev Buy       | 0.00 (free)  | 0.00 (free)
Non-Lev Sell      | ~1.13 daily  | calculated
Non-Lev Buy CFD   | separate col | (n/a)
```

### 2.2 Non-Leveraged CFD Overnight Fee (V1-specific)

**What**: V1 includes a dedicated column for non-leveraged CFD buy positions, distinguishing them from real stock buy positions.

**Columns/Parameters Involved**: `NonLeveragedBuyCFDOverNightFee`

**Rules**:
- Added later than the other fee columns (DEFAULT 0 constraint suggests it was added to an existing table)
- CFD positions (no real stock ownership) have a different cost structure than real stock positions
- Superseded in V2 by the SettlementTypeID dimension which handles all settlement-type-specific fee differentiation

---

## 3. Data Overview

| InstrumentID | NonLeveragedBuyOverNightFee | NonLeveragedSellOverNightFee | LeveragedBuyOverNightFee | LeveragedSellOverNightFee | Occurred | Meaning |
|---|---|---|---|---|---|---|
| 11544007 | 0 | 1.13185479 | 0.12576164 | 1.13185479 | 2025-09-29 | Fee config for this instrument (likely a stock): free to hold long (no borrow cost), 1.13% daily to short |
| 11543996 | 0 | 0.31237890 | 0.03470877 | 0.31237890 | 2025-09-29 | Different instrument with lower shorting cost (~0.31%) - fees vary significantly across instruments |
| 11543989 | 0 | 0.27665753 | 0.03073973 | 0.27665753 | 2025-09-29 | Another instrument: similar pattern - zero buy fee, 0.28% daily sell fee |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument this fee configuration applies to. PK in the live table (one row per instrument). FK to Trade.Instrument(InstrumentID). |
| 2 | NonLeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for non-leveraged (real stock) short sell positions. Charged when position is held over the weekend. Rate is a daily/weekly fee amount. |
| 3 | NonLeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for non-leveraged (real stock) long buy positions. Typically 0 as customers own the asset outright. |
| 4 | NonLeveragedBuyOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for non-leveraged long buy positions. Typically 0 because the customer owns the real stock outright and incurs no borrowing cost. Live data confirms all sampled rows = 0. |
| 5 | NonLeveragedSellOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for non-leveraged short sell positions. Positive because short selling requires borrowing the stock - customer pays the stock lending fee per night held. Varies by instrument based on borrow cost. |
| 6 | LeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for leveraged short sell positions. Covers the weekend holding period (3 days) as a single charge. |
| 7 | LeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for leveraged long buy positions. Approximately 3x the overnight rate, covering the weekend period. |
| 8 | LeveragedBuyOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for leveraged long buy positions. Small positive rate representing the daily interest cost on the borrowed capital used to lever the position (e.g., 0.035 to 0.126 per night). |
| 9 | LeveragedSellOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for leveraged short sell positions. Higher than buy overnight fee due to additional stock borrowing cost on top of leverage interest. Typically equals NonLeveragedSellOverNightFee in sampled data. |
| 10 | Occurred | datetime | NO | - | CODE-BACKED | Timestamp when this fee configuration was set or last updated by the user/process. Business-layer timestamp (distinct from BeginTime which is the temporal system timestamp). |
| 11 | UpdatedByUser | varchar(50) | YES | - | CODE-BACKED | Username of the operator who last updated this fee configuration. Null for automated system updates. |
| 12 | BeginTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this fee configuration became active in Trade.InstrumentToFeeConfig. Functions as SysStartTime in the temporal pattern (non-standard column name). |
| 13 | EndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this fee configuration was superseded. Functions as SysEndTime. Rows with EndTime = '9999-12-31' are active in the live table, not here. |
| 14 | NonLeveragedBuyCFDOverNightFee | decimal(16,8) | NO | 0 | CODE-BACKED | Overnight fee for non-leveraged CFD buy positions (contract for difference, no real stock ownership). Added post-initial-design (DEFAULT 0). Distinguishes CFD buy cost from real stock buy cost before V2 added SettlementTypeID to handle this differentiation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (FK in live table) | The instrument whose fee history is recorded. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentToFeeConfig | SYSTEM_VERSIONING | Temporal Source | Live table whose history is stored here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. (Temporal history table.)

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfig | Table | Live temporal table whose history is stored here |
| Trade.UpdateInstrumentToFeeConfigTable | Stored Procedure | Writer - updates fee configuration, creating history rows |
| Trade.GetInstrumentToFeeConfiguration | Stored Procedure | Reader - retrieves current fee configuration |
| Trade.CalculatePositionOvernightFee | Function | Reader - uses fee rates to compute overnight fee amounts |
| Trade.GetPositionsForFeeProcess | Stored Procedure | Reader - retrieves positions due for fee processing with fee config |
| Trade.CalcOverNightFeeRates | Stored Procedure | Reader - calculates overnight fee rates using this config |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentToFeeConfig | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active |

### 7.2 Constraints

None. (History tables do not have PK, FK, or CHECK constraints.)

---

## 8. Sample Queries

### 8.1 Find fee configuration for a specific instrument at a point in time
```sql
DECLARE @AsOf datetime2 = '2025-01-01 00:00:00'
SELECT
    InstrumentID,
    LeveragedBuyOverNightFee,
    LeveragedSellOverNightFee,
    NonLeveragedBuyOverNightFee,
    NonLeveragedSellOverNightFee,
    BeginTime,
    EndTime,
    UpdatedByUser
FROM History.InstrumentToFeeConfig WITH (NOLOCK)
WHERE InstrumentID = 1
  AND BeginTime <= @AsOf
  AND EndTime > @AsOf
```

### 8.2 Find all fee configuration changes for an instrument with attribution
```sql
SELECT
    InstrumentID,
    LeveragedBuyOverNightFee,
    LeveragedSellOverNightFee,
    NonLeveragedSellOverNightFee,
    BeginTime AS EffectiveFrom,
    EndTime AS EffectiveTo,
    Occurred,
    UpdatedByUser
FROM History.InstrumentToFeeConfig WITH (NOLOCK)
WHERE InstrumentID = 100
ORDER BY BeginTime DESC
```

### 8.3 Find instruments with high overnight sell fees (short-selling cost analysis)
```sql
SELECT
    InstrumentID,
    NonLeveragedSellOverNightFee,
    LeveragedSellOverNightFee,
    BeginTime AS ConfiguredFrom,
    EndTime AS ConfiguredTo
FROM History.InstrumentToFeeConfig WITH (NOLOCK)
WHERE EndTime > DATEADD(year, -1, GETUTCDATE())
  AND NonLeveragedSellOverNightFee > 1.0
ORDER BY NonLeveragedSellOverNightFee DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Payments in Non-USD - Overnight Fees, Dividends, Interest](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14039384103/Payments+in+Non-USD+Overnight+Fees+Dividends+Interest) | Confluence | Context on how overnight fees are structured and processed in the fee payment system |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentToFeeConfig | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentToFeeConfig.sql*
