# Dealing_dbo.Dealing_NOP_LPandClients

> Instrument-level daily NOP (Net Open Position) report combining both LP hedge positions and client open positions in a single table, enabling dealing desk NOP reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — LP netting + client positions combined |
| **Refresh** | Daily |
| **Retention** | 730 days (2 years, older rows deleted) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dealing_NOP_LPandClients is the central NOP reconciliation table for the eToro dealing desk. It stores instrument-level net open position data for both LP (liquidity provider) positions and client positions in a unified schema, enabling the dealing desk to see:

1. **LP positions**: The actual hedge positions held on LP servers (from netting history), valued at latest EOD prices and USD-converted
2. **Client positions**: The aggregate client positions (from BI_DB_PositionPnL), grouped by instrument and direction
3. **Special buckets**: Positions excluded from hedge computation (IsComputeForHedge=0) and LabelID=30 accounts, tracked separately

With ~45.5M rows covering 2 years across 64 hedge servers, 6 instrument types, and 4 TranTypes, this is one of the larger Dealing_dbo tables. It's populated by `SP_NOP_LPandClients` (authored by Jenia Simonovitch, 2019; LiquidityAccountID added by Adar in 2024, SR-281136).

---

## 2. Business Logic

### 2.1 LP NOP Calculation

**What**: Calculates the USD-denominated NOP of LP hedge positions at each instrument level.

**Columns Involved**: `NOP`, `NOP_Units` (when TranType='LP')

**Rules**:
- Source: `etoro_History_Netting_History` (temporal) UNION `etoro_Hedge_Netting` (current), deduplicated to latest per LiquidityAccountID+HedgeServerID+InstrumentID
- NOP_Units = `Units * (2*IsBuy - 1)` — positive for long, negative for short
- NOP = `Units * Price * (2*IsBuy-1) * FX_rate` — USD-converted using Bid (long) or Ask (short)
- FX conversion cascade: SellCurrencyID=1 → 1.0, BuyCurrencyID=1 → 1/price, else cross via intermediate pair
- Prices from `BI_DB_SpreadedPriceCandle60MinSplitted` — latest available before report date

### 2.2 Client Position Aggregation

**What**: Aggregates client open positions by instrument, direction, and classification.

**Columns Involved**: `NOP`, `NOP_Units` (when TranType IN ('Clients','IsComputeForHedge=0','LabelID=30'))

**Rules**:
- Source: `BI_DB_dbo.BI_DB_PositionPnL` for the target DateID
- NOP_Units = `SUM(AmountInUnitsDecimal * (2*IsBuy - 1))`
- NOP = `SUM(NOP)` from BI_DB_PositionPnL (already in NOP form)
- TranType classification:
  - `'IsComputeForHedge=0'` — positions where `Dim_Position.IsComputeForHedge = 0` (excluded from hedge calc)
  - `'LabelID=30'` — customers with `Dim_Customer.LabelID = 30` (special label)
  - `'Clients'` — all other client positions

### 2.3 Data Retention

**What**: Old data is pruned automatically.

**Rules**: Rows older than 730 days (2 years) are deleted on each SP execution before inserting new data.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED COLUMNSTORE. ~45.5M rows. Always filter by `DateID` or `Date`. CCI provides efficient aggregation for analytical queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Net exposure by instrument for a day | `WHERE DateID = @DateID GROUP BY InstrumentID, Instrument, TranType` |
| LP vs Client NOP comparison | Pivot on TranType: `WHERE DateID = @DateID AND TranType IN ('LP','Clients')` |
| Find instruments with hedge gaps | Compare LP NOP vs Clients NOP per InstrumentID |
| Track specific server's positions | `WHERE HedgeServerID = @ID AND DateID = @DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Get full instrument details |
| Dealing_dbo.Dealing_LP_StocksNOP | ON Date AND HedgeServerID | Cross-reference with aggregated LP NOP |
| Dealing_dbo.Dealing_ClientsCapitalAdequacy | ON Date | Regulatory capital adequacy context |

### 3.4 Gotchas

