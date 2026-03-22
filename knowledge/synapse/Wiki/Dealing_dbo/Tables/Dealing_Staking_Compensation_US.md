# Dealing_dbo.Dealing_Staking_Compensation_US

> US-market equivalent of Dealing_Staking_Compensation — per-client cash compensation records for US-regulated clients who could not receive crypto airdrops during the staking program. Currently a very small table reflecting the early-stage US staking program (14 rows, 7 clients across 5 months).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (operational output) |
| **Production Source** | Dealing_dbo.Dealing_Staking_Results_US (WHERE ActualCompensationType = 'Cash') |
| **Refresh** | Monthly — SP_Staking_Emails_US runs when US airdrop results confirmed in etoro_Trade_AdminPositionLog |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **Row Count** | 14 (as of Mar 2026) |
| **Date Range** | Oct 2025 – Feb 2026 |
| **Last Updated** | 2026-03-06 |

---

## 1. Business Meaning

US-market parallel to `Dealing_Staking_Compensation`. Records the USD cash compensation paid to US-regulated clients who were eligible for staking but received cash instead of crypto airdrops. The table is currently very small (14 rows, 7 distinct clients across 5 months) reflecting that US staking launched in October 2025 and that cash compensation cases are rare.

**Key differences from the non-US Dealing_Staking_Compensation**:
- US staking started October 2025 (non-US Sep 2023)
- Only 3 crypto instruments (ADA, SOL, ETH) vs 9 globally
- COLUMNSTORE index vs CLUSTERED row-store index (identical pattern to other US staking tables)
- Significantly fewer compensation cases (14 vs 189,419 rows) — US program is newer and has fewer clients

---

## 2. Column Descriptions

Identical schema to `Dealing_Staking_Compensation`. See that table's documentation for full column descriptions. US-specific notes:

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | YYYYMM format. US program starts at 202510. No malformed ID bug observed for US (unlike non-US). (Tier 3 — Dealing_Staking_Results_US) |
| StakingMonth | varchar(100) | Month name. (Tier 3) |
| StakingYear | int | Calendar year. (Tier 3) |
| CID | int | US client account ID receiving cash compensation. (Tier 3 — Dealing_Staking_Results_US) |
| InstrumentID | int | Crypto instrument FK. For US: ADA, SOL, or ETH only. (Tier 3 — Dealing_Staking_Results_US) |
| StakingRewards_USD | decimal(28,4) | USD cash compensation amount. (Tier 3 — computed via SP_Staking_US) |
| UpdateDate | datetime | ETL run timestamp from SP_Staking_Emails_US. (Tier 4 — ETL metadata) |

---

## 3. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_Compensation` | Non-US equivalent — larger scale, longer history |
| `Dealing_dbo.Dealing_Staking_Results_US` | Source — filtered to ActualCompensationType = 'Cash' |
| `Dealing_dbo.Dealing_Staking_Emails_US` | Co-written by SP_Staking_Emails_US in same run — email notification data |

---

## 4. Notes & Caveats

- **Very low volume**: Only 14 rows across 5 months suggests either extremely low cash compensation rate in US, or that cash compensation criteria differ for US clients.
- **No data quality issues**: The malformed StakingMonthID bug found in the non-US table (2025030, 2024100) is NOT present in this table — SP_Staking_Emails_US was likely written after the bug was fixed.
