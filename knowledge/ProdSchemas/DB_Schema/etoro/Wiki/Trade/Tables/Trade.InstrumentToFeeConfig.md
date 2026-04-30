# Trade.InstrumentToFeeConfig

> Temporal table that maps each instrument to percentage-based overnight and weekend fee rates (legacy; superseded by Trade.InstrumentToFeeConfigV2 with settlement-type awareness).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (PK) |
| **Partition** | None; on PRIMARY |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

**WHAT**: Trade.InstrumentToFeeConfig stores per-instrument fee rates for overnight (daily) and weekend (end-of-week) charges. Each row holds eight fee percentages: NonLeveraged vs Leveraged, Buy vs Sell, and OverNight vs EndOfWeek. The table is system-versioned with History.InstrumentToFeeConfig. A backward-compatibility view also named Trade.InstrumentToFeeConfig projects data from Trade.InstrumentToFeeConfigV2 for consumers that expect the old shape.

**WHY**: CFD and other leveraged positions incur overnight and weekend financing fees. The rates depend on leverage (leveraged vs non-leveraged) and direction (buy/sell). The legacy table did not distinguish settlement types (CFD, REAL, TRS, etc.); InstrumentToFeeConfigV2 adds SettlementTypeID for multi-settlement support. Trade.GetPositionsForFeeBulkGeneral still JOINs to Trade.InstrumentToFeeConfig (view over V2); Trade.GetPositionsForFeeProcess uses InstrumentToFeeConfigV2 directly.

**HOW**: Trade.UpdateInstrumentToFeeConfigTable accepts the legacy InstrumentToFeeConfigType TVP, maps it to InstrumentToFeeConfigTypeV2 (using SettlementTypeID from InstrumentMetaData), and delegates to Trade.UpdateInstrumentToFeeConfigTableV2. The view aggregates InstrumentToFeeConfigV2 by SettlementTypeID subsets (AllOther, Futures, CFD) to present a single-instrument-per-row shape for backward compatibility.

---

## 2. Business Logic

### 2.1 Fee Rate Layout

Columns: NonLeveragedSellEndOfWeekFee, NonLeveragedBuyEndOfWeekFee, NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee; LeveragedSellEndOfWeekFee, LeveragedBuyEndOfWeekFee, LeveragedBuyOverNightFee, LeveragedSellOverNightFee; NonLeveragedBuyCFDOverNightFee. Values are percentages (e.g., 0.01 = 0.01%). Leverage=1 uses NonLeveraged*; Leverage>1 uses Leveraged*.

### 2.2 CFD-Specific OverNight Fee

NonLeveragedBuyCFDOverNightFee applies to non-leveraged buy CFD positions. The view Trade.InstrumentToFeeConfig uses IIF(cfdType.InstrumentTypeID IS NULL, 0, CFD.NonLeveragedBuyOverNightFee) for CFD instruments in GetInstrumentTypeIDsForCFDFee; others get 0.

### 2.3 Temporal and Update Flow

Occurred stores when the config was changed; UpdatedByUser tracks who changed it. All updates flow through Trade.UpdateInstrumentToFeeConfigTableV2 (via UpdateInstrumentToFeeConfigTable for legacy callers). History.InstrumentToFeeConfig preserves previous versions.

---

## 3. Data Overview

