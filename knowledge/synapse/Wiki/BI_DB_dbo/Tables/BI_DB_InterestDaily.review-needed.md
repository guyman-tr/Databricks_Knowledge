# Review Sidecar: BI_DB_dbo.BI_DB_InterestDaily

## Verification Status

| Item | Status | Notes |
|------|--------|-------|
| Business meaning | Verified via Confluence + SP code | eToro Club "Interest on Balance" feature |
| External source | Verified from SP code | interest-west.database.windows.net, Interest.Trade.InterestDaily |
| Column passthrough | Verified from SP code | All columns passthrough except DateID (computed) and UpdateDate (GETDATE()) |
| Consumer SPs | Verified via repo grep | 7 consumer SPs found (CMR Automation × 5 + Dashboard + DailyPanel) |

## Unverified Items

| Column | Tier | Issue |
|--------|------|-------|
| PlayerLevelID | T4 | Assumed mapping to club tiers (Bronze=1, Silver=2, etc.) — actual IDs need verification |
| Interest | T4 | Unclear if this is running total, monthly accumulation, or separate metric |
| MinRealMoney | T4 | Exact definition of "minimum real money" threshold unclear |
| StatusID | T4 | No FK confirmed — maps to unknown status dimension |
| MonthlyTaxPercentage | T4 | Tax rate source and calculation rules unknown |

## Quality Notes

- Source is external DB (not DWH pipeline) — column meanings depend on Interest microservice documentation
- Synapse MCP unavailable — no live data sampling performed
- Rich Atlassian context found — 5 relevant Confluence pages
