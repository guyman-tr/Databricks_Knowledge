# BI_DB_dbo.BI_DB_CopyDailyData — Review Needed

Generated: 2026-04-23 | Batch: 74

## Open Items

### HIGH — UC Migration Decision
**UC Target is `_Not_Migrated`** — not in Generic Pipeline. This table is the primary PI performance time-series and a key input for dashboards and account manager reporting.
- Action: Assess with Data Platform team whether this historical series should be migrated to Unity Catalog.

### HIGH — `commission` Is Cumulative from 2011, Not Daily
The `commission` column accumulates from hardcoded `@start_date = '20110101'` to `@date`. **This is NOT a daily commission delta.** Any report that SUMs `commission` across multiple rows for the same PI will produce a severely inflated number.
- Action: Add a comment or view that exposes a daily commission delta for correct usage.
- Risk: High — misuse of this column in reports is easy and produces incorrect results.

### HIGH — Four Column Name Typos in DDL
The following columns have typos that are baked into the DDL and cannot be corrected without a pipeline/table rebuild:
- `CurrenyEquity` (→ CurrencyEquity or CurrentEquity)
- `ProtfoilioType` (→ PortfolioType)
- `MifidCatigorization` (→ MifidCategorization)
- `DaysInCurrnetStatus` (→ DaysInCurrentStatus)
- Action: Document canonical names in all downstream views and reports. Raise a migration ticket to fix names when UC target is created.

### MEDIUM — `Language` Column Over-Provisioned as char(500)
Language names are typically < 30 chars. `char(500)` wastes significant storage and returns trailing spaces. Any comparison or display query must use `RTRIM(Language)`.
- Action: Fix column type when UC target is created. In the interim, RTRIM() all uses.

### MEDIUM — `Country` and `Region` Are varchar(500)
Same issue — country and region names are < 100 chars. Provisioned at 500.
- Action: Fix at UC migration.

### MEDIUM — `LastContactDate = '1900-01-01'` Sentinel
NULL-replacement sentinel for "no contact on record." Consumers must filter `> '1900-01-01'` rather than IS NOT NULL. This is a silent data quality issue — the column appears to have a value but carries no real information.
- Action: Consider returning NULL directly instead of a sentinel in any UC-layer view.

### MEDIUM — PnL Column Commented Out
The `--,[PnL]` column is in the original SP INSERT list but commented out; `#PnL` calculation block is also commented. No PnL column exists in the table.
- Action: Confirm PnL is intentionally excluded. If needed, `CopyPnL` is available as a partial proxy.

### LOW — ROUND_ROBIN Distribution
Unlike most BI_DB_dbo tables (HASH(CID)), this table uses ROUND_ROBIN. Date-filtered queries must scan all distributions.
- Action: Consider HASH(CID) or HASH(DateID) when building UC target for better query performance.

### LOW — DaysAsPI Has a Known Limitation
SP comment: "if PI go back to less than cadet i will not catch the last date" — meaning if a PI is demoted and re-promoted, DaysAsPI counts from their first-ever promotion, not their most recent.
- Action: Document this in reports using DaysAsPI for PI-age analysis.

### INFO — No Confluence Documentation Found
No DATA space pages identified.
- Action: Contact Data Platform team for any PI dashboard or account manager reporting runbooks.
