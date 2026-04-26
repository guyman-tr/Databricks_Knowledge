# BI_DB_dbo.BI_DB_Capital_Guarantee

> Historical capital guarantee exposure tracker: negative P&L per customer per mirror for the Jan-2020 promotional cohort (3 popular investors — GainersQtr, ActiveTraders, SharpTraders). Last updated March 2023; the guarantee product has concluded.

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Row Count | ~135,660 |
| Date Range | 2020-01-05 → 2023-03-11 |
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED INDEX (Date ASC) |
| Writer SP | SP_Capital_Guarantee |
| ETL Pattern | DELETE WHERE Date=@date + INSERT |
| UC Target | _Not_Migrated |
| Status | **INACTIVE** — last updated 2023-03-12; guarantee product concluded |

## 1. Business Meaning

`BI_DB_Capital_Guarantee` tracked the daily **capital guarantee exposure** — the sum of negative P&L per customer-mirror for a specific promotional cohort. The product promised customers that they would not lose money when copying three specific popular investors who opened in a narrow January 2020 window.

The three popular investors covered:
- **GainersQtr** (ParentCID 4657429 or equivalent)
- **ActiveTraders** (ParentCID 4657433 or equivalent)
- **SharpTraders** (ParentCID 4657444 or equivalent)

The SP captured only mirrors with **negative cumulative P&L** (HAVING SUM < 0), representing actual liability under the guarantee. The firm's exposure on any given date = the sum of all negative PnL values in this table for that Date.

**This table is inactive.** The last Date in the table is 2023-03-11 and the last UpdateDate is 2023-03-12. The SP is no longer scheduled or the guarantee period has concluded. The data is preserved for historical audit and reference.

**Regulation breakdown**: CySEC 76%, ASIC 14%, ASIC & GAML 6%, FCA 4% — reflecting the regulatory mix of the Jan-2020 cohort.

## 2. Business Logic

### 2.1 Cohort Definition (Jan 2020 Guarantee Cohort)
Only mirrors matching all of the following are included:
- `dm.ParentCID IN (4657429, 4657433, 4657444)` — the three popular investors in the guarantee program
- `dm.OpenDateID >= 20200105` — mirror relationship started on or after Jan 5, 2020
- `dm.OpenDateID <= MIN(@date, 20200131)` — mirror relationship started on or before Jan 31, 2020 (or @date if earlier)
- `dm.CloseDateID = 0 OR dm.CloseDateID > @date` — mirror was still open on @date (follower had not closed)

### 2.2 Exclusion Logic (#Mirror)
The SP first builds a `#Mirror` temp table identifying mirrors to **exclude**: mirrors where the popular investor's account performed `ActionTypeID = 15` between 2020-02-01 and 2021-02-01. These mirrors are then excluded via `LEFT JOIN #Mirror WHERE tt.MirrorID IS NULL`. The exact meaning of ActionTypeID=15 should be confirmed (see review-needed), but it likely represents a disqualifying event (e.g., popular investor exited or was removed from the program).

### 2.3 P&L Computation
P&L per position is computed as:
```
CASE WHEN pp.PositionID IS NULL THEN dp.NetProfit
     ELSE pp.PositionPnL
END
```
- If the position is currently **open** (found in `BI_DB_PositionPnL` for the given DateID): use `PositionPnL` (live mark-to-market)
- If the position is **closed** (not in `BI_DB_PositionPnL`): use `Dim_Position.NetProfit` (realized P&L)

The SUM of this per-mirror, per-CID group is stored as PnL. Only groups with SUM < 0 are inserted (HAVING clause).

### 2.4 Exposure Semantics
Each row represents one customer (CID) in one mirror (MirrorID) on one Date, with their total negative P&L. The sum of PnL across all rows for a given Date represents the firm's total capital guarantee liability for that day. All PnL values are negative by construction.

## 3. Query Advisory

**This table is historical — do not expect fresh data.** The latest Date is 2023-03-11.

**Typical use**: Sum PnL by Date to get total daily guarantee liability; filter by ParentUserName to see per-popular-investor exposure.

```sql
-- Total daily guarantee liability (most recent dates)
SELECT Date, SUM(PnL) AS Total_Guarantee_Liability
FROM [BI_DB_dbo].[BI_DB_Capital_Guarantee]
WHERE Date >= '2023-01-01'
GROUP BY Date
ORDER BY Date DESC;
```

**Distribution**: ROUND_ROBIN — no skew risk. Filter on Date (CLUSTERED INDEX) for index seeks.

**Gotchas**:
- **All PnL values are negative** (HAVING SUM < 0 in SP). Do not sum expecting mixed signs; ABS(SUM(PnL)) gives gross exposure.
- **Table is INACTIVE** — do not treat MAX(Date) as "current" data. The table stopped being updated in March 2023.
- Each CID may appear multiple times (once per MirrorID if following multiple popular investors in the cohort).
- Rows without a matched BI_DB_PositionPnL entry use the realized NetProfit from Dim_Position — mixing open and closed position P&L.

