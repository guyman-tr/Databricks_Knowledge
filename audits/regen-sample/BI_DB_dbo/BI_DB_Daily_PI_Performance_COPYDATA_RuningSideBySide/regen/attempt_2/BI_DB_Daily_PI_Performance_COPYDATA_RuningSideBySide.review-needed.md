# Review Needed — BI_DB_dbo.BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide

## Priority Items

### 1. BI_DB_PI_Dashboard — Unresolved Upstream (10 Tier 3 columns)
The following columns pass through from `BI_DB_dbo.BI_DB_PI_Dashboard`, which has no wiki in the knowledge base:

| Column | Tier | Comment |
|--------|------|---------|
| CID | Tier 3 | Customer ID — origin is almost certainly Dim_Customer.RealCID |
| UserName | Tier 3 | Login username — origin is almost certainly Dim_Customer.UserName |
| PI_level | Tier 3 | PI tier name — likely same origin as BI_DB_CopyDailyData.PI_Level (Dim_GuruStatus) |
| Acc_RiskIndex | Tier 3 | Risk index — likely same origin as BI_DB_CopyDailyData.Acc_RiskIndex (BI_DB_User_Segment_Snapshot) |
| IsBlocked | Tier 3 | Blocked flag — no wiki; source unclear (BackOffice.Customer attribute?) |
| Classification | Tier 3 | Strategy classification — no wiki; 8 distinct values observed |
| TraderType | Tier 3 | Trading style — no wiki; 4 distinct values observed |
| Last_Day_Performance | Tier 3 | Last-day return — no wiki; calculation method unknown |
| YTD | Tier 3 | Year-to-date return — no wiki; calculation method unknown |
| MTD | Tier 3 | Month-to-date return — no wiki; calculation method unknown |

**Action**: Document `BI_DB_dbo.BI_DB_PI_Dashboard` or confirm the SP that writes it to enable Tier 1 inheritance for these columns.

### 2. Table Activity / "Side-By-Side" Context
The latest data in this table is `2024-03-15`. The name `RuningSideBySide` (sic) strongly implies this was a temporary parallel-run / validation copy of the main PI performance table. Confirm with the BI team:
- Is this table still actively loaded?
- What was the side-by-side comparison validating?
- Should this table be retired or kept for historical reference?

### 3. Column Name Typos
The following column names contain typos inherited from the DDL and cannot be changed without pipeline impact:

| Column | Typo | Intended Meaning |
|--------|------|-----------------|
| `Value_percenet` | percenet → percent | Portfolio weight of top position |

### 4. IsBlocked Values
`IsBlocked` is typed `varchar(20)` but sample data shows only `'No'`. Confirm whether `'Yes'` (or other values) can appear and what business rule triggers a PI to be blocked.

### 5. Performance Metric Calculation Method
`Last_Day_Performance`, `YTD`, `MTD` are stored as `float`. Confirm whether these are:
- Raw decimal fractions (e.g., 0.0223 = +2.23%)
- Percentage points (e.g., 2.23 = +2.23%)

Sample data shows values like `0.0223`, `0.6379`, `-0.0052` which suggests decimal fractions, but values > 1 (e.g., `0.6379` = +63.79% YTD) should be verified.
