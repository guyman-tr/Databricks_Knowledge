# BI_DB_dbo.BI_DB_DDR_Fact_PnL

> **Daily DDR P&amp;L aggregate** at **`RealCID` × `InstrumentTypeID` × flags** grain: **~9.0B rows** (Synapse `COUNT_BIG` May 2026), **`DateID`** span **20150102–20260426** (live pool). Combines **realized** net profit from positions **closed on** `@date` and **unrealized P&amp;L change** from **`BI_DB_PositionPnL`** day-over-day logic inside **`Function_PnL_Single_Day`**, matching the **Fact_CustomerAction** / **Dim_Position** trading foundation. Refreshed **`DELETE` + `INSERT`** per day by **`SP_DDR_Fact_PnL @date`**; exported to UC Gold **`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl`** (Append, 1440 min). **`HASH(RealCID)`** distribution — co-locate with other DDR facts on customer.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Row count (indicative)** | ~8,999,215,549 (`COUNT_BIG(*)` May 2026) |
| **Date span (DateID)** | `20150102` – `20260426` (pool sample) |
| **Production Source** | Position economics chain: `DWH_dbo.Dim_Position`, `BI_DB_dbo.BI_DB_PositionPnL`, `DWH_dbo.Dim_Instrument`, `BI_DB_dbo.Function_Instrument_Snapshot_Enriched` — composed in **`Function_PnL_Single_Day`**; loaded by **`BI_DB_dbo.SP_DDR_Fact_PnL`** |
| **Refresh** | Daily (`DELETE ... WHERE DateID=@dateID` then `INSERT`): Synapse job pattern per DDR family (confirm parent SB in OpsDB if needed) |
| **PII / GDPR** | **`RealCID`** is a **direct customer identifier** — treat as **PII-sensitive**; join **`Dim_Customer`** for attributes under data-governance rules |
| **Synapse Distribution** | `HASH(RealCID)` |
| **Synapse Index** | `CLUSTERED COLUMNSTORE INDEX` |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` |
| **UC Format** | delta |
| **UC Partitioned By** | `etr_y`, `etr_ym`, `etr_ymd` (Databricks layer; `DESCRIBE TABLE` May 2026) |
| **UC Table Type** | Gold export (`bi_db`, generic_id 1982) |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_PnL` is the **rolled-up daily P&amp;L facts** table used in **DDR** reporting and **instrument-type / product-mix** attribution. Each row is **one bucket** for a **calendar day** (`DateID` / `Date`), a **real customer** (`RealCID`), an **asset-class** (`InstrumentTypeID` from `Dim_Instrument`), and a fixed set of **position-style flags** (`IsCopy`, `IsSettled`, `IsFuture`, `IsLeveraged`, `IsBuy`, `IsCopyFund`, `IsSQF`).

**Measures**:

- **`NetProfit`**: **`SUM`** of position-level **`NetProfit`** coming from closed positions on that `DateID` inside `Function_PnL_Single_Day` (sourced from **`DWH_dbo.Dim_Position`** where **`dp.CloseDateID = @dateID`** in the TVF).
- **`UnrealizedPnLChange`**: **`SUM`** of the TVF’s **day-over-day unrealized P&amp;L change** from **`BI_DB_PositionPnL`** (full outer join of **prior-day** vs **`@dateID`** snapshots, with the TVF’s **`CASE`** for NULL endpoints — see §2.2 verbatim SQL).
- **`CountPositions`**: number of **position-level rows** from the TVF that fall into each aggregate bucket.

This design keeps **DDR** consumers on a **small, flag-rich aggregate** while the **position- and action-level** detail remains in **`Dim_Position`** and the broad ledger in **`Fact_CustomerAction`** (event grain / `ActionTypeID`).

---

## 2. Business Logic

### 2.1 Load pattern (`SP_DDR_Fact_PnL`)

**What**: Idempotent **daily partition** replace for one `Date`.

**Columns involved**: All columns (full table insert).

**Rules**:

- `DECLARE @dateID int = CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)`
- `DELETE FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL WHERE DateID = @dateID`
- `INSERT ... SELECT ... GROUP BY` keys and aggregates (see §2.3 for verbatim `INSERT`/`SELECT`).