- **TranType is NOT just LP/Clients**: 4 values exist — `LP`, `Clients`, `IsComputeForHedge=0`, `LabelID=30`. Filter carefully.
- **NOP sign convention**: Positive = long, negative = short (via `2*IsBuy-1` formula)
- **LiquidityAccountID is NULL for client rows** — only populated for LP positions
- **LP NOP is USD-converted**, but Client NOP comes directly from BI_DB_PositionPnL (which may be in native currency) — verify currency alignment before comparing
- **2-year retention**: Do not expect data older than 730 days

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — SP_NOP_LPandClients)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HedgeServerID | int | YES | LP hedge server identifier. Applies to both LP and Client positions — clients are also assigned to hedge servers for routing. (Tier 2 — SP_NOP_LPandClients) |
| 2 | InstrumentType | varchar(50) | YES | Asset class from `DWH_dbo.Dim_Instrument.InstrumentType` via InstrumentID JOIN. Values: Stocks, ETF, Currencies, Commodities, Indices, Crypto Currencies. (Tier 2 — SP_NOP_LPandClients) |
| 3 | InstrumentID | int | YES | Instrument identifier, joining to `DWH_dbo.Dim_Instrument`. (Tier 2 — SP_NOP_LPandClients) |
| 4 | Instrument | varchar(50) | YES | Instrument display name from `DWH_dbo.Dim_Instrument.Name`. Format: `TICKER/CURRENCY` e.g. `AMD.RTH/USD`. (Tier 2 — SP_NOP_LPandClients) |
| 5 | IsBuy | bit | YES | Position direction. 1=Long/Buy, 0=Short/Sell. (Tier 2 — SP_NOP_LPandClients) |
| 6 | TranType | varchar(50) | YES | Position classification. `'LP'` = LP hedge position; `'Clients'` = client position included in hedge; `'IsComputeForHedge=0'` = position excluded from hedge (Dim_Position.IsComputeForHedge=0); `'LabelID=30'` = customer with LabelID=30. (Tier 2 — SP_NOP_LPandClients) |
| 7 | NOP_Units | numeric(20,6) | YES | Net open position in units. LP: `Units*(2*IsBuy-1)`. Clients: `SUM(AmountInUnitsDecimal*(2*IsBuy-1))`. Positive=long, negative=short. (Tier 2 — SP_NOP_LPandClients) |
| 8 | NOP | money | YES | Net open position in monetary value. LP: USD-converted via multi-step FX conversion from latest EOD Bid/Ask prices. Clients: `SUM(NOP)` from BI_DB_PositionPnL. (Tier 2 — SP_NOP_LPandClients) |
| 9 | DateID | int | YES | Date as integer `YYYYMMDD`. Computed via `Dealing_dbo.DateToDateID(@Date)`. (Tier 2 — SP_NOP_LPandClients) |
| 10 | Date | date | YES | Reporting date. `@Date` SP parameter. (Tier 2 — SP_NOP_LPandClients) |
| 11 | UpdateDate | datetime | YES | ETL load timestamp — `GETDATE()`. (Tier 2 — SP_NOP_LPandClients) |
| 12 | LiquidityAccountID | int | YES | LP account identifier from netting data. NULL for client rows. Added in SR-281136 (2024-11-19 by Adar). (Tier 2 — SP_NOP_LPandClients) |

---

## 5. Lineage

Full lineage: see [Dealing_NOP_LPandClients.lineage.md](Dealing_NOP_LPandClients.lineage.md)

### 5.2 ETL Pipeline

| Step | Object | Description |
|------|--------|-------------|
| Source (LP) | etoro_History_Netting_History + etoro_Hedge_Netting | LP hedge netting positions (temporal + current) |
| Source (LP) | BI_DB_SpreadedPriceCandle60MinSplitted | Latest EOD prices for USD conversion |
| Source (Clients) | BI_DB_PositionPnL | Client position-level data |
| Source (Clients) | Dim_Position, Dim_Customer | IsComputeForHedge and LabelID classification |
| Source (shared) | Dim_Instrument | Instrument type and name |
| ETL | SP_NOP_LPandClients | Dedup netting, calc NOP, classify clients, UNION into #Final |
| Target | Dealing_NOP_LPandClients | Daily instrument-level NOP (LP + Clients) |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument details |
| HedgeServerID | Production hedge servers | LP server identity |
| LiquidityAccountID | Production LP accounts | LP account (LP rows only) |

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 12 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 5/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_NOP_LPandClients | Type: Table | Production Source: Derived (LP netting + client positions)*
