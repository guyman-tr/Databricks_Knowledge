# Dealing_dbo.Dealing_Staking_Parameters_US

> US crypto staking configuration table — 4-row lookup containing per-instrument parameters (intro days, liquidity buffer, program start dates) for the US staking program. Manually maintained by the Dealing team.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Writer SP** | None — manually maintained configuration |
| **Refresh** | Manual (updated when new instruments are added or parameters change) |
| **Row Count** | 4 rows (ADA, ETH, SOL, SUI) |
| **Temporal Coverage** | Static configuration; UpdateDate reflects last manual edit |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |

---

## 1. Business Meaning

This is the **configuration reference table** for the US staking program. SP_Staking_US and SP_Staking_DailyPool_US read from this table to determine:
- **IntroDays**: minimum holding period before a position qualifies (ETH=60 days — much stricter than ADA/SOL/SUI=7-9 days)
- **LiquidityBuffer**: fraction of opted-in units eToro can commit to staking (ETH=1.0 means 100%; ADA/SUI=0.9 = 90%)
- **DailyPool_StartDate**: when daily pool tracking activates for the instrument
- **Distribution_StartDate**: when monthly distributions begin for the instrument (SUI = 2026-04-01 is future)

---

## 2. Current Configuration (as of 2026-03-21)

| Currency | InstrumentID | IntroDays | LiquidityBuffer | DailyPool_StartDate | Distribution_StartDate |
|---|---|---|---|---|---|
| ETH | 100001 | 60 | 1.0000 | 2025-08-19 | 2025-11-01 |
| ADA | 100017 | 9 | 0.9000 | 2025-08-19 | 2025-11-01 |
| SOL | 100063 | 7 | 0.8000 | 2025-08-19 | 2025-11-01 |
| SUI | 100340 | 7 | 0.9000 | 2026-02-26 | 2026-04-01 |

---

## 3. Columns

| Column | Type | Description |
|--------|------|-------------|
| InstrumentID | int | eToro instrument identifier for the staking asset (PK) (Tier 4 — manual) |
| Currency | varchar(50) | Asset ticker (ADA/ETH/SOL/SUI) (Tier 4 — manual) |
| IntroDays | int | Minimum consecutive days a position must be held before it earns staking rewards; ETH=60 days (regulatory compliance), ADA/SOL/SUI=7-9 days (Tier 4 — manual) |
| LiquidityBuffer | decimal(12,4) | Fraction of opted-in units available for staking: ADA/SUI=0.90, SOL=0.80, ETH=1.00 (Tier 4 — manual) |
| DailyPool_StartDate | date | Date from which SP_Staking_DailyPool_US begins tracking this instrument's daily pool (Tier 4 — manual) |
| WelcomeEmail_StartDate | date | Date from which welcome emails are sent to newly opted-in clients; ADA/ETH/SOL set to 2026-08-19 (future), SUI=2026-02-26 (Tier 4 — manual) |
| Distribution_StartDate | date | Date from which SP_Staking_US begins producing monthly distributions; SUI distribution starts 2026-04-01 (Tier 4 — manual) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 4 — manual update time) |

---

## 4. Usage Notes

- **ETH IntroDays=60**: Much stricter than other assets. A newly opened ETH position must be held for 60 days before earning any staking reward. This is significantly more restrictive than the global (non-US) staking program.
- **SUI not yet distributing**: Distribution_StartDate=2026-04-01 is in the future as of this writing. Daily pool tracking and OptedOut monitoring are active, but no distributions have been calculated yet.
- **WelcomeEmail_StartDate for ADA/ETH/SOL = 2026-08-19**: This is also in the future, meaning the welcome email flow for the first three instruments has not yet activated.
- **Do not confuse LiquidityBuffer with IntroDays**: IntroDays gates eligibility; LiquidityBuffer scales the units eToro commits to the blockchain.

---

## 5. Relationships

| Relation | Table | Join Key | Notes |
|---|---|---|---|
| Read by | SP_Staking_US | InstrumentID | IntroDays, Distribution_StartDate |
| Read by | SP_Staking_DailyPool_US | InstrumentID | LiquidityBuffer, DailyPool_StartDate |
| Instrument reference | Dealing_Staking_OptedOut_US | InstrumentID | LiquidityBuffer passed through |
| Global counterpart | Dealing_Staking_Parameters | InstrumentID | Non-US equivalent (SP_Staking global params) |