### 2.2 `Function_PnL_Single_Day` — predicates and unrealized change (verbatim excerpts)

**Open / mark-to-market arm (`BI_DB_PositionPnL`)**

- Prior-day snapshot:  
  `WHERE bdppl.DateID = CAST(FORMAT(CAST(DATEADD(DAY,-1, CONVERT(DATE, CONVERT(VARCHAR(8), @dateID), 112)) AS DATE),'yyyyMMdd') as INT)`
- As-of-day snapshot:  
  `WHERE bdppl.DateID = @dateID`
- `FULL OUTER JOIN` the two snapshots **on `PositionID`**, then **`UnrealizedPnLChange`** for the inner row:  
  `CASE WHEN a.UnrealizedPnLStart IS NULL THEN a.UnrealizedPnLEnd WHEN a.UnrealizedPnLEnd IS NULL THEN -1 * a.UnrealizedPnLStart ELSE a.UnrealizedPnLEnd - a.UnrealizedPnLStart END`

**Closed-position arm (`Dim_Position`)**

- `WHERE dp.CloseDateID = @dateID`

**Copy-fund flag**

- `CASE WHEN cpt.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsCopyFund`  
  with `LEFT JOIN BI_DB_dbo.BI_DB_CopyFund_Positions cpt ON ... PositionID`

**Margin-trade flag (position row; not projected to this fact)**

- `CASE WHEN bdppl.SettlementTypeID = 5 THEN 1 ELSE 0 END` / `CASE WHEN dp.SettlementTypeID = 5 THEN 1 ELSE 0 END`

**`IsSQF` on the TVF output**

```sql
, case when sqf.InstrumentID is not null then 1 else 0 end as IsSQF
FROM FINAL f
	left JOIN 
		(
		SELECT InstrumentID FROM BI_DB_dbo.Function_Instrument_Snapshot_Enriched(@dateID) WHERE IsSQF = 1 
		) sqf
			ON f.InstrumentID = sqf.InstrumentID
```

**`Function_Instrument_Snapshot_Enriched` — group 59 (technical source for `IsSQF=1` on the function)**

```sql
FROM DWH_staging.etoro_Trade_InstrumentGroups etig
	WHERE etig.GroupID = 59
```

Then `CASE WHEN adj.InstrumentID IS NOT NULL THEN 1 ELSE 0 END AS IsSQF` joined to the instrument snapshot (`Function_Instrument_Snapshot_Enriched.sql`).

### 2.3 `SP_DDR_Fact_PnL` — verbatim `INSERT`/`SELECT` core

