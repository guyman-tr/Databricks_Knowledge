# BI_DB_dbo.BI_DB_rsk_Portfolio

> Daily snapshot of net portfolio positions per customer per instrument, covering both direct (manual) and copy-trade positions from 2021-01-01 to 2026-04-13. Each row represents a unique customer × instrument × mirror-group combination, capturing signed net USD exposure (`Net_USD_Vol`) and absolute position size (`USD_Vol`) as computed by `SP_rsk_Portfolio` from open positions in `DWH_dbo.Dim_Position`. Approximately 390M rows per daily load; serves as the primary input for the Risk Dashboard (`SP_rsk_AgregatedRisk` → `BI_DB_rsk_DailyRiskAgg`) and PI correlation analysis (`SP_rsk_RiskCorelation_PIs`).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position (open positions snapshot) + DWH_dbo.Dim_Instrument (names) |
| **Refresh** | Daily; DELETE WHERE Date=@date + INSERT. SP @sd = yesterday; stored Date = @sd+1 (today) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC, CID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_rsk_Portfolio` is the daily portfolio exposure staging table for eToro's Risk Dashboard pipeline. Each row captures a customer's aggregated open positions for a single instrument (and mirror group), expressed in USD. 

The table is populated by `SP_rsk_Portfolio` (author: Gil Alpert, 2023-10-12) from `DWH_dbo.Dim_Position`, capturing all positions open as of `Date` (i.e., `OpenOccurred <= Date AND (CloseOccurred >= Date OR CloseDateID = 0)`). Positions are grouped by (CID, InstrumentID, MirrorID) to produce:

- **Net_USD_Vol**: Signed net USD exposure — long positions add positively, short positions subtract. Reflects directional market risk. As of 2026-04-13: 98.3% of rows are long (positive), 0.9% short, 0.8% zero.
- **USD_Vol**: Absolute USD position size regardless of direction. Used in covariance-weighted risk calculations downstream.

The table feeds two downstream risk SPs:
1. **`SP_rsk_AgregatedRisk`** reads `WHERE Date = @eed` (today) to compute portfolio-level standard deviation and covariance across instrument pairs → writes `BI_DB_rsk_DailyRiskAgg`.
2. **`SP_rsk_RiskCorelation_PIs`** reads this table for Popular Investor-specific correlation analysis.

**Date semantics**: The SP receives `@sd` (yesterday) and internally adjusts `@date = DateAdd(Day,1,@sd)`. The `Date` column therefore stores the day AFTER the SP input parameter — i.e., today's date when the SP runs as a daily job.

The top instruments by row count (2026-04-13): BTC/USD (833K rows), NVDA/USD (522K), ETH/USD (473K), AMZN/USD (465K), XRP/USD (407K). 57% of rows are copy-trade positions (MirrorID ≠ 0); 43% are direct manual trades.

---

## 2. Business Logic

### 2.1 Net vs Absolute Volume

**What**: Two parallel volume metrics serve different analytical needs.
**Columns Involved**: `Net_USD_Vol`, `USD_Vol`
**Rules**:
- `Net_USD_Vol` = SUM(AmountInUnitsDecimal × InitForexRate × (IsBuy → +1, else −1) × FX_conversion)
  - Positive = net long exposure in USD; Negative = net short exposure in USD
  - Used for directional market risk — a position that goes flat shows Net_USD_Vol = 0
- `USD_Vol` = SUM(AmountInUnitsDecimal × InitForexRate × FX_conversion) — no direction factor
  - Absolute total position size; always ≥ 0
  - Used for covariance-weight calculations in `SP_rsk_AgregatedRisk` (#c table)
- For a pure-long CID+Instrument+Mirror bucket: `Net_USD_Vol ≈ USD_Vol`
- Currency conversion: For USD quote instruments (SellCurrencyID=1): rate=1; for USD base (BuyCurrencyID=1): rate=1/InitForexRate; otherwise: rate=LastOpConversionRate

### 2.2 Direct vs Copy-Trade Segmentation

**What**: `MirrorID` distinguishes individual trades from copy-trade allocations.
**Columns Involved**: `MirrorID`
**Rules**:
- `MirrorID = 0`: Direct manual position (customer traded independently)
- `MirrorID > 0`: Copy-trade position (customer is copying a Popular Investor or CopyFund)
- `SP_rsk_AgregatedRisk` further segments by joining `Dim_Mirror.ParentCID` to `#Copyfunds` (AccountTypeID=9) to split Copy into CopyFund vs CopyTrader sub-segments
- 57% copy / 43% direct on 2026-04-13

### 2.3 Date Offset Convention

