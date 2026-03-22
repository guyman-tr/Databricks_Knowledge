---
object: Dealing_ClientCountry_Reg
schema: Dealing_dbo
type: Table
description: Daily count of customers per regulatory entity categorized as being in the "same region" as their regulation's jurisdiction vs. a different region. Flags cross-regulatory exposure.
etl_sp: Dealing_dbo.SP_ClientCountry
frequency: Daily
status: Active (last: 2026-03-10)
row_count: ~11,880
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_ClientCountry_Reg

Daily count per regulation entity of customers whose geographic region matches (or doesn't match) the jurisdiction of their regulatory entity. Produced in the same SP execution as `Dealing_ClientCountry`. Used to identify regulatory mismatches — e.g., a client regulated under CySEC (Europe) but located in the USA.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Customer` | All customers → RegulationID + CountryID |
| Dimension | `DWH_dbo.Dim_Regulation` | RegulationID → Name + geographic Region (Europe/UK/USA/Australia/NULL) |
| Dimension | `DWH_dbo.Dim_Country` | CountryID → Country + Region |
| Writer | `Dealing_dbo.SP_ClientCountry` | Daily, OpsDB Priority 0 |

**Region mapping** (hardcoded in SP):
- Regulation → Region: DWHRegulationID 1=Europe, 2=UK, 3/5/11=NULL (global), 4/10=Australia, 6/7/8=USA
- Country → Region: Eastern/North/ROE/French/German/Italian Europe → "Europe", plus UK, USA, Australia

**IsSameRegion logic**: 1 when customer's geographic region = regulation's jurisdiction region, OR when the regulation has no region (global). 0 = geographic mismatch.

Both `Dealing_ClientCountry` and `Dealing_ClientCountry_Reg` are populated in a single SP call.

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. |
| `RegulationID` | int | NULL | Foreign key to DWH_dbo.Dim_Regulation.DWHRegulationID. Identifies the regulatory entity. |
| `Regulation` | varchar(100) | NULL | Regulation name (e.g., "CySEC", "FCA", "FinCEN+FINRA", "NFA", "FSRA"). Denormalized from Dim_Regulation. |
| `Count_SameRegion` | int | NULL | Number of customers under this regulation whose home country region matches the regulation's jurisdiction. |
| `Count_DiffRegion` | int | NULL | Number of customers under this regulation whose home country region does NOT match the regulation's jurisdiction. A non-zero value here flags geographic mismatches. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2023-09-03 → 2026-03-10 (daily)
- 11,880 rows total — ~10 rows per day (one per active regulation)
- Sample (2026-03-10): FinCEN+FINRA → 401,057 same-region, 8 diff-region; FSRA → 87,892 same-region, 0 diff-region; NFA → 105,135 same-region, 0 diff-region
- Small diff-region counts (e.g., 8 for FinCEN+FINRA) may represent US clients misrouted to non-US regulation or cross-border accounts

## Business Context

Compliance and regulatory monitoring. Provides a daily signal for whether the customer base is correctly routed to appropriate regulatory entities by geography. Non-zero `Count_DiffRegion` values warrant review by the Compliance team.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_ClientCountry` | Sister table — same SP, captures NOP by country for domestic instrument positions |
| `DWH_dbo.Dim_Regulation` | RegulationID lookup |
| `DWH_dbo.Dim_Customer` | Customer population source |

## ETL Notes

- Written as the second INSERT in SP_ClientCountry (single SP execution produces both tables)
- RegulationID=NULL customers are excluded (no regulation mapping)
- Global regulations (IDs 3,5,11) contribute IsSameRegion=1 for all customers

## Quality Score: 8.0/10
*Strong coverage: SP logic traced, IsSameRegion computation explained, sample data confirms active status. Minor deduction: Dim_Regulation IDs not fully enumerated (only 3 shown in sample).*