```sql
INSERT INTO BI_DB_dbo.BI_DB_DDR_Fact_PnL (
		DateID,
		[Date],
		RealCID,
		InstrumentTypeID,
		IsCopy,
		IsSettled,
		UnrealizedPnLChange,
		NetProfit,
		CountPositions,
		UpdateDate,
		IsFuture,
		IsLeveraged,
		IsBuy,
		IsCopyFund,
		IsSQF
	) 

SELECT
	frfc.DateID
  , @date AS [Date]
  , frfc.CID AS RealCID
  , di.InstrumentTypeID
  , CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END AS IsCopy
  , frfc.IsSettled
  , sum(frfc.UnrealizedPnLChange) AS  UnrealizedPnLChange
  , sum(frfc.NetProfit) AS  NetProfit
  , count(frfc.PositionID) AS CountPositions
  , getdate () AS UpdateDate
  , ISNULL(frfc.IsFuture,0)
  , CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END AS IsLeveraged
  , frfc.IsBuy
  , ISNULL(frfc.IsCopyFund,0)
  , ISNULL(frfc.IsSQF,0)
FROM BI_DB_dbo.Function_PnL_Single_Day (@dateID) frfc
JOIN DWH_dbo.Dim_Instrument di
	ON frfc.InstrumentID = di.InstrumentID
GROUP BY 
	frfc.DateID
  ,frfc.CID
  , di.InstrumentTypeID
  , CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END 
  , frfc.IsSettled
  , ISNULL(frfc.IsFuture,0)
  , CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END 
  , frfc.IsBuy
  , ISNULL(frfc.IsCopyFund,0)
  , ISNULL(frfc.IsSQF,0)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**`HASH(RealCID)`**: Favors **customer-scoped** DDR joins (`RealCID` predicates). Large **instrument-wide** scans **without** `RealCID` can shuffle.

**Columnstore**: Good for **aggregate** reporting; always filter **`DateID`** (and ideally **`RealCID`** / **`InstrumentTypeID`**) to limit scans on **billions** of rows.

### 3.2 Common Query Patterns

| Analyst question | Recommended approach |
|------------------|---------------------|
| Daily P&amp;L by customer | `WHERE DateID = @d AND RealCID = @c` |
| Crypto vs stocks mix | `JOIN Dim_Instrument` optional — `InstrumentTypeID` already here (use `Dim_Instrument` wiki for **1–10** meanings) |
| Copy vs manual | `WHERE IsCopy = 1` vs `0` |
| SQF futures bucket | `WHERE IsSQF = 1` (**SpotQuotedFuture** — see §4) |

### 3.3 Common JOINs

| Join to | Join condition | Purpose |
|---------|----------------|---------|
| `DWH_dbo.Dim_Customer` | `dc.RealCID = pnl.RealCID` | Customer attributes (**PII** governance) |
| `DWH_dbo.Dim_Instrument` | `di.InstrumentTypeID = pnl.InstrumentTypeID` | **Not** a singleton row — use for **labels** at type grain only |
| `DWH_dbo.Dim_Date` | `dd.DateID = pnl.DateID` | Calendar |

### 3.4 Gotchas

- **Always filter `DateID`** — full-table scans are **prohibitively expensive**.
- **Aggregate grain** — you **cannot** reconstruct individual **`PositionID`** rows from this table; use **`Dim_Position`** / TVF outputs for position detail.
- **`IsSettled`** is **Tier 5** in `Dim_Position`; do not over-interpret without product sign-off.
- **UC `etr_*`** columns exist for Databricks partitioning — not in Synapse DDL (15 physical columns in Synapse).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Grounded in **`Trade.*` / `Customer.*`** via **`Dim_*` / `Fact_CustomerAction`** inheritance |
| **Tier 2** | **ETL- or TVF-derived** (including **`SUM`/`COUNT`**, calendar keys, flags from **`CASE`**) |
| **Tier 5** | **Expert / correction** — disputed or corrected semantics |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Calendar key in **`YYYYMMDD`** integer form. Matches the TVF’s `DateID` and the SP’s **`@dateID`**. (Tier 2 — Function_PnL_Single_Day) |
| 2 | Date | date | YES | Calendar **`date`** for the load: **`@date AS [Date]`** in `SP_DDR_Fact_PnL`. (Tier 2 — SP_DDR_Fact_PnL) |
| 3 | RealCID | int | YES | Real-account Customer ID. HASH distribution key. References **`Dim_Customer.RealCID`**. Each customer has one real CID. BI_DB transform: column name **`RealCID`**; TVF source column is **`CID`** (same semantics as **`Dim_Position.CID`**). (Tier 1 — Customer.CustomerStatic) |
| 4 | InstrumentTypeID | int | YES | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. Join-enriched via **`Dim_Instrument`** in **`SP_DDR_Fact_PnL`**. (Tier 1 — Trade.GetInstrument) |
| 5 | IsCopy | int | YES | **`CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END`**. **1** = copy-trade child path (see **`MirrorID`** semantics in `Dim_Position`). (Tier 2 — SP_DDR_Fact_PnL) |
| 6 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 7 | UnrealizedPnLChange | decimal(16,6) | YES | **`SUM(frfc.UnrealizedPnLChange)`** from **`Function_PnL_Single_Day`**, where per-position change comes from **`BI_DB_PositionPnL`** prior vs current snapshot **`CASE`** (`UnrealizedPnLEnd - UnrealizedPnLStart` with NULL guards). (Tier 2 — BI_DB_PositionPnL) |
| 8 | NetProfit | decimal(16,6) | YES | **`SUM(frfc.NetProfit)`** over the group. Base measure: Realized PnL. 0 when open; set on close. In position currency. (Tier 2 — Trade.PositionTbl) |
| 9 | CountPositions | int | YES | **`COUNT(frfc.PositionID)`** — count of TVF position rows in each aggregate bucket. (Tier 2 — SP_DDR_Fact_PnL) |
| 10 | UpdateDate | datetime | YES | ETL load timestamp: **`GETDATE()`** at SP run. (Tier 2 — SP_DDR_Fact_PnL) |
| 11 | IsFuture | int | YES | 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. **`ISNULL(frfc.IsFuture,0)`** in SP. (Tier 2 — SP_Dim_Instrument) |
| 12 | IsLeveraged | int | YES | **`CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END`**. Derived from position **Leverage**: Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 2 — Trade.PositionTbl) |
| 13 | IsBuy | int | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. DWH note: **`bit`** in **`Dim_Position`**; here **int** from TVF/Synapse path. (Tier 1 — Trade.PositionTbl) |
| 14 | IsCopyFund | int | YES | Smart Portfolio / Fund position flag from TVF: **`CASE WHEN cpt.PositionID IS NOT NULL THEN 1 ELSE 0 END`** with **`LEFT JOIN BI_DB_CopyFund_Positions`**. **`ISNULL(...,0)`** in SP. (Tier 2 — Function_PnL_Single_Day) |
| 15 | IsSQF | int | YES | **`IsSQF` (SpotQuotedFuture flag) — 1 = instrument is a SpotQuotedFuture (smaller-contract variant of eToro RealFutures, traded on the CME / Chicago Mercantile Exchange). 0 = not an SQF instrument. Source: **`Function_Instrument_Snapshot_Enriched(@dateInt)`** via membership in **`Trade.InstrumentGroups`** with **`GroupID = 59`**. **`ISNULL(frfc.IsSQF, 0)`** per SP. (Tier 5 — user expert correction; previously mis-described as "Sustainable & Quality-Focused") |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse column | Production / DWH source | Source column | Transform |
|----------------|-------------------------|---------------|-----------|
| DateID | Calendar / TVF | `@dateID` | passthrough / key |
| Date | SP parameter | `@date` | cast |
| RealCID | `Trade.PositionTbl` lineage | `CID` | rename to `RealCID` |
| InstrumentTypeID | `Trade.GetInstrument` / IMD | `InstrumentTypeID` | join in SP |
| IsCopy | `Trade.PositionTbl` | `MirrorID` | `CASE WHEN >0` |
| IsSettled | `Trade.PositionTbl` | `IsSettled` | passthrough via TVF |
| UnrealizedPnLChange | `BI_DB_PositionPnL` | `PositionPnL` snapshots | TVF `CASE` deltas; **`SUM`** |
| NetProfit | `Trade.PositionTbl` | `NetProfit` | **`SUM`** |
| CountPositions | Internal | `PositionID` | **`COUNT`** |
| UpdateDate | Synapse | runtime | `GETDATE()` |
| IsFuture | `Trade.InstrumentGroups` | GroupID=25 | via `Dim_Instrument` in TVF |
| IsLeveraged | `Trade.PositionTbl` | `Leverage` | `CASE >1` |
| IsBuy | `Trade.PositionTbl` | `IsBuy` | passthrough |
| IsCopyFund | `BI_DB_CopyFund_Positions` | membership | TVF `CASE` |
| IsSQF | `Trade.InstrumentGroups` via staging | GroupID=59 | `Function_Instrument_Snapshot_Enriched` + TVF `CASE` |

### 5.2 ETL Pipeline

```
etoro.Trade.* / etoro.History.*  (positions, closes, instrument groups)
         |-- Generic Pipeline → Lake / staging → DWH_dbo.Dim_Position, Dim_Instrument,
         |                      BI_DB_PositionPnL, DWH_staging.etoro_Trade_InstrumentGroups ---|
         v
