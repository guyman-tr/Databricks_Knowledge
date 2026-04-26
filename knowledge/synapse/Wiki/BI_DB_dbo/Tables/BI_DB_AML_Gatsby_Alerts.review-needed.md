# Review Needed: BI_DB_AML_Gatsby_Alerts

**Generated**: 2026-04-22  
**Batch**: 44  
**Reviewer**: Domain SME (USA AML / Gatsby compliance team)

---

## 1. INVESTIGATE — Zero real alerts in 2+ years of operation

**Priority**: HIGH  
All 808 rows in the table are Dummy Line sentinel rows. No real alerts have fired since 2024-01-17. This could mean:
1. The APEX Options USA/UK customer population genuinely never triggered any of the 6 AML rules — possible if the customer base is small or conservative in behavior
2. A data issue prevents alerts from reaching the table (e.g., EXT869/EXT872 source data is empty, or source filtering is overly restrictive)
3. The SP is running but the source files (APEX SOD) are not being loaded for the OfficeCode='4GS' population

**Action**: Verify that `External_Sodreconciliation_apex_EXT869_CashActivity` has live data for OfficeCode='4GS' and that the SP logic is being evaluated against real transaction volumes.

---

## 2. VERIFY — `DateOfBirth` stores `GETDATE()` for dummy rows

**Priority**: MEDIUM  
Dummy row sentinel sets `DateOfBirth = GETDATE()` — a datetime value reflecting SP execution time, not a real date of birth. Any consumer joining on `DateOfBirth` or using it without filtering `Rule_Checked <> 'Dummy Line'` will pick up garbage values. Confirm that all downstream users filter dummy rows first.

---

## 3. VERIFY — DC10US-1B logic appears inverted

**Priority**: HIGH (potential SP bug)  
In rule DC10US-1B the WHERE clause reads:
```sql
WHERE r2_2.AccountNumber IS NULL
AND r2_2.withdrawal_count >= 5
```
The `r2_2.AccountNumber IS NULL` condition would exclude any account that has withdrawal records — meaning the `r2_2.withdrawal_count >= 5` condition on the same alias `r2_2` would never be satisfied (an account can't simultaneously have no records and have 5+ withdrawals). This may be a copy-paste error from DC10US-1A (where `r1_2` is the trade table with `IS NULL` meaning "no trades"). If the intent was "has 5+ withdrawals," the `IS NULL` should be removed or the alias corrected.

---

## 4. VERIFY — DC10US-1A trade check logic

**Priority**: MEDIUM  
Rule DC10US-1A fires when there are "no trades." The code JOINs `#traded_past_since_unity2` as `r1_2` and then checks `WHERE r1_2.AccountNumber IS NULL` — i.e., LEFT JOIN with IS NULL filter = accounts with no matching trade records. However, `#traded_past_since_unity2` is built with `AND ProcessDate <= @Date` (all-time), not restricted to the 14-day window used for deposits. This means an account that traded once a year ago but not in the last 14 days would NOT trigger DC10US-1A. Confirm whether the trade window should be restricted to the same 14-day period as the deposits.

---

## 5. INFO — Data availability note

APEX SOD files are available only from November 2022 (when the eToro Options App launched in the USA). Historical data before that date cannot be backfilled. The SP has a commented-out WHILE loop for historical backfill — confirm that backfill from 2022-11-01 to 2024-01-17 was completed if required.
