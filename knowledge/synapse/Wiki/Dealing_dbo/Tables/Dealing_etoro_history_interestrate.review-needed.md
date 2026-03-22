# Review Sidecar — Dealing_dbo.Dealing_etoro_history_interestrate

## Unverified Claims

| # | Claim | Source | Needs |
|---|-------|--------|-------|
| 1 | BeginTime/EndTime map to SysStartTime/SysEndTime from a temporal table | Inferred from SCD2 pattern | Confirm with production schema |
| 2 | OverNightFeePatternID links to a fee pattern config table | Column name inference | Identify the linked table if it exists |
| 3 | SettlementTypeID distinguishes cash vs physical settlement | Column name inference | Verify dictionary values |
| 4 | InterestRate column is deprecated in favor of directional rates | Live data pattern (0E-8 in newer rows) | Confirm with Dealing Ops |

## Reviewer Corrections

*(none yet)*
