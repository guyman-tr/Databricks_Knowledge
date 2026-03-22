# Review Needed — Dealing_dbo.Dealing_Staking_OptedOut

**Batch**: 10 | **Date**: 2026-03-21 | **Quality**: 8.5/10

## Open Questions

1. **Decimal client counts**: EligibleClients etc. are DECIMAL(32,4) not INT. This was presumably intentional for aggregation behavior but seems unusual. Are these ever non-integer in practice?

2. **No US equivalent**: There is no Dealing_Staking_OptedOut_US table in the SSDT repo. Is US staking's opt-in/opt-out breakdown tracked elsewhere, or is this monitoring only done for the non-US program?

3. **Regulation source**: The `Regulation` field — is this sourced from `DWH_dbo.Dim_Regulation` or directly from `DWH_dbo.Dim_Customer.Regulation`? Confirm the join path in SP_Staking_DailyPool.
