# BI_DB_dbo.BI_DB_Capital_Adequacy_Monthly_NOP

> Monthly K-AUM (Net Open Position) capital adequacy snapshot for copy/social-trading instruments: NOP aggregated by Regulation × Player_Status × MiFID II categorization × InstrumentType × Real_CFD. Complements Daily_NOP_KASA (real CFD, daily) and Daily_Equity (K-CMH, daily).

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Row Count | ~40,720 |
| Date Range | 2020-01-31 → 2026-04-12 |
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED INDEX (YearMonthID ASC) |
| Writer SP | SP_Risk_Capital_Adequacy |
| ETL Pattern | DELETE WHERE Date=@Date + INSERT |
| UC Target | _Not_Migrated |

## 1. Business Meaning

`BI_DB_Capital_Adequacy_Monthly_NOP` tracks the **Net Open Position (NOP)** for copy/social-trading instruments (`Manual_Copy = 'Copy'`), aggregated at monthly granularity. This feeds into the **K-AUM** (or equivalent monthly capital metric) for positions originating from the firm's copy/social-trading book.

Copy-trading positions represent trades placed by followers replicating a popular investor's portfolio. Their regulatory capital treatment differs from manually-entered positions. This table isolates the NOP of those copy positions, broken down by Regulation, Player_Status, MiFID II categorization, InstrumentType, and Real_CFD flag.

This is the third of three capital adequacy tables written by `SP_Risk_Capital_Adequacy`:
- `BI_DB_Capital_Adequacy_Daily_Equity` — K-CMH (unrealized equity, daily, RegulationID IN(1,2,4,5,10))
- `BI_DB_Capital_Adequacy_Daily_NOP_KASA` — K-ASA (real CFD NOP, daily, Real_CFD='Real')
- **This table** — K-AUM (copy instrument NOP, monthly, Manual_Copy='Copy')

**No IsFuture column**: Unlike the two daily sibling tables, Monthly_NOP does not include an IsFuture dimension. The SP INSERT for this table omits IsFuture, meaning futures vs spot is not tracked in the monthly copy-position report.

**Row count note**: At ~40,720 rows over 6+ years, the compact size reflects monthly grain aggregation (vs daily), combined with the narrower scope of copy instruments only.

**Historical note**: Date range starts 2020-01-31, but UpdateDate begins 2022-02-23 — rows before that date represent a historical backfill at table creation.

## 2. Business Logic

### 2.1 Copy Instrument Filter
The SP filters output to `Manual_Copy = 'Copy'` from Dim_Instrument. This restricts the table to positions on copy/social-trading instruments. The Manual_Copy column in this table will therefore always contain the value `'Copy'`, though it is retained as a dimension for reporting alignment.

### 2.2 Real_CFD Varies
Unlike Daily_NOP_KASA (which filters Real_CFD='Real'), this table does not filter on Real_CFD. Both 'CFD' and 'Real' values appear in Real_CFD, reflecting the range of instrument types within the copy-trading universe.

### 2.3 Monthly Granularity via YearMonthID
The table uses YearMonthID as its cluster key (YYYYMM integer, e.g., 202604). This is the primary query dimension for monthly capital reporting. The CLUSTERED INDEX on YearMonthID (rather than Date as in the daily sibling tables) reflects the monthly grain of this table.

### 2.4 NOP Computation
Same computation path as Daily_NOP_KASA: position P&L from `BI_DB_PositionPnL` is joined to `Dim_Instrument` and `Fact_SnapshotCustomer`, aggregated through `#capitaldata_cid` → `#capitaldata`, then filtered to Manual_Copy='Copy'. Total_NOP may be positive (net long) or negative (net short).

### 2.5 Regulation and Player_Status Snapshot Semantics
Both Regulation and Player_Status reflect the customer's status **at ETL run time** (daily snapshot from Fact_SnapshotCustomer), not at any historical date.

## 3. Query Advisory

**Typical use**: Aggregate Total_NOP by Regulation or InstrumentType for a given YearMonthID to produce monthly copy-position NOP reports.

```sql
-- Monthly copy-position NOP by Regulation and InstrumentType
SELECT YearMonthID, Regulation, InstrumentType,
       SUM(Total_NOP) AS Net_Open_Position
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Monthly_NOP]
WHERE YearMonthID = 202604
GROUP BY YearMonthID, Regulation, InstrumentType
ORDER BY Regulation, InstrumentType;
```

**Index**: CLUSTERED INDEX is on YearMonthID — always filter on YearMonthID for efficient seeks. Filtering on Date alone will not use the clustered index efficiently.

**Gotchas**:
- `Manual_Copy = 'Copy'` for every row — do not use this column to distinguish copy vs manual in this table (all rows are already filtered).
- `Total_NOP` may be negative (net short). Summing without sign awareness understates absolute NOP.
- No `IsFuture` column — unlike the sibling daily tables, futures vs spot is not available here. Cannot decompose copy-position NOP by futures status.
- For a complete NOP picture, combine this table (copy instruments, monthly) with `Daily_NOP_KASA` (real instruments, daily).

## 4. Elements

