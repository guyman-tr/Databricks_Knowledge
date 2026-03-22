# Dealing_dbo.Dealing_DealingDashboard_Clients

> The central Dealing Dashboard fact table for client-side trading activity — daily granular aggregation of volumes, NOP, revenue (Zero), commissions, fees, dividends, and overnight charges segmented by instrument, regulation, country, MiFID category, copy/CFD status, and leverage.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — Dim_Position + BI_DB_PositionPnL + customer/instrument dimensions |
| **Refresh** | Daily |
| **Author** | Jenia Simonovitch (2021-10-06) |
| **Row Count** | ~1.83 billion |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE + NCI on DateID + NCI on (Date, InstrumentID) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dealing_DealingDashboard_Clients is the primary fact table powering the eToro Dealing Dashboard. It provides a comprehensive daily view of client trading activity aggregated at the grain of:

**Date × HedgeServerID × InstrumentID × Regulation × Country × Region × Mifid × IsCopy × IsCFD × Leverage × IsFuture**

This enables the dealing desk to slice and dice client activity across virtually any business dimension: by regulation, by instrument, by country, by copy trading status, by leverage level, etc.

With ~1.83B rows since July 2020, this is one of the largest tables in Dealing_dbo. The CCI storage with two NCIs (DateID and Date+InstrumentID) supports efficient analytical queries.

Key metric groups:
- **Volume**: VolumeOnOpen, VolumeOnClose, VolumeBuy, VolumeSell, TotalVolume
- **Position metrics**: NOP, LongOpenPositions, ShortOpenPositions, UnitsNOP, UnitsBuy, UnitsSell
- **Position counts**: NumberOfPositions, NumberOfPositionsOpened, NumberOfPositionsClosed
- **Revenue (Zero)**: RealizedZero, ChangeInUnrealizedZero, TotalZero
- **Fees**: FullCommission, VariableSpread, OverNightFee, Dividend, TicketFees

---

## 2. Business Logic

### 2.1 Volume Calculation

**Columns**: `VolumeOnOpen`, `VolumeOnClose`, `VolumeBuy`, `VolumeSell`, `TotalVolume`

**Rules**:
- VolumeOnOpen: Position Volume when opened today, else 0
- VolumeOnClose: VolumeOnClose when closed today, else 0
- VolumeBuy: Open+Buy or Close+Sell (buying direction flow)
- VolumeSell: Open+Sell or Close+Buy (selling direction flow)
- TotalVolume: VolumeOnOpen + VolumeOnClose

### 2.2 eToro Revenue (Zero)

**Columns**: `RealizedZero`, `ChangeInUnrealizedZero`, `TotalZero`

**Rules**:
- RealizedZero: Revenue crystallized from closed positions
- ChangeInUnrealizedZero: Daily change in unrealized revenue from open positions
- TotalZero: RealizedZero + ChangeInUnrealizedZero — total eToro daily revenue

### 2.3 Variable Spread

**Column**: `VariableSpread`

**Rules**: Spread revenue computed differently based on position lifecycle:
- Opened and closed same day: `Units * (EndAsk-EndBid) * USDRate`
- Opened earlier, closed today: `Units * (End spread - Init spread)` (change in spread value)
- Opened today, still open: `Units * (InitAsk-InitBid) * USDRate`

### 2.4 MiFID Classification

**Column**: `Mifid`

**Rules**: `CASE WHEN MifidCategorizationID IN (1,4) THEN 'Retail' WHEN IN (2,3) THEN 'Professional' ELSE Dim_MifidCategorization.Name END`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED COLUMNSTORE. **~1.83B rows**. Two NCIs: DateID and (Date, InstrumentID). Always filter by DateID or Date.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total daily volume by instrument type | `WHERE DateID = @DateID GROUP BY InstrumentType` |
| Revenue by regulation | `WHERE DateID = @DateID GROUP BY Regulation` |
| Copy vs non-copy volume | `WHERE DateID = @DateID GROUP BY IsCopy` |
| CFD vs Real comparison | `WHERE DateID = @DateID GROUP BY IsCFD` |
| Top instruments by NOP | `WHERE DateID = @DateID GROUP BY InstrumentID ORDER BY SUM(NOP) DESC` |

### 3.3 Gotchas

