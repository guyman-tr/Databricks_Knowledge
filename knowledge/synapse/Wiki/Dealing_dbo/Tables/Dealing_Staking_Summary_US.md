# Dealing_dbo.Dealing_Staking_Summary_US

> US-market staking overview table — one row per instrument per staking month, aggregating total rewards distributed, eToro yield, annualized return, and utilization metrics for the US crypto staking program. US-only counterpart to Dealing_Staking_Summary.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_Staking_US (also writes Position_US, Results_US, Club_US) |
| **Refresh** | Event-driven: monthly when Fivetran updates platform_rewards with is_us=1 |
| **Row Count** | 14 rows (3 instruments × ~5 months through 2026-01) |
| **Temporal Coverage** | 2025 — present |
| **Instruments** | ADA, ETH (InstrumentID=100001), SOL |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |

---

## 1. Business Meaning

This is the **finance and management dashboard table** for the US staking program. Each row summarizes one instrument's distribution for the month: how much was distributed to clients, how much eToro retained, the effective yield, and what fraction of rewards went unused (rounding residual).

**Key finance metrics**:
- `EtoroYield` = RewardsToDistribute × TotalStakingDays / MonthlyPool — the implied yield eToro earns on the staking pool
- `AnnualizedYield` = (1 + RewardsToDistribute / MonthlyPool)^365 − 1 — annualized compounding rate
- `MonthlyPool` = SUM(AmountInUnitsDecimal × Eligible_Staking_Days) across all eligible positions — the denominator for all pro-rata reward calculations

**Additions vs Dealing_Staking_Summary (global)**:
- `MonthlyPool`: the total weighted eligible units pool (not in global Summary)
- `IntroDays`: mandatory holding period before qualifying (US-specific parameter)

---

## 2. Columns

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking month ID (6-digit YYYYMM); see StakingMonthID bug note (Tier 4 — Fivetran) |
| StakingMonth | varchar(100) | Month name string (Tier 2 — computed) |
| StakingYear | int | Year (Tier 2 — computed) |
| InstrumentID | int | Staking instrument ID (Tier 4 — Fivetran) |
| Currency | varchar(100) | Asset ticker (ADA/ETH/SOL) (Tier 4 — Fivetran) |
| StakingStartDate | date | First day of the staking period (Tier 4 — Fivetran) |
| StakingEndDate | date | Last day of the staking period (Tier 4 — Fivetran) |
| NetworkReportedRewards | decimal(38,8) | Total blockchain rewards for the period as reported by the network (Tier 4 — Fivetran) |
| RewardsToDistribute | decimal(38,8) | Portion of network rewards that eToro distributes to clients (Tier 4 — Fivetran) |
| USD_ConversionRate | decimal(38,8) | BidSpreaded price of the asset in USD at StakingEndDate — single point-in-time rate for all USD columns (Tier 2 — DWH_dbo.Fact_CurrencyPriceWithSplit) |
| RewardsToDistribute_USD | decimal(38,8) | RewardsToDistribute × USD_ConversionRate (Tier 2 — computed) |
| ClientUnits | decimal(38,8) | Total crypto units to distribute to clients (SUM of Client_Airdrop) (Tier 2 — computed) |
| EtoroUnits | decimal(38,8) | Total crypto units retained by eToro (Tier 2 — computed) |
| ClientUSD | decimal(38,8) | Total USD value distributed to eligible clients (Tier 2 — computed) |
| EtoroUSD | decimal(38,8) | eToro's total amount in USD (Tier 2 — computed) |
| ClientPercent | decimal(16,8) | ClientUnits / (ClientUnits + EtoroUnits) (Tier 2 — computed) |
| EtoroPercent | decimal(16,8) | EtoroUnits / (ClientUnits + EtoroUnits) (Tier 2 — computed) |
| UtilizedUnits | decimal(38,8) | SUM(Raw_Staking_Amount) — total allocated to CIDs before RevShare split (Tier 2 — computed) |
| UnutilizedUnits | decimal(38,8) | RewardsToDistribute − UtilizedUnits — rounding residual (Tier 2 — computed) |
| UtilizedPercent | decimal(16,8) | UtilizedUnits / RewardsToDistribute (Tier 2 — computed) |
| UnutilizedPercent | decimal(16,8) | 1 − UtilizedPercent (Tier 2 — computed) |
| IneligibleCustomerRewards | decimal(38,8) | SUM(Etoro_Amount) where IsEligible=0 — rewards that went to eToro because client was ineligible (Tier 2 — computed) |
| RevShareCommission | decimal(38,8) | SUM(Etoro_Amount) where IsEligible=1 — eToro's RevShare from eligible clients (Tier 2 — computed) |
| PercentUnutilized | decimal(16,8) | UnutilizedUnits / EtoroUnits (Tier 2 — computed) |
| PercentIneligible | decimal(16,8) | IneligibleCustomerRewards / EtoroUnits (Tier 2 — computed) |
| PercentRevShare | decimal(16,8) | RevShareCommission / EtoroUnits (Tier 2 — computed) |
| EtoroYield | decimal(38,8) | RewardsToDistribute × TotalStakingDays / MonthlyPool — implied yield for the period (Tier 2 — computed) |
| AnnualizedYield | decimal(38,8) | (1 + RewardsToDistribute / MonthlyPool)^365 − 1 — annualized compounding rate (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 — GETDATE()) |
| MonthlyPool | decimal(32,6) | Total weighted eligible units: SUM(AmountInUnitsDecimal × Eligible_Staking_Days); denominator for all pro-rata reward calculations (Tier 2 — computed) |
| IntroDays | int | Minimum days a position must be held before it qualifies for staking rewards (Tier 4 — Dealing_Staking_Parameters_US) |

---

## 3. Usage Notes

- **Very small table** (14 rows): one row per instrument per staking month; safe to query without filters.
- **USD_ConversionRate** is a single end-of-period rate — all USD columns use the same snapshot price.
- **PercentUnutilized + PercentIneligible + PercentRevShare = 1.0** (approx — three mutually exhaustive categories of EtoroUnits).
- **MonthlyPool**: the key metric that drives all pro-rata calculations. Larger pool → smaller individual awards per unit.
- **IntroDays**: currently varies by instrument in US parameters. Check Dealing_Staking_Parameters_US for current values.
- **StakingMonthID bug**: same 7-digit malformation as other staking tables. Use StakingYear+StakingMonth.

---

## 4. Relationships

| Relation | Table | Join Key | Notes |
|---|---|---|---|
| CID detail | Dealing_Staking_Results_US | StakingMonthID + InstrumentID | Roll-up source |
| Position detail | Dealing_Staking_Position_US | StakingMonthID + InstrumentID | Granular positions |
| Holdings threshold | Dealing_Staking_Club_US | StakingMonthID + InstrumentID + PlayerLevel | $1 min threshold |
| US parameters | Dealing_Staking_Parameters_US | InstrumentID | Source of IntroDays and Distribution_StartDate |
| Global counterpart | Dealing_Staking_Summary | StakingMonthID + InstrumentID | Non-US equivalent |