## 4. Elements

| # | Column | Data Type | Nullable | Description |
|---|--------|-----------|----------|-------------|
| 1 | CID | int | YES | Customer ID — the follower (not the popular investor) in the mirror relationship. One customer may appear multiple times if they copied multiple popular investors in the guarantee cohort. (Tier 2 — SP_Capital_Guarantee code analysis) |
| 2 | Date | date | YES | ETL run date (the @date parameter). One row per CID × MirrorID per ETL run date with negative cumulative P&L. CLUSTERED INDEX column — filter here for efficient seeks. (Tier 2 — SP_Capital_Guarantee code analysis) |
| 3 | Regulation | varchar(50) | YES | Regulatory framework name resolved from Dim_Regulation via BI_DB_CIDFirstDates.RegulationID. Observed values: CySEC (76%), ASIC (14%), ASIC & GAML (6%), FCA (4%). Snapshot at ETL run time. (Tier 2 — SP_Capital_Guarantee code analysis) |
| 4 | MirrorID | int | YES | The specific copy/mirror relationship ID from Dim_Mirror. Uniquely identifies one follower-popular-investor relationship. A customer (CID) can have multiple MirrorIDs if copying more than one popular investor. (Tier 2 — SP_Capital_Guarantee code analysis) |
| 5 | ParentUserName | varchar(50) | YES | Username of the popular investor (parent) in the mirror relationship, from Dim_Mirror. Exactly three values in this table: GainersQtr, ActiveTraders, SharpTraders — corresponding to ParentCID IN (4657429,4657433,4657444). (Tier 2 — SP_Capital_Guarantee code analysis) |
| 6 | PnL | decimal(38,4) | YES | Cumulative P&L for all positions under this CID × MirrorID, summed as of @date. Computed as CASE WHEN open: BI_DB_PositionPnL.PositionPnL ELSE Dim_Position.NetProfit END. Always negative — the HAVING clause filters to SUM < 0 only. Represents the firm's guarantee exposure for this customer-mirror pair. (Tier 2 — SP_Capital_Guarantee code analysis) |
| 7 | UpdateDate | datetime | YES | ETL run timestamp (GETDATE() at SP execution). Latest value = 2023-03-12. Table has not been updated since that date. (Tier 2 — SP_Capital_Guarantee code analysis) |

## 5. Lineage

See [`BI_DB_Capital_Guarantee.lineage.md`](BI_DB_Capital_Guarantee.lineage.md) for full ETL diagram and column-level lineage.

**Key sources**: Dim_Position (positions + NetProfit), BI_DB_CIDFirstDates (RegulationID), Dim_Mirror (ParentCID, ParentUserName, cohort filter), BI_DB_PositionPnL (open position P&L), Fact_CustomerAction (exclusion list via #Mirror), Dim_Regulation (name resolver).

## 6. Relationships

| Related Object | Relationship | Join Key |
|---------------|-------------|----------|
| SP_Capital_Guarantee | Writer SP | — |
| BI_DB_CIDFirstDates | Source | CID — provides RegulationID for Regulation resolution |
| Dim_Position | Source | PositionID / CID — all positions in the guarantee cohort |
| Dim_Mirror | Source | MirrorID — mirror cohort filter (ParentCID, OpenDateID, CloseDateID, ParentUserName) |
| BI_DB_PositionPnL | Source | PositionID + DateID — live P&L for open positions |
| Fact_CustomerAction | Source | MirrorID — builds #Mirror exclusion list (ActionTypeID=15) |
| Dim_Regulation | Source | RegulationID — name resolver |

## 7. Sample Queries

```sql
-- Total daily capital guarantee liability
SELECT Date, SUM(PnL) AS Total_Liability, COUNT(1) AS Affected_Mirrors
FROM [BI_DB_dbo].[BI_DB_Capital_Guarantee]
GROUP BY Date
ORDER BY Date DESC;

-- Exposure breakdown by popular investor
SELECT ParentUserName, SUM(PnL) AS Total_Exposure, COUNT(1) AS Mirror_Count
FROM [BI_DB_dbo].[BI_DB_Capital_Guarantee]
WHERE Date = '2023-03-11'
GROUP BY ParentUserName
ORDER BY Total_Exposure;

-- Top loss-making customers on last available date
SELECT TOP 20 CID, Regulation, ParentUserName, MirrorID, PnL
FROM [BI_DB_dbo].[BI_DB_Capital_Guarantee]
WHERE Date = '2023-03-11'
ORDER BY PnL;
```

## 8. Atlassian

No Atlassian/Confluence sources were queried for this object. MCP Atlassian search not available in this session.

---
*Generated: 2026-04-21 | Quality: 8.9/10 | Phases: 14/14*
*Tiers: 0 T1, 7 T2, 0 T3, 0 T4 | Elements: 7/7 documented*
*Writer SP: SP_Capital_Guarantee | UC: _Not_Migrated | Status: INACTIVE (last 2023-03-12)*
