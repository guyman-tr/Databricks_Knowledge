---
table: BI_DB_dbo.BI_DB_AcquisitionFunnel_AGG
schema: BI_DB_dbo
documented: 2026-04-22
batch: 51
quality_score: 9.0
tier: Tier 2
row_count_approx: 9500000
date_range: 2020-06-01 to 2026-04-12
etl_frequency: Daily
etl_sp: BI_DB_dbo.SP_AcquisitionFunnel_AGG
opsdb_priority: 0
---

# BI_DB_AcquisitionFunnel_AGG

## 1. Purpose

Daily acquisition funnel aggregation by marketing segment. Each row represents the count of **new users who reached each onboarding milestone** (install, registration, verification, first deposit, first trade) on a specific date, for a specific combination of marketing channel, geographic desk, country, regulatory entity, and funnel entry point.

This is the primary **segment-level acquisition funnel report** — it answers "how many users acquired through [channel] in [country] on [date] completed registration? Verification? FTD?" Used by marketing, acquisition, and growth analytics teams for funnel conversion tracking and channel attribution.

The source is `BI_DB_DepositUsersFirstTouchPoints` (customer-level milestone flags, Priority 20), aggregated here to the segment level. Data goes back to 2020-06-01 with a rolling 3-month refresh window.

## 2. Source & Lineage

| Layer | Object |
|-------|--------|
| Upstream | `BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints` (Priority 20, 2-year rolling) — [Tier 1 wiki](BI_DB_DepositUsersFirstTouchPoints.md) |
| Writer SP | `BI_DB_dbo.SP_AcquisitionFunnel_AGG` |
| ETL pattern | Rolling 3-month DELETE+INSERT (from start of month 3 months ago through @Date) |
| OpsDB | Priority 0, SB_Daily, ProcessType SQL |

The SP groups `BI_DB_DepositUsersFirstTouchPoints` by all dimension columns and sums the 0/1 milestone flags. A commented-out AppFlyer UNION branch was intended to also contribute install counts via `BI_DB_AppFlyer_Reports`, but it is disabled — `Installs` column is always NULL.

See [BI_DB_AcquisitionFunnel_AGG.lineage.md](BI_DB_AcquisitionFunnel_AGG.lineage.md) for full SP logic.

## 3. Grain

One row per **Date × Channel × SubChannel × Desk × Region × Country × State × Regulation × DesignatedRegulation × FunnelFrom × Platform × Platform_fromAction_Regs × Platform_fromAction_FTD × KYCFlow**.

- Multiple funnel metric columns per row — NOT one row per milestone. A row covers all milestone counts for that date-segment combination.
- `Date` is the milestone date (the date on which that specific funnel step occurred for counted users)

## 4. Distribution & Clustering

| Property | Value |
|----------|-------|
| Distribution | ROUND_ROBIN |
| Clustering | CLUSTERED INDEX on `Date ASC` |
| Date range (live) | 2020-06-01 → 2026-04-12 |
| Row count | ~9.5M |
| Refresh window | Last 3 months refreshed each daily run |

## 5. Column Reference

### Date Columns

| Column | Type | Description |
|--------|------|-------------|
| `Date` | DATE | The date on which the funnel milestone(s) counted in this row occurred. Milestone date (not run date). |
| `DateID` | INT | `Date` in YYYYMMDD integer format. ETL partition key used for the DELETE window targeting. |
| `UpdateDate` | DATETIME | `GETDATE()` at SP insert time — records when this row was written by the ETL. Useful for freshness checking. |

### Marketing Segment Dimensions

These columns are GROUP BY dimensions sourced from `BI_DB_DepositUsersFirstTouchPoints`. Column descriptions are inherited from that table's [Tier 1 wiki](BI_DB_DepositUsersFirstTouchPoints.md).

