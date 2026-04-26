# BI_DB_dbo.BI_DB_Investors_Top10

> 1.09M-row daily investor ranking table (2019-07-09 to 2026-04-11, 2,306 distinct dates) tracking the top 10 Popular Investors (PI), Portfolio investors, and instrument types by Net Money-In (NetMI) and Assets Under Advisory/Management (AUA/AUM) across four time windows: Yesterday, ThisWeek, ThisMonth, ThisYear. Written by SP_InvestorReportTop10 (SB_Daily, Priority 20). DELETE WHERE DateID + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction (manual NetMI), BI_DB_PositionPnL (AUA), BI_DB_CopyDailyData (copy NetMI + AUM) via SP_InvestorReportTop10 |
| **Refresh** | Daily (SB_Daily, Priority 20) — DELETE WHERE DateID=@dd + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_Investors_Top10 is a daily investor performance ranking table that identifies the top 10 performers (by Amount) within each InstrumentType × AssetType × TimeFrame combination. Each row represents a ranked entry in one of two measurement categories:

- **NetMI** (Net Money-In): the net amount of customer deposits minus withdrawals (`-1 × SUM(Fact_CustomerAction.Amount)` for ActionTypeID IN (1,4)) — positive values mean net inflows. For copy trading rows, this is `BI_DB_CopyDailyData.netMI`.
- **AUA_AUM** (Assets Under Advisory/Management): the total current value of open positions (`BI_DB_PositionPnL.Amount + PositionPnL` for MirrorID=0; `BI_DB_CopyDailyData.CopyAUM` for PI/Portfolio) — represents how much money is being managed within that instrument group.

The ranking is computed separately for each InstrumentType × AssetType × TimeFrame group using `ROW_NUMBER() OVER (PARTITION BY InstrumentType, AssetType ORDER BY Amount DESC)`, keeping only rank ≤ 10.

**AssetType classification** is determined by ETL CASE logic:
- `Investment`: InstrumentTypeID=6 (ETF) or InstrumentTypeID IN (4,5) with Leverage < 3
- `Trade`: everything else (higher-leverage positions)
- Copy (PI/Portfolio) rows are always classified as `Investment`

**Time windows** for NetMI:
- Yesterday: single day (DateID = @ddINT)
- ThisWeek: Monday of @dd week to Sunday
- ThisMonth: 1st of @dd month to end of month
- ThisYear: January 1st of @dd year to end of year

**AUA_AUM is only computed for Yesterday**; the other three time windows only have NetMI rows.

**Important dual-meaning of InstrumentID**: For rows where InstrumentType is 'PI' or 'Portfolio', the `InstrumentID` column stores the **CID** (customer ID) of the Popular Investor or Portfolio, NOT a tradeable instrument ID. Do not join these rows to `Dim_Instrument`.

Population: IsValidCustomer=1, IsDepositor=1 (manual side).

Row count: ~436 rows per date (varies by active instruments and available copy trading data).

---

## 2. Business Logic

### 2.1 AssetType Classification

**What**: Rows are split into Investment and Trade categories based on instrument type and leverage threshold.

**Columns Involved**: AssetType, InstrumentType, (implicit: Dim_Instrument.InstrumentTypeID, Fact_CustomerAction.Leverage)

**Rules**:
- `InstrumentTypeID = 6` (ETF) → always `Investment` regardless of leverage
- `InstrumentTypeID IN (4, 5)` (Indices, Stocks) with `Leverage < 3` → `Investment`
- `InstrumentTypeID IN (4, 5)` with `Leverage >= 3` → `Trade`
- All other instrument types → `Trade`
- PI and Portfolio copy rows → always `Investment` (hardcoded literal)

### 2.2 InstrumentID Dual Meaning for Copy Rows

**What**: The InstrumentID column stores different entity types depending on InstrumentType value.

**Columns Involved**: InstrumentID, InstrumentType

**Rules**:
- InstrumentType NOT IN ('PI', 'Portfolio'): InstrumentID = `DWH_dbo.Dim_Instrument.InstrumentID` — a tradeable instrument pair
- InstrumentType = 'PI': InstrumentID = CID of the Popular Investor (from `BI_DB_CopyDailyData.CID`)
- InstrumentType = 'Portfolio': InstrumentID = CID of the Portfolio manager (from `BI_DB_CopyDailyData.CID`)
- Do NOT join InstrumentType='PI'/'Portfolio' rows to `Dim_Instrument`; join to `Dim_Customer` instead