BI_DB_dbo.Function_PnL_Single_Day(@dateID)
         |-- BI_DB_dbo.SP_DDR_Fact_PnL (@date) ---|
         v
BI_DB_dbo.BI_DB_DDR_Fact_PnL  (HASH RealCID; ~9B rows)
         |-- Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_DDR_Fact_PnL/ (Append, daily) ---|
         v
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl  (+ etr_* partitions)
```

```
UPSTREAM SEARCH LOG — BI_DB_DDR_Fact_PnL:
  Lineage source objects (from .lineage.md):
    1. BI_DB_dbo.Function_PnL_Single_Day (role: primary TVF grain)
    2. DWH_dbo.Dim_Instrument (role: join lookup / InstrumentTypeID)
    3. BI_DB_dbo.SP_DDR_Fact_PnL (role: writer SP)
  For each source:
    Function_PnL_Single_Day
      (a) Local wiki: knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md → FOUND
          Read tool issued: YES
      (b) Production wiki: SSDT Function_PnL_Single_Day.sql → FOUND
          Read tool issued: YES
      Effective upstream: TVF SQL + Fact_CustomerAction.md / Dim_Position.md for position semantics
    Dim_Instrument
      (a) Local wiki: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md → FOUND
          Read tool issued: YES
      (b) Production wiki: DB_Schema routing (etoro) → skipped (local covered InstrumentTypeID / IsFuture)
      Effective upstream: Dim_Instrument.md
    SP_DDR_Fact_PnL
      (a) SSDT: DataPlatform/.../BI_DB_dbo.SP_DDR_Fact_PnL.sql → FOUND
          Read tool issued: YES
      Effective upstream: SSDT SP file
  Columns expected to inherit Tier 1 from each source:
    Fact_CustomerAction / Dim_Customer: RealCID → 1 column
    Dim_Instrument: InstrumentTypeID → 1 column
    Dim_Position: IsBuy (+ leverage narrative) → blended Tiering on aggregates
  Tier-1-eligible columns identified: 3 strict (RealCID, InstrumentTypeID, IsBuy)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related object | Description |
