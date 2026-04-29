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

**Granularity**: One row per (investor × fund) relationship — in principle. In practice, the #final fan-out bug (see §2.6) causes N×K duplicate rows per (investor, fund) pair for investors who watched multiple funds or have multiple follow events for the same fund. Always use `COUNT(DISTINCT RealCID)` rather than `COUNT(*)` when counting investors.

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

### 2.5 LiquidAssetsAnswer = KYC Q11 Self-Reported Bracket

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

### 2.6 #final Fan-Out Bug (Root Cause of Duplicate Rows)

The SP has a structural defect in the `#final` temporary table that causes N×K duplicate rows per (investor, fund) pair. Understanding this is essential for correct use of the table.

**Root cause**: `#temp` is created with `GROUP BY (RealCID, UserName, AccountManagerID, FundCID, FundName)` — giving one row per unique investor-fund combination — but the `SELECT` clause only stores `RealCID` (plus the aggregated flag/equity columns). FundCID and FundName are GROUP BY keys that collapse duplicate follow events, but they are **not physically stored** in `#temp`.

The subsequent join in `#final` is:
```sql
from #temp t
JOIN #transformuserdata tud ON t.RealCID = tud.RealCID
-- NO FundCID predicate
```

`#transformuserdata` retains one row per (RealCID, FundCID) from the external stream — or multiple rows if the same investor followed the same fund more than once within the `@monthback` window (each follow event is a separate row). Since the JOIN is on `RealCID` alone:

- If investor A watched N distinct funds → `#temp` has N rows for A (one per group) AND `#transformuserdata` has M rows for A (sum of all follow events across all funds).
- The JOIN produces N×M rows total for A.
- For a specific fund j with K_j follow events: A gets N×K_j rows in the output with FundName=j.

**Observed evidence**: RealCID=24457833 (watching ~55 distinct funds) generates up to 330 duplicate rows for a single (RealCID, FundName) pair. RealCID=38269010 generates up to 234 duplicates per pair. The fix would be to either (a) include FundCID in the `#temp` SELECT and use it as a JOIN predicate in `#final`, or (b) add `SELECT DISTINCT` before the final INSERT.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no co-location benefit when joining other HASH-distributed tables. The CLUSTERED INDEX on RealCID makes single-customer lookups efficient. For aggregation queries, expect a shuffle when joining to HASH(RealCID) tables like Dim_Customer.

### 3.2 Multiple Rows Per Investor

This table has one row per (investor × fund) pair **in principle**, but due to the fan-out bug (§2.6) heavily-watched investors generate many more rows than expected. Always use `COUNT(DISTINCT RealCID)` rather than `COUNT(*)` when counting investors.

### 3.3 "Not Invested" Filter

To replicate the intended "watched but not yet invested" use case, add `WHERE IsLifetimeCopied = 0` (or `IsCurrentlyCopied = 0` for current-only analysis). The SP does not apply this filter in production.

### 3.4 Common Query Patterns

| Question | Approach |
|----------|----------|
| Customers who watch a fund but never invested | `WHERE IsLifetimeCopied = 0 GROUP BY RealCID` (deduplicate first) |
| Customers who used to invest but stopped | `WHERE IsLifetimeCopied = 1 AND IsCurrentlyCopied = 0` |
| Active fund investors in the watchlist | `WHERE IsCurrentlyCopied = 1` |
| High-value prospects by liquid assets | `WHERE LiquidAssetsAnswer IN ('$50K-$200K','$200K-$500k','$500K-$1M','$1M-$5M')` |
| Watchers for a specific fund | `WHERE FundName = 'BillGates13F'` |
| Deduplicated investor list | `SELECT DISTINCT RealCID, UserName, [Account Manager], AccountManagerID, MoneyAvailable, LiquidAssetsAnswer, IsLifetimeCopied, IsCurrentlyCopied` |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | [Account Manager] | varchar(50) | NO | Full name of the investor's assigned BackOffice account manager. ETL-computed: `dm.FirstName + ' ' + dm.LastName` from DWH_dbo.Dim_Manager. The SP uses an INNER JOIN to Dim_Manager (`join DWH_dbo.Dim_Manager dm on dm.ManagerID = tud.AccountManagerID`), so investors with no assigned AccountManagerID fail the join predicate and are excluded from the table entirely — this column is never NULL in practice (confirmed: 0 NULL rows across 360,846 sampled rows). (Tier 2 — SP_Copyfunds_Watched_Not_Invested) |
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
| 12 | MoneyAvailable | money | YES | Renamed from V_Liabilities.Credit — the customer available credit balance as of yesterday (DateID = @ddID). Direct passthrough from Fact_SnapshotEquity.Credit via V_Liabilities. Range: -$2,572.79 to $855,862.42 (avg $7,186.34); 32.2% of rows show zero credit. (Tier 1 — Fact_SnapshotEquity via V_Liabilities) |
| 13 | LiquidAssetsAnswer | varchar(100) | YES | Answer text for Q11. Self-reported liquid assets bracket from the investor's KYC questionnaire (Q11). Values include 'Up to $10K', '$10K-$50K', '$50K-$200K', '$200K-$500k', '$500K-$1M', '$1M-$5M'. NULL if investor has no Q11 KYC response (Q11_AnswerID IS NULL in BI_DB_KYC_Panel). (Tier 1 — BI_DB_KYC_Panel) |
| 14 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() at insert time by SP_Copyfunds_Watched_Not_Invested. All rows in a given daily run share the same UpdateDate. (Tier 2 — SP_Copyfunds_Watched_Not_Invested) |

