# Dealing_dbo.Dealing_Staking_Position_US

> US-market position-level staking detail table — one row per eligible position per staking month, containing eligibility flags, opt-in/out dates, and weighted staking days for US clients (FinCEN+FINRA regulated). US-only counterpart to Dealing_Staking_Position.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_Staking_US (also writes Results_US, Summary_US, Club_US) |
| **Refresh** | Event-driven: triggered when Fivetran updates platform_rewards for is_us=1 (typically monthly post-staking-period) |
| **Row Count** | ~592K (2025-01 through 2026-01) |
| **Temporal Coverage** | 2025 — present (new; launched Aug 2025 per SR-325088) |
| **Instruments** | ADA, ETH (InstrumentID=100001), SOL — 3 instruments |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |

---

## 1. Business Meaning

This is the **CS-support / CS-dashboard table** for the US crypto staking program. It provides per-position, per-client eligibility detail so Customer Support and Finance can verify why a client did or did not receive staking rewards.

**US program key differences from global staking**:
- **US-only**: RegulationID=8 (FinCEN+FINRA) clients only
- **Opt-in/out source**: US enrollment tables (`External_USABroker_Apex_UserProgramEnrolment`, `External_USABroker_History_UserProgramEnrolment`) instead of global waivers
- **Non-ETH assets**: opted IN by default (UserProgramID=2); clients must opt OUT
- **ETH**: opted OUT by default (UserProgramID=3); clients must opt IN
- **No copy positions**: MirrorID=0 filter; copy trades do not earn US staking rewards
- **IntroDays**: minimum holding period before position qualifies (in Dealing_Staking_Parameters_US)
- **Excluded states**: Nevada, Hawaii (Alabama was excluded then re-included per SR-339857)
- **GCID**: US program uses Global Customer ID across multiple accounts

---

## 2. Business Logic

### 2.1 Eligible_Staking_Days

```
Effective_OpenDate = GREATEST(
  OpenDate + IntroDays + 1,      -- must hold for IntroDays before qualifying
  FirstTimeIn + IntroDays + 1,   -- intro period also applies after opt-in
  StakingStartDate               -- cannot earn before period starts
)

Effective_CloseDate = LEAST(
  CloseOccurred / NULL,  -- position's actual close (NULL = still open at period end)
  LastTimeIn,            -- opt-out date
  StakingEndDate         -- cannot earn after period ends
)

Eligible_Staking_Days = DATEDIFF(Effective_CloseDate, Effective_OpenDate) + 1
```

Only positions where `Eligible_Staking_Days > 0` appear in this table.

### 2.2 Eligibility Flags

| Flag | Condition |
|---|---|
| IsClientEligible=0 | IsEligibleCountry=0 OR IsEtorian=1 OR IsAML_Restricted=1 OR IsAccountStatusEligible=0 |
| IsEligibleCountry=0 | State in excluded list (Nevada, Hawaii) |
| IsEtorian=1 | CountryID=250 (eToro employees) |
| IsAML_Restricted=1 | PlayerStatusID IN (2,9,15,4) or specific SubReasonID values |
| IsAccountStatusEligible=0 | AccountStatusID=2 (suspended/closed) |
| IsWaiver=1 | Opted out before StakingEndDate |

### 2.3 ETH vs Non-ETH Opt-In Logic

- **Non-ETH (ADA, SOL)**: default IsOptedIn=1. The opt-out window and history is tracked via UserProgramID=2 (CryptoStaking).
- **ETH**: default IsOptedIn=0. The opt-in window is tracked via UserProgramID=3 (EthStaking). ETH position only earns if explicitly opted in for the full duration.

---

