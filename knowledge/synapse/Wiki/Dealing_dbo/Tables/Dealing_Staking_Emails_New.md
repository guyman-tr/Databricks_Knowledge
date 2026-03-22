# Dealing_dbo.Dealing_Staking_Emails_New

> Monthly staking notification email list — one row per (GCID, instrument, staking month) for all staking program participants. Contains segmentation (Mailing_Group), reward amounts, tier, country, and language to drive personalized staking notification emails. The successor to Dealing_Staking_Emails.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (marketing/operational output) |
| **Production Source** | Dealing_dbo.Dealing_Staking_Results + Dealing_Staking_Summary + DWH_dbo customer/tier lookups |
| **Refresh** | Monthly — SP_Staking_Emails (same run as Dealing_Staking_Compensation) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on StakingMonthID |
| **Row Count** | 1,815,229 (as of Mar 2026) |
| **Date Range** | Mar 2025 – Feb 2026 (min_month=202503, though malformed 2025030 means history starts mid-program) |
| **Distinct Clients (GCID)** | 168,684 |
| **Last Updated** | 2026-03-05 |

---

## 1. Business Meaning

This table is the **marketing email dispatch list** for the staking notification pipeline. After each monthly staking distribution, SP_Staking_Emails populates this table with one record per eligible client per instrument, providing all data needed to send a personalized notification email:
- What the client received (Reward units)
- Why they were grouped into a particular email template (Mailing_Group)
- Their tier, country, and language (for email personalization)
- The overall pool yield (MPercentage) and their personal share fraction (CPercentage)

**Relationship to Dealing_Staking_Emails**: This is the "New" version — see comment in SP_Staking_Emails line 252: `--SELECT * FROM Dealing_dbo.Dealing_Staking_Emails where StakingMonthID = 202501`. The "_New" version uses GCID (global ID) instead of CID and has a more structured schema for the email platform.

---

## 2. Column Descriptions

| Column | Type | Description |
|--------|------|-------------|
| StakingMonthID | int | Staking period identifier (YYYYMM). ⚠️ **DATA QUALITY**: Same malformed ID bug as Dealing_Staking_Compensation — March 2025 stored as `2025030`, October 2024 as `2024100`. (Tier 3 — Dealing_Staking_Results) |
| StakingYear | int | Calendar year. (Tier 3 — Dealing_Staking_Results) |
| StakingMonth | varchar(100) | Full month name (e.g., "March"). (Tier 3 — Dealing_Staking_Results) |
| GCID | int | **Global** client identifier (not CID). Used for email targeting. Sourced from Dealing_Staking_Results.GCID which maps to DWH_dbo.Dim_Customer.GCID. (Tier 3 — Dealing_Staking_Results) |
| Country | varchar(100) | Client's registered country name (e.g., "United Kingdom", "United Arab Emirates"). Sourced from DWH_dbo.Dim_Country via Fact_SnapshotCustomer snapshot for the SP run date. (Tier 1 — DWH_dbo.Dim_Country) |
| Language | varchar(100) | Client's preferred language (e.g., "English"). From DWH_dbo.Dim_Language via Fact_SnapshotCustomer. Used for email localization. (Tier 1 — DWH_dbo.Dim_Language) |
| InstrumentID | int | Crypto instrument FK. One row per instrument the client received staking for. (Tier 3 — Dealing_Staking_Results) |
| Currency | varchar(20) | Crypto ticker (e.g., "SOL", "ETH", "ADA"). (Tier 3 — Dealing_Staking_Results) |
| Units | decimal(38,0) | Total units in the staking pool for this instrument/month (RewardsToDistribute from Summary). Integer-rounded. This is the pool-level metric, not the client's personal amount — used to show the total distributed in the email. (Tier 3 — Dealing_Staking_Summary) |
| MPercentage | decimal(38,4) | Network-reported yield percentage (EtoroYield from Summary). The % return that the protocol generated. Used in email to show "the network yielded X%". (Tier 3 — Dealing_Staking_Summary) |
| CPercentage | decimal(38,2) | Client's revenue share fraction (e.g., 0.65 = 65% for Gold tier). From RevShare in Dealing_Staking_Results. Corresponds to PlayerLevel: Bronze 0.45, Silver 0.55, Gold 0.65, Platinum 0.75, Platinum Plus 0.85, Diamond 0.90. (Tier 3 — Dealing_Staking_Results) |
| Reward | decimal(38,4) | Actual crypto units received by this client. Uses `ISNULL(ActualAirdropUnits, Client_Airdrop)` — prefers the confirmed actual airdrop amount once available, falls back to planned Client_Airdrop. (Tier 3 — Dealing_Staking_Results) |
| ClubTier | varchar(100) | eToro Club loyalty tier name (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond). From DWH_dbo.Dim_PlayerLevel. Used for email personalization and segment reporting. (Tier 1 — DWH_dbo.Dim_PlayerLevel) |
| Mailing_Group | varchar(100) | **Email template selector**. Determines which email template/flow the client receives. Values: `AirDropClubs` (non-Bronze, non-USA successful airdrop), `AirDropBronze` (Bronze-tier successful airdrop), `AirDropUSAOnly` (USA address successful airdrop, CountryID=219), `FailedNegativeBalance` (FailReasonID=3), `FailedMaxLeverage` (FailReasonID=2 or 6), `Excluded_Countries` (FailReasonID=5 or Cash compensation), `Technical_Issue` (FailReasonID=7), `Error` (unclassified). (Tier 3 — computed from Dealing_Staking_Results) |
| UpdateDate | datetime | ETL run timestamp from SP_Staking_Emails. (Tier 4 — ETL metadata) |

