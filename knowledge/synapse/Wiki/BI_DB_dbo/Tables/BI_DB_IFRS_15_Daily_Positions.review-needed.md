# Review Needed: BI_DB_dbo.BI_DB_IFRS_15_Daily_Positions

> Sidecar to `BI_DB_IFRS_15_Daily_Positions.md`. Items requiring domain expert validation before Tier promotion or UC migration.

---

## Tier 4 Items — Unverified / Always NULL in Samples

| Column | Issue | Action Required |
|--------|-------|-----------------|
| `Changed_CFD_Real` | Always NULL in sampled data (10K row sample). SP inserts NULL from `#relpos` branch; changelog branch populates this separately. Needs production validation that the changelog INSERT path actually fires and contains non-NULL values. | Confirm whether changelog branch populates this in production or if column is de facto unused. |
| `Change_Type` | Same as above — always NULL in sampled data. | Same as Changed_CFD_Real. |

---

## SQL Logic Concerns

### OutlierTransition Filter (Potential Bug)
**Location**: SP_IFRS_15_Balance — `#outliers` population block

**Code**:
```sql
WHERE LOWER(bdon.Transition) <> '%dlt%'
```

**Issue**: Uses `<>` (not-equal) instead of `NOT LIKE`. The string `'%dlt%'` is a LIKE wildcard pattern, not a literal value. This means positions where `Transition = '%dlt%'` (the literal string with percent signs) are excluded, rather than positions where Transition *contains* the substring 'dlt'. The intent appears to be `NOT LIKE '%dlt%'` to exclude DLT transitions from the outlier set.

**Impact**: If this bug is real, DLT transitions are NOT being excluded as intended, and IsOutlier / OutlierTransition values for DLT users may be incorrectly computed.

**Action Required**: Confirm with the SP author (Guy Manova) whether this is intentional or a bug. If a bug, raise an SP fix ticket.

---

## Semantic Reclassifications — Confirm Business Intent

| Column | Source Column | Reclassification | Question |
|--------|---------------|------------------|----------|
| `Staking` | `Dim_Position.IsAirDrop` | `IsAirDrop=1 → 'Staking'` | The source column is `IsAirDrop` but the output label is `Staking`. Confirm that AirDrop positions are intentionally re-labeled as Staking for IFRS 15 purposes and that these two concepts are equivalent in the business domain. |
| `PositionTiming = 'bla'` | SP CASE ELSE | 47% of rows — carry-forward open positions (open before date, still open) | Confirm this is intentional ETL design (not a data quality issue). The 'bla' value appears to be a placeholder for positions that were open before the reporting period and remain open at period end — i.e., they have no open or close event on this date. |

---

## Data Volume / Scope Questions

| Question | Context |
|----------|---------|
| Why does `InstrumentID=624` appear alongside `InstrumentTypeID=10` in the crypto filter? | InstrumentID=624 may be a crypto instrument that does not carry InstrumentTypeID=10, suggesting a data quality exception in Dim_Instrument. Confirm this is intentional. |
| 317.5M rows — is the 2-day retroactive WHILE loop (@date-1 to @date) causing double-counting risk? | The DELETE+INSERT pattern within the WHILE loop should prevent duplicates, but confirm that concurrent SP runs for the same date cannot interleave. |

---

## Not Migrated to UC

This table has **UC Target: Not Migrated**. Before any UC migration planning, the following must be resolved:
- Dependency on `BI_DB_PositionPnL` (itself a UC migration candidate)
- Dependency on `External_Bronze_etoro_Trade_AdminPositionLog` (external Bronze table — confirm UC path)
- Dependency on `Function_Revenue_TicketFeeByPercent` (SP-callable function — confirm UC equivalent)
- Changed_CFD_Real / Change_Type columns (Tier 4) — assess whether changelog branch will be re-implemented in UC or deprecated

---

*Generated: 2026-04-22 | Batch 27 | Reviewer: pending*
