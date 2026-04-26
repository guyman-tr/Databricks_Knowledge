# BI_DB_AllDeposits — Items Requiring Review

## RN-1 — AccountIDAsString Always NULL

**Issue**: The SP explicitly hardcodes `NULL AS AccountIDAsString` in the SELECT. The column has been retained in the table schema for backward compatibility but carries no data.

**Impact**: Any downstream query filtering or grouping on `AccountIDAsString` will get no results. Analysts should be warned.

**Action**: Confirm with data engineering whether this column was historically populated and when the NULL hardcoding was introduced. If permanently deprecated, add a comment in the DDL.

---

## RN-2 — PSPCodeAsString vs PSPCode Duplication

**Issue**: The table has both `PSPCode` (varchar(100)) and `PSPCodeAsString` (varchar(100)). The SP writes:
- `a.PSPCodeAsString 'PSPCode'` (positional #39)
- `a.PSPCodeAsString` again later (positional #91 as PSPCodeAsString)

Both contain the same value. Similarly, `BinCode` (bigint) and `BinCodeAsString` (nvarchar(100)) and `BankCode` + `BankCodeAsString` exist as pairs.

**Action**: Document officially which column is the "canonical" one for query use (the shorter-named one: PSPCode, BinCode, BankCode) and which is the legacy alias (the *AsString variants).

---

## RN-3 — ThreeDsAsJson Truncation

**Issue**: The SP casts `ThreeDsAsJson AS VARCHAR(100)`, truncating what is a full JSON blob in Fact_BillingDeposit (nvarchar(max)). For any deposit with 3DS authentication data longer than 100 characters (virtually all), the JSON in this table is truncated and unparseable.

**Action**: Determine whether analysts need the full JSON from this table. If so, a schema change or re-routing to Fact_BillingDeposit for 3DS analysis is needed.

---

## RN-4 — ModificationDateID Type Mismatch

**Issue**: The DDL declares `ModificationDateID [int]`, but the SP writes `CONVERT(VARCHAR(10), ModificationDate, 112)` (a varchar). SQL Server performs an implicit cast at INSERT. While this works, it's non-obvious and the implicit conversion may cause minor performance overhead.

**Action**: Confirm intent. If the column is always treated as an int (YYYYMMDD), consider changing the SP to produce `CONVERT(INT, CONVERT(VARCHAR(8), ModificationDate, 112))` for clarity.

---

## RN-5 — LEAD Category Never Observed (2026)

**Issue**: In Jan-Apr 2026, Category='LEAD' returns 0 rows. The LEAD category (IsFTD=0 AND FirstDepositDate IS NULL) may be effectively dormant for post-2022 data.

**Action**: Query historical data (pre-2022) to confirm LEAD rows exist. If LEAD is no longer produced by the current pipeline, document this and consider whether the Category logic should be updated.

---

## RN-6 — Row Count Unknown (DMV Permission Error)

**Issue**: `sys.dm_pdw_nodes_db_partition_stats` query returned "User does not have permission to perform this action (6004)". Total row count for this table is unknown.

**Estimate**: Based on 3.5M rows in Jan-Apr 2026 (4 months), historical coverage from 2007-08-29 (earliest ModificationDateID), the table likely contains 50M+ rows.

**Action**: Request a DBA to provide row count via `SELECT COUNT(1) FROM BI_DB_dbo.BI_DB_AllDeposits` during a low-traffic window, or use DMV with elevated permissions.

---

## RN-7 — ExpirationDateAsString Retained But Not Used for ID

**Issue**: `ExpirationDateAsString` is present in BI_DB_AllDeposits. In Fact_BillingDeposit, this field is used to compute `ExpirationDateID` (via a complex formula). BI_DB_AllDeposits does not have ExpirationDateID. The raw string is passed through but its format (e.g., 'MM/YY', 'YYYY-MM') varies by PSP.

**Action**: No action needed for wiki accuracy, but analysts should be aware the field requires parsing and is not standardized.
