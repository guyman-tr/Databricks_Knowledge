# Review Notes — BI_DB_dbo.BI_DB_BO_Generated_Compensations

Generated: 2026-04-23 | Batch: 65 | Phase 16 Score: 8.5 / 10

## Status: PASS — one known bug flagged; Category dictionary deferred

---

## Items Requiring Human Review

### 1. Manager Name Bug — Known in Production
- **Issue**: `CONCAT(BMNG.FirstName, '', BMNG.LastName)` uses empty string separator. Confirmed by live sample showing values like `'AdminNistrator'`. Documented as known bug in Section 3.2.
- **Action**: If the bug is ever fixed in SP_BO_Generated_Compensations, update Section 2.3 and Section 4 Manager column notes.
- **Severity**: Informational — already documented; no action needed unless SP is patched.

### 2. Category Dictionary Not Inlined
- **Issue**: Category has 67+ distinct values (confirmed from sibling BI_DB_BODailyCompensations wiki). This exceeds the 15-value inline threshold, so it was not listed inline. The description notes it comes from BackOffice_CompensationReason.Name.
- **Action**: If a curated subset of top/common categories is useful for business users, consider adding a "Top Categories" note to Section 4.
- **Severity**: Low.

### 3. `Reason` NULL Rate — Not Re-Confirmed for This Table
- **Issue**: The ~87% NULL rate for `Reason` was noted from prior session sampling. This should be verified with a current query.
- **Action**: `SELECT SUM(CASE WHEN Reason IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) null_pct FROM BI_DB_dbo.BI_DB_BO_Generated_Compensations`
- **Severity**: Low — estimate is directionally accurate.

### 4. PlayerLevelID=4 and CountryID=250 Exclusion Semantics
- **Issue**: The exclusion of PlayerLevelID=4 was documented as "internal/staff accounts" and CountryID=250 as "a specific country exclusion." The actual country for CountryID=250 was not confirmed from Dim_Country.
- **Action**: `SELECT Name FROM DWH_dbo.Dim_Country WHERE CountryID = 250` to confirm the excluded country name for documentation.
- **Severity**: Low — functionally documented, but identity of excluded country is missing.

### 5. Upstream Wiki: etoro.History.Credit
- **Issue**: No upstream Tier 1 wiki exists for `etoro.History.Credit`. If one is created in `DB_Schema/etoro/Wiki/History/Credit.md`, all column descriptions should be upgraded to Tier 1 and descriptions should be copied verbatim.
- **Action**: Periodically check `DB_Schema/etoro/Wiki/History/` for new wiki files.
- **Severity**: Medium — structural Tier 1 gap; current docs are accurate but unverified against source-of-truth.

---

## Confidence Assessment

| Section | Confidence | Notes |
|---------|-----------|-------|
| Business Meaning | High | SP code + live sampling confirmed |
| Business Logic | High | SP code read directly; bug confirmed by live sample |
| Query Advisory | High | Bugs confirmed empirically |
| Elements | High | All 13 columns traced to SP code |
| Lineage | High | ETL pipeline read from SP; UC target confirmed from config |
| Relationships | Medium | Sibling table identified; others inferred |
| Sample Queries | High | Standard patterns |