| # | Column | Data Type | Nullable | Description |
|---|--------|-----------|----------|-------------|
| 1 | EOM_Date | date | YES | End-of-month date computed as EOMONTH(@date). Identical for all rows sharing the same YearMonthID. Used for alignment with month-end capital reporting. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 2 | YearMonthID | int | YES | Year-month identifier computed as YEAR(@date)*100 + MONTH(@date) (e.g., 202604 for April 2026). Primary cluster key and query dimension for monthly grain reporting. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 3 | Date | date | YES | ETL run date (the @date parameter). Each run deletes and re-inserts rows for this date. May not be a month-end date — reflects when the SP was last run for this period. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 4 | Manual_Copy | varchar | YES | Instrument copy-trading flag from Dim_Instrument. Always 'Copy' in this table — SP filters output to Manual_Copy='Copy'. Column retained as a dimension for reporting alignment with sibling tables. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 5 | Real_CFD | varchar | YES | Instrument type flag from Dim_Instrument. Values observed: 'CFD', 'Real'. Unlike Daily_NOP_KASA, this table is not filtered on Real_CFD — both values may appear. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 6 | InstrumentType | varchar(50) | YES | Instrument category from Dim_Instrument. Observed values: Currencies, Indices, Stocks, ETF, Crypto Currencies. Primary asset-class dimension for copy-position NOP decomposition. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 7 | Regulation | varchar(50) | YES | Regulatory framework name resolved from Dim_Regulation via Fact_SnapshotCustomer.RegulationID. Snapshot at ETL run time — not historical. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 8 | Player_Status | varchar(50) | YES | Player status label resolved from Dim_PlayerStatus via Fact_SnapshotCustomer.PlayerStatusID. Reflects customer account status at ETL run time. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 9 | MifidCategorization | varchar(50) | YES | MiFID II investor category from Fact_SnapshotCustomer (Retail, Professional, Eligible Counterparty). Determines capital treatment. Snapshot at ETL run time. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 10 | Total_NOP | money | YES | Net Open Position in monetary terms for copy/social-trading instruments, aggregated from BI_DB_PositionPnL via #capitaldata. Positive = net long; negative = net short. The primary K-AUM capital metric for copy-position NOP. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 11 | UpdateDate | datetime | NO | ETL run timestamp (GETDATE() at SP execution). Rows with Date < 2022-02-23 carry UpdateDate = 2022-02-23 (historical backfill at table creation); rows from 2022-02-23 onward carry live execution timestamps. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |

## 5. Lineage

See [`BI_DB_Capital_Adequacy_Monthly_NOP.lineage.md`](BI_DB_Capital_Adequacy_Monthly_NOP.lineage.md) for full ETL diagram and column-level lineage.

**Key sources**: BI_DB_PositionPnL (NOP computation), Dim_Instrument (InstrumentType, Real_CFD, Manual_Copy), Fact_SnapshotCustomer (customer attributes), Dim_Regulation, Dim_PlayerStatus.

## 6. Relationships

| Related Object | Relationship | Join Key |
|---------------|-------------|----------|
| SP_Risk_Capital_Adequacy | Writer SP | — |
| BI_DB_Capital_Adequacy_Daily_Equity | Sibling table | Same SP, daily grain; K-CMH metric (unrealized equity) |
| BI_DB_Capital_Adequacy_Daily_NOP_KASA | Sibling table | Same SP, daily grain; K-ASA metric (real CFD NOP) |
| BI_DB_PositionPnL | Source | CID / InstrumentID — open position P&L |
| Dim_Instrument | Source | InstrumentID — InstrumentType, Real_CFD, Manual_Copy |
| Fact_SnapshotCustomer | Source | CID — daily customer snapshot |
| Dim_Regulation | Source | RegulationID — name resolver |
| Dim_PlayerStatus | Source | PlayerStatusID — name resolver |

## 7. Sample Queries

```sql
-- Monthly copy-position NOP by InstrumentType
SELECT YearMonthID, InstrumentType, SUM(Total_NOP) AS Net_Open_Position
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Monthly_NOP]
WHERE YearMonthID >= 202501
GROUP BY YearMonthID, InstrumentType
ORDER BY YearMonthID, InstrumentType;

-- NOP by Regulation for latest available month
SELECT YearMonthID, Regulation, SUM(Total_NOP) AS Net_Open_Position
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Monthly_NOP]
WHERE YearMonthID = (SELECT MAX(YearMonthID) FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Monthly_NOP])
GROUP BY YearMonthID, Regulation
ORDER BY Regulation;

-- Real_CFD breakdown within copy instruments
SELECT YearMonthID, Real_CFD, SUM(Total_NOP) AS Net_Open_Position
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Monthly_NOP]
WHERE YearMonthID = 202604
GROUP BY YearMonthID, Real_CFD
ORDER BY Real_CFD;
```

## 8. Atlassian

No Atlassian/Confluence sources were queried for this object. MCP Atlassian search not available in this session.

---
*Generated: 2026-04-21 | Quality: 8.7/10 | Phases: 14/14*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4 | Elements: 11/11 documented*
*Writer SP: SP_Risk_Capital_Adequacy | UC: _Not_Migrated*
