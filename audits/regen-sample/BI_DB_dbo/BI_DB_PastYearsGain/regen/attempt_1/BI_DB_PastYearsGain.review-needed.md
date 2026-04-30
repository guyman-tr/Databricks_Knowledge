# Review Needed: BI_DB_dbo.BI_DB_PastYearsGain

## Items for Human Review

### 1. Historical Date Pattern Shift (Dec 1 → Jan 1)

Rows for Year1 2007–2020 have `Date` values on Dec 1, while rows from Year1 2021+ use Jan 1 dates. The current SP code uses `YEAR(Date)-1` which is correct for Jan 1 dates, but the Dec 1 rows show `Year1 = YEAR(Date)` (not `YEAR(Date)-1`). This suggests:
- Either the SP logic changed at some point (Dec 1 → Jan 1 transition)
- Or the older data was loaded by a different process or manually backfilled

**Action**: Confirm whether the historical Dec 1 data was migrated from a legacy system or loaded by an older version of the SP.

### 2. No Year1=2024 Row Yet

The latest data is Year1=2023 (Date=2024-01-01). Year1=2024 would only appear after the SP runs on 2025-01-01. Verify whether the 2025-01-01 run executed successfully — the sample shows no 2025 data.

### 3. Duplicate Risk (No DELETE Before INSERT)

The SP does not DELETE existing rows before INSERT. If the SP is re-run on Jan 1 (e.g., backfill or retry), duplicate rows could appear. Verify whether operational safeguards exist outside the SP to prevent this.

### 4. DWH_GainDaily Zero-Gain Exclusion

DWH_GainDaily excludes customers with `Gain=0` at the source (WHERE g.Gain <> 0). This means customers with exactly 0% yearly return are absent from BI_DB_PastYearsGain. Confirm whether this exclusion is intentional for the average yearly gain calculation in the PI Dashboard.
