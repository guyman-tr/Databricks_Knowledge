# BI_DB_dbo.BI_DB_Capital_Adequacy_Daily_NOP_KASA

> Daily K-ASA (Net Open Position) capital adequacy snapshot for real CFD instruments: NOP aggregated by Regulation × Player_Status × MiFID II categorization × InstrumentType × position type. Covers all regulated jurisdictions. Sibling to BI_DB_Capital_Adequacy_Daily_Equity (K-CMH) and Monthly_NOP (K-AUM).

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Row Count | ~1,339,958 |
| Date Range | 2020-01-01 → 2026-04-12 |
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED INDEX (Date ASC) |
| Writer SP | SP_Risk_Capital_Adequacy |
| ETL Pattern | DELETE WHERE Date=@Date + INSERT |
| UC Target | _Not_Migrated |

## 1. Business Meaning

`BI_DB_Capital_Adequacy_Daily_NOP_KASA` tracks the daily **Net Open Position (NOP)** for real CFD instruments, broken down by Regulation, Player_Status, MiFID II categorization, InstrumentType, Manual_Copy classification, and IsFuture. This feeds into the **K-ASA (capital metric for net open positions)** used in regulatory capital adequacy reporting.

NOP represents the net directional exposure of the firm against client positions. A firm running a book model (hedging) must maintain capital proportional to its net open position across asset classes and regulations. This table provides the granular daily NOP data for that calculation.

The SP filter `Real_CFD = 'Real'` restricts this table to real CFD instrument positions, excluding synthetic or copy-trade instruments that have different capital treatment. The sibling table `BI_DB_Capital_Adequacy_Monthly_NOP` captures copy/social-trading positions (Manual_Copy='Copy') at monthly granularity.

**Row count note**: At ~1.34M rows (vs 493K for Daily_Equity), the higher cardinality reflects the additional InstrumentType and Manual_Copy dimensions in this table.

**Historical note**: Date range starts 2020-01-01, but UpdateDate begins 2022-02-23 — rows before that date represent a historical backfill performed at table creation.

## 2. Business Logic

### 2.1 Real CFD Filter
The SP filters output to `Real_CFD = 'Real'` from Dim_Instrument. This excludes positions on non-real (copy/synthetic) instruments. The Real_CFD column in this table will therefore always contain the value `'Real'`, though it is included as a dimension column for completeness and joining purposes.

### 2.2 NOP Computation
Position-level P&L data from `BI_DB_PositionPnL` is joined to `Dim_Instrument` and `Fact_SnapshotCustomer`, then aggregated through `#capitaldata_cid` → `#capitaldata`. The aggregated NOP (Total_NOP) represents the net open position in monetary terms. Values can be positive (net long) or negative (net short).

### 2.3 Dimension Granularity
The output is more granular than Daily_Equity because it adds InstrumentType and Manual_Copy as segmentation dimensions. This allows capital reporting teams to decompose NOP by asset class (Currencies, Indices, Stocks, ETF, Crypto Currencies) and by trade type (manual vs copy-trading instrument).

### 2.4 Regulation and Player_Status Snapshot Semantics
Both Regulation and Player_Status reflect the customer's status **at ETL run time** (Fact_SnapshotCustomer snapshot), not at any historical date.

## 3. Query Advisory

**Typical use**: Aggregate Total_NOP by Regulation and InstrumentType for a given Date to produce regulatory NOP reports.

```sql
-- Daily NOP by Regulation and InstrumentType
SELECT Date, Regulation, InstrumentType,
       SUM(Total_NOP) AS Net_Open_Position
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_NOP_KASA]
WHERE Date = '2026-04-12'
GROUP BY Date, Regulation, InstrumentType
ORDER BY Regulation, InstrumentType;
```

**Distribution**: ROUND_ROBIN — no skew risk; no partition elimination. Filter on Date (CLUSTERED INDEX) for time-range queries.

**Gotchas**:
- `Real_CFD = 'Real'` for every row in this table — do not use this column to distinguish real vs non-real (all rows are already filtered). The column exists as a dimension for joining/reporting alignment.
- `Total_NOP` may be negative (net short). Summing without sign awareness will understate absolute NOP exposure.
- `Manual_Copy` segments the NOP into manual-entry vs copy-trade instruments within the real CFD universe. Summing across Manual_Copy values gives the total real CFD NOP.
- `EOM_Date = EOMONTH(Date)` — identical for all rows in the same calendar month.

## 4. Elements

