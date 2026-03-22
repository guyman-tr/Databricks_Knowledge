# Review Needed — Dealing_IBRecon_EODHoldings_CFD

**Generated**: 2026-03-21
**Quality Score**: 7.0/10

## Items for Human Review

1. **Very low row count (538 rows)** — Only 538 rows as of 2026-03-09 vs 652K+ in the Real Stocks equivalent. Confirm whether HS 300 (CFD account migrated Apr 2025) is actively sending EOD position data and whether the low count reflects limited CFD hedging through IB or a pipeline issue.

2. **Missing LastExecutionTime** — The CFD variant lacks `LastExecutionTime` present in the Real Stocks table. Confirm if this is intentional (IB doesn't provide execution timestamps for CFD positions) or an oversight.

3. **Relationship to IBRecon_EODHoldings** — Confirm whether these are fully separate pipelines or if CFD and Real rows were previously combined in a single table and later split.
