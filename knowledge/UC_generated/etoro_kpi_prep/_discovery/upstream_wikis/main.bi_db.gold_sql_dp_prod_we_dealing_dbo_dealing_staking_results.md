# Dealing_Staking_Results

## 1. Business Meaning

Client-level staking rewards table — one row per client (CID) per instrument per staking month. This is the central output of the staking pipeline: it records how much crypto each eligible client earns, how much eToro retains, and whether the airdrop was successfully delivered.

Written by `SP_Staking` as part of the same monthly run that produces `Dealing_Staking_Position`. `Dealing_Staking_Results` is the aggregation of eligible positions from `Dealing_Staking_Position` into a single per-client reward allocation.

**Scale and activity:** September 2023 to present (latest = Feb 2026). **20.4 million rows**. 9 instruments × ~1.5M eligible clients per month.

**Key fields:**
- `Client_Airdrop` — crypto units allocated to the client (based on pool share × RevShare)
- `Etoro_Amount` — crypto units retained by eToro
- `IsAirdropSuccess` — delivery status (NULL = not yet run, 1 = delivered, 0 = failed)
- `ClubCategory` — client's Club tier (Silver/Gold/Platinum/Diamond & Platinum Plus), relevant for reduced commission eligibility

**Granularity:** CID × InstrumentID × StakingMonthID. One client can appear up to 9 times (once per staking instrument) per month.

## 2. Business Logic

### 2.1 Reward Allocation Formula

Each client's reward is proportional to their share of the total eligible staking pool, modified by their RevShare bracket:

```
Raw_Staking_Amount = SUM(Total_USD × Eligible_Staking_Days / TotalStakingDays)
  for all eligible positions of this CID × instrument

Client_Airdrop = (Raw_Staking_Amount / SUM_ALL(Raw_Staking_Amount))
               × RewardsToDistribute
               × RevShare

Etoro_Amount = (Raw_Staking_Amount / SUM_ALL(Raw_Staking_Amount))
             × RewardsToDistribute
             × (1 - RevShare)
```

where `RewardsToDistribute` comes from the Fivetran google_sheets configuration.

### 2.2 RevShare Brackets

| Tier | RevShare | Client gets | eToro gets |
|------|----------|-------------|------------|
| Bronze | 45% | 45% | 55% |
| Silver | 55% | 55% | 45% |
| Gold | 65% | 65% | 35% |
| Platinum | 75% | 75% | 25% |
| Platinum Plus | 85% | 85% | 15% |
| Diamond | 90% | 90% | 10% |

### 2.3 USD Conversion

```sql
USD_Compensation = Client_Airdrop × USD_ConversionRate  -- at staking_end_date
Etoro_Amount_USD = Etoro_Amount × USD_ConversionRate
```

`USD_ConversionRate` = BidSpreaded from `DWH_dbo.Fact_CurrencyPriceWithSplit` at `OccurredDateID = staking_end_date`.

### 2.4 Airdrop Execution Fields

After the monthly SP run, the airdrop fields are NULL (airdrop not yet executed). After the distribution process runs:
- `AirdropID` — transaction ID
- `AirdropOccurred` — actual distribution date
- `IsAirdropSuccess` — 1 = delivered, 0 = failed
- `ActualAirdropUnits` — actual units transferred (may differ from Client_Airdrop due to rounding)
- `FailReasonID` — reason code if failed

### 2.5 Cash vs Crypto Compensation

`OriginalCompensationType` = 'Cash' for clients in cash-equivalent countries (e.g., Hungary). These clients receive a USD credit rather than a crypto airdrop. `ActualCompensationType` reflects the final delivery method, which may differ if an override occurred.

### 2.6 StakingMonthID Bug

Same malformed 7-digit IDs as in `Dealing_Staking_Position`: `2025100` (October 2025) and `2024100` (October 2024) are malformed. Use `StakingYear + StakingMonth` for temporal filtering.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, **20.4 million rows**. Filter on `StakingYear` + `StakingMonth` first.

**⚠️ Do NOT use `MAX(StakingMonthID)`** — malformed IDs will be returned. Same workaround as `Dealing_Staking_Position`.

```sql
-- Client rewards for ETH in Feb 2026 (top 10 by award size)
SELECT CID, Client_Airdrop, Etoro_Amount, USD_Compensation, RevShare, ClubCategory
FROM Dealing_dbo.Dealing_Staking_Results
WHERE StakingYear = 2026 AND StakingMonth = 'February'
  AND Currency = 'ETH'
  AND IsEligible = 1
ORDER BY Client_Airdrop DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY

-- Airdrop delivery status by instrument for a month
SELECT Currency, IsAirdropSuccess,
    COUNT(*) AS clients,
    SUM(Client_Airdrop) AS total_units_airdropped
FROM Dealing_dbo.Dealing_Staking_Results
WHERE StakingYear = 2026 AND StakingMonth = 'February'
GROUP BY Currency, IsAirdropSuccess
ORDER BY Currency, IsAirdropSuccess
```