| Column | Type | Description |
|--------|------|-------------|
| `Channel` | NVARCHAR(100) | Marketing acquisition channel. Values: `Direct`, `Affiliate`, `SEM`, `SEO`, `Mobile Acquisition`, `Friend Referral`, `Media Performance`, `Media`, `Media Programmatic`. (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.Channel) |
| `SubChannel` | NVARCHAR(100) | Sub-channel within Channel (e.g., `Direct Mobile`, `Direct`, `Google Brand`, `Affiliate`). (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.SubChannel) |
| `Desk` | NVARCHAR(100) | Sales/support desk regional assignment (e.g., `German`, `UK`, `South & Central America`, `Arabic`). (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.Desk) |
| `Region` | NVARCHAR(100) | Marketing region (e.g., `South & Central America`, `German`, `Arabic GCC`, `ROE`). May match Desk or be a broader grouping. (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.Region) |
| `Country` | VARCHAR(100) | Country of residence name in English (e.g., `Germany`, `Argentina`, `Ireland`). (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.Country) |
| `State` | VARCHAR(100) | US state or province name. NULL for non-US. (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.State) |
| `Regulation` | VARCHAR(100) | Regulatory entity governing users in this segment. Values: `BVI` (4.0M), `CySEC` (2.5M), `eToroUS` (861K), `ASIC & GAML` (753K), `FCA` (567K), `FinCEN+FINRA` (349K), others. (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.Regulation) |
| `DesignatedRegulation` | VARCHAR(100) | Target/assigned regulatory entity. May differ from `Regulation` during entity migrations. (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.DesignatedRegulation) |
| `FunnelFrom` | VARCHAR(100) | Funnel entry point — the product or landing page through which users entered. Values: `Retoro` (web, 2.6M), `reToroAndroid` (1.6M), `reToroiOS` (1.4M), `eToro Homepage` (1.1M), `Stocks Offering`, `Web Registration Form LP`, `Crypto Offering`, `Landing Page`, `Copy Traders Offering`, `CFDs Offering`. (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.FunnelFrom) |
| `Platform` | VARCHAR(100) | Funnel platform name, uppercased by SP (`UPPER(Platform)` from source). Maps to `FunnelFrom` with all-caps: `RETORO`, `RETOROANDROID`, `RETOROIOS`. (Tier 1 — BI_DB_DepositUsersFirstTouchPoints.Platform, uppercased) |
| `Platform_fromAction_Regs` | VARCHAR(100) | The platform/device from which the Registration action was performed (e.g., `iOS_App`, `Android_App`, `Desktop_Web`, `iOS_Web`). Passed through from source as a GROUP BY dimension. |
| `Platform_fromAction_FTD` | VARCHAR(100) | The platform/device from which the First Time Deposit action was performed. Same value set as `Platform_fromAction_Regs`. Populated only for rows where FTD occurred. |
| `KYCFlow` | VARCHAR(50) | KYC (Know Your Customer) flow type. Passed through from source as a GROUP BY dimension. **Disabled in source** (`BI_DB_DepositUsersFirstTouchPoints.KYCFlow` is always NULL) — always NULL in this table. |

### Funnel Metric Columns

Each column is a **count (SUM of 0/1 flags)** representing how many distinct users in this Date × segment combination reached that milestone on this date.

| Column | Type | Description |
|--------|------|-------------|
| `Install` | INT | Count of users whose first app/web install milestone was on this date, in this segment. Sourced from `BI_DB_DepositUsersFirstTouchPoints.Install` flag (from `CIDFirstDates.FirstInstallDate`). |
| `Registration` | INT | Count of users who registered on this date in this segment. The top-of-funnel conversion event. |
| `VerificationLevel1` | INT | Count of users who completed the first identity verification step (ID upload) on this date in this segment. |
| `VerificationLevel2` | INT | Count of users who completed the second verification step on this date in this segment. |
| `VerificationLevel3` | INT | Count of users who completed full verification (all 3 levels) on this date in this segment. |
| `DepositAttDB` | INT | Count of users who made their first deposit attempt on this date in this segment (attempt, not necessarily successful). |
| `FTD` | INT | Count of users who made their First Time Deposit (successful) on this date in this segment. The primary revenue conversion metric. |
| `OpenTrade` | INT | Count of users who opened their first trade position on this date in this segment. |
| `EvMatchStatus` | INT | Count of users who achieved identity verification match status (`SUM(ISNULL(EvMatchStatus, 0))`) on this date in this segment. |

### Disabled / Always-NULL Columns

