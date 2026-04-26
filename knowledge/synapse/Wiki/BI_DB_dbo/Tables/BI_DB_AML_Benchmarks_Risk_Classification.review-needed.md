---
object: BI_DB_dbo.BI_DB_AML_Benchmarks_Risk_Classification
review_generated: 2026-04-23
batch: 80
---

# Review Needed — BI_DB_AML_Benchmarks_Risk_Classification

## Tier 4 Items / Uncertainties

1. **CID (Tier 4)**: Source system unknown. CID is nullable (DDL: `CID int NULL`) while GCID is NOT NULL — atypical for BI_DB_dbo tables where CID is usually NOT NULL and the primary key. If a writer SP or external integration is identified, upgrade source tier to Tier 2 or Tier 3.

2. **GCID (Tier 4)**: Source system unknown. GCID is NOT NULL — meaning this column may be the effective grain key of the table rather than CID. Confirm: is GCID the primary key for this table in the AML source system?

3. **RiskClassChangeDate (Tier 4)**: The "change" this date refers to — is it: (a) when an AML officer made the risk classification decision in the AML case management tool, (b) when the change was applied to the eToro system, or (c) when the ETL ran and recorded it? Confirm with AML compliance team.

4. **RowNumber purpose**: RowNumber is assigned Tier 3 (derived) but the exact `ROW_NUMBER()` logic is unknown — no writer SP available. Key unknowns: (a) Is it partitioned by CID or GCID? (b) Is it ordered ascending (oldest=1) or descending (newest=1)? A descending order with RowNumber=1 = most-recent is most common for deduplication patterns but is unconfirmed here.

5. **Table purpose — "Benchmarks"**: The AML benchmarking use case is inferred from the table name and its companion table (BI_DB_AML_Benchmarks_AML_Alerts). Confirm: does this table drive an AML effectiveness dashboard or report measuring re-classification rates or time-to-action?

6. **Writer mechanism**: No SSDT SP writes to this table. Is it populated by: (a) a direct push from an AML case management tool (e.g., NICE Actimize), (b) a manual CSV upload, (c) a Fivetran connector, or (d) something else?

## Questions for Domain Experts

- What system populates this table? (Confirm the external writer mechanism)
- Is this table actively maintained or decommissioned?
- Why is CID nullable and GCID NOT NULL? Is GCID the primary key in the AML source system?
- What does RowNumber=1 represent — the most recent change or the earliest?
- Are both AML Benchmarks tables (AML_Alerts + Risk_Classification) always populated together as a pair?
- What is the "benchmark" being measured — rate of risk re-classifications per AML review cycle? Time from AML alert to risk class change?

## No Cross-Object Corrections Needed

RiskClass values confirmed from live DWH_dbo.Dim_RiskClassification (6 values): 0=High(100), 1=Medium(50), 2=Low(0), 3=Unacceptable(200), 4=Medium High(75), 5=Medium Low(25). No conflicts with sibling table docs.
