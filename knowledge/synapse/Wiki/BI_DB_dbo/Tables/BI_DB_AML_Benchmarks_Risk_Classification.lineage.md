---
object: BI_DB_dbo.BI_DB_AML_Benchmarks_Risk_Classification
type: Table
lineage_version: 1
generated: 2026-04-23
---

# Column Lineage — BI_DB_AML_Benchmarks_Risk_Classification

## Source Summary

| Property | Value |
|----------|-------|
| **Production Source** | Unknown — no writer SP in SSDT; likely external AML compliance tool or manual population |
| **Writer SP** | None found in SSDT repo |
| **ETL Pattern** | Unknown — table is empty (0 rows as of 2026-04-23) |
| **UC Target** | _Not_Migrated |
| **Sibling Table** | BI_DB_dbo.BI_DB_AML_Benchmarks_AML_Alerts (AML alert-driven status change tracking companion) |
| **Lookup Reference** | DWH_dbo.Dim_RiskClassification: 0=High(100), 1=Medium(50), 2=Low(0), 3=Unacceptable(200), 4=Medium High(75), 5=Medium Low(25) |

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Unknown external AML tool | CID | Customer identifier — subject of the risk classification change | Tier 4 |
| 2 | GCID | Unknown external AML tool | GCID | Group Customer ID — cross-product identity key (NOT NULL, primary key candidate) | Tier 4 |
| 3 | RiskClassID | DWH_dbo.Dim_RiskClassification | RiskClassificationID | New/current risk class ID after the change (0=High, 1=Medium, 2=Low, 3=Unacceptable, 4=Medium High, 5=Medium Low) | Tier 3 |
| 4 | RiskClassDesc | DWH_dbo.Dim_RiskClassification | RiskClassificationName | Denormalized description of the new risk class | Tier 3 |
| 5 | PreviousRiskClassID | DWH_dbo.Dim_RiskClassification | RiskClassificationID (prior) | Prior risk class ID before this change event | Tier 3 |
| 6 | PreviousRiskClassDesc | DWH_dbo.Dim_RiskClassification | RiskClassificationName (prior) | Denormalized description of the prior risk class | Tier 3 |
| 7 | RiskClassChangeDateID | Derived | RiskClassChangeDate | Date of the risk class change in YYYYMMDD integer format (date key) | Tier 3 |
| 8 | RiskClassChangeDate | Unknown external AML tool | change_date | Calendar date when the customer's risk classification changed | Tier 4 |
| 9 | RowNumber | Derived | ROW_NUMBER() | Row ordering number — likely used to identify most-recent change per CID or deduplicate | Tier 3 |
| 10 | UpdateDate | ETL metadata | GETDATE() | ETL run timestamp — propagation column | Tier 5 |

## Notes

- Empty table (0 rows as of 2026-04-23). No writer SP found in SSDT repo.
- Companion to BI_DB_AML_Benchmarks_AML_Alerts — both tables track AML-driven changes in customer state (status alerts vs. risk classification changes).
- Risk class values confirmed from live DWH_dbo.Dim_RiskClassification (6 values): 0=High(RiskScore=100), 1=Medium(50), 2=Low(0), 3=Unacceptable(200), 4=Medium High(75), 5=Medium Low(25).
- Note: The DDL has CID nullable (NULL) but GCID is NOT NULL — unusual (reversed from typical eToro tables where CID is the primary key). GCID may be the grain here (Global Customer ID for cross-product tracking).
- RowNumber likely a ROW_NUMBER() OVER PARTITION BY CID ordering the change history chronologically, or marks the most-recent row per CID for deduplication.
