# BI_DB_ClubChangeLog — Items Requiring Review

## RN-1 — Downgrade Discontinuation (Post-2023)

**Issue**: The post-2023 SP code path (for dates ≥ 2023-01-01) does NOT produce 'Downgrade' rows. The downgrade logic only exists in the pre-2023 code path. This means analysts querying club history post-2023 cannot determine if a customer's club level has dropped from the log alone.

**Impact**: Any analytics relying on BI_DB_ClubChangeLog to track customer tier reductions post-2023 will not reflect actual downgrades. The last log entry for a customer may show a high tier (e.g., Gold) even if their current equity is below Bronze.

**Action**: Confirm whether this is an intentional product decision (clubs no longer downgrade in the loyalty program) or an inadvertent omission. If downgrades still occur in the product, this table needs updating.

---

## RN-2 — PlayerLevelID Non-Sequential IDs

**Issue**: The `NewLevel`/`CurrentLevel` integer values are non-sequential: Bronze=1, Platinum=2, Gold=3, Silver=5, Platinum+=6, Diamond=7. Value 4 is absent. This is a historical artifact from the Dim_PlayerLevel definition.

**Impact**: Any code that orders by NewLevel/CurrentLevel to determine club rank will produce wrong results (e.g., treating Gold-3 as higher than Platinum-2).

**Action**: Always document use of Sort columns (NewSort/CurrentSort) for ordering, never PlayerLevelID. This is noted in the wiki.

---

## RN-3 — Equity Methodology Change Boundary

**Issue**: Pre-2023 rows used a 3-month MAXIMUM equity window (a customer could "freeze" at a high tier if they had high equity at any point in the prior 3 months). Post-2023 rows use point-in-time equity. This creates an analytical discontinuity at the 2023-01-01 boundary.

**Impact**: Longitudinal analyses spanning pre/post-2023 should flag the methodology difference. Upgrade rates and tier distributions are not directly comparable across this boundary.

**Action**: Add a note in any analytics or dashboard using this table that covers multi-year history.

---

## RN-4 — IsFTC Backfill Timing

**Issue**: For Upgrade events, `IsFTC` is initially inserted as NULL, then updated in a second pass (UPDATE join with #FTC CTE). This means there may be a brief window after the INSERT where IsFTC=NULL for today's upgrades if the SP fails mid-run.

**Action**: Confirm the SP atomicity. If the SP can fail between the INSERT and the UPDATE, add a retry or wrap both in a transaction.

---

## RN-5 — Row Count Not Obtained

**Issue**: DMV query failed (permission error). Total table size unknown. Based on First Club events alone (~1.5M per 4 months × 7+ years), the table likely contains 30M+ rows.

**Action**: Request row count from DBA or use INFORMATION_SCHEMA approximation.