|---------|----------------|-------------|
| InstrumentTypeID | `DWH_dbo.Dim_Instrument` | Asset-class key (**type grain**, not `InstrumentID`) |
| RealCID | `DWH_dbo.Dim_Customer` | Customer dimension (**PII**) |

### 6.2 Referenced By (other objects point to this)

DDR consumers (dashboards, Genie spaces) — see **Atlassian** PRD link in §8.

---

## 7. Sample Queries

### 7.1 Daily customer P&amp;L buckets

```sql
SELECT DateID, RealCID, InstrumentTypeID,
       SUM(UnrealizedPnLChange) AS u_pnl,
       SUM(NetProfit) AS r_pnl,
       SUM(CountPositions) AS pos
FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL
WHERE DateID = 20260426
  AND RealCID = 6867448
GROUP BY DateID, RealCID, InstrumentTypeID
ORDER BY InstrumentTypeID;
```

### 7.2 SQF vs non-SQF notional count of positions (day slice)

```sql
SELECT IsSQF,
       SUM(CountPositions) AS positions,
       SUM(NetProfit) AS net_profit,
       SUM(UnrealizedPnLChange) AS unreal_change
FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL
WHERE DateID >= 20260101
GROUP BY IsSQF;
```

---

## 8. Atlassian Knowledge Sources

| Title | URL | Note |
|-------|-----|------|
| PRD: Genie Space Source – eToro PnL | https://etoro-jira.atlassian.net/wiki/spaces/BIA/pages/14154727425/PRD+Genie+Space+Source+eToro+PnL | Names **`BI_DB_dbo.BI_DB_DDR_Fact_PnL`** as Genie / P&amp;L source |
| DDR Tables | https://etoro-jira.atlassian.net/wiki/spaces/~164971827/pages/13596884995/DDR+Tables | Overview of DDR **BI_DB** tables |

---

*Generated: 2026-05-14 | Quality: 8.5/10 | Phases: execution card + P1–P16 notes in deliverables*  
*Tiers: 3 T1, 10 T2, 0 T3, 0 T4, 2 T5 | Elements: 15/15 | Synapse DDL columns: 15 | Logic: 9/10 | Sampling: PASS (TOP 5 + COUNT_BIG)*  
*Object: BI_DB_dbo.BI_DB_DDR_Fact_PnL | Type: Table | Production Source: Dim_Position + BI_DB_PositionPnL + Dim_Instrument + InstrumentGroups (via Function_Instrument_Snapshot_Enriched)*  
