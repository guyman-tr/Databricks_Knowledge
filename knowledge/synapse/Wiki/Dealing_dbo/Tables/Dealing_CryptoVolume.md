# Dealing_dbo.Dealing_CryptoVolume

## 1. Overview
Hourly crypto trading volume broken down by instrument, direction (IsBuy), client side vs eToro hedge side vs market maker, with settlement status. Table is **STALE** — last data date is 2024-04-02. No active writer SP was found in the SSDT repository.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered Columnstore |
| **Row Count** | ~8.5M |
| **Date Range** | Historical → 2024-04-02 (STALE) |
| **Grain** | One row per Date × StartHour × InstrumentID × IsBuy |
| **Refresh** | None — no active writer SP found |

## 2. Business Context
This table was designed to capture hourly crypto trading volumes across three perspectives: client-side (Clients_Volume/Units/Commission), hedge server side (HS_Volume/Units), and market maker side (MM_Volume/Units plus spot MM activity). The hourly grain (StartHour/EndHour) is finer than typical daily tables, indicating it was used for intraday crypto hedging oversight. The table has been stale since April 2024 — the responsible SP was likely decommissioned or renamed when crypto hedging infrastructure changed. The CLUSTERED COLUMNSTORE INDEX (unlike most Dealing_dbo tables which use clustered row-store) suggests it was optimized for analytical aggregations over large time ranges.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| InstrumentID | int | Yes | Crypto instrument ID (InstrumentTypeID=10) | T4 | Unknown — no active writer SP |
| Date | date | Yes | Trading date | T4 | Unknown |
| StartHour | time(7) | Yes | Start of the 1-hour interval | T4 | Unknown |
| EndHour | time(7) | Yes | End of the 1-hour interval | T4 | Unknown |
| InstrumentName | varchar(20) | Yes | Crypto instrument name (e.g., BTC/USD, ETH/USD) | T4 | Unknown |
| IsBuy | int | Yes | Trade direction: 1=buy, 0=sell | T4 | Unknown |
| Clients_Volume | float | Yes | Client-side trade count (opens/closes) in this hour | T4 | Unknown |
| Clients_Units | float | Yes | Client-side position units in this hour | T4 | Unknown |
| Clients_Commission | float | Yes | Client-side commission in USD for this hour | T4 | Unknown |
| HS_Volume | float | Yes | Hedge server trade count for this hour | T4 | Unknown |
| HS_Units | float | Yes | Hedge server position units | T4 | Unknown |
| MM_Volume | float | Yes | Market maker CFD trade count for this hour | T4 | Unknown |
| MM_Units | float | Yes | Market maker CFD position units | T4 | Unknown |
| UpdateDate | datetime | Yes | ETL metadata: row write timestamp | T4 | Unknown |
| MM_Crypto_Spot_Units | float | Yes | Market maker spot crypto units (separate from CFD) | T4 | Unknown |
| MM_Crypto_Spot_Volume | float | Yes | Market maker spot crypto trade count | T4 | Unknown |
| IsSettled | int | Yes | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) | T4 | Unknown |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| DWH_dbo.Dim_Instrument | Instrument metadata | InstrumentID |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | Unknown — no SP found in SSDT with INSERT INTO Dealing_CryptoVolume |
| **Load Pattern** | Unknown (CLUSTERED COLUMNSTORE INDEX suggests full-reload or append) |
| **Status** | STALE — last row 2024-04-02; likely decommissioned |
| **OpsDB** | No entry found for this table |

## 6. Data Lifecycle
- **Retention**: No automated cleanup — historical data frozen as of 2024-04-02
- **Volume**: ~8.5M rows; instruments include HBAR/USD, LUNA2/USD, SUI/USD, STORJ/USD, BAT/USD and others

## 7. Known Gaps
- **No active writer SP**: Cannot trace column lineage; T4 (unresolved) for all columns
- **STALE**: Data ends 2024-04-02 — do not use for current analysis
- The CLUSTERED COLUMNSTORE INDEX is unusual for Dealing_dbo tables (most use row-store) — suggests this was written in bulk/analytical mode
- `Dealing_CryptoVolume_ByDirection` is the active replacement with daily grain data through 2026

## 8. Quality Score
**3.0/10** — Table is stale and writer SP not found. Column semantics inferred from naming only. Retained for historical reference.