- **1.83B rows**: Always filter by DateID/Date. Full scans are extremely expensive.
- **NumberOfPositions** excludes partial close children (IsPartialCloseChild=1) to avoid double-counting
- **FullCommission** uses ISNULL fallback: `ISNULL(FullCommission, Commission)` — newer positions use FullCommission, older ones use Commission
- **IsCFD is inverted from IsSettled**: IsCFD=1 when IsSettled=0 (unsettled = CFD)
- **OverNightFee** is split into Long/Short in separate columns added later

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date. (Tier 2 — SP_DealingDashboard_Clients) |
| 2 | DateID | int | YES | Date as YYYYMMDD integer. (Tier 2 — SP_DealingDashboard_Clients) |
| 3 | HedgeServerID | int | YES | Hedge server routing the position. From Dim_Position. (Tier 2 — SP_DealingDashboard_Clients) |
| 4 | InstrumentType | varchar(50) | YES | Asset class from Dim_Instrument. (Tier 2 — SP_DealingDashboard_Clients) |
| 5 | InstrumentID | int | YES | Instrument identifier. (Tier 2 — SP_DealingDashboard_Clients) |
| 6 | InstrumentDisplayName | varchar(100) | YES | Human-readable instrument name. (Tier 2 — SP_DealingDashboard_Clients) |
| 7 | InstrumentName | varchar(100) | YES | Instrument ticker e.g. `AMD.RTH/USD`. (Tier 2 — SP_DealingDashboard_Clients) |
| 8 | Symbol | varchar(50) | YES | Short ticker symbol e.g. `AMD`. (Tier 2 — SP_DealingDashboard_Clients) |
| 9 | SellCurrency | varchar(10) | YES | Quote/sell currency of the instrument. (Tier 2 — SP_DealingDashboard_Clients) |
| 10 | Exchange | varchar(50) | YES | Stock exchange. From Dim_Instrument. (Tier 2 — SP_DealingDashboard_Clients) |
| 11 | Regulation | varchar(50) | YES | Client's regulatory jurisdiction. From Dim_Regulation via Fact_SnapshotCustomer. (Tier 2 — SP_DealingDashboard_Clients) |
| 12 | Country | varchar(50) | YES | Client's country. From Dim_Country via Fact_SnapshotCustomer. (Tier 2 — SP_DealingDashboard_Clients) |
| 13 | Region | varchar(50) | YES | Client's geographic region. From Fact_SnapshotCustomer. (Tier 2 — SP_DealingDashboard_Clients) |
| 14 | Mifid | varchar(50) | YES | MiFID classification: 'Retail' (IDs 1,4), 'Professional' (IDs 2,3), or Dim_MifidCategorization.Name. (Tier 2 — SP_DealingDashboard_Clients) |
| 15 | IsCopy | bit | YES | Copy trading flag. `CASE WHEN MirrorID>0 THEN 1 ELSE 0 END`. (Tier 2 — SP_DealingDashboard_Clients) |
| 16 | IsCFD | bit | YES | CFD flag. `CASE WHEN IsSettled=1 THEN 0 ELSE 1 END`. 1=CFD, 0=Real. (Tier 2 — SP_DealingDashboard_Clients) |
| 17 | Leverage | int | YES | Position leverage level from Dim_Position. (Tier 2 — SP_DealingDashboard_Clients) |
| 18 | VolumeOnOpen | money | YES | Trading volume from positions opened today. (Tier 2 — SP_DealingDashboard_Clients) |
| 19 | VolumeOnClose | money | YES | Trading volume from positions closed today. (Tier 2 — SP_DealingDashboard_Clients) |
| 20 | VolumeBuy | money | YES | Buy-direction volume (open buy + close sell). (Tier 2 — SP_DealingDashboard_Clients) |
| 21 | VolumeSell | money | YES | Sell-direction volume (open sell + close buy). (Tier 2 — SP_DealingDashboard_Clients) |
| 22 | TotalVolume | money | YES | VolumeOnOpen + VolumeOnClose. (Tier 2 — SP_DealingDashboard_Clients) |
| 23 | NOP | money | YES | Net open position value from BI_DB_PositionPnL. (Tier 2 — SP_DealingDashboard_Clients) |
| 24 | LongOpenPositions | money | YES | NOP for long positions (IsBuy=1). (Tier 2 — SP_DealingDashboard_Clients) |
| 25 | ShortOpenPositions | money | YES | ABS(NOP) for short positions (IsBuy=0). (Tier 2 — SP_DealingDashboard_Clients) |
| 26 | UnitsNOP | float | YES | Net units in open positions. Positive=long, negative=short. Only for positions still open at EOD. (Tier 2 — SP_DealingDashboard_Clients) |
| 27 | UnitsBuy | float | YES | Units in buy-direction flow (open buy + close sell). (Tier 2 — SP_DealingDashboard_Clients) |
| 28 | UnitsSell | float | YES | Units in sell-direction flow (open sell + close buy). (Tier 2 — SP_DealingDashboard_Clients) |
| 29 | NumberOfPositions | int | YES | Count of distinct positions (excludes partial close children). (Tier 2 — SP_DealingDashboard_Clients) |
| 30 | NumberOfPositionsOpened | int | YES | Positions opened today (excludes partial close children). (Tier 2 — SP_DealingDashboard_Clients) |
| 31 | NumberOfPositionsClosed | int | YES | Positions closed today. (Tier 2 — SP_DealingDashboard_Clients) |
| 32 | RealizedZero | money | YES | Realized eToro revenue (Zero) from closed positions. (Tier 2 — SP_DealingDashboard_Clients) |
| 33 | ChangeInUnrealizedZero | money | YES | Daily change in unrealized eToro revenue from open positions. (Tier 2 — SP_DealingDashboard_Clients) |
| 34 | TotalZero | money | YES | Total eToro daily revenue: Realized + ChangeInUnrealized. (Tier 2 — SP_DealingDashboard_Clients) |
| 35 | FullCommission | money | YES | Total commission. `ISNULL(FullCommission, Commission)` from Dim_Position. (Tier 2 — SP_DealingDashboard_Clients) |
| 36 | FullCommissionOnOpen | money | YES | Commission charged on position open. (Tier 2 — SP_DealingDashboard_Clients) |
| 37 | FullCommissionOnClose | money | YES | Commission charged on position close. (Tier 2 — SP_DealingDashboard_Clients) |
| 38 | VariableSpread | money | YES | Spread revenue. `Units*(Ask-Bid)*USDRate`, varies by open/close timing. (Tier 2 — SP_DealingDashboard_Clients) |
| 39 | OverNightFee | money | YES | Total overnight fee charged. (Tier 2 — SP_DealingDashboard_Clients) |
| 40 | Dividend | money | YES | Dividend adjustments on positions. From Fact_DividendTransaction. (Tier 2 — SP_DealingDashboard_Clients) |
| 41 | UpdateDate | datetime | YES | ETL load timestamp. (Tier 2 — SP_DealingDashboard_Clients) |
| 42 | OverNightFee_Long | decimal(19,4) | YES | Overnight fee for long positions only. (Tier 2 — SP_DealingDashboard_Clients) |
| 43 | OverNightFee_Short | decimal(19,4) | YES | Overnight fee for short positions only. (Tier 2 — SP_DealingDashboard_Clients) |
| 44 | TicketFees | money | YES | Ticket fees charged. From Fact_TicketFee. Added SR-263106 (2024-07). (Tier 2 — SP_DealingDashboard_Clients) |
| 45 | IsFuture | int | YES | Whether instrument is a future contract. From Dim_Instrument.IsFuture. Added SR-303782 (2025-03). (Tier 2 — SP_DealingDashboard_Clients) |

---

## 5. Lineage

Full lineage: see [Dealing_DealingDashboard_Clients.lineage.md](Dealing_DealingDashboard_Clients.lineage.md)

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_dbo.Dim_Position | Position lifecycle data, volumes, commissions |
| Source | BI_DB_dbo.BI_DB_PositionPnL | Daily NOP and P&L |
| Source | DWH_dbo.Fact_SnapshotCustomer | Customer regulation, country, MiFID |
| Source | DWH_dbo.Dim_Instrument | Instrument details, type, exchange |
| Source | DWH_dbo.Dim_Regulation | Regulation names |
| Source | DWH_dbo.Dim_Country | Country names |
| Source | DWH_dbo.Dim_MifidCategorization | MiFID category names |
| ETL | SP_DealingDashboard_Clients | Multi-step aggregation with Zero, fees, dividends |
| Target | Dealing_DealingDashboard_Clients | Daily dealing dashboard fact table |

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 45 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 8/10*
*Object: Dealing_dbo.Dealing_DealingDashboard_Clients | Type: Table | Production Source: Derived (Dim_Position + BI_DB_PositionPnL + dimensions)*