**What**: The stored `Date` value is one day ahead of the SP input parameter.
**Columns Involved**: `Date`
**Rules**:
- SP is invoked with `@sd = yesterday` (e.g., 2026-04-12)
- Inside SP: `@date = DateAdd(Day,1,@sd)` → `@date = 2026-04-13`
- The row `Date = 2026-04-13` is therefore inserted when SP runs on 2026-04-13 morning (with @sd = 2026-04-12)
- `SP_rsk_AgregatedRisk` reads `WHERE Date = @eed` where `@eed = dateadd(day,1,@sd)` — the same offset convention ensures the two SPs are temporally aligned

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`ROUND_ROBIN` — data is evenly distributed across 60 distributions. No column-level data locality. For large-scale aggregations, avoid joining on CID across many dates (fan-out risk). The clustered index on `(Date ASC, CID ASC)` makes date-bounded queries efficient; always filter by `Date =` or a narrow date range.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily portfolio exposure by instrument | `SELECT InstrumentName, SUM(Net_USD_Vol) FROM BI_DB_rsk_Portfolio WHERE Date = @date GROUP BY InstrumentName ORDER BY SUM(Net_USD_Vol) DESC` |
| Copy vs direct exposure ratio | `SELECT Date, SUM(CASE WHEN MirrorID=0 THEN USD_Vol ELSE 0 END) as DirectVol, SUM(CASE WHEN MirrorID>0 THEN USD_Vol ELSE 0 END) as CopyVol FROM BI_DB_rsk_Portfolio WHERE Date = @date GROUP BY Date` |
| Customer total portfolio size | `SELECT CID, SUM(USD_Vol) as TotalPositionSize FROM BI_DB_rsk_Portfolio WHERE Date = @date GROUP BY CID ORDER BY TotalPositionSize DESC` |
| Short positions by instrument | `SELECT InstrumentName, COUNT(*) as short_cids, SUM(ABS(Net_USD_Vol)) as short_usd FROM BI_DB_rsk_Portfolio WHERE Date = @date AND Net_USD_Vol < 0 GROUP BY InstrumentName` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `p.InstrumentID = di.InstrumentID` | Get InstrumentTypeID, asset class, currency pairs |
| DWH_dbo.Dim_Customer | `p.CID = dc.RealCID` | Customer demographic enrichment |
| DWH_dbo.Dim_Mirror | `p.MirrorID = dm.MirrorID WHERE p.MirrorID > 0` | Resolve copy-trade to Popular Investor (ParentCID) |

### 3.4 Gotchas