| # | Column | Data Type | Nullable | Description |
|---|--------|-----------|----------|-------------|
| 1 | EOM_Date | date | YES | End-of-month date computed as EOMONTH(@date). Identical for all rows within the same calendar month. Used to align daily NOP rows with monthly capital adequacy reports. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 2 | Date | date | YES | ETL run date (the @date parameter passed to SP_Risk_Capital_Adequacy). Each daily run deletes and re-inserts all rows for this date. Primary time-series key. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 3 | Manual_Copy | varchar(6) | NO | Instrument classification from Dim_Instrument indicating whether the position is a manually-entered trade or a copy/social-trading instrument. Observed values include 'Manual' and 'Copy' (or similar). (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 4 | Real_CFD | varchar(4) | NO | Instrument type flag from Dim_Instrument. Always 'Real' in this table — SP filters output to Real_CFD='Real'. Column retained as a dimension for reporting alignment with sibling tables. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 5 | InstrumentType | varchar(50) | NO | Instrument category from Dim_Instrument. Observed values: Currencies, Indices, Stocks, ETF, Crypto Currencies. The primary asset-class dimension for NOP decomposition. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 6 | Regulation | varchar(50) | YES | Regulatory framework name resolved from Dim_Regulation via Fact_SnapshotCustomer.RegulationID. Snapshot at ETL run time — not historical. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 7 | Player_Status | varchar(50) | YES | Player status label resolved from Dim_PlayerStatus via Fact_SnapshotCustomer.PlayerStatusID. Reflects customer account status at ETL run time. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 8 | MifidCategorization | varchar(50) | YES | MiFID II investor category from Fact_SnapshotCustomer (Retail, Professional, or Eligible Counterparty). Determines capital treatment. Snapshot at ETL run time. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 9 | Total_NOP | money | YES | Net Open Position in monetary terms, aggregated from BI_DB_PositionPnL via #capitaldata. Positive = net long; negative = net short. The primary K-ASA capital metric for real CFD NOP exposure. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 10 | UpdateDate | datetime | NO | ETL run timestamp (GETDATE() at SP execution). Rows with Date < 2022-02-23 carry UpdateDate = 2022-02-23 (historical backfill at table creation); rows from 2022-02-23 onward carry live execution timestamps. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 11 | IsFuture | int | YES | Instrument futures flag from Dim_Instrument: 1=futures instrument, 0=spot CFD. NULL possible where instrument metadata is absent. Allows decomposition of NOP into futures vs spot segments for regulatory capital treatment. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |

## 5. Lineage

See [`BI_DB_Capital_Adequacy_Daily_NOP_KASA.lineage.md`](BI_DB_Capital_Adequacy_Daily_NOP_KASA.lineage.md) for full ETL diagram and column-level lineage.

**Key sources**: BI_DB_PositionPnL (NOP computation), Dim_Instrument (InstrumentType, Real_CFD, Manual_Copy, IsFuture), Fact_SnapshotCustomer (customer attributes), Dim_Regulation, Dim_PlayerStatus.

## 6. Relationships

| Related Object | Relationship | Join Key |
|---------------|-------------|----------|
| SP_Risk_Capital_Adequacy | Writer SP | — |
| BI_DB_Capital_Adequacy_Daily_Equity | Sibling table | Same SP, same date grain; K-CMH metric (unrealized equity) |
| BI_DB_Capital_Adequacy_Monthly_NOP | Sibling table | Same SP, monthly grain; K-AUM metric (copy positions) |
| BI_DB_PositionPnL | Source | CID / InstrumentID — open position P&L |
| Dim_Instrument | Source | InstrumentID — InstrumentType, Real_CFD, Manual_Copy, IsFuture |
| Fact_SnapshotCustomer | Source | CID — daily customer snapshot |
| Dim_Regulation | Source | RegulationID — name resolver |
| Dim_PlayerStatus | Source | PlayerStatusID — name resolver |

## 7. Sample Queries

```sql
-- NOP by InstrumentType and Regulation for a given date
SELECT Date, Regulation, InstrumentType,
       SUM(Total_NOP) AS Net_Open_Position
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_NOP_KASA]
WHERE Date = '2026-04-12'
GROUP BY Date, Regulation, InstrumentType
ORDER BY Regulation, InstrumentType;

-- Absolute NOP exposure by asset class (ignoring direction)
SELECT Date, InstrumentType,
       SUM(ABS(Total_NOP)) AS Absolute_NOP
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_NOP_KASA]
WHERE Date = '2026-04-12'
GROUP BY Date, InstrumentType
ORDER BY Absolute_NOP DESC;

-- Futures vs spot NOP breakdown
SELECT Date, IsFuture,
       SUM(Total_NOP) AS Net_Open_Position
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_NOP_KASA]
WHERE Date = '2026-04-12'
GROUP BY Date, IsFuture
ORDER BY IsFuture;
```

## 8. Atlassian

No Atlassian/Confluence sources were queried for this object. MCP Atlassian search not available in this session.

---
*Generated: 2026-04-21 | Quality: 8.7/10 | Phases: 14/14*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4 | Elements: 11/11 documented*
*Writer SP: SP_Risk_Capital_Adequacy | UC: _Not_Migrated*