---

## 5. Lineage

**Production Source chain**:
- Follow events → eToro Social Graph → `BI_DB_dbo_Relationship_sp` (external stream)
- Investor / fund identity → `DWH_dbo.Dim_Customer` → Customer.CustomerStatic + BackOffice.Customer
- Copy-trading history → `DWH_dbo.Dim_Mirror` → etoro.Trade.Mirror + etoro.History.Mirror
- Manager names → `DWH_dbo.Dim_Manager` → etoro.BackOffice.Manager
- Credit balance → `DWH_dbo.V_Liabilities` → Fact_SnapshotEquity → eToro Billing
- KYC answers → `BI_DB_dbo.BI_DB_KYC_Panel` → UserApiDB.KYC.CustomerAnswers

### ETL Pipeline

```
eToro Social Graph (FollowRelationships)
  └── SP_Create_External_Streams_dbo_FollowRelationships_Range(@monthback, @dd)
        └── BI_DB_dbo.BI_DB_dbo_Relationship_sp  (external stream — last month of follow events)
              └── #userfollowfund  (Username, FundName — raw follow pairs from CreatedAt >= @monthback)

DWH_dbo.Dim_Customer (INNER JOIN on investor username + fund username)
  ├── dc1: investor identity  WHERE IsValidCustomer=1
  └── dc2: fund identity  WHERE AccountTypeID=9
        └── #transformuserdata  (RealCID, UserName, AccountManagerID, FundCID, FundName)
              ⚠ Multiple rows per (RealCID, FundCID) if same fund was followed multiple
                times in the window (each follow event = one row in external stream)
              └── #distincttransformuserdata  (DISTINCT RealCID — input to mirror join only)

DWH_dbo.Dim_Mirror (LEFT JOIN on CID; all mirror types)
  └── #temp  (GROUP BY RealCID, UserName, AccountManagerID, FundCID, FundName)
        Outputs: RealCID, IsLifetimeCopied, IsLastYearCopied, IsCurrentlyCopied,
                 CopyEquity, CopyPortfolioEquity
        ⚠ FundCID in GROUP BY but NOT in SELECT → N rows per investor in #temp
          (one per unique watched fund), but fan-out occurs in #final JOIN below

DWH_dbo.Dim_Manager  (INNER JOIN on AccountManagerID — rows without manager excluded)  ──┐
DWH_dbo.V_Liabilities (INNER JOIN on CID + DateID = @ddID = yesterday)                  ─┤
BI_DB_dbo.BI_DB_KYC_Panel (LEFT JOIN on RealCID WHERE Q11_AnswerID IS NOT NULL)          ─┤
  └── #final  ←── JOIN #temp ON t.RealCID = tud.RealCID (NO FundCID predicate)           ─┘
        ⚠ N×K fan-out: N=#temp rows for investor × K=follow events per fund in
          #transformuserdata → up to 330 duplicate rows per (RealCID, FundName) pair
          (observed: RealCID=24457833 × FundName='Sharia-AIGrowth' = 330 rows)

  └── TRUNCATE [BI_DB_dbo].[BI_DB_Copyfunds_Watched_Not_Invested]
        └── INSERT 14 columns + GETDATE() as UpdateDate
              → BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested (360,846 rows as of 2025-03-10)
```

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
| AccountManagerID | DWH_dbo.Dim_Manager | ManagerID (INNER JOIN) |
| (implicit) | DWH_dbo.Dim_Mirror | CID |
| (implicit) | DWH_dbo.V_Liabilities | CID + DateID |
| (implicit) | BI_DB_dbo.BI_DB_KYC_Panel | RealCID |

### 6.3 Referenced By

| Consumer | Purpose |
|----------|---------|
| Account manager BI dashboards / reporting | Sales and retention analysis — identifying fund-interested customers who have not yet invested |

---

## 7. Sample Queries

### 7.1 Deduplicated list of customers who watched a fund but never invested

```sql
SELECT DISTINCT
    [Account Manager], RealCID, UserName,
    MoneyAvailable, LiquidAssetsAnswer,
    IsLifetimeCopied, IsCurrentlyCopied
FROM [BI_DB_dbo].[BI_DB_Copyfunds_Watched_Not_Invested]
WHERE IsLifetimeCopied = 0
ORDER BY MoneyAvailable DESC;
```

### 7.2 High-value prospects by liquid assets bracket (deduplicated)

```sql
SELECT DISTINCT
    [Account Manager], RealCID, UserName,
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

*Generated: 2026-04-28 | Quality: 8.5/10 (★★★★☆) | Phases: P1,P2,P3,P4,P5,P6,P7,P8,P9,P9B,P10A,P10B,P11*
*SP: SP_Copyfunds_Watched_Not_Invested | Tiers: 7 T1, 7 T2, 0 T3, 0 T4*
*Object: BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested | Type: Table | Production Source: eToro Social Graph + DWH_dbo.Dim_Customer + Dim_Mirror + Dim_Manager + V_Liabilities + BI_DB_KYC_Panel*