| InstrumentID | NonLeveragedSellEndOfWeekFee | NonLeveragedBuyOverNightFee | Occurred | Meaning |
|--------------|------------------------------|-----------------------------|----------|---------|
| 1 | 0.0111573 | 0.01012 | 2026-03-12 14:49 | Instrument 1 rates |
| 200001 | 0 | 0 | 2024-12-01 05:59 | Zero-rate instrument |
| 200002 | 0.00452055 | 0.02424658 | 2026-01-27 13:16 | Higher overnight rate |
| 201000 | 0 | 0 | 2024-12-01 05:59 | Zero-rate instrument |
| 201001 | 0 | 0 | 2024-12-01 05:59 | Zero-rate instrument |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | PK; FK to Trade.Instrument. |
| 2 | NonLeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | VERIFIED | Weekend fee % for non-leveraged sell. |
| 3 | NonLeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | VERIFIED | Weekend fee % for non-leveraged buy. |
| 4 | NonLeveragedBuyOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee % for non-leveraged buy. |
| 5 | NonLeveragedSellOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee % for non-leveraged sell. |
| 6 | LeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | VERIFIED | Weekend fee % for leveraged sell. |
| 7 | LeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | VERIFIED | Weekend fee % for leveraged buy. |
| 8 | LeveragedBuyOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee % for leveraged buy. |
| 9 | LeveragedSellOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee % for leveraged sell. |
| 10 | Occurred | datetime | NO | - | VERIFIED | When config was last changed. |
| 11 | UpdatedByUser | varchar(50) | YES | - | VERIFIED | User/system that updated. |
| 12 | BeginTime | datetime2(7) | NO | (generated) | VERIFIED | Temporal row start. |
| 13 | EndTime | datetime2(7) | NO | (generated) | VERIFIED | Temporal row end. |
| 14 | NonLeveragedBuyCFDOverNightFee | decimal(16,8) | NO | 0 | VERIFIED | CFD-specific overnight rate for non-leveraged buy. |

---

## 5. Relationships

### 5.1 References To

| Referenced Object | Key | Relationship |
|------------------|-----|--------------|
| Trade.Instrument | InstrumentID | Instrument mapping |

### 5.2 Referenced By

| Object | Usage |
|--------|-------|
| Trade.GetPositionsForFeeBulkGeneral | JOIN (via view over V2) |
| Trade.UpdateInstrumentToFeeConfigTable | Maps to V2 and updates |
| Trade.RolloverFeesAlertIfNeeded1 | Compares current vs prev (History) |
| Trade.CheckValidInstruments_bck | Existence check; copy from |
| Trade.InstrumentToFeeConfig (view) | Presents V2 data in legacy shape |
| History.InstrumentToFeeConfig | Temporal history |

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.Instrument -> Trade.InstrumentToFeeConfig
Trade.InstrumentToFeeConfig -> Trade.GetPositionsForFeeBulkGeneral (via view)
Trade.UpdateInstrumentToFeeConfigTable -> Trade.InstrumentToFeeConfigV2

### 6.1 Objects This Depends On

| Object | Type | Purpose |
|--------|------|---------|
| Trade.Instrument | Table | InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | Purpose |
|--------|------|---------|
| Trade.GetPositionsForFeeBulkGeneral | Procedure | Fee rates for bulk overnight/weekend |
| Trade.UpdateInstrumentToFeeConfigTable | Procedure | Legacy update path |
| Trade.InstrumentToFeeConfig (view) | View | Backward compat over V2 |
| History.InstrumentToFeeConfig | Table | Temporal history |

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Key Columns | Purpose |
|-----|------|-------------|---------|
| PK_InstrumentToFeeConfigTemporal | Clustered PK | InstrumentID | Primary key |

### 7.2 Constraints

| Name | Type | Definition |
|-----|------|------------|
| PK_InstrumentToFeeConfigTemporal | PRIMARY KEY | InstrumentID |
| DF NonLeveragedBuyCFDOverNightFee | DEFAULT | 0 |
| SYSTEM_VERSIONING | - | History.InstrumentToFeeConfig |

---

## 8. Sample Queries

```sql
-- Current config for instrument (table or view)
SELECT InstrumentID, NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee,
       NonLeveragedSellEndOfWeekFee, LeveragedSellEndOfWeekFee
FROM Trade.InstrumentToFeeConfig WITH (NOLOCK)
WHERE InstrumentID = 1;

-- Temporal history for an instrument
SELECT InstrumentID, NonLeveragedBuyOverNightFee, Occurred, BeginTime, EndTime
FROM History.InstrumentToFeeConfig WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY BeginTime DESC;

-- Fee configs with recent updates
SELECT TOP 10 InstrumentID, Occurred, UpdatedByUser,
       NonLeveragedBuyOverNightFee, LeveragedBuyOverNightFee
FROM Trade.InstrumentToFeeConfig WITH (NOLOCK)
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.5/10 | Sources: DDL, MCP live data, Trade.UpdateInstrumentToFeeConfigTable, Trade.GetPositionsForFeeBulkGeneral, view definition*
