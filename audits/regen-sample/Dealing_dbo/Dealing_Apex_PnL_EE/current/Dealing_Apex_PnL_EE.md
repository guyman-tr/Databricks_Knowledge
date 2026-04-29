# Dealing_dbo.Dealing_Apex_PnL_EE

> **Equity-level** (account-level) week-to-date PnL for the Apex Clearing LP — total **account equity** change, not per symbol; **stale since June 2024**, written by **`SP_Apex_PnL`**.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Apex LP **equity / statement** style feeds via staging (equity balances, transfers, aggregate dividends) — same **`SP_Apex_PnL`** family as symbol tables; see **`Dealing_Apex_PnL_EE.lineage.md`** |
| **Refresh** | Weekly WTD (Saturday-style report date aligned with symbol WTD table) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

**⚠️ Stale dataset:** Last row date **2024-06-07**; last update **2024-06-08 09:19**. Do not use for current exposure — **historical reconciliation only** unless the pipeline is revived.

**“EE” = equity-level:** This table holds **one Apex account’s total equity PnL** for the **week**, **without symbol granularity**. It answers: **How did eToro’s Apex account equity move this week** after **cash transfers**, and how does that compare to **aggregated position PnL** from **`Dealing_Apex_PnL`**?

**Middle Office use:** **Account-level** sign-off vs Apex **equity statements**; complements **`Dealing_Apex_PnL`** (per-symbol) and **`Dealing_Apex_PnL_Daily` / `Dealing_Apex_PnL_EE_Daily`** for other grains.

**Size:** Only **~5,130 rows** historically (**2021-02-10 → 2024-06-07**) — typically **a few rows per `Date`** (often **one row per `AccountNumber`** per week). **No PII** at client level.

**Dividends vs PnL:** **`Dividends`** is **aggregate dividend income across all instruments** for the account in the week. The **`PnL`** formula shown below is **equity-based** and **does not add dividends inside the same expression** — analysts may **add dividends** when presenting **total income** for the week (see Business Logic).

## 2. Business Logic

**Equity WTD formula** (from `SP_Apex_PnL` analysis):

```
PnL = Equity_End - Equity_Start - Transfers
```

- **`Equity_Start`:** **Total account equity** at **week start** (prior **Friday EOD**), **USD**.
- **`Equity_End`:** **Total account equity** at **`Date` EOD**, **USD**.
- **`Transfers`:** **Net cash** moved **into/out of** the Apex account during the week (deposits/withdrawals of hedge cash). **Positive** = funds received at Apex; **negative** = funds withdrawn.
- **`Dividends`:** **Sum of dividends** credited to the account for the week (**all symbols**).

**Reconciliation hints (from domain notes):**

- Summing **`Dealing_Apex_PnL.PnL`** across **all symbols** for a **`Date`** should **approximately** match **`Dealing_Apex_PnL_EE.PnL`**, **after transfers and presentation** — material gaps may indicate **unmapped positions**, **fees booked only at equity level**, or **timing**.
- **`PnL`** as defined **excludes embedding `Dividends`** in the same formula — for a **“total P&L including income”** narrative, **add `Dividends` explicitly** when that is the business definition.

## 3. Query Advisory

