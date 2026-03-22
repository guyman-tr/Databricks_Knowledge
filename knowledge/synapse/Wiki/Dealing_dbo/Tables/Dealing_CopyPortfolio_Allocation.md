# Dealing_dbo.Dealing_CopyPortfolio_Allocation

> Daily instrument-level allocation breakdown for CopyPortfolio (Smart Portfolio) managers, showing each instrument's weight by units and NOP within the portfolio, plus AUM and copier count.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — BI_DB_PositionPnL + BI_DB_CopyDailyData |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dealing_CopyPortfolio_Allocation tracks the daily portfolio composition of CopyPortfolio (also known as Smart Portfolio) managers on eToro. Each row represents one instrument held by one portfolio manager on a given date.

The table enables the Dealing team to monitor:
- **Portfolio concentration**: Which instruments dominate a manager's portfolio (by NOP_Percent)
- **AUM and scale**: Total assets under management and number of copiers per portfolio
- **Net position direction**: Whether the manager is net long or short each instrument (via signed NetUnits/NOP)

Scoped to `CopyType='Portfolio'` accounts from `BI_DB_CopyDailyData` — 207 distinct portfolio managers in history (~5.7M rows since 2021). The SP (`SP_CopyPortfolio_Allocation`) aggregates all positions for these managers from `BI_DB_PositionPnL`.

---

## 2. Business Logic

### 2.1 Portfolio Allocation Percentages

**What**: Computes each instrument's weight within a portfolio.

**Columns Involved**: `UnitsPercent`, `NOP_Percent`

**Rules**:
- UnitsPercent = `ABS(NetUnits) / SUM(ABS(NetUnits))` per CID — share of total portfolio units
- NOP_Percent = `ABS(NOP) / SUM(ABS(NOP))` per CID — share of total portfolio notional value
- Both sum to 1.0 across all instruments for a given CID+Date

### 2.2 Net Position Calculation

**What**: Nets long and short positions in each instrument.

**Columns Involved**: `NetUnits`, `NOP`

**Rules**:
- NetUnits = `SUM((2*IsBuy-1) * AmountInUnitsDecimal)` — positive for net long, negative for net short
- NOP = `SUM(NOP)` from BI_DB_PositionPnL — net notional value

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date. ~5.7M rows. Filter by Date.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Portfolio composition for a manager | `WHERE Date = @Date AND CID = @CID ORDER BY NOP_Percent DESC` |
| Largest portfolios by AUM | `WHERE Date = @Date GROUP BY CID, Username, AUM ORDER BY AUM DESC` |
| Most concentrated positions | `WHERE Date = @Date AND NOP_Percent > 0.2` |
| Portfolio with most copiers | `WHERE Date = @Date` and order by `Copiers DESC` |

### 3.3 Gotchas

- **CID is the portfolio manager**, not individual copiers. Copier positions are not in this table.
- **NOP may be in mixed currencies** — aggregated from BI_DB_PositionPnL without FX conversion
- **Only CopyType='Portfolio'** — does not include CopyTrader (person-copy) accounts

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date. `@Date` SP parameter. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 2 | CID | int | YES | CopyPortfolio manager's Customer ID. Filtered from `BI_DB_CopyDailyData` where `CopyType='Portfolio'`. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 3 | Username | varchar(100) | YES | Portfolio manager's username from `DWH_dbo.Dim_Customer.UserName` via RealCID JOIN. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 4 | InstrumentID | int | YES | Instrument identifier from `BI_DB_PositionPnL`. Joins to `DWH_dbo.Dim_Instrument`. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 5 | InstrumentDisplayName | varchar(100) | YES | Human-readable instrument name from `Dim_Instrument.InstrumentDisplayName`. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 6 | NetUnits | decimal(18,6) | YES | Signed net units. `SUM((2*IsBuy-1)*AmountInUnitsDecimal)`. Positive=net long, negative=net short. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 7 | NOP | decimal(18,6) | YES | Net open position value. `SUM(NOP)` from BI_DB_PositionPnL for this CID+instrument. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 8 | UnitsPercent | decimal(18,8) | YES | Instrument allocation weight by units. `ABS(NetUnits)/SUM(ABS(NetUnits))` per CID. Sums to 1.0 across portfolio. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 9 | NOP_Percent | decimal(18,8) | YES | Instrument allocation weight by notional value. `ABS(NOP)/SUM(ABS(NOP))` per CID. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 10 | UpdateDate | datetime | YES | ETL load timestamp — `GETDATE()`. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 11 | AUM | decimal(18,6) | YES | Total Assets Under Management for this portfolio. `CopyAUM` from `BI_DB_CopyDailyData`. (Tier 2 — SP_CopyPortfolio_Allocation) |
| 12 | Copiers | int | YES | Number of users copying this portfolio. `NumOfCopiers` from `BI_DB_CopyDailyData`. (Tier 2 — SP_CopyPortfolio_Allocation) |

---

## 5. Lineage

Full lineage: see [Dealing_CopyPortfolio_Allocation.lineage.md](Dealing_CopyPortfolio_Allocation.lineage.md)

| Step | Object | Description |
|------|--------|-------------|
| Source | BI_DB_CopyDailyData | Portfolio CID list + AUM/Copiers (CopyType='Portfolio') |
| Source | BI_DB_PositionPnL | Position-level data for portfolio managers |
| Source | Dim_Instrument | Instrument display names |
| Source | Dim_Customer | Usernames |
| ETL | SP_CopyPortfolio_Allocation | Aggregate positions, compute allocation %s |
| Target | Dealing_CopyPortfolio_Allocation | Daily portfolio allocation snapshot |

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 12 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_CopyPortfolio_Allocation | Type: Table | Production Source: Derived*