These columns exist in the DDL and INSERT list but are always NULL due to disabled SP logic or disabled source columns:

| Column | Type | Reason Always NULL |
|--------|------|-------------------|
| `Installs` | INT | AppFlyer install count — the `#AppFlyer_Reports_AGG` UNION branch is entirely commented out in the SP. Was intended to count AppFlyer-attributed installs by geo/platform. |
| `EmailVerification` | INT | Disabled in `BI_DB_DepositUsersFirstTouchPoints` source (all NULL there too). Hardcoded NULL in INSERT. |
| `PhoneVerification` | INT | Same as `EmailVerification`. Disabled in source and hardcoded NULL in INSERT. |

## 6. ETL Notes

- **Rolling 3-month window**: `@DateRun = DATEADD(MONTH, -3, first day of @Date's month)`. DELETE WHERE `DateID >= @DateRun AND DateID <= @Date`. This means the last ~90 days are always re-computed to capture late-arriving funnel milestones from the source.
- **Source uses NOLOCK**: `FROM [BI_DB_DepositUsersFirstTouchPoints] WITH(NOLOCK)` — legacy SQL Server pattern; on Synapse this hint is accepted but not strictly necessary.
- **Source is Priority 20**: `BI_DB_DepositUsersFirstTouchPoints` is refreshed by `SP_DepositUsersFirstTouchPoints` at Priority 20 (TRUNCATE+INSERT). AGG must run after Priority 20 completes. OpsDB Main row shows Priority 0 for this SP — likely a metadata inconsistency.
- **Historical data gap**: Source has 2-year rolling window (drops milestones older than 2 years). AGG has data back to 2020-06-01. Pre-2024 data in AGG cannot be refreshed from the current source.
- **`Platform` uppercased**: SP applies `UPPER(Platform)`, so `reToroAndroid` → `RETOROANDROID`, `reToroiOS` → `RETOROIOS`, `Retoro` → `RETORO`. `FunnelFrom` keeps original case.

## 7. Usage Notes

- **Funnel conversion rate**: Divide downstream metric by Registration to get conversion rates: `FTD / Registration`, `VerificationLevel1 / Registration`, etc.
- **Channel attribution**: Group by `Channel` + `SubChannel` + `Desk` to see acquisition performance by marketing channel and regional team.
- **Regulatory split**: Group by `Regulation` to see funnel performance by eToro entity (BVI, CySEC, FCA, etc.).
- **Platform analysis**: Use `FunnelFrom` or `Platform` to split by mobile app vs web entry point. `Platform_fromAction_Regs` and `Platform_fromAction_FTD` reveal which device the conversion occurred on (may differ from entry platform).
- **Date semantics**: Each row's funnel metrics reflect users whose specific milestone occurred on `Date` — NOT cumulative counts. Sum across dates for period totals.
- **Do not use `Installs`, `EmailVerification`, `PhoneVerification`** — always NULL (see disabled columns above).
- **User-level source**: For user-level detail behind these aggregates, query `BI_DB_DepositUsersFirstTouchPoints` directly (2-year window, one row per CID per milestone date).

## 8. Quality & Caveats

| Issue | Detail |
|-------|--------|
| `Installs` always NULL | AppFlyer UNION branch disabled. This column was designed to hold AppFlyer-attributed install counts by geo/platform (complementing the organic `Install` column from touch points), but the branch is commented out. Do not use. |
| `EmailVerification`, `PhoneVerification` always NULL | Disabled in source and hardcoded NULL in INSERT. Both are vestigial DDL columns. |
| `KYCFlow` always NULL | Disabled in `BI_DB_DepositUsersFirstTouchPoints` source — all NULL there, so always NULL here too. |
| OpsDB Priority inconsistency | Main row shows Priority 0 for `SP_AcquisitionFunnel_AGG` but it reads from a Priority 20 source. In practice the scheduler must handle this; the effective run priority is after Priority 20. |
| Historical data not refreshable | Data before ~2024-04-01 is frozen (outside the 2-year source window). Any historical corrections require manual reprocessing from archived source data. |
| Rolling window reprocesses 3 months | Each daily run re-aggregates the last ~90 days. Expected behavior — ensures completeness but means same row can be updated across multiple daily runs. |