| Topic | Guidance |
|-------|----------|
| **Size** | **Very small** — performance is trivial; still **filter `Date`** for clarity. |
| **Distribution** | **ROUND_ROBIN**; **clustered on `Date`**. |
| **Grain** | **Account equity WTD** — **not** symbol level; join **symbol facts** from **`Dealing_Apex_PnL`**. |
| **Transfers** | Understand **sign convention** before interpreting **PnL** — large transfers can **mask** market PnL if not normalized. |
| **Stale** | Always print **`MAX(Date)`** in audit outputs. |

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_PnL)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **WTD report date** — **end-of-week** anchor (Saturday-style), aligned with **`Dealing_Apex_PnL.Date`** semantics. (Tier 2 — SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | **Apex account** key — **COALESCE**-style resolution across equity/transfers/dividend feeds in SP when identifiers differ by feed. (Tier 2 — SP_Apex_PnL) |
| 3 | Equity_Start | decimal(16,6) | YES | **Total equity (USD)** at **week start** — **Friday EOD** prior to **`Date`**. (Tier 2 — SP_Apex_PnL) |
| 4 | Equity_End | decimal(16,6) | YES | **Total equity (USD)** at **`Date` EOD** — closing equity on the statement. (Tier 2 — SP_Apex_PnL) |
| 5 | Transfers | decimal(16,8) | YES | **Net transfers** for the week — **cash movement** into/out of Apex; use to **explain** equity step changes separate from **market PnL**. (Tier 2 — SP_Apex_PnL) |
| 6 | PnL | decimal(16,6) | YES | **Equity PnL:** `Equity_End - Equity_Start - Transfers` — **does not** roll **`Dividends`** into this expression per SP logic. (Tier 2 — SP_Apex_PnL) |
| 7 | UpdateDate | datetime | YES | **ETL timestamp** (`GETDATE()` from `SP_Apex_PnL`). (Tier 2 — SP_Apex_PnL) |
| 8 | Dividends | decimal(16,6) | YES | **Aggregate dividends** for the **account** for the week (all instruments). (Tier 2 — SP_Apex_PnL) |

## 5. Lineage

See **`Dealing_Apex_PnL_EE.lineage.md`**. **Summary:** Same **`SP_Apex_PnL`** execution as the symbol tables. **Inputs** are **Apex equity / transfer / dividend** aggregates (via staging); **`AccountNumber`** may be derived from **whichever feed carries it** when joins are built. **No Generic Pipeline** code — **LP external** classification.

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| **`Dealing_dbo.Dealing_Apex_PnL`** | **Per-symbol WTD** — **sum of symbol PnL** should **relate to** this **`PnL`** after **transfers** and **presentation**; use both for **full** Middle Office story. |
| **`Dealing_dbo.Dealing_Apex_PnL_Daily`** | **Daily symbol** detail — drill from **equity** anomalies into **names**. |
| **`Dealing_dbo.Dealing_Apex_PnL_EE_Daily`** | **Daily equity** counterpart from the **same SP** — DOD **account** bridge. |
| **Apex staging (equity/transfers/dividends)** | Upstream of **`SP_Apex_PnL`** — see lineage file for column mapping. |

## 7. Sample Queries

**Latest equity snapshot (stale check):**

```sql
SELECT MAX(Date) AS LastReportDate, COUNT(*) AS RowCount
FROM Dealing_dbo.Dealing_Apex_PnL_EE;
```

**One week, one account — equity bridge components:**

```sql
SELECT Date, AccountNumber, Equity_Start, Equity_End, Transfers, PnL, Dividends,
       Equity_End - Equity_Start AS RawEquityDelta
FROM Dealing_dbo.Dealing_Apex_PnL_EE
WHERE Date = @WeekEndDate
  AND AccountNumber = @AccountNumber;
```

**Compare account PnL to sum of symbol WTD (investigation only):**

```sql
SELECT e.PnL AS EquityPnL,
       SUM(s.PnL) AS SumSymbolPnL,
       e.PnL - SUM(s.PnL) AS Diff
FROM Dealing_dbo.Dealing_Apex_PnL_EE AS e
JOIN Dealing_dbo.Dealing_Apex_PnL AS s
  ON s.Date = e.Date
 AND s.AccountNumber = e.AccountNumber
WHERE e.Date = @WeekEndDate
  AND e.AccountNumber = @AccountNumber
GROUP BY e.PnL;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Batch: 7 (redo)*  
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4 | Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10*  
*Object: Dealing_dbo.Dealing_Apex_PnL_EE | Type: Table | Production Source: LP external data*
