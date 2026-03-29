# Dealing_dbo.Dealing_CryptoVolume_ByDirection

## 1. Overview
Daily crypto trading volume by instrument and direction (open/close, buy/sell), capturing trade count and units for all crypto positions (InstrumentTypeID=10). One row per DateID × InstrumentID × IsBuy × Leverage × IsSettled combination. Active daily refresh.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (DateID ASC) |
| **Row Count** | ~775K |
| **Date Range** | Historical → present (last: 2026-03-10) |
| **Grain** | One row per DateID × InstrumentID × IsBuy × Leverage × IsSettled |
| **Refresh** | Daily, via SP_CryptoVolume_ByDirection |

## 2. Business Context
This table provides the active daily-grain replacement for the stale `Dealing_CryptoVolume` table. It tracks how many crypto trades were opened vs closed in each direction, broken down by instrument, leverage, and settlement status. The key subtlety is that IsBuy is **inverted for close trades**: a close of a buy position is recorded as IsBuy=0, making it look like a sell — this enables volume aggregation by direction to balance correctly. Leverage and IsSettled segmentation allows analysis of leveraged vs non-leveraged crypto activity and settled vs open positions separately.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| DateID | int | No | Date integer key (YYYYMMDD) — distribution and clustering key | T2 | SP_CryptoVolume_ByDirection: @DateID parameter |
| FullDate | datetime | No | Full date as datetime | T2 | SP_CryptoVolume_ByDirection: `CONVERT(DATETIME, @Date)` |
| Leverage | int | No | Position leverage multiplier | T2 | DWH_dbo.Dim_Position.Leverage |
| IsSettled | int | Yes | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) | T2 | DWH_dbo.Dim_Position.IsSettled |
| InstrumentID | int | No | Crypto instrument ID (InstrumentTypeID=10) | T2 | DWH_dbo.Dim_Instrument (InstrumentTypeID=10 filter) |
| Instrument | varchar(50) | No | Crypto instrument name (e.g., BTC/USD, ETH/USD) | T2 | DWH_dbo.Dim_Instrument.InstrumentName |
| IsBuy | bit | No | Trade direction: 1=buy/open, 0=sell/close. NOTE: for close trades, IsBuy is inverted from position direction — a buy position close is recorded as IsBuy=0 | T2 | SP_CryptoVolume_ByDirection: `CASE WHEN IsBuy=1 THEN 0 ELSE 1 END` for closes |
| Volume | int | Yes | Trade count (number of click events) — `SUM(Volume)` for opens, `SUM(VolumeOnClose)` for closes | T2 | DWH_dbo.Dim_Position |
| Units | decimal(17,6) | Yes | Position size in instrument units | T2 | DWH_dbo.Dim_Position.AmountInUnitsDecimal |
| UpDate_Date | datetime | No | Row write timestamp | T2 | SP_CryptoVolume_ByDirection: `GETDATE()` |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| DWH_dbo.Dim_Position | Position data | InstrumentID, OpenDateID/CloseDateID=@DateID |
| DWH_dbo.Dim_Customer | IsValidCustomer=1 filter | CID |
| DWH_dbo.Dim_Instrument | Crypto instrument filter | InstrumentTypeID=10 |
| Dealing_dbo.Dealing_CryptoVolume | Predecessor table (stale) | Same concept, hourly grain |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_CryptoVolume_ByDirection` |
| **Parameters** | `@Date DATE`, `@DateID INT` |
| **Load Pattern** | DELETE + INSERT for @DateID |
| **Population** | All valid customers (IsValidCustomer=1) with crypto positions (InstrumentTypeID=10) opened or closed on @Date |
| **Key Logic** | 1) Filter Dim_Instrument for InstrumentTypeID=10. 2) Join Dim_Position for opens (OpenDateID=@DateID) and closes (CloseDateID=@DateID). 3) For opens: use IsBuy direct. 4) For closes: invert IsBuy (`CASE WHEN IsBuy=1 THEN 0 ELSE 1 END`). 5) Aggregate Volume/Units by DateID, InstrumentID, IsBuy, Leverage, IsSettled. |

## 6. Data Lifecycle
- **Retention**: No automated cleanup
- **Volume**: ~775K rows; low-cardinality aggregation — grows linearly with date range

## 7. Known Gaps
- IsBuy inversion for closes is a non-obvious convention — users must understand this when querying directional totals
- No client-level detail — aggregated grain only
- Compare with `Dealing_CryptoVolume` (stale hourly predecessor) for historical granularity pre-2024

## 8. Quality Score
**7.5/10** — Clear daily crypto volume aggregation. IsBuy inversion is well-documented in SP logic. Small table with clean grain.
