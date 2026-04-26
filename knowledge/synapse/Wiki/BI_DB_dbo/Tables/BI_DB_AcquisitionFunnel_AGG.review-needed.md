---
table: BI_DB_dbo.BI_DB_AcquisitionFunnel_AGG
review_priority: low
generated: 2026-04-22
batch: 51
---

# Review Notes: BI_DB_AcquisitionFunnel_AGG

## Items Requiring Human Verification

### 1. OpsDB Priority Inconsistency
**Status:** Flagged — low risk  
**Detail:** OpsDB Main row shows Priority 0 for `SP_AcquisitionFunnel_AGG`, but the Dependency row shows it reads from `BI_DB_DepositUsersFirstTouchPoints` (populated by `SP_DepositUsersFirstTouchPoints` at Priority 20). In the OpsDB scheduler, Priority 0 runs before Priority 20 — so technically AGG would run before its source is ready. This is likely a metadata registration error in OpsDB, or the scheduler handles dependency rows separately from priority ordering. Verify with the data engineering team how this SP is actually scheduled.

### 2. AppFlyer UNION — Intentionally Disabled?
**Status:** Unknown — needs confirmation  
**Detail:** The `#AppFlyer_Reports_AGG` UNION branch (which would populate `Installs` from `BI_DB_AppFlyer_Reports`) is entirely commented out. The `Installs` column is always NULL as a result. It's unclear whether:
- This was a deliberate design decision (AppFlyer geo data superseded by BI_DB_AppFlyer_Geo table)
- A temporary disable during debugging that was never re-enabled
- A performance optimization (AppFlyer data is very large)

If `Installs` is expected to show AppFlyer install counts, this is a bug. If it's intentionally disabled, the column should be removed from the DDL to avoid confusion. Ask the data engineering or marketing analytics team.

### 3. Historical Data Pre-2024 — Frozen
**Status:** Informational  
**Detail:** `BI_DB_DepositUsersFirstTouchPoints` (the source) has a 2-year rolling window and drops milestones older than 2 years. `BI_DB_AcquisitionFunnel_AGG` has data from 2020-06-01 (6 years). The 2020-06-01 to ~2024-04-01 data is historical/frozen and cannot be refreshed from the current source state. If historical corrections are needed for pre-2024 data, they would require special reprocessing. Confirm if this historical data is considered reliable or if there are known gaps.

### 4. Platform_fromAction_Regs / Platform_fromAction_FTD — Source Clarification
**Status:** Partially verified — medium confidence  
**Detail:** These columns come from `BI_DB_DepositUsersFirstTouchPoints` as GROUP BY dimensions. The values observed (iOS_App, Android_App, Desktop_Web, iOS_Web) suggest they track the platform used at the Registration and FTD action moments. However, `BI_DB_DepositUsersFirstTouchPoints` wiki does not document these columns explicitly (they may have been added after that wiki was written). Confirm the exact source derivation with the BI_DB_CIDFirstDates or actions tracking team.

## Column Descriptions Confidence

- Dimension columns (Channel, SubChannel, Desk, Region, Country, State, Regulation, DesignatedRegulation, FunnelFrom, Platform): **High (Tier 1)** — inherited from documented source
- Funnel metric columns (Install, Registration, VL1-3, FTD, DepositAttDB, OpenTrade, EvMatchStatus): **High (Tier 2)** — SP logic is clear and source is documented
- Disabled columns (Installs, EmailVerification, PhoneVerification, KYCFlow): **Confirmed NULL** — SP code verified
- Platform_fromAction_*: **Medium** — values observed in live data but derivation in source not documented

## Three-File Write

Complete. Lineage, wiki, and review-needed sidecar all written.
