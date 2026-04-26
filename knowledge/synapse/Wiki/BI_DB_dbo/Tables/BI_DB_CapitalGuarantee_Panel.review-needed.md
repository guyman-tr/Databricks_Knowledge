# Review Needed — BI_DB_dbo.BI_DB_CapitalGuarantee_Panel

**Batch**: 70 | **Generated**: 2026-04-23 | **Quality**: 8.5/10

## Tier 2 Items (Require Human Verification)

| Column | Current Description | Question |
|---|---|---|
| FirstTimeOpenID | MAX(OpenDateID) — does NOT correspond to MIN(OpenOccurred) | Is FirstTimeOpenID intentionally the MAX OpenDateID (most recent copy) rather than the DateID of the first copy? This appears to be a naming/logic mismatch — the column name suggests "first" but MAX returns the latest. |
| CopyPnL | SUM(PositionPnL + RealziedPnL) WHERE bdppl.DateID >= @dateID | The filter uses `>=` instead of `=` @dateID. Is this intentional? For a daily snapshot, `= @dateID` would be more precise. `>=` may include future PositionPnL snapshots if they exist. |
| AvailableBalance | V_Liabilities.Credit (INNER JOIN — investors without V_Liabilities record are dropped) | Confirm: are there known cases where investors appear in Dim_Mirror but have no V_Liabilities snapshot for a given date? How common is it? |
| MoneyIn / MoneyOut | ActionTypeID 15/17 = in, 16/18 = out — negated from FCA Amount | Confirm ActionTypeID definitions: 15=copy open, 16=copy close, 17=?, 18=? The naming in the SP doesn't document what each type represents beyond the in/out classification. |

## Known Data Quality Issues

- **IsCreditReportValidCB not stored**: Selected and used in GROUP BY within #Investors and #Investment temp tables but excluded from the final INSERT column list. This field is computed but not available for querying.
- **@date parameter override**: The SP always runs for GETDATE()-1 regardless of @date passed by scheduler. Back-filling historical dates is not possible by calling this SP directly.
- **FirstTimeOpenID mismatch**: `FirstTimeOpen = MIN(OpenOccurred)` but `FirstTimeOpenID = MAX(OpenDateID)`. For investors with multiple copy positions these reflect different mirror records. Do not assume these two columns describe the same event.
- **Capital Guarantee scope only**: Hard-coded `OpenOccurred >= '20250101'` means only mirrors opened in the Capital Guarantee Alpha period are included. Long-standing SP copiers who predate 2025 are invisible in this table.
- **60.6M rows + HEAP + ROUND_ROBIN**: No index, no distribution key. Always filter by DateID. Full scans take 10+ seconds.

## No Tier 4 Items

All source tables are documented DWH dimension/fact objects. No blacklisted dependencies.
