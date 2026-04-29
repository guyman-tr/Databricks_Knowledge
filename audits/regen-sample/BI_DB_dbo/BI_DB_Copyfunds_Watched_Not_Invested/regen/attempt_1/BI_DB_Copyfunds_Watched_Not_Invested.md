# BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested

> Daily full-rebuild table (360K rows, 63.7K distinct investors × 129 funds) tracking valid eToro customers who followed at least one eToro-managed copy-fund account in the past month — capturing each investor's fund watchlist relationship alongside their copy-trading history (lifetime/last-year/current fund copy flags), active mirror equity, credit balance, and KYC liquid-assets bracket for account-manager sales and retention workflows.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | eToro Social Graph (FollowRelationships) + DWH_dbo.Dim_Customer + DWH_dbo.Dim_Mirror + DWH_dbo.Dim_Manager + DWH_dbo.V_Liabilities + BI_DB_dbo.BI_DB_KYC_Panel |
| **Refresh** | Daily — SP_Copyfunds_Watched_Not_Invested; full TRUNCATE + INSERT each run |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **Column Count** | 14 |
| **Row Count (sampled 2025-03-10)** | 360,846 rows; 63,741 distinct investors; 129 distinct funds; 109 distinct account managers |
| **UC Target** | Not confirmed |

---

## 1. Business Meaning

`BI_DB_Copyfunds_Watched_Not_Invested` is an account-manager sales-support table. It answers the question: "Which of my customers have expressed interest in copy-funds (by following/watching a fund account) but may not yet be actively investing in one?" The table is the downstream output of `SP_Copyfunds_Watched_Not_Invested`, which:

1. Pulls all follow-relationship events from the last calendar month via the external stream `BI_DB_dbo_Relationship_sp` (social graph).
2. Resolves both sides of the follow relationship to eToro customer CIDs, filtering to fund accounts (AccountTypeID=9) on the followed side and valid customers (IsValidCustomer=1) on the follower side.
3. Joins each investor's copy-trading history from `Dim_Mirror` to produce three binary flags indicating whether the investor has **ever** copied a fund, copied one **in the past year**, or **currently** has an active fund copy.
4. Adds financial context from `V_Liabilities` (available credit) and `BI_DB_KYC_Panel` (self-reported liquid assets bracket) to help account managers prioritize outreach.

**Despite the table name**: The SP comment `--where t.IsLifetimeCopied = 0` is commented out in production, meaning the table contains **all** fund-watchers — including those who are already investing. The three `Is*Copied` flags allow downstream consumers to filter to true "watched but not invested" rows if needed.

**Granularity**: One row per (investor × fund) relationship. A single investor watching multiple funds generates multiple rows. As of the sample date, 360,846 rows cover 63,741 distinct investors and 129 distinct funds.

---

## 2. Business Logic

### 2.1 Fund Detection (AccountTypeID=9)

The SP identifies fund accounts by joining `Dim_Customer` on the fund username from `BI_DB_dbo_Relationship_sp` and filtering `WHERE dc2.AccountTypeID = 9`. AccountTypeID=9 is the eToro managed-fund account type (per Dim_Mirror documentation: IsCopyFundMirror is 1 when ParentCID is in BackOffice accounts with AccountTypeID=9).

### 2.2 Copy Scope Window Variables

The SP declares three time reference variables:
- `@dd` = yesterday
- `@monthback` = 1 month before yesterday — used for the follow-event window (only watchers from last month are included)
- `@yearback` / `@yearbackID` = 1 year before yesterday — used for `IsLastYearCopied` threshold

### 2.3 IsLifetimeCopied / IsLastYearCopied / IsCurrentlyCopied

All three flags are computed in `#temp` via `MAX(CASE ...)` over a LEFT JOIN to `Dim_Mirror` (all mirror types):

| Flag | Condition |
|------|-----------|
| IsLifetimeCopied | MirrorTypeID=4 (any open or closed fund mirror ever) |
| IsLastYearCopied | MirrorTypeID=4 AND OpenDateID >= @yearbackID (fund mirror opened in last year) |
| IsCurrentlyCopied | MirrorTypeID=4 AND CloseDateID=0 (active fund mirror using open-mirror sentinel) |

### 2.4 CopyEquity vs. CopyPortfolioEquity

| Column | Mirror Scope | Condition |
|--------|-------------|-----------|
| CopyEquity | ALL active mirrors (any MirrorTypeID) | CloseDateID=0 |
| CopyPortfolioEquity | Fund mirrors only (MirrorTypeID=4) | MirrorTypeID=4 AND CloseDateID=0 |

`CopyEquity` captures the investor's total active copy-trading book (regular + fund copies). `CopyPortfolioEquity` isolates fund-portfolio exposure.

### 2.5 MoneyAvailable = Yesterday's Credit

`MoneyAvailable` is `V_Liabilities.Credit` for the day before the SP run (`DateID = @ddID`). Credit in V_Liabilities is the customer's available credit line (bonus/promotional credit balance), not their total equity. This is the amount available for copy-fund investment without needing a new deposit.

