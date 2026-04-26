---
object: BI_DB_dbo.BI_DB_AML_Benchmarks_AML_Alerts
type: Table
lineage_version: 1
generated: 2026-04-23
---

# Column Lineage — BI_DB_AML_Benchmarks_AML_Alerts

## Source Summary

| Property | Value |
|----------|-------|
| **Production Source** | Unknown — no writer SP in SSDT; likely external AML compliance tool or manual population |
| **Writer SP** | None found in SSDT repo |
| **ETL Pattern** | Unknown — table is empty (0 rows as of 2026-04-23) |
| **UC Target** | _Not_Migrated |
| **Sibling Table** | BI_DB_dbo.BI_DB_AML_Benchmarks_Risk_Classification (risk class change tracking companion) |

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Unknown external AML tool | CID | Customer identifier for the AML alert change event | Tier 4 |
| 2 | GCID | Unknown external AML tool | GCID | Group Customer ID — cross-product identity key | Tier 4 |
| 3 | PlayerStatusID | DWH_dbo.Dim_PlayerStatus | PlayerStatusID | AML-driven status code applied to the customer | Tier 3 |
| 4 | PlayerStatusName | DWH_dbo.Dim_PlayerStatus | Name | Denormalized status name (e.g., Blocked, Warning) | Tier 3 |
| 5 | PlayerStatusReasonID | DWH_dbo.Dim_PlayerStatusReason | PlayerStatusReasonID | Reason code for the AML-driven status change | Tier 3 |
| 6 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReason | Reason | Denormalized reason description | Tier 3 |
| 7 | PlayerStatusSubReasonID | DWH_dbo.Dim_PlayerStatusSubReason | SubReasonID | Sub-reason code for the status change | Tier 3 |
| 8 | PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReason | SubReason | Denormalized sub-reason description | Tier 3 |
| 9 | AMLAlert_ChangeDateTime | Unknown external AML tool | change_datetime | Precise datetime when the AML alert-driven status change occurred | Tier 4 |
| 10 | AMLAlert_ChangeDate | Unknown external AML tool | change_date | Date portion of the status change (derived from AMLAlert_ChangeDateTime) | Tier 3 |
| 11 | UpdateDate | ETL metadata | GETDATE() | ETL run timestamp — propagation column | Tier 5 |

## Notes

- Empty table (0 rows as of 2026-04-23). No writer SP found anywhere in SSDT repo.
- Companion to BI_DB_AML_Benchmarks_Risk_Classification — both tables track AML-driven changes in customer state.
- Likely used for AML performance benchmarking: measuring rate and timing of AML alert-triggered status changes.
- PlayerStatus values confirmed from live Dim_PlayerStatus: 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Blocked-Under Investigation, etc. (16 distinct values).
