# Dealing_Staking_Summary

## 1. Business Meaning

Instrument-level staking summary — one row per crypto instrument per staking month. The top-level aggregate of the staking pipeline, consolidating all client-level distributions (`Dealing_Staking_Results`) into a single management-view row per instrument.

This is the go-to table for finance, management, and compliance reporting on staking: how many crypto units were distributed to clients, how many eToro retained, what the USD values were, and what yield eToro achieved from the staking program.

**Scale and activity:** 158 rows total (9 instruments × ~18 months from September 2023 to February 2026). **One row per instrument per staking month.** Very small table — suitable for direct dashboard consumption.

**Key metrics in this table:**
- `RewardsToDistribute` — total pool for the month (from blockchain/Google Sheets config)
- `ClientUnits` / `EtoroUnits` — split of rewards between clients and eToro
- `MonthlyPool` — total USD value of all staked positions (pool denominator for yield)
- `EtoroYield` / `AnnualizedYield` — eToro's profitability metric from the staking program
- `ClientPercent` / `EtoroPercent` — weighted average split rates

**Current instruments (Feb 2026):** ADA, ATOM, DOT, ETH, NEAR, POL, SOL, SUI, TRX.

## 2. Business Logic

### 2.1 Aggregation from Dealing_Staking_Results

```sql
ClientUnits = SUM(Client_Airdrop)     -- from Dealing_Staking_Results
EtoroUnits  = SUM(Etoro_Amount)       -- from Dealing_Staking_Results
```

### 2.2 Pool and Utilization

```sql
MonthlyPool   = SUM(Total_USD) for ALL positions (eligible+ineligible) in Dealing_Staking_Position
UtilizedUnits = SUM(Total_USD) for eligible + opted-in positions only
UnutilizedUnits = MonthlyPool - UtilizedUnits
UtilizedPercent = UtilizedUnits / MonthlyPool
```

"Unutilized" = positions that were in the pool but whose holders were ineligible or opted out. This crypto was not distributed; eToro retains the network rewards associated with it as `IneligibleCustomerRewards`.

### 2.3 eToro Yield Calculation

```sql
EtoroUSD       = EtoroUnits × USD_ConversionRate
MonthlyPool_USD = MonthlyPool (already in USD from Dealing_Staking_Position.Total_USD)
EtoroYield     = EtoroUSD / MonthlyPool_USD
AnnualizedYield = EtoroYield × (365 / TotalStakingDays)
```

This yield represents eToro's return from operating the staking program — the fraction of the total pool that eToro retains after distributing client shares.

### 2.4 USD Conversion

`USD_ConversionRate` = `DWH_dbo.Fact_CurrencyPriceWithSplit.BidSpreaded` at `OccurredDateID = staking_end_date`. All USD conversions in this table use the same single end-of-period rate.

### 2.5 StakingMonthID Bug

`StakingMonthID = 2025030` (March 2025) is malformed (7 digits). The actual latest month in the table is February 2026 (StakingMonthID = 202602). `MAX(StakingMonthID)` returns 2025030, not 202602. Use `StakingYear + StakingMonth` for temporal ordering.

### 2.6 PercentUnutilized vs UnutilizedPercent

Two columns cover the same concept — `UnutilizedPercent` (current) and `PercentUnutilized` (historical legacy). These should be equal. `PercentUnutilized` is retained for backward compatibility.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, **158 rows**. Full table scans are essentially free.

**⚠️ Do NOT use `MAX(StakingMonthID)`** — returns malformed 7-digit ID 2025030.

