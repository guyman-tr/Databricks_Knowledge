---
table: BI_DB_dbo.BI_DB_AcquisitionFunnel_AGG
lineage_tier: Tier 2 — derived from SP code + Tier 1 upstream wiki (BI_DB_DepositUsersFirstTouchPoints)
generated: 2026-04-22
---

# Lineage: BI_DB_AcquisitionFunnel_AGG

## ETL Pipeline

```
BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints   [Priority 20, TRUNCATE+INSERT, 2-year rolling window]
  → SP_AcquisitionFunnel_AGG (@Date DATE)
        @DateRun = start of month 3 months ago
        @DateID  = CONVERT(@DateRun, 112)
        DELETE WHERE DateID >= @DateID AND DateID <= CONVERT(@Date, 112)
        INSERT aggregated data from @DateRun through @Date
  → BI_DB_dbo.BI_DB_AcquisitionFunnel_AGG     [ROUND_ROBIN, CLUSTERED(Date ASC)]
```

## Writer SP: SP_AcquisitionFunnel_AGG

| Property | Value |
|----------|-------|
| SP | `BI_DB_dbo.SP_AcquisitionFunnel_AGG` |
| OpsDB Priority | 0 — (reads from Priority 20 source; runs after SP_DepositUsersFirstTouchPoints completes) |
| Frequency | Daily (SB_Daily process, ProcessType SQL) |
| Pattern | DELETE last 3 months + INSERT aggregate from source for same window |
| Date window | Rolling 3-month: start of month 3 months prior to @Date through @Date |

**Logic summary:**
1. Set `@DateRun = first day of the month 3 months before @Date`
2. Create temp table `#TP_AGG` (HEAP, ROUND_ROBIN) by grouping `BI_DB_DepositUsersFirstTouchPoints` WHERE `Date >= @DateRun AND Date < @Date+1` by all dimension columns
3. DELETE from target WHERE `DateID >= @DateID AND DateID <= @dt_int`
4. INSERT from `#TP_AGG` with `UpdateDate = GETDATE()`

**Column derivations:**
- All dimension columns (`Channel`, `SubChannel`, `Desk`, `Region`, `Country`, `State`, `Regulation`, `DesignatedRegulation`, `FunnelFrom`, `Platform_fromAction_Regs`, `Platform_fromAction_FTD`, `KYCFlow`): passed through from source as GROUP BY keys
- `Platform`: `UPPER(Platform)` from source — uppercased version of the source's FunnelName
- `Install`, `Registration`, `VerificationLevel1/2/3`, `DepositAttDB`, `FTD`, `OpenTrade`: `SUM(flag)` of corresponding 0/1 milestone flags in source
- `EvMatchStatus`: `SUM(ISNULL(EvMatchStatus, 0))` — count of users achieving identity match status on this date in this segment
- `Installs`: hardcoded `NULL` — AppFlyer install union branch (`#AppFlyer_Reports_AGG`) is entirely commented out
- `EmailVerification`, `PhoneVerification`: hardcoded `NULL` in INSERT — commented out in `#TP_AGG` (disabled in source too)
- `KYCFlow`: passed through from source as GROUP BY dimension, but is also disabled (all NULL) in `BI_DB_DepositUsersFirstTouchPoints`
- `UpdateDate`: `GETDATE()` at insert time — records when the ETL ran (current as of 2026-04-13)

## Upstream Sources

| Layer | Object | Type | Wiki |
|-------|--------|------|------|
| Primary source | `BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints` | Internal table (Priority 20, TRUNCATE+INSERT) | [BI_DB_DepositUsersFirstTouchPoints.md](BI_DB_DepositUsersFirstTouchPoints.md) — **Tier 1** |

**Dead code (commented out):**
- `#AppFlyer_Reports_AGG` — was intended to UNION AppFlyer install data (from `BI_DB_AppFlyer_Reports` joined to `DWH.dbo.Dim_Country`) to populate the `Installs` column. Now entirely commented out. The `Installs` column is always NULL as a result.

## Downstream Consumers

None identified in OpsDB procedure dependencies. `BI_DB_AcquisitionFunnel_AGG` is a leaf endpoint — no downstream stored procedures read from it.

## Upstream Wiki Reference

**Tier 1 source:** Column semantics for dimension columns are documented in [BI_DB_DepositUsersFirstTouchPoints.md](BI_DB_DepositUsersFirstTouchPoints.md). Descriptions for `Channel`, `SubChannel`, `Desk`, `Region`, `Country`, `State`, `Regulation`, `DesignatedRegulation`, `FunnelFrom`, `Platform`, `Platform_fromAction_Regs`, `Platform_fromAction_FTD` are inherited from that wiki.

## Notes

- **Rolling 3-month window**: The last 3 months of data are always refreshed each run. This allows late-arriving funnel completions (captured in the TRUNCATE+INSERT source) to flow through.
- **Source depth mismatch**: `BI_DB_DepositUsersFirstTouchPoints` has a 2-year rolling window (milestones ≥ 2 years ago are dropped). `BI_DB_AcquisitionFunnel_AGG` goes back to 2020-06-01. Pre-2024 data in AGG is historical and cannot be refreshed from the current source.
- **Live date range**: 2020-06-01 → 2026-04-12 (~9.5M rows)
- **OpsDB dependency**: OpsDB Main row shows Priority 0 for SP_AcquisitionFunnel_AGG, but a Dependency row shows it reads from `BI_DB_DepositUsersFirstTouchPoints` (Priority 20 source). In practice it must run after SP_DepositUsersFirstTouchPoints completes.
