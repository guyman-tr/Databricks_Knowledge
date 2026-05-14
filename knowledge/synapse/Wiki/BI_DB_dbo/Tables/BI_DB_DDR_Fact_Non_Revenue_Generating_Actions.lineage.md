# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions` |
| **Writer SP** | `BI_DB_dbo.SP_DDR_Fact_Non_Revenue_Generating_Actions` |
| **Synapse row estimate** | ~1.82B rows (`sys.partitions` sum, MCP 2026-05-14 session) |
| **Date span (loaded keys)** | `DateID` **20070827**–**20260426** (MCP MIN/MAX same session) |
| **Complement** | `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions` — revenue TVFs / fee streams |
| **Canonical upstream fact** | `DWH_dbo.Fact_CustomerAction` (see `Fact_CustomerAction.md` + `.lineage.md`, 2026-05-14) |
| **UC Target (naming convention)** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions` |
| **UC Gold status** | **Not present** in `main.bi_db` per Databricks `SHOW TABLES ... LIKE '*ddr_fact*'` (2026-05-14 MCP) — sibling `..._revenue_generating_actions` exists |
| **Generated** | 2026-05-14 |

## Phase 9 (verbatim SP behavior) — filter and load

**Staging read (no `ActionTypeID` predicate):** `#fcaPrep` selects from `DWH_dbo.Fact_CustomerAction` with:

```sql
WHERE frcf.DateID = @dateID
```

**Final insert filter (rows that fall through the business `CASE … ELSE 'NA'` are dropped):**

```sql
FROM #fcaBiz b
WHERE b.ActionType <> 'NA'
```

**Included `ActionTypeID` set (effective “non-revenue for DDR”):** all IDs that map to a non-`NA` label in the `CASE` in `#fcaBizPrep` (see wiki §2.1 for the full WHEN list). All other `Fact_CustomerAction` rows for `@dateID` are aggregated but **excluded** before insert.

### INSERT column list (verbatim from SP)

```sql
INSERT INTO BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions (
       DateID
     , [Date]
     , RealCID
     , ActionType
     , Amount
     , CountActions
     , UpdateDate
     , IsCopyFund
)
SELECT b.DateID
     , @date AS [Date]
     , b.RealCID
     , b.ActionType
     , b.Amount
     , b.CountActions
     , GETDATE() AS UpdateDate
     , b.IsCopyFund
FROM #fcaBiz b
WHERE b.ActionType <> 'NA'
```

## Source Objects

| Source Object | Role |
|---------------|------|
| `DWH_dbo.Fact_CustomerAction` | Base events: `DateID`, `RealCID`, `ActionTypeID`, `CompensationReasonID`, `IsAirDrop`, `Amount`, `PositionID`, `MirrorID` → temp `#fcaPrep` |
| `DWH_dbo.Dim_ActionType` | `ActionType` name at first aggregate (`#fca`) |
| `DWH_dbo.Dim_CompensationReason` | Compensation reason label at `#fca` |
| `DWH_dbo.Dim_Position` | `PositionID` ↔ `MirrorID` for open/close-date window (`OpenDateID` / `CloseDateID` = `@dateID`) |
| `DWH_dbo.Dim_Mirror` | `MirrorTypeID = 4` (Smart Portfolio / “copy fund”) for `IsCopyFund` — joined on position mirror and on `Fact_CustomerAction.MirrorID` |
| `DWH_dbo.Fact_SnapshotCustomer` + `DWH_dbo.Dim_Range` | `IsDepositor = 1` on `@dateID` — splits login bucket `DepositorsLoggedIn` vs `LoggedIn` |

## Lineage Chain

```
DWH_dbo.Fact_CustomerAction (@dateID slice)
  ├─► #fcaPrep (HASH(PositionID) columnstore staging)
  └─► #fca  (GROUP BY … + Dim_Position / Dim_Mirror / Dim_ActionType / Dim_CompensationReason)
        └─► #fcaBizPrep (+ depositor split for logins; CASE → business ActionType + signed Amount)
              └─► #fcaBiz (second GROUP BY …)
                    └─► DELETE BI_DB_DDR_Fact_Non_Revenue_Generating_Actions WHERE DateID = @dateID
                          INSERT … WHERE ActionType <> 'NA'

Generic Pipeline (Gold) — **pending / not listed in Databricks bi_db ddr_fact set (2026-05-14)**
  → main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions  (target naming only)
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|------------|--------------|---------------|-----------|-------|
| DateID | Fact_CustomerAction | DateID | passthrough via `#fca` aggregates | Same calendar key as upstream fact row set for `@dateID` |
| Date | SP parameter | @date | ETL-assigned literal | `@date AS [Date]` on INSERT SELECT |
| RealCID | Fact_CustomerAction | RealCID | passthrough through grouped temps | HASH distribution column on target |
| ActionType | Fact_CustomerAction | ActionTypeID + CompensationReasonID + depositor cohort | SP CASE → varchar bucket | Drops to `'NA'` for unmapped combos (then filtered out) |
| Amount | Fact_CustomerAction | Amount | SUM + CASE sign / zeroing rules in `#fcaBizPrep`, then SUM in `#fcaBiz` | Mirrors non-revenue DDR business sign rules |
| CountActions | Fact_CustomerAction | (row count proxy) | `COUNT(RealCID)` in `#fca`, then summed in `#fcaBiz` | Event counts inside each bucket |
| UpdateDate | — | — | `GETDATE()` | Load watermark |
| IsCopyFund | Dim_Position / Dim_Mirror / Fact_CustomerAction | MirrorID joins | `CASE WHEN COALESCE(dm.MirrorID, dm1.MirrorID) IS NOT NULL THEN 1 ELSE 0 END` grouped | SP change history notes `MirrorID` gap for `ActionTypeID = 5` — position path compensates |

## Summary

| Category | Detail |
|----------|--------|
| **Columns mapped** | 8 (matches Synapse DDL) |
| **“Non-revenue” definition** | **Not** `NOT IN (<revenue ids>)`; it is **`CASE … ELSE 'NA'` + final `WHERE ActionType <> 'NA'`** in `SP_DDR_Fact_Non_Revenue_Generating_Actions` |
