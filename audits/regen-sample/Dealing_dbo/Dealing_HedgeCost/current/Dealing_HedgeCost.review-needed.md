# Review: Dealing_dbo.Dealing_HedgeCost

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 4 |
| **Quality Score** | 7.8/10 |
| **Status** | Needs Review |

## Automated Confidence Flags

| Flag | Detail | Action Required |
|------|--------|-----------------|
| ⚠️ Atlassian MCP unavailable | Phase 10 (Jira/Confluence) skipped | Search for "HedgeCost" or "SP_HedgeCost" in Confluence for additional business context |
| ⚠️ HC formula verification | HC formula reverse-engineered from SP — complex calculation | Verify with Dealing team that the HC formula interpretation is correct |
| ⚠️ FullCommission source ambiguity | `FullCommission` in output comes from `Dealing_DailyZeroPnL_Stocks.RealizedCommission`, but `AvgRateClientsNoSpread` uses `FullCommissionByUnits/2` from Dim_Position — two different commission measures | Clarify which commission metric is used where and why they differ |
| ⚠️ Dealing_DailyZeroPnL_Stocks dependency | This table depends on `Dealing_DailyZeroPnL_Stocks` which is not yet documented (Pending) | Document that dependency before this table's accuracy can be fully confirmed |
| ℹ️ Name column length | `Name` is varchar(50) which matches Dim_Instrument.Name, but Dim_Instrument has `InstrumentDisplayName` (varchar(100)) which is more descriptive — the SP uses `Name` not `InstrumentDisplayName` | Consider whether InstrumentDisplayName would be more useful for end users |

## Reviewer Corrections

<!-- Leave blank for reviewer to fill in. -->
