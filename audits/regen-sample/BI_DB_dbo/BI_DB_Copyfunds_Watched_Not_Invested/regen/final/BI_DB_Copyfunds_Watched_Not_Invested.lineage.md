# Lineage — BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested

Generated: 2026-04-28 | SP: SP_Copyfunds_Watched_Not_Invested

---

## Source Objects

| # | Object | Schema | Type | Role |
|---|--------|--------|------|------|
| 1 | BI_DB_dbo_Relationship_sp | BI_DB_dbo | External Table (temp, populated by SP_Create_External_Streams_dbo_FollowRelationships_Range) | Follow-relationship source: users who watched a fund in the last month (CreatedAt >= @monthback) |
| 2 | Dim_Customer | DWH_dbo | Dimension | Dual-use: investor identity resolution (dc1 — CID, UserName, AccountManagerID) and fund identity resolution (dc2 — RealCID as FundCID, UserName as FundName, AccountTypeID=9 filter) |
| 3 | Dim_Mirror | DWH_dbo | Dimension | Copy-trading relationship flags (MirrorTypeID=4 for portfolio/fund copies) and allocation amounts (Amount, CloseDateID, OpenDateID) |
| 4 | Dim_Manager | DWH_dbo | Dimension | Account manager full name (FirstName + ' ' + LastName → [Account Manager]); INNER JOIN — investors without an assigned manager are excluded |
| 5 | V_Liabilities | DWH_dbo | View | Daily customer credit balance: Credit column aliased as MoneyAvailable; joined on CID + DateID = yesterday |
| 6 | BI_DB_KYC_Panel | BI_DB_dbo | Table | Liquid assets bracket answer text: Q11_AnswerText aliased as LiquidAssetsAnswer; joined on RealCID WHERE Q11_AnswerID IS NOT NULL |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|--------------|--------------|-----------|------|
| 1 | [Account Manager] | DWH_dbo.Dim_Manager | FirstName, LastName | ETL-computed: `dm.FirstName + ' ' + dm.LastName` — string concatenation of manager first and last name; INNER JOIN means this is never NULL | Tier 2 — SP_Copyfunds_Watched_Not_Invested |
| 2 | FundName | DWH_dbo.Dim_Customer | UserName | Passthrough: `dc2.UserName` where dc2 is the fund account (AccountTypeID=9) that the investor followed | Tier 1 — Customer.CustomerStatic |
| 3 | RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough: `dc1.RealCID` — investor's customer ID | Tier 1 — Customer.CustomerStatic |
| 4 | UserName | DWH_dbo.Dim_Customer | UserName | Passthrough: `dc1.UserName` — investor's login username | Tier 1 — Customer.CustomerStatic |
| 5 | FundCID | DWH_dbo.Dim_Customer | RealCID | Rename: `dc2.RealCID [FundCID]` — the fund account's RealCID | Tier 1 — Customer.CustomerStatic |
| 6 | AccountManagerID | DWH_dbo.Dim_Customer | AccountManagerID | Passthrough: `dc1.AccountManagerID` — investor's assigned BackOffice manager ID | Tier 1 — BackOffice.Customer |
| 7 | IsLifetimeCopied | DWH_dbo.Dim_Mirror | MirrorTypeID | ETL-computed: `MAX(CASE WHEN MirrorTypeID=4 THEN 1 ELSE 0 END)` — 1 if investor has ever copied any fund mirror | Tier 2 — SP_Copyfunds_Watched_Not_Invested |
| 8 | IsLastYearCopied | DWH_dbo.Dim_Mirror | MirrorTypeID, OpenDateID | ETL-computed: `MAX(CASE WHEN MirrorTypeID=4 AND OpenDateID >= @yearbackID THEN 1 ELSE 0 END)` — 1 if investor opened a fund copy in the past year | Tier 2 — SP_Copyfunds_Watched_Not_Invested |
| 9 | IsCurrentlyCopied | DWH_dbo.Dim_Mirror | MirrorTypeID, CloseDateID | ETL-computed: `MAX(CASE WHEN MirrorTypeID=4 AND CloseDateID=0 THEN 1 ELSE 0 END)` — 1 if investor has an active fund copy now (CloseDateID=0 sentinel) | Tier 2 — SP_Copyfunds_Watched_Not_Invested |
| 10 | CopyEquity | DWH_dbo.Dim_Mirror | Amount, CloseDateID | ETL-computed: `SUM(CASE WHEN CloseDateID=0 THEN Amount ELSE 0 END)` — total allocated amount across ALL active mirror types (not only funds) | Tier 2 — SP_Copyfunds_Watched_Not_Invested |
| 11 | CopyPortfolioEquity | DWH_dbo.Dim_Mirror | Amount, MirrorTypeID, CloseDateID | ETL-computed: `SUM(CASE WHEN MirrorTypeID=4 AND CloseDateID=0 THEN Amount ELSE 0 END)` — total active allocation in fund mirrors (MirrorTypeID=4) only | Tier 2 — SP_Copyfunds_Watched_Not_Invested |
| 12 | MoneyAvailable | DWH_dbo.V_Liabilities | Credit | Rename: `vl.Credit [MoneyAvailable]` — yesterday's customer credit balance from V_Liabilities (Fact_SnapshotEquity.Credit passthrough) | Tier 1 — Fact_SnapshotEquity (via V_Liabilities) |
| 13 | LiquidAssetsAnswer | BI_DB_dbo.BI_DB_KYC_Panel | Q11_AnswerText | Rename: `rl.Q11_AnswerText [LiquidAssetsAnswer]` — KYC Q11 liquid-assets bracket answer text | Tier 1 — BI_DB_KYC_Panel |
| 14 | UpdateDate | — | — | ETL-computed: `GETDATE()` at insert time — load timestamp | Tier 2 — SP_Copyfunds_Watched_Not_Invested |