### 2.6 LiquidAssetsAnswer = KYC Q11 Self-Reported Bracket

`LiquidAssetsAnswer` is the customer's self-reported liquid assets bracket from their KYC questionnaire (Q11). The SP joins `BI_DB_KYC_Panel` with `WHERE Q11_AnswerID IS NOT NULL`, so customers without a Q11 answer get NULL. Observed distribution from live data:

| Bracket | Rows |
|---------|------|
| Up to $10K | 138,003 (38.2%) |
| $10K–$50K | 115,242 (31.9%) |
| $50K–$200K | 61,876 (17.1%) |
| $200K–$500k | 19,452 (5.4%) |
| $500K–$1M | 13,560 (3.8%) |
| $1M–$5M | 12,039 (3.3%) |
| NULL / other | ~674 (<0.2%) |

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no co-location benefit when joining other HASH-distributed tables. The CLUSTERED INDEX on RealCID makes single-customer lookups efficient. For aggregation queries, expect a shuffle when joining to HASH(RealCID) tables like Dim_Customer.

### 3.2 Multiple Rows Per Investor

This table has one row per (investor × fund) pair. Always use `COUNT(DISTINCT RealCID)` rather than `COUNT(*)` when counting investors.

### 3.3 "Not Invested" Filter

To replicate the intended "watched but not yet invested" use case, add `WHERE IsLifetimeCopied = 0` (or `IsCurrentlyCopied = 0` for current-only analysis). The SP does not apply this filter in production.

### 3.4 Common Query Patterns

| Question | Approach |
|----------|----------|
| Customers who watch a fund but never invested | `WHERE IsLifetimeCopied = 0` |
| Customers who used to invest but stopped | `WHERE IsLifetimeCopied = 1 AND IsCurrentlyCopied = 0` |
| Active fund investors in the watchlist | `WHERE IsCurrentlyCopied = 1` |
| High-value prospects by liquid assets | `WHERE LiquidAssetsAnswer IN ('$50K-$200K','$200K-$500k','$500K-$1M','$1M-$5M')` |
| Watchers for a specific fund | `WHERE FundName = 'BillGates13F'` |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | [Account Manager] | varchar(50) | YES | Full name of the investor's assigned BackOffice account manager. ETL-computed: `dm.FirstName + ' ' + dm.LastName` from DWH_dbo.Dim_Manager. NULL if no manager is assigned. (Tier 2 — SP_Copyfunds_Watched_Not_Invested) |
| 2 | FundName | varchar(100) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Here this is the username of the eToro-managed fund account (AccountTypeID=9) that the investor followed. (Tier 1 — Customer.CustomerStatic) |
| 3 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Here this identifies the investor (the user who followed the fund). (Tier 1 — Customer.CustomerStatic) |
| 4 | UserName | varchar(100) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Here this is the investor's username. (Tier 1 — Customer.CustomerStatic) |
| 5 | FundCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Here this is the RealCID of the eToro-managed fund account (dc2.RealCID). (Tier 1 — Customer.CustomerStatic) |
| 6 | AccountManagerID | int | YES | Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. Here this is the investor's assigned account manager ID. (Tier 1 — BackOffice.Customer) |
| 7 | IsLifetimeCopied | int | YES | 1 if the investor has ever opened a fund copy-mirror (MirrorTypeID=4) at any point in history; 0 otherwise. ETL-computed: `MAX(CASE WHEN MirrorTypeID=4 THEN 1 ELSE 0 END)` over all Dim_Mirror rows for the investor. (Tier 2 — SP_Copyfunds_Watched_Not_Invested) |
| 8 | IsLastYearCopied | int | YES | 1 if the investor opened a fund copy-mirror (MirrorTypeID=4) with OpenDateID >= one year before yesterday; 0 otherwise. ETL-computed: `MAX(CASE WHEN MirrorTypeID=4 AND OpenDateID >= @yearbackID THEN 1 ELSE 0 END)`. (Tier 2 — SP_Copyfunds_Watched_Not_Invested) |
| 9 | IsCurrentlyCopied | int | YES | 1 if the investor currently has an active fund copy-mirror (MirrorTypeID=4 AND CloseDateID=0); 0 otherwise. ETL-computed: `MAX(CASE WHEN MirrorTypeID=4 AND CloseDateID=0 THEN 1 ELSE 0 END)`. CloseDateID=0 is the Dim_Mirror open-mirror sentinel. (Tier 2 — SP_Copyfunds_Watched_Not_Invested) |
| 10 | CopyEquity | money | YES | Total allocated amount (in USD) across ALL of the investor's currently active copy mirrors (any MirrorTypeID), not just fund copies. ETL-computed: `SUM(CASE WHEN CloseDateID=0 THEN dm.Amount ELSE 0 END)`. Max observed: $82,886.67. (Tier 2 — SP_Copyfunds_Watched_Not_Invested) |
| 11 | CopyPortfolioEquity | money | YES | Total allocated amount (in USD) in currently active fund-type copy mirrors only (MirrorTypeID=4 AND CloseDateID=0). ETL-computed: `SUM(CASE WHEN MirrorTypeID=4 AND CloseDateID=0 THEN dm.Amount ELSE 0 END)`. Max observed: $64,842.40. (Tier 2 — SP_Copyfunds_Watched_Not_Invested) |
| 12 | MoneyAvailable | money | YES | Answer text for Q11. Renamed from V_Liabilities.Credit — the investor's available credit balance as of yesterday. Max observed: $855,862.42. Used by account managers to identify investable capacity. (Tier 1 — Fact_SnapshotEquity via V_Liabilities) |
| 13 | LiquidAssetsAnswer | varchar(100) | YES | Answer text for Q11. Self-reported liquid assets bracket from the investor's KYC questionnaire (Q11). Values include 'Up to $10K', '$10K-$50K', '$50K-$200K', '$200K-$500k', '$500K-$1M', '$1M-$5M'. NULL if investor has no Q11 KYC response (Q11_AnswerID IS NULL in BI_DB_KYC_Panel). (Tier 1 — BI_DB_KYC_Panel) |
| 14 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() at insert time by SP_Copyfunds_Watched_Not_Invested. All rows in a given daily run share the same UpdateDate. (Tier 2 — SP_Copyfunds_Watched_Not_Invested) |