### 2.3 AUA_AUM vs NetMI Coverage

**What**: Not all time frames have both amount types.

**Columns Involved**: AmountType, TimeFrame

**Rules**:
- `AmountType = 'NetMI'`: populated for all 4 TimeFrame values (Yesterday/ThisWeek/ThisMonth/ThisYear)
- `AmountType = 'AUA_AUM'`: **only Yesterday** — no weekly/monthly/yearly AUA snapshots
- Manual AUA: SUM per-CID(BI_DB_PositionPnL.Amount + PositionPnL) aggregated by InstrumentID (MirrorID=0 only)
- Copy AUA: BI_DB_CopyDailyData.CopyAUM for the day

### 2.4 NetMI Sign Convention

**What**: Amount for NetMI is a sign-flipped sum of Fact_CustomerAction.Amount.

**Columns Involved**: Amount, AmountType

**Rules**:
- Fact_CustomerAction.Amount for deposits (ActionTypeID=1) is typically negative in the source
- SP applies `SUM(-1 * fca.Amount)` so positive Amount = net inflow to the broker
- For copy rows, netMI sign convention follows BI_DB_CopyDailyData.netMI directly (no additional sign flip)
- Negative Amount values are possible (e.g., net outflow days)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on DateID. Date-range queries are efficient. InstrumentType/TimeFrame/AmountType filters require full-scan over rows for the date range — use DateID range filter first to minimise data movement.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top 10 PIs by AUM yesterday | `WHERE DateID=@dd AND InstrumentType='PI' AND AmountType='AUA_AUM' AND TimeFrame='Yesterday' ORDER BY rank` |
| Top instruments by net flows this month | `WHERE DateID=@dd AND AmountType='NetMI' AND TimeFrame='ThisMonth' AND InstrumentType NOT IN ('PI','Portfolio') ORDER BY InstrumentType, AssetType, rank` |
| Trend of #1 rank for a given instrument type | `WHERE InstrumentType='Stocks' AND AssetType='Trade' AND AmountType='NetMI' AND TimeFrame='Yesterday' AND rank=1 ORDER BY DateID` |
| Combined Investment AUM by instrument type | `WHERE DateID=@dd AND AmountType='AUA_AUM' AND AssetType='Investment' GROUP BY InstrumentType ORDER BY SUM(Amount) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON t.InstrumentID = di.InstrumentID WHERE t.InstrumentType NOT IN ('PI','Portfolio')` | Enrich with InstrumentTypeID, name, sector |
| DWH_dbo.Dim_Customer | `ON t.InstrumentID = dc.RealCID WHERE t.InstrumentType IN ('PI','Portfolio')` | Resolve PI/Portfolio CID to customer name |
| DWH_dbo.Dim_Date | `ON t.DateID = dd.DateKey` | Add calendar dimensions |

### 3.4 Gotchas

