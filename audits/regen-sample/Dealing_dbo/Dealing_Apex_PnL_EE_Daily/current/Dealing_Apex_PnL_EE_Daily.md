# Dealing_dbo.Dealing_Apex_PnL_EE_Daily

> Daily equity-level profit and loss for eToro’s Apex LP account at calendar-day grain (not per symbol). **Stale** — last row date **2024-06-07**; counterpart to week-to-date `Dealing_Apex_PnL_EE`, both written by `Dealing_dbo.SP_Apex_PnL`.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Apex LP account equity — `Dealing_dbo.SP_Apex_PnL` (LP reconciliation / external staging chain) |
| **Refresh** | Stale (last ETL update **2024-06-08 09:19**; historically daily) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **daily** snapshot of total account equity and equity PnL for the **Apex liquidity-provider (LP) account**. Middle Office uses it for **daily equity-level checks** and reconciliation against the LP, without breaking PnL down by traded symbol. It mirrors the business meaning of `Dealing_Apex_PnL_EE` (WTD equity) but at **one row per business day** instead of a rolling week-to-date window.

The dataset is intentionally small (on the order of **~2,491 rows**, roughly one row per trading day). History begins **2022-07-06**, aligned with the start of `Dealing_Apex_PnL_Daily` in the same family of Apex procedures.

**Domain**: Dealing — daily equity reconciliation, Apex LP, Middle Office.

**Operational caveat**: Because refresh stopped in **June 2024**, do not treat this table as current-state; use it for historical daily Apex equity PnL through the last loaded date only.

## 2. Business Logic

**Daily PnL definition** (equity bridge, from procedure logic):

```
PnL = Equity_End - Equity_Start - Transfers
```

- **Equity_Start**: Total account equity at the **prior business day** end of day.
- **Equity_End**: Total account equity at **this calendar day** end of day.
- **Transfers**: Net **cash transfers** into or out of the Apex account on that day (funding movements that are not trading PnL).
- **Dividends**: Total **dividends** received in the Apex account on that day (stored separately from the core bridge; still part of the economic picture for the account).

The procedure builds daily equity using temp tables such as `#Equity_Daily`, `#Transfers_Daily`, and `#Dividends_PerAcc_Daily` (see `.lineage.md` alongside this wiki). Column layout matches **`Dealing_Apex_PnL_EE`** for consistency across WTD vs daily cuts.

**WTD vs daily**: `Dealing_Apex_PnL_EE` uses **Friday of the prior week** as the equity start anchor for week-to-date reporting; this table uses the **prior business day** for true daily deltas.

## 3. Query Advisory

- **Stale data**: Always constrain `Date` (or report “as of max(Date)”) — do not assume rows exist after **2024-06-07**.
- **Cluster key**: The table is **clustered on `Date`** — filter on `Date` or a tight date range for efficient seeks.
- **Distribution**: **ROUND_ROBIN** — small table; distribution is less critical than correct date filtering.
- **Joins**: For symbol-level Apex PnL, use **`Dealing_Apex_PnL_Daily`** (same writer SP family); this table is **account-level only**.
- **PII**: No client identifiers — LP account-level financial aggregates only.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_PnL)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date for the daily equity snapshot — the reporting date for this row. (Tier 2 — SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | Apex LP **account number** identifying the reconciled LP account. (Tier 2 — SP_Apex_PnL) |
| 3 | Equity_Start | decimal(16,6) | YES | **Total account equity** at **prior business day** end of day — opening equity for the daily bridge. (Tier 2 — SP_Apex_PnL) |
| 4 | Equity_End | decimal(16,6) | YES | **Total account equity** at **this day** end of day — closing equity for the daily bridge. (Tier 2 — SP_Apex_PnL) |
| 5 | Transfers | decimal(16,8) | YES | **Net cash transfers** into or out of the Apex account on this date (non-PnL cash movement). (Tier 2 — SP_Apex_PnL) |
| 6 | PnL | decimal(16,6) | YES | **Daily equity PnL**: `Equity_End - Equity_Start - Transfers` — trading and mark-to-market effect at account level for the day. (Tier 2 — SP_Apex_PnL) |
| 7 | UpdateDate | datetime | YES | Row load / ETL timestamp (typically `GETDATE()` at insert). [UNVERIFIED] (Tier 4 — inferred) |
| 8 | Dividends | decimal(16,6) | YES | **Dividends** credited to the Apex account on this business date. (Tier 2 — SP_Apex_PnL) |

## 5. Lineage

Summary — full detail is in **`Dealing_Apex_PnL_EE_Daily.lineage.md`** (do not edit that file from this wiki pass).

- **Writer**: `Dealing_dbo.SP_Apex_PnL` writes both **`Dealing_Apex_PnL_EE`** (WTD) and **`Dealing_Apex_PnL_EE_Daily`** in the same execution.
- **Daily path**: Uses daily temp tables (`#Equity_Daily`, `#Transfers_Daily`, `#Dividends_PerAcc_Daily`) with **prior business day** as the equity start reference.
- **Lineage type** (sidecar / pipeline tagging): LP external staging — same pipeline family as `Dealing_Apex_PnL_EE`; see that object’s lineage for the full upstream chain if needed.

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| `Dealing_dbo.Dealing_Apex_PnL_EE` | **Week-to-date** equity counterpart (same SP, different time window). |
| `Dealing_dbo.Dealing_Apex_PnL_Daily` | **Per-symbol daily** Apex PnL from the same procedure family — use when instrument detail is required. |

## 7. Sample Queries

**1) Latest loaded business date and row count sanity**

```sql
SELECT MAX(Date) AS MaxBusinessDate, COUNT(*) AS RowCnt
FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily;
```

**2) Daily equity bridge for a date range (Middle Office style)**

```sql
SELECT
    Date,
    AccountNumber,
    Equity_Start,
    Equity_End,
    Transfers,
    Dividends,
    PnL,
    Equity_End - Equity_Start - Transfers AS PnL_Recompute_Check
FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily
WHERE Date BETWEEN '2024-05-01' AND '2024-06-07'
ORDER BY Date;
```

**3) Compare last week of loaded data to WTD table (same account)**

```sql
SELECT d.Date, d.PnL AS DailyPnL, w.PnL AS WtdPnL_Example
FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily d
LEFT JOIN Dealing_dbo.Dealing_Apex_PnL_EE w
  ON w.AccountNumber = d.AccountNumber
 AND w.Date = d.Date
WHERE d.Date >= '2024-06-01'
ORDER BY d.Date;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★☆☆) | Batch: 7 (redo)*

*Tiers: 0 T1, 7 T2, 0 T3, 1 T4 | Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10*

*Object: Dealing_dbo.Dealing_Apex_PnL_EE_Daily | Type: Table | Production Source: Apex LP account equity — Dealing_dbo.SP_Apex_PnL*