## 3. Columns

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking month identifier (6-digit YYYYMM, e.g. 202601); see StakingMonthID bug note (Tier 4 — Fivetran) |
| StakingMonth | varchar(50) | Month name string (e.g. "January") (Tier 2 — computed) |
| StakingYear | int | Staking year (Tier 2 — computed) |
| CID | bigint | Customer ID (Tier 1 — DWH_dbo.Dim_Position) |
| GCID | bigint | Global Customer ID — links a client across multiple eToro accounts; used for opt-in/out tracking across accounts (Tier 2 — DWH_dbo.Dim_Customer) |
| InstrumentID | int | Staking instrument (ADA, ETH=100001, SOL) (Tier 1 — DWH_dbo.Dim_Position) |
| Currency | varchar(50) | Ticker symbol of the staking asset (ADA/ETH/SOL) (Tier 4 — Fivetran) |
| PositionID | bigint | Individual position identifier (Tier 1 — DWH_dbo.Dim_Position) |
| Effective_OpenDate | date | Adjusted open date accounting for intro period and opt-in timing (Tier 2 — computed) |
| Effective_CloseDate | date | Adjusted close date accounting for opt-out and staking period end (Tier 2 — computed) |
| Eligible_Staking_Days | int | Number of days this position contributes to reward calculation; must be > 0 (Tier 2 — computed) |
| Total_USD | decimal(38,6) | CID-level USD-denominated staking amount (shared across all positions for this CID×instrument) (Tier 2 — computed) |
| IsClientEligible | int | 1 = client passes all eligibility checks; 0 = excluded (see NonEligible reason in Results_US) (Tier 2 — computed) |
| PlayerLevel | varchar(100) | Player tier: Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond (Tier 1 — DWH_dbo.Dim_PlayerLevel) |
| RevShare | decimal(16,4) | Client's revenue share fraction: B=0.45, S=0.55, G=0.65, P=0.75, PP=0.85, D=0.90 (Tier 2 — computed) |
| Country | varchar(100) | Client's country of residence (Tier 1 — DWH_dbo.Dim_Country) |
| IsEligibleCountry | int | 1 = eligible country/state; 0 = excluded state (Nevada, Hawaii) (Tier 2 — computed) |
| IsCashEquivalentCountry | int | 1 = client receives USD credit instead of crypto airdrop (Tier 2 — computed) |
| IsEtorian | int | 1 = eToro employee (CountryID=250); excluded from staking (Tier 2 — computed) |
| UK_Prohibited | int | Always 0 for US clients — legacy field from global version, not applicable (Tier 2 — hardcoded) |
| Regulation | varchar(100) | Regulation name: FinCEN or FinCEN+FINRA (Tier 1 — DWH_dbo.Dim_Regulation) |
| IsRegulationEligible | int | 1 = RegulationID=8 (FinCEN+FINRA); FinCEN-only clients (RegulationID=6,7) are ineligible (Tier 2 — computed) |
| PlayerStatus | varchar(100) | Account status description (Tier 1 — DWH_dbo.Dim_PlayerStatus) |
| IsAML_Restricted | int | 1 = AML/compliance restriction applies; client excluded from staking (Tier 2 — computed) |
| IsAccountStatusEligible | int | 1 = account is active; 0 = suspended/closed (AccountStatusID=2) (Tier 2 — computed) |
| IsWaiver | int | 1 = client opted out before staking period end (position ineligible due to waiver) (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 — GETDATE()) |
| IsPI | int | Reserved field — always NULL; PI status is checked in Eligible_Pool filter but not stored (Tier 2 — NULL) |
| IsOptedIn_ETH | int | Reserved field — always NULL; ETH opt-in state is used in calculation but not stored here (Tier 2 — NULL) |

---

## 4. Usage Notes

- **StakingMonthID bug** (inherited from global tables): Months with 2-digit numbers padded incorrectly → 7-digit IDs (e.g., 2025030 for March 2025). Always use `StakingYear + StakingMonth` for temporal ordering.
- **No copy positions**: MirrorID=0 filter in SP — CopyTrading positions do not earn US staking rewards.
- **Position-level duplicates**: One row per position (PositionID), not per CID. A client with 5 ADA positions will have 5 rows. Use Dealing_Staking_Results_US for CID-level aggregates.
- **IsPI/IsOptedIn_ETH are NULL**: These DDL columns are reserved but not populated by the current SP version.

---

## 5. Relationships

| Relation | Table | Join Key | Notes |
|---|---|---|---|
| CID-level roll-up | Dealing_Staking_Results_US | StakingMonthID + CID + InstrumentID | Aggregate from position level |
| Period overview | Dealing_Staking_Summary_US | StakingMonthID + InstrumentID | Summary stats |
| Holdings threshold | Dealing_Staking_Club_US | StakingMonthID + InstrumentID + PlayerLevel | $1 minimum threshold |
| US parameters | Dealing_Staking_Parameters_US | InstrumentID | IntroDays, Distribution_StartDate |
| Global counterpart | Dealing_Staking_Position | StakingMonthID + PositionID | Non-US equivalent |