**Ineligible clients are included** — `IsEligible = 0` rows are present with `NonEligible_PrimaryReason` populated. Filter `WHERE IsEligible = 1` for pool/reward analysis.

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking month key (YYYYMM). ⚠️ Malformed 7-digit IDs for Oct-2024 (2024100) and Oct-2025 (2025100). Use StakingYear+StakingMonth. (Tier 2) |
| StakingMonth | varchar | Month name (January–December). (Tier 2) |
| StakingYear | int | Calendar year. (Tier 2) |
| InstrumentID | int | Crypto instrument. (Tier 2) |
| Currency | varchar | Crypto ticker. (Tier 2) |
| CID | int | Client account ID. (Tier 2) |
| GCID | int | Group/household customer ID. (Tier 2) |
| IsEligible | bit | 1 = meets all eligibility criteria. (Tier 2 — ETL-computed) |
| NonEligible_PrimaryReason | varchar | First failing eligibility check when IsEligible=0. NULL when eligible. (Tier 2 — ETL-computed) |
| Raw_Staking_Amount | decimal | Client's proportional share of the total staking pool (USD, weighted by eligible days). (Tier 2 — ETL-computed from Dealing_Staking_Position) |
| RevShare | decimal | Client's reward fraction (0.45–0.90) from PlayerLevel bracket. (Tier 2 — passthrough from Dealing_Staking_Position) |
| Client_Airdrop | decimal | Crypto units allocated to the client: pool_share × RewardsToDistribute × RevShare. (Tier 2 — ETL-computed) |
| Etoro_Amount | decimal | Crypto units retained by eToro: pool_share × RewardsToDistribute × (1-RevShare). (Tier 2 — ETL-computed) |
| OriginalCompensationType | varchar | 'Crypto' or 'Cash'. Cash for clients in cash-equivalent countries (e.g., Hungary). (Tier 2 — ETL-computed) |
| USD_Compensation | decimal | USD value of Client_Airdrop at staking_end_date exchange rate. (Tier 2 — ETL-computed) |
| Etoro_Amount_USD | decimal | USD value of Etoro_Amount at staking_end_date exchange rate. (Tier 2 — ETL-computed) |
| AirdropID | bigint | Airdrop transaction identifier. NULL before distribution runs. (Tier 2 — passthrough from airdrop execution) |
| AirdropOccurred | datetime | Actual distribution date. NULL before distribution. (Tier 2 — passthrough) |
| IsAirdropSuccess | bit | 1 = delivered; 0 = failed; NULL = not yet run. (Tier 2 — ETL-computed from airdrop execution) |
| FailReasonID | int | Fail reason code when IsAirdropSuccess=0. NULL when successful or not run. (Tier 2 — ETL-computed) |
| ActualAirdropUnits | decimal | Actual units transferred. May differ from Client_Airdrop due to rounding. NULL before distribution. (Tier 2) |
| ActualCompensationType | varchar | Final delivery method. May differ from OriginalCompensationType if override applied. (Tier 2) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). (Tier 2 — ETL metadata) |
| ClubCategory | varchar | Client's Club tier (Silver/Gold/Platinum/Diamond & Platinum Plus). Based on ≤40 USD holdings threshold. (Tier 2 — join-enriched from Dealing_Staking_Club) |

## 5. Lineage

| Source | Role |
|--------|------|
| `Dealing_dbo.Dealing_Staking_Position` | Pre-computed eligibility and pool contribution per position |
| `Dealing_staging.Fivetran_google_sheets_platform_rewards` | RewardsToDistribute config |
| `DWH_dbo.Dim_CustomerStakingAirdrop` (or equiv.) | Airdrop execution results post-distribution |
| `Dealing_dbo.Dealing_Staking_Club` | ClubCategory enrichment |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | USD conversion rate at staking_end_date |

**ETL:** `Dealing_dbo.SP_Staking` → `Dealing_dbo.Dealing_Staking_Results`

**Coverage:** September 2023 to present (monthly event-driven refresh).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_Position` | Source — position-level eligibility feeding into this CID-level result |
| `Dealing_dbo.Dealing_Staking_Summary` | Downstream — aggregates this to instrument×month level |

## 7. Sample Queries

```sql
-- Revenue share by instrument (eToro vs client split)
SELECT Currency,
    SUM(Client_Airdrop) AS client_total,
    SUM(Etoro_Amount) AS etoro_total,
    AVG(RevShare) AS avg_rev_share
FROM Dealing_dbo.Dealing_Staking_Results
WHERE StakingYear = 2026 AND StakingMonth = 'February'
  AND IsEligible = 1
GROUP BY Currency
ORDER BY client_total DESC

-- Failed airdrop analysis
SELECT Currency, FailReasonID, COUNT(*) AS failed_clients,
    SUM(Client_Airdrop) AS units_not_delivered
FROM Dealing_dbo.Dealing_Staking_Results
WHERE StakingYear = 2026 AND StakingMonth = 'February'
  AND IsAirdropSuccess = 0
GROUP BY Currency, FailReasonID
ORDER BY failed_clients DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
