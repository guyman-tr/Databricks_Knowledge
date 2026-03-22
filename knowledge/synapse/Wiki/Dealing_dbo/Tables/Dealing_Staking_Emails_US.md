# Dealing_dbo.Dealing_Staking_Emails_US

> US-market equivalent of Dealing_Staking_Emails_New — monthly staking notification email list for US-regulated clients. One row per (GCID, instrument, staking month). Covers ADA, SOL, ETH. Active from October 2025.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (marketing/operational output) |
| **Production Source** | Dealing_dbo.Dealing_Staking_Results_US + Dealing_Staking_Summary_US + DWH_dbo customer/tier lookups |
| **Refresh** | Monthly — SP_Staking_Emails_US (daily SB_Daily pipeline, writes once per staking month) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on StakingMonthID |
| **Row Count** | 6,747 (as of Mar 2026) |
| **Date Range** | Oct 2025 – Feb 2026 |
| **Distinct Clients (GCID)** | 1,718 |
| **Last Updated** | 2026-03-06 |

---

## 1. Business Meaning

US-market parallel to `Dealing_Staking_Emails_New`. Provides the same email dispatch list structure for US-regulated clients who participated in the staking program. Written by SP_Staking_Emails_US in the same run that writes Dealing_Staking_Compensation_US.

**Key differences from Dealing_Staking_Emails_New**:
- Only US-regulated clients (3 instruments: ADA, SOL, ETH — no SUI in email list)
- Started October 2025 (first US distribution)
- No malformed StakingMonthID bug (fixed before this SP was written)
- Notably uses row-store CLUSTERED INDEX (not COLUMNSTORE — unlike other US staking tables)
- Much smaller: 6,747 rows vs 1.8M non-US

The same `Mailing_Group` segmentation logic applies (AirDropClubs, AirDropBronze, Excluded_Countries, etc.) — see `Dealing_Staking_Emails_New` for full breakdown.

---

## 2. Column Descriptions

Identical schema to `Dealing_Staking_Emails_New`. See that table's documentation for full column descriptions.

| Column | US-Specific Notes |
|--------|-----------------|
| StakingMonthID | No malformed IDs. Range 202510–202602. |
| GCID | US client global ID |
| Country | US clients — predominantly "United States" but may include other English-speaking countries |
| Currency | US-eligible only: ADA, SOL, ETH |
| Mailing_Group | Same logic as non-US. AirDropUSAOnly (CountryID=219) common here |

---

## 3. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_Emails_New` | Non-US equivalent — same schema, larger scale |
| `Dealing_dbo.Dealing_Staking_Results_US` | Primary source |
| `Dealing_dbo.Dealing_Staking_Compensation_US` | Co-written by SP_Staking_Emails_US |

---

## 4. Notes & Caveats

- **Row-store index**: Unlike other US staking tables (which use COLUMNSTORE), this table uses the same CLUSTERED INDEX as the non-US version. No functional difference — just DDL inconsistency with other US staking tables.
- **SUI absent**: Despite SUI appearing in Dealing_Staking_DailyPool_US, SUI has no entries in this email list — likely no distributions have occurred for US SUI clients yet.