- **Date is NOT today's SP run date** — `Date = @sd+1`. A SP run with @sd=2026-04-12 inserts rows with Date=2026-04-13. Query by the date you want exposure *on*, not the load date.
- **MirrorID=0 vs MirrorID>0** — do NOT treat MirrorID as a boolean. Zero = direct; non-zero = copy. JOINing all rows to Dim_Mirror will miss direct positions (MirrorID=0 exists in Dim_Mirror as a system row).
- **Net_USD_Vol can be zero** — 0.8% of rows have Net_USD_Vol=0 (hedged or rounding). USD_Vol will typically still be non-zero in these cases.
- **ROUND_ROBIN** — no distribution key. Cross-distribution JOINs on CID or InstrumentID will shuffle data. For large aggregations, consider using `#pos` temp table patterns (as the SPs do) to avoid broadcast joins.
- **Table is ~390M rows per day** — use `COUNT_BIG(*)` not `COUNT(*)`. Always filter by `Date` before aggregating.
- **SP reads its own output** — `SP_rsk_AgregatedRisk` line 147 reads `FROM BI_DB_dbo.BI_DB_rsk_Portfolio WHERE Date = @eed`. This creates a run-order dependency: `SP_rsk_Portfolio` must complete before `SP_rsk_AgregatedRisk` starts.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (DWH_dbo wiki or production DB_Schema wiki) |
| Tier 2 | Derived from SP code, ETL logic, or Synapse DDL analysis |
| Tier 3 | Inferred from data sampling, naming conventions, or context |
| Tier 4 | Undetermined — pending review |
| P | Propagation metadata (ETL timestamp columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) |
| 2 | InstrumentID | int | NO | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 — Trade.Instrument) |
| 3 | InstrumentName | varchar(50) | NO | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). Passthrough from DWH_dbo.Dim_Instrument. (Tier 1 — DWH_dbo.Dim_Instrument) |
| 4 | MirrorID | int | YES | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 5 | Net_USD_Vol | decimal(38,6) | YES | Signed net USD exposure for this customer × instrument × mirror group on Date. Computed: SUM(AmountInUnitsDecimal × InitForexRate × IsBuy_direction × FX_rate). Positive = net long; Negative = net short. Used for directional risk analysis. 98.3% positive (long-biased platform) on 2026-04-13. (Tier 2 — SP_rsk_Portfolio) |
| 6 | USD_Vol | decimal(38,9) | YES | Absolute (unsigned) USD position size for this customer × instrument × mirror group. Computed: SUM(AmountInUnitsDecimal × InitForexRate × FX_rate) without buy/sell direction factor. Always ≥ 0. Used as covariance weight in SP_rsk_AgregatedRisk (#c.USD_Vol/1000 = Weightt1/2). (Tier 2 — SP_rsk_Portfolio) |
| 7 | Date | date | YES | Portfolio snapshot date. NOTE: equals SP @sd+1 — when SP runs with @sd=yesterday, stored Date is today. Open positions condition: OpenOccurred <= Date AND (CloseOccurred >= Date OR CloseDateID=0). Range: 2021-01-01 to 2026-04-13. (Tier 2 — SP_rsk_Portfolio) |
| 8 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (P) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Position | CID | Passthrough (group-by key) |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough via Dim_Position JOIN |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Passthrough (b.Name AS InstrumentName) |
| MirrorID | DWH_dbo.Dim_Position | MirrorID | Passthrough (group-by key) |
| Net_USD_Vol | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate, IsBuy, SellCurrencyID, BuyCurrencyID, LastOpConversionRate | SUM(AmountInUnitsDecimal × InitForexRate × ±direction × conversion) |
| USD_Vol | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate, SellCurrencyID, BuyCurrencyID, LastOpConversionRate | SUM(AmountInUnitsDecimal × InitForexRate × conversion) |
| Date | ETL parameter | @date = DateAdd(Day,1,@sd) | ETL date stamp |
| UpdateDate | GETDATE() | — | ETL metadata |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (open positions: OpenOccurred<=@date AND CloseOccurred>=@date)
  |-- JOIN DWH_dbo.Dim_Instrument ON InstrumentID (for Name) ---|
  |-- SP_rsk_Portfolio (@sd=yesterday → @date=@sd+1) ---------|
  |-- #pos: filter open positions at @date                      |
  |-- #a: GROUP BY CID,InstrumentID,InstrumentName,MirrorID     |
  v
BI_DB_dbo.BI_DB_rsk_Portfolio (DELETE WHERE Date=@date + INSERT)
  |-- SP_rsk_AgregatedRisk (@sd → reads WHERE Date=@eed) ---|
  v
BI_DB_dbo.BI_DB_rsk_DailyRiskAgg (portfolio risk metrics)

  |-- SP_rsk_RiskCorelation_PIs (PI correlation analysis) ---|
  v
BI_DB_dbo.BI_DB_rsk_RiskCorelation (PI correlation output)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer reference |
| InstrumentID | DWH_dbo.Dim_Instrument (InstrumentID) | Instrument reference |
| MirrorID | DWH_dbo.Dim_Mirror (MirrorID) | Copy-trade mirror reference (when > 0) |

### 6.2 Referenced By

| Object | How Used |
|--------|---------|
| BI_DB_dbo.BI_DB_rsk_DailyRiskAgg | Downstream — SP_rsk_AgregatedRisk reads this table to compute portfolio STD and covariance |
| BI_DB_dbo.BI_DB_Mirror_Assets_Allocation | Downstream — SP_rsk_AgregatedRisk computes asset allocation by mirror type |

---

## 7. Sample Queries

### Daily top 10 instruments by net long exposure

```sql
SELECT TOP 10
    InstrumentName,
    SUM(Net_USD_Vol) AS net_long_usd,
    COUNT(DISTINCT CID) AS customer_count
FROM [BI_DB_dbo].[BI_DB_rsk_Portfolio]
WHERE Date = '2026-04-13'
GROUP BY InstrumentName
ORDER BY SUM(Net_USD_Vol) DESC;
```

### Copy vs manual portfolio split by date

```sql
SELECT
    Date,
    SUM(CASE WHEN MirrorID = 0 THEN USD_Vol ELSE 0 END) AS direct_usd_vol,
    SUM(CASE WHEN MirrorID > 0 THEN USD_Vol ELSE 0 END) AS copy_usd_vol,
    SUM(USD_Vol) AS total_usd_vol
FROM [BI_DB_dbo].[BI_DB_rsk_Portfolio]
WHERE Date >= '2026-04-01' AND Date <= '2026-04-13'
GROUP BY Date
ORDER BY Date;
```

### Short positions by instrument (directional risk)

```sql
SELECT
    InstrumentName,
    COUNT(DISTINCT CID) AS short_customers,
    SUM(ABS(Net_USD_Vol)) AS total_short_usd
FROM [BI_DB_dbo].[BI_DB_rsk_Portfolio]
WHERE Date = '2026-04-13'
  AND Net_USD_Vol < 0
GROUP BY InstrumentName
ORDER BY total_short_usd DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. SP header attributes authorship to Gil Alpert (2023-10-12), updated 2023-12-13 by Adi F. Risk Dashboard pipeline context available from SP comments.

---

*Generated: 2026-04-23 | Quality: 8.7/10 | Phases: 11/14*
*Tiers: 4 T1, 3 T2, 0 T3, 0 T4, 1 P | Elements: 8/8, Logic: 9/10, Data Evidence: 10/10*
*Object: BI_DB_dbo.BI_DB_rsk_Portfolio | Type: Table | Production Source: DWH_dbo.Dim_Position + Dim_Instrument*
