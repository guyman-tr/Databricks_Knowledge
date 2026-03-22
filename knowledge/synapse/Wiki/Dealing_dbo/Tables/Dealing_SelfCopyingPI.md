---
object: Dealing_SelfCopyingPI
schema: Dealing_dbo
type: Table
description: Former daily surveillance table identifying Popular Investors whose own secondary accounts copy their PI portfolio (self-copy = artificial AUM inflation). DECOMMISSIONED: SP placed on HOLD April 2024; last data September 2023.
etl_sp: Dealing_dbo.HOLD_20240416_SP_SelfCopyingPI (HOLD)
frequency: Was Daily
status: ⛔ DECOMMISSIONED (last data: 2023-09-03)
row_count: ~18,914
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 7.5
---

# Dealing_SelfCopyingPI

**DECOMMISSIONED**: The writing SP (`SP_SelfCopyingPI`) was placed on HOLD on 2024-04-16 (evidenced by `HOLD_20240416_SP_SelfCopyingPI.sql` in the SSDT repo). Last data was 2023-09-03 — the table has been empty since then.

When active, this table identified Popular Investors (PIs) who were using secondary accounts under the same IP address to copy their own PI portfolio, artificially inflating their AUM figure. This practice violates eToro's PI program rules.

## Source & Lineage (Historical)

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Mirror` | Active copy relationships (CopyerIP, AUM, ParentCID) |
| Reference | PI identification | ParentCID = the PI being self-copied |
| Writer | `Dealing_dbo.HOLD_20240416_SP_SelfCopyingPI` | Was daily; now deactivated |

**Detection logic** (inferred from schema):
- For each PI (ParentCID), find copier accounts sharing the same IP (CopyerIP)
- PercentageOfAUM = CopyerAUM / TotalCopyAum — what fraction of PI's total AUM is from self-copying accounts
- High PercentageOfAUM (approaching 1.0) = majority of PI's AUM is self-inflated

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. Last populated: 2023-09-03. |
| `DateInt` | int | NULL | Integer date key (YYYYMMDD). |
| `ParentCID` | int | NULL | The PI (Popular Investor) whose portfolio is being copied. |
| `CopyerIP` | varchar(15) | NULL | IP address of the copying account. Matching IP to PI's IP identifies self-copy. |
| `CopyerAUM` | money | NULL | AUM (Assets Under Management) of the copying account in the PI's portfolio. |
| `TotalCopyAum` | money | NULL | Total AUM across all copiers of this PI. |
| `ParentUserName` | varchar(20) | NULL | Username of the PI (ParentCID). |
| `PercentageOfAUM` | float | NULL | CopyerAUM / TotalCopyAum. Value near 1.0 indicates the copying account represents most of the PI's AUM (high self-copy fraction). |
| `UpdateDate` | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- ⛔ **DECOMMISSIONED**: Last data 2023-09-03 (Sept 2023)
- SP placed on HOLD April 2024 (file: HOLD_20240416_SP_SelfCopyingPI.sql)
- 18,914 rows total (2022-06-20 → 2023-09-03) — about 15 months of data
- Sample (2023-09-03): PercentageOfAUM values 0.30–1.0 (some PIs had 100% self-copy AUM)
- ROUND_ROBIN distribution

## Business Context

Addressed a specific fraud pattern: PI candidates artificially inflating their AUM (which affects their PI tier and bonus eligibility) by having secondary accounts copy their main portfolio. The PercentageOfAUM metric directly quantified the extent of self-inflation. The SP was decommissioned — possibly because the detection was moved to a different system, IP-based detection became unreliable (VPNs, NAT), or the rule was superseded by another program integrity check.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_SuspiciousActivityTrading_24H` | Companion surveillance table (still active) |
| `Dealing_PreviouslyIdentifiedAbusers` | Companion surveillance table (still active) |

## Quality Score: 7.5/10
*Good for a decommissioned table: HOLD file identified, last data confirmed, detection logic inferred from schema. Deduction for lack of SP code confirmation (HOLD file not read).*
