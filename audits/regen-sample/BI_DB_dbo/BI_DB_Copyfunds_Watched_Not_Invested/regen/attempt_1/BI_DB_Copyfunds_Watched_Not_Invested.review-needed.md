# Review Needed — BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested

Generated: 2026-04-28

---

## Items Requiring Human Review

### 1. Table name vs. actual SP scope mismatch (HIGH — business intent unclear)

**Issue**: The table is named `BI_DB_Copyfunds_Watched_Not_Invested` (implying it tracks only watchers who have NOT invested), but the SP has `--where t.IsLifetimeCopied = 0` commented out. In production, the table includes ALL fund watchers — those who have invested AND those who have not.

**Action needed**: Confirm whether this is intentional (the table serves both use cases via the `Is*Copied` flags) or a regression (the filter was accidentally removed/commented out).

**Impact**: Downstream consumers relying on the table name semantics will get inflated counts unless they apply `WHERE IsLifetimeCopied = 0` themselves.

---

### 2. `BI_DB_dbo_Relationship_sp` external table — wiki not found in bundle

**Issue**: The harness marked `BI_DB_dbo.BI_DB_dbo_Relationship_sp` as unresolved. This is the external stream table populated by `SP_Create_External_Streams_dbo_FollowRelationships_Range`. No wiki exists for it in the knowledge base.

**Action needed**: Confirm the underlying social-graph source schema (FollowRelationships — eToro social platform). If a production table wiki exists, link it to this object's lineage.

---

### 3. `MoneyAvailable` description re-use from Q11 upstream

**Issue**: Column 12 (`MoneyAvailable`) description was written as: *"Answer text for Q11. Renamed from V_Liabilities.Credit..."*. This is because the Q11_AnswerText description from BI_DB_KYC_Panel was (incorrectly) reused. The correct upstream wiki description for V_Liabilities.Credit is from Fact_SnapshotEquity (T1 passthrough). The description in the generated wiki has been written to clarify this, but the verbatim Fact_SnapshotEquity Credit column description was not available in the bundle (V_Liabilities wiki documents Credit as "Direct" without a verbatim source description).

**Action needed**: When Fact_SnapshotEquity wiki is available, update the MoneyAvailable description with the verbatim upstream description for Fact_SnapshotEquity.Credit.

---

### 4. Duplicate rows in sample data (CID 54019 × StanleyDruck13F appears twice)

**Issue**: The live data sample returned two identical rows for CID=54019 and FundName='StanleyDruck13F' with the same UpdateDate. This suggests either a duplicate-row issue in the SP output (possibly from the #transformuserdata join producing fan-out), or an expected design (e.g., multiple follow events for the same pair in the month window).

**Action needed**: Verify whether duplicate (RealCID, FundName) pairs are expected or a data-quality defect. If defect, add `SELECT DISTINCT` or deduplication to the SP.

---

### 5. Stale data — UpdateDate is 2025-03-10 (over a year old as of 2026-04-28)

**Issue**: All rows sampled show UpdateDate = 2025-03-10 05:21:27. The SP should run daily; the table appears to have not been refreshed since March 2025.

**Action needed**: Check whether the SP is still scheduled and running. If the table is no longer being maintained, mark it as deprecated/legacy in the wiki.

---

### 6. `[Account Manager]` column name contains a space (non-standard)

**Issue**: The column `[Account Manager]` uses a space in its name (requires bracket quoting in all SQL). This is an unusual pattern for Synapse DWH tables.

**Action needed**: Confirm this is by design (for BI tool display) or should be normalized to `AccountManager` in a future schema version.
