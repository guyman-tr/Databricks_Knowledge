# BI_DB_dbo.BI_DB_Investors_STG

> ~9.5M-row daily staging table holding per-CID investor activity detail across three streams — Manual (direct positions), Copy (mirror-based trading), and Balance (uninvested cash) — populated by SP_InvestorReport and consumed by SP_InvestorReport_Cluster to produce the aggregated BI_DB_Investors and BI_DB_Investors_Unclustered report tables.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Staging) |
| **Production Source** | Derived — DWH dimensions/facts aggregated by SP_InvestorReport |
| **Refresh** | Daily truncate-and-reload within SP_InvestorReport (SB_Daily) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_Investors_STG` is the CID-level staging table for the investor activity reporting pipeline. It holds one row per customer per activity dimension (ActionType × InstrumentType × AssetType) for a single business date. The table is TRUNCATED at the start of each `SP_InvestorReport` run and rebuilt from scratch with three INSERT streams:

1. **Manual** — Direct (non-copy) position activity. Open/close trades from `Fact_CustomerAction` (ActionTypeID 1=Open, 4=Close). AUA from `BI_DB_PositionPnL` (Amount + PositionPnL for non-mirror positions).
2. **Copy** — Mirror-based copy-trading activity from `Dim_Mirror` + `Fact_CustomerAction` (ActionTypeID 15-18). AUM from `etoroGeneral_History_GuruCopiers` (Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL).
3. **Balance** — Uninvested cash credit from `V_Liabilities`. NetMI = today's Credit minus yesterday's Credit.

Only valid depositing customers are included (Fact_SnapshotCustomer.IsValidCustomer = 1 AND IsDepositor = 1, filtered via Dim_Range date boundaries).

After the three INSERTs complete, `SP_InvestorReport` reads the STG table to aggregate into `BI_DB_Investors_Unclustered`. Then `SP_InvestorReport_Cluster` reads the STG table, joins `BI_DB_CID_DailyCluster` for ClusterSF, and aggregates into `BI_DB_Investors`. The STG table is transient — it holds data for exactly one date at a time and is truncated on each run.

As of 2026-04-25 (most recent load): ~9.5M rows — Balance: 5,875,751 (61.9%), Manual: 3,299,576 (34.8%), Copy: 319,121 (3.4%).

---

## 2. Business Logic

### 2.1 Three Source Streams

**What**: Activity is segmented into three mutually exclusive streams that are loaded via separate INSERT statements.

**Columns Involved**: `SourceTable`, `ActionType`

**Rules**:
- **Manual**: Direct position open/close. SourceTable = 'Manual', ActionType = 'Manual'. Sources: Fact_CustomerAction (ActionTypeID IN 1, 4) joined with Dim_Position (leverage), Dim_Instrument (type), BI_DB_PositionPnL (AUA for open positions with MirrorID = 0).
- **Copy**: Copy-trading mirror activity. SourceTable = 'Copy', ActionType = 'Copy'. Sources: Dim_Mirror (active mirrors), Fact_CustomerAction (ActionTypeID IN 15, 16, 17, 18 for mirror operations), etoroGeneral_History_GuruCopiers (AUM).
- **Balance**: Uninvested cash. SourceTable = 'Balance', ActionType = 'Balance'. Source: V_Liabilities (today's Credit vs yesterday's Credit).

### 2.2 AssetType Classification

**What**: Classifies activity into investment style categories.

**Columns Involved**: `AssetType`, `InstrumentTypeID` (from Dim_Instrument), `Leverage` (from Dim_Position)

**Rules**:
- `'Investment'`: InstrumentTypeID IN (4, 5, 6) AND Leverage < 3 — long-term, low-leverage stock/ETF/index holding
- `'Trade'`: All other manual positions — short-term or leveraged
- `'Copy'`: All copy-trading activity (Copy stream)
- `'NonInvested'`: Balance stream (uninvested cash credit)

### 2.3 InstrumentType Classification

**What**: Labels the instrument category or copy product type.

**Columns Involved**: `InstrumentType`, `MirrorTypeID` (from Dim_Mirror)

**Rules**:
- **Manual stream**: Passthrough from Dim_Instrument.InstrumentType (Stocks, ETF, Crypto Currencies, Commodities, Indices, Currencies)
- **Copy stream**: MirrorTypeID IN (1, 2) → 'Copy Trading'; other MirrorTypeID → 'Copy Portfolio'
- **Balance stream**: Literal 'Balance'

### 2.4 Customer Validity Filter

**What**: Only valid depositing customers are included across all streams.

**Columns Involved**: All rows filtered

**Rules**:
- Fact_SnapshotCustomer.IsValidCustomer = 1
- Fact_SnapshotCustomer.IsDepositor = 1
- Dim_Range boundary: FromDateID <= @ddINT AND ToDateID >= @ddINT (current SCD2 row)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) with CLUSTERED INDEX on CID ASC. JOINs on CID are co-located. The table is transient staging — it holds only one date's data at any time.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Check current staging data | `SELECT TOP 10 * FROM BI_DB_dbo.BI_DB_Investors_STG` |
| Stream breakdown | `SELECT SourceTable, COUNT(*) FROM ... GROUP BY SourceTable` |
| Customer detail for debugging | `WHERE CID = @cid` (HASH-optimized) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_CID_DailyCluster | ON CID, DateID range | Add ClusterSF for clustered aggregation (SP_InvestorReport_Cluster) |
| DWH_dbo.Dim_Country | ON CountryID | Country name |
| DWH_dbo.Dim_Regulation | ON RegulationID | Regulation name |
| DWH_dbo.Dim_Manager | ON AccountManagerID = ManagerID | Account manager name |

### 3.4 Gotchas

- **Transient staging table**: Data is TRUNCATED at the start of each SP_InvestorReport run. Only holds one date's data. Do not rely on this table for historical analysis — use BI_DB_Investors_Unclustered or BI_DB_Investors instead.
- **SourceTable vs ActionType**: Both columns carry the same literal values ('Manual', 'Copy', 'Balance'). SourceTable identifies the INSERT stream; ActionType is the business-facing label. They are always identical.
- **NetMI naming**: The column is named "NetMI" (Net Money Invested) in the STG table but becomes "Amount" in the downstream BI_DB_Investors_Unclustered table. The naming mismatch can be confusing.
- **AUA dual meaning**: AUA represents Assets Under Administration for Manual/Balance streams (position value or cash credit) and Assets Under Management for Copy stream (mirror portfolio value). The semantic distinction is collapsed into one column.
- **AUA can be NULL**: 161 rows (out of ~9.5M) have NULL AUA, likely Copy stream rows where no GuruCopiers match was found. Use ISNULL when aggregating.
- **Balance Customers = COUNT(CID) not COUNT(DISTINCT CID)**: The Manual and Copy streams use COUNT(DISTINCT CID), but the Balance stream uses COUNT(CID). This can cause inconsistencies in downstream Customers aggregations if a CID appears in multiple balance rows.
- **~9.5M rows is single-date**: The row count reflects one day's staging. Historical data does not accumulate.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Passthrough from upstream wiki — description copied verbatim from documented source table |
| Tier 2 | ETL-computed or multi-source passthrough in SP_InvestorReport |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | SourceTable | varchar(50) | NO | Identifies which INSERT stream produced this row: 'Manual' (direct position activity), 'Copy' (mirror-based copy trading), or 'Balance' (uninvested cash credit). Always matches ActionType. (Tier 2 — SP_InvestorReport) |
| 2 | Date | date | YES | Business date for this daily snapshot. Set from SP parameter @dd. (Tier 2 — SP_InvestorReport) |
| 3 | DateID | int | YES | Date as YYYYMMDD integer. Derived as CONVERT(CHAR(8), @dd, 112). Used for delete-insert partitioning in downstream tables. (Tier 2 — SP_InvestorReport) |
| 4 | CID | int | YES | Customer ID. Manual stream: Fact_CustomerAction.RealCID. Copy stream: Dim_Mirror.CID. Balance stream: V_Liabilities.CID. HASH distribution key. (Tier 2 — Fact_CustomerAction / Dim_Mirror / V_Liabilities) |
| 5 | AccountManagerID | int | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 1 — Fact_SnapshotCustomer) |
| 6 | CountryID | int | YES | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 1 — Fact_SnapshotCustomer) |
| 7 | RegulationID | tinyint | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. FK to Dim_Regulation. (Tier 1 — Fact_SnapshotCustomer) |
| 8 | ActionType | varchar(255) | NO | Activity source stream label: 'Manual' (direct position open/close), 'Copy' (copy-trading mirror activity), 'Balance' (uninvested cash). Always matches SourceTable. (Tier 2 — SP_InvestorReport) |
| 9 | AssetType | varchar(255) | YES | Investment classification. 'Investment' (InstrumentTypeID IN (4,5,6) AND Leverage < 3), 'Trade' (all other manual positions), 'Copy' (copy stream), 'NonInvested' (balance stream). (Tier 2 — Dim_Instrument / Dim_Position) |
| 10 | InstrumentType | varchar(255) | YES | Instrument category. Manual stream: from Dim_Instrument.InstrumentType (Stocks, ETF, Crypto Currencies, Commodities, Indices, Currencies). Copy stream: 'Copy Trading' (MirrorTypeID IN (1,2)) or 'Copy Portfolio' (other). Balance stream: 'Balance'. (Tier 2 — Dim_Instrument / Dim_Mirror) |
| 11 | NetMI | decimal(38,2) | YES | Net money invested in USD. Manual: SUM(-1 * Fact_CustomerAction.Amount). Copy: SUM(Fact_CustomerAction.Amount * -1) for mirror actions (ActionTypeID 15-18). Balance: ISNULL(today V_Liabilities.Credit, 0) - ISNULL(yesterday Credit, 0). Named "Amount" in downstream BI_DB_Investors_Unclustered. (Tier 2 — Fact_CustomerAction / V_Liabilities) |
| 12 | AUA | decimal(38,4) | YES | Assets under management/administration in USD. Manual: SUM(BI_DB_PositionPnL.Amount + PositionPnL) for non-mirror positions (MirrorID = 0). Copy: SUM(etoroGeneral_History_GuruCopiers Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL). Balance: V_Liabilities.Credit. 161 NULLs observed in recent data. Named "AUM_AUA" in downstream BI_DB_Investors_Unclustered. (Tier 2 — BI_DB_PositionPnL / etoroGeneral_History_GuruCopiers / V_Liabilities) |
| 13 | UpdateDate | datetime | NO | ETL timestamp. Set to GETDATE() at insert time. (Tier 2 — SP_InvestorReport) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object(s) | Source Column(s) | Transform |
|---------------|-----------------|-----------------|-----------|
| SourceTable | SP_InvestorReport | — | Literal: 'Manual', 'Copy', or 'Balance' |
| Date | SP parameter | @dd | Direct assignment |
| DateID | SP parameter | @dd | CONVERT(CHAR(8), @dd, 112) |
| CID | Fact_CustomerAction / Dim_Mirror / V_Liabilities | RealCID / CID / CID | Passthrough per stream |
| AccountManagerID | Fact_SnapshotCustomer | AccountManagerID | Passthrough |
| CountryID | Fact_SnapshotCustomer | CountryID | Passthrough |
| RegulationID | Fact_SnapshotCustomer | RegulationID | Passthrough |
| ActionType | SP_InvestorReport | — | Literal: 'Manual', 'Copy', or 'Balance' |
| AssetType | SP_InvestorReport | InstrumentTypeID + Leverage | CASE classification |
| InstrumentType | Dim_Instrument / Dim_Mirror | InstrumentType / MirrorTypeID | Passthrough or CASE per stream |
| NetMI | Fact_CustomerAction / V_Liabilities | Amount / Credit | SUM(-1 * Amount) or credit delta |
| AUA | BI_DB_PositionPnL / etoroGeneral_History_GuruCopiers / V_Liabilities | Amount+PositionPnL / Cash+Investment+PnL+... / Credit | Multi-source SUM per stream |
| UpdateDate | SP_InvestorReport | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (position open/close, mirror actions)
DWH_dbo.Dim_Instrument (InstrumentType classification)
DWH_dbo.Dim_Position (Leverage for AssetType)
DWH_dbo.Fact_SnapshotCustomer (AM, Country, Regulation, validity)
DWH_dbo.Dim_Range (SCD2 date boundary filter)
DWH_dbo.Dim_Manager (AccountManagerID JOIN filter)
DWH_dbo.Dim_Mirror (active copy relationships)
BI_DB_dbo.BI_DB_PositionPnL (manual position AUA)
general.etoroGeneral_History_GuruCopiers (copy AUM)
DWH_dbo.V_Liabilities (balance credit)
  |-- SP_InvestorReport @dd (daily) -------------------------|
  |   Step 1: TRUNCATE BI_DB_Investors_STG                    |
  |   Step 2: Build #leverage, #fca, #openClose temp tables   |
  |   Step 3: #ManNetMI + #AUA → #manual (FULL OUTER JOIN)    |
  |   Step 4: INSERT STG (Manual stream)                      |
  |   Step 5: #ActiveMirror + #CopyType + #AUM               |
  |   Step 6: INSERT STG (Copy stream)                        |
  |   Step 7: INSERT STG (Balance stream from V_Liabilities)  |
  v
BI_DB_dbo.BI_DB_Investors_STG (~9.5M rows, single date)
  |-- SP_InvestorReport (same SP, continues) ----------------|
  |   Aggregates STG → BI_DB_Investors_Unclustered            |
  |-- SP_InvestorReport_Cluster @dd (daily) -----------------|
  |   JOINs STG + BI_DB_CID_DailyCluster → BI_DB_Investors   |
  v
BI_DB_dbo.BI_DB_Investors_Unclustered (aggregated, no cluster)
BI_DB_dbo.BI_DB_Investors (aggregated, with ClusterSF)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountManagerID | DWH_dbo.Dim_Manager | Account manager details |
| CountryID | DWH_dbo.Dim_Country | Country name |
| RegulationID | DWH_dbo.Dim_Regulation | Regulation name |

### 6.2 Referenced By (other objects point to this)

| Source Object | Type | Description |
|--------------|------|-------------|
| BI_DB_dbo.SP_InvestorReport | SP | Writer: TRUNCATE + 3x INSERT; also reads STG to aggregate into BI_DB_Investors_Unclustered |
| BI_DB_dbo.SP_InvestorReport_Cluster | SP | Reader: JOINs STG with BI_DB_CID_DailyCluster, aggregates into BI_DB_Investors |

---

## 7. Sample Queries

### 7.1 Stream distribution breakdown

```sql
SELECT SourceTable,
       COUNT(*) AS rows,
       COUNT(DISTINCT CID) AS unique_customers,
       SUM(NetMI) AS total_netmi,
       SUM(AUA) AS total_aua
FROM [BI_DB_dbo].[BI_DB_Investors_STG]
GROUP BY SourceTable
ORDER BY rows DESC
```

### 7.2 Top customers by AUA in Manual stream

```sql
SELECT TOP 20
    CID,
    InstrumentType,
    AssetType,
    SUM(AUA) AS total_aua,
    SUM(NetMI) AS net_investment
FROM [BI_DB_dbo].[BI_DB_Investors_STG]
WHERE SourceTable = 'Manual'
GROUP BY CID, InstrumentType, AssetType
ORDER BY total_aua DESC
```

### 7.3 Regulation-level summary

```sql
SELECT RegulationID,
       ActionType,
       COUNT(DISTINCT CID) AS customers,
       SUM(AUA) AS total_aua
FROM [BI_DB_dbo].[BI_DB_Investors_STG]
GROUP BY RegulationID, ActionType
ORDER BY RegulationID, ActionType
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 12/14*
*Tiers: 3 T1, 10 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_Investors_STG | Type: Table (Staging) | Production Source: Derived — DWH dimensions/facts by SP_InvestorReport*
