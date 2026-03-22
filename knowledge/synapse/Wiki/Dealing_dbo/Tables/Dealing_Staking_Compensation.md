# Dealing_dbo.Dealing_Staking_Compensation

> Per-client, per-instrument staking cash compensation records — USD amounts paid to clients who were eligible for staking rewards but received cash instead of a crypto airdrop. One row per (client, instrument, staking month) for all 'Cash' compensation recipients.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (operational output) |
| **Production Source** | Dealing_dbo.Dealing_Staking_Results (WHERE ActualCompensationType = 'Cash') |
| **Refresh** | Monthly — SP_Staking_Emails runs when airdrop results are confirmed in etoro_Trade_AdminPositionLog |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on StakingMonthID |
| **Row Count** | 189,419 (as of Mar 2026) |
| **Date Range** | Sep 2023 – Feb 2026 |
| **Distinct Clients** | ~46,513 per month |
| **Last Updated** | 2026-03-05 |

---

## 1. Business Meaning

When a client is eligible for crypto staking rewards but the airdrop fails (e.g., wrong jurisdiction, technical issue, compliance block), eToro pays a cash (USD) equivalent instead. This table records the cash compensation amounts per client per staking month.

It is a downstream extract from `Dealing_Staking_Results`, filtered to only clients with `ActualCompensationType = 'Cash'`. It feeds the `Dealing_Staking_Emails_New` pipeline (written in the same SP run) that sends marketing/notification emails to compensated clients.

**Typical reasons for cash compensation** (from SP_Staking FailReasonID logic):
- Client's country is not eligible for the specific crypto airdrop
- Technical issue preventing airdrop execution
- Error code 813 (Compliance block on opening positions)
- Client is in the intro period (IntroDays waiting period)

---

## 2. Column Descriptions

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking period identifier in YYYYMM format. ⚠️ **DATA QUALITY ISSUE**: Records for March 2025 and October 2024 use malformed 7-digit values (`2025030`, `2024100`) due to a historical bug in SP_Staking_Emails that used `LEFT(..., 7)` instead of `LEFT(..., 6)`. These rows are effectively orphaned — queries filtering by correct YYYYMM format will miss them. (Tier 3 — Dealing_Staking_Results) |
| StakingMonth | varchar(100) | Full month name (e.g., "February"). Inherited from Dealing_Staking_Results. (Tier 3 — Dealing_Staking_Results) |
| StakingYear | int | Calendar year of the staking period. Inherited from Dealing_Staking_Results. (Tier 3 — Dealing_Staking_Results) |
| CID | int | Client account identifier (RealCID / trading account). The client who received cash compensation instead of a crypto airdrop. (Tier 3 — Dealing_Staking_Results) |
| InstrumentID | int | eToro instrument identifier for the crypto that should have been airdropped. FK to DWH_dbo.Dim_Instrument. Compensation is for this specific crypto's staking reward. (Tier 3 — Dealing_Staking_Results) |
| StakingRewards_USD | decimal(28,4) | USD amount of cash compensation paid. Sourced from `Dealing_Staking_Results.USD_Compensation` cast to DECIMAL(28,4). Represents the fair value of the crypto airdrop the client would have received. (Tier 3 — Dealing_Staking_Results → SP_Staking computation) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was written by SP_Staking_Emails. Set to GETDATE() at SP execution time. (Tier 4 — ETL metadata) |

---

## 3. Business Logic

### 3.1 SP_Staking_Emails Execution Trigger

SP_Staking_Emails runs when all three conditions are met:
1. `Dealing_staging.etoro_Trade_AdminPositionLog` has airdrop results (`OpenActionType = 11`) for the target staking month
2. The last airdrop record is older than 3 hours (confirming all batches have arrived, not just the first)
3. `Dealing_Staking_Compensation` does NOT yet have data for that month (prevents duplicate runs)

### 3.2 Cash vs Airdrop

SP_Staking classifies each client's compensation as either:
- `'Airdrop'` — client receives actual crypto units (the standard path)
- `'Cash'` — client receives USD equivalent

This table contains ONLY the `'Cash'` records. For airdrop recipients, see `Dealing_Staking_Results` (IsAirdropSuccess=1).

### 3.3 Known Data Quality Issue

Two staking months have malformed IDs:
- March 2025 stored as `2025030` (should be `202503`)
- October 2024 stored as `2024100` (should be `202410`)

Caused by an older SP version using `LEFT(CAST(...AS INT), 7)` instead of `LEFT(CAST(...AS INT), 6)`. Fixed in later runs but historical data not corrected.

---

## 4. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_Results` | Primary source — this table is a filtered subset (Cash only) |
| `Dealing_dbo.Dealing_Staking_Emails_New` | Written in the same SP_Staking_Emails run — email notification data for compensated clients |
| `Dealing_dbo.Dealing_Staking_Compensation_US` | US-market equivalent — same structure, written by SP_Staking_Emails_US |
| `Dealing_staging.etoro_Trade_AdminPositionLog` | Trigger dependency — SP waits for airdrop records (OpenActionType=11) here |

---

## 5. Notes & Caveats

- **Not a complete staking picture**: This table only covers cash compensation recipients. Clients who received crypto airdrops are not represented here (use Dealing_Staking_Results for the full picture).
- **Historical coverage**: Sep 2023 – present, covering 30+ staking months. Two months (Mar 2025, Oct 2024) have malformed IDs.
- **Client count**: ~46,513 distinct clients across all months — represents a significant minority of the eligible staking population who couldn't receive crypto directly.
