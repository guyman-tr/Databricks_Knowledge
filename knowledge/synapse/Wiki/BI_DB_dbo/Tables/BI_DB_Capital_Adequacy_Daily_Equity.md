# BI_DB_dbo.BI_DB_Capital_Adequacy_Daily_Equity

> Daily K-CMH capital adequacy snapshot: aggregated unrealized equity per Regulation × Player_Status × MiFID II segment, covering CySEC, BVI, FCA, and ASIC-regulated customers. Used for regulatory capital requirement reporting.

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Row Count | ~493,208 |
| Date Range | 2020-01-01 → 2026-04-12 |
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED INDEX (Date ASC) |
| Writer SP | SP_Risk_Capital_Adequacy |
| ETL Pattern | DELETE WHERE Date=@Date + INSERT |
| UC Target | _Not_Migrated |

## 1. Business Meaning

`BI_DB_Capital_Adequacy_Daily_Equity` tracks the daily **K-CMH (Capital Requirement for Client Money Holdings)** position for each regulated jurisdiction segment. It stores aggregated **unrealized equity** — combining customer cash balances and CFD open-position P&L — broken down by Regulation, Player_Status, and MiFID II categorization.

K-CMH is a prudential capital requirement imposed on investment firms to ensure sufficient own-funds coverage against client equity exposure. This table provides the daily equity component fed into capital adequacy calculations and is restricted to regulated jurisdictions only (RegulationID IN (1,2,4,5,10) — CySEC, BVI, FCA, ASIC, ASIC+GAML).

The SP is shared with two sibling tables: `BI_DB_Capital_Adequacy_Daily_NOP_KASA` (K-ASA — real CFD positions NOP) and `BI_DB_Capital_Adequacy_Monthly_NOP` (K-AUM — copy positions, monthly grain). All three are written in a single SP execution.

**Historical note**: Date range starts 2020-01-01, but UpdateDate begins 2022-02-23 — rows before that date represent a historical backfill performed at table creation. Rows from 2022-02-23 onward carry live GETDATE() timestamps.

## 2. Business Logic

### 2.1 Scope — Regulated Jurisdictions Only
Output is filtered to `RegulationID IN (1,2,4,5,10)`. Observed Regulation values: CySEC, BVI, FCA, ASIC, ASIC+GAML. Customers in other regulatory contexts (or unregulated) are excluded.

### 2.2 Unrealized Equity Computation
The SP constructs two temp table components:
- **#customerbalance_cid**: Cash balances from `V_Liabilities` × `Fact_SnapshotCustomer`, restricted to `VerLevelID ≥ 2` (verified customers) and `IsCreditReportValidCB = 1`. Aggregated by Regulation × Player_Status × MifidCategorization.
- **#cfdequity**: CFD unrealized equity from `BI_DB_PositionPnL` × `Dim_Instrument` × `Fact_SnapshotCustomer`, aggregated by Regulation × Player_Status × MifidCategorization × IsFuture.

These are combined via **FULL OUTER JOIN** into `#kcmh`: `Unrealized_Equity = ISNULL(cash, 0) + ISNULL(cfd_equity, 0)`. The FULL OUTER JOIN means rows may appear with only a cash component (IsFuture = NULL) or only a CFD component.

### 2.3 IsFuture Behavior
IsFuture comes from `Dim_Instrument` via the CFD path. Approximately **70% of 2026 rows have IsFuture = NULL** — these are cash-only segments where the FULL OUTER JOIN cash side had no matching CFD equity row. IsFuture = 0 (~30%) represents spot CFD positions. IsFuture = 1 would represent futures instruments.

### 2.4 Regulation and Player_Status Snapshot Semantics
Both Regulation and Player_Status reflect the customer's status **at ETL run time** (daily snapshot from Fact_SnapshotCustomer), not at a historical date. Time-series analysis by Regulation may be misleading for customers who changed regulatory jurisdiction.

## 3. Query Advisory

**Typical use**: Aggregate Unrealized_Equity by Regulation or MifidCategorization for a given Date to feed regulatory capital reporting.

```sql
-- Daily K-CMH total by Regulation
SELECT Date, Regulation, SUM(Unrealized_Equity) AS Total_KCM_Equity
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_Equity]
WHERE Date = '2026-04-12'
GROUP BY Date, Regulation
ORDER BY Regulation;
```

**Distribution**: ROUND_ROBIN — no skew risk; no partition elimination. Filter on Date (CLUSTERED INDEX) for index seeks on time-range queries.

**Gotchas**:
- `IsFuture = NULL` does NOT mean missing data — it means the row has only a cash equity component (no matching CFD position). Do not filter out NULLs for total Unrealized_Equity calculations.
- `Unrealized_Equity` may be **negative** (net short CFD positions or cash balances negative after losses).
- `EOM_Date = EOMONTH(Date)` — identical for all rows in a calendar month; useful for joining to monthly capital reports.

## 4. Elements