---

## ETL Pipeline

```
eToro Social Graph (FollowRelationships)
  └── SP_Create_External_Streams_dbo_FollowRelationships_Range(@monthback, @dd)
        └── BI_DB_dbo.BI_DB_dbo_Relationship_sp  (external stream — last month of follow events)
              └── #userfollowfund  (Username, FundName — raw follow pairs)

DWH_dbo.Dim_Customer (IsValidCustomer=1, AccountTypeID=9 for fund detection)
  └── #transformuserdata  (RealCID, UserName, AccountManagerID, FundCID, FundName)
        ⚠ May contain multiple rows per (RealCID, FundCID) if investor followed
          the same fund multiple times within the @monthback window
        └── #distincttransformuserdata  (DISTINCT RealCID — for mirror join input only)

DWH_dbo.Dim_Mirror (LEFT JOIN on CID; MirrorTypeID=4 = fund copy)
  └── #temp  (GROUP BY RealCID, UserName, AccountManagerID, FundCID, FundName)
        Columns: RealCID + IsLifetimeCopied + IsLastYearCopied + IsCurrentlyCopied
                 + CopyEquity + CopyPortfolioEquity
        ⚠ FundCID/FundName in GROUP BY but NOT in SELECT — N rows per investor
          (one per unique fund watched) but fan-out occurs in #final JOIN

DWH_dbo.Dim_Manager  (INNER JOIN on AccountManagerID — rows without manager excluded)
DWH_dbo.V_Liabilities (DateID = @ddID = yesterday)
BI_DB_dbo.BI_DB_KYC_Panel (LEFT JOIN, Q11_AnswerID IS NOT NULL)
  └── #final  (all 13 output columns)
        ⚠ JOIN #temp t JOIN #transformuserdata tud ON t.RealCID = tud.RealCID
          — no FundCID predicate — causes N×K duplicate rows per (investor, fund)
          where N = distinct funds watched, K = follow events for that fund in window

  └── TRUNCATE + INSERT → BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested
```

**Refresh pattern**: Daily. SP_Copyfunds_Watched_Not_Invested truncates and fully rebuilds the table each run.
**Scope**: All valid customers (IsValidCustomer=1) who followed any fund account (AccountTypeID=9) in the past month.
**Note**: The commented-out `--where t.IsLifetimeCopied = 0` in the SP means the table includes ALL watchers — those who have invested in a fund AND those who have not — despite the "Watched_Not_Invested" naming.
