# BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions — Review needed

> Sidecar checklist — **no** Elements table here.

## PII / sensitivity

| Topic | Note |
|-------|------|
| `RealCID` | **Customer identifier** — join to `Dim_Customer` for demographics; follow **masked vs PII UC** policy on customer attributes (see `Dim_Customer.md`: `main.dwh.*_masked` vs `main.pii_data.*`). **This fact stores `RealCID` only** — no direct name/email columns. |

## Phase 16 adversarial score (2026-05-14)

**Overall: 8.7 / 10**

| Dimension | Score | Notes |
|-----------|-------|-------|
| Tier accuracy | 9/10 | **`RealCID`** upgraded to **Tier 1** verbatim from `Fact_CustomerAction.md`; remaining columns correctly **Tier 2** (SP `CASE`, aggregates, `GETDATE()`). |
| Upstream fidelity | 9/10 | **`DateID`** uses Fact’s **`(Tier 2 — SP_Fact_CustomerAction)`** tag; **`RealCID`** copied verbatim (Tier 1 Customer.CustomerStatic). |
| Evidence / grounding | 9/10 | SP read from **local DataPlatform file**; Synapse MCP row estimate, date span, Phase 3 TOP IDs, latest sample date. |
| Operational completeness | 8/10 | Service Broker priority / job name **not re-verified** this session (soft). |
| Deploy / UC honesty | 8/10 | Explicitly flags **missing Databricks table** vs canonical naming — avoids fake UC parity. |

### Phase 16 findings (actionable)

1. **UC Gold gap** — reconcile with Data Platform: table missing while **`..._revenue_generating_actions`** exists.
2. **`RealCID` nullable in Synapse DDL** — inconsistent with fact semantics (likely type-system artifact); confirm with SSDT `CREATE TABLE`.
3. **`ActionTypeID = 5` + `MirrorID` gap** — still an open data-quality question for `IsCopyFund` accuracy.

## Reviewer corrections

| Topic | Current | Correction | Reviewer | Date |
|-------|---------|------------|----------|------|
| | | | | |

## Soft fails (this pipeline run)

| Gate | Status | Detail |
|------|--------|--------|
| Phase 3 | **PARTIAL** | Only **15** distinct `ActionTypeID` values on **`DateID = 20260426`** — TOP 20 requested; table shows **15**. |
| UC verify | **FAIL (expected)** | Databricks: table **not found**; sibling DDR Gold tables **visible**. |
| Atlassian | **NO HITS** | Confluence CQL returned **0** rows. |
| `sys.dm_pdw_table_mappings` | **N/A** | Not available on connected pool — distribution column taken as **`RealCID`** per BI DDR convention + property parity with sibling facts. |

## Open questions

1. When will **`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions`** be deployed, and will **`etr_*`** partitions match other BI_DB Gold exports?
2. Should **`LoggedIn` vs `DepositorsLoggedIn`** split align with a formal data dictionary (depositor definition = `Fact_SnapshotCustomer.IsDepositor` on `@dateID`)?
3. Are social action types **21–23** still business-relevant given sparse `PostID` lineage in `Fact_CustomerAction`?