---

## 5. Lineage

See `BI_DB_Copyfunds_Watched_Not_Invested.lineage.md` for full column lineage and ETL pipeline diagram.

**Production Source chain**:
- Follow events → eToro Social Graph → `BI_DB_dbo_Relationship_sp` (external stream)
- Investor / fund identity → `DWH_dbo.Dim_Customer` → Customer.CustomerStatic + BackOffice.Customer
- Copy-trading history → `DWH_dbo.Dim_Mirror` → etoro.Trade.Mirror + etoro.History.Mirror
- Manager names → `DWH_dbo.Dim_Manager` → etoro.BackOffice.Manager
- Credit balance → `DWH_dbo.V_Liabilities` → Fact_SnapshotEquity → eToro Billing
- KYC answers → `BI_DB_dbo.BI_DB_KYC_Panel` → UserApiDB.KYC.CustomerAnswers

---

## 6. Relationships

### 6.1 Produced By

| SP | Pattern | Schedule |
|----|---------|----------|
| BI_DB_dbo.SP_Copyfunds_Watched_Not_Invested | TRUNCATE + full INSERT | Daily |

### 6.2 References To

| Column | Related Object | Join Key |
|--------|---------------|---------|
| RealCID / FundCID | DWH_dbo.Dim_Customer | RealCID |
| AccountManagerID | DWH_dbo.Dim_Manager | ManagerID |
| (implicit) | DWH_dbo.Dim_Mirror | CID |
| (implicit) | DWH_dbo.V_Liabilities | CID + DateID |
| (implicit) | BI_DB_dbo.BI_DB_KYC_Panel | RealCID |

### 6.3 Referenced By

| Consumer | Purpose |
|----------|---------|
| Account manager BI dashboards / reporting | Sales and retention analysis — identifying fund-interested customers who have not yet invested |

---

## 7. Sample Queries

### 7.1 Customers who watched a fund but never invested (true target)

```sql
SELECT [Account Manager], FundName, RealCID, UserName,
       MoneyAvailable, LiquidAssetsAnswer, UpdateDate
FROM [BI_DB_dbo].[BI_DB_Copyfunds_Watched_Not_Invested]
WHERE IsLifetimeCopied = 0
ORDER BY MoneyAvailable DESC;
```

### 7.2 High-value prospects by liquid assets bracket

```sql
SELECT [Account Manager], FundName, RealCID, UserName,
       LiquidAssetsAnswer, MoneyAvailable, CopyEquity,
       IsCurrentlyCopied
FROM [BI_DB_dbo].[BI_DB_Copyfunds_Watched_Not_Invested]
WHERE LiquidAssetsAnswer IN ('$50K-$200K', '$200K-$500k', '$500K-$1M', '$1M-$5M')
  AND IsCurrentlyCopied = 0
ORDER BY MoneyAvailable DESC;
```

### 7.3 Investor count per fund (distinct investors watching each fund)

```sql
SELECT FundName, FundCID,
       COUNT(DISTINCT RealCID) AS WatcherCount,
       SUM(CASE WHEN IsCurrentlyCopied = 1 THEN 1 ELSE 0 END) AS CurrentlyInvested,
       SUM(CASE WHEN IsLifetimeCopied = 0 THEN 1 ELSE 0 END) AS NeverInvested
FROM [BI_DB_dbo].[BI_DB_Copyfunds_Watched_Not_Invested]
GROUP BY FundName, FundCID
ORDER BY WatcherCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources confirmed in this session (Atlassian MCP not invoked).

---

*Generated: 2026-04-28 | SP: SP_Copyfunds_Watched_Not_Invested | Tiers: 6 T1, 8 T2, 0 T3, 0 T4*
*Object: BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested | Type: Table | Production Source: eToro Social Graph + DWH_dbo.Dim_Customer + Dim_Mirror + Dim_Manager + V_Liabilities + BI_DB_KYC_Panel*