| # | Column | Data Type | Nullable | Description |
|---|--------|-----------|----------|-------------|
| 1 | EOM_Date | date | YES | End-of-month date for the reporting period, computed as EOMONTH(@date). All rows for dates within the same calendar month share the same EOM_Date. Used to join daily K-CMH rows to monthly capital adequacy aggregates. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 2 | Date | date | YES | ETL run date (the @date parameter passed to SP_Risk_Capital_Adequacy). Each daily run deletes and re-inserts all rows for this date. Primary time-series key for daily K-CMH reporting. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 3 | Regulation | varchar(50) | YES | Regulatory framework name resolved from Dim_Regulation via Fact_SnapshotCustomer.RegulationID. Restricted to RegulationID IN (1,2,4,5,10): CySEC, BVI, FCA, ASIC, ASIC+GAML. Snapshot at ETL run time — not historical. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 4 | Player_Status | varchar(50) | YES | Player status label resolved from Dim_PlayerStatus via Fact_SnapshotCustomer.PlayerStatusID. Reflects customer account status at ETL run time. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 5 | MifidCategorization | varchar(50) | YES | MiFID II investor category from Fact_SnapshotCustomer. Typically Retail, Professional, or Eligible Counterparty. Determines capital treatment under CRR/MiFID II. Snapshot at ETL run time. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 6 | Unrealized_Equity | money | YES | Aggregated unrealized equity = customer cash balances (#customerbalance_cid, V_Liabilities, VerLevelID≥2, IsCreditReportValidCB=1) + CFD open-position P&L (#cfdequity, BI_DB_PositionPnL). Combined via FULL OUTER JOIN: ISNULL(cash,0) + ISNULL(cfd_equity,0). May be negative. Primary K-CMH capital adequacy metric. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 7 | UpdateDate | datetime | NO | ETL run timestamp (GETDATE() at SP execution time). Rows with Date < 2022-02-23 carry UpdateDate = 2022-02-23 (historical backfill at table creation); rows from 2022-02-23 onward carry live execution timestamps. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |
| 8 | IsFuture | int | YES | Indicates whether the CFD equity component involves a futures instrument: 1=futures, 0=spot CFD, NULL=no CFD component (cash-only row from FULL OUTER JOIN — no matching #cfdequity row). Sourced from Dim_Instrument via #cfdequity temp table. ~70% NULL in 2026 data. (Tier 2 — SP_Risk_Capital_Adequacy code analysis) |

## 5. Lineage

See [`BI_DB_Capital_Adequacy_Daily_Equity.lineage.md`](BI_DB_Capital_Adequacy_Daily_Equity.lineage.md) for full ETL diagram and column-level lineage.

**Key sources**: V_Liabilities (cash balances), BI_DB_PositionPnL (CFD P&L), Fact_SnapshotCustomer (customer attributes), Dim_Regulation, Dim_PlayerStatus, Dim_Instrument (IsFuture).

## 6. Relationships

| Related Object | Relationship | Join Key |
|---------------|-------------|----------|
| SP_Risk_Capital_Adequacy | Writer SP | — |
| BI_DB_Capital_Adequacy_Daily_NOP_KASA | Sibling table | Same SP, same date grain; K-ASA metric (real CFD positions NOP) |
| BI_DB_Capital_Adequacy_Monthly_NOP | Sibling table | Same SP, monthly grain; K-AUM metric (copy positions) |
| Fact_SnapshotCustomer | Source | CID — daily customer snapshot |
| V_Liabilities | Source | CID — customer cash balances |
| BI_DB_PositionPnL | Source | CID / InstrumentID — open CFD position P&L |
| Dim_Instrument | Source | InstrumentID — IsFuture, Real_CFD classification |
| Dim_Regulation | Source | RegulationID — name resolver |
| Dim_PlayerStatus | Source | PlayerStatusID — name resolver |

## 7. Sample Queries

```sql
-- K-CMH equity by Regulation for a given date
SELECT Date, Regulation, MifidCategorization,
       SUM(Unrealized_Equity) AS Total_Unrealized_Equity
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_Equity]
WHERE Date = '2026-04-12'
GROUP BY Date, Regulation, MifidCategorization
ORDER BY Regulation, MifidCategorization;

-- Monthly trend by Regulation (EOM_Date for grouping)
SELECT EOM_Date, Regulation,
       SUM(Unrealized_Equity) AS Total_Unrealized_Equity
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_Equity]
WHERE EOM_Date >= '2025-01-31'
GROUP BY EOM_Date, Regulation
ORDER BY EOM_Date, Regulation;

-- Isolate CFD equity component only (exclude cash-only rows)
SELECT Date, Regulation, IsFuture,
       SUM(Unrealized_Equity) AS CFD_Equity
FROM [BI_DB_dbo].[BI_DB_Capital_Adequacy_Daily_Equity]
WHERE Date = '2026-04-12'
  AND IsFuture IS NOT NULL
GROUP BY Date, Regulation, IsFuture
ORDER BY Regulation, IsFuture;
```

## 8. Atlassian

No Atlassian/Confluence sources were queried for this object. MCP Atlassian search not available in this session.

---
*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 14/14*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4 | Elements: 8/8 documented*
*Writer SP: SP_Risk_Capital_Adequacy | UC: _Not_Migrated*
