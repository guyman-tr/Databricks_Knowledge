# Dealing_Staking_Position

## 1. Business Meaning

Position-level granularity table for the crypto staking program — one row per client position per staking month. This is the foundational table in the staking pipeline: it records every position that was considered for staking eligibility, along with the eligibility decision and all attributes that drove it.

Written by `SP_Staking` when it processes a new staking month (event-driven: triggers when Fivetran updates `google_sheets_platform_rewards` with a new month's config). Positions that qualified contribute their `Total_USD` to the staking pool used for reward distribution in `Dealing_Staking_Results`.

**Scale and activity:** September 2023 to present (latest StakingMonthID = 202502 / Feb 2026). **159.5 million rows**. 9 staking-eligible instruments: ADA, ATOM, DOT, ETH, NEAR, POL, SOL, SUI, TRX.

**Key design notes:**
- ETH is **opt-in OFF by default** — all other coins are opt-in ON by default
- Non-US clients only (SR-330593 added `AND ((is_us<>1) OR (is_us IS NULL))` in Sept 2025)
- **StakingMonthID has a known 7-digit bug** in two historical records (2025030 and 2024100) — use `StakingMonth + StakingYear` for time-based filtering
- `Effective_OpenDate` and `Effective_CloseDate` are adjusted by the `IntroDays` grace period

## 2. Business Logic

### 2.1 Staking Period and Grace Period

Each staking month runs from `staking_start_date` to `staking_end_date` (from Fivetran google_sheets). Positions opened within `IntroDays` days before the start date are still eligible (grace period):

```sql
Effective_OpenDate = MAX(staking_start_date - IntroDays, actual_open_date)
Effective_CloseDate = MIN(staking_end_date, actual_close_date)
Eligible_Staking_Days = DATEDIFF(DAY, Effective_OpenDate, Effective_CloseDate) + 1
```

A position closed before the staking period starts = 0 eligible days = excluded.

### 2.2 Eligibility Rules (IsClientEligible = 1 requires ALL of):

| Rule | Column | Condition |
|------|--------|-----------|
| Country eligible | IsEligibleCountry | Country NOT IN large exclusion list |
| Regulation eligible | IsRegulationEligible | RegulationID NOT IN (6,7,8) — no US |
| No AML restriction | IsAML_Restricted | = 0 |
| Active account | IsAccountStatusEligible | Account status = Active |
| Not eToro employee | IsEtorian | = 0 |
| Not UK-prohibited | UK_Prohibited | = 0 (per SR-262096, specific coins) |
| Opted-in (ETH) | IsOptedIn_ETH | = 1 (ETH only — default OFF) |
| Not opted-out | IsWaiver | = 0 (other coins default ON) |
| Not Popular Investor | IsPI | = 0 (PIs excluded from staking) |

### 2.3 RevShare Brackets

Client's share of rewards is determined by PlayerLevel:

| PlayerLevelID | Tier | RevShare |
|---------------|------|----------|
| 1 | Bronze | 45% |
| 5 | Silver | 55% |
| 3 | Gold | 65% |
| 2 | Platinum | 75% |
| 6 | Platinum Plus | 85% |
| 7 | Diamond | 90% |

### 2.4 StakingMonthID Bug

Two historical IDs are malformed (7 digits instead of 6):
- `2024100` (should be `202410` — October 2024)
- `2025030` (should be `202503` — March 2025)

These sort numerically **above** all valid 6-digit IDs, corrupting any `MAX(StakingMonthID)` or `ORDER BY StakingMonthID DESC` query.

**Workaround:** Always filter or order using `StakingYear` + `StakingMonth` (month name) instead of `StakingMonthID`.

### 2.5 Cash vs Crypto Compensation

`IsCashEquivalentCountry` flags clients who receive cash compensation instead of a crypto airdrop:
```sql
IsCashEquivalentCountry = CASE WHEN CountryID IN (63,67,96,105,148,167,94) THEN 1 ELSE 0 END
```
CountryID 94 = Hungary (most common). These clients still appear in Dealing_Staking_Position as eligible but receive USD credit instead of crypto airdrop.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, **159.5 million rows**. Always filter on `StakingMonthID` or `StakingYear`+`StakingMonth`. Avoid full scans.

**⚠️ Do NOT use `MAX(StakingMonthID)` or `ORDER BY StakingMonthID DESC`** — malformed IDs 2025030 and 2024100 will be returned instead of the latest valid month. Use:

```sql
-- Safe: get latest staking month
SELECT TOP 1 StakingYear, StakingMonth
FROM Dealing_dbo.Dealing_Staking_Position
WHERE LEN(CAST(StakingMonthID AS VARCHAR)) = 6  -- exclude malformed 7-digit IDs
ORDER BY StakingYear DESC,
    CASE StakingMonth
      WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3
      WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6
      WHEN 'July' THEN 7 WHEN 'August' THEN 8 WHEN 'September' THEN 9
      WHEN 'October' THEN 10 WHEN 'November' THEN 11 WHEN 'December' THEN 12
    END DESC
```

```sql
-- Eligible positions for Feb 2026 by instrument
SELECT Currency, COUNT(*) AS eligible_positions,
    SUM(Total_USD) AS pool_contribution
FROM Dealing_dbo.Dealing_Staking_Position
WHERE StakingYear = 2026 AND StakingMonth = 'February'
  AND IsClientEligible = 1
GROUP BY Currency
ORDER BY pool_contribution DESC
```

```sql
-- Ineligibility reason distribution for a month
SELECT NonEligible_PrimaryReason, COUNT(*) AS count
FROM Dealing_dbo.Dealing_Staking_Position
WHERE StakingYear = 2026 AND StakingMonth = 'February'
  AND IsClientEligible = 0
GROUP BY NonEligible_PrimaryReason
ORDER BY count DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking month key (YYYYMM format). ⚠️ Two malformed 7-digit values (2025030, 2024100) — use StakingYear+StakingMonth for filtering. (Tier 2) |
| StakingMonth | varchar | Month name (January–December). (Tier 2 — ETL-computed from staking_end_date) |
| StakingYear | int | Calendar year of the staking period. (Tier 2 — ETL-computed from staking_end_date) |
| CID | int | Client account ID. (Tier 2 — Dim_Customer.RealCID passthrough) |
| GCID | int | Group/household customer ID. (Tier 2 — Dim_Customer.GCID passthrough) |
| InstrumentID | int | Staking-eligible crypto instrument. 9 instruments: ADA/ATOM/DOT/ETH/NEAR/POL/SOL/SUI/TRX. (Tier 2) |
| Currency | varchar | Crypto ticker (ADA, ETH, SOL, etc.). (Tier 2) |
| PositionID | bigint | Position contributing to the staking pool. (Tier 2 — BI_DB_PositionPnL passthrough) |
| Effective_OpenDate | date | Adjusted open date: MAX(staking_start_date - IntroDays, actual_open_date). (Tier 2 — ETL-computed) |
| Effective_CloseDate | date | Adjusted close date: MIN(staking_end_date, actual_close_date). (Tier 2 — ETL-computed) |
| Eligible_Staking_Days | int | Days position was eligible: DATEDIFF(Effective_OpenDate, Effective_CloseDate) + 1. (Tier 2 — ETL-computed) |
| Total_USD | decimal | USD value of the staked position (SUM of units_invested_USD over eligible days). Contributes to pool denominator. (Tier 2 — ETL-computed from BI_DB_PositionPnL) |
| IsClientEligible | bit | 1 = fully eligible for rewards. AND of all eligibility flags. (Tier 2 — ETL-computed) |
| PlayerLevel | varchar | Client's tier label (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond). (Tier 2 — join-enriched from Dim_PlayerLevel) |
| RevShare | decimal | Client's reward share fraction (0.45–0.90). Determined by PlayerLevel. (Tier 2 — ETL-computed) |
| Country | varchar | Client country name. Used for IsEligibleCountry determination. (Tier 2 — join-enriched from Dim_Customer) |
| IsEligibleCountry | bit | 1 = country is eligible for staking rewards. (Tier 2 — ETL-computed) |
| IsCashEquivalentCountry | bit | 1 = client receives cash instead of crypto airdrop (e.g., Hungary). (Tier 2 — ETL-computed) |
| IsEtorian | bit | 1 = eToro employee — excluded from rewards. (Tier 2 — ETL-computed from Dim_Customer) |
| UK_Prohibited | bit | 1 = UK FCA prohibition for specific coins (per SR-262096). (Tier 2 — ETL-computed) |
| Regulation | varchar | Regulatory entity (EU, UK, AS, etc.). (Tier 2 — join-enriched from Dim_Regulation) |
| IsRegulationEligible | bit | 1 = non-US regulation eligible. RegulationID NOT IN (6,7,8). (Tier 2 — ETL-computed) |
| PlayerStatus | varchar | Account status at staking run time (Active/Inactive/Closed). (Tier 2 — ETL-computed) |
| IsAML_Restricted | bit | 1 = AML-blocked client. (Tier 2 — ETL-computed from Dim_Customer) |
| IsAccountStatusEligible | bit | 1 = account status is active. (Tier 2 — ETL-computed) |
| IsWaiver | bit | 1 = client opted out for this position (non-ETH coins). (Tier 2 — ETL-computed from Dealing_Staking_OptedOut) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). (Tier 2 — ETL metadata) |
| IsPI | bit | 1 = Popular Investor (GuruStatusID IN (5,6)). PIs are excluded from staking. (Tier 2 — ETL-computed) |
| IsOptedIn_ETH | bit | ETH-specific opt-in flag. ETH is opt-in OFF by default; all other coins default ON. (Tier 2 — ETL-computed from Dealing_Staking_OptedOut) |
| NonEligible_PrimaryReason | varchar | First failing eligibility check when IsClientEligible=0. NULL when eligible. (Tier 2 — ETL-computed) |
| IntroDays | int | Grace period days before staking start (from Dealing_Staking_Parameters per instrument). (Tier 2 — passthrough) |

## 5. Lineage

| Source | Role |
|--------|------|
| `BI_DB_dbo.BI_DB_PositionPnL` | Position data (PositionID, units_invested_USD, open/close dates) |
| `Dealing_staging.Fivetran_google_sheets_platform_rewards` | Staking config per month (dates, InstrumentID, IntroDays) |
| `Dealing_dbo.Dealing_Staking_Parameters` | IntroDays per instrument |
| `DWH_dbo.Dim_Customer` + `Fact_SnapshotCustomer` | Eligibility attributes (country, regulation, AML, IsEtoro, GuruStatusID) |
| `DWH_dbo.Dim_PlayerLevel` | RevShare brackets |
| `Dealing_dbo.Dealing_Staking_OptedOut` | Per-position opt-in/opt-out waiver status |

**ETL:** `Dealing_dbo.SP_Staking` → `Dealing_dbo.Dealing_Staking_Position`

**Coverage:** September 2023 to present (event-driven monthly refresh).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_Results` | Downstream: aggregates Dealing_Staking_Position to CID×instrument level |
| `Dealing_dbo.Dealing_Staking_Summary` | Further downstream: summarizes to instrument×month level |
| `Dealing_dbo.Dealing_Staking_Parameters` | Config source: IntroDays per instrument |

## 7. Sample Queries

```sql
-- Pool size by instrument for Feb 2026 (eligible positions only)
SELECT Currency, COUNT(*) AS positions, SUM(Total_USD) AS pool_usd
FROM Dealing_dbo.Dealing_Staking_Position
WHERE StakingYear = 2026 AND StakingMonth = 'February'
  AND IsClientEligible = 1
GROUP BY Currency
ORDER BY pool_usd DESC

-- ETH opt-in rate (ETH requires explicit opt-in)
SELECT StakingYear, StakingMonth,
    COUNT(*) AS total_eth_positions,
    SUM(CAST(IsOptedIn_ETH AS INT)) AS opted_in,
    CAST(SUM(CAST(IsOptedIn_ETH AS INT)) AS FLOAT) / COUNT(*) AS opt_in_rate
FROM Dealing_dbo.Dealing_Staking_Position
WHERE Currency = 'ETH'
  AND LEN(CAST(StakingMonthID AS VARCHAR)) = 6
GROUP BY StakingYear, StakingMonth
ORDER BY StakingYear DESC, StakingMonth
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