---

## 3. Business Logic

### 3.1 Mailing_Group Logic

The `Mailing_Group` field routes each client into the correct email template:

| Mailing_Group | Condition | Meaning |
|---|---|---|
| AirDropClubs | IsAirdropSuccess=1, CountryID≠219, PlayerLevelID≠1, not Cash | Successful airdrop, non-Bronze, non-US |
| AirDropBronze | IsAirdropSuccess=1, CountryID≠219, PlayerLevelID=1, not Cash | Successful airdrop, Bronze tier |
| AirDropUSAOnly | IsAirdropSuccess=1, CountryID=219, not Cash | Successful airdrop, US address |
| FailedNegativeBalance | FailReasonID=3 | Airdrop failed — negative balance |
| FailedMaxLeverage | FailReasonID=2 or 6 | Airdrop failed — max leverage |
| Excluded_Countries | FailReasonID=5 OR Cash compensation | Country excluded or cash comp |
| Technical_Issue | FailReasonID=7 | Technical execution failure |
| Error | None of the above | Unclassified — needs investigation |

### 3.2 GCID vs CID

This table uses GCID (global cross-account identifier) while most staking tables use CID (trading account ID). GCID is needed for email targeting because it's the stable identifier for marketing communications — a client may have multiple CIDs but a single GCID.

### 3.3 Relationship to Dealing_Staking_Emails (old version)

`Dealing_Staking_Emails` is the predecessor. The "New" version adds GCID-based targeting, more columns (Country, Language, MPercentage, CPercentage, ClubTier), and the generic `Mailing_Group` field introduced in SR-304378 (Mar 2025) to replace hardcoded per-currency email templates.

---

## 4. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Staking_Results` | Primary source — all staking outcome data |
| `Dealing_dbo.Dealing_Staking_Summary` | Source for Units (RewardsToDistribute) and MPercentage (EtoroYield) |
| `Dealing_dbo.Dealing_Staking_Compensation` | Co-written by same SP_Staking_Emails run — cash compensation recipients |
| `Dealing_dbo.Dealing_Staking_Emails_US` | US-market equivalent — same structure, written by SP_Staking_Emails_US |
| `DWH_dbo.Fact_SnapshotCustomer` | Used to resolve Country, Language, PlayerLevelID for email personalization |

---

## 5. Notes & Caveats

- **GCID-based**: Unlike most staking tables (which use CID), this uses GCID — critical for the email platform.
- **Same malformed ID bug**: StakingMonthID 2025030 and 2024100 present here. See Dealing_Staking_Compensation docs.
- **"New" suffix**: This is the current production email list. The old `Dealing_Staking_Emails` is preserved for historical reference but new runs write here.
- **Scale**: 1.8M rows across ~30 months reflects high staking participation (~168K unique clients have received staking notifications).
