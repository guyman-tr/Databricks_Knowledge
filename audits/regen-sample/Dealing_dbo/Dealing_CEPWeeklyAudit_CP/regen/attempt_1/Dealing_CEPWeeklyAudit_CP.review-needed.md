# Review Needed: Dealing_dbo.Dealing_CEPWeeklyAudit_CP

## Tier 4 Columns

| Column | Current Tier | Question |
|--------|-------------|----------|
| UpdateDate | Tier 4 | Standard `GETDATE()` ETL metadata pattern — confirmed from SP code. No action needed unless SP logic changes. |

## Open Questions

1. **LoginName NULL rate (~72%)**: The `AppLoginName` from staging externals is NULL for most deletion rows and some history entries. Confirm whether this is expected behavior or a data gap in the source system.

2. **Rule context fan-out**: A single CP deletion can appear as multiple rows when the CP was mapped to multiple rules via `#Dim_CPtoRule`. Confirm whether downstream consumers expect deduplicated CP events or the fanned-out rule-context rows.

3. **No-change placeholder rows (79)**: The LEFT JOIN on `#FromDateToDate` produces scaffold rows. Confirm whether these placeholder rows serve a downstream purpose or could be eliminated.

## Cross-Table Naming Note

- This table uses **`CPName`** (no underscore). Sibling table `Dealing_CEPWeeklyAudit_CPToRule` uses **`CP_Name`** (with underscore). This is an intentional inconsistency in the SP — not a bug, but analysts should be aware when joining.

## Lineage Confidence

- All 11 business columns traced to SP code → **Tier 2**. No upstream production wiki provides direct column-level documentation for CEP Compound Properties — staging externals are unresolved.
- `UpdateDate` is standard `GETDATE()` → **Tier 4**.
