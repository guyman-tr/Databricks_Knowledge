# BI_DB_dbo.BI_DB_Flare_Eligibility

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Writer SP** | BI_DB_dbo.SP_Flare_Eligibility |
| **ETL Pattern** | TRUNCATE + INSERT (full reload, no date parameter) |
| **OpsDB Priority** | 20 |
| **Frequency** | Daily |
| **Row Estimate** | Varies by campaign (Finance-uploaded CID list) |
| **UC Target** | Not Migrated |

## Overview

Flare Network airdrop eligibility assessment for eToro customers. For each campaign cycle, Finance uploads a CSV of candidate customer IDs (`Flare_list_of_CIDs.csv`) to the data lake. The SP loads this list, applies four regulatory and compliance eligibility checks against current customer dimension data, and produces a binary `IsEligible` flag per customer.

**Flare context**: Flare Network ran a token airdrop campaign where holders of certain crypto assets were entitled to receive Flare tokens. eToro Finance needed to identify which eligible customers could participate, subject to regulatory (target market, AML, cash-equivalent rules) and account-status restrictions.

The table is a full daily snapshot — no historical rows are retained. Each daily run truncates and reloads based on the current Finance-uploaded candidate list.

## ETL Summary

```
Finance CSV upload (lake path: BI_OUTPUT/Finance/Uploads/Flare_list_of_CIDs.csv)
  ↓ External_Flare_CID3 (CID, IsOptOut)
  ↓ JOIN Dim_Customer → apply 4 eligibility flags
  ↓ Derive IsEligible = AND(all flags=1, IsOptOut=0)
  → TRUNCATE BI_DB_Flare_Eligibility → INSERT
```

**Source**: External table `BI_DB_dbo.External_Flare_CID3` (CSV, `analysis` data source, `skipHeader_CSV` format).

**Reload pattern**: Full TRUNCATE + INSERT on every daily run. No incremental or date-partitioned logic. The table always reflects the current state of the Finance-provided candidate list against today's customer dimension snapshot.

## Column Reference

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within eToro DB. Used as the universal customer identifier across all tables. Populated from Finance-uploaded CSV. | Tier 1 — Dim_Customer.RealCID |
| 2 | IsOptOut | int | YES | Customer opt-out flag for the Flare airdrop campaign. 0 = opted in (willing to participate); 1 = opted out (declined). Sourced from Finance-uploaded CSV — customers who explicitly declined participation are excluded from IsEligible regardless of other flags. | Tier 2 |
| 3 | Negative Target Market | int | YES | Eligibility flag: 1 = customer is in an eligible target market; 0 = excluded. Exclusion criteria: RiskGroupID=1 (high-risk group), CountryID IN (250=eToro internal, 44=China), RegulationID=5 (BVI regulation), or PlayerStatusReasonID=28. | Tier 2 |
| 4 | AML Status Restriction | int | YES | Eligibility flag: 1 = customer has no AML restrictions; 0 = excluded due to AML status. Exclusion criteria: PlayerStatusID IN (2,9,15,4) or PlayerStatusSubReasonID IN (25=Selfie, 33=Screening Possible Match, 31=Screening Negative Result, 32=Screening PEP, 26=Expired POI/POA, 30=HRC, 51=Risk Check). | Tier 2 |
| 5 | Account status | int | YES | Eligibility flag: 1 = account is in an eligible status; 0 = excluded. Exclusion criterion: AccountStatusID=2 (closed/blocked account). | Tier 2 |
| 6 | Cash Equivalent | int | YES | Eligibility flag: 1 = customer is not in a cash-equivalent restricted jurisdiction; 0 = excluded. Exclusion criteria: CountryID IN (67,167,148,79,63,105,96) or RegulationID IN (6,7,8). Cash-equivalent restrictions apply where regulatory treatment of crypto tokens as near-cash instruments would complicate the airdrop. | Tier 2 |
| 7 | IsEligible | int | YES | Composite eligibility flag: 1 = customer is eligible to receive the Flare airdrop; 0 = ineligible. Logic: `CASE WHEN [Negative Target Market]=1 AND [AML Status Restriction]=1 AND [Account status]=1 AND [Cash Equivalent]=1 AND IsOptOut=0 THEN 1 ELSE 0 END`. All five conditions must be satisfied simultaneously. | Tier 2 |
| 8 | UpdateDate | date | YES | ETL metadata: date when this row was last refreshed by the ETL pipeline (GETDATE() at INSERT time). | ETL_METADATA |

## Eligibility Logic

```
IsEligible = 1 when ALL of:
  ├─ [Negative Target Market] = 1   (not in restricted market)
  ├─ [AML Status Restriction] = 1   (no AML flags on account)
  ├─ [Account status] = 1           (account is open/active)
  ├─ [Cash Equivalent] = 1          (not in cash-equivalent jurisdiction)
  └─ IsOptOut = 0                   (customer did not opt out)
```

Each flag is independently evaluated. A customer can fail one or multiple checks. The individual flags allow Finance to report on the breakdown of ineligibility reasons.

## Upstream Dependencies

| Upstream Object | Type | Role |
|----------------|------|------|
| BI_DB_dbo.External_Flare_CID3 | External Table | Base candidate CID population (Finance CSV upload) |
| DWH_dbo.Dim_Customer | Table | Customer regulation, player status, account status, country |
| DWH_dbo.Dim_PlayerStatus | Table | PlayerStatusID lookup (joined for FK integrity) |
| DWH_dbo.Dim_Country | Table | Country risk group and country ID |

## Data Quality Notes

- **External CSV dependency**: The table is only as complete as the Finance-uploaded `Flare_list_of_CIDs.csv`. If the CSV is missing, outdated, or corrupt, the ETL will load 0 rows (the TRUNCATE still executes). Monitor for empty-table scenarios after reload.
- **Daily snapshot**: No historical versions are retained. If eligibility changes day-to-day (e.g., customer resolves AML flag), only the current day's state is visible.
- **Integer flags**: All eligibility columns use INT (not BIT). Values are 0 or 1; NULLs should not appear in practice given the CASE logic, but are possible if Dim_Customer JOIN misses a CID.
- **Column names with spaces**: Three columns use space-containing names (`[Negative Target Market]`, `[AML Status Restriction]`, `[Account status]`). These require bracket-quoting in all SQL references.

## Known Issues

- **Specific CountryID and RegulationID values not named**: The SP encodes exclusion lists numerically (e.g., CountryID IN (67,167,148,79,63,105,96), RegulationID IN (6,7,8)). The mapping to country/regulation names requires a Dim_Country / Dim_Regulation JOIN at query time.
- **Campaign-specific**: This table was built for the Flare Network airdrop campaign. The candidate CID list and eligibility logic may not be reused for future campaigns. Verify with Finance whether this table is still actively maintained.

## UC Target

Not Migrated. No `.alter.sql` generated (wiki-only batch).
