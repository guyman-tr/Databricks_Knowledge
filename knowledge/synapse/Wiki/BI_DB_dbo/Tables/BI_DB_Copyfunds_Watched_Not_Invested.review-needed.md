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

### 3. #final fan-out bug — duplicate (RealCID, FundName) rows (HIGH — data quality defect)

**Issue**: The SP's `#final` temp table is built via:
```sql
JOIN #temp t JOIN #transformuserdata tud ON t.RealCID = tud.RealCID
```
without a FundCID predicate. Because `#temp` has N rows per investor (one per distinct fund watched) and `#transformuserdata` has M rows per investor (multiple follow events per fund are retained), the join produces N×K_j duplicate rows for each (investor, fund_j) pair.

**Evidence from live data**: RealCID=24457833 generates up to 330 rows for a single (RealCID, FundName='Sharia-AIGrowth') pair. RealCID=38269010 generates 234 duplicates for multiple funds. These are not data-entry errors — they are structural SP defects.

**Root cause**: FundCID appears in the `#temp` GROUP BY clause but is not included in the SELECT, so the FundCID binding is lost before the #final JOIN.

**Fix**: Either (a) include `FundCID` in `#temp` SELECT and add `AND t.FundCID = tud.FundCID` to the #final JOIN predicate, or (b) wrap the final INSERT with `SELECT DISTINCT` over all 14 output columns.

**Impact**: Queries using `COUNT(*)` instead of `COUNT(DISTINCT RealCID)` will significantly overcount investors. All aggregations on this table should use DISTINCT or pre-deduplicate.

---

### 4. Stale data — UpdateDate is 2025-03-10 (over a year old as of 2026-04-28)

**Issue**: All rows sampled show UpdateDate = 2025-03-10 05:21:27. The SP should run daily; the table appears to have not been refreshed since March 2025.

**Action needed**: Check whether the SP is still scheduled and running. If the table is no longer being maintained, mark it as deprecated/legacy in the wiki.

---

### 5. `[Account Manager]` column name contains a space (non-standard)

**Issue**: The column `[Account Manager]` uses a space in its name (requires bracket quoting in all SQL). This is an unusual pattern for Synapse DWH tables.

**Action needed**: Confirm this is by design (for BI tool display) or should be normalized to `AccountManager` in a future schema version.

---

### 6. MoneyAvailable upstream verbatim — Fact_SnapshotEquity.Credit wiki not in bundle

**Issue**: `MoneyAvailable` is Tier 1 from Fact_SnapshotEquity.Credit (via V_Liabilities). The V_Liabilities wiki documents `Credit` as a direct passthrough from `Fact_SnapshotEquity.Credit` but does not provide a verbatim upstream description for Fact_SnapshotEquity.Credit itself (Fact_SnapshotEquity wiki was not included in the bundle).

**Action needed**: When Fact_SnapshotEquity wiki is available, update the MoneyAvailable Tier 1 description with the verbatim upstream description for Fact_SnapshotEquity.Credit.