- **InstrumentID dual meaning**: Do NOT join all rows to `Dim_Instrument` — PI/Portfolio rows use InstrumentID as CID. Always filter `WHERE InstrumentType NOT IN ('PI','Portfolio')` before joining to Dim_Instrument.
- **AUA_AUM is Yesterday-only**: Filtering `AmountType='AUA_AUM'` AND `TimeFrame <> 'Yesterday'` returns zero rows.
- **Negative Amount**: NetMI can be negative on days with net outflows. Do not assume Amount > 0.
- **No top-10 in some groups**: For some InstrumentType × AssetType × TimeFrame combinations on certain dates, fewer than 10 instruments may qualify (e.g., PI on a low-activity day). rank may go from 1 to fewer than 10.
- **No InstrumentType=NULL filter**: For 'PI' and 'Portfolio' rows, Dim_Instrument.InstrumentType lookup would fail — always guard with WHERE clause.
- **AUA uses MirrorID=0**: BI_DB_PositionPnL is filtered to MirrorID=0 (manual positions only). Copy AUA comes separately from BI_DB_CopyDailyData.CopyAUM.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best-available estimate; requires business confirmation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | ETL integer date key (YYYYMMDD) derived from SP parameter @dd. Marks the run date. Used as the DELETE key (DELETE WHERE DateID=@ddINT). (Tier 2 — SP_InvestorReportTop10) |
| 2 | Date | date | YES | Calendar date for this ranking snapshot. Equal to the SP's @dd parameter. Corresponds to DateID. (Tier 2 — SP_InvestorReportTop10) |
| 3 | TimeFrame | varchar(9) | NOT NULL | Aggregation window for which the ranking is computed. Values: `Yesterday` (single day), `ThisWeek` (Mon–Sun of @dd week), `ThisMonth` (1st to end of @dd month), `ThisYear` (Jan 1 to end of @dd year). AUA_AUM is only available for `Yesterday`. (Tier 2 — SP_InvestorReportTop10) |
| 4 | rank | bigint | YES | Top-10 rank (1=highest Amount) within InstrumentType × AssetType × TimeFrame partition. Computed by ROW_NUMBER() OVER (PARTITION BY InstrumentType, AssetType ORDER BY Amount DESC). Values: 1–10 per group. (Tier 2 — SP_InvestorReportTop10) |
| 5 | InstrumentType | varchar(50) | YES | Instrument category or copy trading type. For instrument-based rows: passthrough from DWH_dbo.Dim_Instrument.InstrumentType (Commodities, Crypto Currencies, Currencies, ETF, Indices, Stocks). For copy rows: literal 'PI' (Popular Investor) or 'Portfolio'. NULL not expected for instrument rows (filtered via INNER JOIN to Dim_Instrument). (Tier 2 — SP_InvestorReportTop10) |
| 6 | InstrumentID | int | YES | **Dual-meaning column.** For InstrumentType NOT IN ('PI','Portfolio'): tradeable instrument primary key from DWH_dbo.Dim_Instrument.InstrumentID. For InstrumentType IN ('PI','Portfolio'): CID (customer ID) of the Popular Investor or Portfolio manager, sourced from BI_DB_CopyDailyData.CID. Do NOT join PI/Portfolio rows to Dim_Instrument. (Tier 2 — SP_InvestorReportTop10) |
| 7 | Amount | decimal(38,2) | YES | Ranked metric value. Interpretation depends on AmountType: `NetMI`=net money-in for the time window in USD (SUM(-1×Fact_CustomerAction.Amount) for manual; BI_DB_CopyDailyData.netMI for copy — can be negative). `AUA_AUM`=assets under advisory/management in USD (SUM(BI_DB_PositionPnL.Amount+PositionPnL) for manual; BI_DB_CopyDailyData.CopyAUM for copy). Range (2026-04-11 AUA_AUM): $221K–$1.63B. (Tier 2 — SP_InvestorReportTop10) |
| 8 | AssetType | varchar(10) | NOT NULL | Asset classification: `Investment` (low-leverage stocks/indices + ETF + all copy trading) or `Trade` (higher-leverage positions). ETF (InstrumentTypeID=6) is always Investment. Stocks/Indices with Leverage<3 = Investment; ≥3 = Trade. PI/Portfolio copy rows hardcoded as Investment. (Tier 2 — SP_InvestorReportTop10) |
| 9 | AmountType | varchar(7) | NOT NULL | Metric type being ranked. Values: `NetMI` (net money-in; all 4 TimeFrame values) or `AUA_AUM` (assets under advisory/management; Yesterday only). (Tier 2 — SP_InvestorReportTop10) |
| 10 | UpdateDate | datetime | YES | ETL execution timestamp — GETDATE() at SP run time. Indicates when the ranking was last computed for this DateID. (Tier 2 — SP_InvestorReportTop10) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateID | SP parameter @dd | — | CONVERT(CHAR(8), @dd, 112) → INT |
| TimeFrame | ETL literal | — | 'Yesterday'/'ThisWeek'/'ThisMonth'/'ThisYear' |
| rank | ETL computed | — | ROW_NUMBER() OVER (...) |
| InstrumentType (instrument rows) | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| InstrumentType (copy rows) | BI_DB_CopyDailyData | CopyType | Literal passthrough ('PI'/'Portfolio') |
| InstrumentID (instrument rows) | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough |
| InstrumentID (copy rows) | BI_DB_CopyDailyData | CID | CID of PI/Portfolio stored as InstrumentID |
| Amount (manual NetMI) | DWH_dbo.Fact_CustomerAction | Amount | SUM(-1 × Amount) WHERE ActionTypeID IN (1,4) |
| Amount (copy NetMI) | BI_DB_CopyDailyData | netMI | Passthrough |
| Amount (manual AUA) | BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount+PositionPnL) per instrument, MirrorID=0 |
| Amount (copy AUM) | BI_DB_CopyDailyData | CopyAUM | Passthrough |
| AssetType | ETL CASE | Dim_Instrument.InstrumentTypeID, Fact_CustomerAction.Leverage | CASE logic on type+leverage |
| AmountType | ETL literal | — | 'NetMI' or 'AUA_AUM' |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID IN 1,4 — deposits/withdrawals)
DWH_dbo.Dim_Instrument (InstrumentType, InstrumentID lookup)
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (IsValidCustomer=1, IsDepositor=1 filter)
BI_DB_dbo.BI_DB_PositionPnL (MirrorID=0 — manual AUA: Amount+PositionPnL per CID×Instrument)
BI_DB_dbo.BI_DB_CopyDailyData (CopyType='PI'/'Portfolio' — copy netMI + CopyAUM)
  |-- SP_InvestorReportTop10 @dd (SB_Daily, Priority 20) ---|
  |   DELETE WHERE DateID=@ddINT                            |
  |   4 manual time-window temp tables (#Yesterday etc.)   |
  |   1 manual AUA temp table (#AUAYesterday)              |
  |   4 copy NetMI temp tables (#YesterdayCopy etc.)       |
  |   1 copy AUM temp table (#AUMYesterday)                |
  |   UNION all → TOP 10 rank per partition → INSERT       |
  ↓
BI_DB_dbo.BI_DB_Investors_Top10 (ROUND_ROBIN, CLUSTERED DateID)
  |-- UC: Not Migrated ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID (non-PI/Portfolio) | DWH_dbo.Dim_Instrument | FK to instrument dimension for type, name, sector enrichment |
| InstrumentID (PI/Portfolio rows) | DWH_dbo.Dim_Customer.RealCID | CID of the Popular Investor or Portfolio manager |
| Amount (manual NetMI) | DWH_dbo.Fact_CustomerAction | Source of net money-in via -1×Amount sum |
| Amount (manual AUA) | BI_DB_dbo.BI_DB_PositionPnL | Source of AUA: Amount+PositionPnL per MirrorID=0 position |
| Amount (copy) | BI_DB_dbo.BI_DB_CopyDailyData | Source of copy netMI and CopyAUM |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| (No documented consumers in current batch context) | — |

---

## 7. Sample Queries

### Top 10 Popular Investors by AUM yesterday

```sql
SELECT DateID, InstrumentType, InstrumentID AS PI_CID, rank, Amount AS AUM_USD
FROM [BI_DB_dbo].[BI_DB_Investors_Top10]
WHERE DateID = 20260411
  AND InstrumentType = 'PI'
  AND AmountType = 'AUA_AUM'
  AND TimeFrame = 'Yesterday'
ORDER BY rank;
```

### Top instruments by net money-in this year (Investment asset type)

```sql
SELECT DateID, InstrumentType, InstrumentID, rank, Amount AS NetMI_USD
FROM [BI_DB_dbo].[BI_DB_Investors_Top10]
WHERE DateID = 20260411
  AND AmountType = 'NetMI'
  AND TimeFrame = 'ThisYear'
  AND AssetType = 'Investment'
  AND InstrumentType NOT IN ('PI', 'Portfolio')
ORDER BY InstrumentType, rank;
```

### Daily trend for #1 Stocks (Trade) net money-in

```sql
SELECT DateID, Amount AS NetMI_USD
FROM [BI_DB_dbo].[BI_DB_Investors_Top10]
WHERE InstrumentType = 'Stocks'
  AND AssetType = 'Trade'
  AND AmountType = 'NetMI'
  AND TimeFrame = 'Yesterday'
  AND rank = 1
  AND DateID >= 20260101
ORDER BY DateID;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for BI_DB_Investors_Top10.

---

*Generated: 2026-04-22 | Quality: 8.7/10 | Phases: 11/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, ETL: 9/10*
*Object: BI_DB_dbo.BI_DB_Investors_Top10 | Type: Table | Production Source: DWH_dbo.Fact_CustomerAction + BI_DB_PositionPnL + BI_DB_CopyDailyData via SP_InvestorReportTop10*