```sql
-- Latest month performance by instrument
SELECT StakingYear, StakingMonth, Currency,
    RewardsToDistribute, ClientUnits, EtoroUnits,
    RewardsToDistribute_USD, ClientUSD, EtoroUSD,
    EtoroYield, AnnualizedYield,
    ClientPercent, UtilizedPercent
FROM Dealing_dbo.Dealing_Staking_Summary
WHERE StakingYear = 2026 AND StakingMonth = 'February'
ORDER BY RewardsToDistribute_USD DESC

-- Annualized yield trend by instrument (last 6 months)
SELECT StakingYear, StakingMonth,
    CASE StakingMonth
      WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3
      WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6
      WHEN 'July' THEN 7 WHEN 'August' THEN 8 WHEN 'September' THEN 9
      WHEN 'October' THEN 10 WHEN 'November' THEN 11 WHEN 'December' THEN 12
    END AS MonthNum,
    Currency, AnnualizedYield
FROM Dealing_dbo.Dealing_Staking_Summary
WHERE LEN(CAST(StakingMonthID AS VARCHAR)) = 6   -- exclude malformed IDs
  AND ((StakingYear = 2025 AND CAST(
      CASE StakingMonth WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3
        WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6
        WHEN 'July' THEN 7 WHEN 'August' THEN 8 WHEN 'September' THEN 9
        WHEN 'October' THEN 10 WHEN 'November' THEN 11 WHEN 'December' THEN 12
      END AS INT) >= 9)
   OR StakingYear = 2026)
ORDER BY StakingYear, MonthNum, Currency
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking month key (YYYYMM). ⚠️ 2025030 (March 2025) is malformed. Use StakingYear+StakingMonth. (Tier 2) |
| StakingMonth | varchar | Month name (January–December). (Tier 2) |
| StakingYear | int | Calendar year. (Tier 2) |
| InstrumentID | int | Crypto instrument. (Tier 2) |
| Currency | varchar | Crypto ticker (ADA/ATOM/DOT/ETH/NEAR/POL/SOL/SUI/TRX). (Tier 2) |
| StakingStartDate | date | Official start of the staking measurement period. (Tier 2 — passthrough from google_sheets) |
| StakingEndDate | date | Official end of the staking measurement period. (Tier 2 — passthrough from google_sheets) |
| NetworkReportedRewards | decimal | Total rewards reported by the blockchain network. (Tier 2 — passthrough from google_sheets) |
| RewardsToDistribute | decimal | Actual rewards to distribute (may include bonus buffer from prior months). (Tier 2 — passthrough) |
| USD_ConversionRate | decimal | Crypto/USD exchange rate at staking_end_date. BidSpreaded from Fact_CurrencyPriceWithSplit. (Tier 2) |
| RewardsToDistribute_USD | decimal | USD value: RewardsToDistribute × USD_ConversionRate. (Tier 2 — ETL-computed) |
| ClientUnits | decimal | Total crypto units distributed to all eligible clients. SUM(Client_Airdrop). (Tier 2 — ETL-computed) |
| EtoroUnits | decimal | Total crypto units retained by eToro. SUM(Etoro_Amount). (Tier 2 — ETL-computed) |
| ClientUSD | decimal | USD value of client distributions: ClientUnits × USD_ConversionRate. (Tier 2 — ETL-computed) |
| EtoroUSD | decimal | USD value of eToro's share: EtoroUnits × USD_ConversionRate. (Tier 2 — ETL-computed) |
| ClientPercent | decimal | Fraction of total rewards going to clients: ClientUnits / RewardsToDistribute. (Tier 2 — ETL-computed) |
| EtoroPercent | decimal | Fraction retained by eToro: EtoroUnits / RewardsToDistribute. (Tier 2 — ETL-computed) |
| UtilizedUnits | decimal | Crypto units from eligible + opted-in positions. Numerator for utilization metrics. (Tier 2 — ETL-computed) |
| UnutilizedUnits | decimal | Crypto units from opted-out or ineligible positions (MonthlyPool - UtilizedUnits). (Tier 2 — ETL-computed) |
| UtilizedPercent | decimal | Pool utilization rate: UtilizedUnits / MonthlyPool. (Tier 2 — ETL-computed) |
| UnutilizedPercent | decimal | Fraction of pool not utilized. Current column (use over PercentUnutilized). (Tier 2 — ETL-computed) |
| IneligibleCustomerRewards | decimal | Rewards that would have gone to ineligible clients — retained by eToro. (Tier 2 — ETL-computed) |
| RevShareCommission | decimal | eToro's RevShare portion specifically. SUM of Etoro_Amount for RevShare model clients. (Tier 2 — ETL-computed) |
| PercentUnutilized | decimal | Legacy duplicate of UnutilizedPercent. Retained for backward compatibility. (Tier 2 — ETL-computed) |
| PercentIneligible | decimal | Fraction of rewards lost to ineligibility: IneligibleCustomerRewards / RewardsToDistribute. (Tier 2 — ETL-computed) |
| PercentRevShare | decimal | Weighted average RevShare rate across all clients: RevShareCommission / ClientUnits. (Tier 2 — ETL-computed) |
| EtoroYield | decimal | eToro's yield as fraction of total pool value: EtoroUSD / MonthlyPool_USD. (Tier 2 — ETL-computed) |
| AnnualizedYield | decimal | Annualized yield: EtoroYield × (365 / TotalStakingDays). Benchmark comparison metric. (Tier 2 — ETL-computed) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). (Tier 2 — ETL metadata) |
| MonthlyPool | decimal | Total USD value of ALL staked positions (eligible+ineligible). Pool denominator for yield calculations. (Tier 2 — ETL-computed from Dealing_Staking_Position) |
| IntroDays | int | Grace period days for this instrument from Dealing_Staking_Parameters. (Tier 2 — passthrough) |

## 5. Lineage

| Source | Role |
|--------|------|
| `Dealing_dbo.Dealing_Staking_Results` | ClientUnits (SUM Client_Airdrop), EtoroUnits (SUM Etoro_Amount), RevShareCommission |
| `Dealing_dbo.Dealing_Staking_Position` | MonthlyPool (SUM Total_USD all positions), UtilizedUnits (eligible positions) |
| `Dealing_staging.Fivetran_google_sheets_platform_rewards` | NetworkReportedRewards, RewardsToDistribute, staking dates |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | USD_ConversionRate at staking_end_date |
| `Dealing_dbo.Dealing_Staking_Parameters` | IntroDays per instrument |

**ETL:** `Dealing_dbo.SP_Staking` (Summary aggregation step) → `Dealing_dbo.Dealing_Staking_Summary`

**Coverage:** September 2023 to present (monthly event-driven refresh).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_Results` | Source — CID-level results aggregated into this summary |
| `Dealing_dbo.Dealing_Staking_Position` | Source — position pool aggregated for MonthlyPool and UtilizedUnits |

## 7. Sample Queries

```sql
-- eToro staking revenue by instrument (all time)
SELECT Currency,
    SUM(EtoroUSD) AS total_etoro_usd,
    AVG(AnnualizedYield) AS avg_annualized_yield,
    COUNT(*) AS months_active
FROM Dealing_dbo.Dealing_Staking_Summary
WHERE LEN(CAST(StakingMonthID AS VARCHAR)) = 6
GROUP BY Currency
ORDER BY total_etoro_usd DESC

-- Client vs eToro split by month
SELECT StakingYear, StakingMonth,
    SUM(ClientUSD) AS total_client_usd,
    SUM(EtoroUSD) AS total_etoro_usd,
    AVG(PercentRevShare) AS avg_rev_share
FROM Dealing_dbo.Dealing_Staking_Summary
WHERE LEN(CAST(StakingMonthID AS VARCHAR)) = 6
GROUP BY StakingYear, StakingMonth
ORDER BY StakingYear DESC, StakingMonth
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
