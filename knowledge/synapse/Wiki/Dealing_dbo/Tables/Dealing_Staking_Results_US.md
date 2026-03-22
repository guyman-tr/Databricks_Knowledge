# Dealing_dbo.Dealing_Staking_Results_US

> US-market CID-level staking results table — one row per client per instrument per staking month, containing eligibility, computed airdrop amounts, RevShare split, and airdrop execution status for US clients (FinCEN+FINRA). US-only counterpart to Dealing_Staking_Results.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_Staking_US (also writes Position_US, Summary_US, Club_US) |
| **Refresh** | Event-driven: monthly when Fivetran updates platform_rewards with is_us=1 |
| **Row Count** | ~122K (2025 — 2026) |
| **Temporal Coverage** | 2025 — present |
| **Instruments** | ADA, ETH (InstrumentID=100001), SOL |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |

---

## 1. Business Meaning

This is the **primary distribution table** for the US staking program — one row per CID×instrument×month aggregates eligibility and reward amounts. Finance and operations use this to:
- Determine who receives an airdrop and how much (`Client_Airdrop`, `IsEligible=1`)
- Track actual airdrop execution (`AirdropID`, `IsAirdropSuccess`, `ActualAirdropUnits`)
- Compute eToro's revenue share (`Etoro_Amount`)

**Reward formula**:
```
Raw_Staking_Amount = (CID_Units × Days) / SUM(all eligible Units × Days) × RewardsToDistribute

Client_Airdrop     = Raw_Staking_Amount × RevShare     (if IsEligible=1, else 0)
Etoro_Amount       = Raw_Staking_Amount × (1-RevShare) (if eligible)
                   = Raw_Staking_Amount                (if ineligible — all goes to eToro)
```

**$1 minimum threshold**: `USD_Compensation < 1` → IsPositionEligible=0 (NonEligible_PrimaryReason='Less than $1'). Use `Dealing_Staking_Club_US` to find the holding threshold needed to cross $1.

---

## 2. Columns

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking month ID (6-digit YYYYMM); see StakingMonthID bug note (Tier 4 — Fivetran) |
| StakingMonth | varchar(100) | Month name string (Tier 2 — computed) |
| StakingYear | int | Year (Tier 2 — computed) |
| InstrumentID | int | Staking instrument ID (Tier 4 — Fivetran) |
| Currency | varchar(100) | Asset ticker (ADA/ETH/SOL) (Tier 4 — Fivetran) |
| CID | bigint | Customer ID (Tier 1 — DWH_dbo.Dim_Position) |
| GCID | bigint | Global Customer ID (Tier 2 — DWH_dbo.Dim_Customer) |
| IsEligible | int | 1 = client AND position passed all eligibility checks; receives Client_Airdrop (Tier 2 — computed) |
| NonEligible_PrimaryReason | varchar(100) | First matched exclusion: Country/Etorian/AML Restricted/Account Status/Less than $1/Waiver (Tier 2 — computed) |
| Raw_Staking_Amount | decimal(38,8) | CID's pro-rata share of RewardsToDistribute before RevShare split: (Units×Days / TotalPool) × Rewards (Tier 2 — computed) |
| RevShare | decimal(16,4) | Client's revenue share fraction by player tier (Tier 2 — computed) |
| Client_Airdrop | decimal(38,8) | Crypto units to airdrop to client; 0 if IsEligible=0 (Tier 2 — computed) |
| Etoro_Amount | decimal(38,8) | eToro's share: Raw × (1-RevShare) if eligible; Raw if ineligible (all ineligible rewards stay with eToro) (Tier 2 — computed) |
| OriginalCompensationType | varchar(100) | Intended form at calculation time: Airdrop / Cash (IsCashEquivalentCountry=1) / None (ineligible) (Tier 2 — computed) |
| USD_Compensation | decimal(38,8) | Client_Airdrop converted to USD at StakingEndDate price; basis for $1 minimum threshold check (Tier 2 — computed) |
| Etoro_Amount_USD | decimal(38,8) | eToro's share in USD (Tier 2 — computed) |
| AirdropID | int | Airdrop execution record ID — NULL until airdrop is processed post-calculation (Tier 2 — updated post-run) |
| AirdropOccurred | date | Date airdrop was executed — always NULL on initial insert; updated post-execution (Tier 2 — updated post-run) |
| IsAirdropSuccess | int | 1 = airdrop delivered successfully — NULL until executed (Tier 2 — updated post-run) |
| FailReasonID | int | Airdrop failure reason ID — NULL if successful or not yet processed (Tier 2 — updated post-run) |
| ActualAirdropUnits | decimal(38,8) | Actual crypto units delivered — NULL until executed (Tier 2 — updated post-run) |
| ActualCompensationType | varchar(100) | Actual form: '' (pending airdrop) / Cash / None (ineligible) (Tier 2 — computed/updated) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 — GETDATE()) |
| ClubCategory | varchar(150) | Player tier grouping for $1 threshold table: Bronze / Silver+Gold+Platinum / Diamond+Platinum Plus (Tier 2 — computed) |

---

## 3. Usage Notes

- **IsEligible=1 → receives Client_Airdrop**: Join to Dealing_Staking_Club_US for minimum holding threshold context.
- **Post-execution columns** (AirdropID, AirdropOccurred, IsAirdropSuccess, FailReasonID, ActualAirdropUnits): NULL on initial calculation run; updated by the airdrop execution system.
- **Cash-equivalent clients** (IsCashEquivalentCountry=1): receive USD credit instead of crypto. OriginalCompensationType='Cash'. Tracked in eToro's finance system.
- **GCID**: Required for US program tracking across multiple accounts; a client may have multiple CIDs sharing one GCID.
- **StakingMonthID bug**: 7-digit malformed IDs for months Oct/Mar. Use StakingYear + StakingMonth for ordering.

---

## 4. Relationships

| Relation | Table | Join Key | Notes |
|---|---|---|---|
| Position detail | Dealing_Staking_Position_US | StakingMonthID + CID + InstrumentID | Per-position breakdown |
| Period overview | Dealing_Staking_Summary_US | StakingMonthID + InstrumentID | Instrument-month summary |
| Holdings threshold | Dealing_Staking_Club_US | StakingMonthID + InstrumentID + ClubCategory | Avg daily holdings for $1 threshold |
| Global counterpart | Dealing_Staking_Results | StakingMonthID + CID + InstrumentID | Non-US equivalent |
